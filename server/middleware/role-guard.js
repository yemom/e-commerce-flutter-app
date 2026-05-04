// middleware/role-guard.js
// Protects routes by checking the authenticated user's role.
// Usage: router.get('/route', auth, allowRoles('admin', 'super_admin'), handler)

/**
 * Middleware factory that restricts access to users with specific roles.
 * Must be used AFTER the auth middleware so req.auth is already populated.
 *
 * @param {...string} roles - Allowed roles e.g. 'driver', 'admin', 'super_admin', 'user'
 */
const allowRoles =
  (...roles) =>
  (req, res, next) => {
    // Auth middleware must run first to populate req.auth
    if (!req.auth) {
      return res.status(401).json({
        message: "Unauthorized. Please log in to continue.",
      });
    }

    const userRole = req.auth.role || req.auth?.user?.role;

    if (!userRole) {
      return res.status(401).json({
        message: "Unauthorized. No role found in token.",
      });
    }

    if (!roles.includes(userRole)) {
      return res.status(403).json({
        message: `Forbidden. This action requires one of these roles: ${roles.join(", ")}. Your role: ${userRole}.`,
      });
    }

    next();
  };

/**
 * Shorthand guards for common role combinations.
 * Import whichever you need directly instead of calling allowRoles() each time.
 */
const requireDriver = allowRoles("driver");
const requireUser = allowRoles("user");
const requireAdmin = allowRoles("admin", "super_admin");
const requireSuperAdmin = allowRoles("super_admin");
const requireAnyStaff = allowRoles("admin", "super_admin", "driver");

module.exports = {
  allowRoles,
  requireDriver,
  requireUser,
  requireAdmin,
  requireSuperAdmin,
  requireAnyStaff,
};
