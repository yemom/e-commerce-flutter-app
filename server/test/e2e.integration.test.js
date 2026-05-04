const test = require('node:test');
const assert = require('node:assert/strict');
const fetch = global.fetch || require('node-fetch');

const { connectToDatabase } = require('../config/database');
const { syncSuperAdminAccount } = require('../utils/super-admin');
const { buildApp } = require('../app');
const mongoose = require('mongoose');
const { superAdminEmail, superAdminPassword } = require('../config/env');

test('full end-to-end: create branch, users, order, assign driver, verify payload', async (t) => {
  // Start DB + app on ephemeral port
  await connectToDatabase();
  await syncSuperAdminAccount();

  const app = buildApp();
  const server = app.listen(0);
  const port = server.address().port;
  const base = `http://127.0.0.1:${port}/api`;

  try {
    // 1) create a customer user
    const customerEmail = `e2e-customer-${Date.now()}@example.com`;
    const customerPassword = 'password123';
    const customerResp = await fetch(`${base}/auth/register`, {
      method: 'POST',
      headers: { 'content-type': 'application/json' },
      body: JSON.stringify({ email: customerEmail, password: customerPassword, fullName: 'E2E Customer' }),
    });
    assert.equal(customerResp.status, 201);
    const customerBody = await customerResp.json();
    const customerId = customerBody.user.id;

    // 2) create a driver account
    const driverEmail = `e2e-driver-${Date.now()}@example.com`;
    const driverPassword = 'driverpass';
    const driverResp = await fetch(`${base}/auth/register`, {
      method: 'POST',
      headers: { 'content-type': 'application/json' },
      body: JSON.stringify({ email: driverEmail, password: driverPassword, fullName: 'E2E Driver', registerAsDriver: true, vehicleType: 'motor', licenseNumber: 'E2E-123' }),
    });
    assert.equal(driverResp.status, 201);
    const driverBody = await driverResp.json();
    const driverId = driverBody.user.id;

    // 3) create a branch
    const branchId = `branch-e2e-${Date.now()}`;
    const branchResp = await fetch(`${base}/branches`, {
      method: 'POST',
      headers: { 'content-type': 'application/json' },
      body: JSON.stringify({ id: branchId, name: 'E2E Branch' }),
    });
    assert.equal(branchResp.status, 201);

    // 4) create an order
    const orderId = `e2e-${Date.now().toString(36)}`;
    const createResp = await fetch(`${base}/orders`, {
      method: 'POST',
      headers: { 'content-type': 'application/json' },
      body: JSON.stringify({
        id: orderId,
        branchId,
        customerId,
        customerName: 'E2E Customer',
        customerEmail,
        deliveryAddress: { label: 'E2E Drop', line1: 'Test st', city: 'City', country: 'CT', lat: 9.01, lng: 38.76 },
        items: [{ productId: 'p-e2e', productName: 'Test', quantity: 1, unitPrice: 10 }],
        payment: { id: `pay-${orderId}`, method: 'cash', amount: 10 },
        subtotal: 10,
        deliveryFee: 5,
        total: 15,
      }),
    });
    assert.equal(createResp.status, 201);
    const created = await createResp.json();
    assert.equal(created.id, orderId);

    // 5) login as admin to get token
    const adminLogin = await fetch(`${base}/auth/admin`, {
      method: 'POST',
      headers: { 'content-type': 'application/json' },
      body: JSON.stringify({ identifier: superAdminEmail, password: superAdminPassword }),
    });
    assert.equal(adminLogin.status, 200);
    const adminBody = await adminLogin.json();
    const token = adminBody.token;
    assert.ok(token);

    // 6) assign driver to order
    const assignResp = await fetch(`${base}/orders/${orderId}/assign-driver`, {
      method: 'POST',
      headers: { 'content-type': 'application/json', Authorization: `Bearer ${token}` },
      body: JSON.stringify({ driverId, location: created.deliveryAddress }),
    });
    assert.equal(assignResp.status, 200);
    const assigned = await assignResp.json();
    assert.equal(assigned.driverId, driverId);
    assert.ok(assigned.assignedDriver && assigned.assignedDriver.id === driverId);

    // 7) fetch order list and validate payload
    const ordersResp = await fetch(`${base}/orders`);
    assert.equal(ordersResp.status, 200);
    const orders = await ordersResp.json();
    const found = orders.find((o) => o.id === orderId);
    assert.ok(found, 'created order should be listed');
    assert.equal(found.driverId, driverId);
    assert.ok(found.assignedDriver && found.assignedDriver.id === driverId);
    assert.equal(found.deliveryAddress.lat, 9.01);
    assert.equal(found.deliveryAddress.lng, 38.76);

  } finally {
    // teardown
    await new Promise((resolve) => server.close(resolve));
    await mongoose.disconnect();
  }
});
