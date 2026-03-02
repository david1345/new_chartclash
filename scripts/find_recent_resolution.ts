
import { createClient } from '@supabase/supabase-js';
import dotenv from 'dotenv';
dotenv.config({ path: '.env.local' });

const supabaseUrl = process.env.NEXT_PUBLIC_SUPABASE_URL;
const supabaseKey = process.env.SUPABASE_SERVICE_ROLE_KEY;

const supabase = createClient(supabaseUrl, supabaseKey);

async function check() {
    console.log('--- LATEST RESOLVED PREDICTIONS (ALL USERS) ---');
    const { data: preds, error } = await supabase
        .from('predictions')
        .select('*, profiles(username, email)')
        .not('resolved_at', 'is', null)
        .order('resolved_at', { ascending: false })
        .limit(10);

    if (error) {
        console.error(error);
    } else {
        console.log(JSON.stringify(preds, null, 2));
    }
}

check();
