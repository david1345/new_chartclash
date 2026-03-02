
import { createClient } from '@supabase/supabase-js';
import dotenv from 'dotenv';
dotenv.config();

const supabaseUrl = process.env.NEXT_PUBLIC_SUPABASE_URL!;
const supabaseKey = process.env.SUPABASE_SERVICE_ROLE_KEY!;
const supabase = createClient(supabaseUrl, supabaseKey);

async function checkSystemSettings() {
    const { data, error } = await supabase
        .from('system_settings')
        .select('*')
        .limit(1);

    if (error) {
        console.error('❌ system_settings Check Error:', error.message);
    } else {
        console.log('✅ system_settings table found.');
    }
}

checkSystemSettings();
