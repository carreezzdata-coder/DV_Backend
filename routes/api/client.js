const express = require('express');
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
  const isProduction = process.env.NODE_ENV === 'production' || process.env.VERCEL_ENV === 'production' || process.env.RENDER === 'true';
  if (!isProduction) return `http://localhost:5000/${cleanPath}`;
  const r2Url = process.env.R2_PUBLIC_URL;
  if (r2Url) {
    const cleanUrl = r2Url.endsWith('/') ? r2Url.slice(0, -1) : r2Url;
    return `${cleanUrl}/${cleanPath}`;
  }
  return `https://www.dailyvaibe.com/${cleanPath}`;
};

const normalizeArticle = (article) => ({
  newsId: article.news_id,
  news_id: article.news_id,
  title: article.title,
  excerpt: article.excerpt || article.meta_description || '',
  slug: article.slug,
  imageUrl: getImageUrl(article.image_url),
  image_url: getImageUrl(article.image_url),
  publishedAt: article.published_at,
  published_at: article.published_at,
  readingTime: article.reading_time || 3,
  reading_time: article.reading_time || 3,
  views: article.views || 0,
  likesCount: article.likes_count || 0,
  likes_count: article.likes_count || 0,
  commentsCount: article.comments_count || 0,
  comments_count: article.comments_count || 0,
  shareCount: article.share_count || 0,
  share_count: article.share_count || 0,
  firstName: article.first_name || 'Daily Vaibe',
  first_name: article.first_name || 'Daily Vaibe',
  lastName: article.last_name || 'Editor',
  last_name: article.last_name || 'Editor',
  categoryName: article.category_name || 'Uncategorized',
  category_name: article.category_name || 'Uncategorized',
  categorySlug: article.category_slug || 'general',
  category_slug: article.category_slug || 'general',
  categoryColor: article.category_color || '#6366f1',
  category_color: article.category_color || '#6366f1',
  categoryIcon: article.category_icon || '📰',
  category_icon: article.category_icon || '📰',
  metaDescription: article.meta_description,
  meta_description: article.meta_description
});

router.get('/home', async (req, res) => {
  res.set({
    'Cache-Control': 'no-cache, no-store, must-revalidate',
    'Pragma': 'no-cache',
    'Expires': '0'
  });

  try {
    const pool = getPool();

    const parentCategoriesResult = await pool.query(`
      SELECT c.category_id, c.name, c.slug, c.description, c.color, c.icon, COALESCE(c.order_index, 999) as order_index
      FROM categories c
      WHERE c.parent_id IS NULL AND c.active = true
      ORDER BY COALESCE(c.order_index, 999) ASC, c.name ASC
      LIMIT 20
    `);

    const parentCategories = parentCategoriesResult.rows;
    const categoryIds = parentCategories.map(c => c.category_id);
    
    if (categoryIds.length === 0) {
      return res.json({
        success: true,
        sliderSlides: [],
        headlines: [],
        categorySections: []
      });
    }

    const [recentResult, articlesResult] = await Promise.all([
      pool.query(`
        SELECT n.news_id, n.title, n.excerpt, n.slug, n.image_url, n.published_at, n.reading_time, n.views, n.likes_count, n.comments_count, n.share_count, n.meta_description,
          COALESCE(a.first_name, 'Daily Vaibe') as first_name,
          COALESCE(a.last_name, 'Editor') as last_name,
          parent_cat.name as category_name,
          parent_cat.slug as category_slug,
          parent_cat.color as category_color,
          parent_cat.icon as category_icon
        FROM news n
        LEFT JOIN admins a ON n.author_id = a.admin_id
        LEFT JOIN categories c ON n.category_id = c.category_id
        LEFT JOIN categories parent_cat ON COALESCE(c.parent_id, c.category_id) = parent_cat.category_id
        WHERE n.status = 'published'
        ORDER BY n.published_at DESC
        LIMIT 24
      `),
      pool.query(`
        SELECT n.news_id, n.title, n.excerpt, n.slug, n.image_url, n.published_at, n.reading_time, n.views, n.likes_count, n.comments_count, n.share_count, n.meta_description,
          COALESCE(a.first_name, 'Daily Vaibe') as first_name,
          COALESCE(a.last_name, 'Editor') as last_name,
          parent_cat.category_id,
          parent_cat.name as category_name,
          parent_cat.slug as category_slug,
          parent_cat.color as category_color,
          parent_cat.icon as category_icon
        FROM news n
        LEFT JOIN admins a ON n.author_id = a.admin_id
        LEFT JOIN categories c ON n.category_id = c.category_id
        LEFT JOIN categories parent_cat ON COALESCE(c.parent_id, c.category_id) = parent_cat.category_id
        WHERE n.status = 'published' AND parent_cat.category_id = ANY($1::int[])
        ORDER BY parent_cat.category_id, n.published_at DESC
      `, [categoryIds])
    ]);

    const recent = recentResult.rows.map(normalizeArticle);

    const articlesByCategory = {};
    articlesResult.rows.forEach(row => {
      const catId = row.category_id;
      if (!articlesByCategory[catId]) {
        articlesByCategory[catId] = [];
      }
      if (articlesByCategory[catId].length < 8) {
        articlesByCategory[catId].push(normalizeArticle(row));
      }
    });

    const categorySections = parentCategories
      .map(cat => ({
        categoryId: cat.category_id,
        name: cat.name,
        slug: cat.slug,
        description: cat.description || '',
        color: cat.color || '#6366f1',
        icon: cat.icon || '📰',
        orderIndex: cat.order_index,
        articles: articlesByCategory[cat.category_id] || []
      }))
      .filter(section => section.articles.length > 0);

    return res.json({
      success: true,
      sliderSlides: recent.slice(0, 8),
      headlines: recent.slice(0, 12),
      categorySections: categorySections
    });
  } catch (error) {
    console.error('[client/home] ERROR:', error.message);
    return res.status(500).json({
      success: false,
      message: 'Internal server error',
      sliderSlides: [],
      headlines: [],
      categorySections: []
    });
  }
});

