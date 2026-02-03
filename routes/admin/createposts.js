const express = require('express');
const router = express.Router();
const { getPool } = require('../../config/db');
const { upload, processUploadedFiles } = require('../../config/imagesUpload');
const requireAdminAuth = require('../../middleware/adminAuth');
const { requireEditor, canPublishDirectly } = require('../../middleware/rolePermissions');

const safeJSON = (input, fallback = []) => {
  if (!input || input === '' || input === 'null' || input === 'undefined') return fallback;
  if (typeof input !== 'string') return input;
  try {
    return JSON.parse(input);
  } catch (error) {
    return fallback;
  }
};

const parseIntSafe = (val, fallback = 0) => {
  if (!val || val === '' || val === 'null' || val === 'undefined') return fallback;
  const parsed = parseInt(val, 10);
  return isNaN(parsed) ? fallback : parsed;
};

const generateSlug = (title) => {
  const baseSlug = title.toLowerCase().trim().replace(/[^a-z0-9\s-]/g, '').replace(/\s+/g, '-').replace(/-+/g, '-').substring(0, 180);
  const randomSuffix = Date.now().toString(36).substring(-6);
  return `${baseSlug}-${randomSuffix}`;
};

const calculateReadingTime = (content) => content ? Math.max(1, Math.ceil(content.trim().split(/\s+/).length / 200)) : 1;

const processContentFormatting = (content) => {
  if (!content) return { processedContent: '', rawContent: '' };
  const rawContent = content;
  let processedContent = content
    .replace(/\[QUOTE sayer="([^"]*)"\](.*?)\[\/QUOTE\]/gs, '<blockquote class="news-large-quote" data-sayer="$1"><p>$2</p><footer>— $1</footer></blockquote>')
    .replace(/\[QUOTE\](.*?)\[\/QUOTE\]/gs, '<blockquote class="news-large-quote">$1</blockquote>')
    .replace(/\[HIGHLIGHT\](.*?)\[\/HIGHLIGHT\]/gs, '<span class="news-highlight">$1</span>')
    .replace(/\[BOLD\](.*?)\[\/BOLD\]/gs, '<strong>$1</strong>')
    .replace(/\[ITALIC\](.*?)\[\/ITALIC\]/gs, '<em>$1</em>')
    .replace(/\[HEADING\](.*?)\[\/HEADING\]/gs, '<h3 class="content-heading">$1</h3>');
  return { processedContent, rawContent };
};

const extractQuotes = (content) => {
  if (!content) return [];
  const quoteRegex = /\[QUOTE(?:\s+sayer="([^"]*)")?\](.*?)\[\/QUOTE\]/gs;
  const quotes = [];
  let match;
  while ((match = quoteRegex.exec(content)) !== null) {
    quotes.push({ 
      text: match[2] ? match[2].trim() : '', 
      sayer: match[1] || null, 
      position: match.index || 0 
    });
  }
  return quotes;
};

const logAdminActivity = async (client, adminId, action, targetType, targetId, details, ip) => {
  try {
    await client.query(
      `INSERT INTO admin_activity_log (admin_id, action, target_type, target_id, details, ip_address) VALUES ($1, $2, $3, $4, $5, $6)`,
      [adminId, action, targetType, targetId, details, ip]
    );
  } catch (error) {
    console.error('[Activity Log] Error:', error);
  }
};

