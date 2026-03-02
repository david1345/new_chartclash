import { createClient } from '@supabase/supabase-js';
import dotenv from 'dotenv';
import path from 'path';

dotenv.config({ path: path.resolve(process.cwd(), '.env.local') });

const supabase = createClient(
    process.env.NEXT_PUBLIC_SUPABASE_URL!,
    process.env.SUPABASE_SERVICE_ROLE_KEY!
);

async function checkPending() {
    console.log('--- Checking Pending Predictions ---');
    const now = new Date();
    console.log('Current Time (Server):', now.toISOString());
    console.log('Current Time (Local):', now.toLocaleString());

    const { data: preds, error } = await supabase
        .from('predictions')
        .select('*')
        .eq('status', 'pending')
        .order('created_at', { ascending: false });

    if (error) {
        console.error('Error fetching predictions:', error);
        return;
    }

    console.log(`Found ${preds?.length || 0} pending predictions.`);

    for (const pred of preds || []) {
        const closeTime = new Date(pred.candle_close_at);
        const diffSeconds = (now.getTime() - closeTime.getTime()) / 1000;
        const isReady = diffSeconds > 20; // 20s buffer as per route code

        console.log(`\nID: ${pred.id} | Asset: ${pred.asset_symbol} | TF: ${pred.timeframe}`);
        console.log(`  Created At: ${pred.created_at}`);
        console.log(`  Candle Close At: ${pred.candle_close_at}`);
        console.log(`  Diff From Now: ${diffSeconds.toFixed(1)}s`);
        console.log(`  Is Ready (Calculated): ${isReady}`);
    }
}

checkPending();
