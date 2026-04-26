// Centralizes MongoDB connection setup so the server can start with one shared database helper.
const mongoose = require('mongoose');
const { mongoUri } = require('./env');

// Keep query behavior explicit and compatible across Mongoose versions.
mongoose.set('strictQuery', true);

async function connectToDatabase() {
  if (!mongoUri) {
    throw new Error('MONGODB_URI is missing. Add it to server/.env before starting the API.');
  }

  // Fail quickly when Atlas/local Mongo is unreachable to avoid hanging startup.
  await mongoose.connect(mongoUri, {
    serverSelectionTimeoutMS: 10000,
  });
}

module.exports = {
  connectToDatabase,
};

