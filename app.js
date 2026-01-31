const express = require('express');
const cors = require('cors');
const session = require('express-session');
const pgSession = require('connect-pg-simple')(session);
const path = require('path');
const helmet = require('helmet');
const compression = require('compression');
const morgan = require('morgan');
const fs = require('fs');
const cluster = require('cluster');
const os = require('os');
require('dotenv').config();

const { getPool } = require('./config/db');
const frontendConfig = require('./config/frontendconfig');
const cloudflareService = require('./services/cloudflareService');

let cacheOptimization, cleanupScheduler, promotionCronService;

try {
  cacheOptimization = require('./services/cacheOptimization');
} catch (e) {
  console.warn('Cache optimization not available');
  cacheOptimization = null;
}

try {
  cleanupScheduler = require('./services/cleanupScheduler');
} catch (e) {
  console.warn('Cleanup scheduler not available');
  cleanupScheduler = null;
}

try {
  promotionCronService = require('./services/promotionCronService');
} catch (e) {
  console.warn('Promotion cron service not available');
  promotionCronService = null;
}
// backend/app.js - INTEGRATION SNIPPET
// Add after line 38 (promotionCronService)

let geoCdnSyncCron;

try {
  geoCdnSyncCron = require('./services/geoCdnSyncCron');
} catch (e) {
  console.warn('GeoCdnSyncCron not available');
  geoCdnSyncCron = null;
}

const isProduction = process.env.NODE_ENV === 'production';
const isStaging = process.env.NODE_ENV === 'staging';
const isDevelopment = !isProduction && !isStaging;
const USE_CLUSTERING = process.env.USE_CLUSTERING === 'true' && isProduction;
const WORKERS = process.env.WORKERS || Math.min(os.cpus().length, 4);

if (USE_CLUSTERING && cluster.isMaster) {
  console.log(`Master ${process.pid} starting ${WORKERS} workers`);
  for (let i = 0; i < WORKERS; i++) {
    cluster.fork();
  }
  cluster.on('exit', (worker) => {
    console.log(`Worker ${worker.process.pid} died. Spawning replacement...`);
    cluster.fork();
  });
  return;
}

const app = express();

app.set('trust proxy', 1);
app.disable('x-powered-by');

const {
  FRONTEND_URL,
  CLIENT_URL,
  ADMIN_URL,
  API_DOMAIN,
  ALLOWED_ORIGINS
} = frontendConfig;

const helmetConfig = {
  crossOriginEmbedderPolicy: false,
  crossOriginResourcePolicy: { policy: 'cross-origin' },
  hsts: {
    maxAge: 31536000,
    includeSubDomains: true,
    preload: true
  },
  frameguard: { action: 'deny' },
  noSniff: true,
  xssFilter: true,
  referrerPolicy: { policy: 'strict-origin-when-cross-origin' }
};

if (isProduction) {
  helmetConfig.contentSecurityPolicy = {
    directives: {
      defaultSrc: ["'self'"],
      styleSrc: ["'self'", "'unsafe-inline'"],
      scriptSrc: ["'self'", "'unsafe-inline'", "'unsafe-eval'"],
      imgSrc: ["'self'", "data:", "blob:", "https:", process.env.R2_PUBLIC_URL].filter(Boolean),
      connectSrc: [
        "'self'",
        FRONTEND_URL,
        CLIENT_URL,
        ADMIN_URL,
        API_DOMAIN,
        process.env.R2_PUBLIC_URL,
        ...ALLOWED_ORIGINS.filter(origin => origin && origin.startsWith('http'))
      ].filter(Boolean),
      fontSrc: ["'self'", "data:", "https:"],
      objectSrc: ["'none'"],
      mediaSrc: ["'self'", "blob:", "https:", process.env.R2_PUBLIC_URL].filter(Boolean),
      frameSrc: ["'none'"],
      workerSrc: ["'self'", "blob:"],
      manifestSrc: ["'self'"],
      upgradeInsecureRequests: []
    }
  };
} else {
  helmetConfig.contentSecurityPolicy = false;
}

app.use(helmet(helmetConfig));

app.use(compression({
  level: isProduction ? 6 : 1,
  threshold: 1024,
  filter: (req, res) => {
    if (req.headers['x-no-compression']) return false;
    return compression.filter(req, res);
  }
}));

if (isProduction) {
  const logsDir = path.join(__dirname, 'logs');
  if (!fs.existsSync(logsDir)) {
    fs.mkdirSync(logsDir, { recursive: true });
  }
  const accessLogStream = fs.createWriteStream(
    path.join(logsDir, 'access.log'),
    { flags: 'a' }
  );
  app.use(morgan('combined', { 
    stream: accessLogStream,
    skip: (req) => req.url === '/health' || req.url === '/health/ready'
  }));
} else {
  app.use(morgan('dev'));
}

