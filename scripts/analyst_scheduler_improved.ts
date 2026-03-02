import { createClient } from '@supabase/supabase-js';
import OpenAI from 'openai';
import dotenv from 'dotenv';
import fs from 'fs';
import path from 'path';

dotenv.config();

/**
 * ----------------------------------------------------------------------------
 * 🔒 SINGLE INSTANCE LOCK (프로세스 중복 실행 방지)
 * ----------------------------------------------------------------------------
 */
const LOCK_FILE = path.join(process.cwd(), '.analyst-scheduler.lock');
const PID_FILE = path.join(process.cwd(), '.analyst-scheduler.pid');

function acquireLock(): boolean {
    try {
        // Check if lock file exists
        if (fs.existsSync(LOCK_FILE)) {
            const pidStr = fs.readFileSync(PID_FILE, 'utf-8').trim();
            const oldPid = parseInt(pidStr);

            // Check if process is still running
            try {
                process.kill(oldPid, 0); // Signal 0 checks if process exists
                console.error(`❌ ERROR: Scheduler already running with PID ${oldPid}`);
                console.error(`   To force restart: kill ${oldPid} && rm ${LOCK_FILE} ${PID_FILE}`);
                return false;
            } catch (e) {
                // Process not running, remove stale lock
                console.log(`🧹 Removing stale lock from PID ${oldPid}`);
                fs.unlinkSync(LOCK_FILE);
                fs.unlinkSync(PID_FILE);
            }
        }

        // Create lock
        fs.writeFileSync(LOCK_FILE, new Date().toISOString());
        fs.writeFileSync(PID_FILE, process.pid.toString());
        console.log(`🔒 Lock acquired: PID ${process.pid}`);

        // Clean up on exit
        process.on('exit', () => {
            try {
                if (fs.existsSync(LOCK_FILE)) fs.unlinkSync(LOCK_FILE);
                if (fs.existsSync(PID_FILE)) fs.unlinkSync(PID_FILE);
            } catch (e) { /* ignore */ }
        });

        process.on('SIGINT', () => {
            console.log('\n🛑 Received SIGINT, cleaning up...');
            process.exit(0);
        });

        process.on('SIGTERM', () => {
            console.log('\n🛑 Received SIGTERM, cleaning up...');
            process.exit(0);
        });

        return true;
    } catch (e: any) {
        console.error(`❌ Failed to acquire lock:`, e.message);
        return false;
    }
}

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

const TIMEFRAMES = ['1h', '4h'];

// Crypto only for tasting
// 10 Crypto, 10 Stocks, 10 Commodities (Total 30)
const ALL_ASSETS = [
    // Crypto (10)
    'BTCUSDT', 'ETHUSDT', 'SOLUSDT', 'XRPUSDT', 'DOGEUSDT',
    'ADAUSDT', 'AVAXUSDT', 'DOTUSDT', 'LINKUSDT', 'MATICUSDT',
    // Stocks (10)
    'AAPL', 'NVDA', 'TSLA', 'MSFT', 'AMZN',
    'GOOGL', 'META', 'NFLX', 'AMD', 'INTC',
    // Commodities (10)
    'XAUUSD', 'XAGUSD', 'WTI', 'NG', 'CORN',
    'SOY', 'WHEAT', 'HG', 'PL', 'PA'
];

/**
 * 🔍 HELPER: Get Real Price from Binance (Crypto only)
 */
async function getRealPrice(symbol: string) {
    try {
        const cleanSymbol = symbol.toUpperCase().replace('/', '');
        const url = `https://api.binance.com/api/v3/ticker/price?symbol=${cleanSymbol}`;
        const res = await fetch(url);
        const json: any = await res.json();
        return parseFloat(json.price) || 0;
    } catch (e) {
        // For non-crypto assets, use mock price
        return Math.random() * 1000 + 100;
    }
}

/**
 * 🧠 ENGINE: Run AI Analysis with Direction & Confidence
 */
