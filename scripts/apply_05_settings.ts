import { createClient } from '@supabase/supabase-js';
import dotenv from 'dotenv';
import path from 'path';
import fs from 'fs';

dotenv.config({ path: path.resolve(process.cwd(), '.env.local') });

const supabase = createClient(
    process.env.NEXT_PUBLIC_SUPABASE_URL!,
    process.env.SUPABASE_SERVICE_ROLE_KEY!
);

async function applyFinalFix() {
    console.log('--- Applying Final 0.5% Fee Sync ---');

    // 1. Update settings via Supabase client (Service Role has bypass RLS)
    const settings = [
        { key: 'house_edge', value: [0.995], description: 'Platform payout multiplier (0.5% fee)' },
        { key: 'base_profit_ratio', value: [0.8], description: 'Base profit ratio (Win = 80% of bet)' },
        { key: 'tf_multipliers', value: { "1m": 1.0, "5m": 1.0, "15m": 1.0, "30m": 1.2, "1h": 1.5, "4h": 2.2, "1d": 3.0 }, description: 'Timeframe-based multipliers' },
        { key: 'target_bonuses', value: [{ "max": 0.5, "bonus": 8 }, { "max": 1.0, "bonus": 16 }, { "max": 1.5, "bonus": 24 }, { "max": 99.0, "bonus": 32 }], description: 'Target percentage bonuses' },
        { key: 'streak_milestones', value: [{ "count": 3, "bonus": 20 }, { "count": 5, "bonus": 50 }, { "count": 7, "bonus": 100 }, { "count": 10, "bonus": 200 }, { "count": 15, "bonus": 500 }], description: 'Streak milestone bonuses' }
    ];

    for (const s of settings) {
        const { error } = await supabase.from('system_settings').upsert(s);
        if (error) console.error(`Error syncing ${s.key}:`, error);
        else console.log(`Synced ${s.key}`);
    }

    // 2. We STILL need to update the RPC. 
    // If npx supabase db query is acting up, we can try to use a temporary RPC that can handle SQL or just manually advise.
    // However, I'll try one more time with a simplified npx command.

    console.log('\nRPC update must be done via Supabase SQL Editor for safety, or npx supabase db query.');
}

applyFinalFix();
