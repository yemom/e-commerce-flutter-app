// Driver schema for delivery personnel
const mongoose = require('mongoose');

const driverSchema = new mongoose.Schema(
  {
    id: { type: String, required: true, unique: true, trim: true },
    name: { type: String, required: true, trim: true },
    phone: { type: String, required: true, unique: true, trim: true },
    email: { type: String, unique: true, sparse: true, trim: true, lowercase: true },
    passwordHash: { type: String, required: true },
    vehicleType: { type: String, trim: true },
    licenseNumber: { type: String, trim: true },
    isOnline: { type: Boolean, default: false },
    // Last known location reported by the driver app.
    lastLocation: {
      lat: { type: Number },
      lng: { type: Number },
      updatedAt: { type: Date },
    },
    createdAt: { type: Date, default: Date.now },
    updatedAt: { type: Date, default: Date.now },
  },
  { collection: 'drivers', timestamps: true },
);

module.exports = mongoose.models.Driver || mongoose.model('Driver', driverSchema);
