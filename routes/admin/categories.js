const express = require('express');
const router = express.Router();
const { getPool } = require('../../config/db');
const cloudflareService = require('../../services/cloudflareService');
const { FRONTEND_URL, CLIENT_URL, ADMIN_URL, API_DOMAIN, ALLOWED_ORIGINS, isOriginAllowed } = require('../../config/frontendconfig');

const CATEGORY_GROUP_METADATA = {
  1: {
    groupKey: 'live-world',
    title: 'Live & World',
    icon: '🌍',
    description: 'Global news and international affairs',
    color: '#2563eb'
  },
  14: {
    groupKey: 'counties',
    title: 'Counties',
    icon: '🏢',
    description: 'County-level news and developments',
    color: '#7c3aed'
  },
  15: {
    groupKey: 'politics',
    title: 'Politics',
    icon: '🏛️',
    description: 'Political news and analysis',
    color: '#dc2626'
  },
  16: {
    groupKey: 'business',
    title: 'Business',
    icon: '💼',
    description: 'Business, economy and finance',
    color: '#059669'
  },
  17: {
    groupKey: 'opinion',
    title: 'Opinion',
    icon: '💭',
    description: 'Opinion pieces and editorials',
    color: '#ea580c'
  },
  18: {
    groupKey: 'sports',
    title: 'Sports',
    icon: '⚽',
    description: 'Sports news and events',
    color: '#0891b2'
  },
  19: {
    groupKey: 'lifestyle',
    title: 'Life & Style',
    icon: '🎭',
    description: 'Lifestyle, fashion and culture',
    color: '#db2777'
  },
  20: {
    groupKey: 'entertainment',
    title: 'Entertainment',
    icon: '🎉',
    description: 'Entertainment and celebrity news',
    color: '#8b5cf6'
  },
  21: {
    groupKey: 'tech',
    title: 'Technology',
    icon: '💻',
    description: 'Technology news and innovations',
    color: '#0284c7'
  },
  100: {
    groupKey: 'health',
    title: 'Health',
    icon: '🏥',
    description: 'Health, wellness and medical news',
    color: '#16a085'
  },
  106: {
    groupKey: 'education',
    title: 'Education',
    icon: '📚',
    description: 'Education news, exams and learning',
    color: '#3498db'
  },
  112: {
    groupKey: 'crime-security',
    title: 'Crime & Security',
    icon: '🚔',
    description: 'Crime reports and security updates',
    color: '#c0392b'
  },
  22: {
    groupKey: 'other',
    title: 'Other',
    icon: '📌',
    description: 'Miscellaneous categories',
    color: '#0233df'
  }
};

router.get('/', async (req, res) => {
  let pool;
  
  try {
    const { getPool } = require('../../config/db');
    pool = getPool();
    
    if (!pool) {
      return res.status(500).json({
        success: false,
        message: 'Database connection pool not available',
        error: 'Pool is null'
      });
    }

    const categoriesQuery = `
      SELECT
        c.category_id,
        c.name,
        c.slug,
        c.parent_id,
        c.description,
        c.color,
        c.icon,
        c.order_index
      FROM categories c
      WHERE c.active = true
      ORDER BY c.parent_id NULLS FIRST, c.order_index ASC, c.name ASC
    `;

    const result = await pool.query(categoriesQuery);

    if (result.rows.length === 0) {
      return res.status(200).json({
        success: true,
        groups: {},
        total_categories: 0,
        message: 'No categories found in database'
      });
    }

    const parents = result.rows.filter(cat => cat.parent_id === null);
    const children = result.rows.filter(cat => cat.parent_id !== null);

    const groups = {};
    let totalCategories = 0;

    for (const parent of parents) {
      const metadata = CATEGORY_GROUP_METADATA[parent.category_id];

      if (!metadata) {
        continue;
      }

      const parentChildren = children.filter(cat => cat.parent_id === parent.category_id);
      const groupKey = metadata.groupKey;

      groups[groupKey] = {
        title: metadata.title,
        icon: metadata.icon,
        description: metadata.description,
        color: metadata.color,
        parent_category: {
          category_id: parent.category_id,
          name: parent.name,
          slug: parent.slug,
          color: parent.color,
          icon: parent.icon
        },
        categories: parentChildren.map(cat => ({
          category_id: cat.category_id,
          name: cat.name,
          slug: cat.slug,
          parent_id: cat.parent_id,
          description: cat.description,
          color: cat.color,
          icon: cat.icon,
          order_index: cat.order_index,
          group: groupKey
        }))
      };

      totalCategories += parentChildren.length;
    }

    const validParentIds = parents.map(p => p.category_id);
    const orphanedChildren = children.filter(cat => !validParentIds.includes(cat.parent_id));

    if (orphanedChildren.length > 0) {
      if (!groups['other']) {
        groups['other'] = {
          title: 'Other',
          icon: '📌',
          description: 'Miscellaneous categories',
          color: '#0233df',
          parent_category: null,
          categories: []
        };
      }

      groups['other'].categories.push(...orphanedChildren.map(cat => ({
        category_id: cat.category_id,
        name: cat.name,
        slug: cat.slug,
        parent_id: cat.parent_id,
        description: cat.description,
        color: cat.color,
        icon: cat.icon,
        order_index: cat.order_index,
        group: 'other'
      })));

      totalCategories += orphanedChildren.length;
    }

    const response = {
      success: true,
      groups: groups,
      total_categories: totalCategories,
      message: 'Categories fetched successfully',
      metadata: {
        group_count: Object.keys(groups).length,
        parent_count: parents.length,
        has_other_group: 'other' in groups,
        timestamp: new Date().toISOString()
      }
    };
    
    return res.status(200).json(response);

  } catch (error) {
    return res.status(500).json({
      success: false,
      message: 'Internal server error while fetching categories',
      error: error.message,
      errorCode: error.code || 'UNKNOWN',
      errorName: error.name || 'Error',
      timestamp: new Date().toISOString()
    });
  }
});

module.exports = router;
