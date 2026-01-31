const { getPool } = require('../config/db');
const cloudflareService = require('./cloudflareService');
const cacheOptimization = require('./cacheOptimization');

class GeoCdnService {

  async syncGeoDataToCloudflare() {
    if (!cloudflareService.isEnabled()) {
      return {
        success: false,
        message: 'Cloudflare not configured'
      };
    }

    try {
      const pool = getPool();

      const geoData = await pool.query(`
        SELECT
          category,
          county,
          town,
          total_registered as session_count,
          active_today as total_visits,
          last_activity
        FROM active_location_counts
        WHERE total_registered > 0
        ORDER BY total_registered DESC
        LIMIT 1000
      `);

      const geoJson = {
        timestamp: new Date().toISOString(),
        totalRecords: geoData.rows.length,
        data: geoData.rows
      };

      const buffer = Buffer.from(JSON.stringify(geoJson, null, 2));

      const file = {
        buffer,
        originalname: 'geo-data.json',
        mimetype: 'application/json',
        size: buffer.length
      };

      const result = await cloudflareService.uploadFile(file, 'geo-data');

      cacheOptimization.set('geo-cdn-url', result.url, 3600000);

      return {
        success: true,
        url: result.url,
        records: geoData.rows.length,
        timestamp: new Date().toISOString()
      };

    } catch (error) {
      console.error('Error syncing geo data to Cloudflare:', error);
      return {
        success: false,
        error: error.message
      };
    }
  }

  async getGeoDataFromCdn() {
    if (!cloudflareService.isEnabled()) {
      return this.getGeoDataFromDatabase();
    }

    try {
      const cachedUrl = cacheOptimization.get('geo-cdn-url');
      const cdnUrl = cachedUrl || cloudflareService.getPublicUrl('geo-data/geo-data.json');

      if (!cdnUrl) {
        return this.getGeoDataFromDatabase();
      }

      const response = await fetch(cdnUrl);

      if (!response.ok) {
        return this.getGeoDataFromDatabase();
      }

      const data = await response.json();

      return {
        success: true,
        source: 'cdn',
        cdnUrl,
        ...data
      };

    } catch (error) {
      console.error('Error fetching from CDN, falling back to database:', error);
      return this.getGeoDataFromDatabase();
    }
  }

  async getGeoDataFromDatabase() {
    try {
      const pool = getPool();

      const cacheKey = 'geo-database-snapshot';
      const cached = cacheOptimization.get(cacheKey);
      if (cached) {
        return {
          success: true,
          source: 'cache',
          ...cached
        };
      }

      const geoData = await pool.query(`
        SELECT
          category,
          county,
          town,
          total_registered as session_count,
          active_today as total_visits,
          last_activity
        FROM active_location_counts
        WHERE total_registered > 0
        ORDER BY total_registered DESC
        LIMIT 1000
      `);

      const result = {
        timestamp: new Date().toISOString(),
        totalRecords: geoData.rows.length,
        data: geoData.rows
      };

      cacheOptimization.set(cacheKey, result, 300000);

      return {
        success: true,
        source: 'database',
        ...result
      };

    } catch (error) {
      console.error('Error fetching geo data from database:', error);
      return {
        success: false,
        error: error.message,
        data: []
      };
    }
  }

  async getGeoStatsByCity() {
    try {
      const pool = getPool();

      const cacheKey = 'geo-city-stats';
      const cached = cacheOptimization.get(cacheKey);
      if (cached) {
        return cached;
      }

      const cityStats = await pool.query(`
        SELECT
          town as city,
          county,
          category,
          total_registered as unique_visitors,
          active_today as total_visits,
          last_activity as last_seen
        FROM active_location_counts
        WHERE town IS NOT NULL
        ORDER BY total_registered DESC
        LIMIT 50
      `);

      const result = {
        success: true,
        cities: cityStats.rows,
        totalCities: cityStats.rows.length
      };

      cacheOptimization.set(cacheKey, result, 300000);

      return result;

    } catch (error) {
      console.error('Error fetching city stats:', error);
      return {
        success: false,
        error: error.message
      };
    }
  }

  async getNearestCdnNode(county, town) {
    const cdnNodes = {
      'NAIROBI': 'nairobi-cdn.r2.dev',
      'MOMBASA': 'mombasa-cdn.r2.dev',
      'KISUMU': 'kisumu-cdn.r2.dev',
      'NAKURU': 'nakuru-cdn.r2.dev'
    };

    const normalizedCounty = county?.toUpperCase();
    const cdnNode = cdnNodes[normalizedCounty] || cloudflareService.publicUrl;

    return {
      county,
      town,
      cdnNode: cdnNode || 'global-cdn.r2.dev',
      isLocalNode: !!cdnNodes[normalizedCounty]
    };
  }
}

module.exports = new GeoCdnService();