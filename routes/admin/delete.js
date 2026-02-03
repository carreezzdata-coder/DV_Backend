const express = require('express');
const router = express.Router();
const { getPool } = require('../../config/db');
const { FRONTEND_URL, CLIENT_URL, ADMIN_URL, API_DOMAIN, ALLOWED_ORIGINS } = require('../../config/frontendconfig');
const requireAdminAuth = require('../../middleware/adminAuth');
const { requireDeleter } = require('../../middleware/rolePermissions');
const cloudflareService = require('../../services/cloudflareService');

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

const deleteCloudflareImages = async (newsId, client) => {
  try {
    const imagesResult = await client.query(
      'SELECT image_url FROM news_images WHERE news_id = $1',
      [newsId]
    );

    const mainImageResult = await client.query(
      'SELECT image_url FROM news WHERE news_id = $1',
      [newsId]
    );

    const imageUrls = [];
    
    if (mainImageResult.rows.length > 0 && mainImageResult.rows[0].image_url) {
      imageUrls.push(mainImageResult.rows[0].image_url);
    }

    imagesResult.rows.forEach(row => {
      if (row.image_url) {
        imageUrls.push(row.image_url);
      }
    });

    for (const imageUrl of imageUrls) {
      try {
        await cloudflareService.deleteImage(imageUrl);
        console.log(`Deleted Cloudflare image: ${imageUrl}`);
      } catch (error) {
        console.error(`Failed to delete Cloudflare image ${imageUrl}:`, error);
      }
    }

    return imageUrls.length;
  } catch (error) {
    console.error('[deleteCloudflareImages] Error:', error);
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
    const userRole = req.userRole;

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

    const deletedImagesCount = await deleteCloudflareImages(id, client);

    await client.query('DELETE FROM news_categories WHERE news_id = $1', [id]);
    await client.query('DELETE FROM news_images WHERE news_id = $1', [id]);
    await client.query('DELETE FROM news_social_media WHERE news_id = $1', [id]);
    await client.query('DELETE FROM news_comments WHERE news_id = $1', [id]);
    await client.query('DELETE FROM likes WHERE news_id = $1', [id]);
    await client.query('DELETE FROM post_promotions WHERE news_id = $1', [id]);
    await client.query('DELETE FROM featured_news WHERE news_id = $1', [id]);
    
    await client.query('DELETE FROM news WHERE news_id = $1', [id]);

    const ip = req.headers['x-forwarded-for'] || req.headers['x-real-ip'] || req.ip || 'unknown';
    
    await logAdminActivity(
      client,
      adminId,
      'delete_news',
      'news',
      id,
      `Permanently deleted article: ${article.title} (${deletedImagesCount} images removed from Cloudflare)`,
      ip
    );

    await client.query('COMMIT');

    return res.status(200).json({
      success: true,
      message: 'Article permanently deleted',
      action: 'delete',
      deleted_images: deletedImagesCount
    });

  } catch (error) {
    console.error('[Delete] Error:', error.message);
    console.error('[Delete] Stack:', error.stack);
    
    try {
      await client.query('ROLLBACK');
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

    let totalDeletedImages = 0;

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

        const deletedImagesCount = await deleteCloudflareImages(newsId, client);
        totalDeletedImages += deletedImagesCount;

        await client.query('DELETE FROM news_categories WHERE news_id = $1', [newsId]);
        await client.query('DELETE FROM news_images WHERE news_id = $1', [newsId]);
        await client.query('DELETE FROM news_social_media WHERE news_id = $1', [newsId]);
        await client.query('DELETE FROM news_comments WHERE news_id = $1', [newsId]);
        await client.query('DELETE FROM likes WHERE news_id = $1', [newsId]);
        await client.query('DELETE FROM post_promotions WHERE news_id = $1', [newsId]);
        await client.query('DELETE FROM featured_news WHERE news_id = $1', [newsId]);
        await client.query('DELETE FROM news WHERE news_id = $1', [newsId]);

        results.success.push({ 
          id: newsId, 
          title: article.title,
          deleted_images: deletedImagesCount 
        });

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
      `Bulk deleted ${results.success.length} articles (${totalDeletedImages} images removed from Cloudflare)`,
      ip
    );

    await client.query('COMMIT');

    return res.status(200).json({
      success: true,
      message: `Bulk operation completed: ${results.success.length} succeeded, ${results.failed.length} failed`,
      results,
      total_deleted_images: totalDeletedImages
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
