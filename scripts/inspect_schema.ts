
import { createClient } from '@supabase/supabase-js';
import dotenv from 'dotenv';
dotenv.config();

const supabaseUrl = process.env.NEXT_PUBLIC_SUPABASE_URL!;
const supabaseKey = process.env.SUPABASE_SERVICE_ROLE_KEY!;
const supabase = createClient(supabaseUrl, supabaseKey);

async function inspectSchema() {
    // Try to query the information_schema via RPC or raw query if allowed
    // But usually we can just try to select * and see the keys of the first row
    const { data, error } = await supabase
        .from('profiles')
        .select('*')
        .limit(1);

    if (error) {
        console.error('❌ Inspection Error:', error.message);
    } else if (data && data.length > 0) {
        console.log('✅ Columns found in profiles:', Object.keys(data[0]));
    } else {
        console.log('⚠️ No rows found in profiles to inspect.');
    }
}

inspectSchema();
