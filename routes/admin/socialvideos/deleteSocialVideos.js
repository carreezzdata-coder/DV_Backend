const express = require('express');
const router = express.Router();
const { getPool } = require('../../../config/db');
const { FRONTEND_URL, CLIENT_URL, ADMIN_URL, API_DOMAIN, ALLOWED_ORIGINS, isOriginAllowed } = require('../../../config/frontendconfig');
const requireAdminAuth = require('../../../middleware/adminAuth');
const { requireEditor } = require('../../../middleware/rolePermissions');

router.delete('/:video_id', requireAdminAuth, requireEditor, async (req, res) => {
  const pool = getPool();
  const client = await pool.connect();

  try {
    await client.query('BEGIN');

    const { video_id } = req.params;
    const { admin_id } = req.body;

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

    const video = checkResult.rows[0];

    await client.query('DELETE FROM live_broadcast_sessions WHERE video_id = $1', [video_id]);
    await client.query('DELETE FROM social_videos_analytics WHERE video_id = $1', [video_id]);
    await client.query('DELETE FROM social_videos WHERE video_id = $1', [video_id]);

    const ip = req.headers['x-forwarded-for'] || req.headers['x-real-ip'] || req.ip || 'unknown';

    await client.query(
      `INSERT INTO admin_activity_log (admin_id, action, target_type, target_id, details, ip_address) 
       VALUES ($1, $2, $3, $4, $5, $6)`,
      [admin_id, 'delete_social_video', 'social_videos', video_id, `Deleted social video: ${video.title}`, ip]
    );

    await client.query('COMMIT');

    return res.status(200).json({
      success: true,
      message: 'Video deleted successfully'
    });

  } catch (error) {
    await client.query('ROLLBACK');
    console.error('[Social Videos DELETE] Error:', error);
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