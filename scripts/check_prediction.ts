import { createClient } from '@supabase/supabase-js';
import dotenv from 'dotenv';

dotenv.config({ path: '.env.local' });

const supabase = createClient(
    process.env.NEXT_PUBLIC_SUPABASE_URL!,
    process.env.SUPABASE_SERVICE_ROLE_KEY!
);

async function checkPrediction(id: number) {
    const { data, error } = await supabase
        .from('predictions')
        .select('*')
        .eq('id', id)
        .single();

    if (error) {
        console.error('Error fetching prediction:', error.message);
        return;
    }

    console.log('Prediction Data:', JSON.stringify(data, null, 2));
}

checkPrediction(110);
