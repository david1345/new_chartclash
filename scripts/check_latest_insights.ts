import { createClient } from '@supabase/supabase-js';
import dotenv from 'dotenv';
import path from 'path';

dotenv.config({ path: path.resolve(process.cwd(), '.env.local') });

const supabase = createClient(
    process.env.NEXT_PUBLIC_SUPABASE_URL!,
    process.env.SUPABASE_SERVICE_ROLE_KEY!
);

async function checkLatestInsights() {
    console.log('--- Checking Latest AI Insights ---');

    // Bots have usernames starting with Analyst_
    const { data: bots } = await supabase
        .from('profiles')
        .select('id')
        .eq('is_bot', true);

    if (!bots || bots.length === 0) {
        console.error('No bots found');
        return;
    }

    const botIds = bots.map(b => b.id);

    const { data: latest, error } = await supabase
        .from('predictions')
        .select('created_at, asset_symbol, timeframe, user_id')
        .in('user_id', botIds)
        .order('created_at', { ascending: false })
        .limit(10);

    if (error) {
        console.error('Error fetching latest insights:', error);
        return;
    }

    console.table(latest.map(p => ({
        created_at: p.created_at,
        symbol: p.asset_symbol,
        tf: p.timeframe
    })));
}

checkLatestInsights();
