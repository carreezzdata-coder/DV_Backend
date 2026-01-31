const fs = require('fs');
const path = require('path');

const clientPath = path.join(process.cwd(), 'routes/api/client.js');

console.log('🔧 Fixing duplicate getImageUrl in client.js...\n');

if (!fs.existsSync(clientPath)) {
  console.error('❌ File not found:', clientPath);
  process.exit(1);
}

let content = fs.readFileSync(clientPath, 'utf8');

const correctVersion = `const express = require('express');
const router = express.Router();
const { getPool } = require('../../config/db');
const cloudflareService = require('../../services/cloudflareService');
const { FRONTEND_URL, CLIENT_URL, ADMIN_URL, API_DOMAIN, ALLOWED_ORIGINS, isOriginAllowed } = require('../../config/frontendconfig');

const getImageUrl = (imageUrl) => {
  if (!imageUrl) return null;
  if (imageUrl.startsWith('http://') || imageUrl.startsWith('https://')) return imageUrl;
  const cleanPath = imageUrl.startsWith('/') ? imageUrl.substring(1) : imageUrl;
  if (cloudflareService.isEnabled()) {
    return cloudflareService.getPublicUrl(cleanPath);
  }
  const isProduction = process.env.NODE_ENV === 'production' || process.env.VERCEL_ENV === 'production' || process.env.RENDER === 'true';
  if (!isProduction) return \`http://localhost:5000/\${cleanPath}\`;
  const r2Url = process.env.R2_PUBLIC_URL;
  if (r2Url) {
    const cleanUrl = r2Url.endsWith('/') ? r2Url.slice(0, -1) : r2Url;
    return \`\${cleanUrl}/\${cleanPath}\`;
  }
  return \`https://www.dailyvaibe.com/\${cleanPath}\`;
};`;

const duplicatePattern = /const express = require\('express'\);[\s\S]*?const getImageUrl = \(imageUrl\)[\s\S]*?\n\};[\s\S]*?const { FRONTEND_URL[\s\S]*?const getImageUrl = \(imageUrl\)[\s\S]*?\n\};/;

if (duplicatePattern.test(content)) {
  content = content.replace(duplicatePattern, correctVersion);
  fs.writeFileSync(clientPath, content, 'utf8');
  console.log('✅ Fixed duplicate getImageUrl declaration');
  console.log('✅ Merged imports and kept single Cloudflare-enabled version');
} else {
  console.log('ℹ️  No duplicate found or already fixed');
}

console.log('\n✨ Client.js is now clean!');