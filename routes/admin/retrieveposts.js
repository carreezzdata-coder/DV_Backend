const express = require('express');
const router = express.Router();
const { getPool } = require('../../config/db');
const requireAdminAuth = require('../../middleware/adminAuth');
const { requireApprover, requireDeleter } = require('../../middleware/rolePermissions');

const { FRONTEND_URL, CLIENT_URL, ADMIN_URL, API_DOMAIN, ALLOWED_ORIGINS, isOriginAllowed } = require('../../config/frontendconfig');

const getImageUrl = (imageUrl) => {
  if (!imageUrl) return null;
  if (imageUrl.startsWith('http://') || imageUrl.startsWith('https://')) {
    return imageUrl;
  }

  const cleanPath = imageUrl.startsWith('/') ? imageUrl.substring(1) : imageUrl;

  if (process.env.NODE_ENV === 'development') {
    return `http://localhost:5000/${cleanPath}`;
  }

  const r2Url = process.env.R2_PUBLIC_URL;
  if (r2Url) {
    const cleanUrl = r2Url.endsWith('/') ? r2Url.slice(0, -1) : r2Url;
    return `${cleanUrl}/${cleanPath}`;
  }

  return imageUrl;
};

router.get('/', requireAdminAuth, async (req, res) => {
  try {
    const pool = getPool();
    const { 
      page = 1, 
      limit = 20, 
      search = '', 
      status = '', 
      category_ids = '',
      author_id = '',
      sort = 'published_at',
      order = 'DESC'
    } = req.query;

    const offset = (parseInt(page) - 1) * parseInt(limit);
    const queryParams = [];
    let paramIndex = 1;
    let whereConditions = [];

    if (search) {
      queryParams.push(`%${search}%`);
      whereConditions.push(`(n.title ILIKE $${paramIndex} OR n.content ILIKE $${paramIndex})`);
      paramIndex++;
    }

    if (status) {
      queryParams.push(status);
      whereConditions.push(`n.status = $${paramIndex}`);
      paramIndex++;
    }

    if (category_ids) {
      const categoryArray = category_ids.split(',').map(id => parseInt(id)).filter(id => !isNaN(id));
      if (categoryArray.length > 0) {
        queryParams.push(categoryArray);
        whereConditions.push(`(n.category_id = ANY($${paramIndex}) OR n.primary_category_id = ANY($${paramIndex}))`);
        paramIndex++;
      }
    }

    if (author_id) {
      queryParams.push(parseInt(author_id));
      whereConditions.push(`n.author_id = $${paramIndex}`);
      paramIndex++;
    }

    const whereClause = whereConditions.length > 0 ? `WHERE ${whereConditions.join(' AND ')}` : '';

    const validSortColumns = ['published_at', 'created_at', 'updated_at', 'views', 'likes_count', 'title'];
    const sortColumn = validSortColumns.includes(sort) ? sort : 'published_at';
    const sortOrder = order.toUpperCase() === 'ASC' ? 'ASC' : 'DESC';

    const newsQuery = `
      SELECT 
        n.news_id,
        n.title,
        n.excerpt,
        n.slug,
        n.image_url,
        n.status,
        n.views,
        n.likes_count,
        n.comments_count,
        n.share_count,
        n.published_at,
        n.created_at,
        n.updated_at,
        n.author_id,
        n.category_id,
        n.primary_category_id,
        n.tags,
        n.priority,
        n.reading_time,
        a.first_name,
        a.last_name,
        a.email as author_email,
        c.name as category_name,
        c.slug as category_slug,
        pc.name as primary_category_name,
        ARRAY_AGG(DISTINCT nc.category_id) FILTER (WHERE nc.category_id IS NOT NULL) as category_ids,
        (SELECT tier FROM featured_news WHERE news_id = n.news_id AND manually_removed = false LIMIT 1) as featured_tier,
        (SELECT ends_at FROM featured_news WHERE news_id = n.news_id AND manually_removed = false LIMIT 1) as featured_until,
        (SELECT priority FROM breaking_news WHERE news_id = n.news_id AND manually_removed = false LIMIT 1) as breaking_level,
        (SELECT ends_at FROM breaking_news WHERE news_id = n.news_id AND manually_removed = false LIMIT 1) as breaking_until,
        (SELECT tier FROM pinned_news WHERE news_id = n.news_id AND manually_removed = false LIMIT 1) as pin_type,
        (SELECT position FROM pinned_news WHERE news_id = n.news_id AND manually_removed = false LIMIT 1) as pin_position,
        (SELECT ends_at FROM pinned_news WHERE news_id = n.news_id AND manually_removed = false LIMIT 1) as pin_until,
        (SELECT COUNT(*) > 0 FROM editor_pick WHERE news_id = n.news_id AND manually_removed = false) as editor_pick
      FROM news n
      LEFT JOIN admins a ON n.author_id = a.admin_id
      LEFT JOIN categories c ON n.category_id = c.category_id
      LEFT JOIN categories pc ON n.primary_category_id = pc.category_id
      LEFT JOIN news_categories nc ON n.news_id = nc.news_id
      ${whereClause}
      GROUP BY 
        n.news_id, n.title, n.excerpt, n.slug, n.image_url, n.status,
        n.views, n.likes_count, n.comments_count, n.share_count,
        n.published_at, n.created_at, n.updated_at,
        n.author_id, n.category_id, n.primary_category_id, n.tags, n.priority, n.reading_time,
        a.admin_id, a.first_name, a.last_name, a.email,
        c.category_id, c.name, c.slug,
        pc.category_id, pc.name
      ORDER BY n.${sortColumn} ${sortOrder}
      LIMIT $${paramIndex} OFFSET $${paramIndex + 1}
    `;

    queryParams.push(parseInt(limit), offset);

    const countQuery = `
      SELECT COUNT(DISTINCT n.news_id) as total
      FROM news n
      LEFT JOIN news_categories nc ON n.news_id = nc.news_id
      ${whereClause}
    `;

    const statsQuery = `
      SELECT 
        COUNT(*) as total_posts,
        COUNT(*) FILTER (WHERE status = 'published') as published_posts,
        COUNT(*) FILTER (WHERE status = 'draft') as draft_posts,
        COUNT(*) FILTER (WHERE status = 'archived') as archived_posts,
        COALESCE(SUM(views), 0) as total_views,
        COALESCE(SUM(likes_count), 0) as total_likes,
        COALESCE(SUM(comments_count), 0) as total_comments
      FROM news
    `;

    const newsResult = await pool.query(newsQuery, queryParams);
    const countResult = await pool.query(countQuery, queryParams.slice(0, -2));
    const statsResult = await pool.query(statsQuery);

    const totalNews = parseInt(countResult.rows[0].total);
    const totalPages = Math.ceil(totalNews / parseInt(limit));
    const currentPage = parseInt(page);

    const news = newsResult.rows.map(item => ({
      news_id: item.news_id,
      title: item.title,
      excerpt: item.excerpt,
      slug: item.slug,
      image_url: getImageUrl(item.image_url),
      status: item.status,
      views: item.views || 0,
      likes_count: item.likes_count || 0,
      comments_count: item.comments_count || 0,
      share_count: item.share_count || 0,
      published_at: item.published_at,
      created_at: item.created_at,
      updated_at: item.updated_at,
      author_id: item.author_id,
      first_name: item.first_name,
      last_name: item.last_name,
      author_email: item.author_email,
      author_name: `${item.first_name || 'Unknown'} ${item.last_name || 'Author'}`,
      category_id: item.category_id,
      category_name: item.category_name,
      category_slug: item.category_slug,
      primary_category_id: item.primary_category_id,
      primary_category_name: item.primary_category_name,
      category_ids: item.category_ids || [],
      tags: item.tags,
      priority: item.priority,
      reading_time: item.reading_time,
      promotions: {
        featured: item.featured_tier !== null,
        featured_tier: item.featured_tier,
        featured_until: item.featured_until,
        breaking: item.breaking_level !== null,
        breaking_level: item.breaking_level,
        breaking_until: item.breaking_until,
        pinned: item.pin_type !== null,
        pin_type: item.pin_type,
        pin_position: item.pin_position,
        pin_until: item.pin_until,
        editor_pick: item.editor_pick
      }
    }));

    return res.status(200).json({
      success: true,
      news,
      pagination: {
        current_page: currentPage,
        total_pages: totalPages,
        total_items: totalNews,
        items_per_page: parseInt(limit),
        has_next: currentPage < totalPages,
        has_prev: currentPage > 1
      },
      stats: statsResult.rows[0]
    });

  } catch (error) {
    console.error('[Admin] Retrieve news error:', error);
    console.error('[Admin] Error stack:', error.stack);
    
    return res.status(500).json({
      success: false,
      message: 'Failed to retrieve news',
      error: process.env.NODE_ENV === 'development' ? error.message : undefined
    });
  }
});

