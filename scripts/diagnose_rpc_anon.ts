import { createClient } from '@supabase/supabase-js';
import dotenv from 'dotenv';
dotenv.config();

const supabase = createClient(
    process.env.NEXT_PUBLIC_SUPABASE_URL!,
    process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY! // USING ANON KEY
);

async function diagnose() {
    console.log('📡 Testing get_ranked_insights with ANON KEY...');
    const { data, error } = await supabase.rpc('get_ranked_insights', {
        p_channel: 'analyst_hub',
        p_limit: 5,
        p_is_opinion: true
    });

    if (error) {
        console.error('❌ ANON RPC ERROR:', error);
    } else {
        console.log('✅ ANON RPC SUCCESS! Data count:', data?.length);
    }
}

diagnose();
