const express = require('express');
const router = express.Router();
const { getPool } = require('../../config/db');
const requireAdminAuth = require('../../middleware/adminAuth');
const { getUserRole } = require('../../middleware/rolePermissions');

const { FRONTEND_URL, CLIENT_URL, ADMIN_URL, API_DOMAIN, ALLOWED_ORIGINS, isOriginAllowed } = require('../../config/frontendconfig');

const canManageQuotes = (role) => {
  return ['super_admin', 'admin', 'editor', 'moderator'].includes(role);
};

const logAdminActivity = async (client, adminId, action, targetType, targetId, details, ip) => {
  try {
    await client.query(
      `INSERT INTO admin_activity_log (admin_id, action, target_type, target_id, details, ip_address) VALUES ($1, $2, $3, $4, $5, $6)`,
      [adminId, action, targetType, targetId, details, ip]
    );
  } catch (error) {
    console.error('[logAdminActivity] Error:', error.message);
  }
};

const getImageUrl = (imageUrl) => {
  if (!imageUrl) return null;
  if (imageUrl.startsWith('http://') || imageUrl.startsWith('https://')) {
    return imageUrl;
  }

  const cleanPath = imageUrl.startsWith('/') ? imageUrl.substring(1) : imageUrl;

  if (process.env.NODE_ENV === 'development') {
    return `http://localhost:5000/${cleanPath}`;
  }

  const r2Url = process.env.R2_PUBLIC_URL;
  if (r2Url) {
    const cleanUrl = r2Url.endsWith('/') ? r2Url.slice(0, -1) : r2Url;
    return `${cleanUrl}/${cleanPath}`;
  }

  return imageUrl;
};

router.get('/', requireAdminAuth, async (req, res) => {
  try {
    const pool = getPool();
    
    console.log('[RETRIEVE QUOTES] Fetching all quotes');
    
    const query = `
      SELECT 
        q.quote_id, 
        q.quote_text, 
        q.sayer_name, 
        q.sayer_title, 
        q.active,
        q.editor_pick,
        q.image_url,
        q.created_at, 
        q.updated_at
      FROM news_quotes q
      ORDER BY q.created_at DESC
    `;

    const result = await pool.query(query);

    console.log(`[RETRIEVE QUOTES] Found ${result.rows.length} quotes`);

    const quotes = result.rows.map(quote => ({
      quote_id: quote.quote_id,
      quote_text: quote.quote_text,
      sayer_name: quote.sayer_name,
      sayer_title: quote.sayer_title || '',
      image_url: getImageUrl(quote.image_url),
      active: quote.active,
      editor_pick: quote.editor_pick || false,
      created_at: quote.created_at,
      updated_at: quote.updated_at
    }));

    return res.status(200).json({
      success: true,
      quotes: quotes,
      total: quotes.length,
      message: 'Quotes retrieved successfully'
    });

  } catch (error) {
    console.error('[RETRIEVE QUOTES] Error:', error);
    return res.status(500).json({ 
      success: false, 
      message: 'Internal server error', 
      error: error.message 
    });
  }
});

router.get('/:quote_id', requireAdminAuth, async (req, res) => {
  try {
    const pool = getPool();
    const { quote_id } = req.params;
    
    console.log('[RETRIEVE QUOTES] Fetching quote:', quote_id);
    
    if (!quote_id || isNaN(Number(quote_id))) {
      return res.status(400).json({
        success: false,
        message: 'Valid quote ID required'
      });
    }

    const query = `
      SELECT 
        q.quote_id, 
        q.quote_text, 
        q.sayer_name, 
        q.sayer_title, 
        q.active,
        q.editor_pick,
        q.image_url,
        q.created_at, 
        q.updated_at
      FROM news_quotes q
      WHERE q.quote_id = $1
    `;

    const result = await pool.query(query, [quote_id]);

    if (result.rows.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'Quote not found'
      });
    }

    const quote = result.rows[0];

    return res.status(200).json({
      success: true,
      quote: {
        quote_id: quote.quote_id,
        quote_text: quote.quote_text,
        sayer_name: quote.sayer_name,
        sayer_title: quote.sayer_title || '',
        image_url: getImageUrl(quote.image_url),
        active: quote.active,
        editor_pick: quote.editor_pick || false,
        created_at: quote.created_at,
        updated_at: quote.updated_at
      },
      message: 'Quote retrieved successfully'
    });

  } catch (error) {
    console.error('[RETRIEVE QUOTES] Error:', error);
    return res.status(500).json({ 
      success: false, 
      message: 'Internal server error', 
      error: error.message 
    });
  }
});

