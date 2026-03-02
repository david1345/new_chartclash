import { createClient } from '@supabase/supabase-js';
import dotenv from 'dotenv';
import path from 'path';

dotenv.config({ path: path.resolve(process.cwd(), '.env.local') });

const supabase = createClient(
    process.env.NEXT_PUBLIC_SUPABASE_URL!,
    process.env.SUPABASE_SERVICE_ROLE_KEY!
);

async function testResolve() {
    console.log('--- Manual Resolution Test Start ---');
    try {
        const { data: predictions, error: fetchError } = await supabase
            .from('predictions')
            .select('*')
            .eq('status', 'pending');

        if (fetchError) throw fetchError;
        console.log(`Found ${predictions?.length || 0} pending predictions.`);

        if (!predictions || predictions.length === 0) {
            console.log('No pending predictions to resolve.');
            return;
        }

        for (const pred of predictions) {
            console.log(`Checking Prediction ID: ${pred.id} (${pred.asset_symbol} ${pred.timeframe})`);
            console.log(`  Created At: ${pred.created_at}`);
            console.log(`  Candle Close At: ${pred.candle_close_at}`);

            const now = new Date();
            const closeTime = new Date(pred.candle_close_at);
            const isReady = now.getTime() > closeTime.getTime() + 20000;

            console.log(`  Current Time: ${now.toISOString()}`);
            console.log(`  Is Ready: ${isReady}`);

            if (isReady) {
                console.log(`  Attempting resolution for ${pred.id}...`);
                // Note: In a real test, we would fetch prices here, but let's just check the RPC signature.
                const { data, error } = await supabase.rpc('resolve_prediction_advanced', {
                    p_id: Number(pred.id),
                    p_close_price: pred.entry_price || 0
                });

                if (error) {
                    console.error(`  ❌ RPC Error for ${pred.id}:`, error.message);
                } else {
                    console.log(`  ✅ RPC Success for ${pred.id}:`, data);
                }
            } else {
                console.log(`  ⏩ Skipping ${pred.id} (not ready yet)`);
            }
        }
    } catch (err) {
        console.error('Test failed:', err);
    }
    console.log('--- Manual Resolution Test End ---');
}

testResolve();
