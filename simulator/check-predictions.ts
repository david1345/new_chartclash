
import { createClient } from '@supabase/supabase-js';
import dotenv from 'dotenv';
import path from 'path';

dotenv.config({ path: path.resolve(__dirname, '../.env.local') });

const supabaseUrl = process.env.NEXT_PUBLIC_SUPABASE_URL!;
const supabaseServiceKey = process.env.SUPABASE_SERVICE_ROLE_KEY!;

const supabase = createClient(supabaseUrl, supabaseServiceKey);

async function checkRecentPredictions() {
    console.log('Checking recent predictions...');
    const { data: predictions, error } = await supabase
        .from('predictions')
        .select('*, profiles(username)')
        .order('created_at', { ascending: false })
        .limit(5);

    if (error) {
        console.error('Error fetching predictions:', error.message);
    } else {
        console.log('Latest 5 predictions:', predictions);
    }
}

checkRecentPredictions();
