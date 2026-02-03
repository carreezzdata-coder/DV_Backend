// backend/routes/admin/auth.js
const express = require('express');
const bcrypt = require('bcryptjs');
const crypto = require('crypto');
const { getPool } = require('../../config/db');
const { FRONTEND_URL, CLIENT_URL, ADMIN_URL, API_DOMAIN, ALLOWED_ORIGINS, isOriginAllowed } = require('../../config/frontendconfig');
const router = express.Router();

const generateCSRFToken = () => crypto.randomBytes(32).toString('hex');

// ============================================================================
// LOGIN
// ============================================================================
router.post('/login', async (req, res) => {
  let pool;
  try {
    pool = getPool();
    const { identifier, email, password } = req.body;
    const loginField = identifier || email;

    if (!loginField || !password) {
      return res.status(400).json({
        success: false,
        authenticated: false,
        user: null,
        csrf_token: null,
        error: 'Username/email and password are required',
        message: null
      });
    }

    const trimmedIdentifier = loginField.trim();
    const trimmedPassword = password.trim();

    if (!trimmedIdentifier || !trimmedPassword) {
      return res.status(400).json({
        success: false,
        authenticated: false,
        user: null,
        csrf_token: null,
        error: 'Username/email and password cannot be empty',
        message: null
      });
    }

    if (trimmedPassword.length < 6) {
      return res.status(400).json({
        success: false,
        authenticated: false,
        user: null,
        csrf_token: null,
        error: 'Password must be at least 6 characters',
        message: null
      });
    }

    console.log('[Admin Login] Attempt for:', trimmedIdentifier);

    // ✅ FIX: Cast ENUM types to text to ensure proper string handling
    const adminResult = await pool.query(
      `SELECT 
        admin_id, 
        first_name, 
        last_name, 
        email, 
        phone, 
        role::text as role,
        permissions,
        password_hash, 
        last_login, 
        status::text as status,
        username,
        role_id
       FROM admins
       WHERE (email = $1 OR phone = $1 OR username = $1) AND status = 'active'
       LIMIT 1`,
      [trimmedIdentifier]
    );

    console.log('[Admin Login] Query result:', {
      found: adminResult.rows.length > 0,
      role: adminResult.rows[0]?.role,
      status: adminResult.rows[0]?.status
    });

    if (adminResult.rows.length === 0) {
      console.log('[Admin Login] No matching admin found');
      return res.status(401).json({
        success: false,
        authenticated: false,
        user: null,
        csrf_token: null,
        error: 'Invalid credentials',
        message: null
      });
    }

    const admin = adminResult.rows[0];
    console.log('[Admin Login] Found admin:', {
      adminId: admin.admin_id,
      email: admin.email,
      role: admin.role,
      username: admin.username
    });

    // ✅ Password verification using bcryptjs
    let isValidPassword = false;

    try {
      isValidPassword = await bcrypt.compare(trimmedPassword, admin.password_hash);
      console.log('[Admin Login] Password validation result:', isValidPassword);
    } catch (bcryptError) {
      console.error('[Admin Login] Bcrypt comparison error:', bcryptError.message);
      console.error('[Admin Login] Stack:', bcryptError.stack);
      return res.status(500).json({
        success: false,
        authenticated: false,
        user: null,
        csrf_token: null,
        error: 'Password verification failed',
        message: 'Please contact administrator'
      });
    }

    if (!isValidPassword) {
      console.log('[Admin Login] Invalid password');
      return res.status(401).json({
        success: false,
        authenticated: false,
        user: null,
        csrf_token: null,
        error: 'Invalid credentials',
        message: null
      });
    }

    // ✅ Regenerate session for security
    req.session.regenerate(async (err) => {
      if (err) {
        console.error('[Admin Login] Session regeneration error:', err);
        return res.status(500).json({
          success: false,
          authenticated: false,
          user: null,
          csrf_token: null,
          error: 'Could not create session',
          message: 'Session creation failed'
        });
      }

      try {
        // ✅ Store admin info in session
        req.session.adminId = admin.admin_id;
        req.session.loginTime = new Date().toISOString();

        const csrfToken = generateCSRFToken();
        req.session.csrfToken = csrfToken;

        // ✅ Update last login
        await pool.query(
          'UPDATE admins SET last_login = NOW() WHERE admin_id = $1',
          [admin.admin_id]
        );

        // ✅ FIX: Normalize role to lowercase string
        const normalizedRole = admin.role ? admin.role.toLowerCase() : 'moderator';

        console.log('[Admin Login] Login successful:', {
          adminId: admin.admin_id,
          email: admin.email,
          role: normalizedRole
        });

        const userResponse = {
          admin_id: admin.admin_id,
          first_name: admin.first_name,
          last_name: admin.last_name,
          email: admin.email,
          phone: admin.phone,
          role: normalizedRole,  // ✅ Send normalized role
          permissions: admin.permissions || [],
          last_login: new Date().toISOString(),
          status: admin.status
        };

        return res.status(200).json({
          success: true,
          authenticated: true,
          user: userResponse,
          csrf_token: csrfToken,
          error: null,
          message: 'Login successful'
        });
      } catch (updateError) {
        console.error('[Admin Login] Error updating last login:', updateError);
        return res.status(500).json({
          success: false,
          authenticated: false,
          user: null,
          csrf_token: null,
          error: 'Login processing failed',
          message: null
        });
      }
    });

  } catch (error) {
    console.error('[Admin Login] Login error:', error);
    console.error('[Admin Login] Error stack:', error.stack);
    return res.status(500).json({
      success: false,
      authenticated: false,
      user: null,
      csrf_token: null,
      error: 'Internal server error',
      message: 'Login failed'
    });
  }
});

