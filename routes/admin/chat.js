const express = require('express');
const router = express.Router();
const { FRONTEND_URL, CLIENT_URL, ADMIN_URL, API_DOMAIN, ALLOWED_ORIGINS, isOriginAllowed } = require('../../config/frontendconfig');
const { getPool } = require('../../config/db');
const requireAdminAuth = require('../../middleware/adminAuth');
const { getUserRole } = require('../../middleware/rolePermissions');

router.get('/messages', requireAdminAuth, async (req, res) => {
  try {
    const adminId = req.adminId;
    const { receiver_id } = req.query;
    const pool = getPool();

    let query;
    let params;

    if (receiver_id) {
      query = `
        SELECT
          acm.message_id,
          acm.sender_id,
          acm.receiver_id,
          acm.message_text,
          acm.is_broadcast,
          acm.is_read,
          acm.created_at,
          CONCAT(sender.first_name, ' ', sender.last_name) as sender_name,
          sender.role as sender_role,
          CONCAT(receiver.first_name, ' ', receiver.last_name) as receiver_name,
          receiver.role as receiver_role
        FROM admin_chat_messages acm
        LEFT JOIN admins sender ON acm.sender_id = sender.admin_id
        LEFT JOIN admins receiver ON acm.receiver_id = receiver.admin_id
        WHERE ((acm.sender_id = $1 AND acm.receiver_id = $2)
           OR (acm.sender_id = $2 AND acm.receiver_id = $1))
          AND acm.is_broadcast = FALSE
        ORDER BY acm.created_at ASC
        LIMIT 100
      `;
      params = [adminId, receiver_id];
    } else {
      query = `
        SELECT
          acm.message_id,
          acm.sender_id,
          acm.receiver_id,
          acm.message_text,
          acm.is_broadcast,
          acm.is_read,
          acm.created_at,
          CONCAT(sender.first_name, ' ', sender.last_name) as sender_name,
          sender.role as sender_role,
          CONCAT(receiver.first_name, ' ', receiver.last_name) as receiver_name,
          receiver.role as receiver_role
        FROM admin_chat_messages acm
        LEFT JOIN admins sender ON acm.sender_id = sender.admin_id
        LEFT JOIN admins receiver ON acm.receiver_id = receiver.admin_id
        WHERE acm.is_broadcast = TRUE
           OR acm.receiver_id = $1
           OR acm.sender_id = $1
        ORDER BY acm.created_at ASC
        LIMIT 100
      `;
      params = [adminId];
    }

    const result = await pool.query(query, params);

    if (receiver_id) {
      await pool.query(`
        UPDATE admin_chat_messages
        SET is_read = TRUE, updated_at = CURRENT_TIMESTAMP
        WHERE receiver_id = $1 AND sender_id = $2 AND is_read = FALSE
      `, [adminId, receiver_id]);
    }

    return res.json({
      success: true,
      messages: result.rows
    });

  } catch (error) {
    console.error('[Admin Chat] Error fetching messages:', error);
    return res.status(500).json({
      success: false,
      error: 'Failed to fetch messages',
      message: error.message
    });
  }
});

router.post('/messages', requireAdminAuth, async (req, res) => {
  try {
    const adminId = req.adminId;
    const { receiver_id, message_text, is_broadcast } = req.body;

    if (!message_text?.trim()) {
      return res.status(400).json({
        success: false,
        error: 'Message text is required'
      });
    }

    const pool = getPool();

    const senderResult = await pool.query(
      `SELECT first_name, last_name, role FROM admins WHERE admin_id = $1 AND status = 'active'`,
      [adminId]
    );

    if (senderResult.rows.length === 0) {
      return res.status(404).json({
        success: false,
        error: 'Admin not found or inactive'
      });
    }

    const sender = senderResult.rows[0];
    const senderName = `${sender.first_name} ${sender.last_name}`;

    const isBroadcast = is_broadcast === true || is_broadcast === 'true';

    if (isBroadcast) {
      const userRole = await getUserRole(adminId);
      if (!['super_admin', 'admin'].includes(userRole)) {
        return res.status(403).json({
          success: false,
          error: 'Only Super Admins and Admins can send broadcast messages',
          your_role: userRole
        });
      }
    }

    if (!isBroadcast && !receiver_id) {
      return res.status(400).json({
        success: false,
        error: 'Receiver ID is required for direct messages'
      });
    }

    if (receiver_id) {
      const receiverCheck = await pool.query(
        `SELECT admin_id FROM admins WHERE admin_id = $1 AND status = 'active'`,
        [receiver_id]
      );

      if (receiverCheck.rows.length === 0) {
        return res.status(404).json({
          success: false,
          error: 'Receiver not found or inactive'
        });
      }
    }

    const result = await pool.query(`
      INSERT INTO admin_chat_messages (
        sender_id,
        sender_name,
        receiver_id,
        message_text,
        is_broadcast,
        created_at
      ) VALUES ($1, $2, $3, $4, $5, CURRENT_TIMESTAMP)
      RETURNING *
    `, [
      adminId,
      senderName,
      receiver_id || null,
      message_text.trim(),
      isBroadcast
    ]);

    return res.json({
      success: true,
      message: result.rows[0]
    });

  } catch (error) {
    console.error('[Admin Chat] Error sending message:', error);
    return res.status(500).json({
      success: false,
      error: 'Failed to send message',
      message: error.message
    });
  }
});