router.get('/:id', requireAdminAuth, async (req, res) => {
  try {
    const pool = getPool();
    const { id } = req.params;

    if (!id || isNaN(Number(id))) {
      return res.status(400).json({
        success: false,
        message: 'Valid news ID is required'
      });
    }

    const newsQuery = `
      SELECT 
        n.*,
        a.first_name,
        a.last_name,
        a.email as author_email,
        c.name as category_name,
        c.slug as category_slug,
        c.color as category_color,
        pc.name as primary_category_name,
        (SELECT tier FROM featured_news WHERE news_id = n.news_id AND manually_removed = false LIMIT 1) as featured_tier,
        (SELECT ends_at FROM featured_news WHERE news_id = n.news_id AND manually_removed = false LIMIT 1) as featured_until,
        (SELECT priority FROM breaking_news WHERE news_id = n.news_id AND manually_removed = false LIMIT 1) as breaking_level,
        (SELECT ends_at FROM breaking_news WHERE news_id = n.news_id AND manually_removed = false LIMIT 1) as breaking_until,
        (SELECT tier FROM pinned_news WHERE news_id = n.news_id AND manually_removed = false LIMIT 1) as pin_type,
        (SELECT position FROM pinned_news WHERE news_id = n.news_id AND manually_removed = false LIMIT 1) as pin_position,
        (SELECT ends_at FROM pinned_news WHERE news_id = n.news_id AND manually_removed = false LIMIT 1) as pin_until,
        (SELECT COUNT(*) > 0 FROM editor_pick WHERE news_id = n.news_id AND manually_removed = false) as editor_pick
      FROM news n
      LEFT JOIN admins a ON n.author_id = a.admin_id
      LEFT JOIN categories c ON n.category_id = c.category_id
      LEFT JOIN categories pc ON n.primary_category_id = pc.category_id
      WHERE n.news_id = $1
    `;

    const imagesQuery = `
      SELECT 
        image_id,
        image_url,
        image_caption,
        alt_text,
        display_order,
        is_featured,
        storage_provider,
        cloudflare_id,
        width,
        height,
        mime_type
      FROM news_images
      WHERE news_id = $1
      ORDER BY 
        CASE WHEN is_featured = true THEN 0 ELSE 1 END,
        display_order ASC NULLS LAST,
        image_id ASC
    `;

    const mediaQuery = `
      SELECT 
        social_media_id,
        platform,
        post_type,
        post_url,
        embed_code,
        embed_html,
        author_name,
        author_handle,
        caption,
        post_text,
        display_order,
        is_featured,
        show_full_embed,
        auto_embed,
        thumbnail_url,
        post_date,
        duration,
        likes_count,
        comments_count,
        views_count,
        oembed_url,
        oembed_data
      FROM news_social_media
      WHERE news_id = $1
      ORDER BY 
        CASE WHEN is_featured = true THEN 0 ELSE 1 END,
        display_order ASC NULLS LAST,
        social_media_id ASC
    `;

    const categoriesQuery = `
      SELECT 
        nc.category_id,
        nc.is_primary,
        c.name,
        c.slug,
        c.color
      FROM news_categories nc
      JOIN categories c ON nc.category_id = c.category_id
      WHERE nc.news_id = $1
      ORDER BY nc.is_primary DESC, c.name ASC
    `;

    const [newsResult, imagesResult, mediaResult, categoriesResult] = await Promise.all([
      pool.query(newsQuery, [id]),
      pool.query(imagesQuery, [id]),
      pool.query(mediaQuery, [id]),
      pool.query(categoriesQuery, [id])
    ]);

    if (newsResult.rows.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'News article not found'
      });
    }

    const article = newsResult.rows[0];

    const tagsArray = article.tags 
      ? article.tags.split(',').map(tag => tag.trim()).filter(Boolean)
      : [];

    const keywordsArray = article.seo_keywords
      ? article.seo_keywords.split(',').map(k => k.trim()).filter(Boolean)
      : [];

    const processedArticle = {
      ...article,
      author_name: `${article.first_name || 'Unknown'} ${article.last_name || 'Author'}`,
      tags: tagsArray,
      seo_keywords: keywordsArray,
      images: imagesResult.rows.map(img => ({
        image_id: img.image_id,
        image_url: getImageUrl(img.image_url),
        image_caption: img.image_caption,
        alt_text: img.alt_text,
        display_order: img.display_order,
        is_featured: img.is_featured,
        storage_provider: img.storage_provider,
        cloudflare_id: img.cloudflare_id,
        width: img.width,
        height: img.height,
        mime_type: img.mime_type
      })),
      media: mediaResult.rows,
      categories: categoriesResult.rows,
      promotions: {
        featured: article.featured_tier !== null,
        featured_tier: article.featured_tier,
        featured_until: article.featured_until,
        breaking: article.breaking_level !== null,
        breaking_level: article.breaking_level,
        breaking_until: article.breaking_until,
        pinned: article.pin_type !== null,
        pin_type: article.pin_type,
        pin_position: article.pin_position,
        pin_until: article.pin_until,
        editor_pick: article.editor_pick
      }
    };

    return res.status(200).json({
      success: true,
      article: processedArticle
    });

  } catch (error) {
    console.error('[Admin] Get single news error:', error);
    console.error('[Admin] Error stack:', error.stack);
    
    return res.status(500).json({
      success: false,
      message: 'Failed to retrieve news article',
      error: process.env.NODE_ENV === 'development' ? error.message : undefined
    });
  }
});

