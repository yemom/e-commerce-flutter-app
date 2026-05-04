// Handles product CRUD

const express = require("express");
const { Product } = require("../models");
const {
  escapeRegex,
  normalizePatch,
  serializeDocument,
  upsertById,
} = require("../utils/persistence");
const { requireFields } = require("../utils/validation");

function createProductsRouter() {
  const router = express.Router();

  // GET products
  router.get("/products", async (req, res) => {
    const { query } = req.query;

    const filter = query
      ? { name: { $regex: escapeRegex(query), $options: "i" } }
      : {};

    const products = await Product.find(filter);
    res.json(products.map(serializeDocument));
  });

  // GET single
  router.get("/products/:id", async (req, res) => {
    const product = await Product.findOne({ id: req.params.id });
    if (!product) return res.status(404).json({ message: "Not found" });

    res.json(serializeDocument(product));
  });

  // CREATE
  router.post("/products", async (req, res) => {
    requireFields(req.body, ["id", "name", "categoryId"]);

    const product = await upsertById(Product, req.body.id, {
      ...req.body,
      imageUrls: req.body.imageUrls || [],
    });

    res.status(201).json(serializeDocument(product));
  });

  // UPDATE
  router.patch("/products/:id", async (req, res) => {
    const product = await Product.findOneAndUpdate(
      { id: req.params.id },
      normalizePatch(req.body),
      { new: true },
    );

    res.json(serializeDocument(product));
  });

  // DELETE
  router.delete("/products/:id", async (req, res) => {
    await Product.deleteOne({ id: req.params.id });
    res.status(204).send();
  });

  return router;
}

module.exports = { createProductsRouter };
