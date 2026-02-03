const express = require('express');
const router = express.Router();

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
  22: {
    groupKey: 'other',
    title: 'Other',
    icon: '📌',
    description: 'Miscellaneous categories',
    color: '#0233df'
  }
};

router.get('/', async (req, res) => {
  console.log('=== CATEGORIES GET REQUEST RECEIVED ===');
  console.log('Timestamp:', new Date().toISOString());
  console.log('URL:', req.url);
  console.log('Method:', req.method);
  console.log('Headers:', JSON.stringify(req.headers, null, 2));

  let pool;
  
  try {
    console.log('[Step 1] Getting database pool...');
    const { getPool } = require('../../config/db');
    pool = getPool();
    
    if (!pool) {
      console.error('[Step 1] FAILED: Pool is null or undefined');
      return res.status(500).json({
        success: false,
        message: 'Database connection pool not available',
        error: 'Pool is null',
        step: 'get_pool'
      });
    }
    
    console.log('[Step 1] SUCCESS: Pool obtained');

    console.log('[Step 2] Executing database query...');
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
    console.log('[Step 2] SUCCESS: Query executed');
    console.log(`[Step 2] Rows returned: ${result.rows.length}`);
    
    if (result.rows.length > 0) {
      console.log('[Step 2] First row sample:', JSON.stringify(result.rows[0], null, 2));
    }

    if (result.rows.length === 0) {
      console.warn('[Step 2] WARNING: No categories found in database');
      return res.status(200).json({
        success: true,
        groups: {},
        total_categories: 0,
        message: 'No categories found in database'
      });
    }

    console.log('[Step 3] Processing categories...');
    const parents = result.rows.filter(cat => cat.parent_id === null);
    const children = result.rows.filter(cat => cat.parent_id !== null);

    console.log(`[Step 3] Parents found: ${parents.length}`);
    console.log(`[Step 3] Children found: ${children.length}`);
    
    if (parents.length > 0) {
      console.log('[Step 3] Parent IDs:', parents.map(p => p.category_id).join(', '));
    }

    const groups = {};
    let totalCategories = 0;

    console.log('[Step 4] Building groups...');
    for (const parent of parents) {
      console.log(`[Step 4] Processing parent: ${parent.category_id} (${parent.name})`);
      
      const metadata = CATEGORY_GROUP_METADATA[parent.category_id];

      if (!metadata) {
        console.warn(`[Step 4] WARNING: No metadata for parent ID ${parent.category_id}`);
        console.warn(`[Step 4] Available metadata IDs: ${Object.keys(CATEGORY_GROUP_METADATA).join(', ')}`);
        continue;
      }

      const parentChildren = children.filter(cat => cat.parent_id === parent.category_id);
      const groupKey = metadata.groupKey;

      console.log(`[Step 4] Group "${groupKey}" has ${parentChildren.length} children`);

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

    console.log('[Step 5] Handling orphaned categories...');
    const validParentIds = parents.map(p => p.category_id);
    const orphanedChildren = children.filter(cat => !validParentIds.includes(cat.parent_id));

    if (orphanedChildren.length > 0) {
      console.warn(`[Step 5] Found ${orphanedChildren.length} orphaned categories`);
      console.warn(`[Step 5] Orphaned parent IDs: ${[...new Set(orphanedChildren.map(c => c.parent_id))].join(', ')}`);

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

    console.log('[Step 6] Preparing response...');
    console.log(`[Step 6] Total groups: ${Object.keys(groups).length}`);
    console.log(`[Step 6] Total categories: ${totalCategories}`);
    console.log(`[Step 6] Group keys: ${Object.keys(groups).join(', ')}`);

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

    console.log('[Step 7] Sending response...');
    console.log('[Step 7] SUCCESS - Response prepared');
    
    return res.status(200).json(response);

  } catch (error) {
    console.error('=== CATEGORIES ERROR ===');
    console.error('Error name:', error.name);
    console.error('Error message:', error.message);
    console.error('Error stack:', error.stack);
    
    if (error.code) {
      console.error('Error code:', error.code);
    }
    
    if (error.detail) {
      console.error('Error detail:', error.detail);
    }

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
