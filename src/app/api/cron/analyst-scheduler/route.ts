import { createClient } from '@supabase/supabase-js';
import OpenAI from 'openai';
import { NextResponse } from 'next/server';
import { ASSETS, isMarketOpen, type Asset } from '@/lib/constants';
import { verifyCronSecret } from '@/lib/server-access';

// Vercel Cron Job endpoint for AI Analyst Scheduler
// 상용망 스케줄러 - 중복 실행 방지 및 비용 제어

const supabase = createClient(
    process.env.NEXT_PUBLIC_SUPABASE_URL!,
    process.env.SUPABASE_SERVICE_ROLE_KEY!
);

const openai = new OpenAI({ apiKey: process.env.OPENAI_API_KEY! });

const MAX_DAILY_CALLS = 3000;
const LOCK_KEY = 'analyst-scheduler-cron';
const LOCK_TTL = 300; // 5분

// Get unique instance ID
const INSTANCE_ID = `vercel-${process.env.VERCEL_DEPLOYMENT_ID?.substring(0, 8) || 'local'}-${Date.now()}`;

/**
 * Database-based Lock & API Tracking
 */
async function acquireLock(): Promise<{ success: boolean; error?: string }> {
    try {
        const { data, error } = await supabase.rpc('acquire_scheduler_lock', {
            p_lock_key: LOCK_KEY,
            p_locked_by: INSTANCE_ID,
            p_ttl_seconds: LOCK_TTL
        });

        if (error) throw error;
        return data as { success: boolean; error?: string };
    } catch (e: any) {
        return { success: false, error: e.message };
    }
}

async function releaseLock(): Promise<void> {
    try {
        await supabase.rpc('release_scheduler_lock', {
            p_lock_key: LOCK_KEY,
            p_locked_by: INSTANCE_ID
        });
    } catch (e) {
        console.error('Failed to release lock:', e);
    }
}

async function canMakeApiCall(): Promise<boolean> {
    try {
        const { data, error } = await supabase.rpc('can_make_api_call', {
            p_service: 'openai',
            p_max_daily: MAX_DAILY_CALLS
        });

        if (error) throw error;
        return data === true;
    } catch (e) {
        console.error('Failed to check API limit:', e);
        return false;
    }
}

async function trackApiCall(): Promise<void> {
    try {
        await supabase.rpc('track_api_call', {
            p_service: 'openai',
            p_increment: 1
        });
    } catch (e) {
        console.error('Failed to track API call:', e);
    }
}

async function getApiUsage(): Promise<number> {
    try {
        const { data, error } = await supabase.rpc('get_api_usage', {
            p_service: 'openai',
            p_date: new Date().toISOString().split('T')[0]
        });

        if (error) throw error;
        return data?.count || 0;
    } catch (e) {
        console.error('Failed to get API usage:', e);
        return 0;
    }
}

/**
 * Main Cron Handler
 */
