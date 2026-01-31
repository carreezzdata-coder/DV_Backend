// backend/routes/api/videos.js
const express = require('express');
const { FRONTEND_URL, CLIENT_URL, ADMIN_URL, API_DOMAIN, ALLOWED_ORIGINS, isOriginAllowed } = require('../../config/frontendconfig');
const router = express.Router();
const { getPool } = require('../../config/db');
const cloudflareService = require('../../services/cloudflareService');

const getImageUrl = (imageUrl) => {
  if (!imageUrl) return null;
  if (imageUrl.startsWith('http://') || imageUrl.startsWith('https://')) return imageUrl;
  const cleanPath = imageUrl.startsWith('/') ? imageUrl.substring(1) : imageUrl;
  if (cloudflareService.isEnabled()) {
    return cloudflareService.getPublicUrl(cleanPath);
  }
  const isProduction = process.env.NODE_ENV === 'production' || 
                       process.env.VERCEL_ENV === 'production' ||
                       process.env.RENDER === 'true';
  if (!isProduction) return `http://localhost:5000/${cleanPath}`;
  const r2Url = process.env.R2_PUBLIC_URL;
  if (r2Url) {
    const cleanUrl = r2Url.endsWith('/') ? r2Url.slice(0, -1) : r2Url;
    return `${cleanUrl}/${cleanPath}`;
  }
  return `https://www.dailyvaibe.com/${cleanPath}`;
};

/**
 * GET /api/videos/articles
 * Get articles with featured videos - Enhanced with better error handling and validation
 */
