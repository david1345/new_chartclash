
import { createClient } from '@supabase/supabase-js';
import dotenv from 'dotenv';
import path from 'path';

dotenv.config({ path: path.resolve(process.cwd(), '.env.local') });

const supabaseUrl = process.env.NEXT_PUBLIC_SUPABASE_URL!;
const supabaseKey = process.env.SUPABASE_SERVICE_ROLE_KEY!;
const supabase = createClient(supabaseUrl, supabaseKey);

async function checkRpcs() {
    const query = 'SELECT 1';
    const rpcs = ['exec_sql', 'execute_sql', 'run_sql'];

    for (const rpc of rpcs) {
        console.log(`Testing RPC: ${rpc}...`);
        const { data, error } = await supabase.rpc(rpc, { sql: query });
        if (error) {
            console.warn(`❌ ${rpc} failed: ${error.message}`);
        } else {
            console.log(`✅ ${rpc} is available! Data:`, data);
        }
    }
}

checkRpcs();