router.put('/:quote_id', requireAdminAuth, async (req, res) => {
  console.log('[UPDATE QUOTE] Starting update for quote:', req.params.quote_id);
  
  const pool = getPool();
  let client;
  
  try {
    if (!req.body || Object.keys(req.body).length === 0) {
      return res.status(400).json({ 
        success: false,
        message: "No update data provided" 
      });
    }

    client = await pool.connect();
    await client.query('BEGIN');
    
    const { quote_id } = req.params;

    if (!quote_id || !/^\d+$/.test(quote_id)) {
      await client.query('ROLLBACK');
      client.release();
      return res.status(400).json({ 
        success: false,
        message: "Invalid quote ID" 
      });
    }

    const { quote_text, sayer_name, sayer_title, active, editor_pick } = req.body;

    const adminId = req.adminId;
    const userRole = await getUserRole(adminId);
    
    if (!userRole || !canManageQuotes(userRole)) {
      await client.query('ROLLBACK');
      client.release();
      return res.status(403).json({ 
        success: false, 
        message: 'Insufficient permissions to update quotes'
      });
    }

    const checkQuery = `SELECT * FROM news_quotes WHERE quote_id = $1`;
    const checkResult = await client.query(checkQuery, [quote_id]);
    
    if (checkResult.rows.length === 0) {
      await client.query('ROLLBACK');
      client.release();
      return res.status(404).json({ 
        success: false, 
        message: 'Quote not found' 
      });
    }

    const existingQuote = checkResult.rows[0];
    
    const updateQuery = `
      UPDATE news_quotes 
      SET 
        quote_text = COALESCE($1, quote_text),
        sayer_name = COALESCE($2, sayer_name),
        sayer_title = COALESCE($3, sayer_title),
        active = COALESCE($4, active),
        editor_pick = COALESCE($5, editor_pick),
        updated_at = CURRENT_TIMESTAMP
      WHERE quote_id = $6
      RETURNING *
    `;

    const updateResult = await client.query(updateQuery, [
      quote_text || null,
      sayer_name || null,
      sayer_title !== undefined ? sayer_title : null,
      active !== undefined ? active : null,
      editor_pick !== undefined ? editor_pick : null,
      quote_id
    ]);

    const ip = req.headers['x-forwarded-for'] || req.headers['x-real-ip'] || req.ip || 'unknown';
    
    const changes = [];
    if (quote_text && quote_text !== existingQuote.quote_text) changes.push('text');
    if (sayer_name && sayer_name !== existingQuote.sayer_name) changes.push('name');
    if (active !== undefined && active !== existingQuote.active) changes.push('status');
    if (editor_pick !== undefined && editor_pick !== existingQuote.editor_pick) changes.push('editor_pick');
    
    await logAdminActivity(
      client, 
      adminId,
      'update_quote', 
      'news_quotes', 
      quote_id, 
      `Updated: ${changes.join(', ')}`, 
      ip
    );
    
    await client.query('COMMIT');
    client.release();

    console.log('[UPDATE QUOTE] Successfully updated quote:', quote_id);

    return res.status(200).json({ 
      success: true, 
      message: 'Quote updated successfully',
      quote: updateResult.rows[0]
    });

  } catch (error) {
    if (client) {
      await client.query('ROLLBACK');
      client.release();
    }
    console.error('[UPDATE QUOTE] Error:', error.message);
    return res.status(500).json({ 
      success: false, 
      message: 'Failed to update quote', 
      error: error.message
    });
  }
});

router.delete('/:quote_id', requireAdminAuth, async (req, res) => {
  console.log('[DELETE QUOTE] Starting delete for quote:', req.params.quote_id);
  
  const pool = getPool();
  let client;
  
  try {
    client = await pool.connect();
    await client.query('BEGIN');
    
    const { quote_id } = req.params;

    if (!quote_id || !/^\d+$/.test(quote_id)) {
      await client.query('ROLLBACK');
      client.release();
      return res.status(400).json({ 
        success: false,
        message: "Invalid quote ID" 
      });
    }

    const adminId = req.adminId;
    const userRole = await getUserRole(adminId);
    
    if (!userRole || !canManageQuotes(userRole)) {
      await client.query('ROLLBACK');
      client.release();
      return res.status(403).json({ 
        success: false, 
        message: 'Insufficient permissions to delete quotes'
      });
    }

    const checkQuery = `SELECT * FROM news_quotes WHERE quote_id = $1`;
    const checkResult = await client.query(checkQuery, [quote_id]);
    
    if (checkResult.rows.length === 0) {
      await client.query('ROLLBACK');
      client.release();
      return res.status(404).json({ 
        success: false, 
        message: 'Quote not found' 
      });
    }

    const existingQuote = checkResult.rows[0];

    console.log('[DELETE QUOTE] Deleting image metadata...');
    await client.query(`DELETE FROM news_quotes_images WHERE quote_id = $1`, [quote_id]);
    
    console.log('[DELETE QUOTE] Deleting quote...');
    await client.query(`DELETE FROM news_quotes WHERE quote_id = $1`, [quote_id]);

    const ip = req.headers['x-forwarded-for'] || req.headers['x-real-ip'] || req.ip || 'unknown';
    
    await logAdminActivity(
      client, 
      adminId,
      'delete_quote', 
      'news_quotes', 
      quote_id, 
      `Deleted: "${existingQuote.quote_text.substring(0, 50)}..." by ${existingQuote.sayer_name}`, 
      ip
    );
    
    await client.query('COMMIT');
    client.release();

    console.log('[DELETE QUOTE] Successfully deleted quote:', quote_id);

    return res.status(200).json({ 
      success: true, 
      message: 'Quote deleted successfully'
    });

  } catch (error) {
    if (client) {
      await client.query('ROLLBACK');
      client.release();
    }
    console.error('[DELETE QUOTE] Error:', error.message);
    return res.status(500).json({ 
      success: false, 
      message: 'Failed to delete quote', 
      error: error.message
    });
  }
});

module.exports = router;