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

// Safe delete helper - doesn't fail if table doesn't exist or no rows found
const safeDelete = async (client, tableName, newsId) => {
  try {
    const result = await client.query(`DELETE FROM ${tableName} WHERE news_id = $1`, [newsId]);
    console.log(`[Delete] Deleted ${result.rowCount} rows from ${tableName}`);
    return result.rowCount;
  } catch (error) {
    // If table doesn't exist or other error, log but continue
    console.warn(`[Delete] Warning deleting from ${tableName}:`, error.message);
    return 0;
  }
};

router.delete('/:id', requireDeleter, async (req, res) => {
  const pool = getPool();
  const client = await pool.connect();
  
  try {
    await client.query('BEGIN');
    
    const { id } = req.params;
    const adminId = req.adminId;

    console.log(`[Delete] Starting delete for news_id: ${id}`);

    if (!id || !/^\d+$/.test(id)) {
      await client.query('ROLLBACK');
      return res.status(400).json({
        success: false,
        message: 'Valid news ID is required'
      });
    }

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
    console.log(`[Delete] Found article: "${article.title}"`);

    // Delete from all related tables - using safe delete to avoid errors
    let totalDeleted = 0;
    
    totalDeleted += await safeDelete(client, 'breaking_news', id);
    totalDeleted += await safeDelete(client, 'featured_news', id);
    totalDeleted += await safeDelete(client, 'pinned_news', id);
    totalDeleted += await safeDelete(client, 'news_categories', id);
    totalDeleted += await safeDelete(client, 'news_images', id);
    totalDeleted += await safeDelete(client, 'news_social_media', id);
    totalDeleted += await safeDelete(client, 'news_videos', id);
    totalDeleted += await safeDelete(client, 'news_content_blocks', id);
    totalDeleted += await safeDelete(client, 'news_comments', id);
    totalDeleted += await safeDelete(client, 'news_reactions', id);
    totalDeleted += await safeDelete(client, 'news_shares', id);
    totalDeleted += await safeDelete(client, 'user_saved_articles', id);
    totalDeleted += await safeDelete(client, 'page_views', id);
    totalDeleted += await safeDelete(client, 'news_approval_history', id);
    totalDeleted += await safeDelete(client, 'news_approval', id);
    
    console.log(`[Delete] Deleted ${totalDeleted} related records`);
    
    // Delete the main news record
    const newsDeleteResult = await client.query('DELETE FROM news WHERE news_id = $1', [id]);
    console.log(`[Delete] Deleted ${newsDeleteResult.rowCount} news record(s)`);

    if (newsDeleteResult.rowCount === 0) {
      await client.query('ROLLBACK');
      return res.status(500).json({
        success: false,
        message: 'Failed to delete news article'
      });
    }

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

    await client.query('COMMIT');
    console.log(`[Delete] Successfully committed deletion of news_id: ${id}`);

    return res.status(200).json({
      success: true,
      message: 'Article permanently deleted',
      action: 'delete',
      deleted_records: totalDeleted + newsDeleteResult.rowCount
    });

  } catch (error) {
    console.error('[Delete] Error:', error.message);
    console.error('[Delete] Stack:', error.stack);
    
    try {
      await client.query('ROLLBACK');
      console.log('[Delete] Transaction rolled back');
    } catch (rollbackError) {
      console.error('[Delete] Rollback failed:', rollbackError);
    }
    
    return res.status(500).json({
      success: false,
      message: 'Internal server error',
      error: error.message,
      code: error.code
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

        // Delete from all related tables
        await safeDelete(client, 'breaking_news', newsId);
        await safeDelete(client, 'featured_news', newsId);
        await safeDelete(client, 'pinned_news', newsId);
        await safeDelete(client, 'news_categories', newsId);
        await safeDelete(client, 'news_images', newsId);
        await safeDelete(client, 'news_social_media', newsId);
        await safeDelete(client, 'news_videos', newsId);
        await safeDelete(client, 'news_content_blocks', newsId);
        await safeDelete(client, 'news_comments', newsId);
        await safeDelete(client, 'news_reactions', newsId);
        await safeDelete(client, 'news_shares', newsId);
        await safeDelete(client, 'user_saved_articles', newsId);
        await safeDelete(client, 'page_views', newsId);
        await safeDelete(client, 'news_approval_history', newsId);
        await safeDelete(client, 'news_approval', newsId);
        
        const newsDeleteResult = await client.query('DELETE FROM news WHERE news_id = $1', [newsId]);
        
        if (newsDeleteResult.rowCount > 0) {
          results.success.push({ 
            id: newsId, 
            title: article.title
          });
        } else {
          results.failed.push({ id: newsId, reason: 'Delete failed' });
        }

      } catch (itemError) {
        console.error(`Error processing news ${newsId}:`, itemError);
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

    return res.status(200).json({
      success: true,
      message: `Bulk operation completed: ${results.success.length} succeeded, ${results.failed.length} failed`,
      results
    });

  } catch (error) {
    await client.query('ROLLBACK');
    console.error('[Bulk Delete] Error:', error);
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
