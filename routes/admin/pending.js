const express = require('express');
const router = express.Router();
const { getPool } = require('../../config/db');
const requireAdminAuth = require('../../middleware/adminAuth');
const { requireApprover, requireDeleter } = require('../../middleware/rolePermissions');

const { FRONTEND_URL, CLIENT_URL, ADMIN_URL, API_DOMAIN, ALLOWED_ORIGINS, isOriginAllowed } = require('../../config/frontendconfig');

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
    const { 
      workflow_status = 'pending_approval',
      search = '', 
      author_id = '',
      category_ids = '',
      priority = ''
    } = req.query;

    const queryParams = [];
    let paramIndex = 1;
    let whereConditions = ['na.workflow_status = $1'];
    queryParams.push(workflow_status);
    paramIndex++;

    if (search) {
      queryParams.push(`%${search}%`);
      whereConditions.push(`(n.title ILIKE $${paramIndex} OR n.content ILIKE $${paramIndex})`);
      paramIndex++;
    }

    if (author_id) {
      queryParams.push(parseInt(author_id));
      whereConditions.push(`n.author_id = $${paramIndex}`);
      paramIndex++;
    }

    if (category_ids) {
      const categoryArray = category_ids.split(',').map(id => parseInt(id)).filter(id => !isNaN(id));
      if (categoryArray.length > 0) {
        queryParams.push(categoryArray);
        whereConditions.push(`(n.category_id = ANY($${paramIndex}) OR n.primary_category_id = ANY($${paramIndex}))`);
        paramIndex++;
      }
    }

    if (priority) {
      queryParams.push(priority);
      whereConditions.push(`n.priority = $${paramIndex}`);
      paramIndex++;
    }

    const whereClause = `WHERE ${whereConditions.join(' AND ')}`;

    const query = `
      SELECT 
        n.news_id, n.title, n.excerpt, n.content, n.slug, n.image_url, n.status,
        n.views, n.likes_count, n.comments_count, n.share_count, n.published_at,
        n.created_at, n.updated_at, n.author_id, n.category_id, n.primary_category_id,
        n.tags, n.priority, n.reading_time,
        na.workflow_status, na.submitted_at, na.rejection_reason,
        a.first_name, a.last_name, a.email as author_email, a.role as author_role,
        c.name as category_name, c.slug as category_slug,
        pc.name as primary_category_name,
        ARRAY_AGG(DISTINCT nc.category_id) FILTER (WHERE nc.category_id IS NOT NULL) as category_ids,
        LENGTH(n.content) - LENGTH(REPLACE(n.content, ' ', '')) + 1 as word_count
      FROM news_approval na
      JOIN news n ON na.news_id = n.news_id
      LEFT JOIN admins a ON n.author_id = a.admin_id
      LEFT JOIN categories c ON n.category_id = c.category_id
      LEFT JOIN categories pc ON n.primary_category_id = pc.category_id
      LEFT JOIN news_categories nc ON n.news_id = nc.news_id
      ${whereClause}
      GROUP BY 
        n.news_id, na.approval_record_id, na.workflow_status, na.submitted_at, na.rejection_reason,
        a.admin_id, a.first_name, a.last_name, a.email, a.role,
        c.category_id, c.name, c.slug, pc.category_id, pc.name
      ORDER BY 
        CASE n.priority 
          WHEN 'high' THEN 1 
          WHEN 'medium' THEN 2 
          WHEN 'low' THEN 3 
          ELSE 4 
        END,
        na.submitted_at DESC NULLS LAST,
        n.created_at DESC
    `;

    const result = await pool.query(query, queryParams);

    const posts = result.rows.map(item => ({
      ...item,
      image_url: getImageUrl(item.image_url)
    }));

    return res.status(200).json({
      success: true,
      posts
    });

  } catch (error) {
    console.error('[Pending GET] Error:', error);
    return res.status(500).json({
      success: false,
      message: 'Failed to fetch pending posts',
      error: error.message
    });
  }
});

