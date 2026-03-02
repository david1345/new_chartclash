
import { createClient } from '@supabase/supabase-js';
import dotenv from 'dotenv';
dotenv.config({ path: '.env.local' });

const supabaseUrl = process.env.NEXT_PUBLIC_SUPABASE_URL;
const supabaseKey = process.env.SUPABASE_SERVICE_ROLE_KEY;

const supabase = createClient(supabaseUrl, supabaseKey);

async function check() {
    const userId = '690d9bc7-40d1-4c1c-9a84-d819f8af3542'; // sjustone000
    console.log('--- RECENT RESOLVED PREDICTION FOR +27 CHECK ---');
    const { data: preds, error } = await supabase
        .from('predictions')
        .select('*')
        .eq('user_id', userId)
        .eq('status', 'WIN')
        .order('resolved_at', { ascending: false })
        .limit(1);

    if (error) {
        console.error(error);
    } else {
        console.log(JSON.stringify(preds, null, 2));
    }

    // Also check system configs
    const { data: configs } = await supabase.from('system_configs').select('*');
    console.log('\n--- SYSTEM CONFIGS ---');
    console.log(JSON.stringify(configs, null, 2));
}

check();
