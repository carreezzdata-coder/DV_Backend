const express = require('express');
const router = express.Router();
const { getPool } = require('../../config/db');
const cloudflareService = require('../../services/cloudflareService');



const { FRONTEND_URL, CLIENT_URL, ADMIN_URL, API_DOMAIN, ALLOWED_ORIGINS, isOriginAllowed } = require('../../config/frontendconfig');

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

router.get('/slugs', async (req, res) => {
  res.set({
    'Cache-Control': 'public, max-age=600, s-maxage=1800, stale-while-revalidate=3600',
    'CDN-Cache-Control': 'max-age=1800, stale-while-revalidate=3600',
    'Vary': 'Accept-Encoding'
  });

  try {
    const pool = getPool();
    const result = await pool.query(
      `SELECT slug, name, description, color, icon, parent_id
       FROM categories WHERE active = true ORDER BY order_index ASC, name ASC`
    );

    res.json({
      success: true,
      categories: result.rows,
      slugs: result.rows.map(row => row.slug)
    });
  } catch (error) {
    console.error('Error fetching category slugs:', error);
    res.status(500).json({
      success: false,
      slugs: [],
      error: error.message
    });
  }
});

router.get('/:slug', async (req, res) => {
  res.set({
    'Cache-Control': 'public, max-age=300, s-maxage=600, stale-while-revalidate=1800',
    'CDN-Cache-Control': 'max-age=600, stale-while-revalidate=1800',
    'Vary': 'Accept-Encoding'
  });

  try {
    const pool = getPool();
    const { slug } = req.params;

    const categoryResult = await pool.query(
      `SELECT c.category_id, c.name, c.slug, c.description, c.color, c.icon, 
              c.active, c.order_index, c.parent_id,
              p.name as parent_name, p.slug as parent_slug
       FROM categories c
       LEFT JOIN categories p ON c.parent_id = p.category_id
       WHERE c.slug = $1 AND c.active = true`,
      [slug]
    );

    if (categoryResult.rows.length === 0) {
      return res.status(404).json({
        success: false,
        message: `Category '${slug}' not found`
      });
    }

    const category = categoryResult.rows[0];

    const countResult = await pool.query(
      `SELECT COUNT(DISTINCT n.news_id) as total 
       FROM news n
       INNER JOIN news_categories nc ON n.news_id = nc.news_id
       WHERE nc.category_id = $1 AND n.status = 'published'`,
      [category.category_id]
    );

    return res.json({
      success: true,
      category: {
        ...category,
        article_count: parseInt(countResult.rows[0].total)
      },
      seo: {
        title: `${category.name} News - Daily Vaibe`,
        description: category.description || `Latest ${category.name} news`,
        canonical_url: `/category/${category.slug}`
      }
    });
  } catch (error) {
    console.error(`Category error for ${req.params.slug}:`, error);
    return res.status(500).json({
      success: false,
      message: 'Internal server error',
      error: process.env.NODE_ENV === 'development' ? error.message : undefined
    });
  }
});

