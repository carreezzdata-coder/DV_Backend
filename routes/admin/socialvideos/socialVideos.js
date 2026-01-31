const express = require('express');
const router = express.Router();
const { getPool } = require('../../../config/db');
const { upload, processUploadedFiles } = require('../../../config/imagesUpload');
const { FRONTEND_URL, CLIENT_URL, ADMIN_URL, API_DOMAIN, ALLOWED_ORIGINS, isOriginAllowed } = require('../../../config/frontendconfig');
const requireAdminAuth = require('../../../middleware/adminAuth');
const { requirePublisher, canPublishDirectly } = require('../../../middleware/rolePermissions');

const extractPlatformFromUrl = (url) => {
  if (!url) return 'youtube';
  const lowerUrl = url.toLowerCase();
  
  if (lowerUrl.includes('youtube.com') || lowerUrl.includes('youtu.be')) {
    return lowerUrl.includes('/live') ? 'youtube_live' : 'youtube';
  }
  if (lowerUrl.includes('facebook.com') || lowerUrl.includes('fb.watch')) {
    return lowerUrl.includes('/live') ? 'facebook_live' : 'facebook';
  }
  if (lowerUrl.includes('instagram.com')) {
    return lowerUrl.includes('/live') ? 'instagram_live' : 'instagram';
  }
  if (lowerUrl.includes('twitter.com') || lowerUrl.includes('x.com')) {
    return lowerUrl.includes('/spaces') ? 'twitter_live' : 'twitter';
  }
  if (lowerUrl.includes('tiktok.com')) {
    return lowerUrl.includes('/live') ? 'tiktok_live' : 'tiktok';
  }
  if (lowerUrl.includes('twitch.tv')) return 'twitch';
  if (lowerUrl.includes('vimeo.com')) return 'vimeo';
  if (lowerUrl.includes('dailymotion.com')) return 'dailymotion';
  
  return 'youtube';
};

const extractVideoId = (url, platform) => {
  if (!url) return null;
  
  try {
    if (platform.includes('youtube')) {
      const match = url.match(/(?:youtube\.com\/(?:[^\/]+\/.+\/|(?:v|e(?:mbed)?)\/|.*[?&]v=)|youtu\.be\/)([^"&?\/\s]{11})/);
      return match ? match[1] : null;
    }
    
    if (platform.includes('facebook')) {
      const match = url.match(/facebook\.com\/([^\/]+)\/videos\/(\d+)/);
      return match ? match[2] : null;
    }
    
    if (platform.includes('instagram')) {
      const match = url.match(/instagram\.com\/(?:p|reel|tv)\/([A-Za-z0-9_-]+)/);
      return match ? match[1] : null;
    }
    
    if (platform.includes('tiktok')) {
      const match = url.match(/tiktok\.com\/@[^\/]+\/video\/(\d+)/);
      return match ? match[1] : null;
    }
    
    return null;
  } catch (error) {
    console.error('[socialVideos] extractVideoId error:', error);
    return null;
  }
};

router.post('/', requireAdminAuth, requirePublisher, upload.single('thumbnail'), async (req, res) => {
  const pool = getPool();
  const client = await pool.connect();

  try {
    await client.query('BEGIN');

    const {
      title,
      description,
      video_url,
      video_type,
      is_live,
      status,
      visibility,
      featured,
      display_order,
      tags,
      categories,
      auto_refresh,
      scheduled_start_time,
      admin_id
    } = req.body;

    if (!admin_id) {
      await client.query('ROLLBACK');
      return res.status(400).json({
        success: false,
        message: 'Admin ID is required'
      });
    }

    if (!title || !video_url) {
      await client.query('ROLLBACK');
      return res.status(400).json({
        success: false,
        message: 'Title and video URL are required'
      });
    }

    const platform = extractPlatformFromUrl(video_url);
    const video_id_external = extractVideoId(video_url, platform);

    let thumbnail_url = null;
    if (req.file) {
      const processed = await processUploadedFiles([req.file]);
      if (processed && processed.length > 0) {
        thumbnail_url = processed[0].url;
      }
    }

    const userRole = req.userRole;
    const canPublish = canPublishDirectly(userRole);
    const requestedStatus = status || 'draft';
    const finalStatus = (!canPublish && requestedStatus === 'published') ? 'pending' : requestedStatus;

    const insertQuery = `
      INSERT INTO social_videos (
        title, description, platform, video_type, video_url, video_id_external,
        thumbnail_url, is_live, status, visibility, featured, display_order,
        tags, categories, auto_refresh, scheduled_start_time, created_by
      ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14, $15, $16, $17)
      RETURNING *
    `;

    const values = [
      title,
      description || '',
      platform,
      video_type || 'recorded',
      video_url,
      video_id_external,
      thumbnail_url,
      is_live === 'true' || is_live === true,
      finalStatus,
      visibility || 'public',
      featured === 'true' || featured === true,
      display_order ? parseInt(display_order) : 0,
      tags ? JSON.parse(tags) : [],
      categories ? JSON.parse(categories) : [],
      auto_refresh !== 'false',
      scheduled_start_time || null,
      parseInt(admin_id)
    ];

    const result = await client.query(insertQuery, values);
    const video = result.rows[0];

    const ip = req.headers['x-forwarded-for'] || req.headers['x-real-ip'] || req.ip || 'unknown';

    await client.query(
      `INSERT INTO admin_activity_log (admin_id, action, target_type, target_id, details, ip_address) 
       VALUES ($1, $2, $3, $4, $5, $6)`,
      [admin_id, 'create_social_video', 'social_videos', video.video_id, `Created social video: ${title}`, ip]
    );

    await client.query('COMMIT');

    return res.status(201).json({
      success: true,
      message: canPublish && requestedStatus === 'published'
        ? 'Video published successfully'
        : !canPublish && requestedStatus === 'published'
          ? 'Video submitted for approval'
          : 'Video created successfully',
      video: video,
      requires_approval: !canPublish && requestedStatus === 'published',
      admin_url: `${ADMIN_URL}/admin/social-videos/edit/${video.video_id}`
    });

  } catch (error) {
    await client.query('ROLLBACK');
    console.error('[Social Videos POST] Error:', error);
    return res.status(500).json({
      success: false,
      message: 'Internal server error',
      error: error.message
    });
  } finally {
    client.release();
  }
});

router.get('/:video_id', requireAdminAuth, async (req, res) => {
  try {
    const pool = getPool();
    const { video_id } = req.params;
    
    if (!video_id || isNaN(Number(video_id))) {
      return res.status(400).json({
        success: false,
        message: 'Valid video ID is required'
      });
    }

    const query = 'SELECT * FROM social_videos WHERE video_id = $1';
    const result = await pool.query(query, [video_id]);
    
    if (result.rows.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'Video not found'
      });
    }

    return res.status(200).json({
      success: true,
      video: result.rows[0],
      message: 'Video fetched successfully',
      admin_url: `${ADMIN_URL}/admin/social-videos/edit/${video_id}`
    });

  } catch (error) {
    console.error('[Social Videos GET by ID] Error:', error);
    return res.status(500).json({ 
      success: false, 
      message: 'Internal server error', 
      error: error.message 
    });
  }
});

module.exports = router;