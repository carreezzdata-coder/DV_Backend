// backend/routes/public/content.js
const express = require('express');
const { getPool } = require('../../config/db');

const { FRONTEND_URL, CLIENT_URL, ADMIN_URL, API_DOMAIN, ALLOWED_ORIGINS, isOriginAllowed } = require('../../config/frontendconfig');

const router = express.Router();

router.get('/homepage', async (req, res) => {
  try {
    const pool = getPool();

    const heroQuery = `
      SELECT
        n.news_id,
        n.title,
        n.excerpt,
        n.slug,
        n.image_url,
        n.published_at,
        n.reading_time,
        n.views,
        a.first_name,
        a.last_name,
        c.name as category_name,
        c.slug as category_slug,
        c.color as category_color
      FROM news n
      LEFT JOIN authors a ON n.author_id = a.author_id
      LEFT JOIN categories c ON n.category_id = c.category_id
      WHERE n.status = 'published'
        AND (n.is_breaking = true OR n.featured = true)
      ORDER BY
        CASE WHEN n.is_breaking = true THEN 1 ELSE 2 END,
        n.published_at DESC
      LIMIT 1
    `;

    const featuredQuery = `
      SELECT
        n.news_id,
        n.title,
        n.excerpt,
        n.slug,
        n.image_url,
        n.published_at,
        n.reading_time,
        n.views,
        a.first_name,
        a.last_name,
        c.name as category_name,
        c.slug as category_slug
      FROM news n
      LEFT JOIN authors a ON n.author_id = a.author_id
      LEFT JOIN categories c ON n.category_id = c.category_id
      WHERE n.status = 'published' AND n.featured = true
      ORDER BY n.published_at DESC
      LIMIT 6
    `;

    const latestQuery = `
      SELECT
        n.news_id,
        n.title,
        n.excerpt,
        n.slug,
        n.image_url,
        n.published_at,
        n.reading_time,
        n.views,
        a.first_name,
        a.last_name,
        c.name as category_name,
        c.slug as category_slug
      FROM news n
      LEFT JOIN authors a ON n.author_id = a.author_id
      LEFT JOIN categories c ON n.category_id = c.category_id
      WHERE n.status = 'published'
      ORDER BY n.published_at DESC
      LIMIT 12
    `;

    const categoriesQuery = `
      SELECT
        c.category_id,
        c.name,
        c.slug,
        c.color,
        c.icon,
        COUNT(n.news_id) as news_count
      FROM categories c
      LEFT JOIN news n ON c.category_id = n.category_id AND n.status = 'published'
      WHERE c.active = true
      GROUP BY c.category_id, c.name, c.slug, c.color, c.icon, c.order_index
      ORDER BY c.order_index ASC, c.name ASC
      LIMIT 8
    `;

    const [heroResult, featuredResult, latestResult, categoriesResult] = await Promise.all([
      pool.query(heroQuery),
      await pool.query(featuredQuery),
      await pool.query(latestQuery),
      await pool.query(categoriesQuery)
    ]);

    return res.json({
      success: true,
      hero: heroResult.rows[0] || null,
      featured: featuredResult.rows,
      latest: latestResult.rows,
      categories: categoriesResult.rows,
      last_updated: new Date().toISOString()
    });

  } catch (error) {
    console.error('Homepage content API error:', error);
    return res.status(500).json({
      success: false,
      message: 'Internal server error',
      hero: null,
      featured: [],
      latest: [],
      categories: []
    });
  }
});

router.get('/breaking', async (req, res) => {
  try {
    const pool = getPool();
    const limit = parseInt(req.query.limit || '5');

    const query = `
      SELECT
        n.news_id,
        n.title,
        n.excerpt,
        n.slug,
        n.published_at,
        n.breaking_priority,
        c.name as category_name,
        c.slug as category_slug,
        c.color as category_color
      FROM news n
      LEFT JOIN categories c ON n.category_id = c.category_id
      WHERE n.status = 'published'
        AND n.is_breaking = true
        AND n.published_at >= NOW() - INTERVAL '24 hours'
      ORDER BY
        CASE n.breaking_priority
          WHEN 'urgent' THEN 1
          WHEN 'high' THEN 2
          WHEN 'medium' THEN 3
          ELSE 4
        END,
        n.published_at DESC
      LIMIT $1
    `;

    const result = await pool.query(query, [limit]);

    return res.json({
      success: true,
      breaking_news: result.rows,
      total: result.rows.length,
      last_updated: new Date().toISOString()
    });

  } catch (error) {
    console.error('Breaking news content API error:', error);
    return res.json({
      success: true,
      breaking_news: [],
      total: 0,
      last_updated: new Date().toISOString()
    });
  }
});

