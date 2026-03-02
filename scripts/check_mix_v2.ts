import { createClient } from '@supabase/supabase-js';
import dotenv from 'dotenv';
import path from 'path';

dotenv.config({ path: path.resolve(process.cwd(), '.env.local') });

const supabase = createClient(
    process.env.NEXT_PUBLIC_SUPABASE_URL!,
    process.env.SUPABASE_SERVICE_ROLE_KEY!
);

async function checkMix() {
    console.log('--- Checking Last 20 Predictions (Mix Focus) ---');
    const { data: preds, error } = await supabase
        .from('predictions')
        .select('id, asset_symbol, timeframe, status, created_at, candle_close_at, resolved_at')
        .order('id', { ascending: false })
        .limit(20);

    if (error) {
        console.error(error);
        return;
    }

    for (const p of preds || []) {
        console.log(`[${p.status}] ID: ${p.id} | Asset: ${p.asset_symbol} | TF: ${p.timeframe} | Close: ${p.candle_close_at} | Resolved: ${p.resolved_at || 'N/A'}`);
    }
}

checkMix();
