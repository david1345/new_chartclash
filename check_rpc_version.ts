import { createClient } from '@supabase/supabase-js';
import dotenv from 'dotenv';
import path from 'path';

dotenv.config({ path: path.resolve(__dirname, './.env.local') });

const supabase = createClient(process.env.NEXT_PUBLIC_SUPABASE_URL!, process.env.SUPABASE_SERVICE_ROLE_KEY!);

async function check() {
    const { data, error } = await supabase.rpc('submit_prediction', {
        p_user_id: '00000000-0000-0000-0000-000000000000', // Dummy
        p_asset_symbol: 'BTC',
        p_direction: 'UP',
        p_timeframe: '1h',
        p_bet_amount: 10,
        p_entry_price: 100000,
        p_target_percent: 1.0
    });
    
    // We expect an error, but we want to see WHICH error.
    // If it's about "activity_logs", the fix failed.
    // If it's about "invalid user", the function is updated but failing validly.
    console.log('RPC Call Results:');
    if (error) {
        console.log('Error Message:', error.message);
        console.log('Error Hint:', error.hint);
    } else {
        console.log('Data:', data);
    }
}
check();
