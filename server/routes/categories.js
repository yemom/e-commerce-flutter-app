// Handles category listing, creation, updates, and deletion routes.
const express = require('express');
const { Category } = require('../models');
const { normalizePatch, serializeDocument, upsertById } = require('../utils/persistence');
const { requireFields } = require('../utils/validation');

function createCategoriesRouter() {
  const router = express.Router();

  router.get('/categories', async (req, res) => {
    const categories = await Category.find().sort({ name: 1 });
    res.json(categories.map(serializeDocument));
  });

  router.post('/categories', async (req, res) => {
    requireFields(req.body, ['id', 'name']);
    // Accept both imageUrl and legacy image field for backward compatibility.
    const category = await upsertById(Category, req.body.id, {
      id: req.body.id,
      name: req.body.name,
      description: req.body.description ?? '',
      imageUrl: req.body.imageUrl ?? req.body.image ?? '',
      isActive: req.body.isActive ?? true,
    });

    res.status(201).json(serializeDocument(category));
  });

  router.patch('/categories/:categoryId', async (req, res) => {
    const category = await Category.findOneAndUpdate(
      { id: req.params.categoryId },
      normalizePatch(req.body),
      { returnDocument: 'after' },
    );

    if (!category) {
      return res.status(404).json({ message: 'Category not found.' });
    }

    return res.json(serializeDocument(category));
  });

  router.delete('/categories/:categoryId', async (req, res) => {
    await Category.deleteOne({ id: req.params.categoryId });
    res.status(204).send();
  });

  return router;
}

module.exports = {
  createCategoriesRouter,
};

