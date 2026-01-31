const express = require('express');
const router = express.Router();
const { getPool } = require('../../config/db');

const requireAdmin = (req, res, next) => {
  if (!req.session.user || !req.session.user.is_admin) {
    return res.status(403).json({ success: false, error: 'Admin access required' });
  }
  next();
};

router.use(requireAdmin);

router.get('/featured', async (req, res) => {
  try {
    const pool = getPool();
    const result = await pool.query(`
      SELECT 
        f.featured_id,
        f.news_id,
        f.tier,
        f.starts_at,
        f.ends_at,
        f.manually_removed,
        f.created_at,
        n.title,
        n.slug,
        n.image_url,
        n.published_at,
        c.name as category_name,
        CONCAT(a.first_name, ' ', a.last_name) as author
      FROM featured_news f
      JOIN news n ON f.news_id = n.news_id
      LEFT JOIN categories c ON n.category_id = c.category_id
      LEFT JOIN admins a ON n.author_id = a.admin_id
      WHERE f.manually_removed = false
      ORDER BY f.tier ASC, f.created_at DESC
    `);

    res.json({
      success: true,
      featured: result.rows
    });
  } catch (error) {
    console.error('Get featured error:', error);
    res.status(500).json({ success: false, error: error.message });
  }
});

router.post('/featured', async (req, res) => {
  try {
    const { news_id, tier, starts_at, ends_at } = req.body;

    if (!news_id || !tier) {
      return res.status(400).json({ 
        success: false, 
        error: 'news_id and tier are required' 
      });
    }

    const pool = getPool();
    const result = await pool.query(`
      INSERT INTO featured_news (news_id, tier, starts_at, ends_at)
      VALUES ($1, $2, $3, $4)
      RETURNING *
    `, [news_id, tier, starts_at || new Date(), ends_at]);

    res.json({
      success: true,
      featured: result.rows[0]
    });
  } catch (error) {
    console.error('Add featured error:', error);
    res.status(500).json({ success: false, error: error.message });
  }
});

router.delete('/featured/:featured_id', async (req, res) => {
  try {
    const { featured_id } = req.params;
    const pool = getPool();

    const result = await pool.query(`
      UPDATE featured_news
      SET manually_removed = true
      WHERE featured_id = $1
      RETURNING *
    `, [featured_id]);

    if (result.rowCount === 0) {
      return res.status(404).json({ success: false, error: 'Featured news not found' });
    }

    res.json({
      success: true,
      removed: result.rows[0]
    });
  } catch (error) {
    console.error('Remove featured error:', error);
    res.status(500).json({ success: false, error: error.message });
  }
});

router.get('/breaking', async (req, res) => {
  try {
    const pool = getPool();
    const result = await pool.query(`
      SELECT 
        b.breaking_id,
        b.news_id,
        b.priority,
        b.starts_at,
        b.ends_at,
        b.manually_removed,
        b.created_at,
        n.title,
        n.slug,
        n.image_url,
        n.published_at,
        c.name as category_name,
        CONCAT(a.first_name, ' ', a.last_name) as author
      FROM breaking_news b
      JOIN news n ON b.news_id = n.news_id
      LEFT JOIN categories c ON n.category_id = c.category_id
      LEFT JOIN admins a ON n.author_id = a.admin_id
      WHERE b.manually_removed = false
      ORDER BY b.priority DESC, b.created_at DESC
    `);

    res.json({
      success: true,
      breaking: result.rows
    });
  } catch (error) {
    console.error('Get breaking error:', error);
    res.status(500).json({ success: false, error: error.message });
  }
});

