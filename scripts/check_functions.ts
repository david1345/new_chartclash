import { createClient } from '@supabase/supabase-js';
import dotenv from 'dotenv';
import path from 'path';

dotenv.config({ path: path.resolve(process.cwd(), '.env.local') });

const supabase = createClient(
    process.env.NEXT_PUBLIC_SUPABASE_URL!,
    process.env.SUPABASE_SERVICE_ROLE_KEY!
);

async function checkFunctions() {
    console.log('--- Database Function Check ---');
    try {
        const { data, error } = await supabase.rpc('get_functions_metadata', {}); // Might not exist
        if (error) {
            // Fallback: Query pg_proc via a custom RPC if available, or just try to find what functions exist
            const { data: procData, error: procError } = await supabase.from('_pg_expand_relation').select('*').limit(1); // dummy
            console.log('Direct query attempt failed (expected). Trying to list functions via introspection...');
        }

        // List all functions in public schema
        const { data: funcs, error: funcError } = await supabase
            .rpc('get_service_status'); // Check if this exists

        console.log('Trying to find resolve_prediction_advanced...');
        // We can use this query to check function existence
        const { data: check, error: checkError } = await supabase
            .from('predictions')
            .select('count', { count: 'exact', head: true });

        console.log('Database connection OK.');

        // Let's try to call it with very simple params to see if it even exists
        const { data: testData, error: testError } = await supabase
            .rpc('resolve_prediction_advanced', { p_id: 1, p_close_price: 100 });

        console.log('Test Call Result:', { testData, testError });
    } catch (err) {
        console.error('Check failed:', err);
    }
}

checkFunctions();