router.get('/homeslider', async (req, res) => {
  res.set({
    'Cache-Control': 'no-cache, no-store, must-revalidate',
    'Pragma': 'no-cache',
    'Expires': '0'
  });

  try {
    const pool = getPool();
    
    const result = await pool.query(`
      SELECT n.news_id, n.title, n.excerpt, n.slug, n.image_url, n.published_at, n.reading_time, n.views, n.likes_count, n.comments_count, n.share_count, n.meta_description,
        COALESCE(a.first_name, 'Daily Vaibe') as first_name,
        COALESCE(a.last_name, 'Editor') as last_name,
        parent_cat.name as category_name,
        parent_cat.slug as category_slug,
        parent_cat.color as category_color,
        parent_cat.icon as category_icon
      FROM news n
      LEFT JOIN admins a ON n.author_id = a.admin_id
      LEFT JOIN categories c ON n.category_id = c.category_id
      LEFT JOIN categories parent_cat ON COALESCE(c.parent_id, c.category_id) = parent_cat.category_id
      WHERE n.status = 'published'
      ORDER BY n.published_at DESC
      LIMIT 8
    `);

    const slides = result.rows.map(normalizeArticle);

    return res.json({
      success: true,
      slides: slides
    });
  } catch (error) {
    console.error('[client/homeslider] ERROR:', error.message);
    return res.status(500).json({
      success: false,
      slides: []
    });
  }
});

router.get('/breaking', async (req, res) => {
  res.set({
    'Cache-Control': 'no-cache, no-store, must-revalidate',
    'Pragma': 'no-cache',
    'Expires': '0'
  });

  const limit = Math.min(50, Math.max(1, parseInt(req.query.limit) || 50));
  const page = Math.max(1, parseInt(req.query.page) || 1);
  const offset = (page - 1) * limit;

  try {
    const pool = getPool();
    
    const result = await pool.query(`
      SELECT n.news_id, n.title, n.excerpt, n.slug, n.image_url, n.published_at, n.reading_time, n.views, n.likes_count, n.comments_count, n.share_count, n.meta_description,
        COALESCE(a.first_name, 'Daily Vaibe') as first_name,
        COALESCE(a.last_name, 'Editor') as last_name,
        c.name as category_name,
        c.slug as category_slug,
        c.color as category_color,
        c.icon as category_icon,
        bn.priority as breaking_level
      FROM news n
      LEFT JOIN admins a ON n.author_id = a.admin_id
      LEFT JOIN categories c ON n.category_id = c.category_id
      INNER JOIN breaking_news bn ON n.news_id = bn.news_id
      WHERE n.status = 'published'
        AND bn.manually_removed = false
        AND (bn.ends_at IS NULL OR bn.ends_at > NOW())
      ORDER BY 
        CASE bn.priority
          WHEN 'urgent' THEN 0
          WHEN 'high' THEN 1
          WHEN 'medium' THEN 2
          WHEN 'low' THEN 3
          ELSE 4
        END,
        n.published_at DESC
      LIMIT $1 OFFSET $2
    `, [limit, offset]);

    const news = result.rows.map(normalizeArticle);

    return res.json({
      success: true,
      news: news,
      pagination: {
        current_page: page,
        per_page: limit,
        has_next: news.length === limit,
        has_prev: page > 1
      }
    });
  } catch (error) {
    console.error('[client/breaking] ERROR:', error.message);
    return res.status(500).json({
      success: false,
      message: 'Failed to fetch breaking news',
      news: []
    });
  }
});

