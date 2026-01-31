// routes/public/news.js
const express = require('express');
const { FRONTEND_URL, CLIENT_URL, ADMIN_URL, API_DOMAIN, ALLOWED_ORIGINS, isOriginAllowed } = require('../../config/frontendconfig');
const router = express.Router();

let dbModule = null;
let dbError = null;

try {
  dbModule = require('../../config/db');
} catch (error) {
  dbError = error.message;
  console.error('Database module load error:', error.message);
}

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

const getNewsQuery = (whereClause = '', orderBy = 'n.published_at DESC', limit = null) => {
  let query = `
    SELECT
      n.news_id, n.title, n.content, n.excerpt, n.slug, n.category_id,
      n.status, n.priority, n.tags, n.reading_time, n.views, n.likes_count,
      n.comments_count, n.featured, n.youtube_url, n.youtube_id,
      n.youtube_title, n.youtube_thumbnail, n.published_at, n.created_at,
      n.updated_at, n.image_url, COALESCE(n.share_count, 0) as share_count,
      n.meta_description, n.seo_keywords,
      c.name as category_name, c.slug as category_slug, c.color as category_color, c.icon as category_icon,
      COALESCE(u.first_name, 'VybesTribe') as first_name,
      COALESCE(u.last_name, 'Editor') as last_name,
      u.email as author_email
    FROM news n
    LEFT JOIN categories c ON n.category_id = c.category_id
    LEFT JOIN admins u ON n.author_id = u.admin_id
  `;

  if (whereClause) query += ` WHERE ${whereClause}`;
  query += ` ORDER BY ${orderBy}`;
  if (limit) query += ` LIMIT ${limit}`;

  return query;
};

router.get('/test', (req, res) => {
  res.set('Cache-Control', 'no-store');

  res.json({
    success: true,
    message: 'News API is working',
    database_status: dbModule ? 'connected' : 'error',
    cloudflare_r2: !!process.env.R2_PUBLIC_URL,
    r2_url: process.env.R2_PUBLIC_URL || 'not configured'
  });
});

router.get('/article/:slug', async (req, res) => {
  // CDN cache for article pages
  res.set({
    'Cache-Control': 'public, max-age=300, s-maxage=900, stale-while-revalidate=3600',
    'CDN-Cache-Control': 'max-age=900',
    'Vary': 'Accept-Encoding',
    'X-Content-Type-Options': 'nosniff',
    'X-Frame-Options': 'SAMEORIGIN'
  });

  if (!dbModule) {
    return res.status(500).json({ success: false, error: dbError });
  }

  try {
    const { getPool } = dbModule;
    const pool = getPool();
    const { slug } = req.params;

    const articleQuery = getNewsQuery(`n.slug = $1 AND n.status = 'published'`);
    const articleResult = await pool.query(articleQuery, [slug]);

    if (articleResult.rows.length === 0) {
      return res.status(404).json({ success: false, message: 'Article not found' });
    }

    const article = articleResult.rows[0];

    const relatedQuery = getNewsQuery(
      `n.category_id = $1 AND n.news_id != $2 AND n.status = 'published'`,
      'n.published_at DESC',
      10
    );

    const relatedResult = await pool.query(relatedQuery, [article.category_id, article.news_id]);

    try {
      await pool.query('UPDATE news SET views = COALESCE(views, 0) + 1 WHERE news_id = $1', [article.news_id]);
      article.views = (article.views || 0) + 1;
    } catch (viewError) {
      console.error('Error updating view count:', viewError);
    }

    const processedArticle = {
      ...article,
      image_url: getImageUrl(article.image_url),
      tags: article.tags ? article.tags.split(',').map(t => t.trim()).filter(Boolean) : [],
      seo_keywords: article.seo_keywords ? article.seo_keywords.split(',').map(k => k.trim()).filter(Boolean) : [],
      youtube: article.youtube_id ? {
        url: article.youtube_url,
        id: article.youtube_id,
        title: article.youtube_title,
        thumbnail: article.youtube_thumbnail
      } : null,
      author: {
        first_name: article.first_name,
        last_name: article.last_name,
        full_name: `${article.first_name} ${article.last_name}`,
        email: article.author_email
      },
      category: {
        name: article.category_name,
        slug: article.category_slug,
        color: article.category_color,
        icon: article.category_icon
      }
    };

    const processedRelated = relatedResult.rows.map(rel => ({
      ...rel,
      image_url: getImageUrl(rel.image_url),
      tags: rel.tags ? rel.tags.split(',').map(t => t.trim()).filter(Boolean) : []
    }));

    res.json({
      success: true,
      article: processedArticle,
      related_articles: processedRelated,
      comments: []
    });

  } catch (error) {
    console.error('Article fetch error:', error);
    res.status(500).json({ success: false, message: 'Failed to fetch article', error: error.message });
  }
});