router.get('/online', requireAdminAuth, async (req, res) => {
  try {
    const pool = getPool();

    const result = await pool.query(`
      SELECT
        a.admin_id,
        CONCAT(a.first_name, ' ', a.last_name) as name,
        a.email,
        a.role,
        COALESCE(aos.last_active, a.last_login) as last_active,
        SUBSTRING(a.first_name, 1, 1) || SUBSTRING(a.last_name, 1, 1) as avatar,
        aos.is_online
      FROM admins a
      LEFT JOIN admin_online_status aos ON a.admin_id = aos.admin_id
      WHERE a.status = 'active'
        AND (aos.last_active > CURRENT_TIMESTAMP - INTERVAL '5 minutes'
             OR (aos.last_active IS NULL AND a.last_login > CURRENT_TIMESTAMP - INTERVAL '5 minutes'))
      ORDER BY aos.last_active DESC NULLS LAST
    `);

    return res.json({
      success: true,
      admins: result.rows
    });

  } catch (error) {
    console.error('[Admin Chat] Error fetching online admins:', error);
    return res.status(500).json({
      success: false,
      error: 'Failed to fetch online admins',
      message: error.message
    });
  }
});

router.post('/heartbeat', requireAdminAuth, async (req, res) => {
  try {
    const adminId = req.adminId;
    const pool = getPool();

    await pool.query(`
      INSERT INTO admin_online_status (admin_id, last_active, is_online, updated_at)
      VALUES ($1, CURRENT_TIMESTAMP, TRUE, CURRENT_TIMESTAMP)
      ON CONFLICT (admin_id)
      DO UPDATE SET
        last_active = CURRENT_TIMESTAMP,
        is_online = TRUE,
        updated_at = CURRENT_TIMESTAMP
    `, [adminId]);

    return res.json({
      success: true,
      timestamp: new Date().toISOString()
    });

  } catch (error) {
    console.error('[Admin Chat] Error updating heartbeat:', error);
    return res.status(500).json({
      success: false,
      error: 'Failed to update heartbeat',
      message: error.message
    });
  }
});

router.get('/unread-count', requireAdminAuth, async (req, res) => {
  try {
    const adminId = req.adminId;
    const pool = getPool();

    const result = await pool.query(`
      SELECT COUNT(*) as unread_count
      FROM admin_chat_messages
      WHERE receiver_id = $1 AND is_read = FALSE
    `, [adminId]);

    return res.json({
      success: true,
      unread_count: parseInt(result.rows[0].unread_count) || 0
    });

  } catch (error) {
    console.error('[Admin Chat] Error fetching unread count:', error);
    return res.status(500).json({
      success: false,
      error: 'Failed to fetch unread count',
      message: error.message
    });
  }
});

router.post('/mark-read', requireAdminAuth, async (req, res) => {
  try {
    const adminId = req.adminId;
    const { sender_id } = req.body;

    if (!sender_id) {
      return res.status(400).json({
        success: false,
        error: 'Sender ID is required'
      });
    }

    const pool = getPool();

    const result = await pool.query(`
      UPDATE admin_chat_messages
      SET is_read = TRUE, updated_at = CURRENT_TIMESTAMP
      WHERE receiver_id = $1
        AND sender_id = $2
        AND is_read = FALSE
      RETURNING message_id
    `, [adminId, sender_id]);

    return res.json({
      success: true,
      message: 'Messages marked as read',
      count: result.rowCount
    });

  } catch (error) {
    console.error('[Admin Chat] Error marking messages as read:', error);
    return res.status(500).json({
      success: false,
      error: 'Failed to mark messages as read',
      message: error.message
    });
  }
});

