
import { createClient } from '@supabase/supabase-js';
import dotenv from 'dotenv';
import fs from 'fs';

// Load both envs for comparison
dotenv.config({ path: '.env' }); // Assuming .env is PROD
const prodUrl = process.env.NEXT_PUBLIC_SUPABASE_URL;
const prodKey = process.env.SUPABASE_SERVICE_ROLE_KEY;

// Temporary manual load or assumption of dev env if needed
// For now, I will write a script that dumps PROD's critical areas for me to review manually against the files I have.

async function audit() {
    console.log('--- STARTING PRODUCTION AUDIT ---');
    if (!prodUrl || !prodKey) {
        console.error('Missing PROD env variables');
        return;
    }

    const supabase = createClient(prodUrl, prodKey);

    // 1. Check Tables and Columns
    console.log('\n[1] Checking Table Structures...');
    const { data: tables, error: tableErr } = await supabase.rpc('debug_get_schema_info');
    if (tableErr) {
        // Fallback: manually query information_schema if debug helper doesn't exist
        const { data: infoSchema } = await supabase.from('predictions').select('*', { count: 'exact', head: true });
        console.log(`- predictions table exists. Count: ${infoSchema || 0}`);
    } else {
        console.log(JSON.stringify(tables, null, 2));
    }

    // 2. Check ALL RPC Definitions (Crucial)
    console.log('\n[2] Checking RPC Definitions...');
    const funcNames = ['resolve_prediction_advanced', 'submit_prediction', 'get_ranked_insights'];
    for (const fn of funcNames) {
        console.log(`\n--- Function: ${fn} ---`);
        const { data: source, error } = await supabase.rpc('debug_get_function_source', { fn_name: fn });
        if (error) {
            console.log(`- Could not fetch source for ${fn} via RPC. Will try alternative method.`);
        } else {
            console.log(source);
        }
    }

    // 3. Check System Configs
    console.log('\n[3] Checking System Configs...');
    const { data: configs } = await supabase.from('system_configs').select('*');
    console.log(JSON.stringify(configs, null, 2));

    // 4. Check for any "BTC" in data where it should be "BTCUSDT"
    console.log('\n[4] Checking for Symbol Consistency...');
    const { data: btcPreds } = await supabase.from('predictions').select('asset_symbol').eq('asset_symbol', 'BTC').limit(5);
    console.log(`- Found ${btcPreds?.length || 0} predictions with "BTC" symbol.`);
}

audit();
