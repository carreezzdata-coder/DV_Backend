const { getPool } = require('../config/db');
const { FRONTEND_URL, CLIENT_URL, ADMIN_URL, API_DOMAIN, ALLOWED_ORIGINS } = require('../config/frontendconfig');

const requireAdminAuth = async (req, res, next) => {
  try {
    const adminId = req.session?.adminId;

    if (!adminId) {
      return res.status(401).json({
        success: false,
        authenticated: false,
        message: 'Authentication required'
      });
    }

    const pool = getPool();
    const adminResult = await pool.query(
      `SELECT admin_id, first_name, last_name, email, phone, role, permissions, status
       FROM admins
       WHERE admin_id = $1 AND status = 'active'
       LIMIT 1`,
      [adminId]
    );

    if (adminResult.rows.length === 0) {
      req.session.destroy((err) => {
        if (err) console.error('[adminAuth] Session destroy error:', err);
      });

      return res.status(401).json({
        success: false,
        authenticated: false,
        message: 'Invalid or inactive admin account'
      });
    }

    const admin = adminResult.rows[0];
    
    req.admin = admin;
    req.adminId = admin.admin_id;
    req.userRole = admin.role;

    next();

  } catch (error) {
    console.error('[adminAuth] Middleware error:', error);
    return res.status(500).json({
      success: false,
      authenticated: false,
      message: 'Authentication failed'
    });
  }
};

module.exports = requireAdminAuth;