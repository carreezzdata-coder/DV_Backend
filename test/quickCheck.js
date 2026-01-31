// quickCheck.js - Run this to see what's wrong
const { Client } = require('pg');

const client = new Client({
  host: 'localhost',
  port: 5432,
  database: 'dailyvaibe',
  user: 'postgres',
  password: 'dere84ELIJOOH'
});

async function quickCheck() {
  console.log('\n🔍 QUICK DATABASE CHECK\n');
  
  try {
    await client.connect();
    console.log('✅ Connected to database\n');

    // 1. Check session stores
    console.log('📋 Session Store Types:');
    const sessionTables = ['session_store', 'admin_session_store', 'public_session_store'];
    
    for (const table of sessionTables) {
      try {
        const result = await client.query(`
          SELECT data_type FROM information_schema.columns
          WHERE table_name = $1 AND column_name = 'sess'
        `, [table]);
        
        if (result.rows.length > 0) {
          const type = result.rows[0].data_type;
          const icon = type === 'json' ? '✅' : type === 'jsonb' ? '⚠️' : '❌';
          console.log(`   ${icon} ${table}.sess: ${type}`);
        } else {
          console.log(`   ❌ ${table}: Column 'sess' not found`);
        }
      } catch (e) {
        console.log(`   ❌ ${table}: ${e.message}`);
      }
    }

    // 2. Check news_social_media columns
    console.log('\n📱 news_social_media JSONB Columns:');
    const requiredCols = ['dimensions', 'media_urls', 'metadata', 'oembed_data', 'raw_api_response'];
    
    const result = await client.query(`
      SELECT column_name, data_type 
      FROM information_schema.columns
      WHERE table_name = 'news_social_media'
      AND column_name = ANY($1)
    `, [requiredCols]);
    
    const found = result.rows.map(r => r.column_name);
    
    for (const col of requiredCols) {
      if (found.includes(col)) {
        console.log(`   ✅ ${col}: exists`);
      } else {
        console.log(`   ❌ ${col}: MISSING`);
      }
    }

    // 3. Check embedded_social_posts view
    console.log('\n🗂️  Views Check:');
    try {
      await client.query('SELECT * FROM embedded_social_posts LIMIT 1');
      console.log('   ✅ embedded_social_posts: OK');
    } catch (e) {
      console.log(`   ❌ embedded_social_posts: ${e.message}`);
    }

    // 4. Test the problematic query from error logs
    console.log('\n🔬 Testing Problematic Query:');
    try {
      await client.query(`
        SELECT * FROM embedded_social_posts 
        WHERE news_id IS NOT NULL 
        LIMIT 1
      `);
      console.log('   ✅ Query works');
    } catch (e) {
      console.log(`   ❌ Query failed: ${e.message}`);
    }

    // 5. Check if categories work
    console.log('\n📁 Categories Check:');
    try {
      const catResult = await client.query(`
        SELECT COUNT(*) as total FROM categories WHERE active = true
      `);
      console.log(`   ✅ Active categories: ${catResult.rows[0].total}`);
    } catch (e) {
      console.log(`   ❌ Categories error: ${e.message}`);
    }

    await client.end();
    
    console.log('\n✅ Diagnostic complete!\n');
    console.log('📌 NEXT STEP: Run database fixer:');
    console.log('   node production_db_fixer.js\n');

  } catch (error) {
    console.error('❌ Error:', error.message);
    if (client) await client.end();
    process.exit(1);
  }
}

quickCheck();