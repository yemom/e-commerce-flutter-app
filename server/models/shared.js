// Holds reusable MongoDB sub-schemas shared by products, orders, and payments.
const mongoose = require('mongoose');
const { PAYMENT_STATUSES } = require('../constants/statuses');

const colorOptionSchema = new mongoose.Schema(
  {
    name: { type: String, required: true, trim: true },
    hexCode: { type: String, required: true, trim: true },
  },
  { _id: false },
);

const paymentSchema = new mongoose.Schema(
  {
    id: { type: String, required: true, trim: true },
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
  { _id: false },
);

const orderItemSchema = new mongoose.Schema(
  {
    productId: { type: String, required: true, trim: true },
    productName: { type: String, required: true, trim: true },
    quantity: { type: Number, required: true, min: 1 },
    unitPrice: { type: Number, required: true, min: 0 },
  },
  { _id: false },
);

module.exports = {
  colorOptionSchema,
  paymentSchema,
  orderItemSchema,
};

