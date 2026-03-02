import { createClient } from '@supabase/supabase-js';
import dotenv from 'dotenv';
import path from 'path';

dotenv.config({ path: path.resolve(process.cwd(), '.env.local') });

const supabase = createClient(
    process.env.NEXT_PUBLIC_SUPABASE_URL!,
    process.env.SUPABASE_SERVICE_ROLE_KEY!
);

async function finalRepair() {
    console.log('--- Final Repair & Data Sync ---');

    // 1. Sync system_settings data (Client-side sync)
    const settings = [
        { key: 'house_edge', value: [0.9], description: 'Platform payout multiplier' },
        { key: 'base_profit_ratio', value: [2.0], description: 'Base profit multiplier' },
        { key: 'tf_multipliers', value: { "1m": 1.0, "5m": 1.2, "15m": 1.5, "1h": 2.0, "4h": 3.0, "1d": 5.0 }, description: 'Timeframe-based multipliers' },
        { key: 'target_bonuses', value: [{ "max": 0.5, "bonus": 50 }, { "max": 1.0, "bonus": 120 }, { "max": 1.5, "bonus": 200 }, { "max": 2.0, "bonus": 300 }], description: 'Target percentage bonuses' },
        { key: 'streak_multipliers', value: { "1": 1.0, "2": 1.05, "3": 1.1, "4": 1.15, "5": 1.25 }, description: 'Streak-based bonus multipliers' }
    ];

    for (const s of settings) {
        const { error } = await supabase.from('system_settings').upsert(s);
        if (error) console.error(`Error syncing ${s.key}:`, error);
        else console.log(`Synced ${s.key}`);
    }

    // 2. Repair SOL Prediction (ID 3254)
    // Should be +99 profit. Currently +10. Need +89.
    const userId = '690d9bc7-40d1-4c1c-9a84-d819f8af3542';

    console.log('Updating Prediction 3254 profit to 99...');
    await supabase.from('predictions').update({ profit: 99 }).eq('id', 3254);

    console.log('Adding +89 points to user...');
    const { data: profile } = await supabase.from('profiles').select('points').eq('id', userId).single();
    if (profile) {
        await supabase.from('profiles').update({ points: profile.points + 89 }).eq('id', userId);
        console.log('Profile points updated.');
    }

    console.log('Repair Complete.');
}

finalRepair();
