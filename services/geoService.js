const { getPool } = require('../config/db');
const cacheOptimization = require('./cacheOptimization');

class GeoService {
  static async getGeoStats() {
    try {
      const cacheKey = 'geo-stats-all';
      const cached = cacheOptimization.get(cacheKey);
      if (cached) {
        return cached;
      }

      const pool = getPool();

      const categoryStats = await pool.query(`
        SELECT
          category,
          COUNT(DISTINCT county) FILTER (WHERE county IS NOT NULL AND county != 'Unknown') as total_counties,
          COUNT(DISTINCT town) FILTER (WHERE town IS NOT NULL AND town != 'Unknown') as total_towns,
          SUM(total_registered) as total_devices,
          SUM(active_today) as active_today,
          SUM(active_now) as active_now
        FROM active_location_counts
        GROUP BY category
        ORDER BY total_devices DESC
      `);

      const topLocations = await pool.query(`
        SELECT county, category,
          SUM(total_registered) as total_devices,
          SUM(active_today) as active_today,
          SUM(active_now) as active_now
        FROM active_location_counts
        WHERE county IS NOT NULL AND county != 'Unknown'
        GROUP BY county, category
        ORDER BY total_devices DESC
        LIMIT 20
      `);

      const activeNow = await pool.query(`
        SELECT county, town, category, active_now, active_today, last_activity
        FROM active_location_counts
        WHERE active_now > 0
        ORDER BY active_now DESC
        LIMIT 50
      `);

      const result = {
        success: true,
        byCategory: categoryStats.rows,
        topLocations: topLocations.rows,
        activeNow: activeNow.rows
      };

      cacheOptimization.set(cacheKey, result, 180000);

      return result;
    } catch (error) {
      console.error('Error getting geo stats:', error);
      return { success: false, error: error.message };
    }
  }

  static async getCountyDetails(county) {
    try {
      const cacheKey = `geo-county-${county}`;
      const cached = cacheOptimization.get(cacheKey);
      if (cached) {
        return cached;
      }

      const pool = getPool();

      const summary = await pool.query(`
        SELECT
          SUM(total_registered) as total_devices,
          SUM(active_today) as active_today,
          SUM(active_now) as active_now,
          COUNT(DISTINCT town) as unique_towns
        FROM active_location_counts
        WHERE county = $1
      `, [county]);

      const towns = await pool.query(`
        SELECT
          town,
          total_registered,
          active_today,
          active_now,
          last_activity
        FROM active_location_counts
        WHERE county = $1 AND town IS NOT NULL
        ORDER BY total_registered DESC
      `, [county]);

      const result = {
        success: true,
        county,
        summary: summary.rows[0],
        towns: towns.rows
      };

      cacheOptimization.set(cacheKey, result, 300000);

      return result;
    } catch (error) {
      console.error('Error getting county details:', error);
      return { success: false, error: error.message };
    }
  }

  static async getAdTargetingData(county, town) {
    try {
      const pool = getPool();

      const result = await pool.query(`
        SELECT
          county,
          town,
          category,
          active_now,
          active_today,
          total_registered
        FROM active_location_counts
        WHERE county = $1 AND (town = $2 OR $2 IS NULL)
        ORDER BY active_now DESC
      `, [county, town]);

      return {
        success: true,
        targeting: result.rows
      };
    } catch (error) {
      console.error('Error getting ad targeting data:', error);
      return { success: false, error: error.message };
    }
  }
}

module.exports = GeoService;