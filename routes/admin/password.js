const express = require('express');
const router = express.Router();
const bcrypt = require('bcryptjs');
const { getPool } = require('../../config/db');
const requireAdminAuth = require('../../middleware/adminAuth');
const { getUserRole } = require('../../middleware/rolePermissions');

const { FRONTEND_URL, CLIENT_URL, ADMIN_URL, API_DOMAIN, ALLOWED_ORIGINS, isOriginAllowed } = require('../../config/frontendconfig');

const isProduction = process.env.NODE_ENV === 'production';

const ROLE_HIERARCHY = {
  super_admin: 4,
  admin: 3,
  editor: 2,
  moderator: 1
};

const canManageRole = (requesterRole, targetRole) => {
  return ROLE_HIERARCHY[requesterRole] > ROLE_HIERARCHY[targetRole];
};

router.put('/change', requireAdminAuth, async (req, res) => {
  const pool = getPool();

  try {
    const adminId = req.adminId;
    const { current_password, new_password } = req.body;

    if (!current_password?.trim() || !new_password?.trim()) {
      return res.status(400).json({
        success: false,
        message: 'Current password and new password are required'
      });
    }

    const passwordRegex = /^(?=.*[a-z])(?=.*[A-Z])(?=.*\d).{6,}$/;
    if (!passwordRegex.test(new_password.trim())) {
      return res.status(400).json({
        success: false,
        message: 'Password must be at least 6 characters with uppercase, lowercase, and numbers'
      });
    }

    if (current_password.trim() === new_password.trim()) {
      return res.status(400).json({
        success: false,
        message: 'New password must be different from current password'
      });
    }

    const result = await pool.query(
      'SELECT admin_id, password_hash, email FROM admins WHERE admin_id = $1',
      [adminId]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'User not found'
      });
    }

    const user = result.rows[0];

    const isValidPassword = await bcrypt.compare(current_password.trim(), user.password_hash);

    if (!isValidPassword) {
      return res.status(401).json({
        success: false,
        message: 'Current password is incorrect'
      });
    }

    const hashedPassword = await bcrypt.hash(new_password.trim(), 12);

    await pool.query(
      'UPDATE admins SET password_hash = $1, updated_at = CURRENT_TIMESTAMP WHERE admin_id = $2',
      [hashedPassword, adminId]
    );

    const ip = req.headers['x-forwarded-for'] || req.headers['x-real-ip'] || req.ip || 'unknown';
    try {
      await pool.query(
        `INSERT INTO admin_activity_log (admin_id, action, target_type, target_id, details, ip_address, created_at)
         VALUES ($1, $2, $3, $4, $5, $6, CURRENT_TIMESTAMP)`,
        [
          adminId,
          'change_password',
          'admin',
          adminId,
          'Changed own password',
          ip
        ]
      );
    } catch (logError) {
      console.warn('[Password] Failed to log activity:', logError.message);
    }

    res.status(200).json({
      success: true,
      message: 'Password changed successfully'
    });

  } catch (error) {
    console.error('[Password] Change error:', error);
    res.status(500).json({
      success: false,
      message: 'Internal server error',
      error: isProduction ? undefined : error.message
    });
  }
});

router.put('/reset', requireAdminAuth, async (req, res) => {
  const pool = getPool();

  try {
    const adminId = req.adminId;
    const userRole = await getUserRole(adminId);
    const { user_id, new_password } = req.body;

    if (!user_id) {
      return res.status(400).json({
        success: false,
        message: 'User ID is required'
      });
    }

    if (!new_password?.trim()) {
      return res.status(400).json({
        success: false,
        message: 'New password is required'
      });
    }

    const passwordRegex = /^(?=.*[a-z])(?=.*[A-Z])(?=.*\d).{6,}$/;
    if (!passwordRegex.test(new_password.trim())) {
      return res.status(400).json({
        success: false,
        message: 'Password must be at least 6 characters with uppercase, lowercase, and numbers'
      });
    }

    if (!['super_admin', 'admin'].includes(userRole)) {
      return res.status(403).json({
        success: false,
        message: 'Only Super Admins and Admins can reset passwords'
      });
    }

    const targetUser = await pool.query(
      'SELECT admin_id, role, email, first_name, last_name FROM admins WHERE admin_id = $1',
      [user_id]
    );

    if (targetUser.rows.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'User not found'
      });
    }

    const target = targetUser.rows[0];

    if (parseInt(user_id) === adminId) {
      return res.status(403).json({
        success: false,
        message: 'Cannot reset your own password. Use change password instead'
      });
    }

    if (!canManageRole(userRole, target.role)) {
      return res.status(403).json({
        success: false,
        message: 'Insufficient permissions to reset this user password'
      });
    }

    const hashedPassword = await bcrypt.hash(new_password.trim(), 12);

    await pool.query(
      'UPDATE admins SET password_hash = $1, updated_at = CURRENT_TIMESTAMP WHERE admin_id = $2',
      [hashedPassword, user_id]
    );

    const ip = req.headers['x-forwarded-for'] || req.headers['x-real-ip'] || req.ip || 'unknown';
    try {
      await pool.query(
        `INSERT INTO admin_activity_log (admin_id, action, target_type, target_id, details, ip_address, created_at)
         VALUES ($1, $2, $3, $4, $5, $6, CURRENT_TIMESTAMP)`,
        [
          adminId,
          'reset_password',
          'admin',
          user_id,
          `Reset password for ${target.first_name} ${target.last_name} (${target.email})`,
          ip
        ]
      );
    } catch (logError) {
      console.warn('[Password] Failed to log activity:', logError.message);
    }

    res.status(200).json({
      success: true,
      message: 'Password reset successfully'
    });

  } catch (error) {
    console.error('[Password] Reset error:', error);
    res.status(500).json({
      success: false,
      message: 'Internal server error',
      error: isProduction ? undefined : error.message
    });
  }
});

module.exports = router;