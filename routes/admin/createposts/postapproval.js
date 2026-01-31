const express = require('express');
const router = express.Router();
const requireAdminAuth = require('../../middleware/adminAuth');
const { requireApprover } = require('../../middleware/rolePermissions');
const { getPool } = require('../../config/db');

const { FRONTEND_URL, CLIENT_URL, ADMIN_URL, API_DOMAIN, ALLOWED_ORIGINS, isOriginAllowed } = require('../../../config/frontendconfig');

router.get('/pending', requireAdminAuth, requireApprover, async (req, res) => {
  try {
    const pool = getPool();
    const result = await pool.query(`
      SELECT 
        n.*,
        na.approval_record_id,
        na.workflow_status,
        na.requires_approval,
        na.submitted_at,
        na.submitted_by,
        na.approved_by,
        na.approved_at,
        na.rejected_by,
        na.rejected_at,
        na.rejection_reason,
        a.first_name as author_first_name,
        a.last_name as author_last_name,
        a.email as author_email,
        c.name as category_name,
        c.slug as category_slug,
        c.color as category_color,
        submitter.first_name as submitter_first_name,
        submitter.last_name as submitter_last_name
      FROM news_approval na
      JOIN news n ON na.news_id = n.news_id
      JOIN admins a ON n.author_id = a.admin_id
      LEFT JOIN categories c ON n.primary_category_id = c.category_id
      LEFT JOIN admins submitter ON na.submitted_by = submitter.admin_id
      WHERE na.workflow_status = 'pending_approval'
      ORDER BY na.submitted_at DESC
    `);

    return res.status(200).json({
      success: true,
      approvals: result.rows,
      count: result.rows.length
    });
  } catch (error) {
    console.error('[Approval Pending] Error:', error);
    return res.status(500).json({
      success: false,
      message: 'Failed to fetch pending approvals',
      error: error.message
    });
  }
});

router.get('/all', requireAdminAuth, requireApprover, async (req, res) => {
  try {
    const { status, limit = 50, offset = 0 } = req.query;
    const pool = getPool();
    
    let whereClause = '';
    const queryParams = [];
    
    if (status && ['pending_approval', 'approved', 'rejected'].includes(status)) {
      whereClause = 'WHERE na.workflow_status = $1';
      queryParams.push(status);
    }

    const result = await pool.query(`
      SELECT 
        n.*,
        na.*,
        a.first_name as author_first_name,
        a.last_name as author_last_name,
        c.name as category_name,
        approver.first_name as approver_first_name,
        approver.last_name as approver_last_name,
        rejecter.first_name as rejecter_first_name,
        rejecter.last_name as rejecter_last_name
      FROM news_approval na
      JOIN news n ON na.news_id = n.news_id
      JOIN admins a ON n.author_id = a.admin_id
      LEFT JOIN categories c ON n.primary_category_id = c.category_id
      LEFT JOIN admins approver ON na.approved_by = approver.admin_id
      LEFT JOIN admins rejecter ON na.rejected_by = rejecter.admin_id
      ${whereClause}
      ORDER BY na.submitted_at DESC
      LIMIT $${queryParams.length + 1} OFFSET $${queryParams.length + 2}
    `, [...queryParams, limit, offset]);

    return res.status(200).json({
      success: true,
      approvals: result.rows,
      count: result.rows.length,
      limit: parseInt(limit),
      offset: parseInt(offset)
    });
  } catch (error) {
    console.error('[Approval All] Error:', error);
    return res.status(500).json({
      success: false,
      message: 'Failed to fetch approvals',
      error: error.message
    });
  }
});

