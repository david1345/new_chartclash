import { createClient } from '@supabase/supabase-js';
import dotenv from 'dotenv';

dotenv.config({ path: '.env.local' });

const supabaseUrl = process.env.NEXT_PUBLIC_SUPABASE_URL!;
const supabaseKey = process.env.SUPABASE_SERVICE_ROLE_KEY!;

const supabase = createClient(supabaseUrl, supabaseKey);

async function checkPredictions() {
    console.log('--- Checking Predictions Table ---');
    const { data, error } = await supabase
        .from('predictions')
        .select('id, asset_symbol, status, created_at, candle_close_at')
        .order('created_at', { ascending: false })
        .limit(10);

    if (error) {
        console.error('Error fetching predictions:', error);
        return;
    }

    if (!data || data.length === 0) {
        console.log('No predictions found in the database.');
    } else {
        console.table(data);
    }

    const { count, error: countError } = await supabase
        .from('predictions')
        .select('*', { count: 'exact', head: true })
        .eq('status', 'pending');

    if (countError) {
        console.error('Error counting pending predictions:', countError);
    } else {
        console.log(`Total Pending Predictions: ${count}`);
    }
}

checkPredictions();
