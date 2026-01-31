const { getPool } = require('../config/db');

const GROUP_SLUGS = [
  'world', 'counties', 'politics', 'business', 'opinion',
  'sports', 'lifestyle', 'entertainment', 'tech', 'other'
];

const checkCategoryType = async (slug) => {
  if (GROUP_SLUGS.includes(slug)) {
    return { type: 'group', slug };
  }

  try {
    const pool = getPool();
    const result = await pool.query(
      `SELECT category_id, name, slug, parent_id, 
              color, icon, description
       FROM categories 
       WHERE slug = $1 AND active = true`,
      [slug]
    );

    if (result.rows.length === 0) {
      return { type: 'not_found', slug };
    }

    const category = result.rows[0];

    if (category.parent_id) {
      return { type: 'sub-category', category };
    }

    return { type: 'category', category };
  } catch (error) {
    console.error('[category-alignment] Error checking category type:', error);
    return { type: 'error', slug, error: error.message };
  }
};

const categoryTypeMiddleware = async (req, res, next) => {
  try {
    const { slug } = req.params;
    const typeInfo = await checkCategoryType(slug);

    req.categoryType = typeInfo.type;
    req.categoryData = typeInfo.category || null;
    req.categorySlug = slug;

    next();
  } catch (error) {
    console.error('[category-alignment] Middleware error:', error);
    return res.status(500).json({
      success: false,
      message: 'Failed to determine category type'
    });
  }
};

module.exports = {
  checkCategoryType,
  categoryTypeMiddleware,
  GROUP_SLUGS
};