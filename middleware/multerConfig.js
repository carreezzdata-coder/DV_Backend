const multer = require('multer');
const path = require('path');
const fs = require('fs');
const crypto = require('crypto');

const isProduction = process.env.NODE_ENV === 'production';

const uploadDir = path.join(__dirname, '..', 'uploads');
if (!fs.existsSync(uploadDir)) {
  fs.mkdirSync(uploadDir, { recursive: true });
}

const storage = multer.diskStorage({
  destination: (req, file, cb) => {
    cb(null, uploadDir);
  },
  filename: (req, file, cb) => {
    const uniqueSuffix = `${Date.now()}-${crypto.randomBytes(6).toString('hex')}`;
    const ext = path.extname(file.originalname);
    const basename = path.basename(file.originalname, ext);
    const sanitized = basename.replace(/[^a-zA-Z0-9_-]/g, '_');
    cb(null, `${sanitized}-${uniqueSuffix}${ext}`);
  }
});

const fileFilter = (req, file, cb) => {
  const allowedMimes = [
    'image/jpeg',
    'image/jpg',
    'image/png',
    'image/gif',
    'image/webp',
    'image/svg+xml',
    'video/mp4',
    'video/webm',
    'video/ogg',
    'application/pdf'
  ];

  if (allowedMimes.includes(file.mimetype)) {
    cb(null, true);
  } else {
    cb(new Error(`File type not allowed: ${file.mimetype}`), false);
  }
};

const upload = multer({
  storage: storage,
  fileFilter: fileFilter,
  limits: {
    fileSize: 50 * 1024 * 1024,
    files: 10,
    fields: 50,
    parts: 100
  }
});

const handleMulterError = (err, req, res, next) => {
  if (err instanceof multer.MulterError) {
    console.error('❌ Multer Error:', err.code, err.field);
    
    const errorMessages = {
      LIMIT_FILE_SIZE: 'File size exceeds 50MB limit',
      LIMIT_FILE_COUNT: 'Too many files uploaded',
      LIMIT_FIELD_COUNT: 'Too many fields',
      LIMIT_UNEXPECTED_FILE: `Unexpected file field: ${err.field}`,
      LIMIT_PART_COUNT: 'Too many parts in multipart data'
    };

    return res.status(400).json({
      success: false,
      error: 'File upload error',
      message: errorMessages[err.code] || err.message,
      code: err.code,
      field: err.field
    });
  }

  if (err) {
    console.error('❌ Upload Error:', err.message);
    return res.status(400).json({
      success: false,
      error: 'Upload failed',
      message: err.message
    });
  }

  next();
};

module.exports = {
  upload,
  handleMulterError,
  uploadDir
};