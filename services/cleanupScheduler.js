// backend/services/cleanupScheduler.js
const { getPool } = require('../config/db');

class CleanupScheduler {
  constructor() {
    this.intervalId = null;
    this.isRunning = false;
    this.intervalHours = 24;
  }

  async start() {
    if (this.isRunning) return;

    this.isRunning = true;
    const intervalMs = this.intervalHours * 60 * 60 * 1000;

    await this.runCleanup();

    this.intervalId = setInterval(() => this.runCleanup(), intervalMs);
  }

  stop() {
    if (this.intervalId) {
      clearInterval(this.intervalId);
      this.intervalId = null;
    }
    this.isRunning = false;
  }

  async runCleanup() {
    console.log('Starting database cleanup...');
    const startTime = Date.now();
    
    try {
      const pool = getPool();

      await pool.query('DELETE FROM public_session_store WHERE expire < NOW()');
      await pool.query('DELETE FROM admin_session_store WHERE expire < NOW()');
      await pool.query(`DELETE FROM admin_chat_messages WHERE created_at < NOW() - INTERVAL '7 days'`);
      await pool.query(`DELETE FROM email_queue WHERE created_at < NOW() - INTERVAL '7 days' AND status IN ('sent', 'failed')`);

      await pool.query(`
        UPDATE active_location_counts 
        SET active_now = 0 
        WHERE last_activity < NOW() - INTERVAL '15 minutes'
      `);

      await pool.query(`
        UPDATE active_location_counts 
        SET active_today = 0 
        WHERE last_updated < CURRENT_DATE
      `);

      await pool.query('VACUUM ANALYZE public_session_store');
      await pool.query('VACUUM ANALYZE admin_session_store');
      await pool.query('VACUUM ANALYZE active_location_counts');

      const duration = Date.now() - startTime;
      console.log(`Database cleanup completed in ${duration}ms`);

    } catch (error) {
      console.error('Cleanup error:', error.message);
    }
  }
}

module.exports = new CleanupScheduler();