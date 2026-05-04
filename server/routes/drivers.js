const express = require("express");
console.log('drivers router module loaded');
const bcrypt = require("bcryptjs");
const crypto = require("crypto");
const jwt = require("jsonwebtoken");
const { jwtSecret } = require("../config/env");
const { Driver, Order, User } = require("../models");
const {
  createAuthMiddleware,
  createDriverAuthMiddleware,
  requireSuperAdmin,
} = require("../middleware/auth");
const { serializeDocument } = require("../utils/persistence");

function parseBearerToken(headerValue) {
  if (!headerValue || typeof headerValue !== "string") return null;
  const parts = headerValue.trim().split(" ");
  if (parts.length !== 2) return null;
  const [scheme, token] = parts;
  if (scheme.toLowerCase() !== "bearer") return null;
  return token;
}

function normalizeString(value) {
  return typeof value === "string" ? value.trim() : "";
}

function normalizeDeliveryAddress(value, fallbackAddresses = []) {
  let source = null;
  if (typeof value === "string" && value.trim()) {
    source = { line1: value.trim() };
  } else if (value && typeof value === "object" && !Array.isArray(value)) {
    source = value;
  }

  if (!source) {
    const fallback = Array.isArray(fallbackAddresses)
      ? fallbackAddresses.find((address) => address && typeof address === "object")
      : null;
    source = fallback || {};
  }

  const address = {
    label: normalizeString(source.label),
    line1: normalizeString(source.line1 || source.details || source.address),
    line2: normalizeString(source.line2),
    city: normalizeString(source.city),
    state: normalizeString(source.state),
    postalCode: normalizeString(source.postalCode),
    country: normalizeString(source.country),
  };

  if (source.lat != null && !Number.isNaN(Number(source.lat))) {
    address.lat = Number(source.lat);
  }
  if (source.lng != null && !Number.isNaN(Number(source.lng))) {
    address.lng = Number(source.lng);
  }

  return address;
}

function serializeDriver(driver, extra = {}) {
  return {
    id: driver.id,
    name: driver.name,
    phone: driver.phone,
    email: driver.email || "",
    vehicleType: driver.vehicleType || "",
    licenseNumber: driver.licenseNumber || "",
    isOnline: !!driver.isOnline,
    createdAt: driver.createdAt,
    updatedAt: driver.updatedAt,
    ...extra,
  };
}

function serializeOrderForDriver(order, customerById = new Map()) {
  const customer = customerById.get(order.customerId);
  const payload = serializeDocument(order);
  return {
    ...payload,
    customerName:
      normalizeString(order.customerName) || normalizeString(customer?.name),
    customerEmail:
      normalizeString(order.customerEmail) || normalizeString(customer?.email),
    deliveryAddress: normalizeDeliveryAddress(
      order.deliveryAddress,
      customer?.addresses,
    ),
  };
}

function serializeDriverOrderSummary(order, customerById = new Map()) {
  const payload = serializeOrderForDriver(order, customerById);
  return {
    id: payload.id,
    status: payload.status,
    customerId: payload.customerId,
    customerName: payload.customerName || payload.customerId,
    branchId: payload.branchId,
    createdAt: payload.createdAt,
    deliveredAt: payload.deliveredAt || null,
    total: payload.total ?? 0,
    itemCount: Array.isArray(payload.items) ? payload.items.length : 0,
    deliveryAddressLine: normalizeString(payload.deliveryAddress?.line1),
  };
}

async function buildCustomerIndex(orders) {
  const customerIds = [
    ...new Set(
      orders
        .map((order) => normalizeString(order.customerId))
        .filter((customerId) => customerId),
    ),
  ];

  if (customerIds.length === 0) {
    return new Map();
  }

  const customers = await User.find({ id: { $in: customerIds } });
  return new Map(customers.map((customer) => [customer.id, customer]));
}

