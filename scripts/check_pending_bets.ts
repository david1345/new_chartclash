import { createClient } from '@supabase/supabase-js';
import dotenv from 'dotenv';
import path from 'path';

dotenv.config({ path: path.resolve(process.cwd(), '.env.local') });

const supabase = createClient(
    process.env.NEXT_PUBLIC_SUPABASE_URL!,
    process.env.SUPABASE_SERVICE_ROLE_KEY!
);

async function checkPendingBets() {
    console.log('--- Checking Pending Predictions Ownership ---');

    const { data: counts, error } = await supabase
        .from('predictions')
        .select('user_id, profiles(username)')
        .eq('status', 'pending');

    if (error) {
        console.error('Error fetching pending bets:', error);
        return;
    }

    const summary: Record<string, number> = {};
    counts.forEach((item: any) => {
        const username = item.profiles?.username || 'Unknown';
        summary[username] = (summary[username] || 0) + 1;
    });

    console.log('Summary of Pending Bets by Username:');
    console.table(Object.entries(summary).map(([username, count]) => ({ username, count })));
}

checkPendingBets();
