import { createClient } from '@supabase/supabase-js';
import dotenv from 'dotenv';
import path from 'path';

dotenv.config({ path: path.resolve(process.cwd(), '.env.local') });

const supabase = createClient(
    process.env.NEXT_PUBLIC_SUPABASE_URL!,
    process.env.SUPABASE_SERVICE_ROLE_KEY!
);

async function findBetSequence() {
    console.log('--- Finding BET Activity Sequence (last 5 mins) ---');
    const fiveMinsAgo = new Date(Date.now() - 30 * 60 * 1000).toISOString(); // 30 mins ago to be safe

    const { data: logs, error } = await supabase
        .from('activity_logs')
        .select('*')
        .eq('action_type', 'BET')
        .gte('created_at', fiveMinsAgo)
        .order('created_at', { ascending: false });

    if (error) {
        console.error(error);
        return;
    }

    console.log(`Found ${logs?.length || 0} recent BET logs.`);

    for (const log of logs || []) {
        const meta = log.metadata as any;
        console.log(`LogID: ${log.id} | User: ${log.user_id} | Asset: ${log.asset_symbol} | TF: ${meta?.timeframe} | Created: ${log.created_at} | Close: ${meta?.candle_close_at} | PredID: ${log.prediction_id}`);
    }
}

findBetSequence();
