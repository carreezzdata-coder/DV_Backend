const { getPool } = require('../config/db');

const trackIndexingOpportunity = async (req, res, next) => {
  if (req.method === 'POST' && req.path.includes('/news')) {
    const { slug, news_id } = req.body;
    
    if (slug && news_id) {
      try {
        const pool = getPool();
        const url = `https://dailyvaibe.com/client/articles/${slug}`;
        
        await pool.query(`
          INSERT INTO google_indexing_queue (url, type, status, created_at)
          VALUES ($1, 'URL_UPDATED', 'pending', NOW())
          ON CONFLICT (url) DO UPDATE
          SET status = 'pending', updated_at = NOW()
        `, [url]);
        
        console.log(`[Google Optimization] Queued for indexing: ${url}`);
      } catch (error) {
        console.error('[Google Optimization] Indexing queue error:', error);
      }
    }
  }
  
  next();
};

const enhanceWithGoogleSignals = async (req, res, next) => {
  const originalJson = res.json;
  
  res.json = function(data) {
    if (data && data.success && Array.isArray(data.news)) {
      data.news = data.news.map(article => ({
        ...article,
        canonical_url: `https://dailyvaibe.com/client/articles/${article.slug}`,
        amp_url: `https://dailyvaibe.com/amp/articles/${article.slug}`,
        structured_data_ready: true,
        indexing_priority: calculateIndexingPriority(article)
      }));
    }
    
    return originalJson.call(this, data);
  };
  
  next();
};

const calculateIndexingPriority = (article) => {
  const hoursAgo = (Date.now() - new Date(article.published_at).getTime()) / (1000 * 60 * 60);
  
  if (hoursAgo < 1) return 'urgent';
  if (hoursAgo < 6) return 'high';
  if (hoursAgo < 24) return 'normal';
  return 'low';
};

const addGoogleCacheHeaders = (req, res, next) => {
  const path = req.path;
  
  if (path.includes('/news') || path.includes('/articles')) {
    res.set({
      'X-Robots-Tag': 'index, follow, max-image-preview:large, max-snippet:-1',
      'Link': `<https://dailyvaibe.com${path}>; rel="canonical"`,
      'Content-Language': 'en-KE'
    });
  }
  
  if (path.includes('/featured') || path.includes('/breaking')) {
    res.set({
      'X-Content-Freshness': 'live',
      'X-News-Priority': 'high'
    });
  }
  
  next();
};

const logGoogleMetrics = async (req, res, next) => {
  const start = Date.now();
  
  res.on('finish', async () => {
    const duration = Date.now() - start;
    
    if (duration > 3000) {
      console.warn(`[Google Optimization] Slow response: ${req.path} took ${duration}ms`);
      console.warn('[Google Optimization] This affects Core Web Vitals - optimize query!');
    }
    
    if (req.path.includes('/news') && res.statusCode === 200) {
      try {
        const pool = getPool();
        await pool.query(`
          INSERT INTO google_performance_metrics 
          (endpoint, response_time_ms, status_code, timestamp)
          VALUES ($1, $2, $3, NOW())
        `, [req.path, duration, res.statusCode]);
      } catch (error) {
        console.error('[Google Optimization] Metrics logging error:', error);
      }
    }
  });
  
  next();
};

module.exports = {
  trackIndexingOpportunity,
  enhanceWithGoogleSignals,
  addGoogleCacheHeaders,
  logGoogleMetrics
};