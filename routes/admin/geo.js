// backend/routes/admin/geo.js
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

router.get('/stats', async (req, res) => {
  try {
    const pool = getPool();

    const categoryStats = await pool.query(`
      SELECT
        category,
        COUNT(*) as location_count,
        SUM(total_registered) as total_devices,
        SUM(active_today) as active_today,
        SUM(active_now) as active_now,
        COUNT(DISTINCT county) FILTER (WHERE county IS NOT NULL) as unique_counties,
        COUNT(DISTINCT town) FILTER (WHERE town IS NOT NULL) as unique_towns
      FROM active_location_counts
      GROUP BY category
      ORDER BY total_devices DESC
    `);

    const topLocations = await pool.query(`
      SELECT 
        county,
        town,
        category,
        total_registered,
        active_today,
        active_now,
        last_activity
      FROM active_location_counts
      WHERE county IS NOT NULL
      ORDER BY total_registered DESC
      LIMIT 50
    `);

    const activeNow = await pool.query(`
      SELECT 
        county,
        town,
        category,
        active_now,
        active_today,
        last_activity
      FROM active_location_counts
      WHERE active_now > 0
      ORDER BY active_now DESC
      LIMIT 100
    `);

    res.json({
      success: true,
      byCategory: categoryStats.rows,
      topLocations: topLocations.rows,
      activeNow: activeNow.rows,
      totalActive: activeNow.rows.reduce((sum, loc) => sum + (loc.active_now || 0), 0),
      timestamp: new Date().toISOString()
    });
  } catch (error) {
    console.error('Admin geo stats error:', error);
    res.status(500).json({ success: false, error: error.message });
  }
});

router.get('/locations', async (req, res) => {
  try {
    const pool = getPool();
    const { category, county, limit = 100, offset = 0 } = req.query;

    let query = `
      SELECT
        location_id,
        county,
        town,
        category,
        total_registered,
        active_today,
        active_now,
        last_activity,
        CASE
          WHEN active_now > 0 THEN 'online'
          WHEN active_today > 0 THEN 'today'
          ELSE 'inactive'
        END as status
      FROM active_location_counts
      WHERE 1=1
    `;

    const params = [];
    let paramCount = 1;

    if (category && category !== 'all') {
      query += ` AND category = $${paramCount}`;
      params.push(category);
      paramCount++;
    }

    if (county && county !== 'all') {
      query += ` AND county = $${paramCount}`;
      params.push(county);
      paramCount++;
    }

    query += ` ORDER BY last_activity DESC LIMIT $${paramCount} OFFSET $${paramCount + 1}`;
    params.push(parseInt(limit), parseInt(offset));

    const result = await pool.query(query, params);

    res.json({
      success: true,
      locations: result.rows,
      total: result.rows.length,
      limit: parseInt(limit),
      offset: parseInt(offset)
    });
  } catch (error) {
    console.error('Get locations error:', error);
    res.status(500).json({ success: false, error: error.message });
  }
});

router.get('/active-count', async (req, res) => {
  try {
    const pool = getPool();

    const result = await pool.query(`
      SELECT 
        SUM(active_now) as total_active_now,
        SUM(active_today) as total_active_today
      FROM active_location_counts
    `);

    res.json({
      success: true,
      activeNow: parseInt(result.rows[0].total_active_now) || 0,
      activeToday: parseInt(result.rows[0].total_active_today) || 0
    });
  } catch (error) {
    console.error('Get active count error:', error);
    res.status(500).json({ success: false, error: error.message });
  }
});

