const { getPool } = require('../config/db');

const ROLE_HIERARCHY = {
  super_admin: 4,
  admin: 3,
  editor: 2,
  moderator: 1
};

const getUserRole = async (adminId) => {
  try {
    const pool = getPool();
    const result = await pool.query(
      'SELECT role, status FROM admins WHERE admin_id = $1',
      [adminId]
    );
    
    if (result.rows.length === 0) return null;
    if (result.rows[0].status !== 'active') return null;
    
    return result.rows[0].role.toLowerCase();
  } catch (error) {
    console.error('[rolePermissions] getUserRole error:', error);
    return null;
  }
};

const getRoleLevel = (role) => {
  const normalizedRole = role ? role.toLowerCase() : '';
  return ROLE_HIERARCHY[normalizedRole] || 0;
};

const canManageRole = (actorRole, targetRole) => {
  const actorLevel = getRoleLevel(actorRole);
  const targetLevel = getRoleLevel(targetRole);
  return actorLevel > targetLevel;
};

const getAssignableRoles = (role) => {
  const normalizedRole = role ? role.toLowerCase() : '';
  const userLevel = getRoleLevel(normalizedRole);
  
  return Object.entries(ROLE_HIERARCHY)
    .filter(([_, level]) => level < userLevel)
    .map(([roleName]) => roleName)
    .sort((a, b) => ROLE_HIERARCHY[a] - ROLE_HIERARCHY[b]);
};

const canPublishDirectly = (role) => {
  const normalizedRole = role ? role.toLowerCase() : '';
  return ['super_admin', 'admin', 'editor'].includes(normalizedRole);
};

const canApprove = (role) => {
  const normalizedRole = role ? role.toLowerCase() : '';
  return ['super_admin', 'admin', 'editor'].includes(normalizedRole);
};

const canHardDelete = (role) => {
  const normalizedRole = role ? role.toLowerCase() : '';
  return ['super_admin', 'admin'].includes(normalizedRole);
};

const canArchive = (role) => {
  const normalizedRole = role ? role.toLowerCase() : '';
  return ['super_admin', 'admin', 'editor', 'moderator'].includes(normalizedRole);
};

const canEditAny = (role) => {
  const normalizedRole = role ? role.toLowerCase() : '';
  return ['super_admin', 'admin', 'editor'].includes(normalizedRole);
};

const canManageUsers = (role) => {
  const normalizedRole = role ? role.toLowerCase() : '';
  return ['super_admin', 'admin'].includes(normalizedRole);
};

const canViewUsers = (role) => {
  const normalizedRole = role ? role.toLowerCase() : '';
  return ['super_admin', 'admin', 'editor', 'moderator'].includes(normalizedRole);
};

const canCreateUsers = (role) => {
  const normalizedRole = role ? role.toLowerCase() : '';
  return ['super_admin', 'admin'].includes(normalizedRole);
};

const canEditUsers = (role) => {
  const normalizedRole = role ? role.toLowerCase() : '';
  return ['super_admin', 'admin'].includes(normalizedRole);
};

const canDeleteUsers = (role) => {
  const normalizedRole = role ? role.toLowerCase() : '';
  return ['super_admin', 'admin'].includes(normalizedRole);
};

const canResetPasswords = (role) => {
  const normalizedRole = role ? role.toLowerCase() : '';
  return ['super_admin', 'admin'].includes(normalizedRole);
};

const canManageRoles = (role) => {
  const normalizedRole = role ? role.toLowerCase() : '';
  return ['super_admin', 'admin'].includes(normalizedRole);
};

const requireRole = (allowedRoles) => {
  return async (req, res, next) => {
    try {
      const adminId = req.adminId || req.session?.adminId;

      if (!adminId) {
        return res.status(401).json({
          success: false,
          message: 'Authentication required'
        });
      }

      const role = await getUserRole(adminId);

      if (!role) {
        return res.status(401).json({
          success: false,
          message: 'Invalid or inactive admin account'
        });
      }

      const normalizedRole = role.toLowerCase();
      const normalizedAllowedRoles = allowedRoles.map(r => r.toLowerCase());

      if (!normalizedAllowedRoles.includes(normalizedRole)) {
        return res.status(403).json({
          success: false,
          message: 'Insufficient permissions'
        });
      }

      req.userRole = normalizedRole;
      next();
    } catch (error) {
      console.error('[rolePermissions] requireRole error:', error);
      return res.status(500).json({
        success: false,
        message: 'Permission check failed'
      });
    }
  };
};

