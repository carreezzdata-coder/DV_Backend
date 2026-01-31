const fs = require('fs');
const path = require('path');

const issues = {
  critical: [],
  high: [],
  medium: [],
  low: [],
  schema: []
};

console.log('🔍 DAILY VAIBE PRODUCTION READINESS ANALYZER');
console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n');

// === FILE STRUCTURE ANALYSIS ===
const routeFiles = [
  'routes/api/client.js',
  'routes/api/home.js',
  'routes/api/articles.js',
  'routes/api/fetchall.js',
  'routes/api/personalization.js',
  'routes/api/cookies.js',
  'routes/api/geo.js',
  'routes/api/trending.js',
  'routes/api/videos.js',
  'routes/api/search.js',
  'routes/api/categories.js',
  'routes/api/footer-categories.js',
  'routes/api/clientquotes.js',
  'routes/admin/createposts.js',
  'routes/admin/edit.js',
  'routes/admin/quotes.js',
  'routes/admin/geo.js',
  'routes/admin/analytics.js',
  'routes/admin/categories.js',
  'routes/admin/pending.js',
  'routes/admin/users.js',
  'routes/admin/socialvideos/socialvideos.js',
  'routes/admin/socialvideos/deleteSocialVideos.js',
  'routes/admin/socialvideos/editSocialVideos.js',
  'routes/admin/socialvideos/retrieveSocialVideos.js',
  'config/db.js',
  'config/frontendconfig.js',
  'config/imagesUpload.js',
  'services/cloudflareService.js',
  'services/geoCdnService.js',
  'services/cacheOptimization.js',
  'services/promotionCronService.js',
  'services/cleanupScheduler.js',
  'middleware/adminAuth.js',
  'middleware/rolePermissions.js',
  'app.js',
  'server.js'
];

console.log('📋 ANALYZING CODE STRUCTURE...\n');

