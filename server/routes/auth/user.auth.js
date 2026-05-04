// Handles user/client login only → POST /api/auth/user/login
const express = require("express");
const bcrypt = require("bcryptjs");
const jwt = require("jsonwebtoken");

const { jwtSecret, superAdminEmail } = require("../../config/env");
const { User } = require("../../models");
const { syncSuperAdminAccount } = require("../../utils/super-admin");

const router = express.Router();

const express = require("express");
const router = express.Router();
const controller = require("../../controllers/auth/user.controller");
const {
  createAuthMiddleware,
  requireSuperAdmin,
} = require("../../middleware/auth");

const auth = createAuthMiddleware();

router.post("/login", controller.login);
router.get("/me", auth, controller.getMe);
router.get("/all", auth, requireSuperAdmin, controller.listUsers);

module.exports = router;

function normalizeEmail(value) {
  return String(value || "")
    .trim()
    .toLowerCase();
}

function normalizePhone(value) {
  return String(value || "").trim();
}

function sanitizeUser(userDoc) {
  return {
    id: userDoc.id,
    email: userDoc.email || "",
    phone: userDoc.phone || "",
    name: userDoc.name,
    role: userDoc.role,
    approved: userDoc.approved,
    vehicleType: userDoc.vehicleType || "",
    licenseNumber: userDoc.licenseNumber || "",
  };
}

function signToken(userDoc) {
  return jwt.sign(
    { sub: userDoc.id, role: userDoc.role, email: userDoc.email },
    jwtSecret,
    { expiresIn: "7d" },
  );
}

// POST /api/auth/user/login
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

    // Only match accounts with role === 'user'
    const user = rawIdentifier.includes("@")
      ? await User.findOne({ email, role: "user" })
      : await User.findOne({
          $or: [{ email }, { phone: normalizedPhone }],
          role: "user",
        });

    if (!user) {
      return res.status(401).json({ message: "Invalid credentials." });
    }

    const matches = await bcrypt.compare(password, user.passwordHash);
    if (!matches) {
      return res.status(401).json({ message: "Invalid credentials." });
    }

    return res.json({
      token: signToken(user),
      user: sanitizeUser(user),
    });
  } catch (err) {
    return res.status(500).json({ message: "Login failed. Please try again." });
  }
});

module.exports = router;
