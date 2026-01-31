const { getPool } = require('../config/db');

const trackPublishVelocity = async (req, res, next) => {
  if (req.method === 'POST' && req.path.includes('/news')) {
    const originalJson = res.json;
    
    res.json = async function(data) {
      if (data && data.success && data.news_id) {
        try {
          const pool = getPool();
          const now = new Date();
          const hour = now.getHours();
          
          await pool.query(`
            INSERT INTO content_velocity (article_id, published_at, hour_of_day)
            VALUES ($1, $2, $3)
            ON CONFLICT (article_id) DO NOTHING
          `, [data.news_id, now.toISOString(), hour]);
          
          const hourlyCount = await pool.query(`
            SELECT COUNT(*) as count
            FROM content_velocity
            WHERE published_at >= NOW() - INTERVAL '1 hour'
          `);
          
          const count = parseInt(hourlyCount.rows[0].count);
          
          if (count >= 3) {
            console.log(`[Velocity] HIGH: ${count} articles/hour - Google will prioritize crawling`);
          } else {
            console.log(`[Velocity] ${count} articles/hour`);
          }
          
          data._velocity = {
            hourly: count,
            optimal_posting: true
          };
          
        } catch (error) {
          console.error('[Velocity] Tracking error:', error);
        }
      }
      
      return originalJson.call(this, data);
    };
  }
  
  next();
};

const optimizePublishTiming = async (req, res, next) => {
  if (req.method === 'POST' && req.path.includes('/news')) {
    try {
      const pool = getPool();
      
      const peakHours = await pool.query(`
        SELECT hour_of_day, COUNT(*) as count
        FROM content_velocity
        WHERE published_at >= NOW() - INTERVAL '30 days'
        GROUP BY hour_of_day
        ORDER BY count DESC
        LIMIT 3
      `);
      
      const currentHour = new Date().getHours();
      const isPeakHour = peakHours.rows.some(row => row.hour_of_day === currentHour);
      
      req.publishingContext = {
        isPeakHour,
        currentHour,
        peakHours: peakHours.rows.map(r => r.hour_of_day),
        recommendation: isPeakHour ? 'optimal' : 'consider-rescheduling'
      };
      
      if (!isPeakHour) {
        console.log(`[Velocity] Publishing at ${currentHour}:00 - Peak hours are: ${req.publishingContext.peakHours.join(', ')}`);
      }
      
    } catch (error) {
      console.error('[Velocity] Optimization error:', error);
    }
  }
  
  next();
};

module.exports = {
  trackPublishVelocity,
  optimizePublishTiming
};