router.get('/trending', async (req, res) => {
  res.set({
    'Cache-Control': 'no-cache, no-store, must-revalidate',
    'Pragma': 'no-cache',
    'Expires': '0'
  });

  const limit = Math.min(50, Math.max(1, parseInt(req.query.limit) || 50));
  const page = Math.max(1, parseInt(req.query.page) || 1);
  const offset = (page - 1) * limit;

  try {
    const pool = getPool();
    
    const result = await pool.query(`
      SELECT n.news_id, n.title, n.excerpt, n.slug, n.image_url, n.published_at, n.reading_time, n.views, n.likes_count, n.comments_count, n.share_count, n.meta_description,
        COALESCE(a.first_name, 'Daily Vaibe') as first_name,
        COALESCE(a.last_name, 'Editor') as last_name,
        c.name as category_name,
        c.slug as category_slug,
        c.color as category_color,
        c.icon as category_icon,
        (
          COALESCE(n.views, 0) * 1 + 
          COALESCE(n.likes_count, 0) * 5 + 
          COALESCE(n.comments_count, 0) * 10 +
          COALESCE(n.share_count, 0) * 15
        ) * (
          CASE 
            WHEN EXTRACT(EPOCH FROM (NOW() - n.published_at)) / 3600 < 1 THEN 3.0
            WHEN EXTRACT(EPOCH FROM (NOW() - n.published_at)) / 3600 < 3 THEN 2.0
            WHEN EXTRACT(EPOCH FROM (NOW() - n.published_at)) / 3600 < 6 THEN 1.5
            WHEN EXTRACT(EPOCH FROM (NOW() - n.published_at)) / 3600 < 12 THEN 1.2
            WHEN EXTRACT(EPOCH FROM (NOW() - n.published_at)) / 3600 < 24 THEN 1.0
            WHEN EXTRACT(EPOCH FROM (NOW() - n.published_at)) / 3600 < 48 THEN 0.5
            ELSE 0.2
          END
        ) as trending_score
      FROM news n
      LEFT JOIN admins a ON n.author_id = a.admin_id
      LEFT JOIN categories c ON n.category_id = c.category_id
      WHERE n.status = 'published'
      ORDER BY trending_score DESC, n.published_at DESC
      LIMIT $1 OFFSET $2
    `, [limit, offset]);

    const news = result.rows.map(normalizeArticle);

    return res.json({
      success: true,
      news: news,
      pagination: {
        current_page: page,
        per_page: limit,
        has_next: news.length === limit,
        has_prev: page > 1
      }
    });
  } catch (error) {
    console.error('[client/trending] ERROR:', error.message);
    return res.status(500).json({
      success: false,
      message: 'Failed to fetch trending news',
      news: []
    });
  }
});

router.get('/featured', async (req, res) => {
  res.set({
    'Cache-Control': 'no-cache, no-store, must-revalidate',
    'Pragma': 'no-cache',
    'Expires': '0'
  });

  const limit = Math.min(50, Math.max(1, parseInt(req.query.limit) || 50));
  const page = Math.max(1, parseInt(req.query.page) || 1);
  const offset = (page - 1) * limit;

  try {
    const pool = getPool();
    
    const result = await pool.query(`
      SELECT n.news_id, n.title, n.excerpt, n.slug, n.image_url, n.published_at, n.reading_time, n.views, n.likes_count, n.comments_count, n.share_count, n.meta_description,
        COALESCE(a.first_name, 'Daily Vaibe') as first_name,
        COALESCE(a.last_name, 'Editor') as last_name,
        c.name as category_name,
        c.slug as category_slug,
        c.color as category_color,
        c.icon as category_icon,
        fn.tier as featured_tier
      FROM news n
      LEFT JOIN admins a ON n.author_id = a.admin_id
      LEFT JOIN categories c ON n.category_id = c.category_id
      INNER JOIN featured_news fn ON n.news_id = fn.news_id
      WHERE n.status = 'published'
        AND fn.manually_removed = false
        AND (fn.ends_at IS NULL OR fn.ends_at > NOW())
      ORDER BY 
        CASE fn.tier
          WHEN 'gold' THEN 1
          WHEN 'silver' THEN 2
          WHEN 'bronze' THEN 3
          ELSE 4
        END,
        n.published_at DESC
      LIMIT $1 OFFSET $2
    `, [limit, offset]);

    const news = result.rows.map(normalizeArticle);

    return res.json({
      success: true,
      news: news,
      pagination: {
        current_page: page,
        per_page: limit,
        has_next: news.length === limit,
        has_prev: page > 1
      }
    });
  } catch (error) {
    console.error('[client/featured] ERROR:', error.message);
    return res.status(500).json({
      success: false,
      message: 'Failed to fetch featured news',
      news: []
    });
  }
});

