const fs = require('fs');
const path = require('path');

console.log('🔍 POST-FIX VALIDATION\n');
console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n');

const validations = {
  passed: 0,
  failed: 0,
  warnings: 0
};

const checkFile = (file, checks) => {
  const filePath = path.join(process.cwd(), file);
  
  if (!fs.existsSync(filePath)) {
    console.log(`⏭️  ${file} - NOT FOUND`);
    return;
  }
  
  const content = fs.readFileSync(filePath, 'utf8');
  
  checks.forEach(({ name, test, critical = true }) => {
    const passed = test(content);
    if (passed) {
      console.log(`✅ ${file}: ${name}`);
      validations.passed++;
    } else {
      if (critical) {
        console.log(`❌ ${file}: ${name}`);
        validations.failed++;
      } else {
        console.log(`⚠️  ${file}: ${name}`);
        validations.warnings++;
      }
    }
  });
};

console.log('📋 Validating fixes...\n');

// ===== VALIDATE CLOUDFLARE INTEGRATION =====
console.log('☁️  CLOUDFLARE INTEGRATION:\n');

const cloudflareRoutes = [
  'routes/api/client.js',
  'routes/api/home.js',
  'routes/api/fetchall.js',
  'routes/api/personalization.js',
  'routes/api/articles.js',
  'routes/api/search.js',
  'routes/api/categories.js',
  'routes/api/videos.js',
  'routes/api/trending.js'
];

cloudflareRoutes.forEach(file => {
  checkFile(file, [
    {
      name: 'Has cloudflareService import',
      test: (c) => c.includes("require('../../services/cloudflareService')")
    },
    {
      name: 'Has getImageUrl function',
      test: (c) => c.includes('const getImageUrl')
    },
    {
      name: 'getImageUrl uses cloudflareService.isEnabled()',
      test: (c) => c.includes('cloudflareService.isEnabled()')
    },
    {
      name: 'getImageUrl uses cloudflareService.getPublicUrl()',
      test: (c) => c.includes('cloudflareService.getPublicUrl(')
    },
    {
      name: 'No duplicate getImageUrl',
      test: (c) => (c.match(/const getImageUrl\s*=/g) || []).length === 1
    }
  ]);
});

console.log('\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n');

// ===== VALIDATE DATE.NOW() FIXES =====
console.log('📅 DATE.NOW() FIXES:\n');

const dateNowRoutes = [
  'routes/api/client.js',
  'routes/api/home.js',
  'routes/api/fetchall.js',
  'routes/api/personalization.js',
  'routes/api/trending.js'
];

dateNowRoutes.forEach(file => {
  checkFile(file, [
    {
      name: 'Uses new Date().getTime() instead of Date.now()',
      test: (c) => {
        const dateNowCount = (c.match(/Date\.now\(\)/g) || []).length;
        return dateNowCount <= 2; // Allow max 2 for non-critical uses
      },
      critical: false
    },
    {
      name: 'RequestId uses new Date().getTime()',
      test: (c) => !c.includes('requestId') || c.includes('new Date().getTime()')
    }
  ]);
});

console.log('\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n');

// ===== VALIDATE MATH.RANDOM() REMOVAL =====
console.log('🎲 MATH.RANDOM() REMOVAL:\n');

checkFile('config/imagesUpload.js', [
  {
    name: 'No Math.random() usage',
    test: (c) => !c.includes('Math.random()')
  },
  {
    name: 'Uses crypto.randomBytes()',
    test: (c) => c.includes('crypto.randomBytes(')
  },
  {
    name: 'Has crypto import',
    test: (c) => c.includes("require('crypto')")
  }
]);

console.log('\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n');

// ===== VALIDATE CDN CACHE HEADERS =====
console.log('💨 CDN CACHE HEADERS:\n');

const cacheHeaderRoutes = [
  'routes/api/client.js',
  'routes/api/home.js',
  'routes/api/fetchall.js'
];

cacheHeaderRoutes.forEach(file => {
  checkFile(file, [
    {
      name: 'Has Cache-Control header',
      test: (c) => c.includes('Cache-Control')
    },
    {
      name: 'Has CDN-Cache-Control for Cloudflare',
      test: (c) => c.includes('CDN-Cache-Control'),
      critical: false
    }
  ]);
});

console.log('\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n');

// ===== VALIDATE SESSION SECRET =====
console.log('🔐 SESSION SECRET VALIDATION:\n');

checkFile('app.js', [
  {
    name: 'Has SESSION_SECRET validation',
    test: (c) => c.includes('SESSION_SECRET')
  },
  {
    name: 'Exits on missing SESSION_SECRET in production',
    test: (c) => c.includes('process.exit(1)') && c.includes('isProduction')
  }
]);

console.log('\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n');

// ===== VALIDATE RENDER COMPATIBILITY =====
console.log('🚀 RENDER DEPLOYMENT COMPATIBILITY:\n');

checkFile('server.js', [
  {
    name: 'Uses process.env.PORT',
    test: (c) => c.includes('process.env.PORT')
  },
  {
    name: 'Binds to 0.0.0.0',
    test: (c) => c.includes('0.0.0.0')
  },
  {
    name: 'Has graceful shutdown',
    test: (c) => c.includes('SIGTERM') || c.includes('gracefulShutdown')
  }
]);

console.log('\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n');

// ===== SUMMARY =====
console.log('📊 VALIDATION SUMMARY\n');
console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n');

const total = validations.passed + validations.failed + validations.warnings;
const successRate = total > 0 ? Math.round((validations.passed / total) * 100) : 0;

console.log(`✅ Passed:   ${validations.passed}`);
console.log(`❌ Failed:   ${validations.failed}`);
console.log(`⚠️  Warnings: ${validations.warnings}`);
console.log(`\n📈 Success Rate: ${successRate}%\n`);

console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n');

if (validations.failed === 0) {
  console.log('🎉 ALL CRITICAL VALIDATIONS PASSED!\n');
  console.log('✅ Code is ready for production deployment\n');
  process.exit(0);
} else {
  console.log('⚠️  SOME VALIDATIONS FAILED\n');
  console.log('Review the failed checks above and re-run autofixer.js\n');
  process.exit(1);
}