const corsOptions = {
  origin: (origin, callback) => {
    if (!origin) return callback(null, true);
    if (isDevelopment) return callback(null, true);
    const normalizedOrigin = origin.replace(/\/$/, '');
    const normalizedAllowed = ALLOWED_ORIGINS.map(o => o.replace(/\/$/, ''));
    if (normalizedAllowed.includes(normalizedOrigin)) {
      return callback(null, true);
    }
    console.warn(`CORS blocked: ${origin}`);
    callback(new Error('Not allowed by CORS'));
  },
  credentials: true,
  methods: ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS', 'PATCH'],
  allowedHeaders: [
    'Content-Type',
    'Authorization',
    'Cookie',
    'X-CSRF-Token',
    'X-Requested-With',
    'Accept',
    'Accept-Version',
    'Content-Length',
    'Content-MD5',
    'Date'
  ],
  exposedHeaders: ['Set-Cookie', 'X-RateLimit-Remaining', 'X-RateLimit-Reset'],
  maxAge: 86400,
  preflightContinue: false,
  optionsSuccessStatus: 204
};

app.use(cors(corsOptions));
app.options('*', cors(corsOptions));

const staticDirs = ['uploads', 'public', 'assets', 'media'];

staticDirs.forEach(dir => {
  const dirPath = path.join(__dirname, dir);
  if (fs.existsSync(dirPath)) {
    app.use(`/${dir}`, express.static(dirPath, {
      maxAge: isProduction ? '30d' : '0',
      etag: true,
      lastModified: true,
      immutable: true,
      setHeaders: (res, filepath) => {
        if (filepath.match(/\.(jpg|jpeg|png|gif|webp|svg)$/i)) {
          res.setHeader('Cache-Control', 'public, max-age=2592000, immutable');
        }
        if (filepath.match(/\.(mp4|webm|ogg)$/i)) {
          res.setHeader('Cache-Control', 'public, max-age=7776000, immutable');
        }
      }
    }));
  }
});

const sessionStore = new pgSession({
  pool: getPool(),
  tableName: 'session_store',
  createTableIfMissing: false,
  pruneSessionInterval: 60 * 30,
  errorLog: isProduction ? () => {} : console.error
});

const sessionConfig = {
  store: sessionStore,
  secret: process.env.SESSION_SECRET || 'dev-secret-change-in-production',
  name: 'dailyvaibe.sid',
  resave: false,
  saveUninitialized: false,
  rolling: true,
  proxy: true,
  cookie: {
    secure: isProduction,
    httpOnly: true,
    maxAge: 7 * 24 * 60 * 60 * 1000,
    sameSite: isProduction ? 'none' : 'lax',
    path: '/',
    domain: isProduction ? '.dailyvaibe.com' : undefined
  }
};

if (!sessionConfig.secret || sessionConfig.secret === 'dev-secret-change-in-production') {
  if (isProduction) {
    console.error('CRITICAL: SESSION_SECRET not set in production!');
    console.error('Set SESSION_SECRET environment variable to a random 64-character string');
    process.exit(1);
  } else {
    console.warn('WARNING: Using default SESSION_SECRET in development');
  }
}

app.use(session(sessionConfig));

const multipartRoutes = [
  '/api/admin/createposts',
  '/api/admin/edit',
  '/api/admin/quotes',
  '/api/admin/socialvideos',
  '/api/admin/socialvideos/edit',
  '/api/admin/customize'
];

app.use((req, res, next) => {
  const isMultipart = multipartRoutes.some(route => req.path.startsWith(route));
  if (isMultipart) {
    return next();
  }
  express.json({ limit: '10mb' })(req, res, next);
});

app.use(express.urlencoded({ extended: true, limit: '10mb' }));

const adminAuth = (req, res, next) => {
  if (req.session && req.session.admin) {
    return next();
  }
  res.status(401).json({
    success: false,
    message: 'Unauthorized',
    requiresAuth: true
  });
};

