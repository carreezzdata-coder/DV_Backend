const express = require('express');
const router = express.Router();
const { getPool } = require('../../config/db');
const { FRONTEND_URL, CLIENT_URL, ADMIN_URL, API_DOMAIN, ALLOWED_ORIGINS } = require('../../config/frontendconfig');
const requireAdminAuth = require('../../middleware/adminAuth');

const isProduction = process.env.NODE_ENV === 'production';

router.get('/', requireAdminAuth, async (req, res) => {
  const pool = getPool();
  let client;

  try {
    const adminId = req.adminId;

    client = await pool.connect();

    const profileQuery = `
      SELECT
        admin_id,
        first_name,
        last_name,
        email,
        phone,
        role,
        username,
        permissions,
        last_login,
        created_at,
        status
      FROM admins
      WHERE admin_id = $1 AND status = 'active'
    `;

    const profileResult = await client.query(profileQuery, [adminId]);

    if (profileResult.rows.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'Admin profile not found'
      });
    }

    const profile = profileResult.rows[0];

    const statsQuery = `
      SELECT
        COUNT(*) as total_posts,
        COUNT(*) FILTER (WHERE status = 'published') as published_posts,
        COUNT(*) FILTER (WHERE status = 'draft') as draft_posts,
        COUNT(*) FILTER (WHERE status = 'archived') as archived_posts,
        COALESCE(SUM(views), 0) as total_views,
        COALESCE(SUM(likes_count), 0) as total_likes,
        COALESCE(SUM(comments_count), 0) as total_comments,
        COALESCE(SUM(share_count), 0) as total_shares
      FROM news
      WHERE author_id = $1
    `;

    const statsResult = await client.query(statsQuery, [adminId]);
    const stats = statsResult.rows[0];

    const totalPosts = parseInt(stats.total_posts) || 0;
    const publishedPosts = parseInt(stats.published_posts) || 0;
    const draftPosts = parseInt(stats.draft_posts) || 0;
    const archivedPosts = parseInt(stats.archived_posts) || 0;
    const totalViews = parseInt(stats.total_views) || 0;
    const totalLikes = parseInt(stats.total_likes) || 0;
    const totalComments = parseInt(stats.total_comments) || 0;
    const totalShares = parseInt(stats.total_shares) || 0;

    const totalEngagement = totalLikes + totalComments + totalShares;
    const avgEngagementRate = totalViews > 0 ? (totalEngagement / totalViews) * 100 : 0;

    const topPostQuery = `
      SELECT
        title,
        slug,
        views,
        likes_count,
        comments_count,
        share_count
      FROM news
      WHERE author_id = $1 AND status = 'published'
      ORDER BY views DESC
      LIMIT 1
    `;

    const topPostResult = await client.query(topPostQuery, [adminId]);
    const topPerformingPost = topPostResult.rows.length > 0 ? {
      title: topPostResult.rows[0].title,
      slug: topPostResult.rows[0].slug,
      views: parseInt(topPostResult.rows[0].views) || 0,
      likes: parseInt(topPostResult.rows[0].likes_count) || 0,
      comments: parseInt(topPostResult.rows[0].comments_count) || 0,
      shares: parseInt(topPostResult.rows[0].share_count) || 0
    } : null;

    const activityQuery = `
      SELECT
        action,
        details as target,
        created_at as timestamp
      FROM admin_activity_log
      WHERE admin_id = $1
      ORDER BY created_at DESC
      LIMIT 15
    `;

    const activityResult = await client.query(activityQuery, [adminId]);
    const recentActivity = activityResult.rows.map(row => ({
      action: row.action,
      target: row.target || 'N/A',
      timestamp: row.timestamp
    }));

    const monthlyStatsQuery = `
      SELECT
        COUNT(*) as posts_this_month,
        COALESCE(SUM(views), 0) as views_this_month
      FROM news
      WHERE author_id = $1
        AND created_at >= DATE_TRUNC('month', CURRENT_DATE)
    `;

    const monthlyStatsResult = await client.query(monthlyStatsQuery, [adminId]);
    const monthlyStats = monthlyStatsResult.rows[0];

    const postsThisMonth = parseInt(monthlyStats.posts_this_month) || 0;
    const viewsThisMonth = parseInt(monthlyStats.views_this_month) || 0;

    res.json({
      success: true,
      profile: {
        admin_id: profile.admin_id,
        first_name: profile.first_name,
        last_name: profile.last_name,
        email: profile.email,
        phone: profile.phone,
        role: profile.role,
        username: profile.username || `${profile.first_name.toLowerCase()}${profile.admin_id}`,
        permissions: profile.permissions || [],
        last_login: profile.last_login,
        created_at: profile.created_at,
        status: profile.status
      },
      stats: {
        total_posts: totalPosts,
        published_posts: publishedPosts,
        draft_posts: draftPosts,
        archived_posts: archivedPosts,
        total_views: totalViews,
        total_likes: totalLikes,
        total_comments: totalComments,
        total_shares: totalShares,
        avg_engagement_rate: parseFloat(avgEngagementRate.toFixed(2)),
        posts_this_month: postsThisMonth,
        views_this_month: viewsThisMonth,
        top_performing_post: topPerformingPost,
        recent_activity: recentActivity
      }
    });

  } catch (error) {
    console.error('[User Profile] Fetch error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to fetch user profile',
      error: isProduction ? undefined : error.message
    });
  } finally {
    if (client) {
      client.release();
    }
  }
});

