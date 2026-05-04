// Defines the MongoDB schema for customer orders and their delivery or payment state.
const mongoose = require('mongoose');
const { ORDER_STATUSES } = require('../constants/statuses');
const { paymentSchema, orderItemSchema } = require('./shared');

const orderSchema = new mongoose.Schema(
  {
    id: { type: String, required: true, unique: true, trim: true },
    branchId: { type: String, required: true, trim: true },
    customerId: { type: String, required: true, trim: true },
    customerName: { type: String, trim: true, default: '' },
    customerEmail: { type: String, trim: true, lowercase: true, default: '' },
    deliveryAddress: {
      type: mongoose.Schema.Types.Mixed,
      default: {},
    },
    items: { type: [orderItemSchema], default: [] },
    status: {
      type: String,
      enum: ORDER_STATUSES,
      default: 'confirmed',
    },
    payment: { type: paymentSchema, required: true },
    driverId: { type: String, trim: true, default: null },
    outForDeliveryAt: { type: Date, default: null },
    deliveredAt: { type: Date, default: null },
    subtotal: { type: Number, required: true, min: 0 },
    deliveryFee: { type: Number, required: true, min: 0 },
    total: { type: Number, required: true, min: 0 },
    createdAt: { type: Date, default: Date.now },
  },
  { collection: 'orders', timestamps: true },
);

module.exports = mongoose.models.Order || mongoose.model('Order', orderSchema);
