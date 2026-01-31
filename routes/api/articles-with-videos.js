const express = require('express');
const router = express.Router();
const { getPool } = require('../../config/db');

const { FRONTEND_URL, CLIENT_URL, ADMIN_URL, API_DOMAIN, ALLOWED_ORIGINS, isOriginAllowed } = require('../../config/frontendconfig');

router.get('/with-videos', async (req, res) => {
  try {
    const { limit = 10 } = req.query;
    const pool = getPool();

    console.log(`[API] Fetching articles with videos, limit: ${limit}`);

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
        n.status,
        COALESCE(a.first_name, 'VybesTribe') as first_name,
        COALESCE(a.last_name, 'Editor') as last_name,
        c.name as category_name,
        c.slug as category_slug,
        c.color as category_color,
        c.icon as category_icon,
        (SELECT tier FROM featured_news WHERE news_id = n.news_id AND manually_removed = false LIMIT 1) as featured_tier,
        (SELECT priority FROM breaking_news WHERE news_id = n.news_id AND manually_removed = false LIMIT 1) as breaking_level,
        (SELECT tier FROM pinned_news WHERE news_id = n.news_id AND manually_removed = false LIMIT 1) as pin_type,
        COALESCE(
          (
            SELECT json_agg(
              json_build_object(
                'social_media_id', sm.social_media_id,
                'platform', sm.platform,
                'post_type', sm.post_type,
                'post_url', sm.post_url,
                'embed_code', sm.embed_code,
                'embed_html', sm.embed_html,
                'author_name', sm.author_name,
                'author_handle', sm.author_handle,
                'caption', COALESCE(sm.caption, sm.post_text),
                'thumbnail_url', sm.thumbnail_url,
                'duration', sm.duration,
                'likes_count', sm.likes_count,
                'comments_count', sm.comments_count,
                'views_count', sm.views_count,
                'post_date', sm.post_date,
                'is_featured', sm.is_featured,
                'display_order', sm.display_order,
                'oembed_data', sm.oembed_data
              ) ORDER BY 
                CASE WHEN sm.is_featured = true THEN 0 ELSE 1 END,
                sm.display_order ASC NULLS LAST,
                sm.social_media_id ASC
            )
            FROM news_social_media sm
            WHERE sm.news_id = n.news_id
              AND (
                sm.platform ILIKE ANY(ARRAY['%youtube%', '%vimeo%', '%dailymotion%', '%tiktok%'])
                OR sm.post_type ILIKE ANY(ARRAY['%video%', '%reel%', '%short%'])
                OR (
                  (sm.platform = 'youtube_video' OR sm.platform = 'youtube_short')
                  OR (sm.platform = 'twitter_video' OR sm.platform = 'x_video')
                  OR (sm.platform = 'instagram_video' OR sm.platform = 'instagram_reel')
                  OR (sm.platform = 'facebook_video' OR sm.platform = 'facebook_reel')
                  OR (sm.platform = 'tiktok_video' OR sm.platform = 'tiktok_reel')
                )
              )
              AND sm.is_featured = true
          ),
          '[]'::json
        ) as media,
        (
          SELECT COUNT(*)
          FROM news_social_media sm2
          WHERE sm2.news_id = n.news_id
            AND (
              sm2.platform ILIKE ANY(ARRAY['%youtube%', '%vimeo%', '%dailymotion%', '%tiktok%'])
              OR sm2.post_type ILIKE ANY(ARRAY['%video%', '%reel%', '%short%'])
            )
        ) as video_count
      FROM news n
      LEFT JOIN admins a ON n.author_id = a.admin_id
      LEFT JOIN categories c ON n.category_id = c.category_id
      WHERE n.status = 'published'
        AND EXISTS (
          SELECT 1
          FROM news_social_media sm
          WHERE sm.news_id = n.news_id
            AND (
              sm.platform ILIKE ANY(ARRAY['%youtube%', '%vimeo%', '%dailymotion%', '%tiktok%'])
              OR sm.post_type ILIKE ANY(ARRAY['%video%', '%reel%', '%short%'])
              OR (
                (sm.platform = 'youtube_video' OR sm.platform = 'youtube_short')
                OR (sm.platform = 'twitter_video' OR sm.platform = 'x_video')
                OR (sm.platform = 'instagram_video' OR sm.platform = 'instagram_reel')
                OR (sm.platform = 'facebook_video' OR sm.platform = 'facebook_reel')
                OR (sm.platform = 'tiktok_video' OR sm.platform = 'tiktok_reel')
              )
            )
            AND sm.is_featured = true
        )
      ORDER BY 
        n.published_at DESC,
        n.news_id DESC
      LIMIT $1
    `;

    const result = await pool.query(query, [parseInt(limit, 10) || 10]);

    const articles = result.rows.map(row => {
      const featuredVideo = row.media && row.media.length > 0 
        ? row.media.find(m => m.is_featured) || row.media[0]
        : null;

      return {
        news_id: row.news_id,
        title: row.title,
        slug: row.slug,
        excerpt: row.excerpt,
        image_url: row.image_url,
        views: row.views,
        likes_count: row.likes_count,
        comments_count: row.comments_count,
        reading_time: row.reading_time,
        published_at: row.published_at,
        author: {
          first_name: row.first_name,
          last_name: row.last_name,
          full_name: `${row.first_name} ${row.last_name}`
        },
        category: {
          id: row.category_id,
          name: row.category_name,
          slug: row.category_slug,
          color: row.category_color,
          icon: row.category_icon
        },
        promotions: {
          featured: row.featured_tier !== null,
          featured_tier: row.featured_tier,
          breaking: row.breaking_level !== null,
          breaking_level: row.breaking_level,
          pinned: row.pin_type !== null,
          pin_type: row.pin_type
        },
        featured_video: featuredVideo ? {
          platform: featuredVideo.platform,
          post_type: featuredVideo.post_type,
          url: featuredVideo.post_url,
          embed_code: featuredVideo.embed_code || featuredVideo.embed_html,
          thumbnail: featuredVideo.thumbnail_url,
          caption: featuredVideo.caption,
          duration: featuredVideo.duration,
          stats: {
            likes: featuredVideo.likes_count,
            comments: featuredVideo.comments_count,
            views: featuredVideo.views_count
          }
        } : null,
        videos: row.media || [],
        video_count: parseInt(row.video_count, 10) || 0,
        stats: {
          views: row.views,
          likes: row.likes_count,
          comments: row.comments_count
        }
      };
    });

    res.set({
      'Cache-Control': 'public, max-age=300, s-maxage=900, stale-while-revalidate=3600',
      'CDN-Cache-Control': 'max-age=900',
      'Vary': 'Accept-Encoding',
      'X-Content-Type-Options': 'nosniff'
    });

    return res.json({
      success: true,
      articles,
      count: articles.length,
      total_videos: articles.reduce((sum, article) => sum + article.video_count, 0),
      meta: {
        limit: parseInt(limit, 10) || 10,
        timestamp: new Date().toISOString()
      }
    });

  } catch (error) {
    console.error('[API] Error fetching articles with videos:', error);
    console.error('[API] Stack:', error.stack);

    return res.status(500).json({
      success: false,
      message: 'Failed to fetch articles with videos',
      error: process.env.NODE_ENV === 'development' ? error.message : undefined,
      articles: []
    });
  }
});

router.get('/with-videos/platform/:platform', async (req, res) => {
  try {
    const { platform } = req.params;
    const { limit = 10 } = req.query;
    const pool = getPool();

    const platformMap = {
      'youtube': ['youtube_video', 'youtube_short'],
      'facebook': ['facebook_video', 'facebook_reel'],
      'instagram': ['instagram_video', 'instagram_reel'],
      'tiktok': ['tiktok_video', 'tiktok_reel'],
      'twitter': ['twitter_video', 'x_video'],
      'vimeo': ['vimeo'],
      'dailymotion': ['dailymotion']
    };

    const platformValues = platformMap[platform.toLowerCase()] || [platform];

    const query = `
      SELECT DISTINCT
        n.news_id,
        n.title,
        n.slug,
        n.excerpt,
        n.image_url,
        n.published_at,
        c.name as category_name,
        (SELECT tier FROM featured_news WHERE news_id = n.news_id AND manually_removed = false LIMIT 1) as featured_tier,
        (SELECT priority FROM breaking_news WHERE news_id = n.news_id AND manually_removed = false LIMIT 1) as breaking_level,
        (SELECT tier FROM pinned_news WHERE news_id = n.news_id AND manually_removed = false LIMIT 1) as pin_type,
        (
          SELECT json_agg(
            json_build_object(
              'platform', sm.platform,
              'post_url', sm.post_url,
              'thumbnail_url', sm.thumbnail_url,
              'caption', COALESCE(sm.caption, sm.post_text),
              'likes_count', sm.likes_count,
              'views_count', sm.views_count
            )
          )
          FROM news_social_media sm
          WHERE sm.news_id = n.news_id
            AND sm.platform = ANY($2::text[])
            AND sm.is_featured = true
        ) as platform_videos
      FROM news n
      LEFT JOIN categories c ON n.category_id = c.category_id
      WHERE n.status = 'published'
        AND EXISTS (
          SELECT 1
          FROM news_social_media sm
          WHERE sm.news_id = n.news_id
            AND sm.platform = ANY($2::text[])
            AND sm.is_featured = true
        )
      ORDER BY n.published_at DESC
      LIMIT $1
    `;

    const result = await pool.query(query, [parseInt(limit, 10) || 10, platformValues]);

    const articles = result.rows
      .filter(row => row.platform_videos && row.platform_videos.length > 0)
      .map(row => ({
        news_id: row.news_id,
        title: row.title,
        slug: row.slug,
        excerpt: row.excerpt,
        image_url: row.image_url,
        published_at: row.published_at,
        category_name: row.category_name,
        promotions: {
          featured: row.featured_tier !== null,
          featured_tier: row.featured_tier,
          breaking: row.breaking_level !== null,
          breaking_level: row.breaking_level,
          pinned: row.pin_type !== null,
          pin_type: row.pin_type
        },
        videos: row.platform_videos
      }));

    res.set({
      'Cache-Control': 'public, max-age=300, s-maxage=900, stale-while-revalidate=3600',
      'CDN-Cache-Control': 'max-age=900'
    });

    return res.json({
      success: true,
      platform,
      articles,
      count: articles.length
    });

  } catch (error) {
    console.error(`[API] Error fetching ${req.params.platform} videos:`, error);
    return res.status(500).json({
      success: false,
      message: `Failed to fetch ${req.params.platform} videos`,
      articles: []
    });
  }
});

router.get('/with-videos/stats', async (req, res) => {
  try {
    const pool = getPool();

    const statsQuery = `
      SELECT
        COUNT(DISTINCT n.news_id) as total_articles_with_videos,
        COUNT(sm.social_media_id) as total_videos,
        AVG(
          (SELECT COUNT(*)
           FROM news_social_media sm2
           WHERE sm2.news_id = n.news_id
             AND (sm2.platform ILIKE ANY(ARRAY['%youtube%', '%vimeo%', '%dailymotion%', '%tiktok%'])
                  OR sm2.post_type ILIKE ANY(ARRAY['%video%', '%reel%', '%short%']))
          )::numeric
        ) as avg_videos_per_article,
        json_object_agg(
          COALESCE(platform_group, 'other'),
          count
        ) as videos_by_platform
      FROM (
        SELECT 
          CASE 
            WHEN platform ILIKE '%youtube%' THEN 'youtube'
            WHEN platform ILIKE '%tiktok%' THEN 'tiktok'
            WHEN platform ILIKE '%instagram%' THEN 'instagram'
            WHEN platform ILIKE '%facebook%' THEN 'facebook'
            WHEN platform ILIKE '%twitter%' OR platform ILIKE '%x%' THEN 'twitter'
            WHEN platform ILIKE '%vimeo%' THEN 'vimeo'
            WHEN platform ILIKE '%dailymotion%' THEN 'dailymotion'
            ELSE 'other'
          END as platform_group,
          COUNT(*) as count
        FROM news_social_media sm
        WHERE sm.is_featured = true
          AND (sm.platform ILIKE ANY(ARRAY['%youtube%', '%vimeo%', '%dailymotion%', '%tiktok%'])
               OR sm.post_type ILIKE ANY(ARRAY['%video%', '%reel%', '%short%']))
        GROUP BY platform_group
      ) platform_counts
      CROSS JOIN (
        SELECT DISTINCT n.news_id
        FROM news n
        WHERE n.status = 'published'
          AND EXISTS (
            SELECT 1
            FROM news_social_media sm
            WHERE sm.news_id = n.news_id
              AND (sm.platform ILIKE ANY(ARRAY['%youtube%', '%vimeo%', '%dailymotion%', '%tiktok%'])
                   OR sm.post_type ILIKE ANY(ARRAY['%video%', '%reel%', '%short%']))
              AND sm.is_featured = true
          )
      ) n
      CROSS JOIN news_social_media sm ON sm.news_id = n.news_id
        AND sm.is_featured = true
        AND (sm.platform ILIKE ANY(ARRAY['%youtube%', '%vimeo%', '%dailymotion%', '%tiktok%'])
             OR sm.post_type ILIKE ANY(ARRAY['%video%', '%reel%', '%short%']))
      GROUP BY platform_counts.platform_group, platform_counts.count
    `;

    const result = await pool.query(statsQuery);

    return res.json({
      success: true,
      stats: result.rows[0] || {}
    });

  } catch (error) {
    console.error('[API] Error fetching video stats:', error);
    return res.status(500).json({
      success: false,
      message: 'Failed to fetch video statistics'
    });
  }
});

module.exports = router;