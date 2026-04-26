// Handles payment verification flows and links payment records back to orders.
const express = require('express');
const { Order, PaymentRecord } = require('../models');
const { serializeDocument } = require('../utils/persistence');

function createPaymentsRouter() {
  const router = express.Router();

  router.post('/payments/:paymentId/verify', async (req, res) => {
    const now = new Date();
    const { paymentId } = req.params;
    const transactionReference = typeof req.body.transactionReference === 'string'
      ? req.body.transactionReference.trim()
      : '';

    // Backfill mode: if payment record is missing, attempt to reconstruct from order payload.
    let payment = await PaymentRecord.findOne({ id: paymentId });
    let matchingOrder = null;

    if (!payment) {
      matchingOrder = await Order.findOne({ 'payment.id': paymentId });
    }

    if (!payment) {
      const fallbackOrderId = matchingOrder?.id ?? req.body.orderId ?? `order-${paymentId}`;
      payment = new PaymentRecord({
        id: paymentId,
        orderId: fallbackOrderId,
        method: req.body.method ?? matchingOrder?.payment?.method ?? 'telebirr',
        methodLabel: req.body.methodLabel ?? matchingOrder?.payment?.methodLabel ?? null,
        amount: req.body.amount ?? matchingOrder?.payment?.amount ?? 0,
        status: 'verified',
        transactionReference,
        createdAt: now,
        verifiedAt: now,
      });
    } else {
      payment.status = 'verified';
      payment.transactionReference = transactionReference || payment.transactionReference;
      payment.verifiedAt = now;
    }

    // Persist authoritative verification status for both payment and order documents.
    await payment.save();

    const order = await Order.findOneAndUpdate(
      { 'payment.id': paymentId },
      {
        $set: {
          'payment.status': 'verified',
          'payment.transactionReference': payment.transactionReference,
          'payment.verifiedAt': now,
        },
      },
      { returnDocument: 'after' },
    );

    if (order && payment.orderId !== order.id) {
      payment.orderId = order.id;
      await payment.save();
    }

    res.json(serializeDocument(payment));
  });

  return router;
}

module.exports = {
  createPaymentsRouter,
};

