import { createClient } from '@supabase/supabase-js';
import dotenv from 'dotenv';
dotenv.config({ path: '.env.local' });

const supabase = createClient(
    process.env.NEXT_PUBLIC_SUPABASE_URL!,
    process.env.SUPABASE_SERVICE_ROLE_KEY!
);

async function check() {
    console.log('DB URL:', process.env.NEXT_PUBLIC_SUPABASE_URL);

    // channel별 분포
    const { data: preds } = await supabase
        .from('predictions')
        .select('channel, user_id')
        .limit(1000);

    const dist: Record<string, number> = {};
    preds?.forEach(r => {
        const ch = r.channel || 'NULL';
        dist[ch] = (dist[ch] || 0) + 1;
    });
    console.log('\n채널별 분포:', dist);

    // is_bot = true 프로필
    const { data: bots } = await supabase
        .from('profiles')
        .select('id, username, is_bot')
        .eq('is_bot', true);
    console.log('\nAI 봇 프로필:', bots?.length, '개');
    bots?.slice(0, 5).forEach(b => console.log(' -', b.username));

    // Analyst 패턴
    const { data: analysts } = await supabase
        .from('profiles')
        .select('id, username')
        .ilike('username', '%analyst%');
    console.log('\nAnalyst 유저:', analysts?.map(a => a.username));
}
check().catch(console.error);