router.get('/articles', async (req, res) => {
  const pool = getPool();
  
  try {
    const { 
      limit = 12, 
      offset = 0, 
      platform,
      enabled = 'true' // New parameter for switch functionality
    } = req.query;

    // Validate parameters
    const validLimit = Math.min(Math.max(parseInt(limit, 10) || 12, 1), 100);
    const validOffset = Math.max(parseInt(offset, 10) || 0, 0);

    // If videos are disabled, return empty result
    if (enabled === 'false') {
      return res.json({
        success: true,
        articles: [],
        count: 0,
        total_videos: 0,
        disabled: true,
        meta: {
          limit: validLimit,
          offset: validOffset,
          platform: platform || 'all',
          timestamp: new Date().toISOString()
        }
      });
    }

    console.log(`[VIDEOS API] Fetching articles with videos:`, { 
      limit: validLimit, 
      offset: validOffset,
      platform: platform || 'all',
      enabled 
    });

    // Enhanced platform mapping with more platforms
    const platformMap = {
      'youtube': ['youtube_video', 'youtube_short', 'youtube_live'],
      'facebook': ['facebook_video', 'facebook_reel', 'facebook_live'],
      'instagram': ['instagram_video', 'instagram_reel', 'instagram_story'],
      'tiktok': ['tiktok_video', 'tiktok_reel', 'tiktok_live'],
      'twitter': ['twitter_video', 'x_video', 'twitter_live'],
      'x': ['twitter_video', 'x_video', 'twitter_live'],
      'vimeo': ['vimeo_video'],
      'dailymotion': ['dailymotion_video'],
      'twitch': ['twitch'],
      'rumble': ['rumble_video']
    };

    // Build platform filter
    let platformFilter = '';
    const queryParams = [validLimit, validOffset];
    let paramCounter = 3;

    if (platform && platform !== 'all') {
      const platformLower = platform.toLowerCase();
      const selectedPlatforms = platformMap[platformLower] || [platform];
      
      platformFilter = `AND sm.platform = ANY($${paramCounter})`;
      queryParams.push(selectedPlatforms);
      paramCounter++;
    }

    // Main query to fetch articles with videos
    const query = `
      SELECT DISTINCT
        n.news_id,
        n.title,
        n.slug,
        n.excerpt,
        n.image_url,
        n.views,
        n.likes_count,
        n.comments_count,
        n.reading_time,
        n.published_at,
        n.category_id,
        COALESCE(a.first_name, 'VybesTribe') as first_name,
        COALESCE(a.last_name, 'Editor') as last_name,
        c.name as category_name,
        c.slug as category_slug,
        c.color as category_color,
        c.icon as category_icon,
        -- Featured video (prioritized by display_order and featured flag)
        (
          SELECT json_build_object(
            'social_media_id', sm.social_media_id,
            'platform', sm.platform,
            'post_type', sm.post_type,
            'post_url', sm.post_url,
            'embed_code', COALESCE(sm.embed_code, sm.embed_html),
            'caption', COALESCE(sm.caption, sm.post_text),
            'thumbnail_url', sm.thumbnail_url,
            'duration', sm.duration,
            'likes_count', COALESCE(sm.likes_count, 0),
            'comments_count', COALESCE(sm.comments_count, 0),
            'views_count', COALESCE(sm.views_count, 0),
            'author_name', sm.author_name,
            'author_handle', sm.author_handle,
            'post_date', sm.post_date,
            'is_featured', sm.is_featured,
            'position', sm.display_order
          )
          FROM news_social_media sm
          WHERE sm.news_id = n.news_id
            AND sm.is_featured = true
            AND (
              sm.platform ILIKE ANY(ARRAY['%youtube%', '%vimeo%', '%dailymotion%', '%tiktok%', '%twitch%', '%rumble%'])
              OR sm.post_type ILIKE ANY(ARRAY['%video%', '%reel%', '%short%', '%live%'])
              OR sm.platform IN (
                'youtube_video', 'youtube_short', 'youtube_live',
                'twitter_video', 'x_video', 'twitter_live',
                'instagram_video', 'instagram_reel', 'instagram_story',
                'facebook_video', 'facebook_reel', 'facebook_live',
                'tiktok_video', 'tiktok_reel', 'tiktok_live',
                'vimeo_video', 'dailymotion_video', 'twitch', 'rumble_video'
              )
            )
            ${platformFilter}
          ORDER BY 
            sm.is_featured DESC,
            sm.display_order ASC NULLS LAST,
            sm.social_media_id ASC
          LIMIT 1
        ) as featured_video,
        -- Count of all videos in article
        (
          SELECT COUNT(*)
          FROM news_social_media sm2
          WHERE sm2.news_id = n.news_id
            AND sm2.is_featured = true
            AND (
              sm2.platform ILIKE ANY(ARRAY['%youtube%', '%vimeo%', '%dailymotion%', '%tiktok%', '%twitch%', '%rumble%'])
              OR sm2.post_type ILIKE ANY(ARRAY['%video%', '%reel%', '%short%', '%live%'])
              OR sm2.platform IN (
                'youtube_video', 'youtube_short', 'youtube_live',
                'twitter_video', 'x_video', 'twitter_live',
                'instagram_video', 'instagram_reel', 'instagram_story',
                'facebook_video', 'facebook_reel', 'facebook_live',
                'tiktok_video', 'tiktok_reel', 'tiktok_live',
                'vimeo_video', 'dailymotion_video', 'twitch', 'rumble_video'
              )
            )
            ${platformFilter.replace('sm.', 'sm2.')}
        ) as video_count
      FROM news n
      LEFT JOIN admins a ON n.author_id = a.admin_id
      LEFT JOIN categories c ON n.category_id = c.category_id
      WHERE n.status = 'published'
        AND EXISTS (
          SELECT 1
          FROM news_social_media sm
          WHERE sm.news_id = n.news_id
            AND sm.is_featured = true
            AND (
              sm.platform ILIKE ANY(ARRAY['%youtube%', '%vimeo%', '%dailymotion%', '%tiktok%', '%twitch%', '%rumble%'])
              OR sm.post_type ILIKE ANY(ARRAY['%video%', '%reel%', '%short%', '%live%'])
              OR sm.platform IN (
                'youtube_video', 'youtube_short', 'youtube_live',
                'twitter_video', 'x_video', 'twitter_live',
                'instagram_video', 'instagram_reel', 'instagram_story',
                'facebook_video', 'facebook_reel', 'facebook_live',
                'tiktok_video', 'tiktok_reel', 'tiktok_live',
                'vimeo_video', 'dailymotion_video', 'twitch', 'rumble_video'
              )
            )
            ${platformFilter}
        )
      ORDER BY 
        n.published_at DESC,
        n.news_id DESC
      LIMIT $1
      OFFSET $2
    `;

    const result = await pool.query(query, queryParams);

    console.log(`[VIDEOS API] Query executed: Found ${result.rows.length} articles`);

    // Process and validate results
    const articles = result.rows
      .filter(row => row.featured_video) // Only include articles with valid videos
      .map(row => {
        // Ensure all required fields have defaults
        const featured_video = row.featured_video || {};
        
        return {
          news_id: row.news_id,
          title: row.title || 'Untitled',
          slug: row.slug || '',
          excerpt: row.excerpt || '',
          image_url: row.image_url || '',
          views: parseInt(row.views, 10) || 0,
          likes_count: parseInt(row.likes_count, 10) || 0,
          comments_count: parseInt(row.comments_count, 10) || 0,
          reading_time: parseInt(row.reading_time, 10) || 3,
          published_at: row.published_at,
          author: {
            first_name: row.first_name || 'VybesTribe',
            last_name: row.last_name || 'Editor',
            full_name: `${row.first_name || 'VybesTribe'} ${row.last_name || 'Editor'}`
          },
          category: {
            id: row.category_id,
            name: row.category_name || 'News',
            slug: row.category_slug || 'news',
            color: row.category_color || '#3498db',
            icon: row.category_icon || '📰'
          },
          featured_video: {
            social_media_id: featured_video.social_media_id,
            platform: featured_video.platform || 'youtube',
            post_type: featured_video.post_type || 'video',
            post_url: featured_video.post_url || '',
            embed_code: featured_video.embed_code || '',
            caption: featured_video.caption || '',
            thumbnail_url: featured_video.thumbnail_url || '',
            duration: parseInt(featured_video.duration, 10) || 0,
            likes_count: parseInt(featured_video.likes_count, 10) || 0,
            comments_count: parseInt(featured_video.comments_count, 10) || 0,
            views_count: parseInt(featured_video.views_count, 10) || 0,
            author_name: featured_video.author_name || '',
            author_handle: featured_video.author_handle || '',
            post_date: featured_video.post_date || '',
            is_featured: featured_video.is_featured !== false,
            position: parseInt(featured_video.position, 10) || 0
          },
          video_count: parseInt(row.video_count, 10) || 1
        };
      });

    console.log(`[VIDEOS API] Processed ${articles.length} valid articles with videos`);

    // Get total count for pagination
    const countQuery = `
      SELECT COUNT(DISTINCT n.news_id) as total
      FROM news n
      WHERE n.status = 'published'
        AND EXISTS (
          SELECT 1
          FROM news_social_media sm
          WHERE sm.news_id = n.news_id
            AND sm.is_featured = true
            AND (
              sm.platform ILIKE ANY(ARRAY['%youtube%', '%vimeo%', '%dailymotion%', '%tiktok%', '%twitch%', '%rumble%'])
              OR sm.post_type ILIKE ANY(ARRAY['%video%', '%reel%', '%short%', '%live%'])
              OR sm.platform IN (
                'youtube_video', 'youtube_short', 'youtube_live',
                'twitter_video', 'x_video', 'twitter_live',
                'instagram_video', 'instagram_reel', 'instagram_story',
                'facebook_video', 'facebook_reel', 'facebook_live',
                'tiktok_video', 'tiktok_reel', 'tiktok_live',
                'vimeo_video', 'dailymotion_video', 'twitch', 'rumble_video'
              )
            )
            ${platformFilter}
        )
    `;

    const countResult = await pool.query(
      countQuery, 
      platform && platform !== 'all' ? [queryParams[2]] : []
    );
    const totalCount = parseInt(countResult.rows[0]?.total || 0, 10);

    // Calculate total videos across all articles
    const totalVideos = articles.reduce((sum, article) => sum + article.video_count, 0);

    // Set cache headers
    res.set({
      'Cache-Control': 'public, max-age=300, s-maxage=900, stale-while-revalidate=3600',
      'CDN-Cache-Control': 'max-age=900',
      'Vary': 'Accept-Encoding, Platform'
    });

    return res.json({
      success: true,
      articles,
      count: articles.length,
      total_count: totalCount,
      total_videos: totalVideos,
      meta: {
        limit: validLimit,
        offset: validOffset,
        platform: platform || 'all',
        enabled: enabled === 'true',
        timestamp: new Date().toISOString(),
        has_more: (validOffset + articles.length) < totalCount
      }
    });

  } catch (error) {
    console.error('[VIDEOS API] Error fetching articles:', error);
    console.error('[VIDEOS API] Stack:', error.stack);

    return res.status(500).json({
      success: false,
      message: 'Failed to fetch articles with videos',
      error: process.env.NODE_ENV === 'development' ? error.message : 'Internal server error',
      articles: [],
      count: 0,
      total_videos: 0,
      meta: {
        limit: parseInt(req.query.limit, 10) || 12,
        offset: parseInt(req.query.offset, 10) || 0,
        platform: req.query.platform || 'all',
        timestamp: new Date().toISOString()
      }
    });
  }
});

