import { createClient } from '@supabase/supabase-js';
import dotenv from 'dotenv';
dotenv.config();

const supabase = createClient(
    process.env.NEXT_PUBLIC_SUPABASE_URL!,
    process.env.SUPABASE_SERVICE_ROLE_KEY!
);

async function diagnose() {
    console.log('📡 Testing get_ranked_insights with p_channel...');
    const { data, error } = await supabase.rpc('get_ranked_insights', {
        p_channel: 'analyst_hub',
        p_limit: 5,
        p_is_opinion: true
    });

    if (error) {
        console.error('❌ RPC ERROR:', error);
    } else {
        console.log('✅ RPC SUCCESS! Data count:', data?.length);
        console.log('First Item Snippet:', data?.[0]?.comment);
    }
}

diagnose();
