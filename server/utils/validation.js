// Provides small reusable request validation helpers for required API fields.
const { MissingFieldError } = require('./errors');

function requireFields(payload, fields) {
  // Shared guard for required request fields in route handlers.
  for (const field of fields) {
    const value = payload?.[field];
    if (value === undefined || value === null || value === '') {
      throw new MissingFieldError(`${field} is required.`);
    }
  }
}

module.exports = {
  requireFields,
};

