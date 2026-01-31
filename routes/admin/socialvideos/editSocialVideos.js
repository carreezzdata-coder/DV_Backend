const express = require('express');
const router = express.Router();
const { getPool } = require('../../../config/db');
const { FRONTEND_URL, CLIENT_URL, ADMIN_URL, API_DOMAIN, ALLOWED_ORIGINS, isOriginAllowed } = require('../../../config/frontendconfig');
const requireAdminAuth = require('../../../middleware/adminAuth');
const { requireEditor } = require('../../../middleware/rolePermissions');

router.put('/:video_id', requireAdminAuth, requireEditor, async (req, res) => {
  const pool = getPool();
  const client = await pool.connect();

  try {
    await client.query('BEGIN');

    const { video_id } = req.params;
    const { admin_id, title, description, video_type, status, visibility, featured, display_order, tags, categories } = req.body;

    if (!video_id || isNaN(Number(video_id))) {
      await client.query('ROLLBACK');
      return res.status(400).json({
        success: false,
        message: 'Valid video ID is required'
      });
    }

    if (!admin_id) {
      await client.query('ROLLBACK');
      return res.status(400).json({
        success: false,
        message: 'Admin ID is required'
      });
    }

    const checkQuery = 'SELECT * FROM social_videos WHERE video_id = $1';
    const checkResult = await client.query(checkQuery, [video_id]);

    if (checkResult.rows.length === 0) {
      await client.query('ROLLBACK');
      return res.status(404).json({
        success: false,
        message: 'Video not found'
      });
    }

    const updateQuery = `
      UPDATE social_videos 
      SET 
        title = COALESCE($1, title),
        description = COALESCE($2, description),
        video_type = COALESCE($3, video_type),
        status = COALESCE($4, status),
        visibility = COALESCE($5, visibility),
        featured = COALESCE($6, featured),
        display_order = COALESCE($7, display_order),
        tags = COALESCE($8, tags),
        categories = COALESCE($9, categories),
        updated_at = CURRENT_TIMESTAMP
      WHERE video_id = $10
      RETURNING *
    `;

    const values = [
      title || null,
      description !== undefined ? description : null,
      video_type || null,
      status || null,
      visibility || null,
      featured !== undefined ? featured : null,
      display_order !== undefined ? parseInt(display_order) : null,
      tags || null,
      categories || null,
      video_id
    ];

    const result = await client.query(updateQuery, values);
    const video = result.rows[0];

    const ip = req.headers['x-forwarded-for'] || req.headers['x-real-ip'] || req.ip || 'unknown';

    await client.query(
      `INSERT INTO admin_activity_log (admin_id, action, target_type, target_id, details, ip_address) 
       VALUES ($1, $2, $3, $4, $5, $6)`,
      [admin_id, 'update_social_video', 'social_videos', video_id, `Updated social video: ${video.title}`, ip]
    );

    await client.query('COMMIT');

    return res.status(200).json({
      success: true,
      message: 'Video updated successfully',
      video: video,
      admin_url: `${ADMIN_URL}/admin/social-videos/edit/${video_id}`
    });

  } catch (error) {
    await client.query('ROLLBACK');
    console.error('[Social Videos PUT] Error:', error);
    return res.status(500).json({
      success: false,
      message: 'Internal server error',
      error: error.message
    });
  } finally {
    client.release();
  }
});

module.exports = router;