router.get('/:slug/news', async (req, res) => {
  res.set({
    'Cache-Control': 'public, max-age=180, s-maxage=300, stale-while-revalidate=900',
    'CDN-Cache-Control': 'max-age=300, stale-while-revalidate=900',
    'Vary': 'Accept-Encoding'
  });

  try {
    const pool = getPool();
    const { slug } = req.params;
    const page = Math.max(1, parseInt(req.query.page || '1'));
    const limit = Math.min(50, Math.max(1, parseInt(req.query.limit || '20')));
    const offset = (page - 1) * limit;

    const categoryResult = await pool.query(
      `SELECT c.category_id, c.name, c.slug, c.description, c.color, c.icon, c.parent_id,
              p.name as parent_name, p.slug as parent_slug
       FROM categories c
       LEFT JOIN categories p ON c.parent_id = p.category_id
       WHERE c.slug = $1 AND c.active = true`,
      [slug]
    );

    if (categoryResult.rows.length === 0) {
      return res.status(404).json({
        success: false,
        message: `Category '${slug}' not found`,
        news: [],
        pagination: { current_page: 1, total_pages: 0, total_news: 0 }
      });
    }

    const category = categoryResult.rows[0];

    const countResult = await pool.query(
      `SELECT COUNT(DISTINCT n.news_id) as total 
       FROM news n
       INNER JOIN news_categories nc ON n.news_id = nc.news_id
       WHERE nc.category_id = $1 AND n.status = 'published'`,
      [category.category_id]
    );
    const totalNews = parseInt(countResult.rows[0].total);

    const newsQuery = `
      SELECT DISTINCT ON (n.news_id)
        n.news_id, n.title, n.excerpt, n.slug, n.image_url,
        n.reading_time, n.views, n.likes_count, n.published_at,
        n.tags, n.meta_description, n.content,
        COALESCE(a.first_name, 'Daily Vaibe') as first_name,
        COALESCE(a.last_name, 'Editor') as last_name,
        pc.name as category_name, 
        pc.slug as category_slug, 
        pc.color as category_color
      FROM news n
      INNER JOIN news_categories nc ON n.news_id = nc.news_id
      LEFT JOIN admins a ON n.author_id = a.admin_id
      LEFT JOIN news_categories pnc ON n.news_id = pnc.news_id AND pnc.is_primary = true
      LEFT JOIN categories pc ON pnc.category_id = pc.category_id
      WHERE nc.category_id = $1 AND n.status = 'published'
      ORDER BY n.news_id, n.published_at DESC
      OFFSET $2 LIMIT $3
    `;

    const newsResult = await pool.query(newsQuery, [category.category_id, offset, limit]);

    const processedNews = newsResult.rows.map(article => ({
      ...article,
      image_url: getImageUrl(article.image_url),
      tags: article.tags ? article.tags.split(',').map(t => t.trim()).filter(Boolean) : []
    }));

    const totalPages = Math.ceil(totalNews / limit);

    return res.json({
      success: true,
      category,
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
    console.error(`Category news error for ${req.params.slug}:`, error);
    return res.status(500).json({
      success: false,
      message: 'Internal server error',
      news: [],
      error: process.env.NODE_ENV === 'development' ? error.message : undefined
    });
  }
});

router.get('/:slug/featured', async (req, res) => {
  res.set({
    'Cache-Control': 'public, max-age=300, s-maxage=600, stale-while-revalidate=1800',
    'CDN-Cache-Control': 'max-age=600, stale-while-revalidate=1800',
    'Vary': 'Accept-Encoding'
  });

  try {
    const pool = getPool();
    const { slug } = req.params;
    const limit = Math.min(50, Math.max(1, parseInt(req.query.limit || '10')));

    const categoryResult = await pool.query(
      `SELECT category_id FROM categories WHERE slug = $1 AND active = true`,
      [slug]
    );

    if (categoryResult.rows.length === 0) {
      return res.status(404).json({
        success: false,
        message: `Category '${slug}' not found`,
        featured_news: []
      });
    }

    const categoryId = categoryResult.rows[0].category_id;

    const newsResult = await pool.query(`
      SELECT DISTINCT ON (n.news_id)
        n.news_id, n.title, n.excerpt, n.slug, n.image_url, n.published_at,
        n.reading_time, n.views, n.likes_count,
        COALESCE(a.first_name, 'Daily Vaibe') as first_name,
        COALESCE(a.last_name, 'Editor') as last_name,
        pc.name as category_name, 
        pc.slug as category_slug,
        f.tier as featured_tier,
        f.ends_at as featured_until
      FROM news n
      INNER JOIN news_categories nc ON n.news_id = nc.news_id
      LEFT JOIN admins a ON n.author_id = a.admin_id
      LEFT JOIN news_categories pnc ON n.news_id = pnc.news_id AND pnc.is_primary = true
      LEFT JOIN categories pc ON pnc.category_id = pc.category_id
      INNER JOIN featured_news f ON n.news_id = f.news_id
      WHERE nc.category_id = $1 
        AND n.status = 'published' 
        AND f.manually_removed = false
        AND (f.ends_at IS NULL OR f.ends_at > CURRENT_TIMESTAMP)
      ORDER BY n.news_id,
        CASE f.tier
          WHEN 'gold' THEN 1
          WHEN 'silver' THEN 2
          WHEN 'bronze' THEN 3
          ELSE 4
        END,
        f.ends_at DESC NULLS LAST,
        n.published_at DESC
      LIMIT $2
    `, [categoryId, limit]);

    const processedNews = newsResult.rows.map(article => ({
      ...article,
      image_url: getImageUrl(article.image_url)
    }));

    return res.json({
      success: true,
      featured_news: processedNews,
      category_slug: slug,
      total: processedNews.length
    });
  } catch (error) {
    console.error(`Category featured error:`, error);
    return res.status(500).json({
      success: false,
      featured_news: [],
      error: process.env.NODE_ENV === 'development' ? error.message : undefined
    });
  }
});

router.get('/:slug/trending', async (req, res) => {
  res.set({
    'Cache-Control': 'public, max-age=120, s-maxage=240, stale-while-revalidate=600',
    'CDN-Cache-Control': 'max-age=240, stale-while-revalidate=600',
    'Vary': 'Accept-Encoding'
  });

  try {
    const pool = getPool();
    const { slug } = req.params;
    const limit = Math.min(50, Math.max(1, parseInt(req.query.limit || '10')));
    const days = Math.min(30, Math.max(1, parseInt(req.query.days || '7')));

    const categoryResult = await pool.query(
      `SELECT category_id FROM categories WHERE slug = $1 AND active = true`,
      [slug]
    );

    if (categoryResult.rows.length === 0) {
      return res.status(404).json({
        success: false,
        message: `Category '${slug}' not found`,
        trending_news: []
      });
    }

    const categoryId = categoryResult.rows[0].category_id;

    const newsResult = await pool.query(`
      SELECT DISTINCT ON (n.news_id)
        n.news_id, n.title, n.excerpt, n.slug, n.image_url, n.published_at,
        n.reading_time, n.views, n.likes_count, n.share_count, n.comments_count,
        COALESCE(a.first_name, 'Daily Vaibe') as first_name,
        COALESCE(a.last_name, 'Editor') as last_name,
        pc.name as category_name, 
        pc.slug as category_slug,
        (COALESCE(n.views, 0) * 1 + COALESCE(n.likes_count, 0) * 3 +
         COALESCE(n.share_count, 0) * 5 + COALESCE(n.comments_count, 0) * 2) as engagement_score
      FROM news n
      INNER JOIN news_categories nc ON n.news_id = nc.news_id
      LEFT JOIN admins a ON n.author_id = a.admin_id
      LEFT JOIN news_categories pnc ON n.news_id = pnc.news_id AND pnc.is_primary = true
      LEFT JOIN categories pc ON pnc.category_id = pc.category_id
      WHERE nc.category_id = $1 AND n.status = 'published'
        AND n.published_at >= NOW() - INTERVAL '1 day' * $3
      ORDER BY n.news_id, engagement_score DESC, n.published_at DESC
      LIMIT $2
    `, [categoryId, limit, days]);

    const processedNews = newsResult.rows.map(article => ({
      ...article,
      image_url: getImageUrl(article.image_url)
    }));

    return res.json({
      success: true,
      trending_news: processedNews,
      category_slug: slug,
      total: processedNews.length,
      period_days: days
    });
  } catch (error) {
    console.error(`Category trending error:`, error);
    return res.status(500).json({
      success: false,
      trending_news: [],
      error: process.env.NODE_ENV === 'development' ? error.message : undefined
    });
  }
});

module.exports = router;