import { createClient } from '@supabase/supabase-js';
import dotenv from 'dotenv';
import path from 'path';

dotenv.config({ path: path.resolve(process.cwd(), '.env.local') });

const supabase = createClient(
    process.env.NEXT_PUBLIC_SUPABASE_URL!,
    process.env.SUPABASE_SERVICE_ROLE_KEY!
);

async function compareTiming() {
    console.log('--- Timing Comparison (Resolved vs Pending) ---');

    // Last 10 Resolved
    const { data: res, error: resErr } = await supabase
        .from('predictions')
        .select('id, created_at, candle_close_at, timeframe, status')
        .order('id', { ascending: false })
        .limit(20);

    if (resErr) {
        console.error(resErr);
        return;
    }

    for (const p of res || []) {
        console.log(`ID: ${p.id} | Status: ${p.status} | TF: ${p.timeframe} | Created: ${p.created_at} | Close: ${p.candle_close_at}`);
    }
}

compareTiming();
