
import { createClient } from '@supabase/supabase-js';
import dotenv from 'dotenv';
dotenv.config();

const supabaseUrl = process.env.NEXT_PUBLIC_SUPABASE_URL!;
const supabaseKey = process.env.SUPABASE_SERVICE_ROLE_KEY!;
const supabase = createClient(supabaseUrl, supabaseKey);

async function listTables() {
    console.log('Connecting to:', supabaseUrl);

    // We can use a trick to list tables by querying a non-existent table and checking the error message,
    // or by calling a common system RPC if available. 
    // But since we can't do raw SQL, the most reliable way to check existence is to just try to select from them.

    const tablesToCheck = ['profiles', 'predictions', 'system_settings', 'system_configs', 'activity_logs', 'notifications'];

    for (const table of tablesToCheck) {
        const { error } = await supabase.from(table).select('*').limit(1);
        if (error) {
            console.log(`❌ Table [${table}]: ${error.message}`);
        } else {
            console.log(`✅ Table [${table}]: Exists`);
        }
    }
}

listTables();
