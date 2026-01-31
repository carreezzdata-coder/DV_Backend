// test/routeTester.js
// Run this after fixing the database
// Install dependencies: npm install axios form-data

const axios = require('axios');
const FormData = require('form-data');
const fs = require('fs');
const path = require('path');

const API_BASE = 'http://localhost:5000';

const colors = {
  reset: '\x1b[0m',
  green: '\x1b[32m',
  red: '\x1b[31m',
  yellow: '\x1b[33m',
  cyan: '\x1b[36m',
  bright: '\x1b[1m'
};

class RouteTester {
  constructor() {
    this.results = {
      passed: 0,
      failed: 0,
      tests: []
    };
    this.adminToken = null;
    this.sessionCookie = null;
  }

  log(message, type = 'info') {
    const prefix = {
      info: `${colors.cyan}ℹ`,
      success: `${colors.green}✅`,
      error: `${colors.red}❌`,
      warning: `${colors.yellow}⚠`
    }[type] || '';
    
    console.log(`${prefix} ${message}${colors.reset}`);
  }

  async login() {
    this.log('\n🔐 Logging in as admin...', 'info');
    
    try {
      const response = await axios.post(`${API_BASE}/api/admin/auth/login`, {
        email: 'rahab@dailyvaibe.com', // Change to your admin email
        password: 'your_admin_password' // Change to your admin password
      }, {
        withCredentials: true
      });

      if (response.data.success) {
        // Extract session cookie
        const cookies = response.headers['set-cookie'];
        if (cookies) {
          this.sessionCookie = cookies[0].split(';')[0];
        }
        
        this.log('Login successful', 'success');
        return true;
      }
      
      this.log('Login failed: ' + response.data.message, 'error');
      return false;
      
    } catch (error) {
      this.log(`Login error: ${error.message}`, 'error');
      return false;
    }
  }

  async testCreatePost() {
    this.log('\n📝 Testing: Create News Post', 'info');
    
    try {
      const form = new FormData();
      
      // Add text fields
      form.append('title', 'Test Article - ' + new Date().toISOString());
      form.append('content', 'This is a test article content. [BOLD]Bold text[/BOLD] and [HIGHLIGHT]highlighted text[/HIGHLIGHT].');
      form.append('excerpt', 'Test excerpt for the article');
      form.append('author_id', '5'); // Change to your admin_id
      form.append('category_ids', JSON.stringify([16, 17])); // Business, Opinion
      form.append('primary_category_id', '16');
      form.append('priority', 'medium');
      form.append('status', 'published');
      form.append('tags', 'test, automation');
      form.append('featured', 'false');
      form.append('breaking', 'false');
      form.append('pinned', 'false');
      
      // Add test image (create a small test image or use existing one)
      const testImagePath = path.join(__dirname, 'test-image.jpg');
      if (fs.existsSync(testImagePath)) {
        form.append('images', fs.createReadStream(testImagePath));
      }

      const response = await axios.post(
        `${API_BASE}/api/admin/createposts/news`,
        form,
        {
          headers: {
            ...form.getHeaders(),
            'Cookie': this.sessionCookie
          },
          withCredentials: true,
          maxBodyLength: Infinity,
          maxContentLength: Infinity
        }
      );

      if (response.data.success) {
        this.log('✅ Create Post: PASSED', 'success');
        this.results.passed++;
        this.results.tests.push({
          name: 'Create Post',
          status: 'passed',
          newsId: response.data.news.news_id
        });
        return response.data.news.news_id;
      } else {
        this.log(`❌ Create Post: FAILED - ${response.data.message}`, 'error');
        this.results.failed++;
        this.results.tests.push({
          name: 'Create Post',
          status: 'failed',
          error: response.data.message
        });
        return null;
      }

    } catch (error) {
      this.log(`❌ Create Post: ERROR - ${error.message}`, 'error');
      if (error.response) {
        console.error('Response data:', error.response.data);
      }
      this.results.failed++;
      this.results.tests.push({
        name: 'Create Post',
        status: 'error',
        error: error.message
      });
      return null;
    }
  }

  async testEditPost(newsId) {
    if (!newsId) {
      this.log('⚠ Skipping Edit Post (no news_id)', 'warning');
      return;
    }

    this.log('\n✏️ Testing: Edit News Post', 'info');
    
    try {
      const form = new FormData();
      
      form.append('title', 'Updated Test Article - ' + new Date().toISOString());
      form.append('content', 'This is updated content. [BOLD]Updated bold text[/BOLD].');
      form.append('excerpt', 'Updated test excerpt');
      form.append('author_id', '5');
      form.append('category_ids', JSON.stringify([16]));
      form.append('primary_category_id', '16');
      form.append('status', 'published');
      form.append('existing_images', JSON.stringify([]));

      const response = await axios.put(
        `${API_BASE}/api/admin/edit/news/${newsId}`,
        form,
        {
          headers: {
            ...form.getHeaders(),
            'Cookie': this.sessionCookie
          },
          withCredentials: true
        }
      );

      if (response.data.success) {
        this.log('✅ Edit Post: PASSED', 'success');
        this.results.passed++;
        this.results.tests.push({ name: 'Edit Post', status: 'passed' });
      } else {
        this.log(`❌ Edit Post: FAILED - ${response.data.message}`, 'error');
        this.results.failed++;
        this.results.tests.push({ 
          name: 'Edit Post', 
          status: 'failed', 
          error: response.data.message 
        });
      }

    } catch (error) {
      this.log(`❌ Edit Post: ERROR - ${error.message}`, 'error');
      if (error.response) {
        console.error('Response data:', error.response.data);
      }
      this.results.failed++;
      this.results.tests.push({ 
        name: 'Edit Post', 
        status: 'error', 
        error: error.message 
      });
    }
  }

