// routes/api/footer-categories.js
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

const CATEGORY_GROUPS = {
  'world': {
    title: 'World',
    icon: '🌍',
    description: 'International and national news coverage',
    color: '#2563eb',
    order: 1,
    patterns: ['national', 'east-africa', 'africa', 'international', 'live', 'world-reports']
  },
  'counties': {
    title: 'Counties',
    icon: '🏢',
    description: 'Regional news coverage across Kenya',
    color: '#3498db',
    order: 2,
    patterns: ['nairobi', 'coast', 'mountain', 'lake-region', 'rift-valley', 'northern', 'eastern', 'western', 'county-reports']
  },
  'politics': {
    title: 'Politics',
    icon: '🏛️',
    description: 'Political news and governance',
    color: '#e74c3c',
    order: 3,
    patterns: ['politics', 'governance', 'legal', 'elections', 'parliament', 'political-reports', 'politics-others']
  },
  'business': {
    title: 'Business',
    icon: '💼',
    description: 'Business, economy and finance news',
    color: '#2ecc71',
    order: 4,
    patterns: ['business', 'companies', 'finance-markets', 'investment', 'enterprise', 'economy', 'banking', 'business-reports']
  },
  'opinion': {
    title: 'Opinion',
    icon: '💭',
    description: 'Editorials and commentary',
    color: '#9b59b6',
    order: 5,
    patterns: ['opinion', 'editorials', 'columnists', 'bloggers', 'letters', 'trail-blazing', 'ai-graphics', 'analysis']
  },
  'sports': {
    title: 'Sports',
    icon: '⚽',
    description: 'Sports news and analysis',
    color: '#f39c12',
    order: 6,
    patterns: ['sports', 'sport', 'football', 'athletics', 'rugby', 'motorsport', 'sports-vybe', 'cricket', 'basketball', 'other-sports', 'sports-others']
  },
  'lifestyle': {
    title: 'Life & Style',
    icon: '🎭',
    description: 'Lifestyle and culture',
    color: '#e91e63',
    order: 7,
    patterns: ['lifestyle', 'motoring', 'culture', 'family', 'relationships', 'travel', 'wellness', 'fashion', 'food', 'lifestyle-others']
  },
  'entertainment': {
    title: 'Entertainment',
    icon: '🎉',
    description: 'Entertainment and celebrity news',
    color: '#ff6b6b',
    order: 8,
    patterns: ['entertainment', 'buzz', 'trending', 'trending-pics', 'gossip', 'life-stories', 'music', 'movies', 'celebrity', 'entertainment-others']
  },
  'tech': {
    title: 'Technology',
    icon: '💻',
    description: 'Tech news and innovations',
    color: '#1abc9c',
    order: 9,
    patterns: ['tech', 'technology', 'innovations', 'gadgets', 'startups', 'digital-life', 'ai', 'mobile', 'gaming', 'tech-reports', 'tech-others']
  },
  'other': {
    title: 'Other',
    icon: '📌',
    description: 'Miscellaneous content',
    color: '#34495e',
    order: 10,
    patterns: ['other', 'others', 'human-rights', 'climate-crisis', 'investigations', 'interactives', 'features', 'in-pictures', 'special-reports']
  }
};