router.get('/', async (req, res) => {
  // CDN cache for news listings
  res.set({
    'Cache-Control': 'public, max-age=120, s-maxage=300, stale-while-revalidate=1800',
    'CDN-Cache-Control': 'max-age=300',
    'Vary': 'Accept-Encoding',
    'X-Content-Type-Options': 'nosniff'
  });

  if (!dbModule) {
    return res.status(500).json({ success: false, news: [], error: dbError });
  }

  try {
    const { getPool } = dbModule;
    const pool = getPool();

    const page = Math.max(1, parseInt(req.query.page || '1'));
    const limit = Math.min(50, Math.max(1, parseInt(req.query.limit || '20')));
    const offset = (page - 1) * limit;
    const search = req.query.search?.trim();
    const status = req.query.status || 'published';
    const sort = req.query.sort || 'published_at';
    const order = (req.query.order || 'DESC').toUpperCase();

    let whereConditions = [`n.status = $1`];
    let queryParams = [status];
    let paramIndex = 1;

    if (search) {
      paramIndex++;
      whereConditions.push(`(
        n.title ILIKE $${paramIndex} OR
        n.content ILIKE $${paramIndex} OR
        n.excerpt ILIKE $${paramIndex} OR
        n.tags ILIKE $${paramIndex}
      )`);
      queryParams.push(`%${search}%`);
    }

    const whereClause = whereConditions.join(' AND ');

    const countQuery = `SELECT COUNT(*) as total FROM news n WHERE ${whereClause}`;
    const countResult = await pool.query(countQuery, queryParams);
    const totalNews = parseInt(countResult.rows[0].total);

    const newsQuery = getNewsQuery(whereClause, `n.${sort} ${order}`) + ` OFFSET $${paramIndex + 1} LIMIT $${paramIndex + 2}`;
    queryParams.push(offset, limit);

    const newsResult = await pool.query(newsQuery, queryParams);

    const processedNews = newsResult.rows.map(article => ({
      ...article,
      image_url: getImageUrl(article.image_url),
      tags: article.tags ? article.tags.split(',').map(t => t.trim()).filter(Boolean) : [],
      youtube: article.youtube_id ? {
        id: article.youtube_id,
        thumbnail: article.youtube_thumbnail
      } : null
    }));

    const totalPages = Math.ceil(totalNews / limit);

    res.json({
      success: true,
      news: processedNews,
      pagination: {
        current_page: page,
        per_page: limit,
        total_news: totalNews,
        total_pages: totalPages,
        has_next: page < totalPages,
        has_prev: page > 1
      }
    });

  } catch (error) {
    console.error('News fetch error:', error);
    res.status(500).json({ success: false, message: 'Failed to fetch news', error: error.message, news: [] });
  }
});

router.get('/categories', async (req, res) => {
  // Long CDN cache for categories
  res.set({
    'Cache-Control': 'public, max-age=600, s-maxage=1800, stale-while-revalidate=86400',
    'CDN-Cache-Control': 'max-age=1800',
    'Vary': 'Accept-Encoding'
  });

  if (!dbModule) {
    return res.status(500).json({ success: false, categories: [], error: dbError });
  }

  try {
    const { getPool } = dbModule;
    const pool = getPool();

    const result = await pool.query(`
      SELECT
        c.category_id, c.name, c.slug, c.description, c.color, c.icon, c.active,
        COALESCE(c.order_index, 999) as order_index,
        COUNT(n.news_id) as news_count,
        MAX(n.published_at) as latest_article
      FROM categories c
      LEFT JOIN news n ON c.category_id = n.category_id AND n.status = 'published'
      WHERE c.active = true
      GROUP BY c.category_id, c.name, c.slug, c.description, c.color, c.icon, c.active, c.order_index
      ORDER BY COALESCE(c.order_index, 999) ASC, c.name ASC
    `);

    res.json({ success: true, categories: result.rows });

  } catch (error) {
    console.error('Categories error:', error);
    res.status(500).json({ success: false, message: 'Failed to fetch categories', error: error.message, categories: [] });
  }
});