  async testCreateQuote() {
    this.log('\n💬 Testing: Create Quote', 'info');
    
    try {
      const form = new FormData();
      
      form.append('quote_text', 'This is a test quote for automated testing.');
      form.append('sayer_name', 'Test Speaker');
      form.append('sayer_title', 'Chief Testing Officer');
      form.append('editor_pick', 'false');

      const response = await axios.post(
        `${API_BASE}/api/admin/quotes`,
        form,
        {
          headers: {
            ...form.getHeaders(),
            'Cookie': this.sessionCookie
          },
          withCredentials: true
        }
      );

      if (response.data.success) {
        this.log('✅ Create Quote: PASSED', 'success');
        this.results.passed++;
        this.results.tests.push({ 
          name: 'Create Quote', 
          status: 'passed',
          quoteId: response.data.quote.quote_id
        });
        return response.data.quote.quote_id;
      } else {
        this.log(`❌ Create Quote: FAILED - ${response.data.message}`, 'error');
        this.results.failed++;
        this.results.tests.push({ 
          name: 'Create Quote', 
          status: 'failed', 
          error: response.data.message 
        });
        return null;
      }

    } catch (error) {
      this.log(`❌ Create Quote: ERROR - ${error.message}`, 'error');
      if (error.response) {
        console.error('Response data:', error.response.data);
      }
      this.results.failed++;
      this.results.tests.push({ 
        name: 'Create Quote', 
        status: 'error', 
        error: error.message 
      });
      return null;
    }
  }

  async testCreateSocialVideo() {
    this.log('\n🎥 Testing: Create Social Video', 'info');
    
    try {
      const form = new FormData();
      
      form.append('title', 'Test Social Video - ' + new Date().toISOString());
      form.append('description', 'This is a test social video');
      form.append('video_url', 'https://www.youtube.com/watch?v=dQw4w9WgXcQ');
      form.append('video_type', 'recorded');
      form.append('is_live', 'false');
      form.append('status', 'draft');
      form.append('visibility', 'public');
      form.append('featured', 'false');
      form.append('display_order', '0');
      form.append('tags', JSON.stringify(['test', 'automation']));
      form.append('categories', JSON.stringify([16]));
      form.append('auto_refresh', 'true');
      form.append('admin_id', '5');

      const response = await axios.post(
        `${API_BASE}/api/admin/socialvideos`,
        form,
        {
          headers: {
            ...form.getHeaders(),
            'Cookie': this.sessionCookie
          },
          withCredentials: true
        }
      );

      if (response.data.success) {
        this.log('✅ Create Social Video: PASSED', 'success');
        this.results.passed++;
        this.results.tests.push({ 
          name: 'Create Social Video', 
          status: 'passed',
          videoId: response.data.video.video_id
        });
        return response.data.video.video_id;
      } else {
        this.log(`❌ Create Social Video: FAILED - ${response.data.message}`, 'error');
        this.results.failed++;
        this.results.tests.push({ 
          name: 'Create Social Video', 
          status: 'failed', 
          error: response.data.message 
        });
        return null;
      }

    } catch (error) {
      this.log(`❌ Create Social Video: ERROR - ${error.message}`, 'error');
      if (error.response) {
        console.error('Response data:', error.response.data);
      }
      this.results.failed++;
      this.results.tests.push({ 
        name: 'Create Social Video', 
        status: 'error', 
        error: error.message 
      });
      return null;
    }
  }

  async printResults() {
    console.log(`\n${colors.bright}${colors.cyan}${'='.repeat(80)}${colors.reset}`);
    console.log(`${colors.bright}📊 TEST RESULTS${colors.reset}`);
    console.log(`${colors.cyan}${'='.repeat(80)}${colors.reset}\n`);

    console.log(`${colors.green}✅ Passed: ${this.results.passed}${colors.reset}`);
    console.log(`${colors.red}❌ Failed: ${this.results.failed}${colors.reset}`);
    console.log(`Total: ${this.results.passed + this.results.failed}`);

    console.log(`\n${colors.bright}Test Details:${colors.reset}`);
    this.results.tests.forEach((test, index) => {
      const icon = test.status === 'passed' ? '✅' : '❌';
      console.log(`  ${icon} ${test.name}: ${test.status.toUpperCase()}`);
      if (test.error) {
        console.log(`     Error: ${test.error}`);
      }
    });

    console.log(`\n${colors.cyan}${'='.repeat(80)}${colors.reset}\n`);

    if (this.results.failed === 0) {
      console.log(`${colors.bright}${colors.green}🎉 ALL TESTS PASSED! READY FOR PRODUCTION!${colors.reset}\n`);
    } else {
      console.log(`${colors.bright}${colors.red}⚠ SOME TESTS FAILED - REVIEW ERRORS ABOVE${colors.reset}\n`);
    }
  }

  async runAllTests() {
    console.log(`\n${colors.bright}${colors.cyan}${'='.repeat(80)}`);
    console.log('🧪 DAILY VAIBE ROUTE TESTER');
    console.log(`${'='.repeat(80)}${colors.reset}\n`);

    const loggedIn = await this.login();
    
    if (!loggedIn) {
      this.log('❌ Cannot proceed without authentication', 'error');
      return;
    }

    // Run tests
    const newsId = await this.testCreatePost();
    await this.testEditPost(newsId);
    await this.testCreateQuote();
    await this.testCreateSocialVideo();

    // Print results
    await this.printResults();
  }
}

// Run tests
const tester = new RouteTester();
tester.runAllTests().catch(error => {
  console.error('❌ Test runner error:', error);
  process.exit(1);
});