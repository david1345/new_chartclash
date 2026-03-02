
import { createClient } from '@supabase/supabase-js';
import dotenv from 'dotenv';
dotenv.config();

const supabaseUrl = process.env.NEXT_PUBLIC_SUPABASE_URL;
const supabaseKey = process.env.SUPABASE_SERVICE_ROLE_KEY;

const supabase = createClient(supabaseUrl, supabaseKey);

async function check() {
    console.log('--- CHECKING FOR NEW ACTIVITY ---');

    // Check for any bets created in the last 5 minutes
    const fiveMinsAgo = new Date(Date.now() - 5 * 60 * 1000).toISOString();

    const { data: recentBets } = await supabase
        .from('predictions')
        .select('*, profiles(username)')
        .gt('created_at', fiveMinsAgo)
        .order('created_at', { ascending: false });

    if (recentBets && recentBets.length > 0) {
        console.log(`Found ${recentBets.length} recent bets.`);
        console.log(JSON.stringify(recentBets, null, 2));
    } else {
        console.log('No recent bets found in the last 5 minutes.');
    }

    // Check for any resolutions in the last 2 minutes
    const twoMinsAgo = new Date(Date.now() - 2 * 60 * 1000).toISOString();
    const { data: recentResolutions } = await supabase
        .from('activity_logs')
        .select('*')
        .eq('action_type', 'RESOLVE')
        .gt('created_at', twoMinsAgo);

    if (recentResolutions && recentResolutions.length > 0) {
        console.log('--- NEW RESOLUTION DETECTED! ---');
        recentResolutions.forEach(log => {
            console.log(`Log ID: ${log.id}, Metadata: ${JSON.stringify(log.metadata, null, 2)}`);
        });
    } else {
        console.log('No new resolutions detected in the last 2 minutes.');
    }
}

check();
