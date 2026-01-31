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

const normalizeArticle = (article) => ({
  news_id: article.news_id,
  title: article.title,
  excerpt: article.excerpt || article.meta_description || '',
  slug: article.slug,
  image_url: getImageUrl(article.image_url),
  published_at: article.published_at,
  reading_time: article.reading_time || 3,
  views: article.views || 0,
  likes_count: article.likes_count || 0,
  comments_count: article.comments_count || 0,
  share_count: article.share_count || 0,
  first_name: article.first_name || 'Daily Vaibe',
  last_name: article.last_name || 'Editor',
  category_name: article.category_name,
  category_slug: article.category_slug,
  category_color: article.category_color,
  category_icon: article.category_icon,
  relevance_score: article.relevance_score || 0
});

const calculateRelevanceScore = (article, preferences) => {
  let score = 0;
  const categoryVisits = preferences.categoryVisits || {};
  const preferredCategories = preferences.preferredCategories || [];
  
  if (preferredCategories.includes(article.category_slug)) {
    const index = preferredCategories.indexOf(article.category_slug);
    score += (5 - index) * 20;
  }
  
  const visits = categoryVisits[article.category_slug] || 0;
  score += Math.min(visits * 2, 30);
  
  const now = new Date().getTime();
  const publishedTime = new Date(article.published_at).getTime();
  const hoursAgo = (now - publishedTime) / (1000 * 60 * 60);
  
  if (hoursAgo < 1) score += 25;
  else if (hoursAgo < 6) score += 15;
  else if (hoursAgo < 24) score += 10;
  else if (hoursAgo < 48) score += 5;
  
  const engagement = (article.views || 0) * 0.1 + 
                    (article.likes_count || 0) * 2 + 
                    (article.comments_count || 0) * 3 +
                    (article.share_count || 0) * 5;
  score += Math.min(engagement, 25);
  
  return score;
};

