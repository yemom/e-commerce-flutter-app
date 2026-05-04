// All driver-related business logic extracted from routes/drivers.js and routes/auth.js
const crypto = require("crypto");
const bcrypt = require("bcryptjs");
const jwt = require("jsonwebtoken");

const { jwtSecret } = require("../../config/env");
const { Driver, Order, User } = require("../../models");
const { serializeDocument } = require("../../utils/persistence");

// ── Helpers ───────────────────────────────────────────────────────────────────

function normalizeString(value) {
  return typeof value === "string" ? value.trim() : "";
}

function normalizeEmail(value) {
  return String(value || "")
    .trim()
    .toLowerCase();
}

function normalizePhone(value) {
  return String(value || "").trim();
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
      ? fallbackAddresses.find((a) => a && typeof a === "object")
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
  if (source.lat != null && !Number.isNaN(Number(source.lat)))
    address.lat = Number(source.lat);
  if (source.lng != null && !Number.isNaN(Number(source.lng)))
    address.lng = Number(source.lng);
  return address;
}

function serializeDriver(driver, extra = {}) {
  return {
    id: driver.id,
    name: driver.name,
    phone: driver.phone || "",
    email: driver.email || "",
    vehicleType: driver.vehicleType || "",
    licenseNumber: driver.licenseNumber || "",
    // include last known coordinates when available
    ...(driver.lastLocation ? { lastLocation: driver.lastLocation } : {}),
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
      orders.map((o) => normalizeString(o.customerId)).filter(Boolean),
    ),
  ];
  if (customerIds.length === 0) return new Map();
  const customers = await User.find({ id: { $in: customerIds } });
  return new Map(customers.map((c) => [c.id, c]));
}

async function buildDriverProfile(driver) {
  const assignedOrders = await Order.find({ driverId: driver.id }).sort({
    createdAt: -1,
  });
  const customerById = await buildCustomerIndex(assignedOrders);
  const deliveredOrders = assignedOrders.filter(
    (o) => o.status === "delivered",
  );
  const activeOrdersCount = assignedOrders.filter((o) =>
    ["assigned", "out_for_delivery", "shipped"].includes(o.status),
  ).length;
  const currentStatus =
    activeOrdersCount > 0 ? "busy" : driver.isOnline ? "available" : "offline";

  return serializeDriver(driver, {
    currentStatus,
    activeOrdersCount,
    assignedOrders: assignedOrders.map((o) =>
      serializeDriverOrderSummary(o, customerById),
    ),
    deliveryHistory: deliveredOrders.map((o) =>
      serializeDriverOrderSummary(o, customerById),
    ),
  });
}

function signDriverToken(driver) {
  return jwt.sign(
    {
      sub: driver.id,
      role: "driver",
      email: driver.email,
      phone: driver.phone,
    },
    jwtSecret,
    { expiresIn: "7d" },
  );
}

// ── Controllers ───────────────────────────────────────────────────────────────

// POST /api/auth/driver/login
const login = async (req, res) => {
  try {
    const rawIdentifier = String(
      req.body.identifier || req.body.email || req.body.phone || "",
    ).trim();
    const password = String(req.body.password || "").trim();

    if (!rawIdentifier || !password) {
      return res
        .status(400)
        .json({ message: "Email/phone and password are required." });
    }

    const email = normalizeEmail(rawIdentifier);
    const phone = normalizePhone(rawIdentifier);

    const driver = rawIdentifier.includes("@")
      ? await Driver.findOne({ email })
      : await Driver.findOne({ $or: [{ email }, { phone }] });

    if (!driver) {
      return res.status(401).json({ message: "Invalid credentials." });
    }

    const matches = await bcrypt.compare(password, driver.passwordHash);
    if (!matches) {
      return res.status(401).json({ message: "Invalid credentials." });
    }

    const token = signDriverToken(driver);
    const profile = await buildDriverProfile(driver);

    return res.json({ token, driver: profile, user: profile });
  } catch (err) {
    return res.status(500).json({ message: "Login failed. Please try again." });
  }
};

