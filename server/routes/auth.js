// Handles signup, login, password reset, profile lookup, and admin account management routes.
const crypto = require('crypto');
const express = require('express');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');

const { jwtSecret, superAdminEmail } = require('../config/env');
const { createAuthMiddleware, requireSuperAdmin } = require('../middleware/auth');
const { User, Driver, Order } = require('../models');
const { sendPasswordResetEmail } = require('../utils/mailer');
const { syncSuperAdminAccount } = require('../utils/super-admin');

function normalizeEmail(value) {
  // Keep email comparisons stable across signup/login flows.
  return String(value || '').trim().toLowerCase();
}

function normalizePhone(value) {
  return String(value || '').trim();
}

function isLikelyPhone(value) {
  const normalized = normalizePhone(value);
  return /^[+\d][\d\s\-()]{5,}$/.test(normalized);
}

function hashResetToken(token) {
  // Store only a hash of reset tokens so raw codes are never persisted.
  return crypto.createHash('sha256').update(String(token)).digest('hex');
}

function sanitizeUser(userDoc) {
  // Never expose password hashes or internal fields to API consumers.
  return {
    id: userDoc.id,
    email: userDoc.email || '',
    phone: userDoc.phone || '',
    name: userDoc.name,
    role: userDoc.role,
    approved: userDoc.approved,
    vehicleType: userDoc.vehicleType || '',
    licenseNumber: userDoc.licenseNumber || '',
  };
}

function sanitizeDriver(userDoc, extra = {}) {
  return {
    ...sanitizeUser(userDoc),
    vehicleType: userDoc.vehicleType || '',
    licenseNumber: userDoc.licenseNumber || '',
    isOnline: userDoc.isOnline !== false,
    ...extra,
  };
}

function normalizeString(value) {
  return String(value || '').trim();
}

function buildOrderSummary(order) {
  return {
    id: order.id,
    status: order.status,
    customerId: order.customerId,
    customerName: normalizeString(order.customerName),
    branchId: order.branchId,
    total: order.total ?? 0,
    itemCount: Array.isArray(order.items) ? order.items.length : 0,
    deliveryAddressLine: normalizeString(order.deliveryAddress?.line1),
    createdAt: order.createdAt,
    deliveredAt: order.deliveredAt ?? null,
  };
}

async function buildDriverPayload(user) {
  const assignedOrders = await Order.find({ driverId: user.id }).sort({ createdAt: -1 });
  const deliveredOrders = assignedOrders.filter((order) => order.status === 'delivered');
  const activeOrdersCount = assignedOrders.filter((order) => ['assigned', 'out_for_delivery', 'shipped'].includes(order.status)).length;
  const currentStatus = activeOrdersCount > 0 ? 'busy' : (user.isOnline ? 'available' : 'offline');

  return sanitizeDriver(user, {
    currentStatus,
    activeOrdersCount,
    assignedOrders: assignedOrders.map(buildOrderSummary),
    deliveryHistory: deliveredOrders.map(buildOrderSummary),
  });
}

function signToken(userDoc) {
  // JWT keeps only claims needed by auth middleware and frontend role checks.
  return jwt.sign(
    {
      sub: userDoc.id,
      role: userDoc.role,
      email: userDoc.email,
    },
    jwtSecret,
    { expiresIn: '7d' },
  );
}

function buildUserLoginResponse(user) {
  return {
    token: signToken(user),
    user: sanitizeUser(user),
  };
}

function buildDriverLoginResponse(driver) {
  const token = jwt.sign(
    { sub: driver.id, role: 'driver', email: driver.email, phone: driver.phone },
    jwtSecret,
    { expiresIn: '7d' },
  );

  return {
    token,
    user: {
      id: driver.id,
      email: driver.email,
      name: driver.name,
      role: 'driver',
      approved: true,
    },
  };
}

