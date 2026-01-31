require('dotenv').config();

const isProduction = process.env.NODE_ENV === 'production';
const isStaging = process.env.NODE_ENV === 'staging';

const FRONTEND_CONFIG = {
  production: {
    DOMAIN: 'https://dailyvaibe.com',
    ADMIN_DOMAIN: 'https://admin.dailyvaibe.com',
    API_DOMAIN: 'https://api.dailyvaibe.com',
    FRONTEND_URL: process.env.FRONTEND_URL || 'https://dailyvaibe.com',
    CLIENT_URL: process.env.CLIENT_URL || 'https://dailyvaibe.com',
    ADMIN_URL: process.env.ADMIN_URL || 'https://admin.dailyvaibe.com',
    ALLOWED_ORIGINS: [
      'https://www.dailyvaibe.com',
      'https://dailyvaibe.com',
      'https://admin.dailyvaibe.com',
      'https://api.dailyvaibe.com',
      'https://dailyvaibe-frontend.onrender.com',
      'https://dailyvaibe-backend.onrender.com',
      process.env.FRONTEND_URL,
      process.env.CLIENT_URL,
      process.env.ADMIN_URL,
      process.env.CORS_ORIGIN
    ].filter(Boolean)
  },
  
  staging: {
    DOMAIN: 'https://staging.dailyvaibe.com',
    ADMIN_DOMAIN: 'https://staging-admin.dailyvaibe.com',
    API_DOMAIN: 'https://staging-api.dailyvaibe.com',
    FRONTEND_URL: process.env.FRONTEND_URL || 'https://staging.dailyvaibe.com',
    CLIENT_URL: process.env.CLIENT_URL || 'https://staging.dailyvaibe.com',
    ADMIN_URL: process.env.ADMIN_URL || 'https://staging-admin.dailyvaibe.com',
    ALLOWED_ORIGINS: [
      'https://staging.dailyvaibe.com',
      'https://staging-admin.dailyvaibe.com',
      'http://localhost:3000',
      'http://localhost:5000',
      'http://localhost:5173',
      process.env.FRONTEND_URL,
      process.env.CLIENT_URL,
      process.env.ADMIN_URL
    ].filter(Boolean)
  },
  
  development: {
    DOMAIN: 'http://localhost:3000',
    ADMIN_DOMAIN: 'http://localhost:5001',
    API_DOMAIN: 'http://localhost:5000',
    FRONTEND_URL: process.env.FRONTEND_URL || 'http://localhost:3000',
    CLIENT_URL: process.env.CLIENT_URL || 'http://localhost:3000',
    ADMIN_URL: process.env.ADMIN_URL || 'http://localhost:5001',
    ALLOWED_ORIGINS: [
      'http://localhost:3000',
      'http://localhost:5000',
      'http://localhost:5173',
      'http://localhost:5001',
      'http://127.0.0.1:3000',
      'http://127.0.0.1:5000',
      'http://127.0.0.1:5173',
      'http://127.0.0.1:5001'
    ]
  }
};

const env = isProduction ? 'production' : (isStaging ? 'staging' : 'development');
const config = FRONTEND_CONFIG[env];

module.exports = {
  isProduction,
  isStaging,
  isDevelopment: !isProduction && !isStaging,
  
  DOMAIN: config.DOMAIN,
  ADMIN_DOMAIN: config.ADMIN_DOMAIN,
  API_DOMAIN: config.API_DOMAIN,
  FRONTEND_URL: config.FRONTEND_URL,
  CLIENT_URL: config.CLIENT_URL,
  ADMIN_URL: config.ADMIN_URL,
  
  ALLOWED_ORIGINS: config.ALLOWED_ORIGINS,
  
  config,
  
  getFrontendURL: (path = '') => `${config.DOMAIN}${path}`,
  getAdminURL: (path = '') => `${config.ADMIN_DOMAIN}${path}`,
  getAPIURL: (path = '') => `${config.API_DOMAIN}${path}`,
  
  isOriginAllowed: (origin) => {
    if (!origin) return true;
    return config.ALLOWED_ORIGINS.includes(origin);
  }
};