import { createClient } from '@supabase/supabase-js';
import dotenv from 'dotenv';
import path from 'path';

dotenv.config({ path: path.resolve(process.cwd(), '.env.local') });

const supabase = createClient(
    process.env.NEXT_PUBLIC_SUPABASE_URL!,
    process.env.SUPABASE_SERVICE_ROLE_KEY!
);

async function resetPreds() {
    console.log('--- Resetting Predictions 4791, 4792 to pending ---');

    const { error } = await supabase
        .from('predictions')
        .update({ status: 'pending', profit: 0, resolved_at: null })
        .in('id', [4791, 4792]);

    if (error) {
        console.error(error);
    } else {
        console.log('Success.');
    }
}

resetPreds();
