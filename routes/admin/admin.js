const express = require('express');
const router = express.Router();
const { getPool } = require('../../config/db');
const requireAdminAuth = require('../../middleware/adminAuth');
const { getUserRole, canManageUsers } = require('../../middleware/rolePermissions');

const { FRONTEND_URL, CLIENT_URL, ADMIN_URL, API_DOMAIN, ALLOWED_ORIGINS, isOriginAllowed } = require('../../config/frontendconfig');

const isProduction = process.env.NODE_ENV === 'production';

router.get('/dashboard/stats', requireAdminAuth, async (req, res) => {
  const pool = getPool();
  
  try {
    const adminId = req.adminId;
    const userRole = await getUserRole(adminId);

    let statsQuery;
    let queryParams;

    if (['super_admin', 'admin'].includes(userRole)) {
      statsQuery = `
        SELECT 
          COUNT(DISTINCT n.news_id) as total_posts,
          COUNT(DISTINCT n.news_id) FILTER (WHERE n.status = 'published') as published_posts,
          COUNT(DISTINCT n.news_id) FILTER (WHERE n.status = 'draft') as draft_posts,
          COUNT(DISTINCT n.news_id) FILTER (WHERE n.status = 'archived') as archived_posts,
          COUNT(DISTINCT na.news_id) FILTER (WHERE na.workflow_status IN ('pending_review', 'pending_approval')) as pending_approvals,
          COALESCE(SUM(n.views), 0) as total_views,
          COALESCE(SUM(n.likes_count), 0) as total_likes,
          COALESCE(SUM(n.comments_count), 0) as total_comments,
          COALESCE(SUM(n.share_count), 0) as total_shares
        FROM news n
        LEFT JOIN news_approval na ON n.news_id = na.news_id
      `;
      queryParams = [];
    } else if (userRole === 'editor') {
      statsQuery = `
        SELECT 
          COUNT(DISTINCT n.news_id) as total_posts,
          COUNT(DISTINCT n.news_id) FILTER (WHERE n.status = 'published') as published_posts,
          COUNT(DISTINCT n.news_id) FILTER (WHERE n.status = 'draft') as draft_posts,
          COUNT(DISTINCT n.news_id) FILTER (WHERE n.status = 'archived') as archived_posts,
          COUNT(DISTINCT na.news_id) FILTER (WHERE na.workflow_status IN ('pending_review', 'pending_approval')) as pending_approvals,
          COALESCE(SUM(CASE WHEN n.author_id = $1 THEN n.views ELSE 0 END), 0) as total_views,
          COALESCE(SUM(CASE WHEN n.author_id = $1 THEN n.likes_count ELSE 0 END), 0) as total_likes,
          COALESCE(SUM(CASE WHEN n.author_id = $1 THEN n.comments_count ELSE 0 END), 0) as total_comments,
          COALESCE(SUM(CASE WHEN n.author_id = $1 THEN n.share_count ELSE 0 END), 0) as total_shares
        FROM news n
        LEFT JOIN news_approval na ON n.news_id = na.news_id
      `;
      queryParams = [adminId];
    } else {
      statsQuery = `
        SELECT 
          COUNT(DISTINCT n.news_id) as total_posts,
          COUNT(DISTINCT n.news_id) FILTER (WHERE n.status = 'published') as published_posts,
          COUNT(DISTINCT n.news_id) FILTER (WHERE n.status = 'draft') as draft_posts,
          COUNT(DISTINCT n.news_id) FILTER (WHERE n.status = 'archived') as archived_posts,
          COUNT(DISTINCT na.news_id) FILTER (WHERE na.workflow_status IN ('pending_review', 'pending_approval')) as pending_approvals,
          COALESCE(SUM(n.views), 0) as total_views,
          COALESCE(SUM(n.likes_count), 0) as total_likes,
          COALESCE(SUM(n.comments_count), 0) as total_comments,
          COALESCE(SUM(n.share_count), 0) as total_shares
        FROM news n
        LEFT JOIN news_approval na ON n.news_id = na.news_id
        WHERE n.author_id = $1
      `;
      queryParams = [adminId];
    }

    const statsResult = await pool.query(statsQuery, queryParams);

    let totalUsers = 0;
    if (canManageUsers(userRole)) {
      const usersResult = await pool.query(
        `SELECT COUNT(*) as total FROM admins WHERE status = 'active'`
      );
      totalUsers = parseInt(usersResult.rows[0].total) || 0;
    }

    const stats = {
      total_posts: parseInt(statsResult.rows[0].total_posts) || 0,
      published_posts: parseInt(statsResult.rows[0].published_posts) || 0,
      draft_posts: parseInt(statsResult.rows[0].draft_posts) || 0,
      archived_posts: parseInt(statsResult.rows[0].archived_posts) || 0,
      pending_approvals: parseInt(statsResult.rows[0].pending_approvals) || 0,
      total_views: parseInt(statsResult.rows[0].total_views) || 0,
      total_likes: parseInt(statsResult.rows[0].total_likes) || 0,
      total_comments: parseInt(statsResult.rows[0].total_comments) || 0,
      total_shares: parseInt(statsResult.rows[0].total_shares) || 0,
      total_users: totalUsers,
      user_role: userRole,
      is_global_stats: ['super_admin', 'admin'].includes(userRole)
    };

    return res.status(200).json({
      success: true,
      stats,
      message: 'Dashboard stats fetched successfully'
    });

  } catch (error) {
    console.error('[Admin Dashboard] Stats error:', error);
    return res.status(500).json({
      success: false,
      message: 'Internal server error',
      error: !isProduction ? error.message : undefined
    });
  }
});

