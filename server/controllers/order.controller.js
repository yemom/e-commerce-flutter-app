// Handles order creation, listing, status updates, and payment state changes.

const express = require("express");
const jwt = require("jsonwebtoken");
const { jwtSecret } = require("../config/env");
const { ORDER_STATUSES, PAYMENT_STATUSES } = require("../constants/statuses");
const { Driver, Order, PaymentRecord, User } = require("../models");
const {
  createAuthMiddleware,
  requireSuperAdmin,
} = require("../middleware/auth");
const { serializeDocument, upsertById } = require("../utils/persistence");
const { requireFields } = require("../utils/validation");

function normalizeString(value) {
  return typeof value === "string" ? value.trim() : "";
}

function normalizeDeliveryAddress(value, fallbackAddresses = []) {
  let source = null;

  if (typeof value === "string" && value.trim()) {
    source = { line1: value.trim() };
  } else if (value && typeof value === "object") {
    source = value;
  }

  if (!source) {
    source = fallbackAddresses?.[0] || {};
  }

  return {
    label: normalizeString(source.label),
    line1: normalizeString(source.line1 || source.details || source.address),
    city: normalizeString(source.city),
    country: normalizeString(source.country),
    lat: Number(source.lat) || undefined,
    lng: Number(source.lng) || undefined,
  };
}

async function authenticateDeliveryActor(req) {
  const token = req.headers.authorization?.split(" ")[1];
  if (!token) return { error: { status: 401, message: "Token required" } };

  try {
    const payload = jwt.verify(token, jwtSecret);

    if (payload.role === "driver") {
      const driver = await Driver.findOne({ id: payload.sub });
      if (!driver)
        return { error: { status: 403, message: "Driver not found" } };
      return { payload, actorType: "driver" };
    }

    const user = await User.findOne({ id: payload.sub });
    if (!user || !["admin", "super_admin"].includes(user.role)) {
      return { error: { status: 403, message: "Unauthorized" } };
    }

    return { payload, actorType: "admin" };
  } catch {
    return { error: { status: 401, message: "Invalid token" } };
  }
}

function createOrdersRouter() {
  const router = express.Router();

  // GET Orders
  router.get("/orders", async (req, res) => {
    const orders = await Order.find().sort({ createdAt: -1 });
    res.json(orders.map(serializeDocument));
  });

  // CREATE Order
  router.post("/orders", async (req, res) => {
    requireFields(req.body, ["id", "branchId", "customerId", "payment"]);

    const customer = await User.findOne({ id: req.body.customerId });

    const order = await upsertById(Order, req.body.id, {
      id: req.body.id,
      branchId: req.body.branchId,
      customerId: req.body.customerId,
      customerName: normalizeString(customer?.name),
      deliveryAddress: normalizeDeliveryAddress(req.body.deliveryAddress),
      items: req.body.items || [],
      status: "confirmed",
      payment: { ...req.body.payment, status: "pending" },
      total: req.body.total || 0,
      createdAt: new Date(),
    });

    res.status(201).json(serializeDocument(order));
  });

  // UPDATE Order Status
  router.patch("/orders/:orderId", async (req, res) => {
    if (!ORDER_STATUSES.includes(req.body.status)) {
      return res.status(400).json({ message: "Invalid status" });
    }

    const order = await Order.findOneAndUpdate(
      { id: req.params.orderId },
      { status: req.body.status },
      { new: true },
    );

    if (!order) return res.status(404).json({ message: "Not found" });

    res.json(serializeDocument(order));
  });

  // ASSIGN DRIVER
  router.post(
    "/orders/:orderId/assign-driver",
    createAuthMiddleware(),
    requireSuperAdmin,
    async (req, res) => {
      const order = await Order.findOneAndUpdate(
        { id: req.params.orderId },
        { driverId: req.body.driverId, status: "assigned" },
        { new: true },
      );

      res.json(serializeDocument(order));
    },
  );

  // DELIVERY STATUS
  router.patch("/orders/:orderId/status", async (req, res) => {
    const auth = await authenticateDeliveryActor(req);
    if (auth.error) return res.status(auth.error.status).json(auth.error);

    const order = await Order.findOneAndUpdate(
      { id: req.params.orderId },
      { status: req.body.status },
      { new: true },
    );

    res.json(serializeDocument(order));
  });

  // PAYMENT UPDATE
  router.patch("/orders/:orderId/payment", async (req, res) => {
    if (!PAYMENT_STATUSES.includes(req.body.paymentStatus)) {
      return res.status(400).json({ message: "Invalid payment status" });
    }

    const order = await Order.findOneAndUpdate(
      { id: req.params.orderId },
      { "payment.status": req.body.paymentStatus },
      { new: true },
    );

    res.json(serializeDocument(order));
  });

  return router;
}

module.exports = { createOrdersRouter };