async function runAnalysis(symbol: string, timeframe: string) {
    // Check daily API limit first
    if (!canMakeApiCall()) {
        console.warn(`⚠️ Daily API limit reached. Skipping ${symbol} (${timeframe})`);
        return;
    }

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
        rsi: Math.floor(Math.random() * 50) + 25,
        macd: Math.random() > 0.5 ? 'Bullish Cross' : 'Bearish Cross',
        bollinger: Math.random() > 0.5 ? 'Upper Band Touch' : 'Lower Band Touch',
        volume_delta: `${(Math.random() * 10 - 5).toFixed(1)}%`,
        trend: Math.random() > 0.5 ? 'Uptrend' : 'Downtrend'
    };

    const marketContext = `
        Symbol: ${symbol}
        Timeframe: ${timeframe}
        Timestamp: ${now.toISOString()}
        Current Price: $${price}
        Technical Indicators: ${JSON.stringify(indicators, null, 2)}

        Task: Provide analysis for each of the 10 analysts listed below. Each analysis must include:
        1. Direction: "UP" or "DOWN"
        2. Confidence: A percentage (0-100) representing conviction level
        3. Reasoning: 5-7 sentences of detailed technical analysis explaining the prediction

        Analysts: Analyst_RSI, Analyst_Momentum, Analyst_Trend, Analyst_Volatility, Analyst_Levels, Analyst_Volume, Analyst_Breakout, Analyst_Reversal, Analyst_Correlation, Analyst_Regime
    `;

    // 3. Batch Call OpenAI
    try {
        const completion = await openai.chat.completions.create({
            model: "gpt-4o-mini",
            messages: [
                {
                    role: "system",
                    content: `You are a system managing 10 specialized market analysts. Each analyst must provide:
                    - "direction": "UP" or "DOWN"
                    - "confidence": number between 50-95 (percentage)
                    - "reasoning": 5-7 sentences of detailed technical analysis

                    Return a JSON object where each key is EXACTLY one of these usernames: Analyst_RSI, Analyst_Momentum, Analyst_Trend, Analyst_Volatility, Analyst_Levels, Analyst_Volume, Analyst_Breakout, Analyst_Reversal, Analyst_Correlation, Analyst_Regime.

                    Each value must be an object with: { "direction": "UP"|"DOWN", "confidence": number, "reasoning": string }

                    Make analyses diverse and realistic. Language: English. Professional tone.`
                },
                {
                    role: "user",
                    content: marketContext
                }
            ],
            response_format: { type: "json_object" }
        });

        const rawResults = JSON.parse(completion.choices[0].message.content || '{}');
        const results = rawResults.analysts || rawResults;
        console.log(`  🔍 OpenAI returned keys: ${Object.keys(results).join(', ')}`);

        // Track API usage
        incrementApiCalls();

        // 4. Save to DB (Align candle_close_at to exact boundary)
        let durationMs = 15 * 60 * 1000;
        const tfVal = parseInt(timeframe);
        if (timeframe.endsWith('m')) durationMs = tfVal * 60 * 1000;
        else if (timeframe.endsWith('h')) durationMs = tfVal * 60 * 60 * 1000;
        else if (timeframe.endsWith('d')) durationMs = tfVal * 24 * 60 * 60 * 1000;

        const candleCloseAt = new Date(Math.ceil(now.getTime() / durationMs) * durationMs);

        let successCount = 0;
        for (const bot of bots) {
            const analysis = results[bot.username];
            if (!analysis || !analysis.reasoning) {
                console.warn(`  ⚠️ No analysis found for bot: ${bot.username}`);
                continue;
            }

            const { error: insertError } = await supabase.from('predictions').insert({
                user_id: bot.id,
                asset_symbol: symbol,
                timeframe,
                direction: analysis.direction || 'UP',
                target_percent: parseFloat(analysis.confidence) || 70,
                entry_price: price,
                bet_amount: 10, // Default 10pts for AI
                is_opinion: true,
                channel: 'analyst_hub',
                comment: analysis.reasoning,
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
    if (sec === 0 && min % 5 === 0) {
        console.log(`[${now.toLocaleTimeString()}] 💓 Heartbeat... Processing ${ALL_ASSETS.length} assets`);
    }

    for (const tf of TIMEFRAMES) {
        let trigger = false;

        if (tf === '15m' && min % 15 === 0 && sec === 0) trigger = true;
        if (tf === '30m' && min % 30 === 0 && sec === 0) trigger = true;
        if (tf === '1h' && min === 0 && sec === 0) trigger = true;
        // 4h: 한국시간 1시, 5시, 9시, 13시, 17시, 21시 (hour % 4 === 1)
        if (tf === '4h' && hour % 4 === 1 && min === 0 && sec === 0) trigger = true;
        // 1d: 한국시간 매일 오전 9시
        if (tf === '1d' && hour === 9 && min === 0 && sec === 0) trigger = true;

        if (trigger) {
            // Run analysis for ALL assets in this timeframe
            console.log(`\n🎯 TRIGGERED: ${tf} round for ${ALL_ASSETS.length} assets`);
            for (const symbol of ALL_ASSETS) {
                // Add slight delay to avoid rate limiting
                setTimeout(() => runAnalysis(symbol, tf), ALL_ASSETS.indexOf(symbol) * 2000);
            }
        }
    }
}

/**
 * ----------------------------------------------------------------------------
 * 📊 DAILY API CALL TRACKER (비용 제어)
 * ----------------------------------------------------------------------------
 */
const CALL_TRACKER_FILE = path.join(process.cwd(), '.analyst-api-calls.json');
const MAX_DAILY_CALLS = 3000; // 일일 최대 호출 횟수

interface CallTracker {
    date: string;
    count: number;
    lastReset: string;
}

function loadCallTracker(): CallTracker {
    try {
        if (fs.existsSync(CALL_TRACKER_FILE)) {
            const data = JSON.parse(fs.readFileSync(CALL_TRACKER_FILE, 'utf-8'));
            const today = new Date().toISOString().split('T')[0];

            // Reset if new day
            if (data.date !== today) {
                return { date: today, count: 0, lastReset: new Date().toISOString() };
            }
            return data;
        }
    } catch (e) {
        console.warn('⚠️ Failed to load call tracker, creating new one');
    }

    const today = new Date().toISOString().split('T')[0];
    return { date: today, count: 0, lastReset: new Date().toISOString() };
}

function saveCallTracker(tracker: CallTracker) {
    fs.writeFileSync(CALL_TRACKER_FILE, JSON.stringify(tracker, null, 2));
}

function canMakeApiCall(): boolean {
    const tracker = loadCallTracker();
    return tracker.count < MAX_DAILY_CALLS;
}

function incrementApiCalls() {
    const tracker = loadCallTracker();
    tracker.count++;
    saveCallTracker(tracker);

    if (tracker.count % 100 === 0) {
        console.log(`📊 Daily API Calls: ${tracker.count}/${MAX_DAILY_CALLS} (${((tracker.count / MAX_DAILY_CALLS) * 100).toFixed(1)}%)`);
    }

    if (tracker.count >= MAX_DAILY_CALLS) {
        console.error(`❌ DAILY LIMIT REACHED: ${tracker.count}/${MAX_DAILY_CALLS} calls. Scheduler will pause until tomorrow.`);
    }
}

/**
 * 🚀 BOOT
 */
// 1. Check for duplicate process
if (!acquireLock()) {
    console.error('❌ Cannot start: Another instance is already running');
    process.exit(1);
}

console.log('--- 🤖 ANALYST HUB SCHEDULER V2 STARTED ---');
console.log(`Watching: ${ALL_ASSETS.length} assets | TFs: ${TIMEFRAMES.join(', ')}`);
console.log(`Total Rounds: ${ALL_ASSETS.length * TIMEFRAMES.length} = ${ALL_ASSETS.length * TIMEFRAMES.length}`);

// Show daily call status
const tracker = loadCallTracker();
console.log(`📊 Today's API Calls: ${tracker.count}/${MAX_DAILY_CALLS} (${((tracker.count / MAX_DAILY_CALLS) * 100).toFixed(1)}%)`);
console.log('Awaiting candle opens (00, 15, 30, 45)...\n');

// Run every second for precision
setInterval(checkSchedule, 1000);

// For testing: Run analysis immediately on start if requested
if (process.argv.includes('--now')) {
    const nowIndex = process.argv.indexOf('--now');
    const testSymbol = process.argv[nowIndex + 1] || 'BTCUSDT';
    const testTF = process.argv[nowIndex + 2] || '15m';
    console.log(`🧪 TEST MODE: Running ${testSymbol} ${testTF} immediately...\n`);
    runAnalysis(testSymbol, testTF);
}
