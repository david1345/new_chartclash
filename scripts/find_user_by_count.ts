import { createClient } from '@supabase/supabase-js';
import dotenv from 'dotenv';
import path from 'path';

dotenv.config({ path: path.resolve(process.cwd(), '.env.local') });

const supabase = createClient(
    process.env.NEXT_PUBLIC_SUPABASE_URL!,
    process.env.SUPABASE_SERVICE_ROLE_KEY!
);

async function findUserByCount() {
    console.log('--- Finding User with ~10 Predictions Today ---');
    const today = new Date().toISOString().split('T')[0];

    // Group by user_id for today's predictions
    const { data, error } = await supabase
        .from('predictions')
        .select('user_id, count')
        .gte('created_at', today)
        // Grouping logic in Supabase JS is tricky without raw query, 
        // let's just fetch all IDs and count manually.
        .select('id, user_id, profiles(username)');

    if (error) {
        console.error(error);
        return;
    }

    const counts: Record<string, { count: number, name: string }> = {};
    for (const p of data || []) {
        const uid = p.user_id;
        const name = (p.profiles as any)?.username || 'Unknown';
        if (!counts[uid]) counts[uid] = { count: 0, name: name };
        counts[uid].count++;
    }

    for (const uid in counts) {
        if (counts[uid].count > 0 && !counts[uid].name.startsWith('Analyst_')) {
            console.log(`User: ${counts[uid].name} | Count: ${counts[uid].count} | ID: ${uid}`);
        }
    }
}

findUserByCount();
