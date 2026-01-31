const { S3Client, PutObjectCommand, DeleteObjectCommand, ListObjectsV2Command } = require('@aws-sdk/client-s3');

class CloudflareService {
  constructor() {
    this.accountId = process.env.CLOUDFLARE_ACCOUNT_ID;
    this.accessKeyId = process.env.R2_ACCESS_KEY_ID;
    this.secretAccessKey = process.env.R2_SECRET_ACCESS_KEY;
    this.bucketName = process.env.R2_BUCKET_NAME;
    this.publicUrl = process.env.R2_PUBLIC_URL;

    this.enabled = !!(this.accountId && this.accessKeyId && this.secretAccessKey && this.bucketName);

    if (this.enabled) {
      this.client = new S3Client({
        region: 'auto',
        endpoint: `https://${this.accountId}.r2.cloudflarestorage.com`,
        credentials: {
          accessKeyId: this.accessKeyId,
          secretAccessKey: this.secretAccessKey,
        },
      });
      console.log('Cloudflare R2 initialized successfully');
    } else {
      console.warn('Cloudflare R2 not configured');
    }
  }

  isEnabled() {
    return this.enabled;
  }

  async uploadFile(file, folder = 'uploads') {
    if (!this.enabled) {
      throw new Error('Cloudflare R2 is not configured');
    }

    const timestamp = Date.now();
    const sanitizedName = file.originalname
      .toLowerCase()
      .replace(/[^a-z0-9.]/g, '-')
      .replace(/-+/g, '-');
    const fileName = `${folder}/${timestamp}-${sanitizedName}`;

    const command = new PutObjectCommand({
      Bucket: this.bucketName,
      Key: fileName,
      Body: file.buffer,
      ContentType: file.mimetype,
      CacheControl: 'public, max-age=31536000, immutable',
      Metadata: {
        originalName: file.originalname,
        uploadedAt: new Date().toISOString(),
      }
    });

    await this.client.send(command);

    return {
      fileName,
      url: `${this.publicUrl}/${fileName}`,
      size: file.size,
      mimeType: file.mimetype,
      provider: 'cloudflare',
      cloudflareId: fileName
    };
  }

  async uploadMultipleFiles(files, folder = 'uploads') {
    if (!this.enabled) {
      throw new Error('Cloudflare R2 is not configured');
    }

    const uploadPromises = files.map(file => this.uploadFile(file, folder));
    return await Promise.all(uploadPromises);
  }

  async deleteFile(fileName) {
    if (!this.enabled) {
      throw new Error('Cloudflare R2 is not configured');
    }

    const command = new DeleteObjectCommand({
      Bucket: this.bucketName,
      Key: fileName,
    });

    await this.client.send(command);
    return { success: true, fileName };
  }

  async deleteMultipleFiles(fileNames) {
    if (!this.enabled) {
      throw new Error('Cloudflare R2 is not configured');
    }

    const deletePromises = fileNames.map(fileName => this.deleteFile(fileName));
    const results = await Promise.allSettled(deletePromises);
    
    return results.map((result, index) => ({
      fileName: fileNames[index],
      success: result.status === 'fulfilled',
      error: result.status === 'rejected' ? result.reason.message : null
    }));
  }

  async listFiles(prefix = '', maxKeys = 100) {
    if (!this.enabled) {
      throw new Error('Cloudflare R2 is not configured');
    }

    const command = new ListObjectsV2Command({
      Bucket: this.bucketName,
      Prefix: prefix,
      MaxKeys: maxKeys,
    });

    const response = await this.client.send(command);

    return {
      files: response.Contents || [],
      count: response.KeyCount || 0
    };
  }

  getPublicUrl(fileName) {
    if (!this.enabled || !this.publicUrl) {
      return null;
    }
    return `${this.publicUrl}/${fileName}`;
  }

  async uploadBuffer(buffer, fileName, mimeType, folder = 'uploads') {
    if (!this.enabled) {
      throw new Error('Cloudflare R2 is not configured');
    }

    const timestamp = Date.now();
    const fullFileName = `${folder}/${timestamp}-${fileName}`;

    const command = new PutObjectCommand({
      Bucket: this.bucketName,
      Key: fullFileName,
      Body: buffer,
      ContentType: mimeType,
      CacheControl: 'public, max-age=31536000, immutable',
    });

    await this.client.send(command);

    return {
      fileName: fullFileName,
      url: `${this.publicUrl}/${fullFileName}`,
      size: buffer.length,
      mimeType,
      provider: 'cloudflare'
    };
  }
}

module.exports = new CloudflareService();