router.post('/', async (req, res) => {
  const startTime = new Date().getTime();
  const requestId = `personalized-${req.headers['x-request-id'] || 'req'}`;
  
  res.set({
    'Cache-Control': 'private, max-age=60, must-revalidate',
    'Vary': 'Cookie, Authorization'
  });

  try {
    const pool = getPool();
    const { personalized, preferences, location } = req.body;

    console.log(`[${requestId}] Personalized: ${personalized}`);
    console.log(`[${requestId}] Preferred Categories:`, preferences?.preferredCategories || []);

    if (!personalized || !preferences?.preferredCategories?.length) {
      const defaultResult = await pool.query(`
        SELECT
          n.news_id, n.title, n.excerpt, n.slug, n.image_url, n.published_at,
          n.reading_time, n.views, n.likes_count, n.comments_count, n.share_count,
          n.meta_description,
          COALESCE(a.first_name, 'Daily Vaibe') as first_name,
          COALESCE(a.last_name, 'Editor') as last_name,
          c.name as category_name, c.slug as category_slug, 
          c.color as category_color, c.icon as category_icon
        FROM news n
        LEFT JOIN admins a ON n.author_id = a.admin_id
        LEFT JOIN categories c ON n.category_id = c.category_id
        WHERE n.status = 'published'
        ORDER BY n.published_at DESC
        LIMIT 50
      `);

      return res.json({
        success: true,
        personalized: false,
        featured: defaultResult.rows.slice(0, 10).map(normalizeArticle),
        slider: defaultResult.rows.slice(0, 8).map(normalizeArticle),
        timeline: defaultResult.rows.slice(0, 20).map(normalizeArticle),
        categorySections: []
      });
    }

    const preferredCategorySlugs = preferences.preferredCategories;
    const categoryVisits = preferences.categoryVisits || {};
    
    const categoryIdsResult = await pool.query(`
      SELECT category_id, slug FROM categories 
      WHERE slug = ANY($1::text[]) AND active = true
    `, [preferredCategorySlugs]);

    const categoryMap = {};
    categoryIdsResult.rows.forEach(row => {
      categoryMap[row.slug] = row.category_id;
    });

    const categoryIds = Object.values(categoryMap);

    const personalizedQuery = `
      SELECT
        n.news_id, n.title, n.excerpt, n.slug, n.image_url, n.published_at,
        n.reading_time, n.views, n.likes_count, n.comments_count, n.share_count,
        n.meta_description,
        COALESCE(a.first_name, 'Daily Vaibe') as first_name,
        COALESCE(a.last_name, 'Editor') as last_name,
        c.name as category_name, c.slug as category_slug, 
        c.color as category_color, c.icon as category_icon,
        CASE
          WHEN c.category_id = ANY($1::int[]) THEN 50
          WHEN pc.category_id = ANY($1::int[]) THEN 30
          ELSE 0
        END as category_match_score,
        EXTRACT(EPOCH FROM (NOW() - n.published_at)) / 3600 as hours_ago
      FROM news n
      LEFT JOIN admins a ON n.author_id = a.admin_id
      LEFT JOIN categories c ON n.category_id = c.category_id
      LEFT JOIN categories pc ON c.parent_id = pc.category_id
      WHERE n.status = 'published'
        AND n.published_at >= NOW() - INTERVAL '7 days'
        AND (c.category_id = ANY($1::int[]) OR pc.category_id = ANY($1::int[]))
      ORDER BY 
        category_match_score DESC,
        (
          COALESCE(n.views, 0) * 0.1 + 
          COALESCE(n.likes_count, 0) * 2 + 
          COALESCE(n.comments_count, 0) * 3 +
          COALESCE(n.share_count, 0) * 5
        ) * (
          CASE 
            WHEN EXTRACT(EPOCH FROM (NOW() - n.published_at)) / 3600 < 1 THEN 3.0
            WHEN EXTRACT(EPOCH FROM (NOW() - n.published_at)) / 3600 < 6 THEN 2.0
            WHEN EXTRACT(EPOCH FROM (NOW() - n.published_at)) / 3600 < 24 THEN 1.5
            ELSE 1.0
          END
        ) DESC,
        n.published_at DESC
      LIMIT 100
    `;

    const personalizedResult = await pool.query(personalizedQuery, [categoryIds]);

    const fillerQuery = `
      SELECT
        n.news_id, n.title, n.excerpt, n.slug, n.image_url, n.published_at,
        n.reading_time, n.views, n.likes_count, n.comments_count, n.share_count,
        n.meta_description,
        COALESCE(a.first_name, 'Daily Vaibe') as first_name,
        COALESCE(a.last_name, 'Editor') as last_name,
        c.name as category_name, c.slug as category_slug, 
        c.color as category_color, c.icon as category_icon
      FROM news n
      LEFT JOIN admins a ON n.author_id = a.admin_id
      LEFT JOIN categories c ON n.category_id = c.category_id
      WHERE n.status = 'published'
        AND n.published_at >= NOW() - INTERVAL '3 days'
        AND c.category_id != ALL($1::int[])
      ORDER BY 
        (COALESCE(n.views, 0) + COALESCE(n.likes_count, 0) * 3) DESC,
        n.published_at DESC
      LIMIT 30
    `;

    const fillerResult = await pool.query(fillerQuery, [categoryIds]);

    const allArticles = [...personalizedResult.rows, ...fillerResult.rows];
    const processedArticles = allArticles.map(article => ({
      ...article,
      relevance_score: calculateRelevanceScore(article, preferences)
    }));

    processedArticles.sort((a, b) => b.relevance_score - a.relevance_score);

    const uniqueArticles = [];
    const seenIds = new Set();
    for (const article of processedArticles) {
      if (!seenIds.has(article.news_id)) {
        seenIds.add(article.news_id);
        uniqueArticles.push(article);
      }
    }

    const categorySections = [];
    for (const categorySlug of preferredCategorySlugs.slice(0, 5)) {
      const categoryArticles = uniqueArticles.filter(a => a.category_slug === categorySlug);
      if (categoryArticles.length > 0) {
        const cat = categoryArticles[0];
        categorySections.push({
          categoryId: categoryMap[categorySlug],
          name: cat.category_name,
          slug: cat.category_slug,
          color: cat.category_color,
          icon: cat.category_icon,
          articles: categoryArticles.slice(0, 8).map(normalizeArticle)
        });
      }
    }

    const elapsed = new Date().getTime() - startTime;
    console.log(`[${requestId}] Personalized content: ${uniqueArticles.length} articles in ${elapsed}ms`);

    return res.json({
      success: true,
      personalized: true,
      featured: uniqueArticles.slice(0, 10).map(normalizeArticle),
      slider: uniqueArticles.slice(0, 8).map(normalizeArticle),
      timeline: uniqueArticles.slice(0, 30).map(normalizeArticle),
      categorySections,
      _meta: {
        elapsedMs: elapsed,
        requestId,
        totalArticles: uniqueArticles.length,
        preferredCategories: preferredCategorySlugs
      }
    });

  } catch (error) {
    const elapsed = new Date().getTime() - startTime;
    console.error(`[${requestId}] Personalization error (${elapsed}ms):`, error.message);
    
    return res.status(500).json({
      success: false,
      message: 'Failed to fetch personalized content',
      error: process.env.NODE_ENV === 'development' ? error.message : undefined
    });
  }
});

module.exports = router;