// ============================================================================
// LOGOUT
// ============================================================================
router.post('/logout', (req, res) => {
  console.log('[Admin Logout] Attempting logout for session:', req.session?.id);

  req.session.destroy(err => {
    if (err) {
      console.error('[Admin Logout] Session destroy error:', err);
      return res.status(500).json({
        success: false,
        authenticated: false,
        user: null,
        csrf_token: null,
        error: 'Could not log out',
        message: null
      });
    }

    console.log('[Admin Logout] Logout successful - session destroyed');

    res.status(200).json({
      success: true,
      authenticated: false,
      user: null,
      csrf_token: null,
      error: null,
      message: 'Logout successful'
    });
  });
});

// ============================================================================
// VERIFY SESSION
// ============================================================================
router.get('/verify', async (req, res) => {
  try {
    const pool = getPool();
    const adminId = req.session?.adminId;

    console.log('[Admin Verify] Session verification:', {
      hasSession: !!req.session,
      hasAdminId: !!adminId,
      sessionId: req.session?.id
    });

    if (!adminId) {
      console.log('[Admin Verify] No adminId in session');
      return res.status(401).json({
        success: false,
        authenticated: false,
        user: null,
        csrf_token: null,
        error: 'No active session found',
        message: null
      });
    }

    // ✅ FIX: Cast ENUM types to text
    const adminResult = await pool.query(
      `SELECT 
        admin_id, 
        first_name, 
        last_name, 
        email, 
        phone, 
        role::text as role,
        permissions,
        last_login, 
        status::text as status,
        role_id
       FROM admins
       WHERE admin_id = $1 AND status = 'active'
       LIMIT 1`,
      [adminId]
    );

    console.log('[Admin Verify] Query result:', {
      found: adminResult.rows.length > 0,
      role: adminResult.rows[0]?.role,
      status: adminResult.rows[0]?.status
    });

    if (adminResult.rows.length === 0) {
      console.log('[Admin Verify] Admin not found or inactive');
      req.session.destroy((err) => {
        if (err) console.error('[Admin Verify] Error destroying invalid session:', err);
      });

      return res.status(401).json({
        success: false,
        authenticated: false,
        user: null,
        csrf_token: null,
        error: 'Invalid or expired session',
        message: null
      });
    }

    const admin = adminResult.rows[0];

    // ✅ Generate CSRF token if missing
    if (!req.session.csrfToken) {
      req.session.csrfToken = generateCSRFToken();
    }

    // ✅ FIX: Normalize role to lowercase string
    const normalizedRole = admin.role ? admin.role.toLowerCase() : 'moderator';

    console.log('[Admin Verify] Session verified successfully:', {
      adminId: admin.admin_id,
      role: normalizedRole,
      email: admin.email
    });

    return res.status(200).json({
      success: true,
      authenticated: true,
      user: {
        admin_id: admin.admin_id,
        first_name: admin.first_name,
        last_name: admin.last_name,
        email: admin.email,
        phone: admin.phone,
        role: normalizedRole,  // ✅ Send normalized role
        permissions: admin.permissions || [],
        last_login: admin.last_login,
        status: admin.status
      },
      csrf_token: req.session.csrfToken,
      error: null,
      message: 'Session verified'
    });

  } catch (error) {
    console.error('[Admin Verify] Session verification error:', error);
    console.error('[Admin Verify] Error stack:', error.stack);
    return res.status(500).json({
      success: false,
      authenticated: false,
      user: null,
      csrf_token: null,
      error: 'Session verification failed',
      message: 'Internal server error'
    });
  }
});

module.exports = router;
