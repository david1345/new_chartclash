
import { createClient } from '@supabase/supabase-js';
import dotenv from 'dotenv';
import path from 'path';

dotenv.config({ path: path.resolve(__dirname, '../.env.local') });

const supabaseUrl = process.env.NEXT_PUBLIC_SUPABASE_URL!;
const supabaseServiceKey = process.env.SUPABASE_SERVICE_ROLE_KEY!;

const supabase = createClient(supabaseUrl, supabaseServiceKey);

async function checkTables() {
    console.log('Checking tables...');
    const tables = ['profiles', 'predictions', 'notifications', 'activity_logs', 'prediction_likes'];

    for (const table of tables) {
        const { error } = await supabase.from(table).select('count', { count: 'exact', head: true });
        if (error) {
            console.error(`Table ${table} check error:`, error.message);
        } else {
            console.log(`Table ${table} exists.`);
        }
    }
}

checkTables();
