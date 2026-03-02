import { createClient } from '@supabase/supabase-js';
import dotenv from 'dotenv';
import path from 'path';

dotenv.config({ path: path.resolve(process.cwd(), '.env.local') });

const supabase = createClient(
    process.env.NEXT_PUBLIC_SUPABASE_URL!,
    process.env.SUPABASE_SERVICE_ROLE_KEY!
);

async function inspectTargetUser() {
    const userId = '690d9bc7-40d1-4c1c-9a84-d819f8af3542';
    console.log(`--- Inspecting Predictions for User ID: ${userId} ---`);

    const { data: preds, error } = await supabase
        .from('predictions')
        .select('*')
        .eq('user_id', userId)
        .gte('created_at', new Date().toISOString().split('T')[0])
        .order('id', { ascending: false });

    if (error) {
        console.error(error);
        return;
    }

    console.log(`User Total Predictions Today: ${preds?.length || 0}`);
    for (const p of preds || []) {
        console.log(`ID: ${p.id} | Status: ${p.status} | Asset: ${p.asset_symbol} | TF: ${p.timeframe} | Close: ${p.candle_close_at} | Created: ${p.created_at}`);
    }
}

inspectTargetUser();
