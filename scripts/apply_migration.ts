import { createClient } from '@supabase/supabase-js';
import dotenv from 'dotenv';
import path from 'path';
import fs from 'fs';

dotenv.config({ path: path.resolve(process.cwd(), '.env.local') });

const supabase = createClient(
    process.env.NEXT_PUBLIC_SUPABASE_URL!,
    process.env.SUPABASE_SERVICE_ROLE_KEY!
);

async function applyMigration() {
    const sqlPath = path.resolve(process.cwd(), 'supabase/migrations/20260216_fix_reward_formula.sql');
    const sql = fs.readFileSync(sqlPath, 'utf8');

    console.log('--- Applying Migration: 20260216_fix_reward_formula.sql ---');

    // Using a special 'exec_sql' RPC if available, or trying to find another way
    // Since we don't have exec_sql, we'll try to use the CLI alternative or create a temporary RPC that can execute SQL

    const { error } = await supabase.rpc('exec_sql', { sql_query: sql });

    if (error) {
        console.error('Failed to apply migration via RPC:', error);
        console.log('Suggestion: Use the Supabase Dashboard SQL Editor to apply the following SQL:');
        console.log('------------------------------------------------------------');
        // console.log(sql);
    } else {
        console.log('Migration applied successfully!');
    }
}

applyMigration();