router.post('/', upload.array('images', 10), requireAdminAuth, requireEditor, async (req, res) => {
  const pool = getPool();
  const client = await pool.connect();

  try {
    await client.query('BEGIN');
    const {
      title, content, excerpt, category_ids, primary_category_id,
      priority = 'medium', tags = '', meta_description = '',
      seo_keywords = '', status = 'draft', author_id,
      social_media_links
    } = req.body;

    if (!title || !content || !category_ids || !primary_category_id || !author_id) {
      await client.query('ROLLBACK');
      return res.status(400).json({
        success: false,
        message: 'Missing required fields: title, content, category_ids, primary_category_id, author_id'
      });
    }

    const actualAuthorId = parseIntSafe(author_id);
    if (!actualAuthorId) {
      await client.query('ROLLBACK');
      return res.status(400).json({
        success: false,
        message: 'Invalid author_id'
      });
    }

    const parsedCategoryIds = safeJSON(category_ids, []);
    if (!Array.isArray(parsedCategoryIds) || parsedCategoryIds.length === 0) {
      await client.query('ROLLBACK');
      return res.status(400).json({
        success: false,
        message: 'At least one category must be selected'
      });
    }

    const parsedPrimaryCategoryId = parseIntSafe(primary_category_id);
    if (!parsedPrimaryCategoryId) {
      await client.query('ROLLBACK');
      return res.status(400).json({
        success: false,
        message: 'Primary category ID is required'
      });
    }

    if (!parsedCategoryIds.includes(parsedPrimaryCategoryId)) {
      await client.query('ROLLBACK');
      return res.status(400).json({
        success: false,
        message: 'Primary category must be one of the selected categories'
      });
    }

    const slug = generateSlug(title);
    const reading_time = calculateReadingTime(content);
    const { processedContent, rawContent } = processContentFormatting(content);
    const extractedQuotes = extractQuotes(content);
    const canPublish = canPublishDirectly(req.userRole);
    let finalStatus = status;
    let requiresApproval = false;

    if (status === 'published' && !canPublish) {
      finalStatus = 'pending_approval';
      requiresApproval = true;
    }

    const newsInsertQuery = `
      INSERT INTO news (
        title, slug, content, processed_content, excerpt, author_id, 
        category_id, primary_category_id, 
        priority, reading_time, status, tags, meta_description, seo_keywords, published_at
      ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14, $15)
      RETURNING news_id, title, slug, status
    `;

    const newsInsertValues = [
      title.trim(),
      slug,
      rawContent,
      processedContent,
      excerpt ? excerpt.trim() : title.substring(0, 200),
      actualAuthorId,
      parsedPrimaryCategoryId,
      parsedPrimaryCategoryId,
      priority,
      reading_time,
      finalStatus,
      tags ? tags.trim() : null,
      meta_description ? meta_description.trim() : null,
      seo_keywords ? seo_keywords.trim() : null,
      finalStatus === 'published' ? new Date() : null
    ];

    const newsResult = await client.query(newsInsertQuery, newsInsertValues);
    const newsId = newsResult.rows[0].news_id;

    for (const categoryId of parsedCategoryIds) {
      const isPrimary = categoryId === parsedPrimaryCategoryId;
      await client.query(
        `INSERT INTO news_categories (news_id, category_id, is_primary) VALUES ($1, $2, $3)`,
        [newsId, categoryId, isPrimary]
      );
    }

    if (extractedQuotes.length > 0) {
      await client.query(
        `UPDATE news SET quotes_data = $1 WHERE news_id = $2`,
        [JSON.stringify(extractedQuotes), newsId]
      );
    }

    const parsedSocialLinks = safeJSON(social_media_links, []);
    if (Array.isArray(parsedSocialLinks) && parsedSocialLinks.length > 0) {
      for (const link of parsedSocialLinks) {
        if (link.post_url && link.post_url.trim()) {
          await client.query(
            `INSERT INTO news_social_media (
              news_id, platform, post_type, post_url, display_order, 
              auto_embed, show_full_embed, is_featured, caption
            ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9)`,
            [
              newsId,
              link.platform || 'youtube_video',
              link.post_type || 'video',
              link.post_url.trim(),
              link.display_order || 1,
              link.auto_embed !== false,
              link.show_full_embed !== false,
              link.is_featured || false,
              link.caption || null
            ]
          );
        }
      }
    }

    if (req.files && req.files.length > 0) {
      const uploadedImageData = await processUploadedFiles(req.files);

      const imageMetadataPattern = /^image_metadata_(\d+)$/;
      const metadataByIndex = {};
      Object.keys(req.body).forEach(key => {
        const match = key.match(imageMetadataPattern);
        if (match) {
          const index = parseInt(match[1], 10);
          metadataByIndex[index] = safeJSON(req.body[key], {});
        }
      });

      let featuredImageUrl = null;

      for (let i = 0; i < uploadedImageData.length; i++) {
        const imgData = uploadedImageData[i];
        const metadata = metadataByIndex[i] || {};
        const isFeatured = i === 0 ? true : (metadata.is_featured || false);

        if (isFeatured && !featuredImageUrl) {
          featuredImageUrl = imgData.url;
        }

        await client.query(
          `INSERT INTO news_images (
            news_id, image_url, image_caption, alt_text, display_order, is_featured,
            width, height, file_size, mime_type, storage_provider, cloudflare_id, metadata
          ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13)`,
          [
            newsId,
            imgData.url,
            metadata.caption || '',
            metadata.caption || imgData.originalname || '',
            metadata.order !== undefined ? metadata.order : i,
            isFeatured,
            imgData.width || null,
            imgData.height || null,
            imgData.size || null,
            imgData.mimetype || null,
            imgData.storage_provider || 'local',
            imgData.cloudflare_id || null,
            JSON.stringify({
              originalname: imgData.originalname,
              filename: imgData.filename,
              has_watermark: metadata.has_watermark || false
            })
          ]
        );
      }

      if (featuredImageUrl) {
        await client.query(
          `UPDATE news SET image_url = $1 WHERE news_id = $2`,
          [featuredImageUrl, newsId]
        );
      }
    }

    await logAdminActivity(
      client,
      req.adminId,
      'create_post',
      'news',
      newsId,
      JSON.stringify({ title, status: finalStatus, requires_approval: requiresApproval }),
      req.ip
    );

    await client.query('COMMIT');

    return res.status(201).json({
      success: true,
      message: requiresApproval 
        ? 'Post created and submitted for approval' 
        : (finalStatus === 'published' ? 'Post published successfully' : 'Draft created successfully'),
      news_id: newsId,
      slug,
      status: finalStatus,
      requires_approval: requiresApproval
    });

  } catch (error) {
    await client.query('ROLLBACK');
    console.error('[CREATE POST] Error:', error);
    return res.status(500).json({
      success: false,
      message: 'Failed to create post',
      error: error.message
    });
  } finally {
    client.release();
  }
});

