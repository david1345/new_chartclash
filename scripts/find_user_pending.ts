import { createClient } from '@supabase/supabase-js';
import dotenv from 'dotenv';
import path from 'path';

dotenv.config({ path: path.resolve(process.cwd(), '.env.local') });

const supabase = createClient(
    process.env.NEXT_PUBLIC_SUPABASE_URL!,
    process.env.SUPABASE_SERVICE_ROLE_KEY!
);

async function findUserPending() {
    console.log('--- Finding User Pending Predictions ---');
    // We don't know the exact user_id, so let's just find ALL pending ones again
    // but this time show more details like 'created_at' and 'timeframe'.
    const { data: preds, error } = await supabase
        .from('predictions')
        .select('*')
        .eq('status', 'pending')
        .order('id', { ascending: false });

    if (error) {
        console.error(error);
        return;
    }

    console.log(`Current Total Pending: ${preds?.length || 0}`);

    // Group by timeframe and asset to find clusters
    const groups: Record<string, number> = {};
    for (const pred of preds || []) {
        const key = `${pred.asset_symbol}-${pred.timeframe}-${pred.candle_close_at}`;
        groups[key] = (groups[key] || 0) + 1;

        // If it's a small group, it might be the user's specific ones
        if (preds.length < 50) {
            console.log(`ID: ${pred.id} | Asset: ${pred.asset_symbol} | TF: ${pred.timeframe} | Close: ${pred.candle_close_at} | Created: ${pred.created_at}`);
        }
    }

    console.log('\nPending Groups:', JSON.stringify(groups, null, 2));
}

findUserPending();
