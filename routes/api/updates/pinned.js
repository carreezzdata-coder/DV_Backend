const express = require('express');
const router = express.Router();
const { getPool } = require('../../../config/db');
const cloudflareService = require('../../../services/cloudflareService');

const { FRONTEND_URL, CLIENT_URL, ADMIN_URL, API_DOMAIN, ALLOWED_ORIGINS, isOriginAllowed } = require('../../../config/frontendconfig');
const getImageUrl = (imageUrl) => {
  if (!imageUrl) return null;
  if (imageUrl.startsWith('http://') || imageUrl.startsWith('https://')) return imageUrl;
  const cleanPath = imageUrl.startsWith('/') ? imageUrl.substring(1) : imageUrl;
  if (cloudflareService.isEnabled()) {
    return cloudflareService.getPublicUrl(cleanPath);
  }
  const r2Url = process.env.R2_PUBLIC_URL;
  if (r2Url) {
    const cleanUrl = r2Url.endsWith('/') ? r2Url.slice(0, -1) : r2Url;
    return `${cleanUrl}/${cleanPath}`;
  }
  return imageUrl;
};

const normalizeArticle = (article) => ({
  news_id: article.news_id,
  newsId: article.news_id,
  title: article.title,
  excerpt: article.excerpt || article.meta_description || '',
  slug: article.slug,
  image_url: getImageUrl(article.image_url),
  imageUrl: getImageUrl(article.image_url),
  published_at: article.published_at,
  publishedAt: article.published_at,
  reading_time: article.reading_time || 3,
  readingTime: article.reading_time || 3,
  views: article.views || 0,
  likes_count: article.likes_count || 0,
  likesCount: article.likes_count || 0,
  comments_count: article.comments_count || 0,
  commentsCount: article.comments_count || 0,
  share_count: article.share_count || 0,
  shareCount: article.share_count || 0,
  first_name: article.first_name || 'Daily Vaibe',
  firstName: article.first_name || 'Daily Vaibe',
  last_name: article.last_name || 'Editor',
  lastName: article.last_name || 'Editor',
  category_name: article.category_name || 'Uncategorized',
  categoryName: article.category_name || 'Uncategorized',
  category_slug: article.category_slug || 'general',
  categorySlug: article.category_slug || 'general',
  category_color: article.category_color || '#6366f1',
  categoryColor: article.category_color || '#6366f1',
  category_icon: article.category_icon || '📰',
  categoryIcon: article.category_icon || '📰',
  meta_description: article.meta_description,
  metaDescription: article.meta_description,
  tags: article.tags ? article.tags.split(',').map(t => t.trim()).filter(Boolean) : [],
  pinned: {
    position: article.pin_position,
    tier: article.pin_tier,
    started_at: article.pin_started_at,
    startedAt: article.pin_started_at,
    ends_at: article.pin_ends_at,
    endsAt: article.pin_ends_at,
    emoji: article.pin_tier === 'gold' ? '📌' : 
           article.pin_tier === 'silver' ? '📍' : '📎'
  },
  trending_score: article.trending_score || 0,
  trendingScore: article.trending_score || 0,
  hours_ago: article.hours_ago || 0,
  hoursAgo: article.hours_ago || 0
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
    const categorySlug = req.query.category;

    let whereClause = `
      n.status = 'published' 
      AND p.manually_removed = false
      AND (p.ends_at IS NULL OR p.ends_at > CURRENT_TIMESTAMP)
    `;

    let joinClause = '';
    const queryParams = [limit, offset];

    if (categorySlug) {
      joinClause = `
        INNER JOIN news_categories nc ON n.news_id = nc.news_id
        INNER JOIN categories cat ON nc.category_id = cat.category_id
      `;
      whereClause += ` AND cat.slug = $3`;
      queryParams.push(categorySlug);
    }

    const [countResult, newsResult] = await Promise.all([
      pool.query(`
        SELECT COUNT(DISTINCT n.news_id) as total 
        FROM pinned_news p
        INNER JOIN news n ON p.news_id = n.news_id
        ${joinClause}
        WHERE ${whereClause}
      `, categorySlug ? [categorySlug] : []),
      pool.query(`
        SELECT DISTINCT
          n.news_id, n.title, n.excerpt, n.slug, n.image_url, n.published_at,
          n.reading_time, n.views, n.likes_count, n.comments_count, n.share_count,
          n.meta_description, n.tags,
          COALESCE(a.first_name, 'Daily Vaibe') as first_name,
          COALESCE(a.last_name, 'Editor') as last_name,
          c.name as category_name, 
          c.slug as category_slug, 
          c.color as category_color,
          c.icon as category_icon,
          p.position as pin_position,
          p.tier as pin_tier,
          p.starts_at as pin_started_at,
          p.ends_at as pin_ends_at,
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
        FROM pinned_news p
        INNER JOIN news n ON p.news_id = n.news_id
        LEFT JOIN admins a ON n.author_id = a.admin_id
        LEFT JOIN categories c ON n.category_id = c.category_id
        ${joinClause}
        WHERE ${whereClause}
        ORDER BY 
          p.position ASC NULLS LAST,
          CASE p.tier
            WHEN 'gold' THEN 1
            WHEN 'silver' THEN 2
            WHEN 'bronze' THEN 3
            ELSE 4
          END,
          p.starts_at DESC,
          n.published_at DESC
        LIMIT $1 OFFSET $2
      `, queryParams)
    ]);

    const total = parseInt(countResult.rows[0]?.total || '0');
    const totalPages = Math.ceil(total / limit);

    return res.json({
      success: true,
      news: newsResult.rows.map(normalizeArticle),
      pinnedNews: newsResult.rows.map(normalizeArticle),
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
    console.error('[pinned] ERROR:', error.message);
    return res.status(500).json({
      success: false,
      message: 'Failed to fetch pinned news',
      news: [],
      pinnedNews: [],
      pagination: {
        current_page: 1,
        per_page: 50,
        total_items: 0,
        total_pages: 0,
        has_next: false,
        has_prev: false
      }
    });
  }
});

module.exports = router;
