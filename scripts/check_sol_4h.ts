import { createClient } from '@supabase/supabase-js';
import dotenv from 'dotenv';
import path from 'path';

dotenv.config({ path: path.resolve(process.cwd(), '.env.local') });

const supabase = createClient(
    process.env.NEXT_PUBLIC_SUPABASE_URL!,
    process.env.SUPABASE_SERVICE_ROLE_KEY!
);

async function checkSOLPred() {
    console.log('--- Checking SOLUSDT 4h Prediction Details ---');

    // Find the prediction
    const { data: preds, error } = await supabase
        .from('predictions')
        .select('*')
        .eq('asset_symbol', 'SOLUSDT')
        .eq('timeframe', '4h')
        .order('created_at', { ascending: false })
        .limit(5);

    if (error) {
        console.error(error);
        return;
    }

    console.log('Latest SOLUSDT 4h Predictions:');
    console.table(preds.map(p => ({
        id: p.id,
        status: p.status,
        profit: p.profit,
        created: p.created_at,
        resolved: p.resolved_at,
        entry_price: p.entry_price,
        actual_price: p.actual_price,
        target: p.target_percent
    })));

    if (preds.length > 0) {
        const targetId = preds[0].id;
        console.log(`\n--- Audit Logs for ID: ${targetId} ---`);
        const { data: logs } = await supabase
            .from('activity_logs')
            .select('*')
            .eq('prediction_id', targetId)
            .eq('action_type', 'RESOLVE');

        console.log(JSON.stringify(logs, null, 2));

        console.log(`\n--- System Configs Check ---`);
        const { data: configs } = await supabase
            .from('system_configs')
            .select('*');

        console.table(configs.map(c => ({ key: c.key, value: JSON.stringify(c.value) })));
    }
}

checkSOLPred();
