
import { createClient } from '@supabase/supabase-js';
import dotenv from 'dotenv';
dotenv.config({ path: '.env.local' });

const supabaseUrl = process.env.NEXT_PUBLIC_SUPABASE_URL;
const supabaseKey = process.env.SUPABASE_SERVICE_ROLE_KEY;

const supabase = createClient(supabaseUrl, supabaseKey);

async function check() {
    const emails = ['sjustone000@gmail.com'];
    const { data: profiles } = await supabase.from('profiles').select('*').in('email', emails);
    console.log('Profiles for email:', JSON.stringify(profiles, null, 2));

    const userIds = profiles?.map(p => p.id) || [];
    console.log('Searching for predictions for IDs:', userIds);

    const { data: preds } = await supabase
        .from('predictions')
        .select('*')
        .in('user_id', userIds)
        .order('created_at', { ascending: false })
        .limit(30);

    console.log('Recent predictions for these IDs:', JSON.stringify(preds, null, 2));
}

check();
