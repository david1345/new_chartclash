import { createClient } from '@supabase/supabase-js';
import dotenv from 'dotenv';
import path from 'path';

dotenv.config({ path: path.resolve(process.cwd(), '.env.local') });

const supabase = createClient(
    process.env.NEXT_PUBLIC_SUPABASE_URL!,
    process.env.SUPABASE_SERVICE_ROLE_KEY!
);

async function checkSpecificPreds() {
    console.log('--- Checking 4:48 PM Predictions ---');

    const startTime = '2026-02-19T07:47:00.000Z'; // 4:47 PM KST
    const endTime = '2026-02-19T07:55:00.000Z';   // 4:55 PM KST

    const { data: preds, error } = await supabase
        .from('predictions')
        .select('*')
        .gte('created_at', startTime)
        .lte('created_at', endTime)
        .order('created_at', { ascending: false });

    if (error) {
        console.error(error);
        return;
    }

    console.table(preds.map(p => ({
        id: p.id,
        symbol: p.asset_symbol,
        status: p.status,
        entry: p.entry_price,
        actual: p.actual_price,
        direction: p.direction,
        profit: p.profit,
        created: p.created_at
    })));
}

checkSpecificPreds();
