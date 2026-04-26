// Defines the MongoDB schema for payment methods that admins can enable or configure.
const mongoose = require('mongoose');

const paymentOptionSchema = new mongoose.Schema(
  {
    id: { type: String, required: true, unique: true, trim: true },
    method: { type: String, required: true, trim: true },
    label: { type: String, required: true, trim: true },
    isEnabled: { type: Boolean, default: true },
    iconUrl: { type: String, default: null, trim: true },
  },
  { collection: 'payment_options', timestamps: true },
);

module.exports =
  mongoose.models.PaymentOption || mongoose.model('PaymentOption', paymentOptionSchema);