router.delete('/messages/:message_id', requireAdminAuth, async (req, res) => {
  try {
    const adminId = req.adminId;
    const { message_id } = req.params;

    if (!message_id || isNaN(Number(message_id))) {
      return res.status(400).json({
        success: false,
        error: 'Valid message ID is required'
      });
    }

    const pool = getPool();
    const userRole = await getUserRole(adminId);

    let deleteQuery;
    let deleteParams;

    if (['super_admin', 'admin'].includes(userRole)) {
      deleteQuery = `
        DELETE FROM admin_chat_messages
        WHERE message_id = $1
        RETURNING message_id
      `;
      deleteParams = [message_id];
    } else {
      deleteQuery = `
        DELETE FROM admin_chat_messages
        WHERE message_id = $1 AND sender_id = $2
        RETURNING message_id
      `;
      deleteParams = [message_id, adminId];
    }

    const result = await pool.query(deleteQuery, deleteParams);

    if (result.rowCount === 0) {
      return res.status(404).json({
        success: false,
        error: 'Message not found or unauthorized'
      });
    }

    return res.json({
      success: true,
      message: 'Message deleted successfully'
    });

  } catch (error) {
    console.error('[Admin Chat] Error deleting message:', error);
    return res.status(500).json({
      success: false,
      error: 'Failed to delete message',
      message: error.message
    });
  }
});

router.get('/conversations', requireAdminAuth, async (req, res) => {
  try {
    const adminId = req.adminId;
    const pool = getPool();

    const result = await pool.query(`
      WITH latest_messages AS (
        SELECT DISTINCT ON (
          CASE 
            WHEN sender_id = $1 THEN receiver_id
            ELSE sender_id
          END
        )
          CASE 
            WHEN sender_id = $1 THEN receiver_id
            ELSE sender_id
          END as other_admin_id,
          message_text,
          created_at,
          is_read,
          sender_id
        FROM admin_chat_messages
        WHERE (sender_id = $1 OR receiver_id = $1)
          AND is_broadcast = FALSE
        ORDER BY 
          CASE 
            WHEN sender_id = $1 THEN receiver_id
            ELSE sender_id
          END,
          created_at DESC
      )
      SELECT 
        lm.other_admin_id as admin_id,
        CONCAT(a.first_name, ' ', a.last_name) as name,
        a.email,
        a.role,
        lm.message_text as last_message,
        lm.created_at as last_message_time,
        CASE WHEN lm.sender_id != $1 AND lm.is_read = FALSE THEN 1 ELSE 0 END as has_unread,
        aos.is_online,
        aos.last_active
      FROM latest_messages lm
      JOIN admins a ON lm.other_admin_id = a.admin_id
      LEFT JOIN admin_online_status aos ON a.admin_id = aos.admin_id
      WHERE a.status = 'active'
      ORDER BY lm.created_at DESC
    `, [adminId]);

    return res.json({
      success: true,
      conversations: result.rows
    });

  } catch (error) {
    console.error('[Admin Chat] Error fetching conversations:', error);
    return res.status(500).json({
      success: false,
      error: 'Failed to fetch conversations',
      message: error.message
    });
  }
});

router.get('/admins', requireAdminAuth, async (req, res) => {
  try {
    const pool = getPool();

    const result = await pool.query(`
      SELECT 
        a.admin_id,
        CONCAT(a.first_name, ' ', a.last_name) as name,
        a.email,
        a.role,
        aos.is_online,
        aos.last_active
      FROM admins a
      LEFT JOIN admin_online_status aos ON a.admin_id = aos.admin_id
      WHERE a.status = 'active'
      ORDER BY 
        CASE a.role
          WHEN 'super_admin' THEN 1
          WHEN 'admin' THEN 2
          WHEN 'editor' THEN 3
          WHEN 'moderator' THEN 4
          ELSE 5
        END,
        a.first_name ASC
    `);

    return res.json({
      success: true,
      admins: result.rows
    });

  } catch (error) {
    console.error('[Admin Chat] Error fetching admins:', error);
    return res.status(500).json({
      success: false,
      error: 'Failed to fetch admins',
      message: error.message
    });
  }
});

module.exports = router;