router.put('/update', requireAdminAuth, async (req, res) => {
  const pool = getPool();
  let client;

  try {
    const adminId = req.adminId;
    const { phone, username } = req.body;

    if (!phone && !username) {
      return res.status(400).json({
        success: false,
        message: 'No fields to update'
      });
    }

    client = await pool.connect();
    await client.query('BEGIN');

    let updateQuery = 'UPDATE admins SET ';
    const updateFields = [];
    const updateValues = [];
    let paramIndex = 1;

    if (phone) {
      updateFields.push(`phone = $${paramIndex++}`);
      updateValues.push(phone.trim());
    }

    if (username) {
      const usernameCheck = await client.query(
        'SELECT admin_id FROM admins WHERE username = $1 AND admin_id != $2',
        [username.trim(), adminId]
      );

      if (usernameCheck.rows.length > 0) {
        await client.query('ROLLBACK');
        return res.status(409).json({
          success: false,
          message: 'Username already exists'
        });
      }

      updateFields.push(`username = $${paramIndex++}`);
      updateValues.push(username.trim());
    }

    updateFields.push(`updated_at = CURRENT_TIMESTAMP`);

    updateQuery += updateFields.join(', ');
    updateQuery += ` WHERE admin_id = $${paramIndex} AND status = 'active' RETURNING admin_id, first_name, last_name, email, phone, username`;
    updateValues.push(adminId);

    const result = await client.query(updateQuery, updateValues);

    if (result.rows.length === 0) {
      await client.query('ROLLBACK');
      return res.status(404).json({
        success: false,
        message: 'Admin not found'
      });
    }

    const ip = req.headers['x-forwarded-for'] || req.headers['x-real-ip'] || req.ip || 'unknown';
    await client.query(
      `INSERT INTO admin_activity_log (admin_id, action, target_type, details, ip_address)
       VALUES ($1, $2, $3, $4, $5)`,
      [adminId, 'update_profile', 'settings', 'Updated profile information', ip]
    );

    await client.query('COMMIT');

    res.json({
      success: true,
      message: 'Profile updated successfully',
      profile: result.rows[0]
    });

  } catch (error) {
    if (client) {
      await client.query('ROLLBACK');
    }
    console.error('[User Profile] Update error:', error);

    if (error.code === '23505') {
      return res.status(409).json({
        success: false,
        message: 'Username or phone already exists'
      });
    }

    res.status(500).json({
      success: false,
      message: 'Failed to update profile',
      error: isProduction ? undefined : error.message
    });
  } finally {
    if (client) {
      client.release();
    }
  }
});

module.exports = router;