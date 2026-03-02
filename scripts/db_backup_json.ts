import { createClient } from '@supabase/supabase-js';
import dotenv from 'dotenv';
import fs from 'fs';
import path from 'path';

dotenv.config({ path: '.env.local' });

const supabase = createClient(
    process.env.NEXT_PUBLIC_SUPABASE_URL!,
    process.env.SUPABASE_SERVICE_ROLE_KEY!
);

const TABLES = [
    'profiles',
    'predictions',
    'notifications',
    'posts',
    'feed',
    'interactions'
];

async function backupToJSON() {
    const timestamp = new Date().toISOString().replace(/[:.]/g, '-').replace('T', '_').split('.')[0];
    const backupDir = path.resolve(process.cwd(), 'backups', `db_json_${timestamp}`);

    if (!fs.existsSync(backupDir)) {
        fs.mkdirSync(backupDir, { recursive: true });
    }

    console.log(`🚀 Starting JSON Backup to: ${backupDir}`);

    for (const table of TABLES) {
        console.log(`📦 Backing up table: ${table}...`);
        const { data, error } = await supabase.from(table).select('*');

        if (error) {
            console.error(`❌ Failed to backup ${table}:`, error.message);
            continue;
        }

        const filePath = path.join(backupDir, `${table}.json`);
        fs.writeFileSync(filePath, JSON.stringify(data, null, 2));
        console.log(`✅ Saved ${data?.length || 0} rows to ${table}.json`);
    }

    console.log('\n✨ Backup complete!');
}

backupToJSON();