async function loginSharedAccount(rawIdentifier, password) {
  const email = normalizeEmail(rawIdentifier);
  const normalizedPhone = normalizePhone(rawIdentifier);

  const user = rawIdentifier.includes('@')
    ? await User.findOne({ email })
    : await User.findOne({ $or: [{ email }, { phone: normalizedPhone }] });
  if (user) {
    const passwordMatches = await bcrypt.compare(password, user.passwordHash);
    if (!passwordMatches) {
      return { status: 401, body: { message: 'The email or password is not correct. Please try again.' } };
    }

    if (user.role === 'admin' && !user.approved) {
      return {
        status: 403,
        body: { message: 'Your admin account is waiting for super admin approval. Please try again later.' },
      };
    }

    if (user.email === superAdminEmail) {
      await syncSuperAdminAccount();
      user.role = 'super_admin';
      user.approved = true;
    }

    return { status: 200, body: buildUserLoginResponse(user) };
  }

  const driver = rawIdentifier.includes('@')
    ? await Driver.findOne({ email })
    : await Driver.findOne({ $or: [{ email }, { phone: normalizedPhone }] });
  if (!driver) {
    return { status: 401, body: { message: 'The email or password is not correct. Please try again.' } };
  }

  const driverPasswordMatches = await bcrypt.compare(password, driver.passwordHash);
  if (!driverPasswordMatches) {
    return { status: 401, body: { message: 'The email or password is not correct. Please try again.' } };
  }

  return { status: 200, body: buildDriverLoginResponse(driver) };
}

async function loginUserOnly(rawIdentifier, password) {
  const email = normalizeEmail(rawIdentifier);
  const normalizedPhone = normalizePhone(rawIdentifier);
  const user = rawIdentifier.includes('@')
    ? await User.findOne({ email, role: 'user' })
    : await User.findOne({ $or: [{ email }, { phone: normalizedPhone }], role: 'user' });

  if (!user) {
    return { status: 401, body: { message: 'The email or password is not correct. Please try again.' } };
  }

  const matches = await bcrypt.compare(password, user.passwordHash);
  if (!matches) {
    return { status: 401, body: { message: 'The email or password is not correct. Please try again.' } };
  }

  return { status: 200, body: buildUserLoginResponse(user) };
}

async function loginAdminOnly(rawIdentifier, password) {
  const email = normalizeEmail(rawIdentifier);
  const normalizedPhone = normalizePhone(rawIdentifier);
  const user = rawIdentifier.includes('@')
    ? await User.findOne({ email, role: { $in: ['admin', 'super_admin'] } })
    : await User.findOne({ $or: [{ email }, { phone: normalizedPhone }], role: { $in: ['admin', 'super_admin'] } });

  if (!user) {
    return { status: 401, body: { message: 'The email or password is not correct. Please try again.' } };
  }

  const matches = await bcrypt.compare(password, user.passwordHash);
  if (!matches) {
    return { status: 401, body: { message: 'The email or password is not correct. Please try again.' } };
  }

  if (user.role === 'admin' && !user.approved) {
    return {
      status: 403,
      body: { message: 'Your admin account is waiting for super admin approval. Please try again later.' },
    };
  }

  if (user.email === superAdminEmail) {
    await syncSuperAdminAccount();
    user.role = 'super_admin';
    user.approved = true;
  }

  return { status: 200, body: buildUserLoginResponse(user) };
}

async function loginDriverOnly(rawIdentifier, password) {
  const email = normalizeEmail(rawIdentifier);
  const normalizedPhone = normalizePhone(rawIdentifier);
  const driver = rawIdentifier.includes('@')
    ? await Driver.findOne({ email })
    : await Driver.findOne({ $or: [{ email }, { phone: normalizedPhone }] });

  if (!driver) {
    return { status: 401, body: { message: 'The email or password is not correct. Please try again.' } };
  }

  const matches = await bcrypt.compare(password, driver.passwordHash);
  if (!matches) {
    return { status: 401, body: { message: 'The email or password is not correct. Please try again.' } };
  }

  return { status: 200, body: buildDriverLoginResponse(driver) };
}

