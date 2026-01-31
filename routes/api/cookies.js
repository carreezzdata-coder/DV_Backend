// backend/routes/api/client/cookies.js
const express = require('express');
const { FRONTEND_URL, CLIENT_URL, ADMIN_URL, API_DOMAIN, ALLOWED_ORIGINS, isOriginAllowed } = require('../../config/frontendconfig');
const router = express.Router();

let dbModule = null;

try {
  dbModule = require('../../config/db');
} catch (error) {
  console.error('Database module error:', error.message);
}

router.post('/track', async (req, res) => {
  res.set('Cache-Control', 'no-store');

  try {
    const { consent, preferences } = req.body;

    if (!dbModule) {
      return res.json({
        success: true,
        message: 'Client-side only mode'
      });
    }

    const { getPool } = dbModule;
    const pool = getPool();

    const county = req.geo?.county || 'Unknown';
    const town = req.geo?.town || 'Unknown';
    const category = req.geo?.category || 'UNKNOWN';

    const statDate = new Date().toISOString().split('T')[0];

    await pool.query(`
      INSERT INTO cookie_stats_daily (
        stat_date, county, town, category,
        total_consents,
        accepted_count,
        rejected_count,
        functional_enabled,
        analytics_enabled,
        marketing_enabled,
        personalization_enabled
      ) VALUES ($1, $2, $3, $4, 1, $5, $6, $7, $8, $9, $10)
      ON CONFLICT (stat_date, county, town, category)
      DO UPDATE SET
        total_consents = cookie_stats_daily.total_consents + 1,
        accepted_count = cookie_stats_daily.accepted_count + $5,
        rejected_count = cookie_stats_daily.rejected_count + $6,
        functional_enabled = cookie_stats_daily.functional_enabled + $7,
        analytics_enabled = cookie_stats_daily.analytics_enabled + $8,
        marketing_enabled = cookie_stats_daily.marketing_enabled + $9,
        personalization_enabled = cookie_stats_daily.personalization_enabled + $10,
        updated_at = NOW()
    `, [
      statDate,
      county,
      town,
      category,
      consent ? 1 : 0,
      consent ? 0 : 1,
      preferences?.functional ? 1 : 0,
      preferences?.analytics ? 1 : 0,
      preferences?.marketing ? 1 : 0,
      preferences?.personalization ? 1 : 0
    ]);

    res.json({
      success: true,
      message: 'Stats updated'
    });

  } catch (error) {
    console.error('Cookie tracking error:', error);
    res.status(500).json({
      success: false,
      error: 'Failed to track'
    });
  }
});

router.get('/stats', async (req, res) => {
  res.set({
    'Cache-Control': 'public, max-age=300, s-maxage=600',
    'CDN-Cache-Control': 'max-age=600'
  });

  try {
    if (!dbModule) {
      return res.json({
        success: true,
        stats: {
          totalConsents: 0,
          acceptedCount: 0,
          rejectedCount: 0,
          acceptanceRate: 0
        }
      });
    }

    const { getPool } = dbModule;
    const pool = getPool();

    const days = parseInt(req.query.days) || 30;

    const result = await pool.query(`
      SELECT
        SUM(total_consents) as total_consents,
        SUM(accepted_count) as accepted_count,
        SUM(rejected_count) as rejected_count,
        SUM(functional_enabled) as functional_enabled,
        SUM(analytics_enabled) as analytics_enabled,
        SUM(marketing_enabled) as marketing_enabled,
        SUM(personalization_enabled) as personalization_enabled,
        COUNT(DISTINCT county) as unique_counties,
        COUNT(DISTINCT town) as unique_towns
      FROM cookie_stats_daily
      WHERE stat_date >= CURRENT_DATE - INTERVAL '${days} days'
    `);

    const stats = result.rows[0];
    const totalConsents = parseInt(stats.total_consents) || 0;

    res.json({
      success: true,
      stats: {
        totalConsents,
        acceptedCount: parseInt(stats.accepted_count) || 0,
        rejectedCount: parseInt(stats.rejected_count) || 0,
        acceptanceRate: totalConsents > 0
          ? ((parseInt(stats.accepted_count) / totalConsents) * 100).toFixed(2)
          : 0,
        preferences: {
          functional: parseInt(stats.functional_enabled) || 0,
          analytics: parseInt(stats.analytics_enabled) || 0,
          marketing: parseInt(stats.marketing_enabled) || 0,
          personalization: parseInt(stats.personalization_enabled) || 0
        },
        uniqueCounties: parseInt(stats.unique_counties) || 0,
        uniqueTowns: parseInt(stats.unique_towns) || 0,
        periodDays: days
      }
    });

  } catch (error) {
    console.error('Stats fetch error:', error);
    res.status(500).json({
      success: false,
      error: 'Failed to fetch stats'
    });
  }
});

router.get('/stats/by-location', async (req, res) => {
  res.set({
    'Cache-Control': 'public, max-age=600, s-maxage=1800',
    'CDN-Cache-Control': 'max-age=1800'
  });

  try {
    if (!dbModule) {
      return res.json({
        success: true,
        locations: []
      });
    }

    const { getPool } = dbModule;
    const pool = getPool();

    const days = parseInt(req.query.days) || 7;

    const result = await pool.query(`
      SELECT
        county,
        town,
        category,
        SUM(total_consents) as total_consents,
        SUM(accepted_count) as accepted_count,
        CASE
          WHEN SUM(total_consents) > 0
          THEN ROUND((SUM(accepted_count)::DECIMAL / SUM(total_consents)::DECIMAL) * 100, 2)
          ELSE 0
        END as acceptance_rate
      FROM cookie_stats_daily
      WHERE stat_date >= CURRENT_DATE - INTERVAL '${days} days'
      GROUP BY county, town, category
      ORDER BY total_consents DESC
      LIMIT 50
    `);

    res.json({
      success: true,
      locations: result.rows.map(row => ({
        county: row.county,
        town: row.town,
        category: row.category,
        totalConsents: parseInt(row.total_consents),
        acceptedCount: parseInt(row.accepted_count),
        acceptanceRate: parseFloat(row.acceptance_rate)
      }))
    });

  } catch (error) {
    console.error('Location stats error:', error);
    res.status(500).json({
      success: false,
      error: 'Failed to fetch location stats'
    });
  }
});

router.post('/archive', async (req, res) => {
  res.set('Cache-Control', 'no-store');

  try {
    if (!dbModule) {
      return res.json({
        success: true,
        message: 'No database to archive',
        archived: 0
      });
    }

    const { getPool } = dbModule;
    const pool = getPool();

    const result = await pool.query('SELECT archive_cookie_stats_monthly()');
    const archived = result.rows[0].archive_cookie_stats_monthly;

    res.json({
      success: true,
      message: 'Archive completed',
      archived: archived
    });

  } catch (error) {
    console.error('Archive error:', error);
    res.status(500).json({
      success: false,
      error: 'Failed to archive'
    });
  }
});

module.exports = router;
