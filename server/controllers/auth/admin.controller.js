// All admin/super_admin business logic
const crypto = require("crypto");
const bcrypt = require("bcryptjs");
const jwt = require("jsonwebtoken");

const { jwtSecret, superAdminEmail } = require("../../config/env");
const { User, Order } = require("../../models");
const { syncSuperAdminAccount } = require("../../utils/super-admin");

// ── Helpers ───────────────────────────────────────────────────────────────────

function normalizeEmail(value) {
  return String(value || "")
    .trim()
    .toLowerCase();
}

function normalizePhone(value) {
  return String(value || "").trim();
}

function normalizeString(value) {
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

// POST /api/auth/admin/login
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

    // Only match admin or super_admin roles
    const user = rawIdentifier.includes("@")
      ? await User.findOne({ email, role: { $in: ["admin", "super_admin"] } })
      : await User.findOne({
          $or: [{ email }, { phone }],
          role: { $in: ["admin", "super_admin"] },
        });

    if (!user) {
      return res.status(401).json({ message: "Invalid credentials." });
    }

    const matches = await bcrypt.compare(password, user.passwordHash);
    if (!matches) {
      return res.status(401).json({ message: "Invalid credentials." });
    }

    if (user.role === "admin" && !user.approved) {
      return res.status(403).json({
        message: "Your admin account is waiting for super admin approval.",
      });
    }

    if (user.email === superAdminEmail) {
      await syncSuperAdminAccount();
      user.role = "super_admin";
      user.approved = true;
    }

    return res.json({ token: signToken(user), user: sanitizeUser(user) });
  } catch (err) {
    return res.status(500).json({ message: "Login failed. Please try again." });
  }
};

// GET /api/auth/admin-accounts  (super admin lists all admins)
const listAdminAccounts = async (req, res) => {
  try {
    const accounts = await User.find({
      role: { $in: ["admin", "super_admin"] },
    }).sort({ email: 1 });
    return res.json(accounts.map(sanitizeUser));
  } catch (err) {
    return res.status(500).json({ message: "Could not fetch admin accounts." });
  }
};

// GET /api/auth/admin-accounts/:userId
const getAdminAccount = async (req, res) => {
  try {
    const user = await User.findOne({
      id: req.params.userId,
      role: { $in: ["admin", "super_admin"] },
    });
    if (!user)
      return res.status(404).json({ message: "Admin account not found." });
    return res.json(sanitizeUser(user));
  } catch (err) {
    return res.status(500).json({ message: "Could not fetch admin account." });
  }
};

// POST /api/auth/admin-accounts  (super admin creates admin)
const createAdminAccount = async (req, res) => {
  try {
    const name = normalizeString(req.body.name);
    const email = normalizeEmail(req.body.email);
    const password = normalizeString(req.body.password);

    if (!name)
      return res.status(400).json({ message: "Please enter the admin name." });
    if (!email || !email.includes("@")) {
      return res
        .status(400)
        .json({ message: "Please enter a valid admin email address." });
    }
    if (password.length < 6) {
      return res.status(400).json({
        message: "Admin password must be at least 6 characters long.",
      });
    }

    const existing = await User.findOne({ email });
    if (existing)
      return res
        .status(409)
        .json({ message: "This email is already registered." });

    const user = await User.create({
      id: crypto.randomUUID(),
      email,
      name,
      passwordHash: await bcrypt.hash(password, 10),
      role: email === superAdminEmail ? "super_admin" : "admin",
      approved: email === superAdminEmail,
    });

    return res.status(201).json(sanitizeUser(user));
  } catch (err) {
    return res.status(500).json({ message: "Could not create admin account." });
  }
};

// PATCH /api/auth/admin-accounts/:userId
const updateAdminAccount = async (req, res) => {
  try {
    const updates = {};
    const name = normalizeString(req.body.name);
    const email = normalizeEmail(req.body.email);

    if (name) updates.name = name;
    if (email) updates.email = email;
    if (Object.keys(updates).length === 0) {
      return res
        .status(400)
        .json({ message: "At least one field is required." });
    }

    const user = await User.findOneAndUpdate(
      { id: req.params.userId, role: { $in: ["admin", "super_admin"] } },
      { $set: updates },
      { returnDocument: "after" },
    );
    if (!user)
      return res.status(404).json({ message: "Admin account not found." });

    return res.json(sanitizeUser(user));
  } catch (err) {
    return res.status(500).json({ message: "Could not update admin account." });
  }
};

// POST /api/auth/admin-accounts/promote
const promoteToAdmin = async (req, res) => {
  try {
    const email = normalizeEmail(req.body.email);
    if (!email) return res.status(400).json({ message: "Email is required." });

    const user = await User.findOneAndUpdate(
      { email },
      {
        $set: {
          role: email === superAdminEmail ? "super_admin" : "admin",
          approved: email === superAdminEmail,
        },
      },
      { returnDocument: "after" },
    );
    if (!user) {
      return res.status(404).json({
        message:
          "No user was found with that email. Ask them to sign up first.",
      });
    }

    return res.json(sanitizeUser(user));
  } catch (err) {
    return res.status(500).json({ message: "Could not promote user." });
  }
};

// PATCH /api/auth/admin-accounts/:userId/approval
const updateApproval = async (req, res) => {
  try {
    const { approved } = req.body;
    if (typeof approved !== "boolean") {
      return res
        .status(400)
        .json({ message: "approved must be true or false." });
    }

    const user = await User.findOneAndUpdate(
      { id: req.params.userId, role: "admin" },
      { $set: { approved } },
      { returnDocument: "after" },
    );
    if (!user)
      return res.status(404).json({ message: "Admin account not found." });

    return res.json(sanitizeUser(user));
  } catch (err) {
    return res.status(500).json({ message: "Could not update approval." });
  }
};

// DELETE /api/auth/admin-accounts/:userId/admin-access
const revokeAdminAccess = async (req, res) => {
  try {
    const user = await User.findOneAndUpdate(
      { id: req.params.userId },
      { $set: { role: "user", approved: true } },
      { returnDocument: "after" },
    );
    if (!user) return res.status(404).json({ message: "User not found." });

    return res.status(204).send();
  } catch (err) {
    return res.status(500).json({ message: "Could not revoke admin access." });
  }
};

module.exports = {
  login,
  listAdminAccounts,
  getAdminAccount,
  createAdminAccount,
  updateAdminAccount,
  promoteToAdmin,
  updateApproval,
  revokeAdminAccess,
};
