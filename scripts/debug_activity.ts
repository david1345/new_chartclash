
import { createClient } from '@supabase/supabase-js';
import dotenv from 'dotenv';
dotenv.config({ path: '.env.local' });

const supabaseUrl = process.env.NEXT_PUBLIC_SUPABASE_URL;
const supabaseKey = process.env.SUPABASE_SERVICE_ROLE_KEY;

const supabase = createClient(supabaseUrl, supabaseKey);

async function check() {
    const userId = '690d9bc7-40d1-4c1c-9a84-d819f8af3542';
    console.log('--- ACTIVITY LOGS FOR USER ---');
    const { data: logs, error } = await supabase
        .from('activity_logs')
        .select('*')
        .eq('user_id', userId)
        .order('created_at', { ascending: false })
        .limit(20);

    if (error) console.error(error);
    else console.log(JSON.stringify(logs, null, 2));
}

check();
