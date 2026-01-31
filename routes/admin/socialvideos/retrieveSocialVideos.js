const express = require('express');
const router = express.Router();
const { getPool } = require('../../../config/db');
const { FRONTEND_URL, CLIENT_URL, ADMIN_URL, API_DOMAIN, ALLOWED_ORIGINS, isOriginAllowed } = require('../../../config/frontendconfig');
const requireAdminAuth = require('../../../middleware/adminAuth');


router.get('/', requireAdminAuth, async (req, res) => {
  try {
    const pool = getPool();
    const {
      page = 1,
      limit = 20,
      search = '',
      status = '',
      platforms = '',
      is_live = '',
      order = 'DESC'
    } = req.query;

    const offset = (parseInt(page) - 1) * parseInt(limit);
    const orderBy = order === 'ASC' ? 'ASC' : 'DESC';

    let whereConditions = [];
    let queryParams = [];
    let paramIndex = 1;

    if (search) {
      whereConditions.push(`(title ILIKE $${paramIndex} OR description ILIKE $${paramIndex})`);
      queryParams.push(`%${search}%`);
      paramIndex++;
    }

    if (status) {
      whereConditions.push(`status = $${paramIndex}`);
      queryParams.push(status);
      paramIndex++;
    }

    if (platforms) {
      const platformArray = platforms.split(',').map(p => p.trim());
      whereConditions.push(`platform = ANY($${paramIndex}::varchar[])`);
      queryParams.push(platformArray);
      paramIndex++;
    }

    if (is_live !== '') {
      whereConditions.push(`is_live = $${paramIndex}`);
      queryParams.push(is_live === 'true');
      paramIndex++;
    }

    const whereClause = whereConditions.length > 0 
      ? `WHERE ${whereConditions.join(' AND ')}` 
      : '';

    const countQuery = `
      SELECT COUNT(*) as total
      FROM social_videos
      ${whereClause}
    `;
    const countResult = await pool.query(countQuery, queryParams);
    const totalVideos = parseInt(countResult.rows[0].total);
    const totalPages = Math.ceil(totalVideos / parseInt(limit));

    const videosQuery = `
      SELECT 
        video_id,
        title,
        description,
        video_url,
        platform,
        video_type,
        is_live,
        status,
        visibility,
        featured,
        thumbnail_url,
        views_count,
        likes_count,
        comments_count,
        channel_name,
        channel_id,
        created_at,
        updated_at
      FROM social_videos
      ${whereClause}
      ORDER BY created_at ${orderBy}
      LIMIT $${paramIndex} OFFSET $${paramIndex + 1}
    `;
    
    queryParams.push(parseInt(limit), offset);
    const videosResult = await pool.query(videosQuery, queryParams);

    const statsQuery = `
      SELECT 
        COUNT(*) as total_videos,
        COUNT(*) FILTER (WHERE status = 'published') as published_videos,
        COUNT(*) FILTER (WHERE status = 'draft') as draft_videos,
        COUNT(*) FILTER (WHERE is_live = true) as live_videos,
        COUNT(*) FILTER (WHERE featured = true) as featured_videos,
        COALESCE(SUM(views_count), 0) as total_views,
        COALESCE(SUM(likes_count), 0) as total_likes
      FROM social_videos
    `;
    const statsResult = await pool.query(statsQuery);

    return res.status(200).json({
      success: true,
      videos: videosResult.rows,
      stats: statsResult.rows[0],
      pagination: {
        current_page: parseInt(page),
        total_pages: totalPages,
        total_videos: totalVideos,
        has_next: parseInt(page) < totalPages,
        has_prev: parseInt(page) > 1
      }
    });

  } catch (error) {
    console.error('[Retrieve Social Videos] Error:', error);
    return res.status(500).json({
      success: false,
      message: 'Internal server error',
      error: error.message
    });
  }
});

module.exports = router;