router.get('/trending', async (req, res) => {
  try {
    const pool = getPool();
    const limit = parseInt(req.query.limit || '10');
    const days = parseInt(req.query.days || '7');

    const query = `
      SELECT
        n.news_id,
        n.title,
        n.excerpt,
        n.slug,
        n.image_url,
        n.published_at,
        n.views,
        n.likes_count,
        n.reading_time,
        (n.views * 0.7 + n.likes_count * 0.3) as trend_score,
        c.name as category_name,
        c.slug as category_slug,
        a.first_name,
        a.last_name
      FROM news n
      LEFT JOIN categories c ON n.category_id = c.category_id
      LEFT JOIN authors a ON n.author_id = a.author_id
      WHERE n.status = 'published'
        AND n.published_at >= NOW() - INTERVAL '${days} days'
        AND n.views > 0
      ORDER BY trend_score DESC, n.published_at DESC
      LIMIT $1
    `;

    const result = await pool.query(query, [limit]);

    return res.json({
      success: true,
      trending_news: result.rows,
      total: result.rows.length,
      period_days: days,
      last_updated: new Date().toISOString()
    });

  } catch (error) {
    console.error('Trending content API error:', error);
    return res.json({
      success: true,
      trending_news: [],
      total: 0,
      last_updated: new Date().toISOString()
    });
  }
});

router.get('/quick-reads', async (req, res) => {
  try {
    const pool = getPool();
    const limit = parseInt(req.query.limit || '8');
    const maxReadingTime = parseInt(req.query.max_time || '3');

    const query = `
      SELECT
        n.news_id,
        n.title,
        n.excerpt,
        n.slug,
        n.image_url,
        n.published_at,
        n.reading_time,
        n.views,
        c.name as category_name,
        c.slug as category_slug,
        a.first_name,
        a.last_name
      FROM news n
      LEFT JOIN categories c ON n.category_id = c.category_id
      LEFT JOIN authors a ON n.author_id = a.author_id
      WHERE n.status = 'published'
        AND n.reading_time <= $1
        AND n.reading_time > 0
      ORDER BY n.published_at DESC
      LIMIT $2
    `;

    const result = await pool.query(query, [maxReadingTime, limit]);

    return res.json({
      success: true,
      quick_reads: result.rows,
      total: result.rows.length,
      max_reading_time: maxReadingTime,
      last_updated: new Date().toISOString()
    });

  } catch (error) {
    console.error('Quick reads content API error:', error);
    return res.json({
      success: true,
      quick_reads: [],
      total: 0,
      last_updated: new Date().toISOString()
    });
  }
});

router.get('/categories', async (req, res) => {
  try {
    const pool = getPool();
    const includeNews = req.query.include_news === 'true';

    let query = `
      SELECT
        c.category_id,
        c.name,
        c.slug,
        c.description,
        c.color,
        c.icon,
        c.order_index,
        COUNT(n.news_id) as news_count
      FROM categories c
      LEFT JOIN news n ON c.category_id = n.category_id AND n.status = 'published'
      WHERE c.active = true
      GROUP BY c.category_id, c.name, c.slug, c.description, c.color, c.icon, c.order_index
      ORDER BY c.order_index ASC, c.name ASC
    `;

    const categoriesResult = await pool.query(query);
    let categories = categoriesResult.rows;

    if (includeNews) {
      for (let category of categories) {
        const newsQuery = `
          SELECT
            n.news_id,
            n.title,
            n.excerpt,
            n.slug,
            n.image_url,
            n.published_at,
            n.reading_time,
            n.views,
            a.first_name,
            a.last_name
          FROM news n
          LEFT JOIN authors a ON n.author_id = a.author_id
          WHERE n.category_id = $1 AND n.status = 'published'
          ORDER BY n.published_at DESC
          LIMIT 5
        `;

        const newsResult = await pool.query(newsQuery, [category.category_id]);
        category.recent_news = newsResult.rows;
      }
    }

    return res.json({
      success: true,
      categories: categories,
      total: categories.length,
      last_updated: new Date().toISOString()
    });

  } catch (error) {
    console.error('Categories content API error:', error);
    return res.json({
      success: true,
      categories: [],
      total: 0,
      last_updated: new Date().toISOString()
    });
  }
});

router.get('/category/:slug', async (req, res) => {
  try {
    const pool = getPool();
    const { slug } = req.params;
    const limit = parseInt(req.query.limit || '20');

    const categoryQuery = `
      SELECT
        category_id,
        name,
        slug,
        description,
        color,
        icon,
        (SELECT COUNT(*) FROM news WHERE category_id = c.category_id AND status = 'published') as total_news
      FROM categories c
      WHERE slug = $1 AND active = true
    `;

    const categoryResult = await pool.query(categoryQuery, [slug]);

    if (categoryResult.rows.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'Category not found'
      });
    }

    const category = categoryResult.rows[0];

    const newsQuery = `
      SELECT
        n.news_id,
        n.title,
        n.excerpt,
        n.slug,
        n.image_url,
        n.featured,
        n.published_at,
        n.reading_time,
        n.views,
        n.likes_count,
        a.first_name,
        a.last_name
      FROM news n
      LEFT JOIN authors a ON n.author_id = a.author_id
      WHERE n.category_id = $1 AND n.status = 'published'
      ORDER BY
        CASE WHEN n.featured = true THEN 1 ELSE 2 END,
        n.published_at DESC
      LIMIT $2
    `;

    const newsResult = await pool.query(newsQuery, [category.category_id, limit]);

    return res.json({
      success: true,
      category: category,
      news: newsResult.rows,
      total: newsResult.rows.length,
      last_updated: new Date().toISOString()
    });

  } catch (error) {
    console.error(`Category content API error for ${req.params.slug}:`, error);
    return res.status(500).json({
      success: false,
      message: 'Internal server error'
    });
  }
});