router.post('/breaking', async (req, res) => {
  try {
    const { news_id, priority, starts_at, ends_at } = req.body;

    if (!news_id || !priority) {
      return res.status(400).json({ 
        success: false, 
        error: 'news_id and priority are required' 
      });
    }

    const pool = getPool();
    const result = await pool.query(`
      INSERT INTO breaking_news (news_id, priority, starts_at, ends_at)
      VALUES ($1, $2, $3, $4)
      RETURNING *
    `, [news_id, priority, starts_at || new Date(), ends_at]);

    res.json({
      success: true,
      breaking: result.rows[0]
    });
  } catch (error) {
    console.error('Add breaking error:', error);
    res.status(500).json({ success: false, error: error.message });
  }
});

router.delete('/breaking/:breaking_id', async (req, res) => {
  try {
    const { breaking_id } = req.params;
    const pool = getPool();

    const result = await pool.query(`
      UPDATE breaking_news
      SET manually_removed = true
      WHERE breaking_id = $1
      RETURNING *
    `, [breaking_id]);

    if (result.rowCount === 0) {
      return res.status(404).json({ success: false, error: 'Breaking news not found' });
    }

    res.json({
      success: true,
      removed: result.rows[0]
    });
  } catch (error) {
    console.error('Remove breaking error:', error);
    res.status(500).json({ success: false, error: error.message });
  }
});

router.get('/pinned', async (req, res) => {
  try {
    const pool = getPool();
    const result = await pool.query(`
      SELECT 
        p.pinned_id,
        p.news_id,
        p.tier,
        p.starts_at,
        p.ends_at,
        p.manually_removed,
        p.created_at,
        n.title,
        n.slug,
        n.image_url,
        n.published_at,
        c.name as category_name,
        CONCAT(a.first_name, ' ', a.last_name) as author
      FROM pinned_news p
      JOIN news n ON p.news_id = n.news_id
      LEFT JOIN categories c ON n.category_id = c.category_id
      LEFT JOIN admins a ON n.author_id = a.admin_id
      WHERE p.manually_removed = false
      ORDER BY p.tier ASC, p.created_at DESC
    `);

    res.json({
      success: true,
      pinned: result.rows
    });
  } catch (error) {
    console.error('Get pinned error:', error);
    res.status(500).json({ success: false, error: error.message });
  }
});

router.post('/pinned', async (req, res) => {
  try {
    const { news_id, tier, starts_at, ends_at } = req.body;

    if (!news_id || !tier) {
      return res.status(400).json({ 
        success: false, 
        error: 'news_id and tier are required' 
      });
    }

    const pool = getPool();
    const result = await pool.query(`
      INSERT INTO pinned_news (news_id, tier, starts_at, ends_at)
      VALUES ($1, $2, $3, $4)
      RETURNING *
    `, [news_id, tier, starts_at || new Date(), ends_at]);

    res.json({
      success: true,
      pinned: result.rows[0]
    });
  } catch (error) {
    console.error('Add pinned error:', error);
    res.status(500).json({ success: false, error: error.message });
  }
});

router.delete('/pinned/:pinned_id', async (req, res) => {
  try {
    const { pinned_id } = req.params;
    const pool = getPool();

    const result = await pool.query(`
      UPDATE pinned_news
      SET manually_removed = true
      WHERE pinned_id = $1
      RETURNING *
    `, [pinned_id]);

    if (result.rowCount === 0) {
      return res.status(404).json({ success: false, error: 'Pinned news not found' });
    }

    res.json({
      success: true,
      removed: result.rows[0]
    });
  } catch (error) {
    console.error('Remove pinned error:', error);
    res.status(500).json({ success: false, error: error.message });
  }
});

router.get('/ads', async (req, res) => {
  try {
    const pool = getPool();
    const result = await pool.query(`
      SELECT 
        ad_id,
        title,
        description,
        image_url,
        link_url,
        placement,
        starts_at,
        ends_at,
        active,
        created_at
      FROM advertisements
      WHERE active = true
        AND (ends_at IS NULL OR ends_at > NOW())
      ORDER BY placement ASC, created_at DESC
    `);

    res.json({
      success: true,
      ads: result.rows
    });
  } catch (error) {
    console.error('Get ads error:', error);
    res.status(500).json({ success: false, error: error.message });
  }
});