// POST /api/drivers/register  (self-registration)
const register = async (req, res) => {
  try {
    const {
      name,
      phone,
      email,
      password,
      vehicleType,
      licenseNumber,
      isOnline,
    } = req.body;

    if (!name || !phone || !password) {
      return res
        .status(400)
        .json({ message: "name, phone and password are required." });
    }
    if (String(password).trim().length < 6) {
      return res
        .status(400)
        .json({ message: "Password must be at least 6 characters long." });
    }

    const normalizedPhone = normalizePhone(phone);
    const normalizedEmail = normalizeEmail(email);

    const existing = await Driver.findOne({
      $or: [
        { phone: normalizedPhone },
        ...(normalizedEmail ? [{ email: normalizedEmail }] : []),
      ],
    });
    if (existing) {
      return res
        .status(409)
        .json({ message: "A driver with this phone or email already exists." });
    }

    const driver = await Driver.create({
      id: crypto.randomUUID(),
      name: normalizeString(name),
      phone: normalizedPhone,
      email: normalizedEmail || undefined,
      passwordHash: await bcrypt.hash(String(password).trim(), 10),
      vehicleType: normalizeString(vehicleType),
      licenseNumber: normalizeString(licenseNumber),
      isOnline: !!isOnline,
    });

    const token = signDriverToken(driver);
    return res.status(201).json({ token, driver: serializeDriver(driver) });
  } catch (err) {
    return res
      .status(500)
      .json({ message: "Registration failed. Please try again." });
  }
};

// POST /api/drivers  (admin creates driver)
const createDriver = async (req, res) => {
  try {
    const {
      name,
      phone,
      email,
      password,
      vehicleType,
      licenseNumber,
      isOnline,
    } = req.body;

    if (!name || (!phone && !email) || !password) {
      return res
        .status(400)
        .json({ message: "name, email or phone, and password are required." });
    }
    if (!vehicleType || !licenseNumber) {
      return res
        .status(400)
        .json({ message: "vehicleType and licenseNumber are required." });
    }

    const normalizedPhone = normalizePhone(phone);
    const normalizedEmail = normalizeEmail(email);

    const existing = await Driver.findOne({
      $or: [
        ...(normalizedPhone ? [{ phone: normalizedPhone }] : []),
        ...(normalizedEmail ? [{ email: normalizedEmail }] : []),
      ],
    });
    if (existing) {
      return res
        .status(409)
        .json({ message: "A driver with this phone or email already exists." });
    }

    const driver = await Driver.create({
      id: crypto.randomUUID(),
      name: normalizeString(name),
      phone: normalizedPhone || undefined,
      email: normalizedEmail || undefined,
      passwordHash: await bcrypt.hash(String(password).trim(), 10),
      vehicleType: normalizeString(vehicleType),
      licenseNumber: normalizeString(licenseNumber),
      isOnline: !!isOnline,
    });

    return res.status(201).json(serializeDriver(driver));
  } catch (err) {
    return res
      .status(500)
      .json({ message: "Could not create driver. Please try again." });
  }
};

// GET /api/drivers  (admin lists all drivers)
const listDrivers = async (req, res) => {
  try {
    const { q, status, vehicleType } = req.query;
    const filter = {};
    const requestedStatus =
      typeof status === "string" ? status.trim().toLowerCase() : "";

    if (vehicleType) filter.vehicleType = vehicleType;
    if (q) {
      const pattern = new RegExp(q, "i");
      filter.$or = [
        { name: pattern },
        { phone: pattern },
        { email: pattern },
        { vehicleType: pattern },
        { licenseNumber: pattern },
      ];
    }

    const drivers = await Driver.find(filter).sort({ createdAt: -1 });
    const payload = [];

    for (const driver of drivers) {
      const activeOrdersCount = await Order.countDocuments({
        driverId: driver.id,
        status: { $in: ["assigned", "out_for_delivery", "shipped"] },
      });
      const currentStatus =
        activeOrdersCount > 0
          ? "busy"
          : driver.isOnline
            ? "available"
            : "offline";
      payload.push(
        serializeDriver(driver, { activeOrdersCount, currentStatus }),
      );
    }

    if (["available", "busy", "offline"].includes(requestedStatus)) {
      return res.json(
        payload.filter((d) => d.currentStatus === requestedStatus),
      );
    }

    return res.json(payload);
  } catch (err) {
    return res.status(500).json({ message: "Could not fetch drivers." });
  }
};

// GET /api/drivers/:driverId  (admin gets one driver)
const getDriver = async (req, res) => {
  try {
    const driver = await Driver.findOne({ id: req.params.driverId });
    if (!driver) return res.status(404).json({ message: "Driver not found." });
    return res.json(await buildDriverProfile(driver));
  } catch (err) {
    return res.status(500).json({ message: "Could not fetch driver." });
  }
};