router.get('/category/:slug', async (req, res) => {
  // CDN cache for category pages
  res.set({
    'Cache-Control': 'public, max-age=180, s-maxage=300, stale-while-revalidate=1800',
    'CDN-Cache-Control': 'max-age=300',
    'Vary': 'Accept-Encoding',
    'X-Content-Type-Options': 'nosniff'
  });

  if (!dbModule) {
    return res.status(500).json({ success: false, news: [], error: dbError });
  }

  try {
    const { getPool } = dbModule;
    const pool = getPool();
    const { slug } = req.params;
    const page = Math.max(1, parseInt(req.query.page || '1'));
    const limit = Math.min(50, Math.max(1, parseInt(req.query.limit || '20')));
    const offset = (page - 1) * limit;

    const categoryResult = await pool.query(
      `SELECT category_id, name, slug, description, color, icon, active
       FROM categories WHERE slug = $1 AND active = true`,
      [slug]
    );

    if (categoryResult.rows.length === 0) {
      return res.status(404).json({ success: false, message: `Category '${slug}' not found`, news: [] });
    }

    const category = categoryResult.rows[0];

    const countResult = await pool.query(
      `SELECT COUNT(*) as total FROM news n WHERE n.category_id = $1 AND n.status = 'published'`,
      [category.category_id]
    );

    const totalNews = parseInt(countResult.rows[0].total);

    const newsQuery = getNewsQuery(
      `n.category_id = $1 AND n.status = 'published'`,
      'n.published_at DESC'
    ) + ` OFFSET $2 LIMIT $3`;

    const newsResult = await pool.query(newsQuery, [category.category_id, offset, limit]);

    const processedNews = newsResult.rows.map(article => ({
      ...article,
      image_url: getImageUrl(article.image_url),
      tags: article.tags ? article.tags.split(',').map(t => t.trim()).filter(Boolean) : []
    }));

    const totalPages = Math.ceil(totalNews / limit);

    res.json({
      success: true,
      category: category,
      news: processedNews,
      pagination: {
        current_page: page,
        per_page: limit,
        total_news: totalNews,
        total_pages: totalPages,
        has_next: page < totalPages,
        has_prev: page > 1
      }
    });

  } catch (error) {
    console.error('Category news error:', error);
    res.status(500).json({ success: false, message: 'Failed to fetch category news', error: error.message, news: [] });
  }
});

router.get('/breaking', async (req, res) => {
  // Short CDN cache for breaking news (changes frequently)
  res.set({
    'Cache-Control': 'public, max-age=60, s-maxage=120, stale-while-revalidate=600',
    'CDN-Cache-Control': 'max-age=120',
    'Vary': 'Accept-Encoding',
    'X-Content-Type-Options': 'nosniff'
  });

  if (!dbModule) {
    return res.status(500).json({ success: false, breaking_news: [], error: dbError });
  }

  try {
    const { getPool } = dbModule;
    const pool = getPool();
    const limit = Math.min(50, Math.max(1, parseInt(req.query.limit || '10')));

    const newsQuery = getNewsQuery(
      `n.status = 'published' AND (n.priority = 'high' OR n.featured = true)`,
      'n.published_at DESC',
      limit
    );

    const result = await pool.query(newsQuery);

    const processedNews = result.rows.map(article => ({
      ...article,
      image_url: getImageUrl(article.image_url),
      tags: article.tags ? article.tags.split(',').map(t => t.trim()).filter(Boolean) : []
    }));

    res.json({ success: true, breaking_news: processedNews, news: processedNews, total: processedNews.length });

  } catch (error) {
    console.error('Breaking news error:', error);
    res.status(500).json({ success: false, message: 'Failed to fetch breaking news', error: error.message, breaking_news: [] });
  }
});

router.get('/featured', async (req, res) => {
  // Medium CDN cache for featured news
  res.set({
    'Cache-Control': 'public, max-age=180, s-maxage=360, stale-while-revalidate=1800',
    'CDN-Cache-Control': 'max-age=360',
    'Vary': 'Accept-Encoding'
  });

  if (!dbModule) {
    return res.status(500).json({ success: false, featured_news: [], error: dbError });
  }

  try {
    const { getPool } = dbModule;
    const pool = getPool();
    const limit = Math.min(50, Math.max(1, parseInt(req.query.limit || '10')));

    const newsQuery = getNewsQuery(
      `n.status = 'published' AND n.featured = true`,
      'n.published_at DESC',
      limit
    );

    const result = await pool.query(newsQuery);

    const processedNews = result.rows.map(article => ({
      ...article,
      image_url: getImageUrl(article.image_url),
      tags: article.tags ? article.tags.split(',').map(t => t.trim()).filter(Boolean) : []
    }));

    res.json({ success: true, featured_news: processedNews, news: processedNews, total: processedNews.length });

  } catch (error) {
    console.error('Featured news error:', error);
    res.status(500).json({ success: false, message: 'Failed to fetch featured news', error: error.message, featured_news: [] });
  }
});