router.get('/', async (req, res) => {
  res.set({
    'Cache-Control': 'public, max-age=600, s-maxage=1800, stale-while-revalidate=86400',
    'CDN-Cache-Control': 'max-age=1800',
    'Vary': 'Accept-Encoding'
  });

  if (!dbModule) {
    return res.status(500).json({ success: false, message: 'Database not available', groups: {}, total_categories: 0 });
  }

  try {
    const { getPool } = dbModule;
    const pool = getPool();

    const categoriesQuery = `
      SELECT c.category_id, c.name, c.slug, c.description, c.color, c.icon, c.order_index, c.active, c.parent_id,
             COALESCE(stats.article_count, 0) as article_count, COALESCE(stats.latest_article, NULL) as latest_article
      FROM categories c
      LEFT JOIN (
        SELECT category_id, COUNT(*) as article_count, MAX(published_at) as latest_article
        FROM news WHERE status = 'published' GROUP BY category_id
      ) stats ON c.category_id = stats.category_id
      WHERE c.active = true ORDER BY c.order_index ASC, c.name ASC
    `;

    const result = await pool.query(categoriesQuery);
    const categories = result.rows;
    const groups = {};
    const categorizedIds = new Set();

    Object.entries(CATEGORY_GROUPS).forEach(([key, def]) => {
      groups[key] = {
        title: def.title,
        icon: def.icon,
        description: def.description,
        color: def.color,
        order: def.order,
        slug: key,
        mainSlug: key,
        categories: []
      };
    });

    categories.forEach(category => {
      if (categorizedIds.has(category.category_id)) return;
      const slug = category.slug.toLowerCase();
      if (slug === 'others' || slug === 'other') {
        categorizedIds.add(category.category_id);
        return;
      }
      let matched = false;
      for (const [groupKey, groupDef] of Object.entries(CATEGORY_GROUPS)) {
        if (groupKey === 'other') continue;
        if (groupDef.patterns.includes(slug)) {
          groups[groupKey].categories.push({
            category_id: category.category_id,
            name: category.name,
            slug: category.slug,
            description: category.description,
            color: category.color || groupDef.color,
            icon: category.icon || groupDef.icon,
            article_count: parseInt(category.article_count || 0),
            latest_article: category.latest_article,
            parent_id: category.parent_id
          });
          categorizedIds.add(category.category_id);
          matched = true;
          break;
        }
      }
      if (!matched && slug !== 'home') {
        groups['other'].categories.push({
          category_id: category.category_id,
          name: category.name,
          slug: category.slug,
          description: category.description,
          color: category.color || CATEGORY_GROUPS['other'].color,
          icon: category.icon || CATEGORY_GROUPS['other'].icon,
          article_count: parseInt(category.article_count || 0),
          latest_article: category.latest_article,
          parent_id: category.parent_id
        });
        categorizedIds.add(category.category_id);
      }
    });

    const filteredGroups = {};
    const groupOrder = ['world', 'counties', 'politics', 'business', 'opinion', 'sports', 'lifestyle', 'entertainment', 'tech', 'other'];

    groupOrder.forEach(key => {
      if (groups[key] && (groups[key].categories.length > 0 || key === 'other')) {
        filteredGroups[key] = groups[key];
      }
    });

    const totalArticles = categories.reduce((sum, c) => sum + parseInt(c.article_count || 0), 0);

    return res.json({
      success: true,
      groups: filteredGroups,
      all_categories: categories.map(c => ({
        category_id: c.category_id,
        name: c.name,
        slug: c.slug,
        description: c.description,
        color: c.color,
        icon: c.icon,
        article_count: parseInt(c.article_count || 0),
        parent_id: c.parent_id
      })),
      total_categories: categories.length,
      total_articles: totalArticles,
      seo: {
        sitemap_categories: categories.map(c => ({
          slug: c.slug,
          name: c.name,
          url: `/category/${c.slug}`,
          article_count: parseInt(c.article_count || 0)
        })),
        sitemap_groups: Object.entries(filteredGroups).map(([slug, group]) => ({
          slug,
          name: group.title,
          url: `/category/${slug}`,
          sub_categories: group.categories.length
        }))
      }
    });

  } catch (error) {
    console.error('Footer categories error:', error);
    return res.status(500).json({
      success: false,
      message: 'Failed to fetch grouped categories',
      error: process.env.NODE_ENV === 'development' ? error.message : undefined,
      groups: {},
      total_categories: 0
    });
  }
});

router.get('/all', async (req, res) => {
  res.set({
    'Cache-Control': 'public, max-age=600, s-maxage=1800, stale-while-revalidate=86400',
    'CDN-Cache-Control': 'max-age=1800',
    'Vary': 'Accept-Encoding'
  });

  if (!dbModule) return res.status(500).json({ success: false, categories: [], total: 0 });

  try {
    const { getPool } = dbModule;
    const pool = getPool();
    const query = `
      SELECT c.category_id, c.name, c.slug, c.description, c.color, c.icon, c.order_index, c.parent_id,
             COALESCE(COUNT(n.news_id), 0) as article_count
      FROM categories c
      LEFT JOIN news n ON c.category_id = n.category_id AND n.status = 'published'
      WHERE c.active = true
      GROUP BY c.category_id, c.name, c.slug, c.description, c.color, c.icon, c.order_index, c.parent_id
      ORDER BY c.order_index ASC, c.name ASC
    `;
    const result = await pool.query(query);
    return res.json({
      success: true,
      categories: result.rows.map(c => ({
        category_id: c.category_id,
        name: c.name,
        slug: c.slug,
        description: c.description,
        color: c.color,
        icon: c.icon,
        order_index: c.order_index,
        parent_id: c.parent_id,
        article_count: parseInt(c.article_count || 0)
      })),
      total: result.rows.length
    });
  } catch (error) {
    console.error('All categories error:', error);
    return res.status(500).json({
      success: false,
      categories: [],
      total: 0,
      error: process.env.NODE_ENV === 'development' ? error.message : undefined
    });
  }
});