const routeManifest = [
  { path: '/api/admin/promotions', file: './routes/admin/promotions.js', auth: true },
  { path: '/api/admin/createposts', file: './routes/admin/createposts.js', auth: true },
  { path: '/api/admin/edit', file: './routes/admin/edit.js', auth: true },
  { path: '/api/admin/quotes', file: './routes/admin/quotes.js', auth: true },
  { path: '/api/admin/delete', file: './routes/admin/delete.js', auth: true },
  { path: '/api/admin/customize', file: './routes/admin/customize.js', auth: true },
  { path: '/api/admin/socialvideos/delete', file: './routes/admin/socialvideos/deleteSocialVideos.js', auth: true },
  { path: '/api/admin/socialvideos/togglelive', file: './routes/admin/socialvideos/toggleLiveSocialVideos.js', auth: true },
  { path: '/api/admin/socialvideos/edit', file: './routes/admin/socialvideos/editSocialVideos.js', auth: true },
  { path: '/api/admin/socialvideos/retrieve', file: './routes/admin/socialvideos/retrieveSocialVideos.js', auth: true },
  { path: '/api/admin/socialvideos', file: './routes/admin/socialvideos/socialvideos.js', auth: true },
  { path: '/api/admin/adminmessages', file: './routes/admin/adminmessages.js', auth: true },
  { path: '/api/admin/retrieveposts', file: './routes/admin/retrieveposts.js', auth: true },
  { path: '/api/admin/retrievequotes', file: './routes/admin/retrievequotes.js', auth: true },
  { path: '/api/admin/users', file: './routes/admin/users.js', auth: true },
  { path: '/api/admin/password', file: './routes/admin/password.js', auth: true },
  { path: '/api/admin/userprofile', file: './routes/admin/userprofile.js', auth: true },
  { path: '/api/admin/geo', file: './routes/admin/geo.js', auth: true },
  { path: '/api/admin/system-services/analytics', file: './routes/admin/systemservices/analytics.js', auth: true },
  { path: '/api/admin/system-services/cache', file: './routes/admin/systemservices/cacheManagement.js', auth: true },
  { path: '/api/admin/system-services/cleanup', file: './routes/admin/systemservices/cleanup.js', auth: true },
  { path: '/api/admin/system-services/db-opt', file: './routes/admin/systemservices/databaseOptimization.js', auth: true },
  { path: '/api/admin/system-monitoring', file: './routes/admin/systemservices/systemMonitoring.js', auth: true },
  { path: '/api/admin/userroles', file: './routes/admin/userroles.js', auth: true },
  { path: '/api/admin/categories', file: './routes/admin/categories.js', auth: true },
  { path: '/api/admin/analytics', file: './routes/admin/analytics.js', auth: true },
  { path: '/api/admin/pending', file: './routes/admin/pending.js', auth: true },
  { path: '/api/admin/permissions', file: './routes/admin/permissions.js', auth: true },
  { path: '/api/admin/auth', file: './routes/admin/auth.js', auth: false },
  { path: '/api/home', file: './routes/api/home.js', auth: false },
  { path: '/api/client', file: './routes/api/client.js', auth: false },
  { path: '/api/articles', file: './routes/api/articles.js', auth: false },
  { path: '/api/categories', file: './routes/api/categories.js', auth: false },
  { path: '/api/footer-categories', file: './routes/api/footer-categories.js', auth: false },
  { path: '/api/category-groups', file: './routes/api/category-groups.js', auth: false },
  { path: '/api/search', file: './routes/api/search.js', auth: false },
  { path: '/api/notifications', file: './routes/api/notifications.js', auth: false },
  { path: '/api/ads', file: './routes/api/ads.js', auth: false },
  { path: '/api/interactions', file: './routes/api/interactions.js', auth: false },
  { path: '/api/personalization', file: './routes/api/personalization.js', auth: false },
  { path: '/api/geo', file: './routes/api/geo.js', auth: false },
  { path: '/api/cookies', file: './routes/api/cookies.js', auth: false },
  { path: '/api/clientquotes', file: './routes/api/clientquotes.js', auth: false },
  { path: '/api/fetchall', file: './routes/api/fetchall.js', auth: false },
  { path: '/api/updates/breaking', file: './routes/api/updates/breaking.js', auth: false },
  { path: '/api/updates/featured', file: './routes/api/updates/featured.js', auth: false },
  { path: '/api/updates/pinned', file: './routes/api/updates/pinned.js', auth: false },
  { path: '/api/updates/trending', file: './routes/api/trending.js', auth: false },
  { path: '/api/videos', file: './routes/api/videos.js', auth: false },
  { path: '/api/client/auth', file: './routes/client/auth.js', auth: false },
  { path: '/api/client', file: './routes/client/client.js', auth: false }
];

const routeStats = { loaded: 0, failed: 0 };

routeManifest.forEach(route => {
  try {
    const routeModule = require(route.file);
    if (!routeModule) {
      throw new Error('Route module is undefined');
    }
    if (route.auth) {
      app.use(route.path, adminAuth, routeModule);
    } else {
      app.use(route.path, routeModule);
    }
    routeStats.loaded++;
  } catch (error) {
    console.error(`Failed to load route ${route.path}:`, error.message);
    routeStats.failed++;
    const fallback = (req, res) => {
      res.status(501).json({
        success: false,
        message: 'Route temporarily unavailable',
        route: route.path
      });
    };
    app.use(route.path, route.auth ? adminAuth : (req, res, next) => next(), fallback);
  }
});

