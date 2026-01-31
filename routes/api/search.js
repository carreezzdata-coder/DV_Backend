const express = require('express');
const { getPool } = require('../../config/db');
const cloudflareService = require('../../services/cloudflareService');



const { FRONTEND_URL, CLIENT_URL, ADMIN_URL, API_DOMAIN, ALLOWED_ORIGINS, isOriginAllowed } = require('../../config/frontendconfig');

const router = express.Router();

const getImageUrl = (imageUrl) => {
  if (!imageUrl) return '';
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

router.get('/', async (req, res) => {
  res.set({
    'Cache-Control': 'public, max-age=180, s-maxage=300, stale-while-revalidate=1800',
    'CDN-Cache-Control': 'max-age=300',
    'Vary': 'Accept-Encoding, Accept-Language',
    'X-Content-Type-Options': 'nosniff',
    'X-Frame-Options': 'SAMEORIGIN',
    'X-XSS-Protection': '1; mode=block'
  });

  try {
    const pool = getPool();
    const { q, limit = '10', categories, sort = 'relevance', offset = '0' } = req.query;

    if (!q || q.trim().length === 0) {
      return res.json({
        success: true,
        results: [],
        total: 0,
        query: '',
        page: 1,
        total_pages: 0
      });
    }

    const searchQuery = q.trim();
    const searchLimit = Math.min(50, Math.max(1, parseInt(limit)));
    const searchOffset = Math.max(0, parseInt(offset));

    let categoryFilter = '';
    let queryParams = [searchQuery, searchLimit, searchOffset];
    let paramIndex = 4;

    if (categories && categories.trim()) {
      const categoryArray = categories.split(',').map(c => c.trim());
      categoryFilter = `AND c.slug = ANY($${paramIndex})`;
      queryParams.push(categoryArray);
      paramIndex++;
    }

    let sortClause = '';
    switch (sort) {
      case 'recent':
        sortClause = 'ORDER BY n.published_at DESC';
        break;
      case 'popular':
        sortClause = 'ORDER BY COALESCE(n.views, 0) DESC, n.published_at DESC';
        break;
      case 'trending':
        sortClause = `ORDER BY
          (COALESCE(n.views, 0) * 1 + COALESCE(n.likes_count, 0) * 3 + COALESCE(n.share_count, 0) * 5) DESC,
          n.published_at DESC`;
        break;
      case 'relevance':
      default:
        sortClause = `ORDER BY
          ts_rank(
            to_tsvector('english', n.title || ' ' || n.excerpt || ' ' || COALESCE(n.tags, '')),
            plainto_tsquery('english', $1)
          ) DESC,
          n.published_at DESC`;
        break;
    }

    const searchSQL = `
      SELECT
        n.news_id,
        n.title,
        n.excerpt,
        n.slug,
        n.category_id,
        n.primary_category_id,
        n.editor_pick,
        n.tags,
        n.reading_time,
        n.views,
        n.likes_count,
        n.comments_count,
        n.share_count,
        n.published_at,
        n.meta_description,
        COALESCE(ni.image_url, n.image_url) as image_url,
        COALESCE(a.first_name, 'VybesTribe') as first_name,
        COALESCE(a.last_name, 'Editor') as last_name,
        a.email as author_email,
        c.name as category_name,
        c.slug as category_slug,
        c.color as category_color,
        c.icon as category_icon,
        pc.name as primary_category_name,
        pc.slug as primary_category_slug,
        ts_rank(
          to_tsvector('english', n.title || ' ' || n.excerpt || ' ' || COALESCE(n.tags, '')),
          plainto_tsquery('english', $1)
        ) as relevance_score
      FROM news n
      LEFT JOIN admins a ON n.author_id = a.admin_id
      LEFT JOIN categories c ON n.category_id = c.category_id
      LEFT JOIN categories pc ON n.primary_category_id = pc.category_id
      LEFT JOIN LATERAL (
        SELECT image_url FROM news_images
        WHERE news_id = n.news_id AND is_featured = true
        ORDER BY display_order ASC
        LIMIT 1
      ) ni ON true
      WHERE n.status = 'published'
        AND (
          to_tsvector('english', n.title || ' ' || n.excerpt || ' ' || COALESCE(n.tags, '')) @@ plainto_tsquery('english', $1)
          OR n.title ILIKE '%' || $1 || '%'
          OR n.excerpt ILIKE '%' || $1 || '%'
          OR n.tags ILIKE '%' || $1 || '%'
        )
        ${categoryFilter}
      ${sortClause}
      LIMIT $2 OFFSET $3
    `;

    const results = await pool.query(searchSQL, queryParams);

    const countSQL = `
      SELECT COUNT(*) as total
      FROM news n
      LEFT JOIN categories c ON n.category_id = c.category_id
      WHERE n.status = 'published'
        AND (
          to_tsvector('english', n.title || ' ' || n.excerpt || ' ' || COALESCE(n.tags, '')) @@ plainto_tsquery('english', $1)
          OR n.title ILIKE '%' || $1 || '%'
          OR n.excerpt ILIKE '%' || $1 || '%'
          OR n.tags ILIKE '%' || $1 || '%'
        )
        ${categoryFilter}
    `;

    const countParams = categoryFilter ? [searchQuery, queryParams[3]] : [searchQuery];
    const countResult = await pool.query(countSQL, countParams);
    const totalResults = parseInt(countResult.rows[0].total);
    const totalPages = Math.ceil(totalResults / searchLimit);
    const currentPage = Math.floor(searchOffset / searchLimit) + 1;

    const processedResults = results.rows.map(article => ({
      news_id: article.news_id.toString(),
      title: article.title,
      excerpt: article.excerpt || article.title?.substring(0, 150) + '...',
      slug: article.slug,
      image_url: getImageUrl(article.image_url),
      thumbnail_url: getImageUrl(article.image_url),
      tags: article.tags ? article.tags.split(',').map(t => t.trim()).filter(Boolean) : [],
      reading_time: article.reading_time || 3,
      views: article.views || 0,
      likes_count: article.likes_count || 0,
      comments_count: article.comments_count || 0,
      share_count: article.share_count || 0,
      published_at: article.published_at,
      meta_description: article.meta_description,
      editor_pick: article.editor_pick || false,
      author_name: `${article.first_name} ${article.last_name}`,
      author: {
        first_name: article.first_name,
        last_name: article.last_name,
        full_name: `${article.first_name} ${article.last_name}`,
        email: article.author_email
      },
      category: {
        category_id: article.category_id,
        name: article.category_name,
        slug: article.category_slug,
        color: article.category_color,
        icon: article.category_icon
      },
      primary_category: article.primary_category_id ? {
        category_id: article.primary_category_id,
        name: article.primary_category_name,
        slug: article.primary_category_slug
      } : null,
      first_name: article.first_name,
      last_name: article.last_name,
      category_name: article.category_name,
      category_slug: article.category_slug,
      relevance_score: parseFloat(article.relevance_score || 0).toFixed(4),
      url: `/article/${article.slug}`
    }));

    return res.json({
      success: true,
      results: processedResults,
      total: totalResults,
      query: searchQuery,
      sort: sort,
      categories: categories || null,
      pagination: {
        current_page: currentPage,
        total_pages: totalPages,
        per_page: searchLimit,
        offset: searchOffset,
        has_next: currentPage < totalPages,
        has_prev: currentPage > 1
      },
      search_meta: {
        query_time: new Date().toISOString(),
        result_count: processedResults.length
      }
    });

  } catch (error) {
    console.error('Search error:', error);
    return res.status(500).json({
      success: false,
      message: 'Search failed',
      error: process.env.NODE_ENV === 'development' ? error.message : 'Internal server error'
    });
  }
});

router.get('/suggestions', async (req, res) => {
  res.set({
    'Cache-Control': 'public, max-age=300, s-maxage=600, stale-while-revalidate=3600',
    'CDN-Cache-Control': 'max-age=600',
    'Vary': 'Accept-Encoding',
    'X-Content-Type-Options': 'nosniff'
  });

  try {
    const pool = getPool();
    const { q, limit = '5' } = req.query;

    if (!q || q.trim().length < 2) {
      return res.json({
        success: true,
        suggestions: []
      });
    }

    const searchQuery = q.trim();
    const searchLimit = Math.min(10, Math.max(1, parseInt(limit)));

    const suggestionsSQL = `
      SELECT DISTINCT
        n.news_id,
        n.title,
        n.slug,
        COALESCE(ni.image_url, n.image_url) as image_url,
        n.excerpt,
        c.name as category_name,
        c.slug as category_slug,
        c.color as category_color,
        COALESCE(n.views, 0) as views,
        COALESCE(a.first_name, 'VybesTribe') as first_name,
        COALESCE(a.last_name, 'Editor') as last_name
      FROM news n
      LEFT JOIN categories c ON n.category_id = c.category_id
      LEFT JOIN admins a ON n.author_id = a.admin_id
      LEFT JOIN LATERAL (
        SELECT image_url FROM news_images
        WHERE news_id = n.news_id AND is_featured = true
        LIMIT 1
      ) ni ON true
      WHERE n.status = 'published'
        AND (n.title ILIKE $1 || '%' OR n.tags ILIKE '%' || $1 || '%')
      ORDER BY COALESCE(n.views, 0) DESC, n.published_at DESC
      LIMIT $2
    `;

    const results = await pool.query(suggestionsSQL, [searchQuery, searchLimit]);

    const processedSuggestions = results.rows.map(item => ({
      news_id: item.news_id.toString(),
      title: item.title,
      slug: item.slug,
      image_url: getImageUrl(item.image_url),
      excerpt: item.excerpt ? item.excerpt.substring(0, 100) + '...' : null,
      category_name: item.category_name,
      category_slug: item.category_slug,
      category_color: item.category_color,
      views: item.views || 0,
      author_name: `${item.first_name} ${item.last_name}`,
      url: `/article/${item.slug}`
    }));

    return res.json({
      success: true,
      suggestions: processedSuggestions,
      query: searchQuery
    });

  } catch (error) {
    console.error('Suggestions error:', error);
    return res.status(500).json({
      success: false,
      message: 'Failed to fetch suggestions',
      suggestions: []
    });
  }
});

router.get('/trending', async (req, res) => {
  res.set({
    'Cache-Control': 'public, max-age=180, s-maxage=300, stale-while-revalidate=1800',
    'CDN-Cache-Control': 'max-age=300',
    'Vary': 'Accept-Encoding',
    'X-Content-Type-Options': 'nosniff'
  });

  try {
    const pool = getPool();
    const limit = Math.min(20, Math.max(1, parseInt(req.query.limit || '10')));
    const days = Math.min(7, Math.max(1, parseInt(req.query.days || '1')));

    const trendingSQL = `
      SELECT
        n.news_id,
        n.title,
        n.slug,
        COALESCE(ni.image_url, n.image_url) as image_url,
        n.excerpt,
        n.views,
        n.likes_count,
        n.share_count,
        n.published_at,
        c.name as category_name,
        c.slug as category_slug,
        COALESCE(a.first_name, 'VybesTribe') as first_name,
        COALESCE(a.last_name, 'Editor') as last_name,
        (COALESCE(n.views, 0) + COALESCE(n.likes_count, 0) * 3 + COALESCE(n.share_count, 0) * 5) as engagement_score
      FROM news n
      LEFT JOIN categories c ON n.category_id = c.category_id
      LEFT JOIN admins a ON n.author_id = a.admin_id
      LEFT JOIN LATERAL (
        SELECT image_url FROM news_images
        WHERE news_id = n.news_id AND is_featured = true
        LIMIT 1
      ) ni ON true
      WHERE n.status = 'published'
        AND n.published_at >= NOW() - INTERVAL '1 day' * $2
      ORDER BY engagement_score DESC, n.published_at DESC
      LIMIT $1
    `;

    const results = await pool.query(trendingSQL, [limit, days]);

    const processedTrending = results.rows.map(item => ({
      news_id: item.news_id.toString(),
      title: item.title,
      slug: item.slug,
      image_url: getImageUrl(item.image_url),
      excerpt: item.excerpt,
      views: item.views || 0,
      likes_count: item.likes_count || 0,
      share_count: item.share_count || 0,
      published_at: item.published_at,
      category_name: item.category_name,
      category_slug: item.category_slug,
      author_name: `${item.first_name} ${item.last_name}`,
      first_name: item.first_name,
      last_name: item.last_name,
      engagement_score: parseInt(item.engagement_score),
      url: `/article/${item.slug}`
    }));

    return res.json({
      success: true,
      trending: processedTrending,
      total: processedTrending.length,
      period_days: days
    });

  } catch (error) {
    console.error('Trending error:', error);
    return res.status(500).json({
      success: false,
      message: 'Failed to fetch trending articles',
      trending: []
    });
  }
});

module.exports = router;