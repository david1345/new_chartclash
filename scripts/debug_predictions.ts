
import { createClient } from '@supabase/supabase-js';
import dotenv from 'dotenv';
dotenv.config({ path: '.env.local' });

const supabaseUrl = process.env.NEXT_PUBLIC_SUPABASE_URL;
const supabaseKey = process.env.SUPABASE_SERVICE_ROLE_KEY;

const supabase = createClient(supabaseUrl, supabaseKey);

async function check() {
    console.log('--- USER STATUS ---');
    const { data: profiles } = await supabase.from('profiles').select('*').ilike('username', '%sjust%');
    console.log(JSON.stringify(profiles, null, 2));

    console.log('\n--- LATEST PREDICTIONS (ALL USERS) ---');
    const { data: preds } = await supabase.from('predictions').select('*').order('created_at', { ascending: false }).limit(20);
    console.log(JSON.stringify(preds?.map(p => ({ id: p.id, symbol: p.asset_symbol, tf: p.timeframe, status: p.status, close_at: p.candle_close_at })), null, 2));

    console.log('\n--- TARGET PREDICTION DETAIL ---');
    const target = preds?.find(p => p.timeframe === '1m' && p.status === 'pending');
    if (target) {
        console.log(JSON.stringify(target, null, 2));
    } else {
        console.log('No pending 1m predictions found.');
    }
}

check();
