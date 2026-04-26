// Handles branch CRUD-style routes and branch inventory assignment updates.
const express = require('express');
const { Branch, Product } = require('../models');
const { serializeDocument, upsertById } = require('../utils/persistence');
const { requireFields } = require('../utils/validation');

function createBranchesRouter() {
  const router = express.Router();

  router.get('/branches', async (req, res) => {
    const branches = await Branch.find().sort({ name: 1 });
    res.json(branches.map(serializeDocument));
  });

  router.post('/branches', async (req, res) => {
    requireFields(req.body, ['id', 'name']);
    const branch = await upsertById(Branch, req.body.id, {
      id: req.body.id,
      name: req.body.name,
      location: req.body.location ?? '',
      phoneNumber: req.body.phoneNumber ?? '',
      isActive: req.body.isActive ?? true,
    });

    res.status(201).json(serializeDocument(branch));
  });

  router.delete('/branches/:branchId', async (req, res) => {
    const { branchId } = req.params;
    const deleted = await Branch.findOneAndDelete({ id: branchId });

    if (!deleted) {
      return res.status(404).json({ message: 'Branch not found.' });
    }

    // Remove stale branch references from products to keep inventory data consistent.
    await Product.updateMany(
      { branchIds: branchId },
      {
        $pull: { branchIds: branchId },
        $unset: { [`stockByBranch.${branchId}`]: '' },
      },
    );

    return res.status(204).send();
  });

  router.patch('/branches/:branchId/inventory', async (req, res) => {
    const { branchId } = req.params;
    const { productId, quantity } = req.body;

    if (!productId || typeof productId !== 'string') {
      return res.status(400).json({ message: 'productId is required.' });
    }
    if (!Number.isInteger(quantity) || quantity < 0) {
      return res.status(400).json({ message: 'quantity must be an integer greater than or equal to 0.' });
    }

    // Inventory updates auto-attach the branch to the product if it was missing.
    const product = await Product.findOneAndUpdate(
      { id: productId },
      {
        $addToSet: { branchIds: branchId },
        $set: { [`stockByBranch.${branchId}`]: quantity },
      },
      { returnDocument: 'after' },
    );

    if (!product) {
      return res.status(404).json({ message: 'Product not found.' });
    }

    return res.status(204).send();
  });

  return router;
}

module.exports = {
  createBranchesRouter,
};

