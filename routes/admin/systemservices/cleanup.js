const express = require('express');
const router = express.Router();
const { getPool } = require('../../../config/db'); 

const { FRONTEND_URL, CLIENT_URL, ADMIN_URL, API_DOMAIN, ALLOWED_ORIGINS, isOriginAllowed } = require('../../../config/frontendconfig');

router.get('/', async (req, res) => {
  try {
    const action = req.query.action || 'stats';
    const pool = getPool();
    
    if (action === 'stats') {
      const statsQuery = await pool.query(`
        SELECT 
          (SELECT COUNT(*) FROM session_store) as public_sessions,
          (SELECT COUNT(*) FROM session_store WHERE expire < NOW()) as expired_public,
          (SELECT COUNT(*) FROM admin_session_store) as admin_sessions,
          (SELECT COUNT(*) FROM admin_session_store WHERE expire < NOW()) as expired_admin,
          (SELECT COUNT(*) FROM session_geo) as session_geo,
          (SELECT COUNT(DISTINCT session_id) FROM session_geo WHERE last_seen > NOW() - INTERVAL '7 days') as active_devices,
          (SELECT COUNT(DISTINCT session_id) FROM session_geo WHERE last_seen < NOW() - INTERVAL '30 days') as old_devices
      `);
      
      const row = statsQuery.rows[0];
      
      return res.json({
        success: true,
        stats: {
          publicSessions: parseInt(row.public_sessions) || 0,
          expiredPublic: parseInt(row.expired_public) || 0,
          adminSessions: parseInt(row.admin_sessions) || 0,
          expiredAdmin: parseInt(row.expired_admin) || 0,
          sessionGeo: parseInt(row.session_geo) || 0,
          activeDevices: parseInt(row.active_devices) || 0,
          oldDevices: parseInt(row.old_devices) || 0
        }
      });
    }
    
    if (action === 'status') {
      const lastCleanupQuery = await pool.query(
        'SELECT * FROM cleanup_history ORDER BY cleaned_at DESC LIMIT 1'
      );
      
      const lastCleanup = lastCleanupQuery.rows[0];
      
      return res.json({
        success: true,
        status: {
          isRunning: true,
          lastRun: lastCleanup ? lastCleanup.cleaned_at : null,
          nextRun: null,
          interval: 'manual'
        }
      });
    }
    
    if (action === 'history') {
      const limit = parseInt(req.query.limit) || 20;
      const historyQuery = await pool.query(
        'SELECT * FROM cleanup_history ORDER BY cleaned_at DESC LIMIT $1',
        [limit]
      );
      
      return res.json({
        success: true,
        history: historyQuery.rows
      });
    }
    
    return res.status(400).json({
      success: false,
      message: `Invalid action: ${action}`
    });
    
  } catch (error) {
    console.error('Cleanup GET error:', error);
    return res.status(500).json({
      success: false,
      error: 'Failed to process cleanup request',
      message: error.message
    });
  }
});

router.post('/', async (req, res) => {
  const pool = getPool();
  const client = await pool.connect();
  
  try {
    const action = req.query.action || 'run-now';
    const force = req.query.force === 'true';
    
    if (action === 'run-now') {
      const startTime = Date.now();
      const cleanupType = req.query.type || 'public';
      
      let deletedPublic = 0;
      let deletedAdmin = 0;

      if (cleanupType === 'public') {
        const deletePublic = await client.query(`
          DELETE FROM session_store 
          WHERE expire < NOW()
        `);
        deletedPublic = deletePublic.rowCount;
      } else if (cleanupType === 'admin') {
        const deleteAdmin = await client.query(`
          DELETE FROM admin_session_store 
          WHERE expire < NOW()
        `);
        deletedAdmin = deleteAdmin.rowCount;
      }

      const duration = Date.now() - startTime;
      const totalDeleted = deletedPublic + deletedAdmin;

      await client.query(`
        INSERT INTO cleanup_history 
        (type, public_sessions, admin_sessions, user_sessions, total_sessions, duration, status, triggered_by)
        VALUES ($1, $2, $3, $4, $5, $6, $7, $8)
      `, [
        cleanupType,
        deletedPublic,
        deletedAdmin,
        0,
        totalDeleted,
        duration,
        'completed',
        'manual'
      ]);

      console.log(`${cleanupType} cleanup completed: ${totalDeleted} sessions deleted`);

      return res.json({
        success: true,
        message: `${cleanupType} cleanup completed`,
        results: {
          publicSessions: deletedPublic,
          adminSessions: deletedAdmin,
          total: totalDeleted,
          duration,
          type: cleanupType
        }
      });
    }
    
    return res.status(400).json({
      success: false,
      message: `Invalid action: ${action}`
    });
    
  } catch (error) {
    console.error('Cleanup POST error:', error);
    return res.status(500).json({
      success: false,
      error: 'Cleanup action failed',
      message: error.message
    });
  } finally {
    client.release();
  }
});

module.exports = router;