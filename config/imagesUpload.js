const crypto = require('crypto');
const multer = require('multer');
const path = require('path');
const fs = require('fs');
const cloudflareService = require('../services/cloudflareService');

const isProduction = process.env.NODE_ENV === 'production';
const uploadDir = path.join(__dirname, '..', 'uploads');

if (!isProduction && !fs.existsSync(uploadDir)) {
  fs.mkdirSync(uploadDir, { recursive: true });
  console.log('[imagesUpload] Created uploads directory:', uploadDir);
}

const storage = isProduction
  ? multer.memoryStorage()
  : multer.diskStorage({
      destination: (req, file, cb) => {
        cb(null, uploadDir);
      },
      filename: (req, file, cb) => {
        const uniqueSuffix = Date.now() + '-' + crypto.randomBytes(8).toString('hex');
        const ext = path.extname(file.originalname);
        const sanitizedName = file.originalname
          .replace(ext, '')
          .toLowerCase()
          .replace(/[^a-z0-9]/g, '-')
          .replace(/-+/g, '-')
          .substring(0, 30);
        
        const finalFilename = `${sanitizedName}-${uniqueSuffix}${ext}`;
        console.log('[imagesUpload] Generated filename:', finalFilename);
        cb(null, finalFilename);
      }
    });

const fileFilter = (req, file, cb) => {
  const allowedMimes = [
    'image/jpeg',
    'image/jpg',
    'image/png',
    'image/gif',
    'image/webp',
    'image/svg+xml'
  ];

  if (allowedMimes.includes(file.mimetype)) {
    console.log('[imagesUpload] File accepted:', file.originalname, file.mimetype);
    cb(null, true);
  } else {
    console.error('[imagesUpload] File rejected:', file.originalname, file.mimetype);
    cb(new Error(`Invalid file type. Allowed: ${allowedMimes.join(', ')}`), false);
  }
};

const upload = multer({
  storage: storage,
  limits: {
    fileSize: 10 * 1024 * 1024,
    files: 10
  },
  fileFilter: fileFilter
});

const processUploadedFiles = async (files) => {
  if (!files || files.length === 0) {
    console.log('[processUploadedFiles] No files to process');
    return [];
  }

  console.log('[processUploadedFiles] Processing', files.length, 'file(s)');

  if (isProduction && cloudflareService.isEnabled()) {
    try {
      console.log('[processUploadedFiles] Uploading to Cloudflare R2...');
      const uploadedFiles = await cloudflareService.uploadMultipleFiles(files, 'uploads');
      
      const processedFiles = uploadedFiles.map((uploaded, index) => {
        const file = files[index];
        console.log('[processUploadedFiles] Cloudflare upload success:', uploaded.url);
        return {
          url: uploaded.url,
          originalname: file.originalname,
          filename: uploaded.fileName,
          size: file.size,
          mimetype: file.mimetype,
          cloudflare_id: uploaded.cloudflareId,
          storage_provider: 'cloudflare',
          width: null,
          height: null,
          variants: null
        };
      });
      
      return processedFiles;
    } catch (error) {
      console.error('[processUploadedFiles] Cloudflare upload failed:', error.message);
      throw new Error(`Failed to upload to Cloudflare: ${error.message}`);
    }
  } else {
    const processedFiles = files.map(file => {
      console.log('[processUploadedFiles] File details:', {
        originalname: file.originalname,
        filename: file.filename,
        size: file.size,
        mimetype: file.mimetype,
        path: file.path
      });

      const fileUrl = `/uploads/${file.filename}`;

      const processed = {
        url: fileUrl,
        originalname: file.originalname,
        filename: file.filename,
        size: file.size,
        mimetype: file.mimetype,
        cloudflare_id: null,
        storage_provider: 'local',
        width: null,
        height: null,
        variants: null
      };

      console.log('[processUploadedFiles] Processed file:', processed);
      return processed;
    });

    return processedFiles;
  }
};

module.exports = { 
  upload, 
  processUploadedFiles,
  isProduction 
};