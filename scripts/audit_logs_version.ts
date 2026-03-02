
import { createClient } from '@supabase/supabase-js';
import dotenv from 'dotenv';
dotenv.config();

const supabaseUrl = process.env.NEXT_PUBLIC_SUPABASE_URL;
const supabaseKey = process.env.SUPABASE_SERVICE_ROLE_KEY;

const supabase = createClient(supabaseUrl, supabaseKey);

async function check() {
    console.log('--- AUDITING ACTIVITY LOGS FOR CODES VERSION ---');

    // Check for 'BET' logs
    const { data: betLogs } = await supabase
        .from('activity_logs')
        .select('*')
        .eq('action_type', 'BET')
        .order('created_at', { ascending: false })
        .limit(5);

    console.log('\n[BET Logs Metadata]:', JSON.stringify(betLogs, null, 2));

    // Check for 'RESOLVE' logs
    const { data: resLogs } = await supabase
        .from('activity_logs')
        .select('*')
        .eq('action_type', 'RESOLVE')
        .order('created_at', { ascending: false })
        .limit(5);

    console.log('\n[RESOLVE Logs Metadata]:', JSON.stringify(resLogs, null, 2));
}

check();
