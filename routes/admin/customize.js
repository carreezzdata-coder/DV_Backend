const express = require('express');
const router = express.Router();
const { getPool } = require('../../config/db');
const requireAdminAuth = require('../../middleware/adminAuth');
const { canPublishDirectly } = require('../../middleware/rolePermissions');

const { FRONTEND_URL, CLIENT_URL, ADMIN_URL, API_DOMAIN, ALLOWED_ORIGINS, isOriginAllowed } = require('../../config/frontendconfig');

const logAdminActivity = async (client, adminId, action, targetType, targetId, details, ip) => {
  try {
    await client.query(
      `INSERT INTO admin_activity_log (admin_id, action, target_type, target_id, details, ip_address) VALUES ($1, $2, $3, $4, $5, $6)`,
      [adminId, action, targetType, targetId, details, ip]
    );
  } catch (error) {
    console.error('[Activity Log] Error:', error);
  }
};

router.put('/:id', requireAdminAuth, async (req, res) => {
  const pool = getPool();
  const client = await pool.connect();
  
  try {
    const { id } = req.params;
    const admin_id = req.adminId;

    if (!id || isNaN(Number(id))) {
      return res.status(400).json({
        success: false,
        message: 'Valid news ID is required'
      });
    }

    if (!admin_id) {
      return res.status(401).json({
        success: false,
        message: 'Admin authentication required'
      });
    }

    const userRole = req.userRole;
    if (!canPublishDirectly(userRole)) {
      return res.status(403).json({
        success: false,
        message: 'Only Super Admins, Admins, and Editors can customize promotions'
      });
    }

    const { 
      featured, 
      featured_hours, 
      featured_tier,
      breaking, 
      breaking_hours, 
      breaking_level,
      pinned, 
      pin_type,
      pin_position,
      editor_pick
    } = req.body;

    await client.query('BEGIN');

    const checkQuery = 'SELECT news_id, status FROM news WHERE news_id = $1';
    const checkResult = await client.query(checkQuery, [id]);

    if (checkResult.rows.length === 0) {
      await client.query('ROLLBACK');
      return res.status(404).json({
        success: false,
        message: 'News article not found'
      });
    }

    if (featured !== undefined && featured !== null) {
      await client.query('DELETE FROM featured_news WHERE news_id = $1', [id]);
      
      if (featured === true) {
        if (!featured_tier || !['gold', 'silver', 'bronze'].includes(featured_tier)) {
          await client.query('ROLLBACK');
          return res.status(400).json({
            success: false,
            message: 'Featured tier must be gold, silver, or bronze'
          });
        }
        
        const hours = featured_hours || 72;
        
        await client.query(`
          INSERT INTO featured_news (news_id, tier, starts_at, ends_at, activated_by, manually_removed)
          VALUES ($1, $2, NOW(), NOW() + INTERVAL '1 hour' * $3, $4, false)
        `, [id, featured_tier, hours, admin_id]);
      }
    }

    if (breaking !== undefined && breaking !== null) {
      await client.query('DELETE FROM breaking_news WHERE news_id = $1', [id]);
      
      if (breaking === true) {
        if (!breaking_level || !['high', 'medium', 'low'].includes(breaking_level)) {
          await client.query('ROLLBACK');
          return res.status(400).json({
            success: false,
            message: 'Breaking level must be high, medium, or low'
          });
        }
        
        const hours = breaking_hours || 12;
        
        await client.query(`
          INSERT INTO breaking_news (news_id, priority, starts_at, ends_at, activated_by, manually_removed)
          VALUES ($1, $2, NOW(), NOW() + INTERVAL '1 hour' * $3, $4, false)
        `, [id, breaking_level, hours, admin_id]);
      }
    }

    if (pinned !== undefined && pinned !== null) {
      await client.query('DELETE FROM pinned_news WHERE news_id = $1', [id]);
      
      if (pinned === true) {
        if (!pin_type || !['gold', 'silver', 'bronze'].includes(pin_type)) {
          await client.query('ROLLBACK');
          return res.status(400).json({
            success: false,
            message: 'Pin type must be gold, silver, or bronze'
          });
        }
        
        const hours = pin_type === 'gold' ? 72 : 48;
        const position = pin_position || 1;
        
        await client.query(`
          INSERT INTO pinned_news (news_id, tier, position, starts_at, ends_at, activated_by, manually_removed)
          VALUES ($1, $2, $3, NOW(), NOW() + INTERVAL '1 hour' * $4, $5, false)
        `, [id, pin_type, position, hours, admin_id]);
      }
    }

    if (editor_pick !== undefined && editor_pick !== null) {
      await client.query('DELETE FROM editor_pick WHERE news_id = $1', [id]);
      
      if (editor_pick === true) {
        await client.query(`
          INSERT INTO editor_pick (news_id, picked_by, picked_at, manually_removed)
          VALUES ($1, $2, NOW(), false)
        `, [id, admin_id]);
      }
    }

    const ip = req.headers['x-forwarded-for'] || req.headers['x-real-ip'] || req.ip || 'unknown';
    const details = JSON.stringify({ 
      featured: featured ? featured_tier : false, 
      breaking: breaking ? breaking_level : false, 
      pinned: pinned ? pin_type : false, 
      editor_pick 
    });
    await logAdminActivity(client, admin_id, 'update_promotions', 'news', id, details, ip);

    await client.query('COMMIT');

    const promotionStatus = await client.query(`
      SELECT 
        (SELECT tier FROM featured_news WHERE news_id = $1 AND manually_removed = false AND (ends_at IS NULL OR ends_at > NOW()) LIMIT 1) as featured_tier,
        (SELECT ends_at FROM featured_news WHERE news_id = $1 AND manually_removed = false AND (ends_at IS NULL OR ends_at > NOW()) LIMIT 1) as featured_until,
        (SELECT priority FROM breaking_news WHERE news_id = $1 AND manually_removed = false AND (ends_at IS NULL OR ends_at > NOW()) LIMIT 1) as breaking_level,
        (SELECT ends_at FROM breaking_news WHERE news_id = $1 AND manually_removed = false AND (ends_at IS NULL OR ends_at > NOW()) LIMIT 1) as breaking_until,
        (SELECT tier FROM pinned_news WHERE news_id = $1 AND manually_removed = false AND (ends_at IS NULL OR ends_at > NOW()) LIMIT 1) as pin_type,
        (SELECT position FROM pinned_news WHERE news_id = $1 AND manually_removed = false AND (ends_at IS NULL OR ends_at > NOW()) LIMIT 1) as pin_position,
        (SELECT ends_at FROM pinned_news WHERE news_id = $1 AND manually_removed = false AND (ends_at IS NULL OR ends_at > NOW()) LIMIT 1) as pin_until,
        (SELECT COUNT(*) > 0 FROM editor_pick WHERE news_id = $1 AND manually_removed = false) as editor_pick
    `, [id]);

    const status = promotionStatus.rows[0];

    return res.status(200).json({
      success: true,
      message: 'Promotions updated successfully',
      promotions: {
        featured: status.featured_tier !== null,
        featured_tier: status.featured_tier,
        featured_until: status.featured_until,
        breaking: status.breaking_level !== null,
        breaking_level: status.breaking_level,
        breaking_until: status.breaking_until,
        pinned: status.pin_type !== null,
        pin_type: status.pin_type,
        pin_position: status.pin_position || 1,
        pin_until: status.pin_until,
        editor_pick: status.editor_pick || false
      }
    });

  } catch (error) {
    await client.query('ROLLBACK');
    console.error('[Customize] Error:', error);
    
    if (error.code === '23514') {
      return res.status(400).json({
        success: false,
        message: 'Invalid tier value for promotion type'
      });
    }

    if (error.code === '23503') {
      return res.status(400).json({
        success: false,
        message: 'Invalid admin ID or foreign key constraint violation'
      });
    }

    return res.status(500).json({
      success: false,
      message: 'Internal server error',
      error: process.env.NODE_ENV === 'development' ? error.message : undefined
    });
  } finally {
    client.release();
  }
});