router.get('/dashboard/recent-activity', requireAdminAuth, async (req, res) => {
  const pool = getPool();
  
  try {
    const adminId = req.adminId;
    const userRole = await getUserRole(adminId);
    const { limit = 10 } = req.query;

    let activityQuery;
    let queryParams;

    if (['super_admin', 'admin'].includes(userRole)) {
      activityQuery = `
        SELECT 
          n.news_id,
          n.title,
          n.status,
          n.created_at,
          n.updated_at,
          n.published_at,
          na.workflow_status,
          CONCAT(a.first_name, ' ', a.last_name) as author_name,
          a.role as author_role,
          c.name as category_name
        FROM news n
        LEFT JOIN news_approval na ON n.news_id = na.news_id
        LEFT JOIN admins a ON n.author_id = a.admin_id
        LEFT JOIN categories c ON n.category_id = c.category_id
        ORDER BY n.updated_at DESC
        LIMIT $1
      `;
      queryParams = [parseInt(limit)];
    } else {
      activityQuery = `
        SELECT 
          n.news_id,
          n.title,
          n.status,
          n.created_at,
          n.updated_at,
          n.published_at,
          na.workflow_status,
          CONCAT(a.first_name, ' ', a.last_name) as author_name,
          a.role as author_role,
          c.name as category_name
        FROM news n
        LEFT JOIN news_approval na ON n.news_id = na.news_id
        LEFT JOIN admins a ON n.author_id = a.admin_id
        LEFT JOIN categories c ON n.category_id = c.category_id
        WHERE n.author_id = $1
        ORDER BY n.updated_at DESC
        LIMIT $2
      `;
      queryParams = [adminId, parseInt(limit)];
    }

    const result = await pool.query(activityQuery, queryParams);

    return res.status(200).json({
      success: true,
      activity: result.rows,
      message: 'Recent activity fetched successfully'
    });

  } catch (error) {
    console.error('[Admin Dashboard] Activity error:', error);
    return res.status(500).json({
      success: false,
      message: 'Internal server error',
      error: !isProduction ? error.message : undefined
    });
  }
});

