import { createClient } from '@supabase/supabase-js';
import dotenv from 'dotenv';
import path from 'path';

dotenv.config({ path: path.resolve(process.cwd(), '.env.local') });

const supabase = createClient(
    process.env.NEXT_PUBLIC_SUPABASE_URL!,
    process.env.SUPABASE_SERVICE_ROLE_KEY!
);

async function investigate() {
    console.log('--- Deep Investigation: SOLUSDT 4h (ID: 3254) ---');

    // 1. Check Prediction
    const { data: pred, error: predErr } = await supabase
        .from('predictions')
        .select('*')
        .eq('id', 3254)
        .single();

    if (predErr) {
        console.error('Pred Error:', predErr);
    } else {
        console.log('Prediction 3254:', pred);
    }

    // 2. Check Activity Log
    const { data: logs, error: logErr } = await supabase
        .from('activity_logs')
        .select('*')
        .eq('prediction_id', 3254)
        .eq('action_type', 'RESOLVE');

    if (logErr) {
        console.error('Log Error:', logErr);
    } else {
        console.log('Activity Logs:', JSON.stringify(logs, null, 2));
    }

    // 3. Check System Configs
    console.log('\n--- System Configs ---');
    const { data: configs, error: configErr } = await supabase
        .from('system_configs')
        .select('*');

    if (configErr) {
        console.error('Config Error:', configErr);
    } else if (!configs || configs.length === 0) {
        console.warn('System Configs table is EMPTY!');
    } else {
        configs.forEach(c => {
            console.log(`${c.key}:`, c.value);
        });
    }

    // 4. Trace the resolution time
    // If it was resolved at 5:00 PM KST (08:00 UTC), which cron script was running?
}

investigate();
