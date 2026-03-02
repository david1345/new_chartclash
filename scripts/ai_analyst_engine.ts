
import { createClient } from '@supabase/supabase-js';
import * as fs from 'fs';
import dotenv from 'dotenv';
import OpenAI from 'openai';
dotenv.config();

const supabaseUrl = process.env.NEXT_PUBLIC_SUPABASE_URL!;
const supabaseKey = process.env.SUPABASE_SERVICE_ROLE_KEY!;
const openaiKey = process.env.OPENAI_API_KEY!;
const supabase = createClient(supabaseUrl, supabaseKey);

const openai = new OpenAI({ apiKey: openaiKey });

async function runAnalystEngine(symbol: string, timeframe: string, priceData: any) {
    console.log(`\n[${new Date().toLocaleTimeString()}] 🤖 ANALYST HUB HEARTBEAT (${symbol} ${timeframe})`);

    // 1. Fetch Analyst Bot Profiles
    const { data: bots, error: botError } = await supabase
        .from('profiles')
        .select('id, username, bot_persona')
        .eq('is_bot', true)
        .like('username', 'Analyst_%');

    if (botError || !bots || bots.length === 0) {
        console.error('❌ No Analyst Bots found. Run deploy_analyst_bots.ts first.');
        return;
    }

    // 2. Prepare Market Context for OpenAI
    const marketContext = `
        Symbol: ${symbol}
        Timeframe: ${timeframe}
        Current Price: ${priceData.price}
        Technical Data: ${JSON.stringify(priceData.indicators)}
    `;

    // 3. Batch Call OpenAI for 10 Personas
    console.log('  Calling OpenAI for batch analyst perspectives...');
    try {
        const response = await openai.chat.completions.create({
            model: "gpt-4o-mini",
            messages: [
                {
                    role: "system",
                    content: `You are a team of 10 specialized market analysts at ChartClash. 
                    Based on the market data provided, output 10 unique comments (one per persona).
                    
                    Required JSON Keys (Total 10):
                    - "Analyst_RSI"
                    - "Analyst_Momentum"
                    - "Analyst_Trend"
                    - "Analyst_Volatility"
                    - "Analyst_Levels"
                    - "Analyst_Volume"
                    - "Analyst_Breakout"
                    - "Analyst_Reversal"
                    - "Analyst_Correlation"
                    - "Analyst_Regime"
                    
                    Rules:
                    1. Each comment should focus STRICTLY on its assigned specialty.
                    2. Keep it objective and fact-based (No "HODL!", "To the moon!", or financial advice).
                    3. Output in JSON format exactly as requested.
                    4. Max 140 characters per comment.
                    5. Language: English.`
                },
                {
                    role: "user",
                    content: marketContext
                }
            ],
            response_format: { type: "json_object" }
        });

        const results = JSON.parse(response.choices[0].message.content || '{}');
        console.log('  [AI Result Keys]:', Object.keys(results).join(', '));

        // 4. Submit to Supabase (Direct Insert for Developer/Admin flexibility)
        for (const bot of bots) {
            const comment = results[bot.username];
            if (!comment) continue;

            console.log(`  [POSTING] ${bot.username}...`);
            const { error: insertError } = await supabase
                .from('predictions')
                .insert({
                    user_id: bot.id,
                    asset_symbol: symbol,
                    timeframe,
                    direction: 'UP',
                    target_percent: 0,
                    entry_price: priceData.price,
                    bet_amount: 0,
                    is_opinion: true,
                    channel: 'analyst_hub',
                    comment,
                    status: 'pending',
                    candle_close_at: new Date(Date.now() + 1000 * 60 * 15).toISOString()
                });

            if (insertError) {
                console.error(`  ❌ Failed for ${bot.username}:`, insertError.message);
            } else {
                console.log(`  ✅ ${bot.username} posted to Analyst Hub.`);
            }
        }

    } catch (e) {
        console.error('❌ OpenAI or DB error:', e);
    }
}

// Actual execution
async function main() {
    const timeframes = ['15m', '30m', '1h', '4h', '1d'];
    const symbol = 'BTCUSDT';

    for (const tf of timeframes) {
        await runAnalystEngine(symbol, tf, {
            price: 52450.2, // Simulated price
            indicators: {
                rsi: Math.floor(Math.random() * 40) + 30, // Randomish for variety
                macd: 'neutral',
                bollinger: 'mid',
                volume: 'average'
            }
        });
    }
}

main().then(() => {
    console.log('\n🚀 ALL BTC Timeframes analyzed successfully.');
    process.exit(0);
}).catch(err => {
    console.error('❌ AI Analyst Engine failed:', err);
    process.exit(1);
});
