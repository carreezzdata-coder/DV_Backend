// backend/routes/admin/categories.js
const express = require('express');
const { FRONTEND_URL, CLIENT_URL, ADMIN_URL, API_DOMAIN, ALLOWED_ORIGINS, isOriginAllowed } = require('../../config/frontendconfig');
const requireAdminAuth = require('../../middleware/adminAuth');
const { requirePublisher, requireApprover, requireEditor, requireDeleter } = require('../../middleware/rolePermissions');
const router = express.Router();
const { getPool } = require('../../config/db');

// EXACT metadata from createposts.js
const CATEGORY_GROUP_METADATA = {
  1: { // World parent_id
    groupKey: 'live-world',
    title: 'Live & World',
    icon: '🌍',
    description: 'Global news and international affairs',
    color: '#2563eb'
  },
  14: { // Counties parent_id
    groupKey: 'counties',
    title: 'Counties',
    icon: '🏢',
    description: 'County-level news and developments',
    color: '#7c3aed'
  },
  15: { // Politics parent_id
    groupKey: 'politics',
    title: 'Politics',
    icon: '🏛️',
    description: 'Political news and analysis',
    color: '#dc2626'
  },
  16: { // Business parent_id
    groupKey: 'business',
    title: 'Business',
    icon: '💼',
    description: 'Business, economy and finance',
    color: '#059669'
  },
  17: { // Opinion parent_id
    groupKey: 'opinion',
    title: 'Opinion',
    icon: '💭',
    description: 'Opinion pieces and editorials',
    color: '#ea580c'
  },
  18: { // Sports parent_id
    groupKey: 'sports',
    title: 'Sports',
    icon: '⚽',
    description: 'Sports news and events',
    color: '#0891b2'
  },
  19: { // Life & Style parent_id
    groupKey: 'lifestyle',
    title: 'Life & Style',
    icon: '🎭',
    description: 'Lifestyle, fashion and culture',
    color: '#db2777'
  },
  20: { // Entertainment parent_id
    groupKey: 'entertainment',
    title: 'Entertainment',
    icon: '🎉',
    description: 'Entertainment and celebrity news',
    color: '#8b5cf6'
  },
  21: { // Technology parent_id
    groupKey: 'tech',
    title: 'Technology',
    icon: '💻',
    description: 'Technology news and innovations',
    color: '#0284c7'
  },
  22: { // Other parent_id
    groupKey: 'other',
    title: 'Other',
    icon: '📌',
    description: 'Miscellaneous categories',
    color: '#0233df'
  }
};

router.get('/', async (req, res) => {
  try {
    console.log('[Backend Categories] GET request received');
    const pool = getPool();

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
    console.log(`[Backend Categories] Query returned ${result.rows.length} total rows`);

    if (result.rows.length === 0) {
      return res.status(200).json({
        success: true,
        groups: {},
        total_categories: 0,
        message: 'No categories found'
      });
    }

    const groups = {};
    let totalCategories = 0;

    const parents = result.rows.filter(cat => cat.parent_id === null);
    const children = result.rows.filter(cat => cat.parent_id !== null);

    console.log(`[Backend Categories] Found ${parents.length} parents, ${children.length} children`);

    for (const parent of parents) {
      const metadata = CATEGORY_GROUP_METADATA[parent.category_id];

      if (!metadata) {
        console.warn(`[Backend Categories] No metadata for parent ${parent.category_id} (${parent.name})`);
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
      console.log(`[Backend Categories] Group ${groupKey}: ${parentChildren.length} categories`);
    }

    // Handle orphaned categories
    const validParentIds = parents.map(p => p.category_id);
    const orphanedChildren = children.filter(cat => !validParentIds.includes(cat.parent_id));

    if (orphanedChildren.length > 0) {
      console.warn(`[Backend Categories] ${orphanedChildren.length} orphaned categories`);

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

    console.log(`[Backend Categories] Returning ${totalCategories} categories in ${Object.keys(groups).length} groups`);

    return res.status(200).json({
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
    });

  } catch (error) {
    console.error('[Backend Categories] Error:', error);
    return res.status(500).json({
      success: false,
      message: 'Internal server error',
      error: error.message
    });
  }
});

module.exports = router;