// PATCH /api/drivers/:driverId  (driver self-update or admin)
const updateDriver = async (req, res) => {
  try {
    const updates = {};
    const allowedFields = [
      "name",
      "phone",
      "email",
      "vehicleType",
      "licenseNumber",
      "isOnline",
    ];

    allowedFields.forEach((field) => {
      if (Object.prototype.hasOwnProperty.call(req.body, field)) {
        updates[field] =
          field === "email" && req.body[field]
            ? normalizeEmail(req.body[field])
            : req.body[field];
      }
    });

    if (req.body.password) {
      updates.passwordHash = await bcrypt.hash(
        String(req.body.password).trim(),
        10,
      );
    }

    const driver = await Driver.findOneAndUpdate(
      { id: req.params.driverId },
      { $set: updates },
      { returnDocument: "after" },
    );
    if (!driver) return res.status(404).json({ message: "Driver not found." });

    return res.json(serializeDriver(driver));
  } catch (err) {
    return res.status(500).json({ message: "Could not update driver." });
  }
};

// DELETE /api/drivers/:driverId  (admin)
const deleteDriver = async (req, res) => {
  try {
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
  } catch (err) {
    return res.status(500).json({ message: "Could not delete driver." });
  }
};

// GET /api/drivers/me/orders
const getMyOrders = async (req, res) => {
  try {
    const driver = req.authDriver?.driver;
    if (!driver)
      return res.status(401).json({ message: "Authentication required." });

    const orders = await Order.find({ driverId: driver.id }).sort({
      createdAt: -1,
    });
    const customerById = await buildCustomerIndex(orders);
    return res.json(
      orders.map((o) => serializeOrderForDriver(o, customerById)),
    );
  } catch (err) {
    return res.status(500).json({ message: "Could not fetch orders." });
  }
};

// GET /api/drivers/me/profile
const getMyProfile = async (req, res) => {
  try {
    const driver = req.authDriver?.driver;
    if (!driver)
      return res.status(401).json({ message: "Authentication required." });
    return res.json(await buildDriverProfile(driver));
  } catch (err) {
    return res.status(500).json({ message: "Could not fetch profile." });
  }
};

// PATCH /api/drivers/me/profile
const updateMyProfile = async (req, res) => {
  try {
    const driver = req.authDriver?.driver;
    if (!driver)
      return res.status(401).json({ message: "Authentication required." });

    const updates = {};
    if (typeof req.body.name === "string")
      updates.name = normalizeString(req.body.name);
    if (typeof req.body.phone === "string")
      updates.phone = normalizePhone(req.body.phone);
    if (typeof req.body.email === "string")
      updates.email = normalizeEmail(req.body.email);
    if (typeof req.body.vehicleType === "string")
      updates.vehicleType = normalizeString(req.body.vehicleType);
    if (typeof req.body.licenseNumber === "string")
      updates.licenseNumber = normalizeString(req.body.licenseNumber);

    // Verify current password before allowing password change
    if (
      typeof req.body.currentPassword === "string" &&
      req.body.currentPassword.trim()
    ) {
      const matches = await bcrypt.compare(
        req.body.currentPassword,
        driver.passwordHash,
      );
      if (!matches)
        return res
          .status(400)
          .json({ message: "Current password is not correct." });
    }

    if (
      typeof req.body.newPassword === "string" &&
      req.body.newPassword.trim()
    ) {
      if (req.body.newPassword.trim().length < 6) {
        return res.status(400).json({
          message: "New password must be at least 6 characters long.",
        });
      }
      updates.passwordHash = await bcrypt.hash(req.body.newPassword.trim(), 10);
    }

    const updated = await Driver.findOneAndUpdate(
      { id: driver.id },
      { $set: updates },
      { new: true },
    );
    if (!updated) return res.status(404).json({ message: "Driver not found." });

    return res.json(await buildDriverProfile(updated));
  } catch (err) {
    return res.status(500).json({ message: "Could not update profile." });
  }
};

// GET /api/drivers/:driverId/orders  (admin)
const getDriverOrders = async (req, res) => {
  try {
    if (req.params.driverId === "me") {
      return res.status(404).json({ message: "Driver not found." });
    }
    const driver = await Driver.findOne({ id: req.params.driverId });
    if (!driver) return res.status(404).json({ message: "Driver not found." });

    const orders = await Order.find({ driverId: driver.id }).sort({
      createdAt: -1,
    });
    const customerById = await buildCustomerIndex(orders);
    return res.json(
      orders.map((o) => serializeOrderForDriver(o, customerById)),
    );
  } catch (err) {
    return res.status(500).json({ message: "Could not fetch driver orders." });
  }
};

module.exports = {
  login,
  register,
  createDriver,
  listDrivers,
  getDriver,
  updateDriver,
  deleteDriver,
  getMyOrders,
  getMyProfile,
  updateMyProfile,
  getDriverOrders,
};
