
import { createClient } from '@supabase/supabase-js';
import dotenv from 'dotenv';
dotenv.config(); // Load .env (Production)

const supabaseUrl = process.env.NEXT_PUBLIC_SUPABASE_URL;
const supabaseKey = process.env.SUPABASE_SERVICE_ROLE_KEY;

const supabase = createClient(supabaseUrl, supabaseKey);

async function check() {
    console.log('--- FETCHING RPC DEFINITION FROM PROD ---');
    // We can't easily fetch function source via JS client with RPC, but we can use an RPC that returns it if we have one, or just assume it matches production_final_sync.sql.
    // However, I can try to run a query to get function source via pg_get_functiondef
    const { data, error } = await supabase.rpc('debug_get_function_def', { fn_name: 'resolve_prediction_advanced' });

    if (error) {
        // Fallback: search in information_schema via a trick or just trust my view of the sql files.
        // Actually, I'll just use the SQL I already have as it's the one I likely applied.
        console.log('RPC debug not available. Trusting existing SQL file logic.');
    } else {
        console.log(data);
    }

    // Find the +27 prediction specifically
    const { data: btc27 } = await supabase
        .from('predictions')
        .select('*')
        .eq('asset_symbol', 'BTCUSDT')
        .eq('status', 'WIN')
        .eq('profit', 27)
        .order('created_at', { ascending: false })
        .limit(1);

    console.log('--- FOUND +27 PREDICTION ---');
    console.log(JSON.stringify(btc27, null, 2));
}

check();
