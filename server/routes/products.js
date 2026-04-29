// Handles product listing, creation, updates, deletion, and branch stock assignments.
const express = require('express');
const { Product } = require('../models');
const {
  escapeRegex,
  normalizePatch,
  serializeDocument,
  upsertById,
} = require('../utils/persistence');
const { requireFields } = require('../utils/validation');

function createProductsRouter() {
  const router = express.Router();

  router.get('/products', async (req, res) => {
    const { branchId, categoryId, query, includeUnavailable } = req.query;
    const filter = {};

    // Default storefront behavior hides unavailable products unless explicitly requested.
    if (includeUnavailable !== 'true') {
      filter.isAvailable = true;
    }
    if (branchId) {
      filter.branchIds = branchId;
    }
    if (categoryId) {
      filter.categoryId = categoryId;
    }
    // Query matches both name and description using escaped regex to avoid pattern injection.
    if (query) {
      filter.$or = [
        { name: { $regex: escapeRegex(query), $options: 'i' } },
        { description: { $regex: escapeRegex(query), $options: 'i' } },
      ];
    }

    const products = await Product.find(filter).sort({ name: 1 });
    res.json(products.map(serializeDocument));
  });

  router.get('/products/:productId', async (req, res) => {
    const product = await Product.findOne({ id: req.params.productId });

    if (!product) {
      return res.status(404).json({ message: 'Product not found.' });
    }

    // Return the full stored document so the detail screen can render the latest image gallery.
    return res.json(serializeDocument(product));
  });

  router.post('/products', async (req, res) => {
    requireFields(req.body, ['id', 'name', 'categoryId']);
    // Upsert allows idempotent product creation from admin tooling.
    const product = await upsertById(Product, req.body.id, {
      id: req.body.id,
      name: req.body.name,
      description: req.body.description ?? '',
      imageUrl: req.body.imageUrl ?? '',
      imageUrls: req.body.imageUrls ?? [],
      price: req.body.price ?? 0,
      categoryId: req.body.categoryId,
      branchIds: req.body.branchIds ?? [],
      stockByBranch: req.body.stockByBranch ?? {},
      isAvailable: req.body.isAvailable ?? true,
      availableSizes: req.body.availableSizes ?? [],
      availableColors: req.body.availableColors ?? [],
      selectedSize: req.body.selectedSize ?? null,
      selectedColor: req.body.selectedColor ?? null,
    });

    res.status(201).json(serializeDocument(product));
  });

  router.patch('/products/:productId', async (req, res) => {
    const product = await Product.findOneAndUpdate(
      { id: req.params.productId },
      normalizePatch(req.body),
      { returnDocument: 'after' },
    );

    if (!product) {
      return res.status(404).json({ message: 'Product not found.' });
    }

    return res.json(serializeDocument(product));
  });

  router.delete('/products/:productId', async (req, res) => {
    await Product.deleteOne({ id: req.params.productId });
    res.status(204).send();
  });

  router.patch('/products/:productId/branches/:branchId', async (req, res) => {
    const { productId, branchId } = req.params;
    const { quantity } = req.body;

    if (!Number.isInteger(quantity) || quantity < 0) {
      return res.status(400).json({ message: 'quantity must be an integer greater than or equal to 0.' });
    }

    // Keep branch membership and stock quantity in sync in a single atomic update.
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

    return res.json(serializeDocument(product));
  });

  return router;
}

module.exports = {
  createProductsRouter,
};

