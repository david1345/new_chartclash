import { createClient } from '@supabase/supabase-js';
import dotenv from 'dotenv';
import path from 'path';

dotenv.config({ path: path.resolve(process.cwd(), '.env.local') });

const supabase = createClient(
    process.env.NEXT_PUBLIC_SUPABASE_URL!,
    process.env.SUPABASE_SERVICE_ROLE_KEY!
);

async function findStuck() {
    console.log('--- Finding Stuck Predictions (Candle Close in Past) ---');
    const now = new Date();
    console.log('Current UTC:', now.toISOString());

    const { data: preds, error } = await supabase
        .from('predictions')
        .select('*')
        .eq('status', 'pending')
        .lt('candle_close_at', now.toISOString())
        .order('candle_close_at', { ascending: true });

    if (error) {
        console.error(error);
        return;
    }

    console.log(`Found ${preds?.length || 0} stuck predictions.`);

    for (const pred of preds || []) {
        console.log(`[STUCK] ID: ${pred.id} | Asset: ${pred.asset_symbol} | TF: ${pred.timeframe} | Close: ${pred.candle_close_at}`);
    }
}

findStuck();
