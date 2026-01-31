// routes/client/geo.js
const express = require('express');
const { FRONTEND_URL, CLIENT_URL, ADMIN_URL, API_DOMAIN, ALLOWED_ORIGINS, isOriginAllowed } = require('../../config/frontendconfig');
const router = express.Router();
const GeoService = require('../../services/geoService');

router.get('/current', async (req, res) => {
  res.set({
    'Cache-Control': 'private, no-cache, no-store, must-revalidate',
    'Pragma': 'no-cache',
    'Expires': '0'
  });

  try {
    const location = req.geo || { county: null, town: null, category: 'UNKNOWN' };

    res.json({
      success: true,
      location: {
        county: location.county,
        town: location.town,
        category: location.category
      }
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      error: 'Failed to get current location',
      location: { county: null, town: null, category: 'UNKNOWN' }
    });
  }
});

router.post('/register', async (req, res) => {
  res.set('Cache-Control', 'no-store');

  try {
    const { deviceId, county, town, category } = req.body;

    if (!deviceId) {
      return res.status(400).json({
        success: false,
        error: 'Device ID required'
      });
    }

    const result = await GeoService.registerDevice({
      deviceId,
      county: county || 'Unknown',
      town: town || 'Unknown',
      category: category || 'UNKNOWN'
    });

    res.json(result);
  } catch (error) {
    console.error('Register device error:', error);
    res.status(500).json({
      success: false,
      error: 'Failed to register device'
    });
  }
});

router.get('/stats', async (req, res) => {
  res.set({
    'Cache-Control': 'public, max-age=60, s-maxage=120, stale-while-revalidate=300',
    'CDN-Cache-Control': 'max-age=120',
    'Vary': 'Accept-Encoding'
  });

  try {
    const stats = await GeoService.getGeoStats();
    res.json(stats);
  } catch (error) {
    res.status(500).json({
      success: false,
      error: 'Failed to get geo stats'
    });
  }
});

router.get('/today', async (req, res) => {
  res.set({
    'Cache-Control': 'public, max-age=300, s-maxage=600',
    'CDN-Cache-Control': 'max-age=600',
    'Vary': 'Accept-Encoding'
  });

  try {
    const stats = await GeoService.getTodaysStats();
    res.json(stats);
  } catch (error) {
    res.status(500).json({
      success: false,
      error: 'Failed to get today stats'
    });
  }
});

router.get('/county/:county', async (req, res) => {
  res.set({
    'Cache-Control': 'public, max-age=300, s-maxage=600, stale-while-revalidate=1800',
    'CDN-Cache-Control': 'max-age=600',
    'Vary': 'Accept-Encoding'
  });

  try {
    const { county } = req.params;
    const details = await GeoService.getCountyDetails(county);
    res.json(details);
  } catch (error) {
    res.status(500).json({
      success: false,
      error: 'Failed to get county details'
    });
  }
});

router.get('/trends', async (req, res) => {
  res.set({
    'Cache-Control': 'public, max-age=600, s-maxage=1800, stale-while-revalidate=3600',
    'CDN-Cache-Control': 'max-age=1800',
    'Vary': 'Accept-Encoding'
  });

  try {
    const days = req.query.days ? parseInt(req.query.days) : 7;
    const result = await GeoService.getGeoTrends(days);
    res.json(result);
  } catch (error) {
    res.status(500).json({
      success: false,
      error: 'Failed to get geo trends'
    });
  }
});

router.post('/cleanup', async (req, res) => {
  res.set('Cache-Control', 'no-store');

  try {
    const result = await GeoService.cleanupOldDevices();
    res.json(result);
  } catch (error) {
    res.status(500).json({
      success: false,
      error: 'Failed to cleanup devices'
    });
  }
});

router.post('/archive', async (req, res) => {
  res.set('Cache-Control', 'no-store');

  try {
    const result = await GeoService.archiveDailyStats();
    res.json(result);
  } catch (error) {
    res.status(500).json({
      success: false,
      error: 'Failed to archive stats'
    });
  }
});

router.post('/reset-daily', async (req, res) => {
  res.set('Cache-Control', 'no-store');

  try {
    const result = await GeoService.resetDailyCounts();
    res.json(result);
  } catch (error) {
    res.status(500).json({
      success: false,
      error: 'Failed to reset daily counts'
    });
  }
});

module.exports = router;
