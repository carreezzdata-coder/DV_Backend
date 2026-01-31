const express = require('express');
const router = express.Router();
const { getPool } = require('../../config/db');
const { upload, processUploadedFiles, getFullImageUrl } = require('../../config/imagesUpload');
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

const generateSlug = (title) => title.toLowerCase().trim().replace(/[^a-z0-9\s-]/g, '').replace(/\s+/g, '-').replace(/-+/g, '-').substring(0, 200);

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

// GET /api/admin/edit/news/:id - Retrieve news for editing
router.get('/news/:id', requireAdminAuth, async (req, res) => {
  const pool = getPool();
  try {
    const { id } = req.params;
    
    console.log('[GET NEWS] Request for ID:', id);
    console.log('[GET NEWS] Admin ID:', req.adminId);
    
    if (!id || !/^\d+$/.test(id)) {
      return res.status(400).json({ success: false, error: 'Invalid news ID' });
    }

    const newsQuery = `
      SELECT 
        n.*,
        c.name as primary_category_name, 
        c.slug as primary_category_slug,
        COALESCE(a.first_name, 'Unknown') as first_name, 
        COALESCE(a.last_name, 'Author') as last_name,
        a.email as author_email, 
        a.role as author_role,
        COALESCE(
          (SELECT workflow_status FROM news_approval WHERE news_id = n.news_id LIMIT 1),
          'draft'
        ) as workflow_status,
        COALESCE(
          (SELECT requires_approval FROM news_approval WHERE news_id = n.news_id LIMIT 1),
          false
        ) as requires_approval
      FROM news n
      LEFT JOIN categories c ON n.primary_category_id = c.category_id
      LEFT JOIN admins a ON n.author_id = a.admin_id
      WHERE n.news_id = $1
    `;

    const newsResult = await pool.query(newsQuery, [id]);
    
    if (newsResult.rows.length === 0) {
      console.log('[GET NEWS] News not found for ID:', id);
      return res.status(404).json({ success: false, message: 'News not found' });
    }

    const categoriesResult = await pool.query(
      `SELECT nc.category_id, nc.is_primary, c.name, c.slug 
       FROM news_categories nc
       JOIN categories c ON nc.category_id = c.category_id 
       WHERE nc.news_id = $1
       ORDER BY nc.is_primary DESC, c.name ASC`,
      [id]
    );

    const imagesResult = await pool.query(
      `SELECT * FROM news_images WHERE news_id = $1 ORDER BY display_order ASC`,
      [id]
    );

    const socialMediaResult = await pool.query(
      `SELECT * FROM news_social_media WHERE news_id = $1 ORDER BY display_order ASC`,
      [id]
    );

    const newsData = newsResult.rows[0];

    console.log('[GET NEWS] Successfully retrieved news:', newsData.title);

    return res.status(200).json({
      success: true,
      news: {
        ...newsData,
        image_url: getFullImageUrl(newsData.image_url),
        category_ids: categoriesResult.rows.map(c => c.category_id),
        categories: categoriesResult.rows,
        images_data: imagesResult.rows.map(img => ({
          ...img,
          image_path: getFullImageUrl(img.image_url)
        })),
        social_media_links: socialMediaResult.rows
      }
    });
  } catch (error) {
    console.error('[Get News] Error:', error);
    console.error('[Get News] Stack:', error.stack);
    return res.status(500).json({ success: false, message: 'Failed to fetch news', error: error.message });
  }
});