router.get('/trending', async (req, res) => {
  // Short CDN cache for trending (updates frequently)
  res.set({
    'Cache-Control': 'public, max-age=120, s-maxage=240, stale-while-revalidate=1800',
    'CDN-Cache-Control': 'max-age=240',
    'Vary': 'Accept-Encoding'
  });

  if (!dbModule) {
    return res.status(500).json({ success: false, trending_news: [], error: dbError });
  }

  try {
    const { getPool } = dbModule;
    const pool = getPool();
    const limit = Math.min(50, Math.max(1, parseInt(req.query.limit || '10')));
    const days = Math.min(30, Math.max(1, parseInt(req.query.days || '7')));

    const newsQuery = getNewsQuery(
      `n.status = 'published' AND n.published_at >= NOW() - INTERVAL '${days} days'`,
      '(COALESCE(n.views, 0) + COALESCE(n.likes_count, 0) * 3 + COALESCE(n.share_count, 0) * 5) DESC, n.published_at DESC',
      limit
    );

    const result = await pool.query(newsQuery);

    const processedNews = result.rows.map(article => ({
      ...article,
      image_url: getImageUrl(article.image_url),
      tags: article.tags ? article.tags.split(',').map(t => t.trim()).filter(Boolean) : [],
      engagement_score: (article.views || 0) + (article.likes_count || 0) * 3 + (article.share_count || 0) * 5
    }));

    res.json({
      success: true,
      trending_news: processedNews,
      news: processedNews,
      total: processedNews.length,
      period_days: days
    });

  } catch (error) {
    console.error('Trending news error:', error);
    res.status(500).json({ success: false, message: 'Failed to fetch trending news', error: error.message, trending_news: [] });
  }
});

router.post('/view/:id', async (req, res) => {
  // No cache for tracking
  res.set('Cache-Control', 'no-store');

  if (!dbModule) {
    return res.json({ success: false, message: 'Database not available' });
  }

  try {
    const { getPool } = dbModule;
    const pool = getPool();
    const { id } = req.params;

    const result = await pool.query(
      'UPDATE news SET views = COALESCE(views, 0) + 1 WHERE news_id = $1 RETURNING views',
      [parseInt(id)]
    );

    res.json({ success: true, views: result.rows[0]?.views || 0, message: 'View tracked' });

  } catch (error) {
    console.error('View tracking error:', error);
    res.json({ success: false, message: 'Failed to track view' });
  }
});

router.post('/like/:id', async (req, res) => {
  // No cache for interactions
  res.set('Cache-Control', 'no-store');

  if (!dbModule) {
    return res.json({ success: false, message: 'Database not available' });
  }

  try {
    const { getPool } = dbModule;
    const pool = getPool();
    const { id } = req.params;

    const result = await pool.query(
      'UPDATE news SET likes_count = COALESCE(likes_count, 0) + 1 WHERE news_id = $1 RETURNING likes_count',
      [parseInt(id)]
    );

    res.json({ success: true, likes_count: result.rows[0]?.likes_count || 0, message: 'Article liked' });

  } catch (error) {
    console.error('Like error:', error);
    res.json({ success: false, message: 'Failed to like article' });
  }
});

router.post('/share/:id', async (req, res) => {
  // No cache for tracking
  res.set('Cache-Control', 'no-store');

  if (!dbModule) {
    return res.json({ success: false, message: 'Database not available' });
  }

  try {
    const { getPool } = dbModule;
    const pool = getPool();
    const { id } = req.params;

    const result = await pool.query(
      'UPDATE news SET share_count = COALESCE(share_count, 0) + 1 WHERE news_id = $1 RETURNING share_count',
      [parseInt(id)]
    );

    res.json({ success: true, share_count: result.rows[0]?.share_count || 0, message: 'Article shared' });

  } catch (error) {
    console.error('Share error:', error);
    res.json({ success: false, message: 'Failed to share article' });
  }
});

module.exports = router;
