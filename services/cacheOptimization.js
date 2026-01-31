class CacheOptimizationService {
  constructor() {
    this.memoryCache = new Map();
    this.cacheConfig = {
      default: { ttl: 300000, maxSize: 1000 },
      geo: { ttl: 600000, maxSize: 500 },
      articles: { ttl: 180000, maxSize: 2000 },
      categories: { ttl: 900000, maxSize: 200 }
    };
    this.hits = 0;
    this.misses = 0;
  }

  set(key, value, ttl = 300000) {
    const entry = {
      value,
      timestamp: Date.now(),
      ttl
    };

    this.memoryCache.set(key, entry);
    this.enforceMaxSize();
  }

  get(key) {
    const entry = this.memoryCache.get(key);

    if (!entry) {
      this.misses++;
      return null;
    }

    if (Date.now() - entry.timestamp > entry.ttl) {
      this.memoryCache.delete(key);
      this.misses++;
      return null;
    }

    this.hits++;
    return entry.value;
  }

  enforceMaxSize() {
    const maxSize = this.cacheConfig.default.maxSize;

    if (this.memoryCache.size > maxSize) {
      const entries = Array.from(this.memoryCache.entries());
      entries.sort((a, b) => a[1].timestamp - b[1].timestamp);

      const toDelete = entries.slice(0, this.memoryCache.size - maxSize);
      toDelete.forEach(([key]) => this.memoryCache.delete(key));
    }
  }

  clear(pattern) {
    if (pattern) {
      const keys = Array.from(this.memoryCache.keys()).filter(k => k.includes(pattern));
      keys.forEach(k => this.memoryCache.delete(k));
      return keys.length;
    }

    const size = this.memoryCache.size;
    this.memoryCache.clear();
    this.hits = 0;
    this.misses = 0;
    return size;
  }

  getStats() {
    const total = this.hits + this.misses;
    return {
      total: this.memoryCache.size,
      maxSize: this.cacheConfig.default.maxSize,
      hits: this.hits,
      misses: this.misses,
      hitRate: total > 0 ? ((this.hits / total) * 100).toFixed(2) + '%' : '0%'
    };
  }

  warmup(data, prefix, ttl) {
    if (!Array.isArray(data)) return;
    data.forEach((item, index) => {
      const key = `${prefix}:${item.id || index}`;
      this.set(key, item, ttl);
    });
  }
}

module.exports = new CacheOptimizationService();