router.get('/:id', requireAdminAuth, async (req, res) => {
  const pool = getPool();
  
  try {
    const { id } = req.params;

    if (!id || isNaN(Number(id))) {
      return res.status(400).json({
        success: false,
        message: 'Valid news ID is required'
      });
    }

    const checkNews = await pool.query('SELECT news_id FROM news WHERE news_id = $1', [id]);
    
    if (checkNews.rows.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'News article not found'
      });
    }

    const result = await pool.query(`
      SELECT 
        (SELECT tier FROM featured_news WHERE news_id = $1 AND manually_removed = false AND (ends_at IS NULL OR ends_at > NOW()) LIMIT 1) as featured_tier,
        (SELECT ends_at FROM featured_news WHERE news_id = $1 AND manually_removed = false AND (ends_at IS NULL OR ends_at > NOW()) LIMIT 1) as featured_until,
        (SELECT priority FROM breaking_news WHERE news_id = $1 AND manually_removed = false AND (ends_at IS NULL OR ends_at > NOW()) LIMIT 1) as breaking_level,
        (SELECT ends_at FROM breaking_news WHERE news_id = $1 AND manually_removed = false AND (ends_at IS NULL OR ends_at > NOW()) LIMIT 1) as breaking_until,
        (SELECT tier FROM pinned_news WHERE news_id = $1 AND manually_removed = false AND (ends_at IS NULL OR ends_at > NOW()) LIMIT 1) as pin_type,
        (SELECT position FROM pinned_news WHERE news_id = $1 AND manually_removed = false AND (ends_at IS NULL OR ends_at > NOW()) LIMIT 1) as pin_position,
        (SELECT ends_at FROM pinned_news WHERE news_id = $1 AND manually_removed = false AND (ends_at IS NULL OR ends_at > NOW()) LIMIT 1) as pin_until,
        (SELECT COUNT(*) > 0 FROM editor_pick WHERE news_id = $1 AND manually_removed = false) as editor_pick
    `, [id]);

    const status = result.rows[0];

    return res.status(200).json({
      success: true,
      promotions: {
        featured: status.featured_tier !== null,
        featured_tier: status.featured_tier,
        featured_until: status.featured_until,
        breaking: status.breaking_level !== null,
        breaking_level: status.breaking_level,
        breaking_until: status.breaking_until,
        pinned: status.pin_type !== null,
        pin_type: status.pin_type,
        pin_position: status.pin_position || 1,
        pin_until: status.pin_until,
        editor_pick: status.editor_pick || false
      }
    });

  } catch (error) {
    console.error('[Customize] Get error:', error);
    return res.status(500).json({
      success: false,
      message: 'Internal server error',
      error: process.env.NODE_ENV === 'development' ? error.message : undefined
    });
  }
});

module.exports = router;