const express = require('express');
const router = express.Router();
const { getPool } = require('../../config/db');
const { upload, processUploadedFiles } = require('../../config/imagesUpload');
const requireAdminAuth = require('../../middleware/adminAuth');
const { getUserRole } = require('../../middleware/rolePermissions');

const { FRONTEND_URL, CLIENT_URL, ADMIN_URL, API_DOMAIN, ALLOWED_ORIGINS, isOriginAllowed } = require('../../config/frontendconfig');

const PERMISSIONS = {
  canCreateQuotes: (role) => ['super_admin', 'admin', 'editor', 'moderator'].includes(role),
  canAutoPublish: (role) => ['super_admin', 'admin', 'editor'].includes(role),
  canManageQuotes: (role) => ['super_admin', 'admin', 'editor', 'moderator'].includes(role)
};

const logAdminActivity = async (pool, adminId, action, targetType, targetId, details, ip) => {
  try {
    await pool.query(
      `INSERT INTO admin_activity_log (admin_id, action, target_type, target_id, details, ip_address) 
       VALUES ($1, $2, $3, $4, $5, $6)`,
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

router.post('/', requireAdminAuth, upload.single('sayer_image'), async (req, res) => {
  const pool = getPool();
  
  try {
    if (!req.body || Object.keys(req.body).length === 0) {
      return res.status(400).json({ 
        success: false, 
        message: 'Empty request body' 
      });
    }

    const quoteText = (req.body.quote_text || '').toString().trim();
    const sayerName = (req.body.sayer_name || '').toString().trim();
    const sayerTitle = (req.body.sayer_title || '').toString().trim();
    const editorPick = req.body.editor_pick === 'true' || req.body.editor_pick === true;

    if (!quoteText || !sayerName) {
      return res.status(400).json({ 
        success: false, 
        message: 'Quote text and sayer name are required' 
      });
    }

    const adminId = req.adminId;
    if (!adminId) {
      return res.status(401).json({ 
        success: false, 
        message: 'Authentication required' 
      });
    }
    
    const userRole = await getUserRole(adminId);

    if (!PERMISSIONS.canCreateQuotes(userRole)) {
      return res.status(403).json({ 
        success: false, 
        message: 'Insufficient permissions to create quotes' 
      });
    }

    const activeValue = PERMISSIONS.canAutoPublish(userRole);
    const editorPickValue = PERMISSIONS.canAutoPublish(userRole) ? editorPick : false;

    let imageUrl = null;
    if (req.file) {
      try {
        const processedFiles = await processUploadedFiles([req.file]);
        if (processedFiles && processedFiles.length > 0) {
          const processed = processedFiles[0];
          imageUrl = processed.url.startsWith('http') 
            ? processed.url 
            : processed.url.startsWith('/uploads/')
              ? processed.url
              : `/uploads/${processed.url.replace(/^\/+/, '')}`;
        }
      } catch (imgError) {
        console.error('[CREATE QUOTE] Image error:', imgError.message);
      }
    }
    
    const insertResult = await pool.query(
      `INSERT INTO news_quotes (quote_text, sayer_name, sayer_title, image_url, active, editor_pick) 
       VALUES ($1, $2, $3, $4, $5, $6)
       RETURNING quote_id, quote_text, sayer_name, sayer_title, image_url, active, editor_pick, created_at, updated_at`,
      [quoteText, sayerName, sayerTitle || null, imageUrl, activeValue, editorPickValue]
    );

    if (!insertResult.rows || insertResult.rows.length === 0) {
      throw new Error('Database INSERT failed');
    }

    const newQuote = insertResult.rows[0];
    const quoteId = newQuote.quote_id;

    if (imageUrl && req.file) {
      try {
        await pool.query(
          `INSERT INTO news_quotes_images (quote_id, image_url, file_size, mime_type, storage_provider, storage_mode, local_path, metadata) 
           VALUES ($1, $2, $3, $4, $5, $6, $7, $8)`,
          [
            quoteId,
            imageUrl,
            req.file.size || null,
            req.file.mimetype || 'image/jpeg',
            'local',
            process.env.NODE_ENV || 'development',
            req.file.path || null,
            JSON.stringify({ 
              originalName: req.file.originalname,
              uploadedAt: new Date().toISOString()
            })
          ]
        );
      } catch (imgMetaError) {
        console.error('[CREATE QUOTE] Image metadata error:', imgMetaError.message);
      }
    }

    const ip = req.headers['x-forwarded-for'] || req.headers['x-real-ip'] || req.ip || 'unknown';
    await logAdminActivity(
      pool, 
      adminId,
      'create_quote', 
      'news_quotes', 
      quoteId, 
      `Created: "${quoteText.substring(0, 50)}..." by ${sayerName}`, 
      ip
    );
    
    return res.status(201).json({ 
      success: true, 
      message: activeValue ? 'Quote published successfully' : 'Quote submitted for approval',
      quote: newQuote,
      status: activeValue ? 'published' : 'pending'
    });

  } catch (error) {
    console.error('[CREATE QUOTE] Error:', error.message);
    
    return res.status(500).json({ 
      success: false, 
      message: error.message || 'Failed to create quote',
      error: error.message
    });
  }
});

router.get('/', requireAdminAuth, async (req, res) => {
  try {
    const pool = getPool();
    
    const result = await pool.query(
      `SELECT quote_id, quote_text, sayer_name, sayer_title, active, editor_pick, image_url, created_at, updated_at
       FROM news_quotes
       ORDER BY created_at DESC`
    );

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
    console.error('[GET QUOTES] Error:', error);
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
    
    if (!quote_id || isNaN(Number(quote_id))) {
      return res.status(400).json({
        success: false,
        message: 'Valid quote ID required'
      });
    }

    const result = await pool.query(
      `SELECT quote_id, quote_text, sayer_name, sayer_title, active, editor_pick, image_url, created_at, updated_at
       FROM news_quotes
       WHERE quote_id = $1`,
      [quote_id]
    );

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
    console.error('[GET QUOTE] Error:', error);
    return res.status(500).json({ 
      success: false, 
      message: 'Internal server error', 
      error: error.message 
    });
  }
});

router.put('/:quote_id', requireAdminAuth, async (req, res) => {
  const pool = getPool();
  
  try {
    if (!req.body || Object.keys(req.body).length === 0) {
      return res.status(400).json({ 
        success: false,
        message: "No update data provided" 
      });
    }

    const { quote_id } = req.params;

    if (!quote_id || !/^\d+$/.test(quote_id)) {
      return res.status(400).json({ 
        success: false,
        message: "Invalid quote ID" 
      });
    }

    const { quote_text, sayer_name, sayer_title, active, editor_pick } = req.body;

    const adminId = req.adminId;
    const userRole = await getUserRole(adminId);
    
    if (!userRole || !PERMISSIONS.canManageQuotes(userRole)) {
      return res.status(403).json({ 
        success: false, 
        message: 'Insufficient permissions to update quotes'
      });
    }

    const checkResult = await pool.query(
      `SELECT * FROM news_quotes WHERE quote_id = $1`,
      [quote_id]
    );
    
    if (checkResult.rows.length === 0) {
      return res.status(404).json({ 
        success: false, 
        message: 'Quote not found' 
      });
    }

    const existingQuote = checkResult.rows[0];
    
    const updateResult = await pool.query(
      `UPDATE news_quotes 
       SET quote_text = COALESCE($1, quote_text),
           sayer_name = COALESCE($2, sayer_name),
           sayer_title = COALESCE($3, sayer_title),
           active = COALESCE($4, active),
           editor_pick = COALESCE($5, editor_pick),
           updated_at = CURRENT_TIMESTAMP
       WHERE quote_id = $6
       RETURNING *`,
      [
        quote_text || null,
        sayer_name || null,
        sayer_title !== undefined ? sayer_title : null,
        active !== undefined ? active : null,
        editor_pick !== undefined ? editor_pick : null,
        quote_id
      ]
    );

    const ip = req.headers['x-forwarded-for'] || req.headers['x-real-ip'] || req.ip || 'unknown';
    
    const changes = [];
    if (quote_text && quote_text !== existingQuote.quote_text) changes.push('text');
    if (sayer_name && sayer_name !== existingQuote.sayer_name) changes.push('name');
    if (active !== undefined && active !== existingQuote.active) changes.push('status');
    if (editor_pick !== undefined && editor_pick !== existingQuote.editor_pick) changes.push('editor_pick');
    
    await logAdminActivity(
      pool, 
      adminId,
      'update_quote', 
      'news_quotes', 
      quote_id, 
      `Updated: ${changes.join(', ')}`, 
      ip
    );

    return res.status(200).json({ 
      success: true, 
      message: 'Quote updated successfully',
      quote: updateResult.rows[0]
    });

  } catch (error) {
    console.error('[UPDATE QUOTE] Error:', error.message);
    return res.status(500).json({ 
      success: false, 
      message: 'Failed to update quote', 
      error: error.message
    });
  }
});

router.delete('/:quote_id', requireAdminAuth, async (req, res) => {
  const pool = getPool();
  
  try {
    const { quote_id } = req.params;

    if (!quote_id || !/^\d+$/.test(quote_id)) {
      return res.status(400).json({ 
        success: false,
        message: "Invalid quote ID" 
      });
    }

    const adminId = req.adminId;
    const userRole = await getUserRole(adminId);
    
    if (!userRole || !PERMISSIONS.canManageQuotes(userRole)) {
      return res.status(403).json({ 
        success: false, 
        message: 'Insufficient permissions to delete quotes'
      });
    }

    const checkResult = await pool.query(
      `SELECT * FROM news_quotes WHERE quote_id = $1`,
      [quote_id]
    );
    
    if (checkResult.rows.length === 0) {
      return res.status(404).json({ 
        success: false, 
        message: 'Quote not found' 
      });
    }

    const existingQuote = checkResult.rows[0];

    await pool.query(`DELETE FROM news_quotes_images WHERE quote_id = $1`, [quote_id]);
    await pool.query(`DELETE FROM news_quotes WHERE quote_id = $1`, [quote_id]);

    const ip = req.headers['x-forwarded-for'] || req.headers['x-real-ip'] || req.ip || 'unknown';
    
    await logAdminActivity(
      pool, 
      adminId,
      'delete_quote', 
      'news_quotes', 
      quote_id, 
      `Deleted: "${existingQuote.quote_text.substring(0, 50)}..." by ${existingQuote.sayer_name}`, 
      ip
    );

    return res.status(200).json({ 
      success: true, 
      message: 'Quote deleted successfully'
    });

  } catch (error) {
    console.error('[DELETE QUOTE] Error:', error.message);
    return res.status(500).json({ 
      success: false, 
      message: 'Failed to delete quote', 
      error: error.message
    });
  }
});

module.exports = router;