const express = require('express');
const router = express.Router();
const { getPool } = require('../../config/db');
const cloudflareService = require('../../services/cloudflareService');

const getImageUrl = (imageUrl) => {
  if (!imageUrl) return null;
  if (imageUrl.startsWith('http://') || imageUrl.startsWith('https://')) return imageUrl;
  const cleanPath = imageUrl.startsWith('/') ? imageUrl.substring(1) : imageUrl;
  if (cloudflareService.isEnabled()) {
    return cloudflareService.getPublicUrl(cleanPath);
  }
  if (process.env.NODE_ENV === 'development') return `http://localhost:5000/${cleanPath}`;
  const r2Url = process.env.R2_PUBLIC_URL;
  if (r2Url) {
    const cleanUrl = r2Url.endsWith('/') ? r2Url.slice(0, -1) : r2Url;
    return `${cleanUrl}/${cleanPath}`;
  }
  return imageUrl;
};

router.get('/', async (req, res) => {
  res.set({
    'Cache-Control': 'no-cache, no-store, must-revalidate',
    'Pragma': 'no-cache',
    'Expires': '0'
  });

  const limit = Math.min(100, Math.max(1, parseInt(req.query.limit) || 84));

  try {
    const pool = getPool();
    
    const result = await pool.query(`
      SELECT quote_id, quote_text, sayer_name, sayer_title, image_url, active, created_at, updated_at
      FROM news_quotes
      WHERE active = true
      ORDER BY created_at DESC
      LIMIT $1
    `, [limit]);

    const quotes = result.rows.map(q => ({
      quote_id: q.quote_id,
      quote_text: q.quote_text,
      sayer_name: q.sayer_name,
      sayer_title: q.sayer_title || '',
      sayer_image_url: getImageUrl(q.image_url),
      active: q.active,
      created_at: q.created_at,
      updated_at: q.updated_at
    }));

    const now = new Date();
    const threeDaysAgo = new Date(now.getTime() - (3 * 24 * 60 * 60 * 1000));
    const sevenDaysAgo = new Date(now.getTime() - (7 * 24 * 60 * 60 * 1000));

    const freshQuotes = quotes.filter(q => new Date(q.created_at) >= threeDaysAgo);
    const strikingQuotes = quotes.filter(q => {
      const created = new Date(q.created_at);
      return created < threeDaysAgo && created >= sevenDaysAgo;
    }).slice(0, 12);
    const trendingQuotes = quotes.filter(q => new Date(q.created_at) < sevenDaysAgo).slice(0, 12);

    return res.json({
      success: true,
      quotes: quotes,
      strikingQuotes: strikingQuotes,
      trendingQuotes: trendingQuotes,
      total: quotes.length
    });

  } catch (error) {
    console.error('[clientquotes] ERROR:', error.message);
    return res.status(500).json({
      success: false,
      message: 'Internal server error',
      quotes: [],
      strikingQuotes: [],
      trendingQuotes: []
    });
  }
});

module.exports = router;