router.get('/county/:county', async (req, res) => {
  try {
    const pool = getPool();
    const { county } = req.params;

    const summary = await pool.query(`
      SELECT
        SUM(total_registered) as total_devices,
        SUM(active_today) as active_today,
        SUM(active_now) as active_now,
        COUNT(DISTINCT town) as unique_towns,
        MAX(last_activity) as last_activity
      FROM active_location_counts
      WHERE county = $1
    `, [county]);

    const towns = await pool.query(`
      SELECT
        town,
        category,
        total_registered,
        active_today,
        active_now,
        last_activity
      FROM active_location_counts
      WHERE county = $1 AND town IS NOT NULL
      ORDER BY total_registered DESC
    `, [county]);

    res.json({
      success: true,
      county: county,
      summary: summary.rows[0] || {},
      towns: towns.rows
    });
  } catch (error) {
    console.error('Get county details error:', error);
    res.status(500).json({ success: false, error: error.message });
  }
});

router.get('/trends', async (req, res) => {
  try {
    const pool = getPool();
    const days = parseInt(req.query.days) || 7;

    const trends = await pool.query(`
      SELECT
        DATE(last_activity) as date,
        category,
        SUM(active_today) as active_count,
        COUNT(DISTINCT county) as active_counties
      FROM active_location_counts
      WHERE last_activity > NOW() - INTERVAL '${days} days'
      GROUP BY DATE(last_activity), category
      ORDER BY date DESC, category
    `);

    res.json({
      success: true,
      trends: trends.rows,
      days: days
    });
  } catch (error) {
    console.error('Get geo trends error:', error);
    res.status(500).json({ success: false, error: error.message });
  }
});

router.post('/cleanup', async (req, res) => {
  try {
    const pool = getPool();

    const result = await pool.query(`
      UPDATE active_location_counts
      SET active_now = 0
      WHERE last_activity < NOW() - INTERVAL '15 minutes'
      RETURNING location_id
    `);

    res.json({
      success: true,
      message: `Reset ${result.rowCount} inactive locations`,
      updatedCount: result.rowCount
    });
  } catch (error) {
    console.error('Cleanup error:', error);
    res.status(500).json({ success: false, error: error.message });
  }
});

router.get('/advertising-targets', async (req, res) => {
  try {
    const pool = getPool();
    const { minActive = 5 } = req.query;

    const targets = await pool.query(`
      SELECT
        county,
        town,
        category,
        active_now,
        active_today,
        total_registered,
        last_activity
      FROM active_location_counts
      WHERE (active_now >= $1 OR active_today >= ($1 * 2))
        AND county IS NOT NULL
      ORDER BY 
        (active_now * 3 + active_today) DESC,
        total_registered DESC
      LIMIT 100
    `, [parseInt(minActive)]);

    res.json({
      success: true,
      targets: targets.rows,
      count: targets.rows.length,
      minActiveThreshold: parseInt(minActive)
    });
  } catch (error) {
    console.error('Get advertising targets error:', error);
    res.status(500).json({ success: false, error: error.message });
  }
});

router.get('/survey-reach', async (req, res) => {
  try {
    const pool = getPool();

    const reach = await pool.query(`
      SELECT
        category,
        COUNT(DISTINCT county) as counties_reached,
        COUNT(DISTINCT town) as towns_reached,
        SUM(active_today) as daily_reach,
        SUM(total_registered) as total_reach,
        AVG(active_today) as avg_daily_per_location
      FROM active_location_counts
      WHERE county IS NOT NULL
      GROUP BY category
      ORDER BY daily_reach DESC
    `);

    const topCounties = await pool.query(`
      SELECT
        county,
        SUM(active_today) as daily_reach,
        SUM(total_registered) as total_reach
      FROM active_location_counts
      WHERE county IS NOT NULL
      GROUP BY county
      ORDER BY daily_reach DESC
      LIMIT 20
    `);

    res.json({
      success: true,
      byCategory: reach.rows,
      topCounties: topCounties.rows,
      totalDailyReach: reach.rows.reduce((sum, cat) => sum + (parseInt(cat.daily_reach) || 0), 0)
    });
  } catch (error) {
    console.error('Get survey reach error:', error);
    res.status(500).json({ success: false, error: error.message });
  }
});

module.exports = router;