router.post('/submit/:newsId', requireAdminAuth, async (req, res) => {
  const pool = getPool();
  const client = await pool.connect();

  try {
    await client.query('BEGIN');

    const { newsId } = req.params;
    const adminId = req.adminId;

    const newsCheck = await client.query(
      'SELECT news_id, author_id, status, title FROM news WHERE news_id = $1',
      [newsId]
    );

    if (newsCheck.rows.length === 0) {
      await client.query('ROLLBACK');
      return res.status(404).json({
        success: false,
        message: 'News article not found'
      });
    }

    const news = newsCheck.rows[0];

    const existingApproval = await client.query(
      'SELECT approval_record_id, workflow_status FROM news_approval WHERE news_id = $1',
      [newsId]
    );

    if (existingApproval.rows.length > 0) {
      await client.query(`
        UPDATE news_approval 
        SET 
          workflow_status = 'pending_approval',
          requires_approval = true,
          submitted_at = CURRENT_TIMESTAMP,
          submitted_by = $1,
          approved_by = NULL,
          approved_at = NULL,
          rejected_by = NULL,
          rejected_at = NULL,
          rejection_reason = NULL,
          updated_at = CURRENT_TIMESTAMP
        WHERE news_id = $2
      `, [adminId, newsId]);
    } else {
      await client.query(`
        INSERT INTO news_approval (
          news_id,
          workflow_status,
          requires_approval,
          submitted_at,
          submitted_by
        ) VALUES ($1, 'pending_approval', true, CURRENT_TIMESTAMP, $2)
      `, [newsId, adminId]);
    }

    await client.query(
      'UPDATE news SET status = $1, updated_at = CURRENT_TIMESTAMP WHERE news_id = $2',
      ['draft', newsId]
    );

    await client.query(`
      INSERT INTO news_approval_history (
        news_id,
        reviewer_id,
        action,
        comments,
        previous_status,
        new_status
      ) VALUES ($1, $2, 'submit', $3, $4, 'pending_approval')
    `, [
      newsId,
      adminId,
      `Submitted "${news.title}" for approval`,
      news.status
    ]);

    await client.query('COMMIT');

    return res.status(200).json({
      success: true,
      message: 'Post submitted for approval successfully',
      news_id: newsId,
      workflow_status: 'pending_approval'
    });

  } catch (error) {
    await client.query('ROLLBACK');
    console.error('[Approval Submit] Error:', error);
    return res.status(500).json({
      success: false,
      message: 'Failed to submit post for approval',
      error: error.message
    });
  } finally {
    client.release();
  }
});

router.post('/approve/:newsId', requireAdminAuth, requireApprover, async (req, res) => {
  const pool = getPool();
  const client = await pool.connect();

  try {
    await client.query('BEGIN');

    const { newsId } = req.params;
    const { comments } = req.body;
    const approverId = req.adminId;

    const approvalCheck = await client.query(
      'SELECT approval_record_id, workflow_status FROM news_approval WHERE news_id = $1',
      [newsId]
    );

    if (approvalCheck.rows.length === 0) {
      await client.query('ROLLBACK');
      return res.status(404).json({
        success: false,
        message: 'Approval record not found'
      });
    }

    const currentStatus = approvalCheck.rows[0].workflow_status;

    await client.query(`
      UPDATE news_approval 
      SET 
        workflow_status = 'approved',
        approved_by = $1,
        approved_at = CURRENT_TIMESTAMP,
        rejected_by = NULL,
        rejected_at = NULL,
        rejection_reason = NULL,
        updated_at = CURRENT_TIMESTAMP
      WHERE news_id = $2
    `, [approverId, newsId]);

    await client.query(`
      UPDATE news 
      SET 
        status = 'published',
        published_at = CURRENT_TIMESTAMP,
        updated_at = CURRENT_TIMESTAMP
      WHERE news_id = $1
    `, [newsId]);

    await client.query(`
      INSERT INTO news_approval_history (
        news_id,
        reviewer_id,
        action,
        comments,
        previous_status,
        new_status
      ) VALUES ($1, $2, 'approve', $3, $4, 'approved')
    `, [newsId, approverId, comments || 'Post approved', currentStatus]);

    const newsResult = await client.query(
      'SELECT title, slug FROM news WHERE news_id = $1',
      [newsId]
    );

    await client.query('COMMIT');

    return res.status(200).json({
      success: true,
      message: 'Post approved and published successfully',
      news_id: newsId,
      news: newsResult.rows[0]
    });

  } catch (error) {
    await client.query('ROLLBACK');
    console.error('[Approval Approve] Error:', error);
    return res.status(500).json({
      success: false,
      message: 'Failed to approve post',
      error: error.message
    });
  } finally {
    client.release();
  }
});

