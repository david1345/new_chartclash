
import { createClient } from '@supabase/supabase-js';
import dotenv from 'dotenv';
dotenv.config({ path: '.env.local' });

const supabaseUrl = process.env.NEXT_PUBLIC_SUPABASE_URL;
const supabaseKey = process.env.SUPABASE_SERVICE_ROLE_KEY;

const supabase = createClient(supabaseUrl, supabaseKey);

async function check() {
    console.log('--- ALL PREDICTIONS IN LAST 2 HOURS ---');
    const twoHoursAgo = new Date(Date.now() - 2 * 60 * 60 * 1000).toISOString();

    const { data: preds, error } = await supabase
        .from('predictions')
        .select('*, profiles(username, email)')
        .gt('created_at', twoHoursAgo)
        .order('created_at', { ascending: false });

    if (error) {
        console.error(error);
    } else {
        console.log(JSON.stringify(preds, null, 2));
    }
}

check();