router.get('/dashboard/performance', requireAdminAuth, async (req, res) => {
  const pool = getPool();
  
  try {
    const adminId = req.adminId;
    const userRole = await getUserRole(adminId);
    const { range = '7d' } = req.query;

    let days = 7;
    if (range === '30d') days = 30;
    else if (range === '90d') days = 90;

    let performanceQuery;
    let queryParams;

    if (['super_admin', 'admin'].includes(userRole)) {
      performanceQuery = `
        WITH daily_stats AS (
          SELECT 
            DATE(n.created_at) as date,
            COUNT(DISTINCT n.news_id) as posts_created,
            COUNT(DISTINCT n.news_id) FILTER (WHERE n.status = 'published') as posts_published,
            COALESCE(SUM(n.views), 0) as daily_views,
            COALESCE(SUM(n.likes_count), 0) as daily_likes,
            COALESCE(SUM(n.comments_count), 0) as daily_comments
          FROM news n
          WHERE n.created_at >= CURRENT_DATE - INTERVAL '${days} days'
          GROUP BY DATE(n.created_at)
          ORDER BY date DESC
        )
        SELECT * FROM daily_stats
      `;
      queryParams = [];
    } else {
      performanceQuery = `
        WITH daily_stats AS (
          SELECT 
            DATE(n.created_at) as date,
            COUNT(DISTINCT n.news_id) as posts_created,
            COUNT(DISTINCT n.news_id) FILTER (WHERE n.status = 'published') as posts_published,
            COALESCE(SUM(n.views), 0) as daily_views,
            COALESCE(SUM(n.likes_count), 0) as daily_likes,
            COALESCE(SUM(n.comments_count), 0) as daily_comments
          FROM news n
          WHERE n.author_id = $1 AND n.created_at >= CURRENT_DATE - INTERVAL '${days} days'
          GROUP BY DATE(n.created_at)
          ORDER BY date DESC
        )
        SELECT * FROM daily_stats
      `;
      queryParams = [adminId];
    }

    const result = await pool.query(performanceQuery, queryParams);

    return res.status(200).json({
      success: true,
      performance: result.rows,
      range: range,
      message: 'Performance data fetched successfully'
    });

  } catch (error) {
    console.error('[Admin Dashboard] Performance error:', error);
    return res.status(500).json({
      success: false,
      message: 'Internal server error',
      error: !isProduction ? error.message : undefined
    });
  }
});

router.get('/permissions', requireAdminAuth, async (req, res) => {
  try {
    const adminId = req.adminId;
    const userRole = await getUserRole(adminId);

    const permissions = {
      role: userRole,
      can_publish_directly: ['super_admin', 'admin', 'editor'].includes(userRole),
      can_approve: ['super_admin', 'admin', 'editor'].includes(userRole),
      can_manage_users: ['super_admin', 'admin'].includes(userRole),
      can_hard_delete: ['super_admin', 'admin'].includes(userRole),
      can_archive: ['super_admin', 'admin', 'editor', 'moderator'].includes(userRole),
      can_set_featured: ['super_admin', 'admin', 'editor'].includes(userRole),
      can_set_breaking: ['super_admin', 'admin'].includes(userRole),
      can_set_pinned: ['super_admin', 'admin'].includes(userRole),
      can_edit_any: ['super_admin', 'admin', 'editor'].includes(userRole),
      can_view_analytics: true,
      can_view_system_settings: ['super_admin'].includes(userRole),
      can_view_all_users: ['super_admin', 'admin'].includes(userRole),
      can_create_super_admin: userRole === 'super_admin',
      can_promote_users: userRole === 'super_admin',
      can_access_chat: true
    };

    return res.status(200).json({
      success: true,
      permissions,
      message: 'Permissions fetched successfully'
    });

  } catch (error) {
    console.error('[Admin Permissions] Error:', error);
    return res.status(500).json({
      success: false,
      message: 'Internal server error',
      error: !isProduction ? error.message : undefined
    });
  }
});

