import { createClient } from '@supabase/supabase-js';
import dotenv from 'dotenv';
import path from 'path';

dotenv.config({ path: path.resolve(process.cwd(), '.env.local') });

const supabase = createClient(
    process.env.NEXT_PUBLIC_SUPABASE_URL!,
    process.env.SUPABASE_SERVICE_ROLE_KEY!
);

async function inspectMix() {
    console.log('--- Inspecting Last 15 Predictions ---');
    const { data: preds, error } = await supabase
        .from('predictions')
        .select('*')
        .order('id', { ascending: false })
        .limit(15);

    if (error) {
        console.error(error);
        return;
    }

    for (const pred of preds || []) {
        console.log(`ID: ${pred.id} | Status: ${pred.status} | Asset: ${pred.asset_symbol} | TF: ${pred.timeframe} | Close: ${pred.candle_close_at}`);
    }
}

inspectMix();