router.post('/reject/:newsId', requireAdminAuth, requireApprover, async (req, res) => {
  const pool = getPool();
  const client = await pool.connect();

  try {
    await client.query('BEGIN');

    const { newsId } = req.params;
    const { reason, comments } = req.body;
    const rejecterId = req.adminId;

    if (!reason || reason.trim() === '') {
      await client.query('ROLLBACK');
      return res.status(400).json({
        success: false,
        message: 'Rejection reason is required'
      });
    }

    const approvalCheck = await client.query(
      'SELECT approval_record_id, workflow_status FROM news_approval WHERE news_id = $1',
      [newsId]
    );

    if (approvalCheck.rows.length === 0) {
      await client.query('ROLLBACK');
      return res.status(404).json({
        success: false,
        message: 'Approval record not found'
      });
    }

    const currentStatus = approvalCheck.rows[0].workflow_status;

    await client.query(`
      UPDATE news_approval 
      SET 
        workflow_status = 'rejected',
        rejected_by = $1,
        rejected_at = CURRENT_TIMESTAMP,
        rejection_reason = $2,
        approved_by = NULL,
        approved_at = NULL,
        updated_at = CURRENT_TIMESTAMP
      WHERE news_id = $3
    `, [rejecterId, reason, newsId]);

    await client.query(
      'UPDATE news SET status = $1, updated_at = CURRENT_TIMESTAMP WHERE news_id = $2',
      ['draft', newsId]
    );

    await client.query(`
      INSERT INTO news_approval_history (
        news_id,
        reviewer_id,
        action,
        comments,
        previous_status,
        new_status
      ) VALUES ($1, $2, 'reject', $3, $4, 'rejected')
    `, [newsId, rejecterId, comments || reason, currentStatus]);

    await client.query('COMMIT');

    return res.status(200).json({
      success: true,
      message: 'Post rejected successfully',
      news_id: newsId,
      rejection_reason: reason
    });

  } catch (error) {
    await client.query('ROLLBACK');
    console.error('[Approval Reject] Error:', error);
    return res.status(500).json({
      success: false,
      message: 'Failed to reject post',
      error: error.message
    });
  } finally {
    client.release();
  }
});

router.post('/request-changes/:newsId', requireAdminAuth, requireApprover, async (req, res) => {
  const pool = getPool();
  const client = await pool.connect();

  try {
    await client.query('BEGIN');

    const { newsId } = req.params;
    const { changes_requested } = req.body;
    const reviewerId = req.adminId;

    if (!changes_requested || changes_requested.trim() === '') {
      await client.query('ROLLBACK');
      return res.status(400).json({
        success: false,
        message: 'Changes description is required'
      });
    }

    const approvalCheck = await client.query(
      'SELECT approval_record_id, workflow_status FROM news_approval WHERE news_id = $1',
      [newsId]
    );

    if (approvalCheck.rows.length === 0) {
      await client.query('ROLLBACK');
      return res.status(404).json({
        success: false,
        message: 'Approval record not found'
      });
    }

    const currentStatus = approvalCheck.rows[0].workflow_status;

    await client.query(`
      UPDATE news_approval 
      SET 
        workflow_status = 'pending_review',
        rejection_reason = $1,
        updated_at = CURRENT_TIMESTAMP
      WHERE news_id = $2
    `, [changes_requested, newsId]);

    await client.query(`
      INSERT INTO news_approval_history (
        news_id,
        reviewer_id,
        action,
        comments,
        previous_status,
        new_status
      ) VALUES ($1, $2, 'request_changes', $3, $4, 'pending_review')
    `, [newsId, reviewerId, changes_requested, currentStatus]);

    await client.query('COMMIT');

    return res.status(200).json({
      success: true,
      message: 'Changes requested successfully',
      news_id: newsId
    });

  } catch (error) {
    await client.query('ROLLBACK');
    console.error('[Approval Request Changes] Error:', error);
    return res.status(500).json({
      success: false,
      message: 'Failed to request changes',
      error: error.message
    });
  } finally {
    client.release();
  }
});

router.get('/details/:newsId', requireAdminAuth, async (req, res) => {
  try {
    const { newsId } = req.params;
    const pool = getPool();

    const approvalResult = await pool.query(`
      SELECT 
        na.*,
        n.title,
        n.status as news_status,
        submitter.first_name as submitter_first_name,
        submitter.last_name as submitter_last_name,
        approver.first_name as approver_first_name,
        approver.last_name as approver_last_name,
        rejecter.first_name as rejecter_first_name,
        rejecter.last_name as rejecter_last_name
      FROM news_approval na
      JOIN news n ON na.news_id = n.news_id
      LEFT JOIN admins submitter ON na.submitted_by = submitter.admin_id
      LEFT JOIN admins approver ON na.approved_by = approver.admin_id
      LEFT JOIN admins rejecter ON na.rejected_by = rejecter.admin_id
      WHERE na.news_id = $1
    `, [newsId]);

    if (approvalResult.rows.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'Approval record not found'
      });
    }

    const historyResult = await pool.query(`
      SELECT 
        nah.*,
        a.first_name as reviewer_first_name,
        a.last_name as reviewer_last_name
      FROM news_approval_history nah
      JOIN admins a ON nah.reviewer_id = a.admin_id
      WHERE nah.news_id = $1
      ORDER BY nah.created_at DESC
    `, [newsId]);

    return res.status(200).json({
      success: true,
      approval: approvalResult.rows[0],
      history: historyResult.rows
    });

  } catch (error) {
    console.error('[Approval Details] Error:', error);
    return res.status(500).json({
      success: false,
      message: 'Failed to fetch approval details',
      error: error.message
    });
  }
});

module.exports = router;