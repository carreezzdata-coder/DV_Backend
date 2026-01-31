const fs = require('fs');
const { exec } = require('child_process');
const path = require('path');

const schemaFile = path.join(__dirname, 'schema-2026-01-25.sql');
const completeFile = path.join(__dirname, 'complete-2026-01-25.sql');

const dbUrl = process.env.DATABASE_URL || 'postgresql://karisdailyvaibe:NjCBtk8SPXJDvQKtUVNCVedxJKsgyuCQ@dpg-d5saqdngi27c73dqp2dg-a.virginia-postgres.render.com/dailyvaibeschema';

async function runCommand(cmd) {
  return new Promise((resolve, reject) => {
    exec(cmd, (error, stdout, stderr) => {
      if (error) {
        reject(new Error(`${error.message}\nSTDOUT: ${stdout}\nSTDERR: ${stderr}`));
        return;
      }
      resolve({ stdout, stderr });
    });
  });
}

async function checkPostgres() {
  try {
    await runCommand(`psql "${dbUrl}" -c "SELECT 1"`);
    return true;
  } catch (error) {
    return false;
  }
}

async function importFile(filename, label) {
  console.log(`📦 ${label}...`);
  
  if (!fs.existsSync(filename)) {
    throw new Error(`File not found: ${filename}`);
  }

  try {
    const result = await runCommand(`psql "${dbUrl}" < "${filename}"`);
    console.log(`✅ ${label} completed`);
    return true;
  } catch (error) {
    console.error(`❌ ${label} failed:`, error.message);
    return false;
  }
}

async function importWithNode() {
  console.log('🔧 Using Node.js direct import...');
  
  const { Client } = require('pg');
  const client = new Client({
    connectionString: dbUrl,
    ssl: { rejectUnauthorized: false }
  });

  try {
    await client.connect();
    console.log('✅ Connected to database');

    const sqlFile = fs.existsSync(completeFile) ? completeFile : schemaFile;
    if (!fs.existsSync(sqlFile)) {
      throw new Error(`No SQL file found at ${sqlFile}`);
    }

    const sql = fs.readFileSync(sqlFile, 'utf8');
    const commands = sql.split(';').filter(cmd => cmd.trim() && !cmd.trim().startsWith('--'));
    
    console.log(`Executing ${commands.length} SQL commands...`);
    let successful = 0;
    let skipped = 0;

    for (let i = 0; i < commands.length; i++) {
      const cmd = commands[i].trim();
      if (cmd) {
        try {
          await client.query(cmd);
          successful++;
          if ((i + 1) % 10 === 0) {
            console.log(`Progress: ${i + 1}/${commands.length} commands executed`);
          }
        } catch (err) {
          skipped++;
          if (err.message.includes('already exists') || err.message.includes('duplicate')) {
            console.log(`⚠️  Skipped existing: ${cmd.substring(0, 50)}...`);
          } else {
            console.warn(`⚠️  Command ${i + 1} failed:`, err.message.substring(0, 100));
          }
        }
      }
    }

    console.log(`\n✅ Import completed: ${successful} successful, ${skipped} skipped`);
    await client.end();
    return true;
  } catch (error) {
    console.error('❌ Import failed:', error.message);
    try {
      await client.end();
    } catch (e) {}
    throw error;
  }
}

async function main() {
  console.log('🚀 Starting Render database import...');
  console.log(`Database: ${dbUrl.split('@')[1]}`);
  
  const hasPostgres = await checkPostgres();
  
  if (!hasPostgres) {
    console.log('⚠️  PostgreSQL client not available, using Node.js import...');
    await importWithNode();
    return;
  }

  console.log('✅ PostgreSQL client ready');
  
  if (fs.existsSync(completeFile)) {
    const success = await importFile(completeFile, 'Complete database import');
    if (success) {
      console.log('🎉 Database import completed successfully!');
      return;
    }
  }

  if (fs.existsSync(schemaFile)) {
    const success = await importFile(schemaFile, 'Schema import');
    if (success) {
      console.log('🎉 Database import completed successfully!');
      return;
    }
  }

  console.log('⚠️  Falling back to Node.js import...');
  await importWithNode();
  console.log('🎉 Database import completed successfully!');
}

if (require.main === module) {
  main().catch(error => {
    console.error('💥 Fatal error:', error.message);
    process.exit(1);
  });
}

module.exports = { main, importWithNode };