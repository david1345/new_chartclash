import { createClient } from '@supabase/supabase-js';
import dotenv from 'dotenv';
import path from 'path';

dotenv.config({ path: path.resolve(process.cwd(), '.env.local') });

const supabase = createClient(
    process.env.NEXT_PUBLIC_SUPABASE_URL!,
    process.env.SUPABASE_SERVICE_ROLE_KEY!
);

async function createTestPred() {
    console.log('--- Creating Test Prediction for Verification ---');
    const userId = '690d9bc7-40d1-4c1c-9a84-d819f8af3542';

    // Set close time to 15 minutes ago (should be ready)
    const fifteenMinsAgo = new Date(Date.now() - 15 * 60 * 1000);
    const fifteenMinsAgoISO = fifteenMinsAgo.toISOString();

    const { data, error } = await supabase
        .from('predictions')
        .insert({
            user_id: userId,
            asset_symbol: 'BTCUSDT',
            timeframe: '15m',
            direction: 'UP',
            target_percent: 0.1,
            entry_price: 66000, // Dummy entry
            bet_amount: 10,
            status: 'pending',
            candle_close_at: fifteenMinsAgoISO,
            created_at: new Date(fifteenMinsAgo.getTime() - 15 * 60 * 1000).toISOString()
        })
        .select();

    if (error) {
        console.error(error);
        return;
    }

    console.log('Test Prediction Created:', data[0].id);
}

createTestPred();
