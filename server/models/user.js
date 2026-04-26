// Defines the MongoDB schema for customers, admins, and super admin accounts.
const mongoose = require('mongoose');

const userSchema = new mongoose.Schema(
  {
    id: { type: String, required: true, unique: true, trim: true },
    email: { type: String, required: true, unique: true, trim: true, lowercase: true },
    name: { type: String, required: true, trim: true },
    passwordHash: { type: String, required: true },
    passwordResetTokenHash: { type: String },
    passwordResetExpiresAt: { type: Date },
    role: {
      type: String,
      enum: ['super_admin', 'admin', 'user'],
      default: 'user',
    },
    approved: { type: Boolean, default: true },
    createdAt: { type: Date, default: Date.now },
    updatedAt: { type: Date, default: Date.now },
  },
  { collection: 'users', timestamps: true },
);

module.exports = mongoose.models.User || mongoose.model('User', userSchema);
