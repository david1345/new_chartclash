
import { createClient } from '@supabase/supabase-js';
import dotenv from 'dotenv';
dotenv.config({ path: '.env.local' });

const supabaseUrl = process.env.NEXT_PUBLIC_SUPABASE_URL;
const supabaseKey = process.env.SUPABASE_SERVICE_ROLE_KEY;

const supabase = createClient(supabaseUrl, supabaseKey);

async function check() {
    const { data: func, error } = await supabase.rpc('get_function_definition', { function_name: 'submit_prediction' });
    if (error) console.error(error);
    else console.log(JSON.stringify(func, null, 2));
}

// Since I don't have get_function_definition, I'll try to find it in the sync script or search.
// Actually, I can use a generic query if I have psql access.
// But I'll just check the migration/sync scripts I ran.

// Wait, I'll just check if there's any other submit_prediction RPC in the project.
check();
