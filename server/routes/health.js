// Exposes a simple health endpoint so clients can confirm the backend is running.
const express = require('express');

function createHealthRouter() {
  const router = express.Router();

  router.get('/health', (req, res) => {
    // Simple liveness endpoint used by local checks and deployment probes.
    res.json({ status: 'ok', timestamp: new Date().toISOString() });
  });

  return router;
}

module.exports = {
  createHealthRouter,
};

