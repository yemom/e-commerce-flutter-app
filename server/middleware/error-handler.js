// Converts thrown server errors into clear HTTP responses for the frontend.
const { MissingFieldError } = require('../utils/errors');

function createErrorHandler() {
  return (error, req, res, next) => {
    // Validation-style errors should return actionable 4xx responses.
    if (error instanceof MissingFieldError) {
      return res.status(400).json({ message: error.message });
    }

    if (error.name === 'ValidationError') {
      return res.status(400).json({ message: error.message });
    }

    // Duplicate key from Mongo unique indexes.
    if (error.code === 11000) {
      return res.status(409).json({ message: 'A record with that id already exists.' });
    }

    // Multer errors should return client-actionable responses instead of generic 500.
    if (error.name === 'MulterError') {
      if (error.code === 'LIMIT_FILE_SIZE') {
        return res.status(413).json({ message: 'Image is too large. Maximum upload size is 10MB.' });
      }
      return res.status(400).json({ message: error.message || 'Invalid upload request.' });
    }

    // Upload file type validation.
    if (error.message === 'Only image uploads are allowed.') {
      return res.status(400).json({ message: error.message });
    }

    // Unknown errors are logged server-side and returned as generic 500.
    console.error(error);
    return res.status(500).json({ message: 'Internal server error.' });
  };
}

module.exports = {
  createErrorHandler,
};

