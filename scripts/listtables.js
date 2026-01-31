require('dotenv').config();
const { Client } = require('pg');

const colors = {
  reset: '\x1b[0m',
  bright: '\x1b[1m',
  red: '\x1b[31m',
  green: '\x1b[32m',
  yellow: '\x1b[33m',
  cyan: '\x1b[36m',
  magenta: '\x1b[35m',
};

const config = {
  host: 'localhost',
  port: 5432,
  database: 'dailyvaibe',
  user: 'postgres',
  password: 'dere84ELIJOOH'
};

async function listTables() {
  const client = new Client(config);

  console.log(`\n${colors.bright}${colors.cyan}${'='.repeat(80)}`);
  console.log('DAILY VAIBE DATABASE - TABLE INVENTORY');
  console.log(`${'='.repeat(80)}${colors.reset}\n`);

  try {
    await client.connect();
    console.log(`${colors.green}✅ Connected to database: ${config.database}${colors.reset}\n`);

    // Get all tables with row counts
    const result = await client.query(`
      SELECT 
        schemaname,
        tablename,
        (SELECT COUNT(*) FROM information_schema.columns 
         WHERE table_schema = 'public' AND table_name = tablename) as column_count
      FROM pg_tables 
      WHERE schemaname = 'public'
      ORDER BY tablename
    `);

    const tables = result.rows;

    // Categorize tables
    const categories = {
      'User Management': [],
      'Content Management': [],
      'Media & Assets': [],
      'Engagement & Analytics': [],
      'Advertising': [],
      'Communication': [],
      'Community Features': [],
      'Session Management': [],
      'System & Logging': []
    };

    const userKeywords = ['user', 'admin', 'role', 'permission'];
    const contentKeywords = ['news', 'categor', 'comment', 'breaking', 'approval'];
    const mediaKeywords = ['image', 'video', 'media', 'cloudflare'];
    const engagementKeywords = ['view', 'reaction', 'share', 'bookmark', 'interaction', 'analytics'];
    const adKeywords = ['ad_', 'advertis'];
    const commKeywords = ['subscriber', 'newsletter', 'email', 'notification', 'chat'];
    const communityKeywords = ['volunteer', 'event', 'donation', 'referral'];
    const sessionKeywords = ['session', 'online_status'];
    const systemKeywords = ['log', 'system', 'scheduler', 'cleanup', 'setting'];

    for (const table of tables) {
      const name = table.tablename;
      let categorized = false;

      if (userKeywords.some(kw => name.includes(kw))) {
        categories['User Management'].push(table);
        categorized = true;
      } else if (contentKeywords.some(kw => name.includes(kw))) {
        categories['Content Management'].push(table);
        categorized = true;
      } else if (mediaKeywords.some(kw => name.includes(kw))) {
        categories['Media & Assets'].push(table);
        categorized = true;
      } else if (engagementKeywords.some(kw => name.includes(kw))) {
        categories['Engagement & Analytics'].push(table);
        categorized = true;
      } else if (adKeywords.some(kw => name.includes(kw))) {
        categories['Advertising'].push(table);
        categorized = true;
      } else if (commKeywords.some(kw => name.includes(kw))) {
        categories['Communication'].push(table);
        categorized = true;
      } else if (communityKeywords.some(kw => name.includes(kw))) {
        categories['Community Features'].push(table);
        categorized = true;
      } else if (sessionKeywords.some(kw => name.includes(kw))) {
        categories['Session Management'].push(table);
        categorized = true;
      } else if (systemKeywords.some(kw => name.includes(kw))) {
        categories['System & Logging'].push(table);
        categorized = true;
      }
    }

    // Print categorized tables
    let tableNumber = 1;
    for (const [category, categoryTables] of Object.entries(categories)) {
      if (categoryTables.length === 0) continue;

      console.log(`${colors.bright}${colors.magenta}📁 ${category} (${categoryTables.length} tables)${colors.reset}`);
      console.log(`${colors.cyan}${'─'.repeat(80)}${colors.reset}`);

      for (const table of categoryTables) {
        // Get row count
        const countResult = await client.query(`SELECT COUNT(*) FROM ${table.tablename}`);
        const rowCount = parseInt(countResult.rows[0].count);
        
        const rowCountStr = rowCount > 0 ? 
          `${colors.green}${rowCount} rows${colors.reset}` : 
          `${colors.yellow}empty${colors.reset}`;

        console.log(
          `${colors.cyan}${String(tableNumber).padStart(2, '0')}.${colors.reset} ` +
          `${colors.bright}${table.tablename.padEnd(35)}${colors.reset} ` +
          `${colors.yellow}${String(table.column_count).padStart(2)} cols${colors.reset} │ ` +
          `${rowCountStr}`
        );
        tableNumber++;
      }
      console.log();
    }

    // Summary statistics
    console.log(`${colors.bright}${colors.cyan}${'='.repeat(80)}${colors.reset}`);
    console.log(`${colors.bright}📊 DATABASE STATISTICS${colors.reset}\n`);

    const totalTables = tables.length;
    const totalColumns = tables.reduce((sum, t) => sum + parseInt(t.column_count), 0);

    // Get total rows
    let totalRows = 0;
    for (const table of tables) {
      const countResult = await client.query(`SELECT COUNT(*) FROM ${table.tablename}`);
      totalRows += parseInt(countResult.rows[0].count);
    }

    // Get indexes count
    const indexResult = await client.query(`
      SELECT COUNT(*) as count
      FROM pg_indexes
      WHERE schemaname = 'public'
    `);
    const indexCount = parseInt(indexResult.rows[0].count);

    // Get views count
    const viewResult = await client.query(`
      SELECT COUNT(*) as count
      FROM pg_views
      WHERE schemaname = 'public'
    `);
    const viewCount = parseInt(viewResult.rows[0].count);

    // Get functions count
    const functionResult = await client.query(`
      SELECT COUNT(*) as count
      FROM pg_proc p
      JOIN pg_namespace n ON p.pronamespace = n.oid
      WHERE n.nspname = 'public'
    `);
    const functionCount = parseInt(functionResult.rows[0].count);

    // Get types count
    const typeResult = await client.query(`
      SELECT COUNT(*) as count
      FROM pg_type t
      JOIN pg_namespace n ON t.typnamespace = n.oid
      WHERE n.nspname = 'public' 
      AND t.typtype = 'e'
    `);
    const typeCount = parseInt(typeResult.rows[0].count);

    console.log(`   ${colors.green}Tables:${colors.reset}      ${totalTables}`);
    console.log(`   ${colors.green}Columns:${colors.reset}     ${totalColumns}`);
    console.log(`   ${colors.green}Total Rows:${colors.reset}  ${totalRows.toLocaleString()}`);
    console.log(`   ${colors.green}Indexes:${colors.reset}     ${indexCount}`);
    console.log(`   ${colors.green}Views:${colors.reset}       ${viewCount}`);
    console.log(`   ${colors.green}Functions:${colors.reset}   ${functionCount}`);
    console.log(`   ${colors.green}Types/Enums:${colors.reset} ${typeCount}`);

    // Database size
    const sizeResult = await client.query(`
      SELECT pg_size_pretty(pg_database_size('${config.database}')) as size
    `);
    console.log(`   ${colors.green}DB Size:${colors.reset}     ${sizeResult.rows[0].size}`);

    console.log(`\n${colors.bright}${colors.cyan}${'='.repeat(80)}${colors.reset}`);
    console.log(`${colors.bright}${colors.green}✅ DATABASE STATUS: HEALTHY${colors.reset}`);
    console.log(`${colors.bright}${colors.cyan}${'='.repeat(80)}${colors.reset}\n`);

    // Export list to file
    const fs = require('fs');
    const tableList = tables.map(t => t.tablename).join('\n');
    fs.writeFileSync('database_tables.txt', tableList);
    console.log(`${colors.yellow}💾 Table list exported to: database_tables.txt${colors.reset}\n`);

  } catch (error) {
    console.error(`\n${colors.red}❌ ERROR: ${error.message}${colors.reset}\n`);
    process.exit(1);
  } finally {
    await client.end();
  }
}

listTables();