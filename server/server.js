// Starts the API server, connects to MongoDB, and bootstraps the default super admin.
const { port } = require('./config/env');
const { connectToDatabase } = require('./config/database');
const { buildApp } = require('./app');
const models = require('./models');
const { syncSuperAdminAccount } = require('./utils/super-admin');

async function startServer() {
  // 1) Connect to MongoDB before serving requests.
  await connectToDatabase();
  // 2) Ensure the configured super admin account exists and is up to date.
  await syncSuperAdminAccount();
  // 3) Build the Express app with all middleware and routes.
  const app = buildApp();

  // 4) Start listening only after dependencies above are ready.
  app.listen(port, () => {
    console.log('MongoDB connected');
    console.log(`API running on http://localhost:${port}`);
  });
}

if (require.main === module) {
  // Crash fast on startup failures so deploy/run scripts can detect the error.
  startServer().catch((error) => {
    console.error('Failed to start API:', error.message);
    process.exit(1);
  });
}

module.exports = {
  buildApp,
  connectToDatabase,
  startServer,
  models,
};

