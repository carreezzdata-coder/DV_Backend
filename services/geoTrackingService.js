const { getPool } = require('../config/db');

class GeoTrackingService {

  async trackSession(sessionData) {
    const pool = getPool();
    const { sessionId, location, visitCount, firstSeen, lastSeen } = sessionData;

    try {
      const result = await pool.query(`
        INSERT INTO session_geo (
          session_id, category, county, town,
          visit_count, first_seen, last_seen, raw_data
        ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8)
        ON CONFLICT (session_id)
        DO UPDATE SET
          county = COALESCE(EXCLUDED.county, session_geo.county),
          town = COALESCE(EXCLUDED.town, session_geo.town),
          category = COALESCE(EXCLUDED.category, session_geo.category),
          visit_count = session_geo.visit_count + 1,
          last_seen = EXCLUDED.last_seen,
          updated_at = NOW()
        RETURNING *
      `, [
        sessionId,
        location.category || 'UNKNOWN',
        location.county,
        location.town,
        visitCount || 1,
        firstSeen || new Date().toISOString(),
        lastSeen || new Date().toISOString(),
        JSON.stringify(location)
      ]);

      await this.updateLocationCounts(location.county, location.town, location.category);

      return { success: true, data: result.rows[0] };
    } catch (error) {
      console.error('GeoTrackingService.trackSession error:', error);
      return { success: false, error: error.message };
    }
  }

  async updateLocationCounts(county, town, category) {
    if (!county && !town) return;

    const pool = getPool();

    try {
      await pool.query(`
        INSERT INTO active_location_counts (
          category, county, town, total_registered, active_today, active_now, last_activity
        ) VALUES ($1, $2, $3, 1, 1, 1, NOW())
        ON CONFLICT (category, county, town)
        DO UPDATE SET
          active_today = active_location_counts.active_today + 1,
          active_now = active_location_counts.active_now + 1,
          last_activity = NOW()
      `, [category || 'UNKNOWN', county, town]);
    } catch (error) {
      console.error('Error updating location counts:', error);
    }
  }

  async getCurrentLocation(ip, userAgent) {
    const category = this.categorizeDevice(userAgent);
    const geoData = await this.lookupIPLocation(ip);

    return {
      county: geoData.county || null,
      town: geoData.town || null,
      category: category,
    };
  }

  categorizeDevice(userAgent) {
    if (!userAgent) return 'UNKNOWN';

    const ua = userAgent.toLowerCase();

    if (ua.includes('mobile') || ua.includes('android') || ua.includes('iphone')) {
      return 'MOBILE';
    }
    if (ua.includes('tablet') || ua.includes('ipad')) {
      return 'TABLET';
    }
    if (ua.includes('bot') || ua.includes('crawler') || ua.includes('spider')) {
      return 'BOT';
    }

    return 'DESKTOP';
  }

  async lookupIPLocation(ip) {
    const pool = getPool();

    try {
      const result = await pool.query(`
        SELECT county, town, category
        FROM session_geo
        WHERE last_seen > NOW() - INTERVAL '24 hours'
        ORDER BY last_seen DESC
        LIMIT 1
      `);

      if (result.rows.length > 0) {
        return result.rows[0];
      }

      return { county: null, town: null, category: 'UNKNOWN' };
    } catch (error) {
      console.error('IP lookup error:', error);
      return { county: null, town: null, category: 'UNKNOWN' };
    }
  }

  async getActiveStats() {
    const pool = getPool();

    try {
      const result = await pool.query(`
        SELECT
          category,
          county,
          COUNT(DISTINCT session_id) as active_sessions,
          SUM(visit_count) as total_visits
        FROM session_geo
        WHERE last_seen > NOW() - INTERVAL '15 minutes'
        GROUP BY category, county
        ORDER BY active_sessions DESC
      `);

      return { success: true, stats: result.rows };
    } catch (error) {
      console.error('Get active stats error:', error);
      return { success: false, error: error.message };
    }
  }

  async cleanupOldSessions(hoursOld = 48) {
    const pool = getPool();

    try {
      const result = await pool.query(`
        DELETE FROM session_geo
        WHERE last_seen < NOW() - INTERVAL '${parseInt(hoursOld)} hours'
        RETURNING session_id
      `);

      console.log(`Cleaned up ${result.rowCount} old sessions`);

      return { success: true, deleted: result.rowCount };
    } catch (error) {
      console.error('Cleanup old sessions error:', error);
      return { success: false, error: error.message };
    }
  }
}

module.exports = new GeoTrackingService();