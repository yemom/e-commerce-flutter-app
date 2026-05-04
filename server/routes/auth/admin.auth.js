// Handles admin/super_admin login only → POST /api/auth/admin/login
const express = require("express");
const bcrypt = require("bcryptjs");
const jwt = require("jsonwebtoken");

const { jwtSecret, superAdminEmail } = require("../../config/env");
const { User } = require("../../models");
const { syncSuperAdminAccount } = require("../../utils/super-admin");

const router = express.Router();

const express = require("express");
const router = express.Router();
const controller = require("../../controllers/auth/admin.controller");
const {
  createAuthMiddleware,
  requireSuperAdmin,
} = require("../../middleware/auth");

const auth = createAuthMiddleware();

router.post("/login", controller.login);
router.get("/accounts", auth, requireSuperAdmin, controller.listAdminAccounts);
router.get(
  "/accounts/:userId",
  auth,
  requireSuperAdmin,
  controller.getAdminAccount,
);
router.post(
  "/accounts",
  auth,
  requireSuperAdmin,
  controller.createAdminAccount,
);
router.patch(
  "/accounts/:userId",
  auth,
  requireSuperAdmin,
  controller.updateAdminAccount,
);
router.post(
  "/accounts/promote",
  auth,
  requireSuperAdmin,
  controller.promoteToAdmin,
);
router.patch(
  "/accounts/:userId/approval",
  auth,
  requireSuperAdmin,
  controller.updateApproval,
);
router.delete(
  "/accounts/:userId/admin-access",
  auth,
  requireSuperAdmin,
  controller.revokeAdminAccess,
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

// POST /api/auth/admin/login
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

    // Only match admin or super_admin roles
    const user = rawIdentifier.includes("@")
      ? await User.findOne({ email, role: { $in: ["admin", "super_admin"] } })
      : await User.findOne({
          $or: [{ email }, { phone: normalizedPhone }],
          role: { $in: ["admin", "super_admin"] },
        });

    if (!user) {
      return res.status(401).json({ message: "Invalid credentials." });
    }

    const matches = await bcrypt.compare(password, user.passwordHash);
    if (!matches) {
      return res.status(401).json({ message: "Invalid credentials." });
    }

    // Block unapproved admin accounts
    if (user.role === "admin" && !user.approved) {
      return res.status(403).json({
        message: "Your admin account is waiting for super admin approval.",
      });
    }

    // Sync super admin if this is the configured owner email
    if (user.email === superAdminEmail) {
      await syncSuperAdminAccount();
      user.role = "super_admin";
      user.approved = true;
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