router.get('/writer-stats/:authorId', requireAdminAuth, async (req, res) => {
  try {
    const pool = getPool();
    const { authorId } = req.params;

    if (!authorId || isNaN(Number(authorId))) {
      return res.status(400).json({
        success: false,
        message: 'Valid author ID is required'
      });
    }

    const statsQuery = `
      SELECT 
        COUNT(DISTINCT n.news_id) as total_submissions,
        COUNT(DISTINCT n.news_id) FILTER (WHERE na.workflow_status = 'approved') as approved_count,
        COUNT(DISTINCT n.news_id) FILTER (WHERE na.workflow_status = 'rejected') as rejected_count,
        COUNT(DISTINCT n.news_id) FILTER (WHERE na.workflow_status IN ('pending_review', 'pending_approval')) as pending_count,
        ROUND(
          (COUNT(DISTINCT n.news_id) FILTER (WHERE na.workflow_status = 'approved')::numeric / 
          NULLIF(COUNT(DISTINCT n.news_id) FILTER (WHERE na.workflow_status IN ('approved', 'rejected')), 0)) * 100, 
          1
        ) as approval_rate,
        ROUND(
          AVG(
            EXTRACT(EPOCH FROM (na.approved_at - na.submitted_at)) / 3600
          ) FILTER (WHERE na.approved_at IS NOT NULL AND na.submitted_at IS NOT NULL),
          1
        ) as avg_review_time,
        COALESCE(SUM(n.views), 0) as total_views,
        COALESCE(SUM(n.likes_count + n.comments_count + n.share_count), 0) as total_engagement
      FROM news n
      LEFT JOIN news_approval na ON n.news_id = na.news_id
      WHERE n.author_id = $1
    `;

    const result = await pool.query(statsQuery, [authorId]);

    const stats = {
      total_submissions: parseInt(result.rows[0].total_submissions) || 0,
      approved_count: parseInt(result.rows[0].approved_count) || 0,
      rejected_count: parseInt(result.rows[0].rejected_count) || 0,
      pending_count: parseInt(result.rows[0].pending_count) || 0,
      approval_rate: parseFloat(result.rows[0].approval_rate) || 0,
      avg_review_time: parseFloat(result.rows[0].avg_review_time) || 0,
      total_views: parseInt(result.rows[0].total_views) || 0,
      total_engagement: parseInt(result.rows[0].total_engagement) || 0
    };

    return res.status(200).json({
      success: true,
      stats
    });

  } catch (error) {
    console.error('[Pending Stats] Error:', error);
    return res.status(500).json({
      success: false,
      message: 'Failed to fetch writer stats',
      error: error.message
    });
  }
});

router.post('/:id/review', requireAdminAuth, requireApprover, async (req, res) => {
  const pool = getPool();
  const client = await pool.connect();

  try {
    await client.query('BEGIN');

    const { id } = req.params;
    const { action, comments, instructions } = req.body;
    const reviewer_id = req.adminId;

    if (!id || isNaN(Number(id))) {
      await client.query('ROLLBACK');
      return res.status(400).json({
        success: false,
        message: 'Valid news ID is required'
      });
    }

    if (!action || !['approve', 'reject', 'request_changes'].includes(action)) {
      await client.query('ROLLBACK');
      return res.status(400).json({
        success: false,
        message: 'Valid action required'
      });
    }

    const checkQuery = 'SELECT news_id FROM news WHERE news_id = $1';
    const checkResult = await client.query(checkQuery, [id]);

    if (checkResult.rows.length === 0) {
      await client.query('ROLLBACK');
      return res.status(404).json({
        success: false,
        message: 'News article not found'
      });
    }

    const approvalCheck = await client.query(
      'SELECT workflow_status FROM news_approval WHERE news_id = $1',
      [id]
    );

    const previousStatus = approvalCheck.rows.length > 0 ? approvalCheck.rows[0].workflow_status : 'pending_approval';
    let newStatus, newsStatus, successMessage;

    if (action === 'approve') {
      newStatus = 'approved';
      newsStatus = 'published';
      successMessage = 'Article approved and published successfully';

      if (approvalCheck.rows.length > 0) {
        await client.query(`
          UPDATE news_approval 
          SET workflow_status = $1, approved_by = $2, approved_at = CURRENT_TIMESTAMP, updated_at = CURRENT_TIMESTAMP
          WHERE news_id = $3
        `, [newStatus, reviewer_id, id]);
      } else {
        await client.query(`
          INSERT INTO news_approval (news_id, workflow_status, requires_approval, approved_by, approved_at, submitted_at, submitted_by)
          VALUES ($1, $2, false, $3, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, $3)
          ON CONFLICT (news_id) DO UPDATE SET
            workflow_status = EXCLUDED.workflow_status,
            requires_approval = EXCLUDED.requires_approval,
            approved_by = EXCLUDED.approved_by,
            approved_at = EXCLUDED.approved_at,
            submitted_at = EXCLUDED.submitted_at,
            submitted_by = EXCLUDED.submitted_by,
            updated_at = CURRENT_TIMESTAMP
        `, [id, newStatus, reviewer_id]);
      }

      await client.query(`
        UPDATE news 
        SET status = $1, published_at = COALESCE(published_at, CURRENT_TIMESTAMP), updated_at = CURRENT_TIMESTAMP
        WHERE news_id = $2
      `, [newsStatus, id]);

    } else if (action === 'request_changes') {
      newStatus = 'pending_review';
      newsStatus = 'draft';
      successMessage = 'Changes requested';

      if (approvalCheck.rows.length > 0) {
        await client.query(`
          UPDATE news_approval 
          SET workflow_status = $1, rejection_reason = $2, rejected_by = $3, rejected_at = CURRENT_TIMESTAMP, updated_at = CURRENT_TIMESTAMP
          WHERE news_id = $4
        `, [newStatus, instructions || comments || 'Changes requested', reviewer_id, id]);
      } else {
        await client.query(`
          INSERT INTO news_approval (news_id, workflow_status, requires_approval, rejection_reason, rejected_by, rejected_at, submitted_at, submitted_by)
          VALUES ($1, $2, true, $3, $4, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, $4)
          ON CONFLICT (news_id) DO UPDATE SET
            workflow_status = EXCLUDED.workflow_status,
            requires_approval = EXCLUDED.requires_approval,
            rejection_reason = EXCLUDED.rejection_reason,
            rejected_by = EXCLUDED.rejected_by,
            rejected_at = EXCLUDED.rejected_at,
            submitted_at = EXCLUDED.submitted_at,
            submitted_by = EXCLUDED.submitted_by,
            updated_at = CURRENT_TIMESTAMP
        `, [id, newStatus, instructions || comments || 'Changes requested', reviewer_id]);
      }

      await client.query(`
        UPDATE news SET status = $1, updated_at = CURRENT_TIMESTAMP WHERE news_id = $2
      `, [newsStatus, id]);

    } else {
      newStatus = 'rejected';
      newsStatus = 'draft';
      successMessage = 'Article rejected';

      if (approvalCheck.rows.length > 0) {
        await client.query(`
          UPDATE news_approval 
          SET workflow_status = $1, rejection_reason = $2, rejected_by = $3, rejected_at = CURRENT_TIMESTAMP, updated_at = CURRENT_TIMESTAMP
          WHERE news_id = $4
        `, [newStatus, comments || 'Article rejected', reviewer_id, id]);
      } else {
        await client.query(`
          INSERT INTO news_approval (news_id, workflow_status, requires_approval, rejection_reason, rejected_by, rejected_at, submitted_at, submitted_by)
          VALUES ($1, $2, true, $3, $4, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, $4)
          ON CONFLICT (news_id) DO UPDATE SET
            workflow_status = EXCLUDED.workflow_status,
            requires_approval = EXCLUDED.requires_approval,
            rejection_reason = EXCLUDED.rejection_reason,
            rejected_by = EXCLUDED.rejected_by,
            rejected_at = EXCLUDED.rejected_at,
            submitted_at = EXCLUDED.submitted_at,
            submitted_by = EXCLUDED.submitted_by,
            updated_at = CURRENT_TIMESTAMP
        `, [id, newStatus, comments || 'Article rejected', reviewer_id]);
      }

      await client.query(`
        UPDATE news SET status = $1, updated_at = CURRENT_TIMESTAMP WHERE news_id = $2
      `, [newsStatus, id]);
    }

    await client.query(`
      INSERT INTO news_approval_history (news_id, reviewer_id, action, comments, previous_status, new_status)
      VALUES ($1, $2, $3, $4, $5, $6)
    `, [id, reviewer_id, action, comments || instructions || '', previousStatus, newStatus]);

    await client.query('COMMIT');

    return res.status(200).json({
      success: true,
      message: successMessage
    });

  } catch (error) {
    await client.query('ROLLBACK');
    console.error('[Pending Review] Error:', error);
    return res.status(500).json({
      success: false,
      message: 'Failed to process review',
      error: error.message
    });
  } finally {
    client.release();
  }
});

