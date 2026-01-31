// backend/routes/admin/auth.js
const express = require('express');
const bcrypt = require('bcryptjs'); // Using bcryptjs - MUST match user.js
const crypto = require('crypto');
const { getPool } = require('../../config/db');
const { FRONTEND_URL, CLIENT_URL, ADMIN_URL, API_DOMAIN, ALLOWED_ORIGINS, isOriginAllowed } = require('../../config/frontendconfig');
const router = express.Router();

const generateCSRFToken = () => crypto.randomBytes(32).toString('hex');

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

    console.log('Admin login attempt for:', trimmedIdentifier);

    const adminResult = await pool.query(
      `SELECT admin_id, first_name, last_name, email, phone, role, permissions,
              password_hash, last_login, status, username
       FROM admins
       WHERE (email = $1 OR phone = $1 OR username = $1) AND status = 'active'
       LIMIT 1`,
      [trimmedIdentifier]
    );

    console.log('Admin query result:', adminResult.rows.length > 0 ? 'Found admin' : 'No admin found');

    if (adminResult.rows.length === 0) {
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
    console.log('Found admin:', admin.username || admin.email);
    console.log('Password hash from DB:', admin.password_hash.substring(0, 20) + '...');

    // Password verification using bcryptjs (MUST match user.js)
    let isValidPassword = false;

    try {
      isValidPassword = await bcrypt.compare(trimmedPassword, admin.password_hash);
      console.log('Password validation result:', isValidPassword);
    } catch (bcryptError) {
      console.error('Bcrypt comparison error:', bcryptError.message);
      console.error('Stack:', bcryptError.stack);
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
      return res.status(401).json({
        success: false,
        authenticated: false,
        user: null,
        csrf_token: null,
        error: 'Invalid credentials',
        message: null
      });
    }

    req.session.regenerate(async (err) => {
      if (err) {
        console.error('Session regeneration error:', err);
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
        req.session.adminId = admin.admin_id;
        req.session.loginTime = new Date().toISOString();

        const csrfToken = generateCSRFToken();
        req.session.csrfToken = csrfToken;

        await pool.query(
          'UPDATE admins SET last_login = NOW() WHERE admin_id = $1',
          [admin.admin_id]
        );

        console.log('Admin login successful:', {
          adminId: admin.admin_id,
          email: admin.email,
          role: admin.role
        });

        const userResponse = {
          admin_id: admin.admin_id,
          first_name: admin.first_name,
          last_name: admin.last_name,
          email: admin.email,
          phone: admin.phone,
          role: admin.role,
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
        console.error('Error updating last login:', updateError);
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
    console.error('Login error details:', error);
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

router.post('/logout', (req, res) => {
  console.log('Admin logout attempt for session:', req.session.id);

  req.session.destroy(err => {
    if (err) {
      console.error('Session destroy error:', err);
      return res.status(500).json({
        success: false,
        authenticated: false,
        user: null,
        csrf_token: null,
        error: 'Could not log out',
        message: null
      });
    }

    console.log('Admin logout successful - session destroyed');

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

router.get('/verify', async (req, res) => {
  try {
    const pool = getPool();
    const adminId = req.session?.adminId;

    console.log('Admin session verification:', {
      hasSession: !!req.session,
      hasAdminId: !!adminId,
      sessionId: req.session?.id
    });

    if (!adminId) {
      return res.status(401).json({
        success: false,
        authenticated: false,
        user: null,
        csrf_token: null,
        error: 'No active session found',
        message: null
      });
    }

    const adminResult = await pool.query(
      `SELECT admin_id, first_name, last_name, email, phone, role, permissions,
              last_login, status
       FROM admins
       WHERE admin_id = $1 AND status = 'active'
       LIMIT 1`,
      [adminId]
    );

    console.log('Admin verification query result:', adminResult.rows.length > 0 ? 'Valid admin found' : 'Admin not found/inactive');

    if (adminResult.rows.length === 0) {
      req.session.destroy((err) => {
        if (err) console.error('Error destroying invalid session:', err);
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

    if (!req.session.csrfToken) {
      req.session.csrfToken = generateCSRFToken();
    }

    console.log('Admin session verified successfully for:', admin.admin_id, 'with role:', admin.role);

    return res.status(200).json({
      success: true,
      authenticated: true,
      user: {
        admin_id: admin.admin_id,
        first_name: admin.first_name,
        last_name: admin.last_name,
        email: admin.email,
        phone: admin.phone,
        role: admin.role,
        permissions: admin.permissions || [],
        last_login: admin.last_login,
        status: admin.status
      },
      csrf_token: req.session.csrfToken,
      error: null,
      message: 'Session verified'
    });

  } catch (error) {
    console.error('Admin session verification error:', error);
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
