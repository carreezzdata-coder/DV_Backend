// routes/api/interactions.js
const express = require('express');
const { FRONTEND_URL, CLIENT_URL, ADMIN_URL, API_DOMAIN, ALLOWED_ORIGINS, isOriginAllowed } = require('../../config/frontendconfig');
const router = express.Router();
const { getPool } = require('../../config/db');

// Image URL handler for Cloudflare R2
const getImageUrl = (imageUrl) => {
  if (!imageUrl) return null;
  if (imageUrl.startsWith('http://') || imageUrl.startsWith('https://')) return imageUrl;
  const r2Url = process.env.R2_PUBLIC_URL;
  if (r2Url) {
    const cleanUrl = r2Url.endsWith('/') ? r2Url.slice(0, -1) : r2Url;
    const cleanImage = imageUrl.startsWith('/') ? imageUrl.substring(1) : imageUrl;
    return `${cleanUrl}/${cleanImage}`;
  }
  return imageUrl.startsWith('/') ? imageUrl : `/uploads/images/${imageUrl}`;
};

router.post('/track', async (req, res) => {
  // No cache for tracking
  res.set({
    'Cache-Control': 'no-store',
    'X-Content-Type-Options': 'nosniff',
    'X-Frame-Options': 'DENY'
  });

  try {
    const { news_id, session_id, interaction_type, county, town, metadata } = req.body;

    if (!news_id || !session_id || !interaction_type) {
      return res.status(400).json({
        success: false,
        error: 'Missing required fields: news_id, session_id, interaction_type'
      });
    }

    // Validate interaction type
    const validTypes = ['view', 'like', 'share', 'comment', 'bookmark', 'report'];
    if (!validTypes.includes(interaction_type)) {
      return res.status(400).json({
        success: false,
        error: `Invalid interaction_type. Must be one of: ${validTypes.join(', ')}`
      });
    }

    const pool = getPool();

    // Insert interaction tracking
    await pool.query(`
      INSERT INTO news_interactions (
        news_id, session_id, interaction_type, county, town, metadata, created_at
      )
      VALUES ($1, $2, $3, $4, $5, $6, NOW())
    `, [news_id, session_id, interaction_type, county || null, town || null, metadata ? JSON.stringify(metadata) : null]);

    // Update news counters based on interaction type
    if (interaction_type === 'like') {
      await pool.query(`
        UPDATE news
        SET likes_count = COALESCE(likes_count, 0) + 1, updated_at = NOW()
        WHERE news_id = $1
      `, [news_id]);
    } else if (interaction_type === 'share') {
      await pool.query(`
        UPDATE news
        SET share_count = COALESCE(share_count, 0) + 1, updated_at = NOW()
        WHERE news_id = $1
      `, [news_id]);
    } else if (interaction_type === 'view') {
      await pool.query(`
        UPDATE news
        SET views = COALESCE(views, 0) + 1, updated_at = NOW()
        WHERE news_id = $1
      `, [news_id]);
    } else if (interaction_type === 'comment') {
      await pool.query(`
        UPDATE news
        SET comments_count = COALESCE(comments_count, 0) + 1, updated_at = NOW()
        WHERE news_id = $1
      `, [news_id]);
    }

    // Get updated counts
    const countsResult = await pool.query(`
      SELECT views, likes_count, share_count, comments_count
      FROM news
      WHERE news_id = $1
    `, [news_id]);

    return res.json({
      success: true,
      message: 'Interaction tracked successfully',
      interaction_type,
      counts: countsResult.rows[0] || {}
    });
  } catch (error) {
    console.error('Track interaction error:', error);
    return res.status(500).json({
      success: false,
      error: 'Failed to track interaction'
    });
  }
});

router.get('/analytics/:news_id', async (req, res) => {
  // CDN cache for analytics
  res.set({
    'Cache-Control': 'public, max-age=300, s-maxage=600, stale-while-revalidate=3600',
    'CDN-Cache-Control': 'max-age=600',
    'Vary': 'Accept-Encoding',
    'X-Content-Type-Options': 'nosniff'
  });

  try {
    const { news_id } = req.params;
    const { period = '7' } = req.query;
    const pool = getPool();

    const days = Math.min(90, Math.max(1, parseInt(period)));

    // Get interaction breakdown
    const interactionsQuery = `
      SELECT
        interaction_type,
        COUNT(*) as count,
        COUNT(DISTINCT session_id) as unique_users,
        county,
        town
      FROM news_interactions
      WHERE news_id = $1
      AND created_at >= NOW() - INTERVAL '${days} days'
      GROUP BY interaction_type, county, town
      ORDER BY count DESC
    `;

    const interactions = await pool.query(interactionsQuery, [news_id]);

    // Get daily breakdown
    const dailyQuery = `
      SELECT
        DATE(created_at) as date,
        interaction_type,
        COUNT(*) as count
      FROM news_interactions
      WHERE news_id = $1
      AND created_at >= NOW() - INTERVAL '${days} days'
      GROUP BY DATE(created_at), interaction_type
      ORDER BY date DESC, interaction_type
    `;

    const daily = await pool.query(dailyQuery, [news_id]);

    // Get total stats
    const totalQuery = `
      SELECT
        views, likes_count, share_count, comments_count,
        title, slug, image_url, published_at
      FROM news
      WHERE news_id = $1
    `;

    const totals = await pool.query(totalQuery, [news_id]);

    // Calculate engagement score
    const article = totals.rows[0] || {};
    const engagementScore = (article.views || 0) +
                           (article.likes_count || 0) * 3 +
                           (article.share_count || 0) * 5 +
                           (article.comments_count || 0) * 2;

    return res.json({
      success: true,
      news_id: parseInt(news_id),
      period_days: days,
      article: {
        title: article.title,
        slug: article.slug,
        image_url: getImageUrl(article.image_url),
        published_at: article.published_at
      },
      totals: {
        views: article.views || 0,
        likes: article.likes_count || 0,
        shares: article.share_count || 0,
        comments: article.comments_count || 0,
        engagement_score: engagementScore
      },
      interactions_breakdown: interactions.rows,
      daily_breakdown: daily.rows
    });
  } catch (error) {
    console.error('Analytics error:', error);
    return res.status(500).json({
      success: false,
      error: 'Failed to fetch analytics'
    });
  }
});

