// Sends transactional emails such as password reset messages using the configured mail service.
const nodemailer = require('nodemailer');

const {
  appName,
  emailFrom,
  smtpHost,
  smtpPass,
  smtpPort,
  smtpSecure,
  smtpUser,
} = require('../config/env');

function hasSmtpConfiguration() {
  // All values are required because transporter and sender depend on each one.
  return Boolean(smtpHost && smtpPort && smtpUser && smtpPass && emailFrom);
}

function createTransporter() {
  if (!hasSmtpConfiguration()) {
    throw new Error('SMTP is not configured. Set SMTP_HOST, SMTP_PORT, SMTP_USER, SMTP_PASS, and EMAIL_FROM in server/.env.');
  }

  return nodemailer.createTransport({
    host: smtpHost,
    port: smtpPort,
    secure: smtpSecure,
    auth: {
      user: smtpUser,
      pass: smtpPass,
    },
  });
}

async function sendPasswordResetEmail({ to, code, expiresInMinutes }) {
  // Build transporter per send to ensure latest env settings are respected.
  const transporter = createTransporter();

  await transporter.sendMail({
    from: `${appName} <${emailFrom}>`,
    to,
    subject: `${appName} password reset code`,
    text: [
      `Your ${appName} password reset code is: ${code}`,
      '',
      `This code expires in ${expiresInMinutes} minutes.`,
      'If you did not request this, you can ignore this email.',
    ].join('\n'),
    html: `
      <div style="font-family:Arial,sans-serif;line-height:1.5;color:#0f172a">
        <h2 style="margin:0 0 12px">${appName} password reset</h2>
        <p>Your password reset code is:</p>
        <div style="display:inline-block;padding:12px 18px;border-radius:10px;background:#f1f5f9;font-size:24px;font-weight:700;letter-spacing:4px;">${code}</div>
        <p style="margin-top:16px">This code expires in ${expiresInMinutes} minutes.</p>
        <p>If you did not request this, you can ignore this email.</p>
      </div>
    `,
  });
}

module.exports = {
  hasSmtpConfiguration,
  sendPasswordResetEmail,
};
