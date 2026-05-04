// Defines the MongoDB schema for customers, admins, and super admin accounts.
const mongoose = require('mongoose');

const userSchema = new mongoose.Schema(
  {
    id: { type: String, required: true, unique: true, trim: true },
    email: { type: String, unique: true, sparse: true, trim: true, lowercase: true },
    phone: { type: String, unique: true, sparse: true, trim: true },
    name: { type: String, required: true, trim: true },
    passwordHash: { type: String, required: true },
    vehicleType: { type: String, trim: true, default: '' },
    licenseNumber: { type: String, trim: true, default: '' },
    passwordResetTokenHash: { type: String },
    passwordResetExpiresAt: { type: Date },
    role: {
      type: String,
      enum: ['super_admin', 'admin', 'user', 'driver'],
      default: 'user',
    },
    approved: { type: Boolean, default: true },
    addresses: {
      type: [
        {
          id: { type: String, required: true, trim: true },
          label: { type: String, trim: true },
          line1: { type: String, required: true, trim: true },
          line2: { type: String, trim: true },
          city: { type: String, trim: true },
          state: { type: String, trim: true },
          postalCode: { type: String, trim: true },
          country: { type: String, trim: true },
        }
      ],
      default: [],
    },
    createdAt: { type: Date, default: Date.now },
    updatedAt: { type: Date, default: Date.now },
  },
  { collection: 'users', timestamps: true },
);

userSchema.path('email').validate(function validateEmailOrPhone() {
  return Boolean((this.email && String(this.email).trim()) || (this.phone && String(this.phone).trim()));
}, 'Either email or phone is required.');

module.exports = mongoose.models.User || mongoose.model('User', userSchema);
