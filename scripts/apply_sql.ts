import { createClient } from '@supabase/supabase-js';
import dotenv from 'dotenv';
import fs from 'fs';
import path from 'path';

dotenv.config({ path: '.env.local' });

const supabase = createClient(
    process.env.NEXT_PUBLIC_SUPABASE_URL!,
    process.env.SUPABASE_SERVICE_ROLE_KEY!
);

async function applySql() {
    const sqlPath = path.resolve(process.cwd(), 'supabase/market_discovery_with_ai_rounds.sql');
    const sql = fs.readFileSync(sqlPath, 'utf8');

    console.log('Attempting to apply SQL to:', process.env.NEXT_PUBLIC_SUPABASE_URL);

    // Try common RPC names for executing SQL
    const rpcs = ['exec_sql', 'execute_sql', 'run_sql'];

    for (const rpc of rpcs) {
        console.log(`Trying RPC: ${rpc}...`);
        const { data, error } = await supabase.rpc(rpc, { sql });

        if (!error) {
            console.log(`✅ Successfully applied SQL via ${rpc}`);
            return;
        }
        console.warn(`❌ RPC ${rpc} failed:`, error.message);
    }

    console.error('Failed to find a suitable RPC for raw SQL execution.');
    console.log('Falling back: Please apply the contents of supabase/notifications_system.sql manually in the Supabase SQL Editor.');
}

applySql();
