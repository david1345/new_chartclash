import { createClient } from '@supabase/supabase-js';
import dotenv from 'dotenv';
import path from 'path';

dotenv.config({ path: path.resolve(process.cwd(), '.env.local') });

const supabase = createClient(
    process.env.NEXT_PUBLIC_SUPABASE_URL!,
    process.env.SUPABASE_SERVICE_ROLE_KEY!
);

async function findOwner() {
    console.log('--- Finding Owner of Recently Resolved Predictions ---');
    const { data: preds, error } = await supabase
        .from('predictions')
        .select(`
            id, status, asset_symbol, timeframe, candle_close_at, resolved_at,
            profiles (username, email)
        `)
        .neq('status', 'pending')
        .order('resolved_at', { ascending: false })
        .limit(10);

    if (error) {
        console.error(error);
        return;
    }

    for (const p of preds || []) {
        console.log(`ID: ${p.id} | User: ${(p.profiles as any)?.username} | Status: ${p.status} | TF: ${p.timeframe} | Close: ${p.candle_close_at}`);
    }
}

findOwner();