const requirePublisher = async (req, res, next) => {
  try {
    const adminId = req.adminId || req.session?.adminId;

    if (!adminId) {
      return res.status(401).json({
        success: false,
        message: 'Authentication required'
      });
    }

    const role = await getUserRole(adminId);

    if (!role) {
      return res.status(401).json({
        success: false,
        message: 'Invalid admin account'
      });
    }

    const normalizedRole = role.toLowerCase();
    req.userRole = normalizedRole;
    req.canPublish = canPublishDirectly(normalizedRole);
    next();
  } catch (error) {
    console.error('[rolePermissions] requirePublisher error:', error);
    return res.status(500).json({
      success: false,
      message: 'Permission check failed'
    });
  }
};

const requireApprover = async (req, res, next) => {
  try {
    const adminId = req.adminId || req.session?.adminId;

    if (!adminId) {
      return res.status(401).json({
        success: false,
        message: 'Authentication required'
      });
    }

    const role = await getUserRole(adminId);
    const normalizedRole = role ? role.toLowerCase() : '';

    if (!role || !canApprove(normalizedRole)) {
      return res.status(403).json({
        success: false,
        message: 'Only Super Admins, Admins, and Editors can approve posts'
      });
    }

    req.userRole = normalizedRole;
    next();
  } catch (error) {
    console.error('[rolePermissions] requireApprover error:', error);
    return res.status(500).json({
      success: false,
      message: 'Permission check failed'
    });
  }
};

const requireEditor = async (req, res, next) => {
  try {
    const adminId = req.adminId || req.session?.adminId;
    const newsId = req.params.id || req.body.news_id;

    if (!adminId) {
      return res.status(401).json({
        success: false,
        message: 'Authentication required'
      });
    }

    const role = await getUserRole(adminId);
    const normalizedRole = role ? role.toLowerCase() : '';

    if (!role) {
      return res.status(401).json({
        success: false,
        message: 'Invalid admin account'
      });
    }

    if (canEditAny(normalizedRole)) {
      req.userRole = normalizedRole;
      req.canEditAny = true;
      return next();
    }

    if (normalizedRole === 'moderator' && newsId) {
      const pool = getPool();
      const result = await pool.query(
        'SELECT author_id, status FROM news WHERE news_id = $1',
        [newsId]
      );

      if (result.rows.length === 0) {
        return res.status(404).json({
          success: false,
          message: 'Post not found'
        });
      }

      const post = result.rows[0];

      if (post.author_id !== adminId) {
        return res.status(403).json({
          success: false,
          message: 'You can only edit your own posts'
        });
      }

      if (post.status === 'published') {
        return res.status(403).json({
          success: false,
          message: 'You cannot edit published posts'
        });
      }

      req.userRole = normalizedRole;
      req.canEditAny = false;
      return next();
    }

    req.userRole = normalizedRole;
    req.canEditAny = false;
    next();

  } catch (error) {
    console.error('[rolePermissions] requireEditor error:', error);
    return res.status(500).json({
      success: false,
      message: 'Permission check failed'
    });
  }
};

const requireDeleter = async (req, res, next) => {
  try {
    const adminId = req.adminId || req.session?.adminId;
    const hardDelete = req.body.hard_delete || false;

    if (!adminId) {
      return res.status(401).json({
        success: false,
        message: 'Authentication required'
      });
    }

    const role = await getUserRole(adminId);
    const normalizedRole = role ? role.toLowerCase() : '';

    if (!role) {
      return res.status(401).json({
        success: false,
        message: 'Invalid admin account'
      });
    }

    if (hardDelete && !canHardDelete(normalizedRole)) {
      return res.status(403).json({
        success: false,
        message: 'Only Super Admins and Admins can permanently delete'
      });
    }

    if (!hardDelete && !canArchive(normalizedRole)) {
      return res.status(403).json({
        success: false,
        message: 'Insufficient permissions to archive'
      });
    }

    req.userRole = normalizedRole;
    next();
  } catch (error) {
    console.error('[rolePermissions] requireDeleter error:', error);
    return res.status(500).json({
      success: false,
      message: 'Permission check failed'
    });
  }
};

const requireUserManager = async (req, res, next) => {
  try {
    const adminId = req.adminId || req.session?.adminId;

    if (!adminId) {
      return res.status(401).json({
        success: false,
        message: 'Authentication required'
      });
    }

    const role = await getUserRole(adminId);
    const normalizedRole = role ? role.toLowerCase() : '';

    if (!role || !canManageUsers(normalizedRole)) {
      return res.status(403).json({
        success: false,
        message: 'Only Super Admins and Admins can manage users'
      });
    }

    req.userRole = normalizedRole;
    next();
  } catch (error) {
    console.error('[rolePermissions] requireUserManager error:', error);
    return res.status(500).json({
      success: false,
      message: 'Permission check failed'
    });
  }
};

module.exports = {
  getUserRole,
  getRoleLevel,
  canManageRole,
  getAssignableRoles,
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
  requireRole,
  requirePublisher,
  requireApprover,
  requireEditor,
  requireDeleter,
  requireUserManager
};