import { createClient } from '@supabase/supabase-js';
import dotenv from 'dotenv';
import path from 'path';

dotenv.config({ path: path.resolve(process.cwd(), '.env.local') });

const supabase = createClient(
    process.env.NEXT_PUBLIC_SUPABASE_URL!,
    process.env.SUPABASE_SERVICE_ROLE_KEY!
);

async function manualResolve() {
    console.log('--- Manually Resolving 4791, 4792 (Repair) ---');

    // ID 4791 (BTCUSDT): WIN, Profit 7
    const profit4791 = 7;
    const payout4791 = 17;

    // ID 4792 (XAUUSD): WIN, Profit 4
    const profit4792 = 4;
    const payout4792 = 14;

    const { error: err1 } = await supabase.from('predictions').update({
        status: 'WIN',
        profit: profit4791,
        resolved_at: new Date().toISOString()
    }).eq('id', 4791);

    const { error: err2 } = await supabase.from('predictions').update({
        status: 'WIN',
        profit: profit4792,
        resolved_at: new Date().toISOString()
    }).eq('id', 4792);

    if (err1 || err2) {
        console.error('Update Predictions Error:', err1 || err2);
        return;
    }

    // Update User Points (Total Credits = 17 + 14 = 31)
    // Actually, since they were ND, they ALREADY got 10 + 10 back.
    // So we just need to ADD the profit (7 + 4 = 11).
    const userId = '690d9bc7-40d1-4c1c-9a84-d819f8af3542';
    const { data: profile } = await supabase.from('profiles').select('points').eq('id', userId).single();
    if (profile) {
        const { error: err3 } = await supabase.from('profiles').update({
            points: profile.points + 11
        }).eq('id', userId);
        if (err3) console.error(err3);
        else console.log('Successfully added +11 profit points to user.');
    }

    console.log('Reprocessed successfully.');
}

manualResolve();
