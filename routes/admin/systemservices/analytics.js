
const express = require('express');
const router = express.Router();
const { getPool } = require('../../../config/db');

const { FRONTEND_URL, CLIENT_URL, ADMIN_URL, API_DOMAIN, ALLOWED_ORIGINS, isOriginAllowed } = require('../../../config/frontendconfig');

const getTimeRangeFilter = (range) => {
  switch (range) {
    case '7d': return "created_at >= NOW() - INTERVAL '7 days'";
    case '30d': return "created_at >= NOW() - INTERVAL '30 days'";
    case '90d': return "created_at >= NOW() - INTERVAL '90 days'";
    default: return '1=1';
  }
};

router.get('/overview', async (req, res) => {
  try {
    const pool = getPool();
    const { range = '30d' } = req.query;
    const timeFilter = getTimeRangeFilter(range);

    const [articleStats, userStats, engagementStats] = await Promise.all([
      pool.query(`
        SELECT 
          COUNT(*) as total_articles,
          COUNT(*) FILTER (WHERE status = 'published') as published_articles,
          COUNT(*) FILTER (WHERE status = 'draft') as draft_articles,
          COALESCE(SUM(views), 0) as total_views,
          COALESCE(SUM(likes_count), 0) as total_likes,
          COALESCE(SUM(comments_count), 0) as total_comments,
          COALESCE(SUM(share_count), 0) as total_shares
        FROM news
        WHERE ${timeFilter}
      `),
      
      pool.query(`
        SELECT 
          COUNT(*) as total_users,
          COUNT(*) FILTER (WHERE created_at >= NOW() - INTERVAL '30 days') as active_users_30d,
          COUNT(*) FILTER (WHERE ${timeFilter}) as new_users_30d
        FROM users
      `),
      
      pool.query(`
        SELECT 
          CASE 
            WHEN SUM(views) > 0 
            THEN ((SUM(likes_count) + SUM(comments_count) + SUM(share_count))::FLOAT / SUM(views)) * 100
            ELSE 0 
          END as avg_engagement_rate
        FROM news
        WHERE ${timeFilter} AND status = 'published'
      `)
    ]);

    return res.json({
      success: true,
      data: {
        ...articleStats.rows[0],
        ...userStats.rows[0],
        avg_engagement_rate: parseFloat(engagementStats.rows[0].avg_engagement_rate || 0)
      }
    });

  } catch (error) {
    console.error('Analytics overview error:', error);
    return res.status(500).json({
      success: false,
      error: 'Failed to fetch overview analytics',
      message: error.message
    });
  }
});

router.get('/content', async (req, res) => {
  try {
    const pool = getPool();
    const { range = '30d' } = req.query;
    const timeFilter = getTimeRangeFilter(range);

    const [topArticles, categoryStats, authorStats] = await Promise.all([
      pool.query(`
        SELECT 
          news_id,
          title,
          views,
          likes_count,
          comments_count,
          share_count,
          CASE 
            WHEN views > 0 
            THEN ((likes_count + comments_count + share_count)::FLOAT / views) * 100
            ELSE 0 
          END as engagement_rate
        FROM news
        WHERE ${timeFilter} AND status = 'published'
        ORDER BY views DESC
        LIMIT 10
      `),
      
      pool.query(`
        SELECT 
          c.name as category_name,
          COUNT(n.news_id) as article_count,
          COALESCE(SUM(n.views), 0) as total_views
        FROM categories c
        LEFT JOIN news n ON c.category_id = n.category_id
        WHERE n.${timeFilter}
        GROUP BY c.category_id, c.name
        ORDER BY total_views DESC
        LIMIT 10
      `),
      
      pool.query(`
        SELECT 
          CONCAT(a.first_name, ' ', a.last_name) as author_name,
          COUNT(n.news_id) as article_count,
          COALESCE(SUM(n.views), 0) as total_views
        FROM admins a
        LEFT JOIN news n ON a.admin_id = n.author_id
        WHERE n.${timeFilter}
        GROUP BY a.admin_id, a.first_name, a.last_name
        ORDER BY total_views DESC
        LIMIT 10
      `)
    ]);

    return res.json({
      success: true,
      data: {
        top_articles: topArticles.rows,
        articles_by_category: categoryStats.rows,
        articles_by_author: authorStats.rows
      }
    });

  } catch (error) {
    console.error('Analytics content error:', error);
    return res.status(500).json({
      success: false,
      error: 'Failed to fetch content analytics',
      message: error.message
    });
  }
});

router.get('/users', async (req, res) => {
  try {
    const pool = getPool();
    const { range = '30d' } = req.query;
    const days = range === '7d' ? 7 : range === '30d' ? 30 : range === '90d' ? 90 : 365;

    const [registrationTrend, topEngaged] = await Promise.all([
      pool.query(`
        SELECT 
          DATE(created_at) as date,
          COUNT(*) as count
        FROM users
        WHERE created_at >= NOW() - INTERVAL '${days} days'
        GROUP BY DATE(created_at)
        ORDER BY date ASC
      `),
      
      pool.query(`
        SELECT 
          u.user_id,
          CONCAT(u.first_name, ' ', u.last_name) as full_name,
          COUNT(ui.interaction_id) as interaction_count
        FROM users u
        LEFT JOIN user_interactions ui ON u.user_id = ui.user_id
        WHERE ui.created_at >= NOW() - INTERVAL '${days} days'
        GROUP BY u.user_id, u.first_name, u.last_name
        ORDER BY interaction_count DESC
        LIMIT 10
      `)
    ]);

    return res.json({
      success: true,
      data: {
        registration_trend: registrationTrend.rows,
        user_activity: [],
        top_engaged_users: topEngaged.rows
      }
    });

  } catch (error) {
    console.error('Analytics users error:', error);
    return res.status(500).json({
      success: false,
      error: 'Failed to fetch user analytics',
      message: error.message
    });
  }
});

router.get('/engagement', async (req, res) => {
  try {
    const pool = getPool();
    const { range = '30d' } = req.query;
    const days = range === '7d' ? 7 : range === '30d' ? 30 : range === '90d' ? 90 : 365;

    const dailyMetrics = await pool.query(`
      SELECT 
        DATE(created_at) as date,
        COALESCE(SUM(views), 0) as views,
        COALESCE(SUM(likes_count), 0) as likes,
        COALESCE(SUM(comments_count), 0) as comments,
        COALESCE(SUM(share_count), 0) as shares
      FROM news
      WHERE created_at >= NOW() - INTERVAL '${days} days'
      GROUP BY DATE(created_at)
      ORDER BY date ASC
    `);

    return res.json({
      success: true,
      data: {
        daily_metrics: dailyMetrics.rows,
        engagement_by_time: []
      }
    });

  } catch (error) {
    console.error('Analytics engagement error:', error);
    return res.status(500).json({
      success: false,
      error: 'Failed to fetch engagement analytics',
      message: error.message
    });
  }
});

module.exports = router;
