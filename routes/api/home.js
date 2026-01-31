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
  title: article.title,
  excerpt: article.excerpt || article.meta_description || '',
  slug: article.slug,
  imageUrl: getImageUrl(article.image_url),
  publishedAt: article.published_at,
  readingTime: article.reading_time || 3,
  views: article.views || 0,
  likesCount: article.likes_count || 0,
  commentsCount: article.comments_count || 0,
  shareCount: article.share_count || 0,
  firstName: article.first_name || 'Daily Vaibe',
  lastName: article.last_name || 'Editor',
  categoryName: article.category_name || 'Uncategorized',
  categorySlug: article.category_slug || 'general',
  categoryColor: article.category_color || '#6366f1',
  categoryIcon: article.category_icon || '📰',
  metaDescription: article.meta_description
});

router.get('/', async (req, res) => {
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
    console.error('[home] ERROR:', error.message);
    return res.status(500).json({
      success: false,
      message: 'Internal server error',
      sliderSlides: [],
      headlines: [],
      categorySections: []
    });
  }
});

module.exports = router;