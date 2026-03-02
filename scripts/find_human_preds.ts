import { createClient } from '@supabase/supabase-js';
import dotenv from 'dotenv';
import path from 'path';

dotenv.config({ path: path.resolve(process.cwd(), '.env.local') });

const supabase = createClient(
    process.env.NEXT_PUBLIC_SUPABASE_URL!,
    process.env.SUPABASE_SERVICE_ROLE_KEY!
);

async function findHumanPending() {
    console.log('--- Finding Human Pending Predictions ---');
    const { data: preds, error } = await supabase
        .from('predictions')
        .select(`
            id, asset_symbol, timeframe, status, created_at, candle_close_at,
            profiles (username, email)
        `)
        .eq('status', 'pending')
        .order('id', { ascending: false })
        .limit(200);

    if (error) {
        console.error(error);
        return;
    }

    let foundCount = 0;
    for (const p of preds || []) {
        const username = (p.profiles as any)?.username || 'Unknown';
        if (!username.startsWith('Analyst_')) {
            console.log(`ID: ${p.id} | User: ${username} | Asset: ${p.asset_symbol} | TF: ${p.timeframe} | Close: ${p.candle_close_at}`);
            foundCount++;
        }
    }

    console.log(`\nFound ${foundCount} non-analyst pending predictions.`);
}

findHumanPending();
