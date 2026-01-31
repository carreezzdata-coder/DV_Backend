const express = require('express');
const router = express.Router();
const requireAdminAuth = require('../../middleware/adminAuth');

const { FRONTEND_URL, CLIENT_URL, ADMIN_URL, API_DOMAIN, ALLOWED_ORIGINS, isOriginAllowed } = require('../../config/frontendconfig');

const { 
  canPublishDirectly, 
  canApprove, 
  canHardDelete, 
  canArchive, 
  canEditAny, 
  canManageUsers,
  canViewUsers,
  canCreateUsers,
  canEditUsers,
  canDeleteUsers,
  canResetPasswords,
  canManageRoles,
  getAssignableRoles
} = require('../../middleware/rolePermissions');

router.get('/me', requireAdminAuth, async (req, res) => {
  try {
    const role = req.userRole ? req.userRole.toLowerCase() : 'moderator';

    const permissions = {
      role: role,
      can_publish_directly: canPublishDirectly(role),
      can_approve_posts: canApprove(role),
      can_hard_delete: canHardDelete(role),
      can_archive: canArchive(role),
      can_edit_any: canEditAny(role),
      can_manage_users: canManageUsers(role),
      can_create_posts: ['super_admin', 'admin', 'editor', 'moderator'].includes(role),
      can_create_quotes: ['super_admin', 'admin', 'editor', 'moderator'].includes(role),
      can_feature: ['super_admin', 'admin', 'editor'].includes(role),
      can_set_breaking: ['super_admin', 'admin'].includes(role),
      can_set_pinned: ['super_admin', 'admin'].includes(role),
      requires_approval: !canPublishDirectly(role),
      can_view_users: canViewUsers(role),
      can_create_users: canCreateUsers(role),
      can_edit_users: canEditUsers(role),
      can_delete_users: canDeleteUsers(role),
      can_change_own_password: ['super_admin', 'admin', 'editor', 'moderator'].includes(role),
      can_reset_others_password: canResetPasswords(role),
      can_manage_roles: canManageRoles(role),
      assignable_roles: getAssignableRoles(role)
    };

    return res.status(200).json({
      success: true,
      permissions
    });
  } catch (error) {
    console.error('[Permissions] Error:', error);
    return res.status(500).json({
      success: false,
      message: 'Failed to fetch permissions',
      error: process.env.NODE_ENV === 'production' ? undefined : error.message
    });
  }
});

router.get('/check/:action', requireAdminAuth, async (req, res) => {
  try {
    const { action } = req.params;
    const role = req.userRole ? req.userRole.toLowerCase() : '';

    let hasPermission = false;

    switch (action) {
      case 'publish':
        hasPermission = canPublishDirectly(role);
        break;
      case 'approve':
        hasPermission = canApprove(role);
        break;
      case 'hard_delete':
        hasPermission = canHardDelete(role);
        break;
      case 'archive':
        hasPermission = canArchive(role);
        break;
      case 'edit_any':
        hasPermission = canEditAny(role);
        break;
      case 'manage_users':
        hasPermission = canManageUsers(role);
        break;
      case 'create_posts':
        hasPermission = ['super_admin', 'admin', 'editor', 'moderator'].includes(role);
        break;
      case 'feature':
        hasPermission = ['super_admin', 'admin', 'editor'].includes(role);
        break;
      case 'breaking':
        hasPermission = ['super_admin', 'admin'].includes(role);
        break;
      case 'pinned':
        hasPermission = ['super_admin', 'admin'].includes(role);
        break;
      case 'view_users':
        hasPermission = canViewUsers(role);
        break;
      case 'create_users':
        hasPermission = canCreateUsers(role);
        break;
      case 'edit_users':
        hasPermission = canEditUsers(role);
        break;
      case 'delete_users':
        hasPermission = canDeleteUsers(role);
        break;
      case 'reset_passwords':
        hasPermission = canResetPasswords(role);
        break;
      case 'manage_roles':
        hasPermission = canManageRoles(role);
        break;
      default:
        hasPermission = false;
    }

    return res.status(200).json({
      success: true,
      action,
      has_permission: hasPermission,
      role
    });
  } catch (error) {
    console.error('[Permissions Check] Error:', error);
    return res.status(500).json({
      success: false,
      message: 'Failed to check permission',
      error: process.env.NODE_ENV === 'production' ? undefined : error.message
    });
  }
});

module.exports = router;