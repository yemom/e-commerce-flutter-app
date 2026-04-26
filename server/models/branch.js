// Defines the MongoDB schema for store branches and their contact details.
const mongoose = require('mongoose');

const branchSchema = new mongoose.Schema(
  {
    id: { type: String, required: true, unique: true, trim: true },
    name: { type: String, required: true, trim: true },
    location: { type: String, default: '', trim: true },
    phoneNumber: { type: String, default: '', trim: true },
    isActive: { type: Boolean, default: true },
  },
  { collection: 'branches', timestamps: true },
);

module.exports = mongoose.models.Branch || mongoose.model('Branch', branchSchema);