function createAuthRouter() {
  const router = express.Router();
  const auth = createAuthMiddleware();

  async function loginWithRole(req, res, expectedRoles) {
    const rawIdentifier = String(req.body.identifier || req.body.email || req.body.phone || '').trim();
    const email = normalizeEmail(rawIdentifier);
    const password = String(req.body.password || '').trim();

    if (!rawIdentifier || !password) {
      return res.status(400).json({ message: 'Email/phone and password are required.' });
    }

    const normalizedPhone = normalizePhone(rawIdentifier);
    const lookup = rawIdentifier.includes('@')
      ? { email }
      : { $or: [{ email }, { phone: normalizedPhone }] };

    const user = await User.findOne(lookup);
    if (user && expectedRoles.includes(user.role)) {
      const passwordMatches = await bcrypt.compare(password, user.passwordHash);
      if (!passwordMatches) {
        return res.status(401).json({ message: 'The email or password is not correct. Please try again.' });
      }

      if (user.role === 'admin' && !user.approved) {
        return res.status(403).json({ message: 'Your admin account is waiting for super admin approval. Please try again later.' });
      }

      const token = signToken(user);
      if (user.email === superAdminEmail) {
        await syncSuperAdminAccount();
        user.role = 'super_admin';
        user.approved = true;
      }

      return res.json({ token, user: sanitizeUser(user) });
    }

    const driver = await Driver.findOne(lookup);
    if (driver && expectedRoles.includes('driver')) {
      const driverPasswordMatches = await bcrypt.compare(password, driver.passwordHash);
      if (!driverPasswordMatches) {
        return res.status(401).json({ message: 'The email or password is not correct. Please try again.' });
      }

      return res.json({
        token: jwt.sign(
          { sub: driver.id, role: 'driver', email: driver.email, phone: driver.phone },
          jwtSecret,
          { expiresIn: '7d' },
        ),
        user: {
          id: driver.id,
          email: driver.email,
          name: driver.name,
          role: 'driver',
          approved: true,
        },
      });
    }

    return res.status(401).json({ message: 'The email or password is not correct. Please try again.' });
  }

  const registerHandler = async (req, res) => {
    const fullName = String(req.body.fullName || req.body.name || '').trim();
    const identifier = String(req.body.identifier || '').trim();
    const inputEmail = normalizeEmail(req.body.email);
    const inputPhone = normalizePhone(req.body.phone);
    const password = String(req.body.password || '').trim();
    const registerAsDriver = req.body.registerAsDriver === true || req.body.role === 'driver';

    const email = inputEmail || (identifier.includes('@') ? normalizeEmail(identifier) : '');
    const phone = inputPhone || (!identifier.includes('@') && isLikelyPhone(identifier) ? normalizePhone(identifier) : '');

    if (!email && !phone) {
      return res.status(400).json({ message: 'Provide a valid email or phone number.' });
    }
    if (password.length < 6) {
      return res.status(400).json({ message: 'Password must be at least 6 characters long.' });
    }
    if (registerAsDriver) {
      const vehicleType = String(req.body.vehicleType || '').trim();
      const licenseNumber = String(req.body.licenseNumber || '').trim();
      if (!vehicleType || !licenseNumber) {
        return res.status(400).json({ message: 'Vehicle type and license number are required for driver registration.' });
      }
    }

    const existing = await User.findOne({
      $or: [
        ...(email ? [{ email }] : []),
        ...(phone ? [{ phone }] : []),
      ],
    });
    if (existing) {
      return res.status(409).json({ message: 'This email or phone is already registered. Please sign in instead.' });
    }

    // Super-admin account is tied to the configured email; all others start as regular users.
    const role = email === superAdminEmail ? 'super_admin' : (registerAsDriver ? 'driver' : 'user');
    const approved = role !== 'admin';
    const passwordHash = await bcrypt.hash(password, 10);

    const user = await User.create({
      id: crypto.randomUUID(),
      email: email || undefined,
      phone: phone || undefined,
      name: fullName || (email ? email.split('@')[0] : phone),
      passwordHash,
      role,
      approved,
      vehicleType: registerAsDriver ? String(req.body.vehicleType || '').trim() : '',
      licenseNumber: registerAsDriver ? String(req.body.licenseNumber || '').trim() : '',
    });

    const token = signToken(user);
    if (user.email === superAdminEmail) {
      // Keep bootstrapped super-admin record synchronized with env configuration.
      await syncSuperAdminAccount();
    }
    return res.status(201).json({ token, user: sanitizeUser(user) });
  };

  router.post('/auth/register', registerHandler);
  router.post('/auth/signup', registerHandler);

  router.post('/auth/login', async (req, res) => {
    const rawIdentifier = String(req.body.identifier || req.body.email || req.body.phone || '').trim();
    const email = normalizeEmail(rawIdentifier);
    const password = String(req.body.password || '').trim();

    if (!rawIdentifier || !password) {
      return res.status(400).json({ message: 'Email/phone and password are required.' });
    }

    const normalizedPhone = normalizePhone(rawIdentifier);
    const user = rawIdentifier.includes('@')
      ? await User.findOne({ email })
      : await User.findOne({ $or: [{ email }, { phone: normalizedPhone }] });
    if (user) {
      const passwordMatches = await bcrypt.compare(password, user.passwordHash);
      if (!passwordMatches) {
        return res.status(401).json({ message: 'The email or password is not correct. Please try again.' });
      }

      if (user.role === 'admin' && !user.approved) {
        // Admin accounts require explicit approval before elevated access is granted.
        return res.status(403).json({ message: 'Your admin account is waiting for super admin approval. Please try again later.' });
      }

      const token = signToken(user);
      if (user.email === superAdminEmail) {
        // Enforce super-admin authority for the configured owner email even after manual DB edits.
        await syncSuperAdminAccount();
        user.role = 'super_admin';
        user.approved = true;
      }
      return res.json({ token, user: sanitizeUser(user) });
    }

    const driver = rawIdentifier.includes('@')
      ? await Driver.findOne({ email })
      : await Driver.findOne({ $or: [{ email }, { phone: normalizedPhone }] });
    if (!driver) {
      return res.status(401).json({ message: 'The email or password is not correct. Please try again.' });
    }

    const driverPasswordMatches = await bcrypt.compare(password, driver.passwordHash);
    if (!driverPasswordMatches) {
      return res.status(401).json({ message: 'The email or password is not correct. Please try again.' });
    }

    const token = jwt.sign(
      { sub: driver.id, role: 'driver', email: driver.email, phone: driver.phone },
      jwtSecret,
      { expiresIn: '7d' },
    );

    return res.json({
      token,
      user: {
        id: driver.id,
        email: driver.email,
        name: driver.name,
        role: 'driver',
        approved: true,
      },
    });
  });

  router.post('/auth/user', async (req, res) => loginWithRole(req, res, ['user']));
  router.post('/auth/admin', async (req, res) => loginWithRole(req, res, ['admin', 'super_admin']));
  router.post('/auth/driver', async (req, res) => loginWithRole(req, res, ['driver']));

  router.post('/auth/password-reset/request', async (req, res) => {
    const email = normalizeEmail(req.body.email);

    if (!email || !email.includes('@')) {
      return res.status(400).json({ message: 'Please provide a valid email address.' });
    }

    const user = await User.findOne({ email });
    if (!user) {
      return res.status(404).json({ message: 'We could not find an account with that email.' });
    }

    // Six-digit numeric code keeps entry user-friendly on mobile.
    const resetToken = crypto.randomInt(100000, 1000000).toString();
    user.passwordResetTokenHash = hashResetToken(resetToken);
    user.passwordResetExpiresAt = new Date(Date.now() + 15 * 60 * 1000);
    await user.save();

    try {
      await sendPasswordResetEmail({
        to: user.email,
        code: resetToken,
        expiresInMinutes: 15,
      });
    } catch (error) {
      const rawMessage = String(error?.message || '').toLowerCase();
      const smtpLoginFailed = rawMessage.includes('invalid login') || rawMessage.includes('badcredentials');
      return res.status(503).json({
        message: smtpLoginFailed
          ? 'Email delivery is not configured correctly. For Gmail, use a Google App Password in SMTP_PASS (not your normal account password).'
          : (error.message || 'We could not send the reset email right now.'),
      });
    }

    return res.json({
      message: 'We sent a password reset code to your email address. Use it within 15 minutes.',
      expiresAt: user.passwordResetExpiresAt,
    });
  });

  router.post('/auth/password-reset/confirm', async (req, res) => {
    const email = normalizeEmail(req.body.email);
    const token = String(req.body.token || '').trim();
    const newPassword = String(req.body.newPassword || '').trim();

    if (!email || !email.includes('@')) {
      return res.status(400).json({ message: 'Please provide a valid email address.' });
    }
    if (!token) {
      return res.status(400).json({ message: 'Reset code is required.' });
    }
    if (newPassword.length < 6) {
      return res.status(400).json({ message: 'Password must be at least 6 characters long.' });
    }

    const user = await User.findOne({ email });
    if (!user || !user.passwordResetTokenHash || !user.passwordResetExpiresAt) {
      return res.status(400).json({ message: 'The reset code is invalid or has expired.' });
    }

    if (user.passwordResetExpiresAt.getTime() < Date.now()) {
      // Clear expired reset artifacts so old codes cannot be retried.
      user.passwordResetTokenHash = undefined;
      user.passwordResetExpiresAt = undefined;
      await user.save();
      return res.status(410).json({ message: 'The reset code has expired. Please request a new one.' });
    }

    if (user.passwordResetTokenHash !== hashResetToken(token)) {
      return res.status(400).json({ message: 'The reset code is invalid or has expired.' });
    }

    user.passwordHash = await bcrypt.hash(newPassword, 10);
    user.passwordResetTokenHash = undefined;
    user.passwordResetExpiresAt = undefined;
    await user.save();

    return res.json({ message: 'Your password has been updated. You can sign in now.' });
  });

  router.get('/auth/me', auth, async (req, res) => {
    return res.json({ user: sanitizeUser(req.auth.user) });
  });

  router.get('/auth/users', auth, requireSuperAdmin, async (req, res) => {
    // Super-admin can inspect every registered account without exposing sensitive fields.
    const users = await User.find({}).sort({ createdAt: -1, email: 1 });
    return res.json(users.map(sanitizeUser));
  });

  router.get('/auth/admin-accounts', auth, requireSuperAdmin, async (req, res) => {
    // Includes super-admin records so ownership and approvals can be audited in one place.
    const accounts = await User.find({ role: { $in: ['admin', 'super_admin'] } }).sort({ email: 1 });
    return res.json(accounts.map(sanitizeUser));
  });

  router.get('/auth/drivers', auth, requireSuperAdmin, async (req, res) => {
    const { q, status, vehicleType } = req.query;
    const filter = { role: 'driver' };

    if (vehicleType) {
      filter.vehicleType = vehicleType;
    }
    if (q) {
      const pattern = new RegExp(String(q), 'i');
      filter.$or = [{ name: pattern }, { email: pattern }, { phone: pattern }, { vehicleType: pattern }, { licenseNumber: pattern }];
    }

    const users = await User.find(filter).sort({ createdAt: -1 });
    const payload = await Promise.all(users.map((user) => buildDriverPayload(user)));
    const requestedStatus = typeof status === 'string' ? status.trim().toLowerCase() : '';
    if (['available', 'busy', 'offline'].includes(requestedStatus)) {
      return res.json(payload.filter((driver) => driver.currentStatus === requestedStatus));
    }
    return res.json(payload);
  });

  router.get('/auth/drivers/:userId', auth, requireSuperAdmin, async (req, res) => {
    const user = await User.findOne({ id: req.params.userId, role: 'driver' });
    if (!user) {
      return res.status(404).json({ message: 'Driver not found.' });
    }
    return res.json(await buildDriverPayload(user));
  });

  router.post('/auth/drivers', auth, requireSuperAdmin, async (req, res) => {
    const name = String(req.body.name || '').trim();
    const phone = normalizeString(req.body.phone);
    const email = normalizeEmail(req.body.email);
    const password = String(req.body.password || '').trim();
    const vehicleType = normalizeString(req.body.vehicleType);
    const licenseNumber = normalizeString(req.body.licenseNumber);
    const isOnline = !!req.body.isOnline;

    if (!name || (!phone && !email) || !password) {
      return res.status(400).json({ message: 'name, email or phone, and password are required.' });
    }
    if (!vehicleType || !licenseNumber) {
      return res.status(400).json({ message: 'vehicleType and licenseNumber are required.' });
    }

    const existing = await User.findOne({
      role: 'driver',
      $or: [
        ...(email ? [{ email }] : []),
        ...(phone ? [{ phone }] : []),
      ],
    });
    if (existing) {
      return res.status(409).json({ message: 'A driver with this phone or email already exists.' });
    }

    const user = await User.create({
      id: crypto.randomUUID(),
      email: email || undefined,
      phone: phone || undefined,
      name,
      passwordHash: await bcrypt.hash(password, 10),
      role: 'driver',
      approved: true,
      vehicleType,
      licenseNumber,
    });

    return res.status(201).json(await buildDriverPayload(user));
  });

  router.patch('/auth/drivers/:userId', auth, requireSuperAdmin, async (req, res) => {
    const updates = {};
    ['name', 'phone', 'email', 'vehicleType', 'licenseNumber'].forEach((field) => {
      if (Object.prototype.hasOwnProperty.call(req.body, field)) {
        updates[field] = field === 'email'
          ? normalizeEmail(req.body[field])
          : normalizeString(req.body[field]);
      }
    });
    if (Object.prototype.hasOwnProperty.call(req.body, 'isOnline')) {
      updates.isOnline = !!req.body.isOnline;
    }
    if (req.body.password) {
      updates.passwordHash = await bcrypt.hash(String(req.body.password).trim(), 10);
    }

    const user = await User.findOneAndUpdate(
      { id: req.params.userId, role: 'driver' },
      { $set: updates },
      { returnDocument: 'after' },
    );

    if (!user) {
      return res.status(404).json({ message: 'Driver not found.' });
    }

    return res.json(await buildDriverPayload(user));
  });

  router.delete('/auth/drivers/:userId', auth, requireSuperAdmin, async (req, res) => {
    const user = await User.findOneAndDelete({ id: req.params.userId, role: 'driver' });
    if (!user) {
      return res.status(404).json({ message: 'Driver not found.' });
    }

    await Order.updateMany(
      { driverId: user.id },
      { $set: { driverId: null, status: 'pending', outForDeliveryAt: null, deliveredAt: null } },
    );

    return res.json({ message: 'Driver deleted.' });
  });

  // Convenience: expose all users to super admin (already added earlier) - keep for compatibility.

  router.get('/auth/admin-accounts/:userId', auth, requireSuperAdmin, async (req, res) => {
    const user = await User.findOne({ id: req.params.userId, role: { $in: ['admin', 'super_admin'] } });
    if (!user) {
      return res.status(404).json({ message: 'Admin account not found.' });
    }
    return res.json(sanitizeUser(user));
  });

  router.post('/auth/admin-accounts', auth, requireSuperAdmin, async (req, res) => {
    const name = String(req.body.name || '').trim();
    const email = normalizeEmail(req.body.email);
    const password = String(req.body.password || '').trim();

    if (!name) {
      return res.status(400).json({ message: 'Please enter the admin name.' });
    }
    if (!email || !email.includes('@')) {
      return res.status(400).json({ message: 'Please enter a valid admin email address.' });
    }
    if (password.length < 6) {
      return res.status(400).json({ message: 'Admin password must be at least 6 characters long.' });
    }

    const existing = await User.findOne({ email });
    if (existing) {
      return res.status(409).json({ message: 'This email is already registered.' });
    }

    const user = await User.create({
      id: crypto.randomUUID(),
      email,
      name,
      passwordHash: await bcrypt.hash(password, 10),
      role: email === superAdminEmail ? 'super_admin' : 'admin',
      approved: email === superAdminEmail,
    });

    return res.status(201).json(sanitizeUser(user));
  });

  router.patch('/auth/admin-accounts/:userId', auth, requireSuperAdmin, async (req, res) => {
    const name = String(req.body.name || '').trim();
    const email = normalizeEmail(req.body.email);

    const updates = {};
    if (name) {
      updates.name = name;
    }
    if (email) {
      updates.email = email;
    }
    if (Object.keys(updates).length === 0) {
      return res.status(400).json({ message: 'At least one field is required.' });
    }

    const user = await User.findOneAndUpdate(
      { id: req.params.userId, role: { $in: ['admin', 'super_admin'] } },
      { $set: updates },
      { returnDocument: 'after' },
    );

    if (!user) {
      return res.status(404).json({ message: 'Admin account not found.' });
    }

    return res.json(sanitizeUser(user));
  });

  router.post('/auth/admin-accounts/promote', auth, requireSuperAdmin, async (req, res) => {
    const email = normalizeEmail(req.body.email);
    if (!email) {
      return res.status(400).json({ message: 'Email is required.' });
    }

    // Promotion toggles role while preserving user identity and historical records.
    const user = await User.findOneAndUpdate(
      { email },
      {
        $set: {
          role: email === superAdminEmail ? 'super_admin' : 'admin',
          approved: email === superAdminEmail ? true : false,
        },
      },
      { returnDocument: 'after' },
    );

    if (!user) {
      return res.status(404).json({ message: 'No user was found with that email. Ask them to sign up first.' });
    }

    return res.json(sanitizeUser(user));
  });

  router.patch('/auth/admin-accounts/:userId/approval', auth, requireSuperAdmin, async (req, res) => {
    const approved = req.body.approved;
    if (typeof approved !== 'boolean') {
      return res.status(400).json({ message: 'approved must be true or false.' });
    }

    const user = await User.findOneAndUpdate(
      { id: req.params.userId, role: 'admin' },
      { $set: { approved } },
      { returnDocument: 'after' },
    );

    if (!user) {
      return res.status(404).json({ message: 'Admin account not found.' });
    }

    return res.json(sanitizeUser(user));
  });

  router.delete('/auth/admin-accounts/:userId/admin-access', auth, requireSuperAdmin, async (req, res) => {
    const user = await User.findOneAndUpdate(
      { id: req.params.userId },
      { $set: { role: 'user', approved: true } },
      { returnDocument: 'after' },
    );

    if (!user) {
      return res.status(404).json({ message: 'User not found.' });
    }

    return res.status(204).send();
  });

  return router;
}

module.exports = {
  createAuthRouter,
};