export async function GET(req: Request) {
    const startTime = Date.now();
    console.log(`[${new Date().toISOString()}] 🚀 Analyst Scheduler Cron triggered`);

    const authError = verifyCronSecret(req);
    if (authError) return authError;

    // 2. Acquire distributed lock
    const lockResult = await acquireLock();
    if (!lockResult.success) {
        console.log(`⏭️ Skipping: ${lockResult.error}`);
        return NextResponse.json({
            skipped: true,
            reason: lockResult.error,
            instance: INSTANCE_ID
        });
    }

    console.log(`🔒 Lock acquired by ${INSTANCE_ID}`);

    try {
        // 3. Check if scheduler is enabled
        const { data: settings, error: settingsError } = await supabase.rpc('get_scheduler_settings', {
            p_service_name: 'ai_analyst'
        });

        if (settingsError) {
            console.error('Failed to fetch scheduler settings:', settingsError);
        }

        const schedulerEnabled = settings?.[0]?.enabled || false;
        const enabledTimeframes = settings?.[0]?.timeframes || ['15m', '30m', '1h', '4h', '1d'];

        if (!schedulerEnabled) {
            console.log('⏭️ Scheduler is disabled in admin settings');
            return NextResponse.json({
                skipped: true,
                reason: 'Scheduler disabled by admin',
                instance: INSTANCE_ID
            });
        }

        console.log(`✅ Scheduler enabled. Active timeframes: ${enabledTimeframes.join(', ')}`);

        // 4. Check daily API limit
        const canCall = await canMakeApiCall();
        const currentUsage = await getApiUsage();

        if (!canCall) {
            console.warn(`⚠️ Daily API limit reached: ${currentUsage}/${MAX_DAILY_CALLS}`);
            return NextResponse.json({
                skipped: true,
                reason: 'Daily API limit reached',
                usage: currentUsage,
                limit: MAX_DAILY_CALLS
            });
        }

        console.log(`📊 Daily API Usage: ${currentUsage}/${MAX_DAILY_CALLS}`);

        // 5. Determine which timeframes to process
        // GitHub Actions cron can be delayed ±5 minutes, so use ±3 min tolerance
        const now = new Date();
        const totalMinutes = now.getUTCHours() * 60 + now.getUTCMinutes();

        const isNear = (interval: number) => {
            const nearest = Math.round(totalMinutes / interval) * interval;
            return Math.abs(totalMinutes - nearest) <= 7;
        };

        const scheduledTimeframes: string[] = [];
        if (isNear(15)) scheduledTimeframes.push('15m');
        if (isNear(30)) scheduledTimeframes.push('30m');
        if (isNear(60)) scheduledTimeframes.push('1h');
        if (isNear(240)) scheduledTimeframes.push('4h');
        if (isNear(1440)) scheduledTimeframes.push('1d');

        // Deduplicate (e.g. :00 qualifies for 15m, 30m, 1h)
        const uniqueTimeframes = [...new Set(scheduledTimeframes)];

        // Filter by admin-enabled timeframes
        const timeframes = uniqueTimeframes.filter(tf => enabledTimeframes.includes(tf));

        console.log(`⏰ Current UTC minute: ${totalMinutes}, Matched: ${uniqueTimeframes.join(', ')}`);

        if (timeframes.length === 0) {
            console.log('⏭️ No enabled timeframes to process at this time');
            return NextResponse.json({ skipped: true, reason: 'No enabled timeframes scheduled', utc_minute: totalMinutes });
        }

        console.log(`⏰ Processing timeframes: ${timeframes.join(', ')}`);

        // 6. Get all 30 assets and filter by market hours
        const allAssets: Asset[] = [
            ...ASSETS.CRYPTO,
            ...ASSETS.STOCKS,
            ...ASSETS.COMMODITIES
        ];

        // Filter assets based on market hours
        const tradableAssets = allAssets.filter(asset => {
            if (asset.type === 'CRYPTO') return true; // Crypto is always tradable
            return isMarketOpen(asset);
        });

        console.log(`📈 Tradable assets: ${tradableAssets.length}/${allAssets.length}`);
        console.log(`   - Crypto: ${tradableAssets.filter(a => a.type === 'CRYPTO').length}`);
        console.log(`   - Stocks: ${tradableAssets.filter(a => a.type === 'STOCK').length}`);
        console.log(`   - Commodities: ${tradableAssets.filter(a => a.type === 'COMMODITY').length}`);

        // 7. Fetch analyst bot profiles
        const { data: bots } = await supabase
            .from('profiles')
            .select('id, username')
            .eq('is_bot', true)
            .like('username', 'Analyst_%');

        if (!bots || bots.length === 0) {
            throw new Error('No analyst bots found');
        }

        console.log(`🤖 Found ${bots.length} analyst bots`);

        // 8. Generate analyses (limit by remaining API quota)
        const remainingCalls = MAX_DAILY_CALLS - currentUsage;
        const totalRounds = tradableAssets.length * timeframes.length;
        const maxRounds = Math.min(totalRounds, remainingCalls);

        console.log(`🎯 Planning ${totalRounds} rounds (${tradableAssets.length} assets × ${timeframes.length} TFs)`);
        console.log(`🎯 Will process ${maxRounds} rounds (limited by API quota)`);

        let processed = 0;
        let errors = 0;
        let skipped = 0;

        for (const timeframe of timeframes) {
            for (const asset of tradableAssets) {
                if (processed >= maxRounds) {
                    skipped++;
                    continue;
                }

                try {
                    // Get current price (mock for now - replace with real price API)
                    const price = Math.random() * 1000 + 100;

                    // 1. Prepare Context (OpenAI sees real price + indicators)
                    const indicators = {
                        rsi: Math.floor(Math.random() * 50) + 25,
                        macd: Math.random() > 0.5 ? 'Bullish Cross' : 'Bearish Cross',
                        bollinger: Math.random() > 0.5 ? 'Upper Band Touch' : 'Lower Band Touch',
                        volume_delta: `${(Math.random() * 10 - 5).toFixed(1)}%`,
                        trend: Math.random() > 0.5 ? 'Uptrend' : 'Downtrend'
                    };

                    const marketContext = `
                        Symbol: ${asset.symbol}
                        Name: ${asset.name}
                        Type: ${asset.type}
                        Timeframe: ${timeframe}
                        Timestamp: ${new Date().toISOString()}
                        Current Price: $${price.toFixed(2)}
                        Technical Indicators: ${JSON.stringify(indicators, null, 2)}

                        Task: Provide a professional market analysis as 10 specialized analysts.
                    `;

                    // 2. Call OpenAI with Professional Prompt
                    const completion = await openai.chat.completions.create({
                        model: 'gpt-4o-mini',
                        messages: [
                            {
                                role: 'system',
                                content: `You are a system managing 10 specialized market analysts. Each analyst must provide:
                                - "direction": "UP" or "DOWN"
                                - "confidence": number between 50-95 (percentage)
                                - "reasoning": 5-7 sentences of detailed technical analysis explaining the price action

                                Return a JSON object where each key is EXACTLY one of these usernames: Analyst_RSI, Analyst_Momentum, Analyst_Trend, Analyst_Volatility, Analyst_Levels, Analyst_Volume, Analyst_Breakout, Analyst_Reversal, Analyst_Correlation, Analyst_Regime.

                                Each value must be an object with: { "direction": "UP"|"DOWN", "confidence": number, "reasoning": string }

                                Make analyses diverse, realistic, and specific to the indicators provided. Language: English. Professional tone.`
                            },
                            {
                                role: 'user',
                                content: marketContext
                            }
                        ],
                        response_format: { type: 'json_object' }
                    });

                    await trackApiCall();

                    const results = JSON.parse(completion.choices[0].message.content || '{}');

                    // Calculate candle close time
                    const tfMinutes = timeframe === '15m' ? 15 : timeframe === '30m' ? 30 :
                        timeframe === '1h' ? 60 : timeframe === '4h' ? 240 : 1440;
                    const candleCloseAt = new Date(Date.now() + tfMinutes * 60 * 1000).toISOString();
                    const roundTime = new Date(Math.floor(Date.now() / (tfMinutes * 60 * 1000)) * (tfMinutes * 60 * 1000)).toISOString();

                    // Save each analyst's prediction
                    for (const bot of bots) {
                        const analysis = results[bot.username];
                        if (!analysis) continue;

                        const { error: insertError } = await supabase
                            .from('predictions')
                            .insert({
                                user_id: bot.id,
                                asset_symbol: asset.symbol,
                                timeframe,
                                direction: analysis.direction || 'UP',
                                target_percent: parseFloat(analysis.confidence) || 70,
                                entry_price: price,
                                bet_amount: 10, // Default mirrored stake size for analyst posts
                                is_opinion: true,
                                channel: 'analyst_hub',
                                comment: analysis.reasoning || 'Analysis unavailable',
                                status: 'pending',
                                candle_close_at: candleCloseAt,
                                round_time: roundTime
                            });

                        if (insertError) {
                            console.error(`  ❌ Failed to save ${bot.username} analysis:`, insertError.message);
                        }
                    }

                    processed++;
                    console.log(`✅ ${asset.symbol} (${asset.type}) ${timeframe}: ${Object.keys(results).length} analysts posted`);

                } catch (e: any) {
                    console.error(`❌ Error processing ${asset.symbol} ${timeframe}:`, e.message);
                    errors++;
                }
            }
        }

        const duration = Date.now() - startTime;
        const finalUsage = await getApiUsage();

        console.log(`✅ Completed: ${processed} rounds, ${errors} errors, ${skipped} skipped, ${duration}ms`);
        console.log(`📊 Final usage: ${finalUsage}/${MAX_DAILY_CALLS}`);

        return NextResponse.json({
            success: true,
            processed,
            errors,
            skipped,
            duration_ms: duration,
            api_usage: finalUsage,
            api_limit: MAX_DAILY_CALLS,
            timeframes,
            total_assets: allAssets.length,
            tradable_assets: tradableAssets.length,
            instance: INSTANCE_ID
        });

    } catch (error: any) {
        console.error('❌ Cron error:', error);
        return NextResponse.json({
            success: false,
            error: error.message,
            instance: INSTANCE_ID
        }, { status: 500 });

    } finally {
        // Always release lock
        await releaseLock();
        console.log(`🔓 Lock released by ${INSTANCE_ID}`);
    }
}