router.post('/:id/approval', requireAdminAuth, requireApprover, async (req, res) => {
  const pool = getPool();
  const client = await pool.connect();

  try {
    const { id } = req.params;
    const { action, comments } = req.body;
    const admin_id = req.adminId;

    if (!id || isNaN(Number(id))) {
      return res.status(400).json({
        success: false,
        message: 'Valid news ID is required'
      });
    }

    if (!['approve', 'disapprove'].includes(action)) {
      return res.status(400).json({
        success: false,
        message: 'Invalid action. Must be approve or disapprove'
      });
    }

    await client.query('BEGIN');

    const checkQuery = 'SELECT news_id, status FROM news WHERE news_id = $1';
    const checkResult = await client.query(checkQuery, [id]);

    if (checkResult.rows.length === 0) {
      await client.query('ROLLBACK');
      return res.status(404).json({
        success: false,
        message: 'News article not found'
      });
    }

    if (action === 'approve') {
      const updateQuery = `
        UPDATE news 
        SET status = 'published', 
            published_at = CASE WHEN published_at IS NULL THEN NOW() ELSE published_at END,
            updated_at = NOW()
        WHERE news_id = $1
        RETURNING news_id, status, published_at
      `;
      await client.query(updateQuery, [id]);

      await client.query(
        `UPDATE news_approval 
         SET workflow_status = 'approved',
             approved_by = $1,
             approved_at = NOW(),
             updated_at = NOW()
         WHERE news_id = $2`,
        [admin_id, id]
      );

      await client.query(
        `INSERT INTO news_approval_history (news_id, reviewer_id, action, comments, previous_status, new_status)
         VALUES ($1, $2, 'approve', $3, 'pending_approval', 'approved')`,
        [id, admin_id, comments || 'Approved']
      );

      await client.query('COMMIT');

      return res.status(200).json({
        success: true,
        message: 'Article approved and published successfully'
      });

    } else if (action === 'disapprove') {
      const updateQuery = `
        UPDATE news 
        SET status = 'draft',
            updated_at = NOW()
        WHERE news_id = $1
        RETURNING news_id, status
      `;
      await client.query(updateQuery, [id]);

      await client.query(
        `UPDATE news_approval 
         SET workflow_status = 'rejected',
             rejected_by = $1,
             rejected_at = NOW(),
             rejection_reason = $2,
             updated_at = NOW()
         WHERE news_id = $3`,
        [admin_id, comments || 'Rejected', id]
      );

      await client.query(
        `INSERT INTO news_approval_history (news_id, reviewer_id, action, comments, previous_status, new_status)
         VALUES ($1, $2, 'reject', $3, 'pending_approval', 'rejected')`,
        [id, admin_id, comments || 'Rejected']
      );

      await client.query('COMMIT');

      return res.status(200).json({
        success: true,
        message: 'Article disapproved and returned to draft'
      });
    }

  } catch (error) {
    await client.query('ROLLBACK');
    console.error('[Admin] Approval error:', error);
    console.error('[Admin] Error stack:', error.stack);
    
    return res.status(500).json({
      success: false,
      message: 'Failed to process approval',
      error: process.env.NODE_ENV === 'development' ? error.message : undefined
    });
  } finally {
    client.release();
  }
});

