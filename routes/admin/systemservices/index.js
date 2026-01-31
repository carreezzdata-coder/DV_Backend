// backend/routes/admin/systemservices/index.js

const express = require('express');
const router = express.Router();

// Import all service routes
const cleanupRoutes = require('./cleanup');
const databaseOptimizationRoutes = require('./databaseOptimization');
const cacheManagementRoutes = require('./cacheManagement');
const systemMonitoringRoutes = require('./systemMonitoring');

const { FRONTEND_URL, CLIENT_URL, ADMIN_URL, API_DOMAIN, ALLOWED_ORIGINS, isOriginAllowed } = require('../../../config/frontendconfig');

// Mount all service routes
router.use('/cleanup', cleanupRoutes);
router.use('/database', databaseOptimizationRoutes);
router.use('/cache', cacheManagementRoutes);
router.use('/monitoring', systemMonitoringRoutes);

// Health check endpoint
router.get('/health', async (req, res) => {
  try {
    return res.json({
      success: true,
      message: 'System Services API is operational',
      services: {
        cleanup: 'available',
        database: 'available',
        cache: 'available',
        monitoring: 'available'
      },
      timestamp: new Date().toISOString()
    });
  } catch (error) {
    console.error('System services health check error:', error);
    return res.status(500).json({
      success: false,
      error: 'Health check failed',
      message: error.message
    });
  }
});

module.exports = router;