router.post('/ads', async (req, res) => {
  try {
    const { title, description, image_url, link_url, placement, starts_at, ends_at } = req.body;

    if (!title || !image_url || !link_url || !placement) {
      return res.status(400).json({ 
        success: false, 
        error: 'title, image_url, link_url, and placement are required' 
      });
    }

    const pool = getPool();
    const result = await pool.query(`
      INSERT INTO advertisements 
        (title, description, image_url, link_url, placement, starts_at, ends_at)
      VALUES ($1, $2, $3, $4, $5, $6, $7)
      RETURNING *
    `, [title, description, image_url, link_url, placement, starts_at || new Date(), ends_at]);

    res.json({
      success: true,
      ad: result.rows[0]
    });
  } catch (error) {
    console.error('Create ad error:', error);
    res.status(500).json({ success: false, error: error.message });
  }
});

router.put('/ads/:ad_id', async (req, res) => {
  try {
    const { ad_id } = req.params;
    const { title, description, image_url, link_url, placement, starts_at, ends_at, active } = req.body;

    const pool = getPool();
    const result = await pool.query(`
      UPDATE advertisements
      SET 
        title = COALESCE($1, title),
        description = COALESCE($2, description),
        image_url = COALESCE($3, image_url),
        link_url = COALESCE($4, link_url),
        placement = COALESCE($5, placement),
        starts_at = COALESCE($6, starts_at),
        ends_at = COALESCE($7, ends_at),
        active = COALESCE($8, active)
      WHERE ad_id = $9
      RETURNING *
    `, [title, description, image_url, link_url, placement, starts_at, ends_at, active, ad_id]);

    if (result.rowCount === 0) {
      return res.status(404).json({ success: false, error: 'Ad not found' });
    }

    res.json({
      success: true,
      ad: result.rows[0]
    });
  } catch (error) {
    console.error('Update ad error:', error);
    res.status(500).json({ success: false, error: error.message });
  }
});

router.delete('/ads/:ad_id', async (req, res) => {
  try {
    const { ad_id } = req.params;
    const pool = getPool();

    const result = await pool.query(`
      UPDATE advertisements
      SET active = false
      WHERE ad_id = $1
      RETURNING *
    `, [ad_id]);

    if (result.rowCount === 0) {
      return res.status(404).json({ success: false, error: 'Ad not found' });
    }

    res.json({
      success: true,
      deactivated: result.rows[0]
    });
  } catch (error) {
    console.error('Delete ad error:', error);
    res.status(500).json({ success: false, error: error.message });
  }
});

router.get('/stats', async (req, res) => {
  try {
    const pool = getPool();
    
    const featured = await pool.query(`
      SELECT COUNT(*) as total
      FROM featured_news
      WHERE manually_removed = false
        AND (ends_at IS NULL OR ends_at > NOW())
    `);

    const breaking = await pool.query(`
      SELECT COUNT(*) as total
      FROM breaking_news
      WHERE manually_removed = false
        AND (ends_at IS NULL OR ends_at > NOW())
    `);

    const pinned = await pool.query(`
      SELECT COUNT(*) as total
      FROM pinned_news
      WHERE manually_removed = false
        AND (ends_at IS NULL OR ends_at > NOW())
    `);

    const ads = await pool.query(`
      SELECT COUNT(*) as total
      FROM advertisements
      WHERE active = true
        AND (ends_at IS NULL OR ends_at > NOW())
    `);

    res.json({
      success: true,
      stats: {
        featured: parseInt(featured.rows[0].total) || 0,
        breaking: parseInt(breaking.rows[0].total) || 0,
        pinned: parseInt(pinned.rows[0].total) || 0,
        ads: parseInt(ads.rows[0].total) || 0
      }
    });
  } catch (error) {
    console.error('Get promotion stats error:', error);
    res.status(500).json({ success: false, error: error.message });
  }
});

module.exports = router;