// PUT /api/admin/edit/news/:id - Update news article
router.put('/news/:id', upload.array('new_images', 10), requireAdminAuth, requireEditor, async (req, res) => {
  const pool = getPool();
  const client = await pool.connect();

  console.log('[UPDATE POST] Request received');
  console.log('[UPDATE POST] req.adminId:', req.adminId);
  console.log('[UPDATE POST] req.body.author_id:', req.body.author_id);
  console.log('[UPDATE POST] Files received:', req.files ? req.files.length : 0);

  try {
    await client.query('BEGIN');

    const { id } = req.params;
    const {
      title, content, excerpt, category_ids, primary_category_id,
      priority = 'medium', tags = '', meta_description = '',
      seo_keywords = '', social_media_links = '[]',
      status = 'draft', author_id, existing_images = '[]'
    } = req.body;

    console.log('[UPDATE POST] Title:', title);
    console.log('[UPDATE POST] Categories:', category_ids);
    console.log('[UPDATE POST] Status:', status);

    if (!id || !/^\d+$/.test(id)) {
      await client.query('ROLLBACK');
      return res.status(400).json({ success: false, error: 'Invalid news ID' });
    }

    if (!req.adminId) {
      await client.query('ROLLBACK');
      return res.status(401).json({ success: false, message: 'Authentication required - no admin ID in session' });
    }

    if (!title || !content) {
      await client.query('ROLLBACK');
      return res.status(400).json({ success: false, message: 'Title and content are required' });
    }

    const checkNews = await client.query('SELECT news_id, author_id FROM news WHERE news_id = $1', [id]);
    if (checkNews.rows.length === 0) {
      await client.query('ROLLBACK');
      return res.status(404).json({ success: false, message: 'News not found' });
    }

    const parsedCategoryIds = safeJSON(category_ids, []);
    if (parsedCategoryIds.length === 0) {
      await client.query('ROLLBACK');
      return res.status(400).json({ success: false, message: 'At least one category is required' });
    }

    const primaryCatId = parseIntSafe(primary_category_id) || parsedCategoryIds[0];

    // Author handling - ALIGNED WITH createposts.js
    const submittedAuthorId = parseIntSafe(author_id);
    const finalAuthorId = submittedAuthorId || checkNews.rows[0].author_id;

    console.log('[UPDATE POST] Final author_id will be:', finalAuthorId);

    const authorCheck = await client.query(
      'SELECT admin_id, first_name, last_name, role FROM admins WHERE admin_id = $1 AND status = $2',
      [finalAuthorId, 'active']
    );

    if (authorCheck.rows.length === 0) {
      await client.query('ROLLBACK');
      console.error('[UPDATE POST] Author not found or inactive:', finalAuthorId);
      return res.status(400).json({ 
        success: false, 
        message: `Author ID ${finalAuthorId} not found or inactive. Please log out and log back in.` 
      });
    }

    console.log('[UPDATE POST] Author verified:', authorCheck.rows[0].first_name, authorCheck.rows[0].last_name);

    const userRole = (req.userRole || '').toLowerCase();
    
    let finalStatus = status;
    let workflowStatus = 'draft';
    let requiresApproval = false;

    if (status === 'published') {
      if (canPublishDirectly(userRole)) {
        finalStatus = 'published';
        workflowStatus = 'published';
      } else {
        finalStatus = 'draft';
        workflowStatus = 'pending_approval';
        requiresApproval = true;
      }
    }

    console.log('[UPDATE POST] Final status:', finalStatus, 'Workflow:', workflowStatus);

    const slug = generateSlug(title);
    const readingTime = calculateReadingTime(content);
    const { processedContent, rawContent } = processContentFormatting(content);
    const quotes = extractQuotes(content);
    const publishedAt = finalStatus === 'published' ? new Date() : null;

    const parsedExistingImages = safeJSON(existing_images, []);
    let featuredImageUrl = null;
    const existingFeaturedImage = parsedExistingImages.find(img => img.is_featured);

    if (existingFeaturedImage) {
      featuredImageUrl = existingFeaturedImage.image_path;
    } else if (req.files && req.files.length > 0) {
      console.log('[UPDATE POST] Processing new images...');
      const processedImages = await processUploadedFiles(req.files);
      featuredImageUrl = processedImages[0]?.url || null;
      console.log('[UPDATE POST] Featured image URL:', featuredImageUrl);
    }

    const updateQuery = `
      UPDATE news SET 
        title = $1, content = $2, processed_content = $3, excerpt = $4, slug = $5,
        category_id = $6, primary_category_id = $7, priority = $8, image_url = $9, status = $10,
        tags = $11, meta_description = $12, seo_keywords = $13, reading_time = $14,
        published_at = $15, quotes_data = $16, author_id = $17, updated_at = CURRENT_TIMESTAMP
      WHERE news_id = $18
    `;

    console.log('[UPDATE POST] Updating news...');
    await client.query(updateQuery, [
      title, rawContent, processedContent, 
      excerpt || title.substring(0, 200) + '...', 
      slug, primaryCatId, primaryCatId, priority, featuredImageUrl, finalStatus, 
      tags, meta_description, seo_keywords, readingTime, publishedAt, 
      JSON.stringify(quotes), finalAuthorId, id
    ]);

    console.log('[UPDATE POST] News updated');

    // Delete and re-insert categories
    await client.query('DELETE FROM news_categories WHERE news_id = $1', [id]);
    for (const catId of parsedCategoryIds) {
      await client.query(
        `INSERT INTO news_categories (news_id, category_id, is_primary) 
         VALUES ($1, $2, $3)
         ON CONFLICT (news_id, category_id) DO UPDATE SET is_primary = EXCLUDED.is_primary`,
        [id, catId, catId === parseInt(primaryCatId)]
      );
    }
    console.log('[UPDATE POST] Categories assigned');

    // Update approval workflow
    await client.query(
      `INSERT INTO news_approval (news_id, workflow_status, requires_approval, submitted_at, submitted_by)
       VALUES ($1, $2, $3, CURRENT_TIMESTAMP, $4)
       ON CONFLICT (news_id) DO UPDATE SET
         workflow_status = EXCLUDED.workflow_status,
         requires_approval = EXCLUDED.requires_approval,
         submitted_at = CURRENT_TIMESTAMP,
         submitted_by = EXCLUDED.submitted_by,
         updated_at = CURRENT_TIMESTAMP`,
      [id, workflowStatus, requiresApproval, req.adminId]
    );
    console.log('[UPDATE POST] Approval record updated');

    // Delete and re-insert social media links
    await client.query('DELETE FROM news_social_media WHERE news_id = $1', [id]);
    const parsedSocialLinks = safeJSON(social_media_links, []);
    for (const link of parsedSocialLinks) {
      if (link.post_url && link.post_url.trim()) {
        await client.query(
          `INSERT INTO news_social_media (news_id, platform, post_type, post_url, display_order, auto_embed, show_full_embed, is_featured, caption)
           VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9)`,
          [id, link.platform || 'unknown', link.post_type || 'post', link.post_url.trim(), link.display_order || 2,
           link.auto_embed !== false, link.show_full_embed !== false, link.is_featured || false, link.caption || '']
        );
      }
    }
    console.log('[UPDATE POST] Social media links updated:', parsedSocialLinks.length);

    // Handle existing images
    const keptImageIds = parsedExistingImages.map(img => img.image_id).filter(Boolean);
    if (keptImageIds.length > 0) {
      await client.query('DELETE FROM news_images WHERE news_id = $1 AND image_id != ALL($2)', [id, keptImageIds]);
      for (const img of parsedExistingImages) {
        if (img.image_id) {
          await client.query(
            `UPDATE news_images SET image_caption = $1, display_order = $2, is_featured = $3 WHERE image_id = $4`,
            [img.caption || '', img.order || 0, img.is_featured || false, img.image_id]
          );
        }
      }
    } else {
      await client.query('DELETE FROM news_images WHERE news_id = $1', [id]);
    }

    // Handle new images
    if (req.files && req.files.length > 0) {
      const processedImages = await processUploadedFiles(req.files);
      for (let i = 0; i < processedImages.length; i++) {
        const img = processedImages[i];
        const metadata = safeJSON(req.body[`new_image_metadata_${i}`], {});
        await client.query(
          `INSERT INTO news_images (news_id, image_url, image_caption, display_order, is_featured, cloudflare_id, storage_provider, file_size, mime_type, metadata)
           VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10)`,
          [id, img.url, metadata.caption || '', metadata.order || (i + parsedExistingImages.length), metadata.is_featured || false,
           img.cloudflare_id || null, img.storage_provider || 'local', img.size || 0, img.mimetype || 'image/jpeg',
           JSON.stringify({ originalName: img.originalname, size: img.size, mimetype: img.mimetype, variants: img.variants || null })]
        );
      }
      console.log('[UPDATE POST] Images updated:', processedImages.length);
    }

    // Log activity
    const ip = req.headers['x-forwarded-for'] || req.headers['x-real-ip'] || req.ip || 'unknown';
    await logAdminActivity(client, req.adminId, 'update_news', 'news', id, `Updated: ${title}`, ip);

    await client.query('COMMIT');
    console.log('[UPDATE POST] Transaction committed successfully');

    return res.status(200).json({
      success: true,
      message: finalStatus === 'published' ? 'News updated and published' : 'News updated successfully',
      requires_approval: requiresApproval
    });

  } catch (error) {
    await client.query('ROLLBACK');
    console.error('[UPDATE POST] Error:', error);
    console.error('[UPDATE POST] Error message:', error.message);
    console.error('[UPDATE POST] Error code:', error.code);
    console.error('[UPDATE POST] Error detail:', error.detail);
    console.error('[UPDATE POST] Error constraint:', error.constraint);
    console.error('[UPDATE POST] Stack:', error.stack);
    
    if (error.code === '23505') {
      return res.status(409).json({ success: false, message: 'Duplicate entry detected', error: error.detail });
    }
    if (error.code === '23503') {
      return res.status(400).json({ 
        success: false, 
        message: `Foreign key violation: ${error.constraint}. Author ID or Category ID not found in database.`, 
        error: error.detail,
        hint: 'Please refresh the page and try again'
      });
    }
    
    return res.status(500).json({ 
      success: false, 
      message: 'Failed to update news', 
      error: process.env.NODE_ENV === 'development' ? error.message : 'Internal server error',
      code: error.code
    });
  } finally {
    client.release();
  }
});

module.exports = router;