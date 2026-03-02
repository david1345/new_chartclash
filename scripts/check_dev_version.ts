import { createClient } from '@supabase/supabase-js';
import dotenv from 'dotenv';

dotenv.config({ path: '.env' });

const supabase = createClient(
    process.env.NEXT_PUBLIC_SUPABASE_URL!,
    process.env.SUPABASE_SERVICE_ROLE_KEY!
);

async function checkVersion() {
    console.log('Checking URL:', process.env.NEXT_PUBLIC_SUPABASE_URL);

    try {
        // 1. Check notifications
        const { data: notifs, error: nError } = await supabase
            .from('notifications')
            .select('*')
            .order('created_at', { ascending: false })
            .limit(3);

        if (nError) {
            console.error('Error fetching notifications:', nError);
        } else {
            console.log('Latest 3 Notifications:');
            notifs?.forEach(n => console.log(`- [${n.type}] ${n.title}: ${n.message}`));
        }

        // 2. Check resolve_prediction_advanced function signature if possible
        // We can use a raw RPC to get the function info if we have a helper, 
        // but let's try to just call it with invalid params and see the error? 
        // Or check a meta table if it exists.

    } catch (e) {
        console.error('Failed to connect:', e);
    }
}

checkVersion();