router.get('/profile', requireAdminAuth, async (req, res) => {
  const pool = getPool();
  
  try {
    const adminId = req.adminId;

    const result = await pool.query(`
      SELECT 
        admin_id,
        first_name,
        last_name,
        email,
        phone,
        role,
        status,
        created_at,
        last_login,
        (SELECT COUNT(*) FROM news WHERE author_id = $1) as total_posts,
        (SELECT COUNT(*) FROM news WHERE author_id = $1 AND status = 'published') as published_posts,
        (SELECT COALESCE(SUM(views), 0) FROM news WHERE author_id = $1) as total_views
      FROM admins
      WHERE admin_id = $1
    `, [adminId]);

    if (result.rows.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'Admin profile not found'
      });
    }

    return res.status(200).json({
      success: true,
      profile: result.rows[0],
      message: 'Profile fetched successfully'
    });

  } catch (error) {
    console.error('[Admin Profile] Error:', error);
    return res.status(500).json({
      success: false,
      message: 'Internal server error',
      error: !isProduction ? error.message : undefined
    });
  }
});

router.put('/profile', requireAdminAuth, async (req, res) => {
  const pool = getPool();
  const client = await pool.connect();
  
  try {
    await client.query('BEGIN');

    const adminId = req.adminId;
    const { first_name, last_name, email, phone } = req.body;

    if (!first_name || !last_name || !email) {
      await client.query('ROLLBACK');
      return res.status(400).json({
        success: false,
        message: 'First name, last name, and email are required'
      });
    }

    const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
    if (!emailRegex.test(email.trim())) {
      await client.query('ROLLBACK');
      return res.status(400).json({
        success: false,
        message: 'Invalid email format'
      });
    }

    const emailCheck = await client.query(
      'SELECT admin_id FROM admins WHERE email = $1 AND admin_id != $2',
      [email.trim().toLowerCase(), adminId]
    );

    if (emailCheck.rows.length > 0) {
      await client.query('ROLLBACK');
      return res.status(409).json({
        success: false,
        message: 'Email already in use by another user'
      });
    }

    const result = await client.query(`
      UPDATE admins
      SET 
        first_name = $1,
        last_name = $2,
        email = $3,
        phone = $4,
        updated_at = CURRENT_TIMESTAMP
      WHERE admin_id = $5
      RETURNING admin_id, first_name, last_name, email, phone, role, updated_at
    `, [
      first_name.trim(),
      last_name.trim(),
      email.trim().toLowerCase(),
      phone?.trim() || null,
      adminId
    ]);

    const ip = req.headers['x-forwarded-for'] || req.headers['x-real-ip'] || req.ip || 'unknown';
    await client.query(
      `INSERT INTO admin_activity_log (admin_id, action, target_type, target_id, details, ip_address)
       VALUES ($1, $2, $3, $4, $5, $6)`,
      [adminId, 'update_profile', 'admin', adminId, 'Updated own profile', ip]
    );

    await client.query('COMMIT');

    return res.status(200).json({
      success: true,
      profile: result.rows[0],
      message: 'Profile updated successfully'
    });

  } catch (error) {
    await client.query('ROLLBACK');
    console.error('[Admin Profile Update] Error:', error);
    return res.status(500).json({
      success: false,
      message: 'Internal server error',
      error: !isProduction ? error.message : undefined
    });
  } finally {
    client.release();
  }
});

router.get('/system/health', requireAdminAuth, async (req, res) => {
  try {
    const adminId = req.adminId;
    const userRole = await getUserRole(adminId);

    if (userRole !== 'super_admin') {
      return res.status(403).json({
        success: false,
        message: 'Only Super Admins can access system health information'
      });
    }

    const pool = getPool();

    const dbHealth = await pool.query('SELECT NOW()');
    const tablesCount = await pool.query(`
      SELECT COUNT(*) as count 
      FROM information_schema.tables 
      WHERE table_schema = 'public'
    `);

    const health = {
      status: 'healthy',
      timestamp: new Date().toISOString(),
      database: {
        connected: true,
        tables: parseInt(tablesCount.rows[0].count) || 0
      },
      environment: process.env.NODE_ENV || 'development'
    };

    return res.status(200).json({
      success: true,
      health,
      message: 'System health check completed'
    });

  } catch (error) {
    console.error('[System Health] Error:', error);
    return res.status(500).json({
      success: false,
      message: 'System health check failed',
      error: !isProduction ? error.message : undefined
    });
  }
});

module.exports = router;