/**
 * GET /api/videos/platforms
 * Get available video platforms with counts - Enhanced
 */
router.get('/platforms', async (req, res) => {
  const pool = getPool();
  
  try {
    console.log('[VIDEOS API] Fetching platform statistics');

    const query = `
      SELECT 
        CASE 
          WHEN platform ILIKE '%youtube%' OR platform IN ('youtube_video', 'youtube_short', 'youtube_live') THEN 'youtube'
          WHEN platform ILIKE '%tiktok%' OR platform IN ('tiktok_video', 'tiktok_reel', 'tiktok_live') THEN 'tiktok'
          WHEN platform ILIKE '%instagram%' OR platform IN ('instagram_video', 'instagram_reel', 'instagram_story') THEN 'instagram'
          WHEN platform ILIKE '%facebook%' OR platform IN ('facebook_video', 'facebook_reel', 'facebook_live') THEN 'facebook'
          WHEN platform ILIKE '%twitter%' OR platform ILIKE '%x_%' OR platform IN ('twitter_video', 'x_video', 'twitter_live') THEN 'twitter'
          WHEN platform ILIKE '%vimeo%' OR platform = 'vimeo_video' THEN 'vimeo'
          WHEN platform ILIKE '%dailymotion%' OR platform = 'dailymotion_video' THEN 'dailymotion'
          WHEN platform ILIKE '%twitch%' OR platform = 'twitch' THEN 'twitch'
          WHEN platform ILIKE '%rumble%' OR platform = 'rumble_video' THEN 'rumble'
          ELSE 'other'
        END as platform_group,
        COUNT(DISTINCT news_id) as article_count,
        COUNT(*) as video_count,
        SUM(COALESCE(views_count, 0)) as total_views,
        SUM(COALESCE(likes_count, 0)) as total_likes
      FROM news_social_media
      WHERE is_featured = true
        AND (
          platform ILIKE ANY(ARRAY['%youtube%', '%vimeo%', '%dailymotion%', '%tiktok%', '%twitch%', '%rumble%'])
          OR post_type ILIKE ANY(ARRAY['%video%', '%reel%', '%short%', '%live%'])
          OR platform IN (
            'youtube_video', 'youtube_short', 'youtube_live',
            'twitter_video', 'x_video', 'twitter_live',
            'instagram_video', 'instagram_reel', 'instagram_story',
            'facebook_video', 'facebook_reel', 'facebook_live',
            'tiktok_video', 'tiktok_reel', 'tiktok_live',
            'vimeo_video', 'dailymotion_video', 'twitch', 'rumble_video'
          )
        )
      GROUP BY platform_group
      HAVING COUNT(*) > 0
      ORDER BY video_count DESC, platform_group ASC
    `;

    const result = await pool.query(query);

    console.log(`[VIDEOS API] Found ${result.rows.length} platforms with videos`);

    // Format platform data
    const platforms = result.rows.map(row => ({
      platform_group: row.platform_group,
      article_count: parseInt(row.article_count, 10) || 0,
      video_count: parseInt(row.video_count, 10) || 0,
      total_views: parseInt(row.total_views, 10) || 0,
      total_likes: parseInt(row.total_likes, 10) || 0
    }));

    res.set({
      'Cache-Control': 'public, max-age=3600, s-maxage=7200',
      'Vary': 'Accept-Encoding'
    });

    return res.json({
      success: true,
      platforms,
      total_platforms: platforms.length,
      timestamp: new Date().toISOString()
    });

  } catch (error) {
    console.error('[VIDEOS API] Error fetching platforms:', error);
    return res.status(500).json({
      success: false,
      message: 'Failed to fetch video platforms',
      error: process.env.NODE_ENV === 'development' ? error.message : 'Internal server error',
      platforms: [],
      timestamp: new Date().toISOString()
    });
  }
});

