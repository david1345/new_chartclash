import { createClient } from '@supabase/supabase-js';
import dotenv from 'dotenv';
import path from 'path';

dotenv.config({ path: path.resolve(process.cwd(), '.env.local') });

const supabase = createClient(
    process.env.NEXT_PUBLIC_SUPABASE_URL!,
    process.env.SUPABASE_SERVICE_ROLE_KEY!
);

async function check1m() {
    console.log('--- Checking for 1m Predictions ---');
    const { data: preds, error } = await supabase
        .from('predictions')
        .select('id, status, asset_symbol, timeframe, candle_close_at, created_at')
        .eq('timeframe', '1m')
        .order('id', { ascending: false })
        .limit(20);

    if (error) {
        console.error(error);
        return;
    }

    console.log(`Found ${preds?.length || 0} recent 1m predictions.`);
    for (const p of preds || []) {
        console.log(`ID: ${p.id} | Status: ${p.status} | Asset: ${p.asset_symbol} | Created: ${p.created_at} | Close: ${p.candle_close_at}`);
    }
}

check1m();
