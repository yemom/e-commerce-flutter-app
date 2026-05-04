const test = require('node:test');
const assert = require('node:assert/strict');

const {
  normalizeDeliveryAddress,
  pickFirstNonEmpty,
  serializeAssignedDriver,
  serializeOrderForClient,
} = require('../routes/orders');

test('pickFirstNonEmpty returns the first usable contact field', () => {
  assert.equal(pickFirstNonEmpty('', null, '  ', 'driver@example.com', 'fallback'), 'driver@example.com');
});

test('serializeAssignedDriver falls back from phone to email and preserves driver metadata', () => {
  const driver = {
    id: 'driver-1',
    name: 'Nuhamin Yenesew',
    phone: '',
    email: 'nunu@dev.com',
    vehicleType: 'motor',
    licenseNumber: 'ABC12345',
    isOnline: true,
  };

  assert.deepEqual(serializeAssignedDriver(driver), {
    id: 'driver-1',
    name: 'Nuhamin Yenesew',
    phone: 'nunu@dev.com',
    email: 'nunu@dev.com',
    contact: 'nunu@dev.com',
    vehicleType: 'motor',
    licenseNumber: 'ABC12345',
    isOnline: true,
  });
});

test('normalizeDeliveryAddress keeps coordinates and trims address fields', () => {
  assert.deepEqual(
    normalizeDeliveryAddress({
      label: '  Home ',
      line1: '  Bole road  ',
      city: ' Addis Ababa ',
      country: ' Ethiopia ',
      lat: '9.01',
      lng: 38.76,
    }),
    {
      label: 'Home',
      line1: 'Bole road',
      line2: '',
      city: 'Addis Ababa',
      state: '',
      postalCode: '',
      country: 'Ethiopia',
      lat: 9.01,
      lng: 38.76,
    },
  );
});

test('serializeOrderForClient exposes a hydrated assignedDriver payload', () => {
  const order = {
    id: 'order-1',
    customerId: 'user-1',
    customerName: 'Customer Name',
    customerEmail: 'customer@example.com',
    deliveryAddress: {
      label: 'Drop point',
      line1: 'Addis Ababa',
      lat: 9.01,
      lng: 38.76,
    },
    driverId: 'driver-1',
  };

  // The order already carries customer fields, so this test stays focused on the driver hydration path.
  const customerById = new Map();
  const driverById = new Map([
    ['driver-1', { id: 'driver-1', name: 'Nuhamin Yenesew', phone: '', email: 'nunu@dev.com', vehicleType: 'motor', licenseNumber: 'ABC12345', isOnline: false }],
  ]);

  const document = {
    ...order,
    toObject() {
      return { ...order };
    },
  };

  const serialized = serializeOrderForClient(document, customerById, driverById);

  assert.deepEqual(serialized.deliveryAddress, {
    label: 'Drop point',
    line1: 'Addis Ababa',
    line2: '',
    city: '',
    state: '',
    postalCode: '',
    country: '',
    lat: 9.01,
    lng: 38.76,
  });
  assert.deepEqual(serialized.assignedDriver, {
    id: 'driver-1',
    name: 'Nuhamin Yenesew',
    phone: 'nunu@dev.com',
    email: 'nunu@dev.com',
    contact: 'nunu@dev.com',
    vehicleType: 'motor',
    licenseNumber: 'ABC12345',
    isOnline: false,
  });
});