router.put('/:newsId', upload.array('images', 10), requireAdminAuth, requireEditor, async (req, res) => {
  const pool = getPool();
  const client = await pool.connect();
  const newsId = parseInt(req.params.newsId, 10);

  try {
    await client.query('BEGIN');

    const existingNews = await client.query(
      `SELECT news_id FROM news WHERE news_id = $1`,
      [newsId]
    );

    if (existingNews.rows.length === 0) {
      await client.query('ROLLBACK');
      return res.status(404).json({
        success: false,
        message: 'Post not found'
      });
    }

    const {
      title, content, excerpt, category_ids, primary_category_id,
      priority = 'medium', tags = '', meta_description = '',
      seo_keywords = '', status = 'draft', author_id,
      social_media_links
    } = req.body;

    if (!title || !content || !category_ids || !primary_category_id) {
      await client.query('ROLLBACK');
      return res.status(400).json({
        success: false,
        message: 'Missing required fields'
      });
    }

    const parsedCategoryIds = safeJSON(category_ids, []);
    if (!Array.isArray(parsedCategoryIds) || parsedCategoryIds.length === 0) {
      await client.query('ROLLBACK');
      return res.status(400).json({
        success: false,
        message: 'At least one category must be selected'
      });
    }

    const parsedPrimaryCategoryId = parseIntSafe(primary_category_id);
    if (!parsedPrimaryCategoryId) {
      await client.query('ROLLBACK');
      return res.status(400).json({
        success: false,
        message: 'Primary category ID is required'
      });
    }

    if (!parsedCategoryIds.includes(parsedPrimaryCategoryId)) {
      await client.query('ROLLBACK');
      return res.status(400).json({
        success: false,
        message: 'Primary category must be one of the selected categories'
      });
    }

    const slug = generateSlug(title);
    const reading_time = calculateReadingTime(content);
    const { processedContent, rawContent } = processContentFormatting(content);
    const extractedQuotes = extractQuotes(content);
    const canPublish = canPublishDirectly(req.userRole);
    let finalStatus = status;
    let requiresApproval = false;

    if (status === 'published' && !canPublish) {
      finalStatus = 'pending_approval';
      requiresApproval = true;
    }

    const updateQuery = `
      UPDATE news SET
        title = $1, slug = $2, content = $3, processed_content = $4, excerpt = $5,
        category_id = $6, primary_category_id = $7, priority = $8, reading_time = $9, status = $10,
        tags = $11, meta_description = $12, seo_keywords = $13,
        published_at = CASE WHEN $10 = 'published' AND published_at IS NULL THEN NOW() ELSE published_at END,
        updated_at = NOW()
      WHERE news_id = $14
      RETURNING news_id, slug, status
    `;

    const updateValues = [
      title.trim(),
      slug,
      rawContent,
      processedContent,
      excerpt ? excerpt.trim() : title.substring(0, 200),
      parsedPrimaryCategoryId,
      parsedPrimaryCategoryId,
      priority,
      reading_time,
      finalStatus,
      tags ? tags.trim() : null,
      meta_description ? meta_description.trim() : null,
      seo_keywords ? seo_keywords.trim() : null,
      newsId
    ];

    await client.query(updateQuery, updateValues);

    await client.query(`DELETE FROM news_categories WHERE news_id = $1`, [newsId]);
    for (const categoryId of parsedCategoryIds) {
      const isPrimary = categoryId === parsedPrimaryCategoryId;
      await client.query(
        `INSERT INTO news_categories (news_id, category_id, is_primary) VALUES ($1, $2, $3)`,
        [newsId, categoryId, isPrimary]
      );
    }

    if (extractedQuotes.length > 0) {
      await client.query(
        `UPDATE news SET quotes_data = $1 WHERE news_id = $2`,
        [JSON.stringify(extractedQuotes), newsId]
      );
    } else {
      await client.query(
        `UPDATE news SET quotes_data = $1 WHERE news_id = $2`,
        ['[]', newsId]
      );
    }

    await client.query(`DELETE FROM news_social_media WHERE news_id = $1`, [newsId]);
    const parsedSocialLinks = safeJSON(social_media_links, []);
    if (Array.isArray(parsedSocialLinks) && parsedSocialLinks.length > 0) {
      for (const link of parsedSocialLinks) {
        if (link.post_url && link.post_url.trim()) {
          await client.query(
            `INSERT INTO news_social_media (
              news_id, platform, post_type, post_url, display_order,
              auto_embed, show_full_embed, is_featured, caption
            ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9)`,
            [
              newsId,
              link.platform || 'youtube_video',
              link.post_type || 'video',
              link.post_url.trim(),
              link.display_order || 1,
              link.auto_embed !== false,
              link.show_full_embed !== false,
              link.is_featured || false,
              link.caption || null
            ]
          );
        }
      }
    }

    if (req.files && req.files.length > 0) {
      const uploadedImageData = await processUploadedFiles(req.files);

      const imageMetadataPattern = /^image_metadata_(\d+)$/;
      const metadataByIndex = {};
      Object.keys(req.body).forEach(key => {
        const match = key.match(imageMetadataPattern);
        if (match) {
          const index = parseInt(match[1], 10);
          metadataByIndex[index] = safeJSON(req.body[key], {});
        }
      });

      let featuredImageUrl = null;

      for (let i = 0; i < uploadedImageData.length; i++) {
        const imgData = uploadedImageData[i];
        const metadata = metadataByIndex[i] || {};
        const isFeatured = i === 0 ? true : (metadata.is_featured || false);

        if (isFeatured && !featuredImageUrl) {
          featuredImageUrl = imgData.url;
        }

        await client.query(
          `INSERT INTO news_images (
            news_id, image_url, image_caption, alt_text, display_order, is_featured,
            width, height, file_size, mime_type, storage_provider, cloudflare_id, metadata
          ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13)`,
          [
            newsId,
            imgData.url,
            metadata.caption || '',
            metadata.caption || imgData.originalname || '',
            metadata.order !== undefined ? metadata.order : i,
            isFeatured,
            imgData.width || null,
            imgData.height || null,
            imgData.size || null,
            imgData.mimetype || null,
            imgData.storage_provider || 'local',
            imgData.cloudflare_id || null,
            JSON.stringify({
              originalname: imgData.originalname,
              filename: imgData.filename,
              has_watermark: metadata.has_watermark || false
            })
          ]
        );
      }

      if (featuredImageUrl) {
        await client.query(
          `UPDATE news SET image_url = $1 WHERE news_id = $2`,
          [featuredImageUrl, newsId]
        );
      }
    }

    await logAdminActivity(
      client,
      req.adminId,
      'update_post',
      'news',
      newsId,
      JSON.stringify({ title, status: finalStatus, requires_approval: requiresApproval }),
      req.ip
    );

    await client.query('COMMIT');

    return res.status(200).json({
      success: true,
      message: requiresApproval 
        ? 'Post updated and submitted for approval' 
        : (finalStatus === 'published' ? 'Post updated successfully' : 'Draft updated successfully'),
      news_id: newsId,
      slug,
      status: finalStatus,
      requires_approval: requiresApproval
    });

  } catch (error) {
    await client.query('ROLLBACK');
    console.error('[UPDATE POST] Error:', error);
    return res.status(500).json({
      success: false,
      message: 'Failed to update post',
      error: error.message
    });
  } finally {
    client.release();
  }
});

