// Handles driver auth + management

const express = require("express");
const bcrypt = require("bcryptjs");
const jwt = require("jsonwebtoken");
const crypto = require("crypto");

const { jwtSecret } = require("../config/env");
const { Driver, Order } = require("../models");
const { serializeDocument } = require("../utils/persistence");

function createDriversRouter() {
  const router = express.Router();

  // REGISTER
  router.post("/drivers/register", async (req, res) => {
    const { name, phone, password } = req.body;

    if (!name || !phone || !password) {
      return res.status(400).json({ message: "Missing fields" });
    }

    const hash = await bcrypt.hash(password, 10);

    const driver = await Driver.create({
      id: crypto.randomUUID(),
      name,
      phone,
      passwordHash: hash,
      isOnline: true,
    });

    const token = jwt.sign({ sub: driver.id, role: "driver" }, jwtSecret, {
      expiresIn: "7d",
    });

    res.json({ token, driver });
  });

  // LOGIN
  router.post("/drivers/login", async (req, res) => {
    const { phone, password } = req.body;

    const driver = await Driver.findOne({ phone });
    if (!driver) return res.status(401).json({ message: "Invalid" });

    const ok = await bcrypt.compare(password, driver.passwordHash);
    if (!ok) return res.status(401).json({ message: "Invalid" });

    const token = jwt.sign({ sub: driver.id, role: "driver" }, jwtSecret, {
      expiresIn: "7d",
    });

    res.json({ token, driver });
  });

  // GET MY ORDERS
  router.get("/drivers/:id/orders", async (req, res) => {
    const orders = await Order.find({ driverId: req.params.id });
    res.json(orders.map(serializeDocument));
  });

  return router;
}

module.exports = { createDriversRouter };
