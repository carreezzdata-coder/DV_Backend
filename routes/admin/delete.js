const express = require('express');
const router = express.Router();
const { getPool } = require('../../config/db');
const { FRONTEND_URL, CLIENT_URL, ADMIN_URL, API_DOMAIN, ALLOWED_ORIGINS } = require('../../config/frontendconfig');
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
    const { hard_delete = false } = req.body;
    const adminId = req.adminId;
    const userRole = req.userRole;

    console.log('═══════════════════════════════════════');
    console.log('🔥 DELETE REQUEST');
    console.log('News ID:', id);
    console.log('Admin ID:', adminId);
    console.log('User Role:', userRole);
    console.log('Hard Delete:', hard_delete);
    console.log('═══════════════════════════════════════');

    if (!id || !/^\d+$/.test(id)) {
      console.error('❌ Invalid news ID:', id);
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
    const isOwnArticle = article.author_id === adminId;

    console.log('📄 Article:', {
      id: article.news_id,
      title: article.title,
      author: article.author_id,
      isOwn: isOwnArticle,
      status: article.status
    });

    if (hard_delete) {
      console.log('🗑️ Performing HARD DELETE...');

      await client.query('DELETE FROM news_categories WHERE news_id = $1', [id]);
      await client.query('DELETE FROM news_images WHERE news_id = $1', [id]);
      await client.query('DELETE FROM news_social_media WHERE news_id = $1', [id]);
      await client.query('DELETE FROM news_comments WHERE news_id = $1', [id]);
      await client.query('DELETE FROM likes WHERE news_id = $1', [id]);
      await client.query('DELETE FROM post_promotions WHERE news_id = $1', [id]);
      
      await client.query('DELETE FROM news WHERE news_id = $1', [id]);

      const ip = req.headers['x-forwarded-for'] || req.headers['x-real-ip'] || req.ip || 'unknown';
      
      await logAdminActivity(
        client,
        adminId,
        'hard_delete_news',
        'news',
        id,
        `Permanently deleted article: ${article.title}`,
        ip
      );

      await client.query('COMMIT');

      console.log('✅ Article permanently deleted');

      return res.status(200).json({
        success: true,
        message: 'Article permanently deleted',
        action: 'hard_delete'
      });

    } else {
      console.log('📦 Performing ARCHIVE (soft delete)...');

      const updateQuery = `
        UPDATE news 
        SET 
          status = 'archived',
          workflow_status = 'archived',
          updated_at = CURRENT_TIMESTAMP
        WHERE news_id = $1
        RETURNING news_id, title
      `;

      const updateResult = await client.query(updateQuery, [id]);

      const ip = req.headers['x-forwarded-for'] || req.headers['x-real-ip'] || req.ip || 'unknown';
      
      await logAdminActivity(
        client,
        adminId,
        'archive_news',
        'news',
        id,
        `Archived article: ${article.title}`,
        ip
      );

      await client.query('COMMIT');

      console.log('✅ Article archived successfully');

      return res.status(200).json({
        success: true,
        message: 'Article archived successfully',
        action: 'archive',
        article: updateResult.rows[0]
      });
    }

  } catch (error) {
    console.error('❌ [Delete] Error:', error.message);
    console.error('❌ [Delete] Stack:', error.stack);
    
    try {
      await client.query('ROLLBACK');
    } catch (rollbackError) {
      console.error('❌ [Delete] Rollback failed:', rollbackError);
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
    
    const { news_ids, hard_delete = false } = req.body;
    const adminId = req.adminId;
    const userRole = req.userRole;

    console.log('═══════════════════════════════════════');
    console.log('🔥 BULK DELETE REQUEST');
    console.log('News IDs:', news_ids);
    console.log('Admin ID:', adminId);
    console.log('User Role:', userRole);
    console.log('Hard Delete:', hard_delete);
    console.log('═══════════════════════════════════════');

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

        if (hard_delete) {
          await client.query('DELETE FROM news_categories WHERE news_id = $1', [newsId]);
          await client.query('DELETE FROM news_images WHERE news_id = $1', [newsId]);
          await client.query('DELETE FROM news_social_media WHERE news_id = $1', [newsId]);
          await client.query('DELETE FROM news_comments WHERE news_id = $1', [newsId]);
          await client.query('DELETE FROM likes WHERE news_id = $1', [newsId]);
          await client.query('DELETE FROM post_promotions WHERE news_id = $1', [newsId]);
          await client.query('DELETE FROM news WHERE news_id = $1', [newsId]);
        } else {
          await client.query(
            `UPDATE news SET status = 'archived', workflow_status = 'archived', updated_at = CURRENT_TIMESTAMP WHERE news_id = $1`,
            [newsId]
          );
        }

        results.success.push({ id: newsId, title: article.title });

      } catch (itemError) {
        console.error(`❌ Error processing news ${newsId}:`, itemError);
        results.failed.push({ id: newsId, reason: itemError.message });
      }
    }

    const ip = req.headers['x-forwarded-for'] || req.headers['x-real-ip'] || req.ip || 'unknown';
    
    await logAdminActivity(
      client,
      adminId,
      hard_delete ? 'bulk_hard_delete' : 'bulk_archive',
      'news',
      null,
      `Bulk ${hard_delete ? 'deleted' : 'archived'} ${results.success.length} articles`,
      ip
    );

    await client.query('COMMIT');

    console.log('✅ Bulk operation completed');
    console.log('Success:', results.success.length);
    console.log('Failed:', results.failed.length);

    return res.status(200).json({
      success: true,
      message: `Bulk operation completed: ${results.success.length} succeeded, ${results.failed.length} failed`,
      results
    });

  } catch (error) {
    await client.query('ROLLBACK');
    console.error('❌ [Bulk Delete] Error:', error);
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