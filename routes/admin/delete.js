const express = require('express');
const router = express.Router();
const { getPool } = require('../../config/db');
const requireAdminAuth = require('../../middleware/adminAuth');
const { requireDeleter } = require('../../middleware/rolePermissions');

const logAdminActivity = async (client, adminId, action, targetType, targetId, details, ip) => {
  try {
    await client.query(
      `INSERT INTO admin_activity_log (admin_id, action, target_type, target_id, details, ip_address) 
       VALUES ($1, $2, $3, $4, $5, $6)`,
      [adminId, action, targetType, targetId, details, ip]
    );
  } catch (error) {
    console.error('[logAdminActivity] Error:', error);
  }
};

router.delete('/:id', requireDeleter, async (req, res) => {
  const pool = getPool();
  const client = await pool.connect();
  
  try {
    await client.query('BEGIN');
    
    const { id } = req.params;
    const adminId = req.adminId;

    console.log(`[DELETE NUCLEAR] Starting delete for news_id: ${id}`);

    if (!id || !/^\d+$/.test(id)) {
      await client.query('ROLLBACK');
      return res.status(400).json({
        success: false,
        message: 'Valid news ID is required'
      });
    }

    // Check if article exists
    const checkQuery = 'SELECT news_id, title, author_id, status FROM news WHERE news_id = $1';
    const checkResult = await client.query(checkQuery, [id]);

    if (checkResult.rows.length === 0) {
      await client.query('ROLLBACK');
      return res.status(404).json({
        success: false,
        message: 'News article not found'
      });
    }

    const article = checkResult.rows[0];
    console.log(`[DELETE NUCLEAR] Found article: "${article.title}"`);

    // NUCLEAR OPTION: Delete everything in one CASCADE query
    // This works because PostgreSQL will follow foreign key cascades
    const deleteResult = await client.query('DELETE FROM news WHERE news_id = $1', [id]);
    
    console.log(`[DELETE NUCLEAR] Deleted ${deleteResult.rowCount} news record(s)`);

    if (deleteResult.rowCount === 0) {
      await client.query('ROLLBACK');
      return res.status(500).json({
        success: false,
        message: 'Failed to delete news article - no rows affected'
      });
    }

    // Log the activity
    const ip = req.headers['x-forwarded-for'] || req.headers['x-real-ip'] || req.ip || 'unknown';
    
    await logAdminActivity(
      client,
      adminId,
      'delete_news',
      'news',
      id,
      `Permanently deleted article: ${article.title}`,
      ip
    );

    // COMMIT the transaction
    await client.query('COMMIT');
    console.log(`[DELETE NUCLEAR] Successfully committed deletion of news_id: ${id}`);

    return res.status(200).json({
      success: true,
      message: 'Article permanently deleted',
      action: 'delete',
      news_id: id,
      title: article.title
    });

  } catch (error) {
    console.error('[DELETE NUCLEAR] Error:', error.message);
    console.error('[DELETE NUCLEAR] Error Code:', error.code);
    console.error('[DELETE NUCLEAR] Stack:', error.stack);
    
    try {
      await client.query('ROLLBACK');
      console.log('[DELETE NUCLEAR] Transaction rolled back');
    } catch (rollbackError) {
      console.error('[DELETE NUCLEAR] Rollback failed:', rollbackError);
    }
    
    return res.status(500).json({
      success: false,
      message: 'Internal server error',
      error: error.message,
      code: error.code,
      detail: error.detail || 'No additional details'
    });
  } finally {
    client.release();
  }
});

router.post('/bulk', requireDeleter, async (req, res) => {
  const pool = getPool();
  const client = await pool.connect();
  
  try {
    await client.query('BEGIN');
    
    const { news_ids } = req.body;
    const adminId = req.adminId;

    if (!news_ids || !Array.isArray(news_ids) || news_ids.length === 0) {
      await client.query('ROLLBACK');
      return res.status(400).json({
        success: false,
        message: 'Valid news IDs array is required'
      });
    }

    console.log(`[DELETE BULK NUCLEAR] Deleting ${news_ids.length} articles`);

    const results = {
      success: [],
      failed: []
    };

    for (const newsId of news_ids) {
      try {
        const checkResult = await client.query(
          'SELECT news_id, title FROM news WHERE news_id = $1',
          [newsId]
        );

        if (checkResult.rows.length === 0) {
          results.failed.push({ id: newsId, reason: 'Not found' });
          continue;
        }

        const article = checkResult.rows[0];

        // NUCLEAR DELETE - cascades will handle related tables
        const deleteResult = await client.query('DELETE FROM news WHERE news_id = $1', [newsId]);
        
        if (deleteResult.rowCount > 0) {
          results.success.push({ 
            id: newsId, 
            title: article.title
          });
          console.log(`[DELETE BULK NUCLEAR] Deleted: ${article.title}`);
        } else {
          results.failed.push({ id: newsId, reason: 'Delete failed - no rows affected' });
        }

      } catch (itemError) {
        console.error(`[DELETE BULK NUCLEAR] Error processing news ${newsId}:`, itemError);
        results.failed.push({ id: newsId, reason: itemError.message });
      }
    }

    const ip = req.headers['x-forwarded-for'] || req.headers['x-real-ip'] || req.ip || 'unknown';
    
    await logAdminActivity(
      client,
      adminId,
      'bulk_delete',
      'news',
      null,
      `Bulk deleted ${results.success.length} articles`,
      ip
    );

    await client.query('COMMIT');
    console.log(`[DELETE BULK NUCLEAR] Successfully committed bulk deletion`);

    return res.status(200).json({
      success: true,
      message: `Bulk operation completed: ${results.success.length} succeeded, ${results.failed.length} failed`,
      results
    });

  } catch (error) {
    await client.query('ROLLBACK');
    console.error('[DELETE BULK NUCLEAR] Error:', error);
    return res.status(500).json({
      success: false,
      message: 'Internal server error',
      error: error.message
    });
  } finally {
    client.release();
  }
});

module.exports = router;