router.get('/popular', async (req, res) => {
  res.set({
    'Cache-Control': 'public, max-age=300, s-maxage=600, stale-while-revalidate=1800',
    'CDN-Cache-Control': 'max-age=600',
    'Vary': 'Accept-Encoding'
  });

  if (!dbModule) return res.status(500).json({ success: false, popular_categories: [], total: 0 });

  try {
    const { getPool } = dbModule;
    const pool = getPool();
    const limit = Math.min(20, Math.max(1, parseInt(req.query.limit || '10')));
    const query = `
      SELECT c.category_id, c.name, c.slug, c.description, c.color, c.icon,
             COUNT(n.news_id) as article_count,
             COALESCE(SUM(n.views), 0) as total_views,
             COALESCE(SUM(n.likes_count), 0) as total_likes
      FROM categories c
      LEFT JOIN news n ON c.category_id = n.category_id AND n.status = 'published'
      WHERE c.active = true
      GROUP BY c.category_id, c.name, c.slug, c.description, c.color, c.icon
      HAVING COUNT(n.news_id) > 0
      ORDER BY total_views DESC, article_count DESC LIMIT $1
    `;
    const result = await pool.query(query, [limit]);
    return res.json({
      success: true,
      popular_categories: result.rows.map(c => ({
        category_id: c.category_id,
        name: c.name,
        slug: c.slug,
        description: c.description,
        color: c.color,
        icon: c.icon,
        article_count: parseInt(c.article_count || 0),
        total_views: parseInt(c.total_views || 0),
        total_likes: parseInt(c.total_likes || 0)
      })),
      total: result.rows.length
    });
  } catch (error) {
    console.error('Popular categories error:', error);
    return res.status(500).json({
      success: false,
      popular_categories: [],
      total: 0,
      error: process.env.NODE_ENV === 'development' ? error.message : undefined
    });
  }
});

router.get('/sitemap', async (req, res) => {
  res.set({
    'Cache-Control': 'public, max-age=3600, s-maxage=7200, stale-while-revalidate=86400',
    'CDN-Cache-Control': 'max-age=7200',
    'Vary': 'Accept-Encoding'
  });

  if (!dbModule) return res.status(500).json({ success: false, categories: [], groups: [] });

  try {
    const { getPool } = dbModule;
    const pool = getPool();
    const query = `
      SELECT c.slug, c.name, c.description, MAX(n.updated_at) as last_modified, COUNT(n.news_id) as article_count
      FROM categories c
      LEFT JOIN news n ON c.category_id = n.category_id AND n.status = 'published'
      WHERE c.active = true
      GROUP BY c.category_id, c.slug, c.name, c.description ORDER BY c.order_index ASC
    `;
    const result = await pool.query(query);
    const groupSlugs = Object.keys(CATEGORY_GROUPS);
    return res.json({
      success: true,
      categories: result.rows.map(c => ({
        loc: `/category/${c.slug}`,
        lastmod: c.last_modified || new Date().toISOString(),
        changefreq: parseInt(c.article_count) > 10 ? 'daily' : 'weekly',
        priority: parseInt(c.article_count) > 50 ? '0.8' : '0.6',
        name: c.name,
        description: c.description
      })),
      groups: groupSlugs.map(slug => ({
        loc: `/category/${slug}`,
        lastmod: new Date().toISOString(),
        changefreq: 'daily',
        priority: '0.9',
        name: CATEGORY_GROUPS[slug].title,
        description: CATEGORY_GROUPS[slug].description
      }))
    });
  } catch (error) {
    console.error('Sitemap categories error:', error);
    return res.status(500).json({
      success: false,
      categories: [],
      groups: [],
      error: process.env.NODE_ENV === 'development' ? error.message : undefined
    });
  }
});

module.exports = router;