console.log(`Routes loaded: ${routeStats.loaded}, Failed: ${routeStats.failed}`);

app.get('/health', async (req, res) => {
  const health = {
    status: 'OK',
    timestamp: new Date().toISOString(),
    uptime: process.uptime(),
    environment: process.env.NODE_ENV || 'development',
    worker: cluster.worker?.id || 'master',
    cloudflare: cloudflareService.isEnabled()
  };
  try {
    const dbStart = Date.now();
    await getPool().query('SELECT 1');
    health.database = {
      status: 'connected',
      latency: `${Date.now() - dbStart}ms`
    };
  } catch (e) {
    health.status = 'DEGRADED';
    health.database = {
      status: 'disconnected',
      error: e.message
    };
  }
  res.status(health.status === 'OK' ? 200 : 503).json(health);
});

app.get('/health/deep', async (req, res) => {
  const checks = {
    timestamp: new Date().toISOString(),
    database: false,
    session: false,
    cloudflare: false,
    cache: false
  };
  try {
    await getPool().query('SELECT 1');
    checks.database = true;
  } catch (e) {
    checks.databaseError = e.message;
  }
  try {
    if (cacheOptimization) {
      checks.cache = true;
      checks.cacheStats = cacheOptimization.getStats();
    }
  } catch (e) {
    checks.cacheError = e.message;
  }
  try {
    checks.session = true;
  } catch (e) {
    checks.sessionError = e.message;
  }
  try {
    checks.cloudflare = cloudflareService.isEnabled();
  } catch (e) {
    checks.cloudflareError = e.message;
  }
  const allHealthy = checks.database && checks.session;
  res.status(allHealthy ? 200 : 503).json(checks);
});

app.get('/health/ready', async (req, res) => {
  try {
    await getPool().query('SELECT 1');
    res.status(200).json({ ready: true });
  } catch (e) {
    res.status(503).json({ ready: false, error: e.message });
  }
});

app.use((req, res, next) => {
  res.status(404).json({
    success: false,
    message: 'Endpoint not found',
    path: req.path,
    method: req.method
  });
});

app.use((err, req, res, next) => {
  const statusCode = err.status || err.statusCode || 500;
  console.error('Application error:', {
    message: err.message,
    stack: isDevelopment ? err.stack : undefined,
    path: req.path,
    method: req.method,
    ip: req.ip
  });
  res.status(statusCode).json({
    success: false,
    message: isProduction ? 'Internal server error' : err.message,
    error: isDevelopment ? {
      stack: err.stack,
      details: err
    } : undefined
  });
});

const shutdown = async (signal) => {
  console.log(`\n${signal} received. Starting graceful shutdown...`);
  const shutdownTimeout = setTimeout(() => {
    console.error('Graceful shutdown timeout. Forcing exit.');
    process.exit(1);
  }, 30000);
  try {
    console.log('Closing database connections...');
    const { closePool } = require('./config/db');
    await closePool();
    console.log('Clearing session store...');
    await new Promise(resolve => sessionStore.close(resolve));
    
    if (cleanupScheduler) {
      console.log('Stopping cleanup scheduler...');
      cleanupScheduler.stop();
    }
    
    if (promotionCronService) {
      console.log('Stopping promotion cron service...');
      promotionCronService.stopAll();
    }
    
    console.log('Cleanup completed successfully');
    clearTimeout(shutdownTimeout);
    process.exit(0);
  } catch (e) {
    console.error('Error during shutdown:', e.message);
    clearTimeout(shutdownTimeout);
    process.exit(1);
  }
};

// Add after line 508 (promotionCronService.startAll())

if (geoCdnSyncCron && (isProduction || isStaging)) {
  geoCdnSyncCron.start().catch(err => {
    console.error('Failed to start geo CDN sync cron:', err);
  });
}

// Add to shutdown function after line 471 (promotionCronService.stopAll())

if (geoCdnSyncCron) {
  console.log('Stopping geo CDN sync cron...');
  geoCdnSyncCron.stop();
}

process.on('SIGTERM', () => shutdown('SIGTERM'));
process.on('SIGINT', () => shutdown('SIGINT'));

process.on('uncaughtException', (err) => {
  console.error('Uncaught Exception:', err);
  if (isProduction) {
    shutdown('uncaughtException');
  }
});

process.on('unhandledRejection', (reason, promise) => {
  console.error('Unhandled Rejection at:', promise, 'reason:', reason);
  if (isProduction) {
    shutdown('unhandledRejection');
  }
});

if (cleanupScheduler && isProduction) {
  cleanupScheduler.start().catch(err => {
    console.error('Failed to start cleanup scheduler:', err);
  });
}

if (promotionCronService && isProduction) {
  promotionCronService.startAll();
}

module.exports = app;