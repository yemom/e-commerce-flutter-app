// Loads environment variables and exposes the backend settings used across the server.
const path = require('path');
const dotenv = require('dotenv');

// Always load environment values from server/.env.
dotenv.config({ path: path.resolve(__dirname, '..', '.env') });

// Core runtime values.
const port = Number(process.env.PORT || 8000);
const mongoUri = process.env.MONGODB_URI || '';
const jwtSecret = process.env.JWT_SECRET || 'dev-only-change-this-secret';

// Super-admin bootstrap values used at startup.
const superAdminEmail = (process.env.SUPER_ADMIN_EMAIL || '12yemom@gmail.com').trim().toLowerCase();
const superAdminPassword = (process.env.SUPER_ADMIN_PASSWORD || 'Admin@1234!').trim();

// SMTP values used for password reset / mail features.
const smtpHost = (process.env.SMTP_HOST || '').trim();
const smtpPort = Number(process.env.SMTP_PORT || 587);
const smtpSecure = String(process.env.SMTP_SECURE || '').trim().toLowerCase() === 'true';
const smtpUser = (process.env.SMTP_USER || '').trim();
const smtpPass = (process.env.SMTP_PASS || '').trim();
const emailFrom = (process.env.EMAIL_FROM || smtpUser || '').trim();

// User-facing app name included in outbound messages.
const appName = (process.env.APP_NAME || 'Kutuku').trim();

// Accept comma-separated origins in .env and normalize to a clean list.
const corsOrigins = (process.env.CORS_ORIGIN || '*')
  .split(',')
  .map((value) => value.trim())
  .filter(Boolean);

module.exports = {
  port,
  mongoUri,
  jwtSecret,
  superAdminEmail,
  superAdminPassword,
  smtpHost,
  smtpPort,
  smtpSecure,
  smtpUser,
  smtpPass,
  emailFrom,
  appName,
  corsOrigins,
};

