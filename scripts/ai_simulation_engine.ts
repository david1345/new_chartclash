
import { createClient } from '@supabase/supabase-js';
import * as fs from 'fs';
import dotenv from 'dotenv';
import fetch from 'node-fetch'; // For Node environment
dotenv.config();

const supabaseUrl = process.env.NEXT_PUBLIC_SUPABASE_URL!;
const supabaseKey = process.env.SUPABASE_SERVICE_ROLE_KEY!;
const supabase = createClient(supabaseUrl, supabaseKey);

const templates = JSON.parse(fs.readFileSync('scripts/ai_comment_templates.json', 'utf8'));
const bots = JSON.parse(fs.readFileSync('scripts/ai_bots_data.json', 'utf8'));

/**
 * Fetches current price for a symbol
 */
async function getPrice(symbol: string, timeframe: string) {
    try {
        const cleanSymbol = symbol.toUpperCase().replace('/', '');
        // For simplicity in simulation, we use a public Binance endpoint
        const url = `https://api.binance.com/api/v3/ticker/price?symbol=${cleanSymbol}`;
        const res = await fetch(url);
        const json: any = await res.json();
        return parseFloat(json.price) || 0;
    } catch (e) {
        return 0;
    }
}

async function runSimulation() {
    console.log(`[${new Date().toLocaleTimeString()}] 🚀 AI Simulation Cycle Started...`);

    // 1. Fetch some bot IDs from the DB that have is_bot = true
    const { data: activeBots, error: botError } = await supabase
        .from('profiles')
        .select('*')
        .eq('is_bot', true)
        .limit(20);

    if (botError || !activeBots || activeBots.length === 0) {
        console.error('❌ No active AI bots found in DB. Run deploy_ai_bots.ts first.');
        return;
    }

    // 2. Pick a random subset of 3-5 bots to act
    const count = Math.floor(Math.random() * 3) + 2;
    const actors = activeBots.sort(() => 0.5 - Math.random()).slice(0, count);

    for (const bot of actors) {
        const persona = bot.bot_persona;
        const asset = persona.favorite_assets[0] || 'BTCUSDT';
        const tf = persona.active_tf[0] || '1h';
        const direction = Math.random() > 0.3 ? persona.bias : (persona.bias === 'BULLISH' ? 'BEARISH' : 'BULLISH');
        const target = (Math.random() * 1.5 + 0.5).toFixed(1);

        console.log(`\n[Action] Bot: ${bot.username} (${asset} ${tf})`);

        // 3. Fetch Price
        const price = await getPrice(asset, tf);
        if (price === 0) {
            console.warn(`  [Skip] Failed to get price for ${asset}`);
            continue;
        }

        // 4. Generate Comment (Simulate RSI logic)
        const rsi = Math.floor(Math.random() * 60) + 20;
        let pool = templates[direction].indicator_logic.neutral;
        if (rsi > 70) pool = templates[direction].indicator_logic.overbought || templates[direction].indicator_logic.uptrend;
        if (rsi < 30) pool = templates[direction].indicator_logic.oversold || templates[direction].indicator_logic.downtrend;

        const baseMsg = pool[Math.floor(Math.random() * pool.length)];
        const ending = templates[direction].ending[Math.floor(Math.random() * templates[direction].ending.length)];
        const comment = baseMsg
            .replace('{rsi}', rsi.toString())
            .replace('{asset}', asset)
            .replace('{timeframe}', tf)
            .replace('{target}', target) + ' ' + ending;

        // 5. Submit Prediction via RPC
        const betAmt = Math.floor(Math.random() * 50) + 10;

        // We use the system_role client so it has permission to override created_at/etc if needed
        // but submit_prediction handles most logic.
        const { data: result, error: rpcError } = await supabase.rpc('submit_prediction', {
            p_user_id: bot.id,
            p_asset_symbol: asset,
            p_timeframe: tf,
            p_direction: direction,
            p_target_percent: parseFloat(target),
            p_entry_price: price,
            p_bet_amount: betAmt
        });

        if (rpcError) {
            console.error(`  [Error] RPC failed for ${bot.username}:`, rpcError.message);
        } else {
            const predId = (result as any).prediction_id;
            console.log(`  [Success] Prediction #${predId} submitted.`);

            // 6. Update the prediction to include the generated comment
            await supabase
                .from('predictions')
                .update({ comment, is_opinion: true })
                .eq('id', predId);

            console.log(`  [Post] Comment: "${comment}"`);
        }
    }

    console.log('\n✅ Simulation Cycle Complete.');
}

runSimulation();
