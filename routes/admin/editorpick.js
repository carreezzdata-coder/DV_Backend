const express = require('express');
const router = express.Router();
const { getPool } = require('../../config/db');

const { FRONTEND_URL, CLIENT_URL, ADMIN_URL, API_DOMAIN, ALLOWED_ORIGINS, isOriginAllowed } = require('../../config/frontendconfig');

const getImageUrl = (imageUrl) => {
  if (!imageUrl) return null;
  if (imageUrl.startsWith('http://') || imageUrl.startsWith('https://')) return imageUrl;
  const cleanPath = imageUrl.startsWith('/') ? imageUrl.substring(1) : imageUrl;
  if (process.env.NODE_ENV === 'development') return `http://localhost:5000/${cleanPath}`;
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
  tags: article.tags ? article.tags.split(',').map(t => t.trim()).filter(Boolean) : [],
  editor_pick: {
    picked_at: article.picked_at,
    picked_by_name: article.picked_by_name
  }
});

router.get('/', async (req, res) => {
  res.set({
    'Cache-Control': 'public, max-age=300, s-maxage=600, stale-while-revalidate=1200',
    'CDN-Cache-Control': 'max-age=600',
    'Vary': 'Accept-Encoding'
  });

  try {
    const pool = getPool();
    const page = Math.max(1, parseInt(req.query.page || '1'));
    const limit = Math.min(100, Math.max(1, parseInt(req.query.limit || '50')));
    const offset = (page - 1) * limit;

    const [countResult, newsResult] = await Promise.all([
      pool.query(`
        SELECT COUNT(*) as total 
        FROM editor_pick e
        INNER JOIN news n ON e.news_id = n.news_id
        WHERE n.status = 'published' 
          AND e.manually_removed = false
      `),
      pool.query(`
        SELECT
          n.news_id, n.title, n.excerpt, n.slug, n.image_url, n.published_at,
          n.reading_time, n.views, n.likes_count, n.comments_count, n.share_count,
          n.meta_description, n.tags,
          COALESCE(a.first_name, 'Daily Vaibe') as first_name,
          COALESCE(a.last_name, 'Editor') as last_name,
          c.name as category_name, 
          c.slug as category_slug, 
          c.color as category_color,
          e.picked_at,
          COALESCE(pa.first_name || ' ' || pa.last_name, 'Editor') as picked_by_name
        FROM editor_pick e
        INNER JOIN news n ON e.news_id = n.news_id
        LEFT JOIN admins a ON n.author_id = a.admin_id
        LEFT JOIN admins pa ON e.picked_by = pa.admin_id
        LEFT JOIN categories c ON n.category_id = c.category_id
        WHERE n.status = 'published' 
          AND e.manually_removed = false
        ORDER BY e.picked_at DESC, n.published_at DESC
        LIMIT $1 OFFSET $2
      `, [limit, offset])
    ]);

    const total = parseInt(countResult.rows[0]?.total || '0');
    const totalPages = Math.ceil(total / limit);

    return res.json({
      success: true,
      news: newsResult.rows.map(normalizeArticle),
      pagination: {
        current_page: page,
        per_page: limit,
        total_items: total,
        total_pages: totalPages,
        has_next: page < totalPages,
        has_prev: page > 1
      }
    });
  } catch (error) {
    console.error('[EditorPick] Error:', error);
    return res.status(500).json({
      success: false,
      message: 'Failed to fetch editor picks',
      error: process.env.NODE_ENV === 'development' ? error.message : undefined
    });
  }
});

module.exports = router;