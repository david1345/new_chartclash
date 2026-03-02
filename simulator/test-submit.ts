
import { createClient } from '@supabase/supabase-js';
import dotenv from 'dotenv';
import path from 'path';

dotenv.config({ path: path.resolve(__dirname, '../.env.local') });

const supabaseUrl = process.env.NEXT_PUBLIC_SUPABASE_URL!;
const supabaseServiceKey = process.env.SUPABASE_SERVICE_ROLE_KEY!;

const supabase = createClient(supabaseUrl, supabaseServiceKey);

async function testSubmit() {
    console.log('Testing submit_prediction RPC...');

    // Use the test user ID
    const userId = 'bd6880d7-c00d-44d8-abf8-832aeca7bd31';

    const { data, error } = await supabase.rpc('submit_prediction', {
        p_user_id: userId,
        p_asset_symbol: 'BTCUSDT',
        p_timeframe: '1h',
        p_direction: 'UP',
        p_target_percent: 0.5,
        p_entry_price: 60000.0,
        p_bet_amount: 50
    });

    if (error) {
        console.error('Submission error:', error.message);
        console.error('Error details:', error);
    } else {
        console.log('Submission successful:', data);
    }
}

testSubmit();
