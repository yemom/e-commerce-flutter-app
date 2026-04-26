// Handles signup, login, password reset, profile lookup, and admin account management routes.
const crypto = require('crypto');
const express = require('express');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');

const { jwtSecret, superAdminEmail } = require('../config/env');
const { createAuthMiddleware, requireSuperAdmin } = require('../middleware/auth');
const { User } = require('../models');
const { sendPasswordResetEmail } = require('../utils/mailer');
const { syncSuperAdminAccount } = require('../utils/super-admin');

function normalizeEmail(value) {
  // Keep email comparisons stable across signup/login flows.
  return String(value || '').trim().toLowerCase();
}

function hashResetToken(token) {
  // Store only a hash of reset tokens so raw codes are never persisted.
  return crypto.createHash('sha256').update(String(token)).digest('hex');
}

function sanitizeUser(userDoc) {
  // Never expose password hashes or internal fields to API consumers.
  return {
    id: userDoc.id,
    email: userDoc.email,
    name: userDoc.name,
    role: userDoc.role,
    approved: userDoc.approved,
  };
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

function createAuthRouter() {
  const router = express.Router();
  const auth = createAuthMiddleware();

  router.post('/auth/signup', async (req, res) => {
    const fullName = String(req.body.fullName || '').trim();
    const email = normalizeEmail(req.body.email);
    const password = String(req.body.password || '').trim();

    if (!email || !email.includes('@')) {
      return res.status(400).json({ message: 'Please provide a valid email address.' });
    }
    if (password.length < 6) {
      return res.status(400).json({ message: 'Password must be at least 6 characters long.' });
    }

    const existing = await User.findOne({ email });
    if (existing) {
      return res.status(409).json({ message: 'This email is already registered. Please sign in instead.' });
    }

    // Super-admin account is tied to the configured email; all others start as regular users.
    const role = email === superAdminEmail ? 'super_admin' : 'user';
    const approved = role !== 'admin';
    const passwordHash = await bcrypt.hash(password, 10);

    const user = await User.create({
      id: crypto.randomUUID(),
      email,
      name: fullName || email.split('@')[0],
      passwordHash,
      role,
      approved,
    });

    const token = signToken(user);
    if (user.email === superAdminEmail) {
      // Keep bootstrapped super-admin record synchronized with env configuration.
      await syncSuperAdminAccount();
    }
    return res.status(201).json({ token, user: sanitizeUser(user) });
  });

  router.post('/auth/login', async (req, res) => {
    const email = normalizeEmail(req.body.email);
    const password = String(req.body.password || '').trim();

    if (!email || !password) {
      return res.status(400).json({ message: 'Email and password are required.' });
    }

    const user = await User.findOne({ email });
    if (!user) {
      return res.status(401).json({ message: 'The email or password is not correct. Please try again.' });
    }

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
  });

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

  router.get('/auth/admin-accounts', auth, requireSuperAdmin, async (req, res) => {
    // Includes super-admin records so ownership and approvals can be audited in one place.
    const accounts = await User.find({ role: { $in: ['admin', 'super_admin'] } }).sort({ email: 1 });
    return res.json(accounts.map(sanitizeUser));
  });

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
