import { createClient } from '@supabase/supabase-js';
import dotenv from 'dotenv';

dotenv.config();

const supabase = createClient(
    process.env.NEXT_PUBLIC_SUPABASE_URL!,
    process.env.SUPABASE_SERVICE_ROLE_KEY!
);

async function check() {
    console.log('--- 🔍 DATABASE DIAGNOSTIC ---');

    // 1. Check Bot Profiles
    const { data: bots, error: botError } = await supabase
        .from('profiles')
        .select('id, username, is_bot')
        .eq('is_bot', true);

    if (botError) {
        console.error('❌ Error fetching bots:', botError);
    } else {
        console.log(`✅ Found ${bots?.length || 0} bot profiles:`);
        bots?.forEach(b => console.log(`   - ${b.username} (${b.id})`));
    }

    // 2. Check Recent Insights
    const { data: insights, error: insightError } = await supabase
        .from('predictions')
        .select('created_at, asset_symbol, timeframe, channel, comment')
        .eq('channel', 'analyst_hub')
        .order('created_at', { ascending: false })
        .limit(5);

    if (insightError) {
        console.error('❌ Error fetching insights:', insightError);
    } else {
        console.log(`✅ Found ${insights?.length || 0} recent analyst insights:`);
        insights?.forEach(i => {
            console.log(`   [${i.created_at}] ${i.asset_symbol} (${i.timeframe}): ${i.comment?.substring(0, 50)}...`);
        });
    }
}

check();
