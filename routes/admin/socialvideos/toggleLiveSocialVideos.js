const express = require('express');
const router = express.Router();
const { getPool } = require('../../../config/db');
const { FRONTEND_URL, CLIENT_URL, ADMIN_URL, API_DOMAIN, ALLOWED_ORIGINS, isOriginAllowed } = require('../../../config/frontendconfig');
const requireAdminAuth = require('../../../middleware/adminAuth');
const { requireEditor } = require('../../../middleware/rolePermissions');

router.post('/:video_id/toggle-live', requireAdminAuth, requireEditor, async (req, res) => {
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
    const newLiveState = !video.is_live;
    const now = new Date();
    const ip = req.headers['x-forwarded-for'] || req.headers['x-real-ip'] || req.ip || 'unknown';
    const userAgent = req.headers['user-agent'] || 'unknown';

    let updateQuery;
    let action;

    if (newLiveState) {
      updateQuery = `
        UPDATE social_videos 
        SET 
          is_live = true,
          status = 'live',
          live_started_at = $1,
          live_ended_at = NULL,
          updated_at = $1
        WHERE video_id = $2
        RETURNING *
      `;
      action = 'started_live';

      await client.query(
        `INSERT INTO live_broadcast_sessions (
          video_id, session_started_at, broadcast_metadata
        ) VALUES ($1, $2, $3)`,
        [video_id, now, JSON.stringify({ user_agent: userAgent, ip: ip })]
      );
    } else {
      updateQuery = `
        UPDATE social_videos 
        SET 
          is_live = false,
          status = 'ended',
          live_ended_at = $1,
          updated_at = $1
        WHERE video_id = $2
        RETURNING *
      `;
      action = 'ended_live';

      await client.query(
        `UPDATE live_broadcast_sessions 
         SET session_ended_at = $1 
         WHERE video_id = $2 AND session_ended_at IS NULL`,
        [now, video_id]
      );
    }

    const result = await client.query(updateQuery, [now, video_id]);
    const updatedVideo = result.rows[0];

    await client.query(
      `INSERT INTO admin_activity_log (admin_id, action, target_type, target_id, details, ip_address) 
       VALUES ($1, $2, $3, $4, $5, $6)`,
      [admin_id, action, 'social_videos', video_id, `${newLiveState ? 'Started' : 'Ended'} live stream: ${video.title}`, ip]
    );

    await client.query('COMMIT');

    return res.status(200).json({
      success: true,
      message: newLiveState ? 'Live stream started' : 'Live stream ended',
      video: updatedVideo,
      action: action,
      admin_url: `${ADMIN_URL}/admin/social-videos/edit/${video_id}`
    });

  } catch (error) {
    await client.query('ROLLBACK');
    console.error('[Social Videos Toggle Live] Error:', error);
    return res.status(500).json({
      success: false,
      message: 'Internal server error',
      error: error.message
    });
  } finally {
    client.release();
  }
});

router.get('/:video_id/live-status', async (req, res) => {
  try {
    const pool = getPool();
    const { video_id } = req.params;

    if (!video_id || isNaN(Number(video_id))) {
      return res.status(400).json({
        success: false,
        message: 'Valid video ID is required'
      });
    }

    const query = `
      SELECT 
        sv.video_id,
        sv.is_live,
        sv.status,
        sv.live_started_at,
        sv.live_ended_at,
        sv.concurrent_viewers,
        sv.peak_viewers,
        lbs.session_id,
        lbs.session_started_at,
        lbs.session_ended_at,
        lbs.peak_viewers as session_peak_viewers
      FROM social_videos sv
      LEFT JOIN live_broadcast_sessions lbs ON sv.video_id = lbs.video_id 
        AND lbs.session_ended_at IS NULL
      WHERE sv.video_id = $1
    `;

    const result = await pool.query(query, [video_id]);

    if (result.rows.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'Video not found'
      });
    }

    return res.status(200).json({
      success: true,
      status: result.rows[0]
    });

  } catch (error) {
    console.error('[Social Videos Live Status] Error:', error);
    return res.status(500).json({
      success: false,
      message: 'Internal server error',
      error: error.message
    });
  }
});

module.exports = router;