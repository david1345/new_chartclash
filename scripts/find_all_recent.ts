
import { createClient } from '@supabase/supabase-js';
import dotenv from 'dotenv';
dotenv.config({ path: '.env.local' });

const supabaseUrl = process.env.NEXT_PUBLIC_SUPABASE_URL;
const supabaseKey = process.env.SUPABASE_SERVICE_ROLE_KEY;

const supabase = createClient(supabaseUrl, supabaseKey);

async function check() {
    const { count, error } = await supabase.from('predictions').select('*', { count: 'exact', head: true });
    console.log('Total predictions count:', count);

    console.log('--- ALL PREDICTIONS ORDERED BY CREATED_AT DESC (LAST 20) ---');
    const { data: preds } = await supabase
        .from('predictions')
        .select('*, profiles(username, email)')
        .order('created_at', { ascending: false })
        .limit(20);

    console.log(JSON.stringify(preds, null, 2));
}

check();