/**
 * GET /api/videos/stats
 * Get overall video statistics - NEW ENDPOINT
 */
router.get('/stats', async (req, res) => {
  const pool = getPool();
  
  try {
    const query = `
      SELECT 
        COUNT(DISTINCT news_id) as total_articles,
        COUNT(*) as total_videos,
        SUM(COALESCE(views_count, 0)) as total_views,
        SUM(COALESCE(likes_count, 0)) as total_likes,
        SUM(COALESCE(comments_count, 0)) as total_comments
      FROM news_social_media
      WHERE is_featured = true
        AND (
          platform ILIKE ANY(ARRAY['%youtube%', '%vimeo%', '%dailymotion%', '%tiktok%', '%twitch%', '%rumble%'])
          OR post_type ILIKE ANY(ARRAY['%video%', '%reel%', '%short%', '%live%'])
          OR platform IN (
            'youtube_video', 'youtube_short', 'youtube_live',
            'twitter_video', 'x_video', 'twitter_live',
            'instagram_video', 'instagram_reel', 'instagram_story',
            'facebook_video', 'facebook_reel', 'facebook_live',
            'tiktok_video', 'tiktok_reel', 'tiktok_live',
            'vimeo_video', 'dailymotion_video', 'twitch', 'rumble_video'
          )
        )
    `;

    const result = await pool.query(query);
    const stats = result.rows[0];

    res.set({
      'Cache-Control': 'public, max-age=600, s-maxage=1800'
    });

    return res.json({
      success: true,
      stats: {
        total_articles: parseInt(stats.total_articles, 10) || 0,
        total_videos: parseInt(stats.total_videos, 10) || 0,
        total_views: parseInt(stats.total_views, 10) || 0,
        total_likes: parseInt(stats.total_likes, 10) || 0,
        total_comments: parseInt(stats.total_comments, 10) || 0
      },
      timestamp: new Date().toISOString()
    });

  } catch (error) {
    console.error('[VIDEOS API] Error fetching stats:', error);
    return res.status(500).json({
      success: false,
      message: 'Failed to fetch video statistics',
      stats: {
        total_articles: 0,
        total_videos: 0,
        total_views: 0,
        total_likes: 0,
        total_comments: 0
      },
      timestamp: new Date().toISOString()
    });
  }
});

module.exports = router;