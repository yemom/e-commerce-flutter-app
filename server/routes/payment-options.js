// Handles payment option listing and admin updates for available payment methods.
const express = require('express');
const { PaymentOption } = require('../models');
const { normalizePatch, serializeDocument, upsertById } = require('../utils/persistence');
const { requireFields } = require('../utils/validation');

function createPaymentOptionsRouter() {
  const router = express.Router();

  router.get('/payment-options', async (req, res) => {
    // Storefront callers get enabled options only; admin tools can request full list.
    const includeDisabled = req.query.includeDisabled === 'true';
    const filter = includeDisabled ? {} : { isEnabled: true };
    const options = await PaymentOption.find(filter).sort({ label: 1 });
    res.json(options.map(serializeDocument));
  });

  router.post('/payment-options', async (req, res) => {
    requireFields(req.body, ['id', 'method', 'label']);
    const option = await upsertById(PaymentOption, req.body.id, {
      id: req.body.id,
      method: req.body.method,
      label: req.body.label,
      isEnabled: req.body.isEnabled ?? true,
      iconUrl: req.body.iconUrl ?? null,
    });

    res.status(201).json(serializeDocument(option));
  });

  router.patch('/payment-options/:optionId', async (req, res) => {
    const option = await PaymentOption.findOneAndUpdate(
      { id: req.params.optionId },
      normalizePatch(req.body),
      { returnDocument: 'after' },
    );

    if (!option) {
      return res.status(404).json({ message: 'Payment option not found.' });
    }

    return res.json(serializeDocument(option));
  });

  router.delete('/payment-options/:optionId', async (req, res) => {
    await PaymentOption.deleteOne({ id: req.params.optionId });
    res.status(204).send();
  });

  return router;
}

module.exports = {
  createPaymentOptionsRouter,
};

