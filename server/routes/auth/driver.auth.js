// Handles driver login only → POST /api/auth/driver/login
const crypto = require("crypto");
const express = require("express");
const bcrypt = require("bcryptjs");
const jwt = require("jsonwebtoken");

const { jwtSecret } = require("../../config/env");
const { Driver } = require("../../models");

const router = express.Router();

const express = require("express");
const router = express.Router();
const controller = require("../../controllers/auth/driver.controller");
const {
  createAuthMiddleware,
  createDriverAuthMiddleware,
  requireSuperAdmin,
} = require("../../middleware/auth");
const { requireDriver } = require("../../middleware/role-guard");

const auth = createAuthMiddleware();
const driverAuth = createDriverAuthMiddleware();

router.post("/login", controller.login);
router.post("/register", controller.register);
router.get("/me/orders", driverAuth, controller.getMyOrders);
router.get("/me/profile", driverAuth, controller.getMyProfile);
router.patch("/me/profile", driverAuth, controller.updateMyProfile);
router.get("/", auth, requireSuperAdmin, controller.listDrivers);
router.post("/", auth, requireSuperAdmin, controller.createDriver);
router.get("/:driverId", auth, requireSuperAdmin, controller.getDriver);
router.patch("/:driverId", auth, controller.updateDriver);
router.delete("/:driverId", auth, requireSuperAdmin, controller.deleteDriver);
router.get(
  "/:driverId/orders",
  auth,
  requireSuperAdmin,
  controller.getDriverOrders,
);

module.exports = router;

function normalizeEmail(value) {
  return String(value || "")
    .trim()
    .toLowerCase();
}

function normalizePhone(value) {
  return String(value || "").trim();
}

function buildDriverLoginResponse(driver) {
  const token = jwt.sign(
    {
      sub: driver.id,
      role: "driver",
      email: driver.email,
      phone: driver.phone,
    },
    jwtSecret,
    { expiresIn: "7d" },
  );
  return {
    token,
    user: {
      id: driver.id,
      email: driver.email,
      phone: driver.phone || "",
      name: driver.name,
      role: "driver",
      approved: true,
      vehicleType: driver.vehicleType || "",
      licenseNumber: driver.licenseNumber || "",
    },
  };
}

// POST /api/auth/driver/login
router.post("/login", async (req, res) => {
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
    const normalizedPhone = normalizePhone(rawIdentifier);

    // Look up driver by email or phone
    const driver = rawIdentifier.includes("@")
      ? await Driver.findOne({ email })
      : await Driver.findOne({ $or: [{ email }, { phone: normalizedPhone }] });

    if (!driver) {
      return res.status(401).json({ message: "Invalid credentials." });
    }

    const matches = await bcrypt.compare(password, driver.passwordHash);
    if (!matches) {
      return res.status(401).json({ message: "Invalid credentials." });
    }

    return res.json(buildDriverLoginResponse(driver));
  } catch (err) {
    return res.status(500).json({ message: "Login failed. Please try again." });
  }
});

module.exports = router;
