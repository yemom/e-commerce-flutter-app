// Wires together the Express app, shared middleware, API routes, and static uploads.
const express = require('express');
const path = require('path');
const cors = require('cors');
const { corsOrigins } = require('./config/env');
const { createErrorHandler } = require('./middleware/error-handler');
const { createNotFoundHandler } = require('./middleware/not-found');
const { createAuthRouter } = require('./routes/auth');
const { createBranchesRouter } = require('./routes/branches');
const { createCategoriesRouter } = require('./routes/categories');
const { createHealthRouter } = require('./routes/health');
const { createOrdersRouter } = require('./routes/orders');
const { createPaymentOptionsRouter } = require('./routes/payment-options');
const { createPaymentsRouter } = require('./routes/payments');
const { createProductsRouter } = require('./routes/products');
const { createUploadsRouter } = require('./routes/uploads');

function buildApp() {
  const app = express();

  // CORS is opened either for all origins ('*') or for the explicit allow-list from .env.
  app.use(
    cors({
      origin: corsOrigins.length === 1 && corsOrigins[0] === '*' ? true : corsOrigins,
    }),
  );
  // Parse JSON request bodies for API routes.
  app.use(express.json({ limit: '1mb' }));
  // Serve uploaded files so returned URLs can be rendered directly in the app.
  app.use('/uploads', express.static(path.resolve(__dirname, 'uploads')));

  // API route groups.
  app.use('/api', createHealthRouter());
  app.use('/api', createAuthRouter());
  app.use('/api', createBranchesRouter());
  app.use('/api', createCategoriesRouter());
  app.use('/api', createProductsRouter());
  app.use('/api', createUploadsRouter());
  app.use('/api', createOrdersRouter());
  app.use('/api', createPaymentOptionsRouter());
  app.use('/api', createPaymentsRouter());

  // Keep these last so they run only when no route matched or when an error bubbles up.
  app.use(createNotFoundHandler());
  app.use(createErrorHandler());

  return app;
}

module.exports = {
  buildApp,
};