router.get('/trending-interactions', async (req, res) => {
  // CDN cache for trending
  res.set({
    'Cache-Control': 'public, max-age=180, s-maxage=300, stale-while-revalidate=1800',
    'CDN-Cache-Control': 'max-age=300',
    'Vary': 'Accept-Encoding'
  });

  try {
    const { limit = '10', days = '7' } = req.query;
    const pool = getPool();

    const searchLimit = Math.min(50, Math.max(1, parseInt(limit)));
    const searchDays = Math.min(90, Math.max(1, parseInt(days)));

    const trendingQuery = `
      SELECT
        n.news_id,
        n.title,
        n.slug,
        n.image_url,
        n.excerpt,
        n.published_at,
        n.views,
        n.likes_count,
        n.share_count,
        n.comments_count,
        c.name as category_name,
        c.slug as category_slug,
        c.color as category_color,
        COUNT(DISTINCT ni.session_id) as unique_interactions,
        (n.views + n.likes_count * 3 + n.share_count * 5 + n.comments_count * 2) as engagement_score
      FROM news n
      LEFT JOIN news_interactions ni ON n.news_id = ni.news_id
        AND ni.created_at >= NOW() - INTERVAL '${searchDays} days'
      LEFT JOIN categories c ON n.category_id = c.category_id
      WHERE n.status = 'published'
      AND n.published_at >= NOW() - INTERVAL '${searchDays} days'
      GROUP BY n.news_id, n.title, n.slug, n.image_url, n.excerpt, n.published_at,
               n.views, n.likes_count, n.share_count, n.comments_count,
               c.name, c.slug, c.color
      ORDER BY engagement_score DESC, unique_interactions DESC
      LIMIT $1
    `;

    const trending = await pool.query(trendingQuery, [searchLimit]);

    const processedTrending = trending.rows.map(article => ({
      ...article,
      image_url: getImageUrl(article.image_url)
    }));

    return res.json({
      success: true,
      trending: processedTrending,
      total: processedTrending.length,
      period_days: searchDays
    });
  } catch (error) {
    console.error('Trending interactions error:', error);
    return res.status(500).json({
      success: false,
      error: 'Failed to fetch trending interactions'
    });
  }
});

router.get('/user-activity/:session_id', async (req, res) => {
  // Private cache for user activity
  res.set({
    'Cache-Control': 'private, max-age=60, must-revalidate',
    'X-Content-Type-Options': 'nosniff'
  });

  try {
    const { session_id } = req.params;
    const { limit = '20' } = req.query;
    const pool = getPool();

    const searchLimit = Math.min(100, Math.max(1, parseInt(limit)));

    const activityQuery = `
      SELECT
        ni.interaction_id,
        ni.news_id,
        ni.interaction_type,
        ni.created_at,
        n.title,
        n.slug,
        n.image_url,
        n.excerpt,
        c.name as category_name,
        c.slug as category_slug
      FROM news_interactions ni
      JOIN news n ON ni.news_id = n.news_id
      LEFT JOIN categories c ON n.category_id = c.category_id
      WHERE ni.session_id = $1
      AND n.status = 'published'
      ORDER BY ni.created_at DESC
      LIMIT $2
    `;

    const activity = await pool.query(activityQuery, [session_id, searchLimit]);

    const processedActivity = activity.rows.map(item => ({
      ...item,
      image_url: getImageUrl(item.image_url)
    }));

    // Get summary stats
    const summaryQuery = `
      SELECT
        COUNT(*) FILTER (WHERE interaction_type = 'view') as total_views,
        COUNT(*) FILTER (WHERE interaction_type = 'like') as total_likes,
        COUNT(*) FILTER (WHERE interaction_type = 'share') as total_shares,
        COUNT(*) FILTER (WHERE interaction_type = 'comment') as total_comments,
        COUNT(*) FILTER (WHERE interaction_type = 'bookmark') as total_bookmarks,
        COUNT(DISTINCT news_id) as unique_articles
      FROM news_interactions
      WHERE session_id = $1
    `;

    const summary = await pool.query(summaryQuery, [session_id]);

    return res.json({
      success: true,
      activity: processedActivity,
      summary: summary.rows[0] || {},
      total: processedActivity.length
    });
  } catch (error) {
    console.error('User activity error:', error);
    return res.status(500).json({
      success: false,
      error: 'Failed to fetch user activity'
    });
  }
});

// Reserved for future social app integration
router.post('/comment', async (req, res) => {
  res.set('Cache-Control', 'no-store');

  return res.status(501).json({
    success: false,
    message: 'Comments feature is reserved for social app integration',
    note: 'This endpoint will be activated when bridging to the social app'
  });
});

// Reserved for future social app integration
router.post('/moderate', async (req, res) => {
  res.set('Cache-Control', 'no-store');

  return res.status(501).json({
    success: false,
    message: 'Moderation feature is reserved for social app integration',
    note: 'This endpoint will be activated when bridging to the social app'
  });
});

module.exports = router;
