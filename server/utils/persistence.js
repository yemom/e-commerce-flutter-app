// Shares small database helpers for upserts, patch cleanup, search safety, and serialization.
async function upsertById(Model, id, payload) {
  // Idempotent create/update helper used by many route handlers.
  return Model.findOneAndUpdate(
    { id },
    payload,
    {
      returnDocument: 'after',
      upsert: true,
      setDefaultsOnInsert: true,
      runValidators: true,
    },
  );
}

function serializeDocument(document) {
  if (!document) {
    return null;
  }

  // Normalize Mongo documents into API-safe plain JSON objects.
  const plain = document.toObject({
    versionKey: false,
    flattenMaps: true,
    depopulate: true,
  });

  // Hide Mongo internal ObjectId because API uses custom string `id`.
  delete plain._id;
  return plain;
}

function normalizePatch(payload) {
  // Ignore undefined fields so PATCH calls do not accidentally clear values.
  return Object.fromEntries(
    Object.entries(payload || {}).filter(([, value]) => value !== undefined),
  );
}

function escapeRegex(value) {
  // Prevent regular-expression injection in text search filters.
  return String(value).replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
}

module.exports = {
  upsertById,
  serializeDocument,
  normalizePatch,
  escapeRegex,
};

