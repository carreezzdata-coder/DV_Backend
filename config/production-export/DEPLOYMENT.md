# Daily Vaibe - Production Deployment

## Render PostgreSQL Setup

### Step 1: Create PostgreSQL Database
1. Go to Render Dashboard
2. Create new PostgreSQL database
3. Note the connection string

### Step 2: Deploy Schema
```bash
# Using the combined file
psql <RENDER_DATABASE_URL> < complete-2026-01-25.sql

# Or separately
psql <RENDER_DATABASE_URL> < schema-2026-01-25.sql
psql <RENDER_DATABASE_URL> < seed-data-2026-01-25.sql
```

### Step 3: Verify Deployment
```sql
-- Check tables
SELECT COUNT(*) FROM information_schema.tables WHERE table_schema = 'public';

-- Check categories
SELECT COUNT(*) FROM categories;

-- Check admin user
SELECT email, role FROM admins WHERE admin_id = 5;
```

## Generated Files
- `schema-2026-01-25.sql` - Complete database schema
- `seed-data-2026-01-25.sql` - Essential seed data
- `complete-2026-01-25.sql` - Combined schema + seed data

## Notes
- All sensitive data excluded
- Only essential seed data included
- Optimized for Render's PostgreSQL constraints
- No session store data
- Foreign keys properly ordered
- Indexes optimized for production

Generated: 2026-01-25T20:10:42.380Z
