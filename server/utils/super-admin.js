// Creates or refreshes the bootstrap super admin account used to manage the system.
const crypto = require('crypto');
const bcrypt = require('bcryptjs');

const { superAdminEmail, superAdminPassword } = require('../config/env');
const { User } = require('../models');

async function syncSuperAdminAccount() {
  // Ensure exactly one canonical super-admin identity exists from env settings.
  const user = await User.findOne({ email: superAdminEmail });
  if (!user) {
    const passwordHash = await bcrypt.hash(superAdminPassword, 10);
    return User.create({
      id: crypto.randomUUID(),
      email: superAdminEmail,
      name: 'Super Admin',
      passwordHash,
      role: 'super_admin',
      approved: true,
    });
  }

  const passwordMatches = await bcrypt.compare(superAdminPassword, user.passwordHash);

  // Self-heal role/approval/password drift if records were changed manually.
  if (user.role !== 'super_admin' || user.approved !== true || !passwordMatches) {
    user.role = 'super_admin';
    user.approved = true;
    if (!passwordMatches) {
      user.passwordHash = await bcrypt.hash(superAdminPassword, 10);
    }
    await user.save();
  }

  return user;
}

module.exports = {
  syncSuperAdminAccount,
};
