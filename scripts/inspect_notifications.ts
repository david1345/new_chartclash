
import { createClient } from '@supabase/supabase-js';
import dotenv from 'dotenv';
dotenv.config();

const supabaseUrl = process.env.NEXT_PUBLIC_SUPABASE_URL!;
const supabaseKey = process.env.SUPABASE_SERVICE_ROLE_KEY!;
const supabase = createClient(supabaseUrl, supabaseKey);

async function inspectMore() {
    const { data: nData, error: nError } = await supabase.from('notifications').select('*').limit(1);
    if (nError) {
        console.log('❌ Notifications Table Error:', nError.message);
    } else if (nData && nData.length > 0) {
        console.log('✅ Notifications Columns:', Object.keys(nData[0]));
    } else {
        console.log('⚠️ Notifications Table is empty, cannot inspect columns easily via SDK.');
    }
}

inspectMore();
