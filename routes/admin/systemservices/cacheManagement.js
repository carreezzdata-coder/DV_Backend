
// backend/routes/admin/cacheManagement.js

const express = require('express');
const router = express.Router();
const { getPool } = require('../../../config/db'); 

const { FRONTEND_URL, CLIENT_URL, ADMIN_URL, API_DOMAIN, ALLOWED_ORIGINS, isOriginAllowed } = require('../../../config/frontendconfig');

router.get('/stats', async (req, res) => {
  try {
    const pool = getPool();
    
    const pgCacheStats = await pool.query(`
      SELECT 
        sum(heap_blks_read) as heap_read,
        sum(heap_blks_hit) as heap_hit,
        sum(idx_blks_read) as idx_read,
        sum(idx_blks_hit) as idx_hit
      FROM pg_statio_user_tables;
    `);

    const stats = pgCacheStats.rows[0];
    const totalRead = parseInt(stats.heap_read || 0) + parseInt(stats.idx_read || 0);
    const totalHit = parseInt(stats.heap_hit || 0) + parseInt(stats.idx_hit || 0);
    const hitRate = totalRead + totalHit > 0 
      ? ((totalHit / (totalRead + totalHit)) * 100).toFixed(2) 
      : 0;

    const tableSizes = await pool.query(`
      SELECT 
        schemaname,
        tablename,
        pg_size_pretty(pg_total_relation_size(schemaname||'.'||tablename)) AS size,
        pg_total_relation_size(schemaname||'.'||tablename) AS size_bytes
      FROM pg_tables
      WHERE schemaname = 'public'
      ORDER BY pg_total_relation_size(schemaname||'.'||tablename) DESC
      LIMIT 10;
    `);

    const totalSize = tableSizes.rows.reduce((sum, row) => sum + parseInt(row.size_bytes || 0), 0);

    const cacheStats = {
      postgresql: {
        connected: true,
        hitRate: `${hitRate}%`,
        heapHits: parseInt(stats.heap_hit || 0),
        heapReads: parseInt(stats.heap_read || 0),
        indexHits: parseInt(stats.idx_hit || 0),
        indexReads: parseInt(stats.idx_read || 0),
        totalHits: totalHit,
        totalReads: totalRead,
        totalSize: `${(totalSize / 1024 / 1024).toFixed(2)} MB`,
        largestTables: tableSizes.rows.slice(0, 5)
      },
      cloudflare: {
        enabled: !!(process.env.CLOUDFLARE_ACCOUNT_ID && process.env.R2_ACCESS_KEY_ID),
        r2Configured: !!(process.env.R2_BUCKET_NAME),
        cdnUrl: process.env.R2_PUBLIC_URL || 'Not configured',
        accountId: process.env.CLOUDFLARE_ACCOUNT_ID ? 'Configured' : 'Not configured'
      },
      cdn: {
        enabled: !!(process.env.R2_PUBLIC_URL),
        provider: 'Cloudflare R2',
        publicUrl: process.env.R2_PUBLIC_URL || null,
        assetsDelivery: process.env.R2_PUBLIC_URL ? 'Global CDN' : 'Local'
      }
    };

    return res.json({
      success: true,
      stats: cacheStats,
      timestamp: new Date().toISOString()
    });

  } catch (error) {
    console.error('Error fetching cache stats:', error);
    return res.status(500).json({
      success: false,
      error: 'Failed to fetch cache statistics',
      message: error.message
    });
  }
});

router.post('/purge', async (req, res) => {
  try {
    const pool = getPool();
    const { type, key } = req.body;
    
    let message = 'Cache purge initiated';
    
    if (type === 'all') {
      await pool.query('DISCARD ALL');
      message = 'All PostgreSQL cache cleared successfully';
    } else if (type === 'sessions') {
      await pool.query(`
        DELETE FROM session_store WHERE expire < NOW();
        DELETE FROM admin_session_store WHERE expire < NOW();
      `);
      message = 'Expired sessions purged successfully';
    } else if (type === 'geo') {
      await pool.query(`
        DELETE FROM session_geo WHERE last_seen < NOW() - INTERVAL '30 days';
      `);
      message = 'Old geo data purged successfully';
    } else if (type === 'news') {
      message = 'News cache purge would happen here (implement based on your caching strategy)';
    }

    return res.json({
      success: true,
      message,
      timestamp: new Date().toISOString()
    });
  } catch (error) {
    console.error('Error purging cache:', error);
    return res.status(500).json({
      success: false,
      error: 'Cache purge failed',
      message: error.message
    });
  }
});

router.post('/optimize', async (req, res) => {
  try {
    const pool = getPool();
    
    await pool.query('VACUUM ANALYZE');
    
    return res.json({
      success: true,
      message: 'PostgreSQL cache optimized successfully',
      timestamp: new Date().toISOString()
    });
  } catch (error) {
    console.error('Error optimizing cache:', error);
    return res.status(500).json({
      success: false,
      error: 'Cache optimization failed',
      message: error.message
    });
  }
});

module.exports = router;