import { createClient } from '@supabase/supabase-js';
import * as fs from 'fs';
import * as path from 'path';
import dotenv from 'dotenv';

dotenv.config({ path: '.env.local' });

async function backup() {
    const supabase = createClient(
        process.env.NEXT_PUBLIC_SUPABASE_URL!,
        process.env.SUPABASE_SERVICE_ROLE_KEY!
    );

    const timestamp = '20260219_232722';
    const backupDir = path.join(process.cwd(), `../vibe-forecast_backup_${timestamp}/db_snapshot`);

    if (!fs.existsSync(backupDir)) {
        fs.mkdirSync(backupDir, { recursive: true });
    }

    const tables = ['profiles', 'predictions', 'system_settings', 'wallets', 'notification_settings'];

    console.log(`🚀 Starting DB Snapshot to: ${backupDir}`);

    for (const table of tables) {
        console.log(`📦 Exporting ${table}...`);
        const { data, error } = await supabase.from(table).select('*').limit(5000);
        if (error) {
            console.error(`  ❌ Failed to export ${table}:`, error.message);
            continue;
        }

        fs.writeFileSync(
            path.join(backupDir, `${table}.json`),
            JSON.stringify(data, null, 2)
        );
        console.log(`  ✅ ${table} exported (${data.length} rows)`);
    }

    console.log('\n✨ DB Snapshot complete.');
}

backup();
