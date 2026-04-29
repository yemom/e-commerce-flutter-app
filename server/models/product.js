// Defines the MongoDB schema for products, stock, branches, and color options.
const mongoose = require('mongoose');
const { colorOptionSchema } = require('./shared');

const productSchema = new mongoose.Schema(
  {
    id: { type: String, required: true, unique: true, trim: true },
    name: { type: String, required: true, trim: true },
    description: { type: String, default: '', trim: true },
    imageUrl: { type: String, default: '', trim: true },
    imageUrls: { type: [String], default: [] },
    price: { type: Number, required: true, min: 0 },
    categoryId: { type: String, required: true, trim: true },
    branchIds: { type: [String], default: [] },
    stockByBranch: { type: Map, of: Number, default: {} },
    isAvailable: { type: Boolean, default: true },
    availableSizes: { type: [String], default: [] },
    availableColors: { type: [colorOptionSchema], default: [] },
    selectedSize: { type: String, default: null },
    selectedColor: { type: colorOptionSchema, default: null },
  },
  { collection: 'products', timestamps: true },
);

module.exports = mongoose.models.Product || mongoose.model('Product', productSchema);