router.delete('/:newsId', requireAdminAuth, async (req, res) => {
  const pool = getPool();
  const client = await pool.connect();
  const newsId = parseInt(req.params.newsId, 10);

  try {
    await client.query('BEGIN');

    const existingNews = await client.query(
      `SELECT news_id, title FROM news WHERE news_id = $1`,
      [newsId]
    );

    if (existingNews.rows.length === 0) {
      await client.query('ROLLBACK');
      return res.status(404).json({
        success: false,
        message: 'Post not found'
      });
    }

    await client.query(`DELETE FROM news_categories WHERE news_id = $1`, [newsId]);
    await client.query(`DELETE FROM news_social_media WHERE news_id = $1`, [newsId]);
    await client.query(`DELETE FROM news_images WHERE news_id = $1`, [newsId]);
    await client.query(`DELETE FROM news WHERE news_id = $1`, [newsId]);

    await logAdminActivity(
      client,
      req.adminId,
      'delete_post',
      'news',
      newsId,
      JSON.stringify({ title: existingNews.rows[0].title }),
      req.ip
    );

    await client.query('COMMIT');

    return res.status(200).json({
      success: true,
      message: 'Post deleted successfully'
    });

  } catch (error) {
    await client.query('ROLLBACK');
    console.error('[DELETE POST] Error:', error);
    return res.status(500).json({
      success: false,
      message: 'Failed to delete post',
      error: error.message
    });
  } finally {
    client.release();
  }
});

module.exports = router;
