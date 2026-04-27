// Accepts product image uploads, stores them on disk, and returns a usable image URL.
const fs = require('fs');
const path = require('path');
const crypto = require('crypto');
const express = require('express');
const multer = require('multer');

// Product images are saved locally under server/uploads/products.
const uploadsRoot = path.resolve(__dirname, '..', 'uploads', 'products');

function ensureUploadsDirectory() {
  // Create upload directory on demand so first upload works without manual setup.
  fs.mkdirSync(uploadsRoot, { recursive: true });
}

function sanitizeFileName(name) {
  // Keep filenames URL-safe and filesystem-safe.
  return name
    .toLowerCase()
    .replace(/[^a-z0-9.\-_]+/g, '-')
    .replace(/-+/g, '-')
    .replace(/^-|-$/g, '');
}

function isAllowedImageExtension(name) {
  const extension = path.extname(name || '').toLowerCase();
  return ['.jpg', '.jpeg', '.png', '.webp', '.gif', '.heic', '.heif'].includes(extension);
}

function resolveExtension(originalName, mimeType) {
  // Prefer extension from filename when valid.
  const parsedExt = path.extname(originalName || '').toLowerCase();
  if (['.jpg', '.jpeg', '.png', '.webp', '.gif', '.heic', '.heif'].includes(parsedExt)) {
    return parsedExt;
  }

  // Fall back to MIME type mapping.
  switch ((mimeType || '').toLowerCase()) {
    case 'image/png':
      return '.png';
    case 'image/webp':
      return '.webp';
    case 'image/gif':
      return '.gif';
    case 'image/jpeg':
    default:
      return '.jpg';
  }
}

// Multer stores uploaded files directly on disk.
const storage = multer.diskStorage({
  destination: (req, file, cb) => {
    ensureUploadsDirectory();
    cb(null, uploadsRoot);
  },
  filename: (req, file, cb) => {
    // Add timestamp + random suffix to avoid collisions.
    const extension = resolveExtension(file.originalname, file.mimetype);
    const baseName = sanitizeFileName(path.basename(file.originalname || 'image', path.extname(file.originalname || '')));
    const unique = crypto.randomBytes(8).toString('hex');
    cb(null, `${baseName || 'image'}-${Date.now()}-${unique}${extension}`);
  },
});

const upload = multer({
  storage,
  limits: {
    // Prevent very large image uploads, while allowing modern phone photos.
    fileSize: 10 * 1024 * 1024,
  },
  fileFilter: (req, file, cb) => {
    // Accept standard image MIME types and Android generic uploads with image extensions.
    const mimeType = (file.mimetype || '').toLowerCase();
    const hasImageMime = mimeType.startsWith('image/');
    const hasImageExtension = isAllowedImageExtension(file.originalname || '');
    const isGenericBinary = mimeType === '' || mimeType === 'application/octet-stream';

    if (!hasImageMime && !(isGenericBinary && hasImageExtension)) {
      cb(new Error('Only image uploads are allowed.'));
      return;
    }
    cb(null, true);
  },
});

function createUploadsRouter() {
  const router = express.Router();

  // Expects multipart/form-data with a single file field named "image".
  router.post('/uploads/products', upload.single('image'), (req, res) => {
    if (!req.file) {
      return res.status(400).json({ message: 'No image file uploaded. Use form field name "image".' });
    }

    // Return a fully qualified URL the frontend can store in product.imageUrl.
    const imageUrl = `${req.protocol}://${req.get('host')}/uploads/products/${req.file.filename}`;
    return res.status(201).json({ imageUrl });
  });

  return router;
}

module.exports = {
  createUploadsRouter,
};

