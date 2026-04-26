// Defines the MongoDB schema for product categories shown in the app.
const mongoose = require('mongoose');

const categorySchema = new mongoose.Schema(
  {
    id: { type: String, required: true, unique: true, trim: true },
    name: { type: String, required: true, trim: true },
    description: { type: String, default: '', trim: true },
    imageUrl: { type: String, default: '', trim: true },
    isActive: { type: Boolean, default: true },
  },
  { collection: 'categories', timestamps: true },
);

module.exports = mongoose.models.Category || mongoose.model('Category', categorySchema);

