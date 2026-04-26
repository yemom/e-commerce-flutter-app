// Re-exports all Mongoose models so route files can import them from one place.
const Branch = require('./branch');
const Category = require('./category');
const Product = require('./product');
const PaymentOption = require('./payment-option');
const PaymentRecord = require('./payment-record');
const Order = require('./order');
const User = require('./user');

module.exports = {
  Branch,
  Category,
  Product,
  PaymentOption,
  PaymentRecord,
  Order,
  User,
};

