// backend/services/geoCdnSyncCron.js
const geoCdnService = require('./geoCdnService');

class GeoCdnSyncCron {
  constructor() {
    this.intervalId = null;
    this.isRunning = false;
    this.syncIntervalMinutes = 5;
  }

  async start() {
    if (this.isRunning) {
      console.log('GeoCdnSyncCron already running');
      return;
    }

    this.isRunning = true;
    const intervalMs = this.syncIntervalMinutes * 60 * 1000;

    console.log(`Starting GeoCdnSyncCron (syncs every ${this.syncIntervalMinutes} minutes)`);

    await this.runSync();

    this.intervalId = setInterval(() => this.runSync(), intervalMs);
  }

  stop() {
    if (this.intervalId) {
      clearInterval(this.intervalId);
      this.intervalId = null;
    }
    this.isRunning = false;
    console.log('GeoCdnSyncCron stopped');
  }

  async runSync() {
    const startTime = Date.now();
    console.log('[GeoCdnSync] Starting sync to Cloudflare R2...');

    try {
      const result = await geoCdnService.syncGeoDataToCloudflare();

      if (result.success) {
        const duration = Date.now() - startTime;
        console.log(`[GeoCdnSync] ✅ Synced ${result.records} records in ${duration}ms`);
        console.log(`[GeoCdnSync] CDN URL: ${result.url}`);
      } else {
        console.warn(`[GeoCdnSync] ⚠️ Sync failed: ${result.message || result.error}`);
      }
    } catch (error) {
      console.error('[GeoCdnSync] ❌ Sync error:', error.message);
    }
  }

  async syncNow() {
    console.log('[GeoCdnSync] Manual sync triggered');
    return await this.runSync();
  }
}

module.exports = new GeoCdnSyncCron();