router.patch('/:id/status', requireAdminAuth, requireApprover, async (req, res) => {
  const pool = getPool();
  const client = await pool.connect();

  try {
    const { id } = req.params;
    const { status } = req.body;
    const admin_id = req.adminId;

    if (!id || isNaN(Number(id))) {
      return res.status(400).json({
        success: false,
        message: 'Valid news ID is required'
      });
    }

    const validStatuses = ['draft', 'published', 'archived', 'pending'];
    if (!validStatuses.includes(status)) {
      return res.status(400).json({
        success: false,
        message: 'Invalid status. Must be: draft, published, archived, or pending'
      });
    }

    await client.query('BEGIN');

    const checkQuery = 'SELECT news_id, status FROM news WHERE news_id = $1';
    const checkResult = await client.query(checkQuery, [id]);

    if (checkResult.rows.length === 0) {
      await client.query('ROLLBACK');
      return res.status(404).json({
        success: false,
        message: 'News article not found'
      });
    }

    const updateQuery = `
      UPDATE news 
      SET status = $1, 
          updated_at = NOW(),
          published_at = CASE 
            WHEN $1 = 'published' AND published_at IS NULL THEN NOW()
            ELSE published_at
          END,
          last_edited_by = $3,
          last_edited_at = NOW()
      WHERE news_id = $2
      RETURNING news_id, status, published_at
    `;

    const result = await client.query(updateQuery, [status, id, admin_id]);

    await client.query('COMMIT');

    return res.status(200).json({
      success: true,
      message: 'News status updated successfully',
      article: result.rows[0]
    });

  } catch (error) {
    await client.query('ROLLBACK');
    console.error('[Admin] Update status error:', error);
    console.error('[Admin] Error stack:', error.stack);
    
    return res.status(500).json({
      success: false,
      message: 'Failed to update news status',
      error: process.env.NODE_ENV === 'development' ? error.message : undefined
    });
  } finally {
    client.release();
  }
});

module.exports = router;