router.get('/timeline', async (req, res) => {
  res.set({
    'Cache-Control': 'no-cache, no-store, must-revalidate',
    'Pragma': 'no-cache',
    'Expires': '0'
  });

  const limit = Math.min(100, Math.max(1, parseInt(req.query.limit) || 20));
  const page = Math.max(1, parseInt(req.query.page) || 1);
  const offset = (page - 1) * limit;

  try {
    const pool = getPool();
    
    const [articlesResult, countResult] = await Promise.all([
      pool.query(`
        SELECT n.news_id, n.title, n.excerpt, n.slug, n.image_url, n.published_at, n.reading_time, n.views, n.likes_count, n.comments_count, n.share_count,
          COALESCE(a.first_name, 'Daily Vaibe') as first_name,
          COALESCE(a.last_name, 'Editor') as last_name,
          c.name as category_name,
          c.slug as category_slug
        FROM news n
        LEFT JOIN admins a ON n.author_id = a.admin_id
        LEFT JOIN categories c ON n.category_id = c.category_id
        WHERE n.status = 'published'
        ORDER BY n.published_at DESC
        LIMIT $1 OFFSET $2
      `, [limit, offset]),
      pool.query(`SELECT COUNT(*) as total FROM news WHERE status = 'published'`)
    ]);

    const articles = articlesResult.rows.map(a => ({
      news_id: a.news_id,
      title: a.title,
      excerpt: a.excerpt,
      slug: a.slug,
      image_url: getImageUrl(a.image_url),
      published_at: a.published_at,
      reading_time: a.reading_time || 3,
      views: a.views || 0,
      likes_count: a.likes_count || 0,
      comments_count: a.comments_count || 0,
      share_count: a.share_count || 0,
      first_name: a.first_name,
      last_name: a.last_name,
      category_name: a.category_name,
      category_slug: a.category_slug
    }));

    const totalItems = parseInt(countResult.rows[0]?.total || 0);

    return res.json({
      success: true,
      timeline: articles,
      articles: articles,
      pagination: {
        current_page: page,
        per_page: limit,
        total_items: totalItems,
        total_pages: Math.ceil(totalItems / limit),
        has_next: (page * limit) < totalItems,
        has_prev: page > 1
      }
    });
  } catch (error) {
    console.error('[client/timeline] ERROR:', error.message);
    return res.status(500).json({
      success: false,
      message: 'Failed to fetch timeline',
      timeline: [],
      articles: []
    });
  }
});

router.get('/quotes', async (req, res) => {
  res.set({
    'Cache-Control': 'no-cache, no-store, must-revalidate',
    'Pragma': 'no-cache',
    'Expires': '0'
  });

  const limit = Math.min(100, Math.max(1, parseInt(req.query.limit) || 84));

  try {
    const pool = getPool();
    
    const result = await pool.query(`
      SELECT quote_id, quote_text, sayer_name, sayer_title, image_url, active, created_at, updated_at
      FROM news_quotes
      WHERE active = true
      ORDER BY created_at DESC
      LIMIT $1
    `, [limit]);

    const quotes = result.rows.map(q => ({
      quote_id: q.quote_id,
      quote_text: q.quote_text,
      sayer_name: q.sayer_name,
      sayer_title: q.sayer_title || '',
      sayer_image_url: getImageUrl(q.image_url),
      active: q.active,
      created_at: q.created_at,
      updated_at: q.updated_at
    }));

    const now = new Date();
    const threeDaysAgo = new Date(now.getTime() - (3 * 24 * 60 * 60 * 1000));
    const sevenDaysAgo = new Date(now.getTime() - (7 * 24 * 60 * 60 * 1000));

    const freshQuotes = quotes.filter(q => new Date(q.created_at) >= threeDaysAgo);
    const strikingQuotes = quotes.filter(q => {
      const created = new Date(q.created_at);
      return created < threeDaysAgo && created >= sevenDaysAgo;
    }).slice(0, 12);
    const trendingQuotes = quotes.filter(q => new Date(q.created_at) < sevenDaysAgo).slice(0, 12);

    return res.json({
      success: true,
      quotes: quotes,
      strikingQuotes: strikingQuotes,
      trendingQuotes: trendingQuotes,
      total: quotes.length
    });
  } catch (error) {
    console.error('[client/quotes] ERROR:', error.message);
    return res.status(500).json({
      success: false,
      message: 'Internal server error',
      quotes: [],
      strikingQuotes: [],
      trendingQuotes: []
    });
  }
});

module.exports = router;