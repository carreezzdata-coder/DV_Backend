const express = require('express');
const router = express.Router();
const { getPool } = require('../../config/db');
const requireAdminAuth = require('../../middleware/adminAuth');
const { canManageUsers } = require('../../middleware/rolePermissions');

const { FRONTEND_URL, CLIENT_URL, ADMIN_URL, API_DOMAIN, ALLOWED_ORIGINS, isOriginAllowed } = require('../../config/frontendconfig');

const isProduction = process.env.NODE_ENV === 'production';

router.get('/dashboard/stats', requireAdminAuth, async (req, res) => {
  const pool = getPool();
  
  try {
    const adminId = req.adminId;
    const userRole = req.userRole;

    if (!userRole) {
      return res.status(401).json({
        success: false,
        message: 'Invalid user role'
      });
    }

    const normalizedRole = userRole.toLowerCase().trim();

    let statsQuery;
    let queryParams;

    if (['super_admin', 'admin'].includes(normalizedRole)) {
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
    } else if (normalizedRole === 'editor') {
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

    console.log('[Dashboard Stats] Executing query for role:', normalizedRole);
    const statsResult = await pool.query(statsQuery, queryParams);

    if (!statsResult.rows || statsResult.rows.length === 0) {
      console.warn('[Dashboard Stats] No data returned from query');
      return res.status(200).json({
        success: true,
        stats: {
          total_posts: 0,
          published_posts: 0,
          draft_posts: 0,
          archived_posts: 0,
          pending_approvals: 0,
          total_views: 0,
          total_likes: 0,
          total_comments: 0,
          total_shares: 0,
          total_users: 0,
          user_role: normalizedRole,
          is_global_stats: ['super_admin', 'admin'].includes(normalizedRole)
        }
      });
    }

    let totalUsers = 0;
    if (canManageUsers(normalizedRole)) {
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
      user_role: normalizedRole,
      is_global_stats: ['super_admin', 'admin'].includes(normalizedRole)
    };

    console.log('[Dashboard Stats] Returning stats:', stats);

    return res.status(200).json({
      success: true,
      stats,
      message: 'Dashboard stats fetched successfully'
    });

  } catch (error) {
    console.error('[Admin Dashboard] Stats error:', error);
    console.error('[Admin Dashboard] Error stack:', error.stack);
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
    const userRole = req.userRole;
    const { limit = 10 } = req.query;

    if (!userRole) {
      return res.status(401).json({
        success: false,
        message: 'Invalid user role'
      });
    }

    const normalizedRole = userRole.toLowerCase().trim();

    let activityQuery;
    let queryParams;

    if (['super_admin', 'admin'].includes(normalizedRole)) {
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
          a.role::text as author_role,
          c.name as category_name
        FROM news n
        LEFT JOIN news_approval na ON n.news_id = na.news_id
        LEFT JOIN admins a ON n.author_id = a.admin_id
        LEFT JOIN categories c ON n.primary_category_id = c.category_id
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
          a.role::text as author_role,
          c.name as category_name
        FROM news n
        LEFT JOIN news_approval na ON n.news_id = na.news_id
        LEFT JOIN admins a ON n.author_id = a.admin_id
        LEFT JOIN categories c ON n.primary_category_id = c.category_id
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
    console.error('[Admin Dashboard] Error stack:', error.stack);
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
    const userRole = req.userRole;
    const { range = '7d' } = req.query;

    if (!userRole) {
      return res.status(401).json({
        success: false,
        message: 'Invalid user role'
      });
    }

    const normalizedRole = userRole.toLowerCase().trim();

    const rangeDays = {
      '7d': 7,
      '30d': 30,
      '90d': 90,
      '1y': 365
    }[range] || 7;

    let performanceQuery;
    let queryParams;

    if (['super_admin', 'admin'].includes(normalizedRole)) {
      performanceQuery = `
        SELECT 
          DATE(created_at) as date,
          COUNT(*) as posts_created,
          SUM(views) as total_views,
          SUM(likes_count) as total_likes
        FROM news
        WHERE created_at >= CURRENT_DATE - INTERVAL '${rangeDays} days'
        GROUP BY DATE(created_at)
        ORDER BY date DESC
      `;
      queryParams = [];
    } else {
      performanceQuery = `
        SELECT 
          DATE(created_at) as date,
          COUNT(*) as posts_created,
          SUM(views) as total_views,
          SUM(likes_count) as total_likes
        FROM news
        WHERE author_id = $1 AND created_at >= CURRENT_DATE - INTERVAL '${rangeDays} days'
        GROUP BY DATE(created_at)
        ORDER BY date DESC
      `;
      queryParams = [adminId];
    }

    const result = await pool.query(performanceQuery, queryParams);

    return res.status(200).json({
      success: true,
      performance: result.rows,
      message: 'Performance data fetched successfully'
    });

  } catch (error) {
    console.error('[Admin Dashboard] Performance error:', error);
    console.error('[Admin Dashboard] Error stack:', error.stack);
    return res.status(500).json({
      success: false,
      message: 'Internal server error',
      error: !isProduction ? error.message : undefined
    });
  }
});

router.get('/permissions', requireAdminAuth, async (req, res) => {
  try {
    const userRole = req.userRole;

    if (!userRole) {
      return res.status(401).json({
        success: false,
        message: 'Invalid user role'
      });
    }

    const normalizedRole = userRole.toLowerCase().trim();

    const getAssignableRoles = (role) => {
      const ROLE_HIERARCHY = {
        super_admin: 4,
        admin: 3,
        editor: 2,
        moderator: 1
      };

      const userLevel = ROLE_HIERARCHY[role] || 0;
      
      return Object.entries(ROLE_HIERARCHY)
        .filter(([_, level]) => level < userLevel)
        .map(([roleName]) => roleName)
        .sort((a, b) => ROLE_HIERARCHY[a] - ROLE_HIERARCHY[b]);
    };

    const permissions = {
      role: normalizedRole,
      can_publish_directly: ['super_admin', 'admin', 'editor'].includes(normalizedRole),
      can_approve_posts: ['super_admin', 'admin', 'editor'].includes(normalizedRole),
      can_hard_delete: ['super_admin', 'admin'].includes(normalizedRole),
      can_archive: true,
      can_edit_any: ['super_admin', 'admin', 'editor'].includes(normalizedRole),
      can_manage_users: ['super_admin', 'admin'].includes(normalizedRole),
      can_create_posts: true,
      can_create_quotes: true,
      can_feature: ['super_admin', 'admin', 'editor'].includes(normalizedRole),
      can_set_breaking: ['super_admin', 'admin'].includes(normalizedRole),
      can_set_pinned: ['super_admin', 'admin'].includes(normalizedRole),
      can_view_users: true,
      can_create_users: ['super_admin', 'admin'].includes(normalizedRole),
      can_edit_users: ['super_admin', 'admin'].includes(normalizedRole),
      can_delete_users: ['super_admin', 'admin'].includes(normalizedRole),
      can_change_own_password: true,
      can_reset_others_password: ['super_admin', 'admin'].includes(normalizedRole),
      can_manage_roles: ['super_admin', 'admin'].includes(normalizedRole),
      requires_approval: !['super_admin', 'admin', 'editor'].includes(normalizedRole),
      can_view_analytics: true,
      can_view_system_settings: ['super_admin'].includes(normalizedRole),
      can_view_all_users: ['super_admin', 'admin'].includes(normalizedRole),
      can_create_super_admin: normalizedRole === 'super_admin',
      can_promote_users: normalizedRole === 'super_admin',
      can_access_chat: true,
      assignable_roles: getAssignableRoles(normalizedRole)
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
        role::text as role,
        status::text as status,
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
      RETURNING admin_id, first_name, last_name, email, phone, role::text as role, updated_at
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
    const userRole = req.userRole;

    if (!userRole) {
      return res.status(401).json({
        success: false,
        message: 'Authentication required'
      });
    }

    const normalizedRole = userRole.toLowerCase().trim();

    if (normalizedRole !== 'super_admin') {
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