routeFiles.forEach(file => {
  const filePath = path.join(process.cwd(), file);
  
  if (!fs.existsSync(filePath)) {
    if (file.includes('routes/api/') || file.includes('routes/admin/')) {
      issues.critical.push(`${file}: MISSING`);
    } else if (file.includes('services/')) {
      issues.medium.push(`${file}: MISSING`);
    }
    return;
  }
  
  const content = fs.readFileSync(filePath, 'utf8');
  
  // === CRITICAL: Cloudflare Integration ===
  if (file.includes('routes/api/') && !file.includes('geo.js') && !file.includes('cookies.js')) {
    if (content.includes('getImageUrl') && !content.includes('cloudflareService')) {
      issues.critical.push(`${file}: getImageUrl missing Cloudflare integration`);
    }
    
    if (!content.includes('cloudflareService') && content.includes('image_url')) {
      issues.high.push(`${file}: No Cloudflare service import for image handling`);
    }
  }
  
  // === CRITICAL: Duplicate getImageUrl declarations ===
  const getImageUrlCount = (content.match(/const getImageUrl\s*=/g) || []).length;
  if (getImageUrlCount > 1) {
    issues.critical.push(`${file}: ${getImageUrlCount} duplicate getImageUrl declarations`);
  }
  
  // === CRITICAL: Hydration Risks ===
  const dateNowUsage = content.match(/Date\.now\(\)/g) || [];
  const mathRandomUsage = content.match(/Math\.random\(\)/g) || [];
  
  if (mathRandomUsage.length > 0) {
    issues.critical.push(`${file}: Math.random() (${mathRandomUsage.length}x) - HYDRATION BREAKER`);
  }
  
  if (dateNowUsage.length > 3 && file.includes('routes/api/')) {
    issues.high.push(`${file}: Date.now() (${dateNowUsage.length}x) - hydration risk`);
  }
  
  // === HIGH: Cache Headers ===
  if (file.includes('routes/api/') && content.includes('router.get')) {
    if (!content.includes('Cache-Control')) {
      issues.high.push(`${file}: Missing Cache-Control headers`);
    }
    
    if (!content.includes('CDN-Cache-Control')) {
      issues.medium.push(`${file}: Missing CDN-Cache-Control for Cloudflare`);
    }
  }
  
  // === HIGH: Error Handling ===
  const tryBlocks = (content.match(/try\s*\{/g) || []).length;
  const catchBlocks = (content.match(/catch\s*\(/g) || []).length;
  
  if (tryBlocks !== catchBlocks) {
    issues.high.push(`${file}: Mismatched try/catch blocks (${tryBlocks}/${catchBlocks})`);
  }
  
  // === MEDIUM: Database Pool Usage ===
  if (content.includes('getPool()') && !content.includes('getPool') && !content.includes('require')) {
    issues.medium.push(`${file}: Direct pool access without import`);
  }
  
  // === MEDIUM: Frontend Config Import ===
  if (file.includes('routes/') && content.includes('FRONTEND_URL') && !content.includes('frontendconfig')) {
    issues.high.push(`${file}: Using FRONTEND_URL without importing frontendconfig`);
  }
  
  // === MEDIUM: SQL Injection Risk ===
  const unsafeQueries = content.match(/query\(`[^`]*\$\{[^}]+\}[^`]*`\)/g) || [];
  if (unsafeQueries.length > 0) {
    unsafeQueries.forEach(q => {
      if (!q.includes('INTERVAL')) {
        issues.high.push(`${file}: Potential SQL injection - string interpolation in query`);
      }
    });
  }
  
  // === LOW: Console.log in production ===
  if (file.includes('routes/')) {
    const consoleLogs = (content.match(/console\.log\(/g) || []).length;
    if (consoleLogs > 5) {
      issues.low.push(`${file}: ${consoleLogs} console.log statements`);
    }
  }
  
  // === CRITICAL: Missing Cloudflare Service Methods ===
  if (file === 'services/cloudflareService.js') {
    const requiredMethods = ['isEnabled', 'uploadFile', 'deleteFile', 'getPublicUrl', 'uploadMultipleFiles'];
    requiredMethods.forEach(method => {
      if (!content.includes(method)) {
        issues.critical.push(`cloudflareService.js: Missing ${method} method`);
      }
    });
    
    if (!content.includes('S3Client')) {
      issues.critical.push(`cloudflareService.js: Missing AWS S3 client for R2`);
    }
  }
  
  // === HIGH: Image Upload Configuration ===
  if (file === 'config/imagesUpload.js') {
    if (!content.includes('multer.memoryStorage') && !content.includes('production')) {
      issues.high.push(`imagesUpload.js: Not configured for production memory storage`);
    }
    
    if (!content.includes('processUploadedFiles')) {
      issues.critical.push(`imagesUpload.js: Missing processUploadedFiles export`);
    }
  }
  
  // === CRITICAL: Environment Variables ===
  if (file === 'app.js' || file === 'server.js') {
    const requiredEnv = ['DATABASE_URL', 'SESSION_SECRET', 'NODE_ENV'];
    const optionalEnv = ['R2_PUBLIC_URL', 'CLOUDFLARE_ACCOUNT_ID', 'R2_ACCESS_KEY_ID', 'R2_SECRET_ACCESS_KEY'];
    
    if (!content.includes('SESSION_SECRET') || content.includes('dev-secret')) {
      issues.critical.push(`${file}: SESSION_SECRET not properly validated`);
    }
  }
  
  // === HIGH: CORS Configuration ===
  if (file === 'app.js') {
    if (!content.includes('cors') || !content.includes('ALLOWED_ORIGINS')) {
      issues.critical.push(`app.js: CORS not properly configured`);
    }
    
    if (!content.includes('credentials: true')) {
      issues.high.push(`app.js: CORS credentials not enabled`);
    }
  }
  
  // === MEDIUM: Rate Limiting ===
  if (file === 'app.js' && !content.includes('RATE_LIMIT')) {
    issues.medium.push(`app.js: No rate limiting implemented`);
  }
  
  // === CRITICAL: Server Configuration ===
  if (file === 'server.js') {
    if (!content.includes('Socket.IO') && !content.includes('io')) {
      issues.medium.push(`server.js: WebSocket support missing`);
    }
    
    if (!content.includes('gracefulShutdown') && !content.includes('SIGTERM')) {
      issues.high.push(`server.js: No graceful shutdown handler`);
    }
    
    if (!content.includes('0.0.0.0')) {
      issues.high.push(`server.js: Not listening on 0.0.0.0 (Render requirement)`);
    }
  }
});

// === SCHEMA VALIDATION ===
console.log('🗄️  ANALYZING DATABASE SCHEMA...\n');

const schemaPath = path.join(process.cwd(), 'EntireSchemaDump1.sql');
if (fs.existsSync(schemaPath)) {
  const schema = fs.readFileSync(schemaPath, 'utf8');
  
  // Required Tables
  const requiredTables = [
    'news',
    'admins',
    'categories',
    'news_images',
    'news_social_media',
    'session_store',
    'cookie_stats_daily',
    'session_geo',
    'featured_news',
    'breaking_news',
    'pinned_news',
    'editor_pick',
    'social_videos',
    'quotes'
  ];
  
  requiredTables.forEach(table => {
    if (!schema.includes(`CREATE TABLE public.${table}`)) {
      issues.schema.push(`MISSING TABLE: ${table}`);
    }
  });
  
  // Index Analysis
  const criticalIndexes = [
    { table: 'news', column: 'slug', type: 'UNIQUE' },
    { table: 'news', column: 'status', type: 'INDEX' },
    { table: 'news', column: 'published_at', type: 'INDEX' },
    { table: 'news_images', column: 'news_id', type: 'INDEX' },
    { table: 'categories', column: 'slug', type: 'UNIQUE' },
    { table: 'session_geo', column: 'session_id', type: 'INDEX' }
  ];
  
  criticalIndexes.forEach(idx => {
    const indexPattern = new RegExp(`CREATE.*INDEX.*${idx.table}.*${idx.column}`, 'i');
    if (!indexPattern.test(schema)) {
      issues.schema.push(`MISSING INDEX: ${idx.table}.${idx.column}`);
    }
  });
  
  // Foreign Key Validation
  if (!schema.includes('FOREIGN KEY') && !schema.includes('REFERENCES')) {
    issues.schema.push(`NO FOREIGN KEYS: Schema lacks referential integrity`);
  }
  
  // Views for Performance
  const requiredViews = ['active_location_counts'];
  requiredViews.forEach(view => {
    if (!schema.includes(`CREATE VIEW public.${view}`)) {
      issues.schema.push(`MISSING VIEW: ${view} (performance optimization)`);
    }
  });
  
  // Stored Procedures
  if (!schema.includes('CREATE FUNCTION') && !schema.includes('CREATE PROCEDURE')) {
    issues.medium.push(`SCHEMA: No stored procedures for complex operations`);
  }
  
  // JSONB Columns
  if (!schema.includes('jsonb')) {
    issues.low.push(`SCHEMA: No JSONB columns for flexible metadata`);
  }
  
} else {
  issues.critical.push(`EntireSchemaDump1.sql: SCHEMA FILE MISSING`);
}

// === ENVIRONMENT FILE VALIDATION ===
console.log('⚙️  VALIDATING ENVIRONMENT SETUP...\n');

const envPath = path.join(process.cwd(), '.env');
if (fs.existsSync(envPath)) {
  const envContent = fs.readFileSync(envPath, 'utf8');
  
  const requiredEnv = [
    'DATABASE_URL',
    'SESSION_SECRET',
    'NODE_ENV'
  ];
  
  const productionEnv = [
    'R2_PUBLIC_URL',
    'CLOUDFLARE_ACCOUNT_ID',
    'R2_ACCESS_KEY_ID',
    'R2_SECRET_ACCESS_KEY',
    'FRONTEND_URL',
    'ADMIN_URL'
  ];
  
  requiredEnv.forEach(env => {
    if (!envContent.includes(env)) {
      issues.critical.push(`ENV: Missing ${env}`);
    }
  });
  
  productionEnv.forEach(env => {
    if (!envContent.includes(env)) {
      issues.high.push(`ENV: Missing ${env} (required for production)`);
    }
  });
  
  if (envContent.includes('SESSION_SECRET=dev-secret')) {
    issues.critical.push(`ENV: Using default SESSION_SECRET`);
  }
  
  if (envContent.includes('DATABASE_URL=postgres://localhost')) {
    issues.high.push(`ENV: DATABASE_URL points to localhost`);
  }
  
} else {
  issues.critical.push(`ENV: .env file not found`);
}

// === PACKAGE.JSON VALIDATION ===
console.log('📦 VALIDATING DEPENDENCIES...\n');

const packagePath = path.join(process.cwd(), 'package.json');
if (fs.existsSync(packagePath)) {
  const pkg = JSON.parse(fs.readFileSync(packagePath, 'utf8'));
  
  const requiredDeps = {
    'express': 'Web framework',
    'pg': 'PostgreSQL client',
    'dotenv': 'Environment variables',
    'helmet': 'Security headers',
    'compression': 'Response compression',
    'cors': 'Cross-origin requests',
    'express-session': 'Session management',
    'connect-pg-simple': 'PostgreSQL session store',
    'multer': 'File uploads',
    '@aws-sdk/client-s3': 'Cloudflare R2 (S3-compatible)',
    'socket.io': 'WebSocket support'
  };
  
  Object.entries(requiredDeps).forEach(([dep, desc]) => {
    if (!pkg.dependencies?.[dep] && !pkg.devDependencies?.[dep]) {
      issues.critical.push(`DEPENDENCY: Missing ${dep} (${desc})`);
    }
  });
  
  // Scripts Validation
  if (!pkg.scripts?.start) {
    issues.critical.push(`PACKAGE: Missing "start" script`);
  }
  
  if (!pkg.scripts?.dev) {
    issues.medium.push(`PACKAGE: Missing "dev" script`);
  }
  
  // Engine Version
  if (!pkg.engines?.node) {
    issues.medium.push(`PACKAGE: No Node.js engine version specified`);
  }
  
} else {
  issues.critical.push(`PACKAGE: package.json not found`);
}

// === CLOUDFLARE + RENDER SPECIFIC CHECKS ===
console.log('☁️  CLOUDFLARE + RENDER DEPLOYMENT CHECKS...\n');

// Check for Render-specific configuration
const renderConfigIssues = [];

// Port binding
const serverPath = path.join(process.cwd(), 'server.js');
if (fs.existsSync(serverPath)) {
  const serverContent = fs.readFileSync(serverPath, 'utf8');
  
  if (!serverContent.includes('process.env.PORT')) {
    renderConfigIssues.push('SERVER: Not reading PORT from environment (Render requirement)');
  }
  
  if (!serverContent.includes('0.0.0.0')) {
    renderConfigIssues.push('SERVER: Not binding to 0.0.0.0 (Render requirement)');
  }
}

renderConfigIssues.forEach(issue => issues.high.push(issue));

// === SECURITY AUDIT ===
console.log('🔒 SECURITY AUDIT...\n');

routeFiles.forEach(file => {
  const filePath = path.join(process.cwd(), file);
  if (!fs.existsSync(filePath)) return;
  
  const content = fs.readFileSync(filePath, 'utf8');
  
  // Hardcoded secrets
  const secretPatterns = [
    /password\s*=\s*['"][^'"]+['"]/i,
    /api[_-]?key\s*=\s*['"][^'"]+['"]/i,
    /secret\s*=\s*['"](?!.*process\.env)[^'"]+['"]/i
  ];
  
  secretPatterns.forEach(pattern => {
    if (pattern.test(content)) {
      issues.high.push(`${file}: Potential hardcoded secret`);
    }
  });
  
  // Admin routes without auth
  if (file.includes('routes/admin/') && !content.includes('requireAdminAuth') && !content.includes('adminAuth')) {
    issues.critical.push(`${file}: Admin route without authentication`);
  }
});

// === PERFORMANCE OPTIMIZATION ===
console.log('⚡ PERFORMANCE CHECKS...\n');

const performanceChecks = {
  cacheService: fs.existsSync(path.join(process.cwd(), 'services/cacheOptimization.js')),
  geoCdn: fs.existsSync(path.join(process.cwd(), 'services/geoCdnService.js')),
  compression: fs.existsSync(path.join(process.cwd(), 'app.js')) && 
              fs.readFileSync(path.join(process.cwd(), 'app.js'), 'utf8').includes('compression')
};

if (!performanceChecks.cacheService) {
  issues.medium.push('PERFORMANCE: No cache optimization service');
}

if (!performanceChecks.geoCdn) {
  issues.medium.push('PERFORMANCE: No geo-CDN service for location-based content');
}

// === GENERATE REPORT ===
console.log('\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n');
console.log('📊 PRODUCTION READINESS REPORT\n');
console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n');

if (issues.critical.length > 0) {
  console.log('🚨 CRITICAL ISSUES (Must fix):\n');
  issues.critical.forEach((issue, i) => console.log(`   ${i + 1}. ${issue}`));
  console.log('');
}

if (issues.high.length > 0) {
  console.log('⚠️  HIGH PRIORITY (Should fix):\n');
  issues.high.forEach((issue, i) => console.log(`   ${i + 1}. ${issue}`));
  console.log('');
}

if (issues.medium.length > 0) {
  console.log('⚡ MEDIUM PRIORITY (Recommended):\n');
  issues.medium.forEach((issue, i) => console.log(`   ${i + 1}. ${issue}`));
  console.log('');
}

if (issues.schema.length > 0) {
  console.log('🗄️  DATABASE SCHEMA ISSUES:\n');
  issues.schema.forEach((issue, i) => console.log(`   ${i + 1}. ${issue}`));
  console.log('');
}

// === CALCULATE PRODUCTION READINESS SCORE ===
const totalIssues = issues.critical.length + issues.high.length + issues.medium.length + issues.schema.length;
const criticalWeight = issues.critical.length * 20;
const highWeight = issues.high.length * 10;
const mediumWeight = issues.medium.length * 5;
const schemaWeight = issues.schema.length * 7;

const deductions = criticalWeight + highWeight + mediumWeight + schemaWeight;
const score = Math.max(0, 100 - deductions);

console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n');
console.log(`📈 PRODUCTION READINESS SCORE: ${score}/100\n`);

if (score >= 90) {
  console.log('✅ EXCELLENT - Ready for production deployment');
} else if (score >= 75) {
  console.log('✅ GOOD - Minor issues to address');
} else if (score >= 50) {
  console.log('⚠️  FAIR - Several issues need attention');
} else {
  console.log('❌ POOR - Critical issues must be resolved');
}

console.log('\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n');

// === GENERATE JSON REPORT ===
const report = {
  timestamp: new Date().toISOString(),
  score: score,
  totalIssues: totalIssues,
  breakdown: {
    critical: issues.critical.length,
    high: issues.high.length,
    medium: issues.medium.length,
    schema: issues.schema.length
  },
  issues: issues,
  deployment: {
    platform: 'Cloudflare + Render',
    ready: score >= 75
  }
};

fs.writeFileSync(
  path.join(process.cwd(), 'production-health-report.json'),
  JSON.stringify(report, null, 2)
);

console.log('📄 Detailed report saved to: production-health-report.json\n');

process.exit(issues.critical.length > 0 ? 1 : 0);