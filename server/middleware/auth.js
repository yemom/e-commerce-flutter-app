// Verifies auth tokens and protects routes that need signed-in or admin users.
const jwt = require('jsonwebtoken');
const { jwtSecret } = require('../config/env');
const { User, Driver } = require('../models');

function parseBearerToken(headerValue) {
  if (!headerValue || typeof headerValue !== 'string') {
    return null;
  }

  // Accept standard "Bearer <token>" format only.
  const [scheme, token] = headerValue.trim().split(' ');
  if (scheme?.toLowerCase() !== 'bearer' || !token) {
    return null;
  }

  return token.trim();
}

function createAuthMiddleware() {
  return async (req, res, next) => {
    // Read and validate JWT from Authorization header.
    const token = parseBearerToken(req.headers.authorization);
    if (!token) {
      return res.status(401).json({ message: 'Authentication token is required.' });
    }

    try {
      const payload = jwt.verify(token, jwtSecret);
      // Token subject maps to application-level user id.
      const user = await User.findOne({ id: payload.sub });
      if (user) {
        req.auth = {
          token,
          user,
        };
        return next();
      }

      const driver = await Driver.findOne({ id: payload.sub });
      if (!driver) {
        return res.status(401).json({ message: 'Authentication token is no longer valid.' });
      }

      req.auth = {
        token,
        user: {
          id: driver.id,
          email: driver.email || '',
          name: driver.name,
          role: 'driver',
          approved: true,
        },
      };
      // Downstream routes can trust req.auth.user.
      return next();
    } catch (_) {
      return res.status(401).json({ message: 'Authentication token is invalid or expired.' });
    }
  };
}

function createDriverAuthMiddleware() {
  return async (req, res, next) => {
    const token = parseBearerToken(req.headers.authorization);
    if (!token) {
      return res.status(401).json({ message: 'Authentication token is required.' });
    }

    try {
      const payload = jwt.verify(token, jwtSecret);
      const user = await User.findOne({ id: payload.sub, role: 'driver' });
      if (user) {
        req.authDriver = {
          token,
          driver: {
            id: user.id,
            name: user.name,
            phone: user.phone || '',
            email: user.email || '',
            vehicleType: user.vehicleType || '',
            licenseNumber: user.licenseNumber || '',
            isOnline: true,
            role: 'driver',
          },
        };
        return next();
      }

      const driver = await Driver.findOne({ id: payload.sub });

      if (!driver) {
        return res.status(401).json({ message: 'Authentication token is no longer valid.' });
      }

      req.authDriver = {
        token,
        driver,
      };
      return next();
    } catch (_) {
      return res.status(401).json({ message: 'Authentication token is invalid or expired.' });
    }
  };
}

function requireSuperAdmin(req, res, next) {
  // Guard admin-management endpoints behind super-admin role only.
  const role = req.auth?.user?.role;
  if (role !== 'super_admin') {
    return res.status(403).json({ message: 'Only a super admin can perform this action.' });
  }
  return next();
}

module.exports = {
  createAuthMiddleware,
  requireSuperAdmin,
  createDriverAuthMiddleware,
};