async function authenticateDriverOrAdmin(req) {
  const token = parseBearerToken(req.headers.authorization);
  if (!token) return null;
  try {
    const payload = jwt.verify(token, jwtSecret);
    if (payload.role === "driver") {
      const driver = await Driver.findOne({ id: payload.sub });
      if (!driver) return null;
      return { kind: "driver", driver, token };
    }

    const user = await User.findOne({ id: payload.sub });
    if (!user || (user.role !== "admin" && user.role !== "super_admin")) return null;
    return { kind: "admin", user, token };
  } catch (err) {
    return null;
  }
}

function createDriversRouter() {
  const router = express.Router();

  router.post("/drivers/register", async (req, res) => {
    const { name, phone, email, password, vehicleType, licenseNumber, isOnline } = req.body;
    if (!name || !phone || !password) {
      return res.status(400).json({ message: "name, phone and password are required." });
    }
    if (String(password).trim().length < 6) {
      return res.status(400).json({ message: "Password must be at least 6 characters long." });
    }

    const normalizedPhone = normalizeString(phone);
    const normalizedEmail = normalizeString(email).toLowerCase();
    const existing = await Driver.findOne({
      $or: [
        { phone: normalizedPhone },
        ...(normalizedEmail ? [{ email: normalizedEmail }] : []),
      ],
    });
    if (existing) {
      return res.status(409).json({ message: "A driver with this phone or email already exists." });
    }

    const passwordHash = await bcrypt.hash(String(password), 10);
    const driver = await Driver.create({
      id: crypto.randomUUID(),
      name: normalizeString(name),
      phone: normalizedPhone,
      email: normalizedEmail,
      passwordHash,
      vehicleType: normalizeString(vehicleType),
      licenseNumber: normalizeString(licenseNumber),
      isOnline: !!isOnline,
    });

    const token = jwt.sign({ sub: driver.id, role: "driver", phone: driver.phone }, jwtSecret, { expiresIn: "7d" });
    return res.status(201).json({ token, driver: serializeDriver(driver) });
  });

  // Create driver (admin only)
  router.post("/drivers", createAuthMiddleware(), requireSuperAdmin, async (req, res) => {
    const { name, phone, email, password, vehicleType, licenseNumber, isOnline } = req.body;
    if (!name || !phone || !password) {
      return res.status(400).json({ message: "name, phone and password are required." });
    }

    const normalizedPhone = normalizeString(phone);
    const normalizedEmail = normalizeString(email).toLowerCase();
    const existing = await Driver.findOne({
      $or: [
        { phone: normalizedPhone },
        ...(normalizedEmail ? [{ email: normalizedEmail }] : []),
      ],
    });
    if (existing) return res.status(409).json({ message: "A driver with this phone or email already exists." });

    const passwordHash = await bcrypt.hash(String(password), 10);
    const driver = await Driver.create({
      id: crypto.randomUUID(),
      name: normalizeString(name),
      phone: normalizedPhone,
      email: normalizedEmail,
      passwordHash,
      vehicleType: normalizeString(vehicleType),
      licenseNumber: normalizeString(licenseNumber),
      isOnline: !!isOnline,
    });

    return res.status(201).json(serializeDriver(driver));
  });

  // List drivers (admin)
  router.get("/drivers", createAuthMiddleware(), requireSuperAdmin, async (req, res) => {
    const { q, status, vehicleType } = req.query;
    const filter = {};
    const requestedStatus = typeof status === "string" ? status.trim().toLowerCase() : "";
    if (vehicleType) filter.vehicleType = vehicleType;
    if (q) {
      const pattern = new RegExp(q, "i");
      filter.$or = [{ name: pattern }, { phone: pattern }, { email: pattern }, { vehicleType: pattern }, { licenseNumber: pattern }];
    }

    const drivers = await Driver.find(filter).sort({ createdAt: -1 });
    const payload = [];
    for (const driver of drivers) {
      const activeOrdersCount = await Order.countDocuments({
        driverId: driver.id,
        status: { $in: ["assigned", "out_for_delivery", "shipped"] },
      });
      const currentStatus = activeOrdersCount > 0 ? "busy" : (driver.isOnline ? "available" : "offline");
      payload.push(serializeDriver(driver, { activeOrdersCount, currentStatus }));
    }

    if (["available", "busy", "offline"].includes(requestedStatus)) {
      return res.json(payload.filter((d) => d.currentStatus === requestedStatus));
    }

    return res.json(payload);
  });

  // Driver detail (admin)
  router.get("/drivers/:driverId", createAuthMiddleware(), requireSuperAdmin, async (req, res) => {
    const driver = await Driver.findOne({ id: req.params.driverId });
    if (!driver) return res.status(404).json({ message: "Driver not found." });

    const assignedOrders = await Order.find({ driverId: driver.id }).sort({ createdAt: -1 });
    const customerById = await buildCustomerIndex(assignedOrders);
    const deliveredOrders = assignedOrders.filter((order) => order.status === "delivered");
    const activeOrdersCount = assignedOrders.filter((order) => ["assigned", "out_for_delivery", "shipped"].includes(order.status)).length;
    const currentStatus = activeOrdersCount > 0 ? "busy" : (driver.isOnline ? "available" : "offline");

    return res.json(serializeDriver(driver, {
      currentStatus,
      activeOrdersCount,
      assignedOrders: assignedOrders.map((order) => serializeDriverOrderSummary(order, customerById)),
      deliveryHistory: deliveredOrders.map((order) => serializeDriverOrderSummary(order, customerById)),
    }));
  });

  // Update driver (driver self or admin)
  router.patch("/drivers/:driverId", async (req, res) => {
    const auth = await authenticateDriverOrAdmin(req);
    if (!auth) return res.status(401).json({ message: "Authentication token is required." });

    const isAdmin = auth.kind === "admin";
    const isSelfDriver = auth.kind === "driver" && auth.driver.id === req.params.driverId;
    if (!isAdmin && !isSelfDriver) return res.status(403).json({ message: "You can only update your own driver profile." });

    const updates = {};
    const allowedFields = ["name", "phone", "email", "vehicleType", "licenseNumber", "isOnline"];
    allowedFields.forEach((field) => {
      if (Object.prototype.hasOwnProperty.call(req.body, field)) {
        updates[field] = field === "email" && req.body[field] ? String(req.body[field]).toLowerCase() : req.body[field];
      }
    });
    if (req.body.password) updates.passwordHash = await bcrypt.hash(String(req.body.password), 10);

    const driver = await Driver.findOneAndUpdate({ id: req.params.driverId }, { $set: updates }, { returnDocument: "after" });
    if (!driver) return res.status(404).json({ message: "Driver not found." });
    return res.json(serializeDriver(driver));
  });

  // Delete driver (admin)
  router.delete("/drivers/:driverId", createAuthMiddleware(), requireSuperAdmin, async (req, res) => {
    const driver = await Driver.findOneAndDelete({ id: req.params.driverId });
    if (!driver) return res.status(404).json({ message: "Driver not found." });

    await Order.updateMany(
      { driverId: driver.id },
      {
        $set: {
          driverId: null,
          status: "pending",
          outForDeliveryAt: null,
          deliveredAt: null,
        },
      },
    );

    return res.json({ message: "Driver deleted." });
  });

  // Login (issues JWT for drivers)
  router.post("/drivers/login", async (req, res) => {
    const { phone, password, email } = req.body;
    if ((!phone && !email) || !password) return res.status(400).json({ message: "phone/email and password required." });

    let driver = null;
    if (phone) {
      const value = normalizeString(phone);
      // If the supplied 'phone' field contains an '@', treat it as an email address.
      if (value.includes('@')) {
        driver = await Driver.findOne({ email: value.toLowerCase() });
      } else {
        driver = await Driver.findOne({ phone: value });
      }
    }
    if (!driver && email) {
      driver = await Driver.findOne({ email: normalizeString(email).toLowerCase() });
    }
    if (!driver) return res.status(401).json({ message: "Invalid credentials." });

    const matches = await bcrypt.compare(password, driver.passwordHash);
    if (!matches) return res.status(401).json({ message: "Invalid credentials." });

    const token = jwt.sign({ sub: driver.id, role: "driver", phone: driver.phone }, jwtSecret, { expiresIn: "7d" });

    // Enrich driver payload with assigned orders and delivery history for immediate client use.
    const assignedOrders = await Order.find({ driverId: driver.id }).sort({ createdAt: -1 });
    const customerById = await buildCustomerIndex(assignedOrders);
    const deliveredOrders = assignedOrders.filter((o) => o.status === 'delivered');
    const activeOrdersCount = assignedOrders.filter((o) => ['assigned', 'out_for_delivery', 'shipped'].includes(o.status)).length;
    const currentStatus = activeOrdersCount > 0 ? 'busy' : (driver.isOnline ? 'available' : 'offline');

    return res.json({
      token,
      driver: serializeDriver(driver, {
        currentStatus,
        activeOrdersCount,
        assignedOrders: assignedOrders.map((order) => serializeDriverOrderSummary(order, customerById)),
        deliveryHistory: deliveredOrders.map((order) => serializeDriverOrderSummary(order, customerById)),
      }),
    });
  });

  // Driver: get own orders
  router.get("/drivers/me/orders", createDriverAuthMiddleware(), async (req, res) => {
    const auth = req.authDriver || {};
    const driver = auth.driver;
    if (!driver) return res.status(401).json({ message: "Authentication required." });
    const orders = await Order.find({ driverId: driver.id }).sort({ createdAt: -1 });
    const customerById = await buildCustomerIndex(orders);
    return res.json(orders.map((order) => serializeOrderForDriver(order, customerById)));
  });

  // Driver: get full own profile with order summaries for the home screen.
  router.get("/drivers/me/profile", createDriverAuthMiddleware(), async (req, res) => {
    const auth = req.authDriver || {};
    const driver = auth.driver;
    if (!driver) return res.status(401).json({ message: "Authentication required." });

    const assignedOrders = await Order.find({ driverId: driver.id }).sort({ createdAt: -1 });
    const customerById = await buildCustomerIndex(assignedOrders);
    const deliveredOrders = assignedOrders.filter((order) => order.status === 'delivered');
    const activeOrdersCount = assignedOrders.filter((order) => ['assigned', 'out_for_delivery', 'shipped'].includes(order.status)).length;
    const currentStatus = activeOrdersCount > 0 ? 'busy' : (driver.isOnline ? 'available' : 'offline');

    return res.json(serializeDriver(driver, {
      currentStatus,
      activeOrdersCount,
      assignedOrders: assignedOrders.map((order) => serializeDriverOrderSummary(order, customerById)),
      deliveryHistory: deliveredOrders.map((order) => serializeDriverOrderSummary(order, customerById)),
    }));
  });

  // Driver: report current location (driver app → POST /api/drivers/me/location)
  router.post("/drivers/me/location", createDriverAuthMiddleware(), async (req, res) => {
    const auth = req.authDriver || {};
    const driver = auth.driver;
    if (!driver) return res.status(401).json({ message: "Authentication required." });

    // Accept either { location: { lat, lng } } or { lat, lng }
    const body = req.body || {};
    const payload = body.location || body;
    const lat = payload.lat != null ? Number(payload.lat) : undefined;
    const lng = payload.lng != null ? Number(payload.lng) : undefined;
    if (lat == null || lng == null || Number.isNaN(lat) || Number.isNaN(lng)) {
      return res.status(400).json({ message: 'lat and lng are required numeric values.' });
    }

    const updated = await Driver.findOneAndUpdate(
      { id: driver.id },
      { $set: { lastLocation: { lat, lng, updatedAt: new Date() } } },
      { returnDocument: "after" },
    );

    if (!updated) return res.status(404).json({ message: 'Driver not found.' });

    const assignedOrders = await Order.find({ driverId: updated.id }).sort({ createdAt: -1 });
    const customerById = await buildCustomerIndex(assignedOrders);
    const deliveredOrders = assignedOrders.filter((order) => order.status === 'delivered');
    const activeOrdersCount = assignedOrders.filter((order) => ['assigned', 'out_for_delivery', 'shipped'].includes(order.status)).length;
    const currentStatus = activeOrdersCount > 0 ? 'busy' : (updated.isOnline ? 'available' : 'offline');

    return res.json(serializeDriver(updated, {
      currentStatus,
      activeOrdersCount,
      assignedOrders: assignedOrders.map((order) => serializeDriverOrderSummary(order, customerById)),
      deliveryHistory: deliveredOrders.map((order) => serializeDriverOrderSummary(order, customerById)),
    }));
  });

  // Driver: update own profile.
  router.patch("/drivers/me/profile", createDriverAuthMiddleware(), async (req, res) => {
    const auth = req.authDriver || {};
    const driver = auth.driver;
    if (!driver) return res.status(401).json({ message: "Authentication required." });

    const updates = {};
    if (typeof req.body.name === 'string') updates.name = normalizeString(req.body.name);
    if (typeof req.body.phone === 'string') updates.phone = normalizeString(req.body.phone);
    if (typeof req.body.email === 'string') updates.email = normalizeString(req.body.email).toLowerCase();
    if (typeof req.body.vehicleType === 'string') updates.vehicleType = normalizeString(req.body.vehicleType);
    if (typeof req.body.licenseNumber === 'string') updates.licenseNumber = normalizeString(req.body.licenseNumber);

    if (typeof req.body.currentPassword === 'string' && req.body.currentPassword.trim()) {
      const matches = await bcrypt.compare(req.body.currentPassword, driver.passwordHash);
      if (!matches) return res.status(400).json({ message: 'Current password is not correct.' });
    }

    if (typeof req.body.newPassword === 'string' && req.body.newPassword.trim()) {
      if (req.body.newPassword.trim().length < 6) {
        return res.status(400).json({ message: 'New password must be at least 6 characters long.' });
      }
      updates.passwordHash = await bcrypt.hash(req.body.newPassword.trim(), 10);
    }

    const updated = await Driver.findOneAndUpdate(
      { id: driver.id },
      { $set: updates },
      { new: true },
    );

    if (!updated) return res.status(404).json({ message: 'Driver not found.' });

    const assignedOrders = await Order.find({ driverId: updated.id }).sort({ createdAt: -1 });
    const customerById = await buildCustomerIndex(assignedOrders);
    const deliveredOrders = assignedOrders.filter((order) => order.status === 'delivered');
    const activeOrdersCount = assignedOrders.filter((order) => ['assigned', 'out_for_delivery', 'shipped'].includes(order.status)).length;
    const currentStatus = activeOrdersCount > 0 ? 'busy' : (updated.isOnline ? 'available' : 'offline');

    return res.json(serializeDriver(updated, {
      currentStatus,
      activeOrdersCount,
      assignedOrders: assignedOrders.map((order) => serializeDriverOrderSummary(order, customerById)),
      deliveryHistory: deliveredOrders.map((order) => serializeDriverOrderSummary(order, customerById)),
    }));
  });

  // Admin: get orders for a specific driver
  router.get("/drivers/:driverId/orders", createAuthMiddleware(), requireSuperAdmin, async (req, res) => {
    if (req.params.driverId === 'me') {
      return res.status(404).json({ message: 'Driver not found.' });
    }
    const driver = await Driver.findOne({ id: req.params.driverId });
    if (!driver) return res.status(404).json({ message: "Driver not found." });
    const orders = await Order.find({ driverId: driver.id }).sort({ createdAt: -1 });
    const customerById = await buildCustomerIndex(orders);
    return res.json(orders.map((order) => serializeOrderForDriver(order, customerById)));
  });

  // Admin debug: list drivers with last known locations
  router.get('/drivers/locations', createAuthMiddleware(), requireSuperAdmin, async (req, res) => {
    try {
      const drivers = await Driver.find({}, { id: 1, name: 1, lastLocation: 1 }).lean();
      const payload = drivers.map((d) => ({ id: d.id, name: d.name, lastLocation: d.lastLocation || null }));
      return res.json(payload);
    } catch (err) {
      return res.status(500).json({ message: 'Could not fetch driver locations.' });
    }
  });

  return router;
}

module.exports = { createDriversRouter };
