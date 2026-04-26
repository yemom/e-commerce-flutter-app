// Handles order creation, listing, status updates, and payment state changes.
const express = require('express');
const { ORDER_STATUSES, PAYMENT_STATUSES } = require('../constants/statuses');
const { Order, PaymentRecord } = require('../models');
const { serializeDocument, upsertById } = require('../utils/persistence');
const { requireFields } = require('../utils/validation');

function createOrdersRouter() {
  const router = express.Router();

  router.get('/orders', async (req, res) => {
    const { branchId, status } = req.query;
    const filter = {};

    if (branchId) {
      filter.branchId = branchId;
    }
    if (status) {
      filter.status = status;
    }

    const orders = await Order.find(filter).sort({ createdAt: -1 });
    res.json(orders.map(serializeDocument));
  });

  router.post('/orders', async (req, res) => {
    requireFields(req.body, ['id', 'branchId', 'customerId', 'payment']);

    // Normalize incoming timestamps and force initial payment status to pending.
    const createdAt = req.body.createdAt ? new Date(req.body.createdAt) : new Date();
    const payment = {
      ...req.body.payment,
      orderId: req.body.id,
      status: 'pending',
      createdAt: req.body.payment?.createdAt ? new Date(req.body.payment.createdAt) : createdAt,
      verifiedAt: req.body.payment?.verifiedAt ? new Date(req.body.payment.verifiedAt) : null,
    };

    // Orders are confirmed at creation in this flow; fulfillment updates happen later via PATCH.
    const order = await upsertById(Order, req.body.id, {
      id: req.body.id,
      branchId: req.body.branchId,
      customerId: req.body.customerId,
      items: req.body.items ?? [],
      status: 'confirmed',
      payment,
      subtotal: req.body.subtotal ?? 0,
      deliveryFee: req.body.deliveryFee ?? 0,
      total: req.body.total ?? 0,
      createdAt,
    });

    // Keep a dedicated payment record in sync for payment-center/admin workflows.
    await upsertById(PaymentRecord, payment.id, {
      id: payment.id,
      orderId: req.body.id,
      method: payment.method,
      methodLabel: payment.methodLabel ?? null,
      amount: payment.amount ?? 0,
      status: payment.status,
      transactionReference: payment.transactionReference ?? '',
      createdAt: payment.createdAt,
      verifiedAt: payment.verifiedAt,
    });

    res.status(201).json(serializeDocument(order));
  });

  router.patch('/orders/:orderId', async (req, res) => {
    const status = req.body.status;
    if (!ORDER_STATUSES.includes(status)) {
      return res.status(400).json({ message: 'A valid order status is required.' });
    }

    const order = await Order.findOneAndUpdate(
      { id: req.params.orderId },
      { status },
      { returnDocument: 'after' },
    );

    if (!order) {
      return res.status(404).json({ message: 'Order not found.' });
    }

    return res.json(serializeDocument(order));
  });

  router.patch('/orders/:orderId/payment', async (req, res) => {
    const paymentStatus = req.body.paymentStatus;
    if (!PAYMENT_STATUSES.includes(paymentStatus)) {
      return res.status(400).json({ message: 'A valid payment status is required.' });
    }

    // Reflect payment status in embedded order payment object and transaction metadata.
    const update = {
      'payment.status': paymentStatus,
      'payment.verifiedAt': paymentStatus === 'verified' ? new Date() : null,
    };

    if (typeof req.body.transactionReference === 'string') {
      update['payment.transactionReference'] = req.body.transactionReference;
    }

    const order = await Order.findOneAndUpdate(
      { id: req.params.orderId },
      { $set: update },
      { returnDocument: 'after' },
    );

    if (!order) {
      return res.status(404).json({ message: 'Order not found.' });
    }

    // Mirror changes into PaymentRecord collection so both read models stay aligned.
    await PaymentRecord.findOneAndUpdate(
      { id: order.payment.id },
      {
        $set: {
          status: paymentStatus,
          transactionReference: order.payment.transactionReference,
          verifiedAt: order.payment.verifiedAt,
        },
      },
      { returnDocument: 'after' },
    );

    return res.json(serializeDocument(order));
  });

  return router;
}

module.exports = {
  createOrdersRouter,
};

