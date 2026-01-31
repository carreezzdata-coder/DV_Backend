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
  meta_description: article.meta_description,
  trending_score: article.trending_score || 0,
  hours_ago: article.hours_ago || 0,
  tags: article.tags ? article.tags.split(',').map(t => t.trim()).filter(Boolean) : [],
  promotions: {
    featured: article.featured_tier !== null,
    featured_tier: article.featured_tier,
    breaking: article.breaking_level !== null,
    breaking_level: article.breaking_level,
    pinned: article.pin_type !== null,
    pin_type: article.pin_type
  }
});

router.get('/', async (req, res) => {
  res.set({
    'Cache-Control': 'no-cache, no-store, must-revalidate',
    'Pragma': 'no-cache',
    'Expires': '0'
  });

  try {
    const pool = getPool();
    const page = Math.max(1, parseInt(req.query.page || '1'));
    const limit = Math.min(100, Math.max(1, parseInt(req.query.limit || '50')));
    const offset = (page - 1) * limit;

    const newsQuery = `
      SELECT
        n.news_id, n.title, n.excerpt, n.slug, n.image_url, n.published_at,
        n.reading_time, n.views, n.likes_count, n.comments_count, n.share_count,
        n.meta_description, n.tags,
        COALESCE(a.first_name, 'Daily Vaibe') as first_name,
        COALESCE(a.last_name, 'Editor') as last_name,
        c.name as category_name, 
        c.slug as category_slug, 
        c.color as category_color,
        (SELECT tier FROM featured_news WHERE news_id = n.news_id AND manually_removed = false 
         AND (ends_at IS NULL OR ends_at > CURRENT_TIMESTAMP) LIMIT 1) as featured_tier,
        (SELECT priority FROM breaking_news WHERE news_id = n.news_id AND manually_removed = false 
         AND (ends_at IS NULL OR ends_at > CURRENT_TIMESTAMP) LIMIT 1) as breaking_level,
        (SELECT tier FROM pinned_news WHERE news_id = n.news_id AND manually_removed = false 
         AND (ends_at IS NULL OR ends_at > CURRENT_TIMESTAMP) LIMIT 1) as pin_type,
        EXTRACT(EPOCH FROM (NOW() - n.published_at)) / 3600 as hours_ago,
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
    `;

    const newsResult = await pool.query(newsQuery, [limit, offset]);

    const countQuery = `SELECT COUNT(*) as total FROM news n WHERE n.status = 'published'`;
    
    const countResult = await pool.query(countQuery);
    const totalItems = parseInt(countResult.rows[0]?.total || '0');

    return res.json({
      success: true,
      news: newsResult.rows.map(normalizeArticle),
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
    console.error('[fetchall] ERROR:', error.message);
    return res.status(500).json({
      success: false,
      message: 'Failed to fetch news',
      news: [],
      pagination: {
        current_page: 1,
        per_page: 20,
        has_next: false,
        has_prev: false
      }
    });
  }
});

module.exports = router;