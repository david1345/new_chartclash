import { createClient } from '@supabase/supabase-js';
import dotenv from 'dotenv';

dotenv.config({ path: '.env.local' });

const supabase = createClient(
    process.env.NEXT_PUBLIC_SUPABASE_URL!,
    process.env.SUPABASE_SERVICE_ROLE_KEY!
);

async function listPredictions(userId: string) {
    const { data, error } = await supabase
        .from('predictions')
        .select('id, asset_symbol, timeframe, status, created_at, bet_amount')
        .eq('user_id', userId)
        .order('created_at', { ascending: false })
        .limit(10);

    if (error) {
        console.error('Error fetching predictions:', error.message);
        return;
    }

    console.table(data);
}

// User ID from the previous check
listPredictions("c9805870-5983-4f3c-8b84-52bffd163971");
