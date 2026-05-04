// All user/client business logic
const bcrypt = require("bcryptjs");
const jwt = require("jsonwebtoken");

const { jwtSecret } = require("../../config/env");
const { User } = require("../../models");

// ── Helpers ───────────────────────────────────────────────────────────────────

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

// ── Controllers ───────────────────────────────────────────────────────────────

// POST /api/auth/user/login
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

    // Only match role === 'user' — blocks drivers and admins from user login endpoint
    const user = rawIdentifier.includes("@")
      ? await User.findOne({ email, role: "user" })
      : await User.findOne({ $or: [{ email }, { phone }], role: "user" });

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
};

// GET /api/auth/me  (any authenticated user)
const getMe = async (req, res) => {
  try {
    return res.json({ user: sanitizeUser(req.auth.user) });
  } catch (err) {
    return res.status(500).json({ message: "Could not fetch profile." });
  }
};

// GET /api/users  (super admin lists all users)
const listUsers = async (req, res) => {
  try {
    const users = await User.find({}).sort({ createdAt: -1, email: 1 });
    return res.json(users.map(sanitizeUser));
  } catch (err) {
    return res.status(500).json({ message: "Could not fetch users." });
  }
};

module.exports = {
  login,
  getMe,
  listUsers,
};
