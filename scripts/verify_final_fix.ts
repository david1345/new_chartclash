
import { createClient } from '@supabase/supabase-js';
import dotenv from 'dotenv';
dotenv.config();

const supabaseUrl = process.env.NEXT_PUBLIC_SUPABASE_URL;
const supabaseKey = process.env.SUPABASE_SERVICE_ROLE_KEY;

const supabase = createClient(supabaseUrl, supabaseKey);

async function verify() {
    console.log('--- FINAL VERIFICATION OF REWARD LOGIC ---');

    // 1. Check if late_mult exists in recently resolved activity logs
    const { data: logs, error } = await supabase
        .from('activity_logs')
        .select('*')
        .eq('action_type', 'RESOLVE')
        .order('created_at', { ascending: false })
        .limit(3);

    if (error) {
        console.error('Error fetching logs:', error);
    } else {
        console.log('\n[Latest Resolution Audit Logs]:');
        logs.forEach(log => {
            const meta = log.metadata;
            console.log(`- ID: ${log.prediction_id}, Status: ${meta.status}, Profit: ${meta.profit}, LateMult: ${meta.late_mult}, Ratio: ${meta.entry_ratio}`);
        });
    }

    // 2. Fetch pending predictions to see if any 1m bets are stuck
    const { data: pending } = await supabase
        .from('predictions')
        .select('*')
        .eq('status', 'pending')
        .order('created_at', { ascending: false })
        .limit(5);

    console.log('\n[Recent Pending Predictions]:');
    console.log(JSON.stringify(pending, null, 2));
}

verify();
