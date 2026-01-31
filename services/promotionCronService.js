const { getPool } = require('../config/db');

class PromotionCronService {
  constructor() {
    this.intervals = [];
  }

  startAutoExpiry() {
    const intervalMs = 10 * 60 * 1000;
    
    const runExpiry = async () => {
      const pool = getPool();
      
      try {
        let totalExpired = 0;

        const featured = await pool.query(`
          UPDATE featured_news
          SET manually_removed = true
          WHERE ends_at IS NOT NULL
            AND ends_at <= NOW()
            AND manually_removed = false
          RETURNING featured_id, news_id, tier;
        `);
        totalExpired += featured.rowCount;

        const breaking = await pool.query(`
          UPDATE breaking_news
          SET manually_removed = true
          WHERE ends_at IS NOT NULL
            AND ends_at <= NOW()
            AND manually_removed = false
          RETURNING breaking_id, news_id, priority;
        `);
        totalExpired += breaking.rowCount;

        const pinned = await pool.query(`
          UPDATE pinned_news
          SET manually_removed = true
          WHERE ends_at IS NOT NULL
            AND ends_at <= NOW()
            AND manually_removed = false
          RETURNING pinned_id, news_id, tier;
        `);
        totalExpired += pinned.rowCount;

        if (totalExpired > 0) {
          console.log(`Auto-expired ${totalExpired} promotions`);
        }

      } catch (error) {
        console.error('Auto-expiry error:', error);
      }
    };

    const interval = setInterval(runExpiry, intervalMs);
    this.intervals.push({ name: 'auto-expiry', interval });
    console.log('Auto-expiry job started (runs every 10 minutes)');
    
    runExpiry();
  }

  startDailyCleanup() {
    const intervalMs = 24 * 60 * 60 * 1000;
    
    const runCleanup = async () => {
      const pool = getPool();
      
      try {
        let totalCleaned = 0;

        const featured = await pool.query(`
          DELETE FROM featured_news
          WHERE ends_at < NOW() - INTERVAL '90 days'
            AND manually_removed = true
          RETURNING featured_id;
        `);
        totalCleaned += featured.rowCount;

        const breaking = await pool.query(`
          DELETE FROM breaking_news
          WHERE ends_at < NOW() - INTERVAL '90 days'
            AND manually_removed = true
          RETURNING breaking_id;
        `);
        totalCleaned += breaking.rowCount;

        const pinned = await pool.query(`
          DELETE FROM pinned_news
          WHERE ends_at < NOW() - INTERVAL '90 days'
            AND manually_removed = true
          RETURNING pinned_id;
        `);
        totalCleaned += pinned.rowCount;

        if (totalCleaned > 0) {
          console.log(`Cleaned up ${totalCleaned} old promotion records`);
        }

      } catch (error) {
        console.error('Cleanup error:', error);
      }
    };

    const interval = setInterval(runCleanup, intervalMs);
    this.intervals.push({ name: 'daily-cleanup', interval });
    console.log('Daily cleanup job started (runs every 24 hours)');
    
    runCleanup();
  }

  startAll() {
    this.startAutoExpiry();
    this.startDailyCleanup();
    console.log('All promotion jobs started successfully');
  }

  stopAll() {
    this.intervals.forEach(({ name, interval }) => {
      clearInterval(interval);
      console.log(`Stopped ${name} job`);
    });
    this.intervals = [];
  }
}

module.exports = new PromotionCronService();