router.delete('/:id', requireAdminAuth, requireDeleter, async (req, res) => {
  const pool = getPool();
  const client = await pool.connect();

  try {
    await client.query('BEGIN');

    const { id } = req.params;
    const { hard_delete = false } = req.body;

    if (!id || isNaN(Number(id))) {
      await client.query('ROLLBACK');
      return res.status(400).json({
        success: false,
        message: 'Valid news ID is required'
      });
    }

    const checkQuery = 'SELECT news_id FROM news WHERE news_id = $1';
    const checkResult = await client.query(checkQuery, [id]);

    if (checkResult.rows.length === 0) {
      await client.query('ROLLBACK');
      return res.status(404).json({
        success: false,
        message: 'News article not found'
      });
    }

    if (hard_delete) {
      await client.query('DELETE FROM news_categories WHERE news_id = $1', [id]);
      await client.query('DELETE FROM news_social_media WHERE news_id = $1', [id]);
      await client.query('DELETE FROM news_images WHERE news_id = $1', [id]);
      await client.query('DELETE FROM news_approval_history WHERE news_id = $1', [id]);
      await client.query('DELETE FROM news_approval WHERE news_id = $1', [id]);
      await client.query('DELETE FROM news WHERE news_id = $1', [id]);

      await client.query('COMMIT');

      return res.status(200).json({
        success: true,
        message: 'Article permanently deleted'
      });
    } else {
      await client.query(`
        UPDATE news SET status = 'archived', updated_at = CURRENT_TIMESTAMP WHERE news_id = $1
      `, [id]);

      await client.query('COMMIT');

      return res.status(200).json({
        success: true,
        message: 'Article archived successfully'
      });
    }

  } catch (error) {
    await client.query('ROLLBACK');
    console.error('[Pending Delete] Error:', error);
    return res.status(500).json({
      success: false,
      message: 'Failed to delete post',
      error: error.message
    });
  } finally {
    client.release();
  }
});

module.exports = router;