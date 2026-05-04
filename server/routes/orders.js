// Handles order creation, listing, status updates, and payment state changes.
const express = require('express');
const jwt = require('jsonwebtoken');
const { jwtSecret } = require('../config/env');
const { ORDER_STATUSES, PAYMENT_STATUSES } = require('../constants/statuses');
const { Driver, Order, PaymentRecord, User } = require('../models');
const { createAuthMiddleware, requireSuperAdmin } = require('../middleware/auth');
const { serializeDocument, upsertById } = require('../utils/persistence');
const { requireFields } = require('../utils/validation');

function normalizeString(value) {
  return typeof value === 'string' ? value.trim() : '';
}

function pickFirstNonEmpty(...values) {
  return values.map(normalizeString).find((value) => value) || '';
}

function normalizeDeliveryAddress(value, fallbackAddresses = []) {
  let source = null;
  if (typeof value === 'string' && value.trim()) {
    source = { line1: value.trim() };
  } else if (value && typeof value === 'object' && !Array.isArray(value)) {
    source = value;
  }

  if (!source) {
    const fallback = Array.isArray(fallbackAddresses)
      ? fallbackAddresses.find((address) => address && typeof address === 'object')
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

function serializeAssignedDriver(driver) {
  if (!driver) {
    return null;
  }

  // Drivers can exist in either collection, and some records only have email or phone.
  // Keep the original fields, but also expose the best available contact so the UI always has something useful to show.
  const name = pickFirstNonEmpty(driver.name, driver.fullName, driver.displayName, driver.email, driver.phone);
  const phone = pickFirstNonEmpty(driver.phone, driver.email);
  const email = pickFirstNonEmpty(driver.email, driver.phone);

  return {
    id: driver.id,
    name,
    phone,
    email,
    contact: pickFirstNonEmpty(driver.phone, driver.email),
    vehicleType: normalizeString(driver.vehicleType),
    licenseNumber: normalizeString(driver.licenseNumber),
    isOnline: !!driver.isOnline,
    // Expose last known coordinates (if driver collection stores them)
    ...(driver.lastLocation ? { location: { lat: driver.lastLocation.lat, lng: driver.lastLocation.lng, updatedAt: driver.lastLocation.updatedAt } } : {}),
  };
}

async function buildDriverIndex(orders) {
  function extractIds(raw) {
    // Orders may already contain a string id, an array, or a serialized array from earlier data fixes.
    if (!raw && raw !== 0) return [];
    if (Array.isArray(raw)) return raw.map(String).map((s) => s.trim()).filter(Boolean);
    if (typeof raw === 'string') {
      const s = raw.trim();
      // handle serialized arrays like "['id1','id2']" or '["id1","id2"]'
      if (s.startsWith('[') && s.endsWith(']')) {
        try {
          // tolerate single quotes by converting to double quotes first
          const normalized = s.replace(/'/g, '"');
          const parsed = JSON.parse(normalized);
          return Array.isArray(parsed) ? parsed.map(String).map((x) => x.trim()).filter(Boolean) : [];
        } catch (e) {
          // fallback: strip brackets and split on commas
          return s
            .slice(1, -1)
            .split(',')
            .map((x) => String(x).replace(/['\"]/g, '').trim())
            .filter(Boolean);
        }
      }
      return s ? [s] : [];
    }
    return [String(raw).trim()].filter(Boolean);
  }

  // Deduplicate ids so we only query each driver once even when many orders share the same assignee.
  const driverIds = [...new Set(orders.flatMap((order) => extractIds(order.driverId)))];

  if (driverIds.length === 0) {
    return new Map();
  }

  // Drivers may live in Driver collection or in User with role='driver'.
  // Use lean() for faster plain objects and tolerate either collection containing the driver.
  const [drivers, userDrivers] = await Promise.all([
    Driver.find({ id: { $in: driverIds } }).lean(),
    User.find({ id: { $in: driverIds }, role: 'driver' }).lean(),
  ]);

  const index = new Map();
  for (const driver of drivers) {
    index.set(String(driver.id), driver);
  }
  for (const userDriver of userDrivers) {
    const id = String(userDriver.id);
    if (!index.has(id)) {
      index.set(id, userDriver);
    }
  }

  return index;
}

async function buildCustomerIndex(orders) {
  const customerIds = [
    ...new Set(
      orders
        .map((order) => String(order.customerId || '').trim())
        .filter((customerId) => customerId),
    ),
  ];

  if (customerIds.length === 0) {
    return new Map();
  }

  const customers = await User.find({ id: { $in: customerIds } });
  return new Map(customers.map((customer) => [customer.id, customer]));
}

function serializeOrderForClient(order, customerById = new Map(), driverById = new Map()) {
  const customer = customerById.get(order.customerId);
  // The tracking screen expects a hydrated driver summary, not just a raw id.
  const assignedDriver = driverById.get(order.driverId);
  return {
    ...serializeDocument(order),
    customerName:
      normalizeString(order.customerName) || normalizeString(customer?.name),
    customerEmail:
      normalizeString(order.customerEmail) || normalizeString(customer?.email),
    deliveryAddress: normalizeDeliveryAddress(
      order.deliveryAddress,
      customer?.addresses,
    ),
    assignedDriver: serializeAssignedDriver(assignedDriver),
  };
}

async function authenticateDeliveryActor(req) {
  const authHeader = req.headers.authorization;
  const token = (authHeader || '').split(' ')[1];
  if (!token) {
    return { error: { status: 401, message: 'Authentication token is required.' } };
  }

  let payload = null;
  try {
    payload = jwt.verify(token, jwtSecret);
  } catch (_) {
    return { error: { status: 401, message: 'Authentication token is invalid or expired.' } };
  }

  if (payload.role === 'driver') {
    const user = await User.findOne({ id: payload.sub, role: 'driver' });
    if (user) {
      return { payload, actorType: 'driver', user };
    }
    const driver = await Driver.findOne({ id: payload.sub });
    if (driver) {
      return { payload, actorType: 'driver', driver };
    }
    return {
      error: {
        status: 403,
        message: 'Only admins or the assigned driver can update delivery status.',
      },
    };
  }

  const user = await User.findOne({ id: payload.sub });
  if (!user || !['admin', 'super_admin'].includes(user.role)) {
    return {
      error: {
        status: 403,
        message: 'Only admins or the assigned driver can update delivery status.',
      },
    };
  }

  return { payload, actorType: 'admin', user };
}

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
    const customerById = await buildCustomerIndex(orders);
    const driverById = await buildDriverIndex(orders);
    res.json(orders.map((order) => serializeOrderForClient(order, customerById, driverById)));
  });

  router.post('/orders', async (req, res) => {
    requireFields(req.body, ['id', 'branchId', 'customerId', 'payment']);

    const customer = await User.findOne({ id: req.body.customerId });

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
      customerName: normalizeString(req.body.customerName) || normalizeString(customer?.name),
      customerEmail: normalizeString(req.body.customerEmail) || normalizeString(customer?.email),
      deliveryAddress: normalizeDeliveryAddress(req.body.deliveryAddress, customer?.addresses),
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

    const customerById = await buildCustomerIndex([order]);
    const driverById = await buildDriverIndex([order]);
    res.status(201).json(serializeOrderForClient(order, customerById, driverById));
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

  // Assign a driver to an order (admin action)
  const assignDriverHandler = async (req, res) => {
    const { driverId } = req.body;
    const locationPayload = req.body.location;
    if (!driverId) {
      return res.status(400).json({ message: 'driverId is required.' });
    }

    const driver = await User.findOne({ id: driverId, role: 'driver' }) || await Driver.findOne({ id: driverId });
    if (!driver) {
      return res.status(404).json({ message: 'Driver not found.' });
    }

    const existingOrder = await Order.findOne({ id: req.params.orderId });
    if (!existingOrder) {
      return res.status(404).json({ message: 'Order not found.' });
    }
    if (existingOrder.status === 'delivered') {
      return res.status(400).json({ message: 'Delivered orders cannot be reassigned.' });
    }

    const order = await Order.findOneAndUpdate(
      { id: req.params.orderId },
      {
        $set: {
          driverId,
          status: 'assigned',
          outForDeliveryAt: null,
          // If admin supplied an explicit location payload when assigning,
          // normalize and persist it into the order's deliveryAddress so drivers
          // receive exact delivery coordinates and address information.
          ...(locationPayload ? { deliveryAddress: normalizeDeliveryAddress(locationPayload) } : {}),
        },
      },
      { returnDocument: 'after' },
    );

    if (!order) {
      return res.status(404).json({ message: 'Order not found.' });
    }
    const customerById = await buildCustomerIndex([order]);
    const driverById = await buildDriverIndex([order]);
    return res.json(serializeOrderForClient(order, customerById, driverById));
  };

  router.post('/orders/:orderId/assign-driver', createAuthMiddleware(), requireSuperAdmin, assignDriverHandler);
  router.patch('/orders/:orderId/assign-driver', createAuthMiddleware(), requireSuperAdmin, assignDriverHandler);

  const updateDeliveryStatusHandler = async (req, res) => {
    const { status } = req.body;
    const allowed = ['assigned', 'out_for_delivery', 'delivered'];
    if (!allowed.includes(status)) {
      return res.status(400).json({ message: 'Invalid delivery status.' });
    }

    const auth = await authenticateDeliveryActor(req);
    if (auth.error) {
      return res.status(auth.error.status).json({ message: auth.error.message });
    }

    const order = await Order.findOne({ id: req.params.orderId });
    if (!order) {
      return res.status(404).json({ message: 'Order not found.' });
    }

    if (auth.actorType === 'driver' && auth.payload.sub !== order.driverId) {
      return res.status(403).json({ message: 'Driver not assigned to this order.' });
    }

    const update = { status };
    if (status === 'assigned') {
      update.outForDeliveryAt = null;
      update.deliveredAt = null;
    }
    if (status === 'out_for_delivery') {
      update.outForDeliveryAt = new Date();
    }
    if (status === 'delivered') {
      update.deliveredAt = new Date();
    }

    const updated = await Order.findOneAndUpdate(
      { id: req.params.orderId },
      { $set: update },
      { returnDocument: 'after' },
    );
    const customerById = await buildCustomerIndex([updated]);
    const driverById = await buildDriverIndex([updated]);
    return res.json(serializeOrderForClient(updated, customerById, driverById));
  };

  // Update delivery status (driver or admin)
  router.post('/orders/:orderId/delivery-status', updateDeliveryStatusHandler);
  router.patch('/orders/:orderId/status', updateDeliveryStatusHandler);

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

    const customerById = await buildCustomerIndex([order]);
    const driverById = await buildDriverIndex([order]);
    return res.json(serializeOrderForClient(order, customerById, driverById));
  });

  return router;
}

module.exports = {
  createOrdersRouter,
  normalizeString,
  normalizeDeliveryAddress,
  pickFirstNonEmpty,
  serializeAssignedDriver,
  buildDriverIndex,
  buildCustomerIndex,
  serializeOrderForClient,
};