router.get('/search', async (req, res) => {
  try {
    const pool = getPool();
    const { q, category, limit = 20 } = req.query;

    if (!q || q.trim().length < 2) {
      return res.json({
        success: true,
        results: [],
        total: 0,
        query: q || ''
      });
    }

    let whereConditions = ['n.status = $1'];
    let queryParams = ['published'];
    let paramCount = 1;

    paramCount++;
    whereConditions.push(`(
      n.title ILIKE ${paramCount} OR
      n.content ILIKE ${paramCount} OR
      n.excerpt ILIKE ${paramCount} OR
      n.tags ILIKE ${paramCount}
    )`);
    queryParams.push(`%${q.trim()}%`);

    if (category && category !== 'all') {
      paramCount++;
      whereConditions.push(`c.slug = ${paramCount}`);
      queryParams.push(category);
    }

    const whereClause = whereConditions.join(' AND ');

    const searchQuery = `
      SELECT
        n.news_id,
        n.title,
        n.excerpt,
        n.slug,
        n.image_url,
        n.published_at,
        n.reading_time,
        n.views,
        a.first_name,
        a.last_name,
        c.name as category_name,
        c.slug as category_slug,
        ts_rank(
          to_tsvector('english', n.title || ' ' || n.content),
          plainto_tsquery('english', ${paramCount + 1})
        ) as relevance
      FROM news n
      LEFT JOIN authors a ON n.author_id = a.author_id
      LEFT JOIN categories c ON n.category_id = c.category_id
      WHERE ${whereClause}
      ORDER BY relevance DESC, n.published_at DESC
      LIMIT ${paramCount + 2}
    `;

    const result = await pool.query(searchQuery, [...queryParams, q.trim(), parseInt(limit)]);

    return res.json({
      success: true,
      results: result.rows,
      total: result.rows.length,
      query: q.trim(),
      category: category || 'all',
      last_updated: new Date().toISOString()
    });

  } catch (error) {
    console.error('Search content API error:', error);
    return res.json({
      success: true,
      results: [],
      total: 0,
      query: req.query.q || '',
      last_updated: new Date().toISOString()
    });
  }
});

router.get('/stats', async (req, res) => {
  try {
    const pool = getPool();

    const statsQuery = `
      SELECT
        COUNT(*) as total_articles,
        COUNT(CASE WHEN status = 'published' THEN 1 END) as published_articles,
        COUNT(CASE WHEN featured = true AND status = 'published' THEN 1 END) as featured_articles,
        COUNT(CASE WHEN is_breaking = true AND status = 'published' THEN 1 END) as breaking_articles,
        COALESCE(SUM(views), 0) as total_views,
        COALESCE(SUM(likes_count), 0) as total_likes,
        COUNT(CASE WHEN published_at >= NOW() - INTERVAL '24 hours' AND status = 'published' THEN 1 END) as articles_today,
        COUNT(CASE WHEN published_at >= NOW() - INTERVAL '7 days' AND status = 'published' THEN 1 END) as articles_this_week
      FROM news
    `;

    const categoriesQuery = `
      SELECT COUNT(*) as total_categories
      FROM categories WHERE active = true
    `;

    const [statsResult, categoriesResult] = await Promise.all([
      pool.query(statsQuery),
      pool.query(categoriesQuery)
    ]);

    const stats = statsResult.rows[0];
    const categoryStats = categoriesResult.rows[0];

    return res.json({
      success: true,
      stats: {
        total_articles: parseInt(stats.total_articles),
        published_articles: parseInt(stats.published_articles),
        featured_articles: parseInt(stats.featured_articles),
        breaking_articles: parseInt(stats.breaking_articles),
        total_views: parseInt(stats.total_views),
        total_likes: parseInt(stats.total_likes),
        articles_today: parseInt(stats.articles_today),
        articles_this_week: parseInt(stats.articles_this_week),
        total_categories: parseInt(categoryStats.total_categories)
      },
      last_updated: new Date().toISOString()
    });

  } catch (error) {
    console.error('Stats content API error:', error);
    return res.json({
      success: true,
      stats: {
        total_articles: 0,
        published_articles: 0,
        featured_articles: 0,
        breaking_articles: 0,
        total_views: 0,
        total_likes: 0,
        articles_today: 0,
        articles_this_week: 0,
        total_categories: 0
      },
      last_updated: new Date().toISOString()
    });
  }
});

module.exports = router;
