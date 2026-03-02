
import { createClient } from '@supabase/supabase-js';
import dotenv from 'dotenv';
import path from 'path';

dotenv.config({ path: path.resolve(__dirname, '../.env.local') });

const supabaseUrl = process.env.NEXT_PUBLIC_SUPABASE_URL!;
const supabaseServiceKey = process.env.SUPABASE_SERVICE_ROLE_KEY!;

const supabase = createClient(supabaseUrl, supabaseServiceKey);

async function testResolve() {
    console.log('Testing resolve_prediction_advanced RPC...');

    // Use the prediction_id from previous test
    const predictionId = 25;

    const { data, error } = await supabase.rpc('resolve_prediction_advanced', {
        p_id: predictionId,
        p_close_price: 61000.0, // Should be a WIN since entry was 60000 and direction was UP
        p_open_price: 60000.0
    });

    if (error) {
        console.error('Resolution error:', error.message);
        console.error('Error details:', error);
    } else {
        console.log('Resolution successful:', data);
    }
}

testResolve();
