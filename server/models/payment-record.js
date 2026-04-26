// Defines the MongoDB schema for recorded payment attempts and verification results.
const mongoose = require('mongoose');
const { PAYMENT_STATUSES } = require('../constants/statuses');

const paymentRecordSchema = new mongoose.Schema(
  {
    id: { type: String, required: true, unique: true, trim: true },
    orderId: { type: String, required: true, trim: true },
    method: { type: String, required: true, trim: true },
    methodLabel: { type: String, trim: true },
    amount: { type: Number, required: true, min: 0 },
    status: {
      type: String,
      enum: PAYMENT_STATUSES,
      default: 'pending',
    },
    transactionReference: { type: String, default: '', trim: true },
    createdAt: { type: Date, default: Date.now },
    verifiedAt: { type: Date, default: null },
  },
  { collection: 'payments', timestamps: true },
);

module.exports =
  mongoose.models.PaymentRecord || mongoose.model('PaymentRecord', paymentRecordSchema);

