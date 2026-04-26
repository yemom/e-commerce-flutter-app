// Keeps the allowed order and payment status values in one shared place.
const ORDER_STATUSES = ['pending', 'confirmed', 'shipped', 'delivered'];
const PAYMENT_STATUSES = ['pending', 'verified', 'failed'];

module.exports = {
  ORDER_STATUSES,
  PAYMENT_STATUSES,
};

