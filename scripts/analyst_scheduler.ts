import { createClient } from '@supabase/supabase-js';
import OpenAI from 'openai';
import dotenv from 'dotenv';

dotenv.config();

/**
 * ----------------------------------------------------------------------------
 * 🛠️ CONFIG & CLIENTS
 * ----------------------------------------------------------------------------
 */
const supabase = createClient(
    process.env.NEXT_PUBLIC_SUPABASE_URL!,
    process.env.SUPABASE_SERVICE_ROLE_KEY!
);
const openai = new OpenAI({ apiKey: process.env.OPENAI_API_KEY! });

const TIMEFRAMES = ['15m', '30m', '1h', '4h', '1d'];
const SYMBOL = 'BTCUSDT';

/**
 * 🔍 HELPER: Get Real Price from Binance
 */
async function getRealPrice(symbol: string) {
    try {
        const cleanSymbol = symbol.toUpperCase().replace('/', '');
        const url = `https://api.binance.com/api/v3/ticker/price?symbol=${cleanSymbol}`;
        const res = await fetch(url);
        const json: any = await res.json();
        return parseFloat(json.price) || 0;
    } catch (e) {
        console.error('  ❌ Price fetch error:', e);
        return 0;
    }
}

/**
 * 🧠 ENGINE: Run AI Analysis
 */
async function runAnalysis(symbol: string, timeframe: string) {
    const now = new Date();
    console.log(`\n[${now.toLocaleTimeString()}] 🚀 ANALYSIS START: ${symbol} (${timeframe})`);

    const price = await getRealPrice(symbol);
    if (price === 0) return;

    // 1. Fetch Analyst Bot Profiles
    const { data: bots, error: botError } = await supabase
        .from('profiles')
        .select('id, username, bot_persona')
        .eq('is_bot', true)
        .like('username', 'Analyst_%');

    if (botError || !bots || bots.length === 0) {
        console.error('  ❌ No Analyst Bots found.');
        return;
    }

    // 2. Prepare Context (OpenAI sees real price)
    const indicators = {
        rsi: Math.floor(Math.random() * 50) + 25, // Mocked for now, but structured
        macd: Math.random() > 0.5 ? 'Bullish Cross' : 'Neutral',
        bollinger: 'Tightening (Squeeze potential)',
        volume_delta: '+5.2%'
    };

    const marketContext = `
        Symbol: ${symbol}
        Timeframe: ${timeframe}
        Timestamp: ${now.toISOString()}
        Price: ${price}
        Technical Context: ${JSON.stringify(indicators)}
    `;

    // 3. Batch Call OpenAI
    try {
        const completion = await openai.chat.completions.create({
            model: "gpt-4o-mini",
            messages: [
                {
                    role: "system",
                    content: `You are 10 specialized market analysts. Provide 10 unique comments based on the data.
                    Return a JSON object where each key is EXACTLY one of the following bot usernames: Analyst_RSI, Analyst_Momentum, Analyst_Trend, Analyst_Volatility, Analyst_Levels, Analyst_Volume, Analyst_Breakout, Analyst_Reversal, Analyst_Correlation, Analyst_Regime.
                    Constraint: Professional, technical, max 140 chars. Language: English.`
                },
                {
                    role: "user",
                    content: marketContext
                }
            ],
            response_format: { type: "json_object" }
        });

        const rawResults = JSON.parse(completion.choices[0].message.content || '{}');
        // Handle cases where OpenAI might nest results under a key like 'analysts'
        const results = rawResults.analysts || rawResults;
        console.log(`  🔍 OpenAI returned keys: ${Object.keys(results).join(', ')}`);

        // 4. Save to DB (Align candle_close_at to exact boundary)
        let durationMs = 15 * 60 * 1000;
        const tfVal = parseInt(timeframe);
        if (timeframe.endsWith('m')) durationMs = tfVal * 60 * 1000;
        else if (timeframe.endsWith('h')) durationMs = tfVal * 60 * 60 * 1000;
        else if (timeframe.endsWith('d')) durationMs = tfVal * 24 * 60 * 60 * 1000;

        const candleCloseAt = new Date(Math.ceil(now.getTime() / durationMs) * durationMs);

        let successCount = 0;
        for (const bot of bots) {
            const comment = results[bot.username];
            if (!comment) {
                console.warn(`  ⚠️ No comment found for bot: ${bot.username}`);
                continue;
            }

            const { error: insertError } = await supabase.from('predictions').insert({
                user_id: bot.id,
                asset_symbol: symbol,
                timeframe,
                direction: 'UP',
                target_percent: 0,
                entry_price: price,
                bet_amount: 0,
                is_opinion: true,
                channel: 'analyst_hub',
                comment,
                status: 'pending',
                candle_close_at: candleCloseAt.toISOString()
            });

            if (insertError) {
                console.error(`  ❌ DB Insert Error for ${bot.username}:`, insertError);
            } else {
                successCount++;
            }
        }
        console.log(`  ✅ Successfully posted ${successCount}/10 analyst insights.`);

    } catch (e) {
        console.error('  ❌ OpenAI/DB Error:', e);
    }
}

/**
 * ⏰ SCHEDULER: Determine when to run
 */
function checkSchedule() {
    const now = new Date();
    const min = now.getMinutes();
    const sec = now.getSeconds();
    const hour = now.getHours();

    // Safety: Only log heartbeat at top of minute 
    if (sec === 0) {
        console.log(`[${now.toLocaleTimeString()}] 💓 Heartbeat...`);
    }

    for (const tf of TIMEFRAMES) {
        let trigger = false;

        if (tf === '15m' && min % 15 === 0 && sec === 0) trigger = true;
        if (tf === '30m' && min % 30 === 0 && sec === 0) trigger = true;
        if (tf === '1h' && min === 0 && sec === 0) trigger = true;
        if (tf === '4h' && hour % 4 === 0 && min === 0 && sec === 0) trigger = true;
        if (tf === '1d' && hour === 0 && min === 0 && sec === 0) trigger = true;

        if (trigger) {
            runAnalysis(SYMBOL, tf);
        }
    }
}

/**
 * 🚀 BOOT
 */
console.log('--- 🤖 ANALYST HUB SCHEDULER STARTED ---');
console.log(`Watching: ${SYMBOL} | TFs: ${TIMEFRAMES.join(', ')}`);
console.log('Awaiting candle opens (00, 15, 30, 45)...');

// Run every second for precision
setInterval(checkSchedule, 1000);

// For testing: Run 15m analysis immediately on start if requested
if (process.argv.includes('--now')) {
    runAnalysis(SYMBOL, '15m');
}
