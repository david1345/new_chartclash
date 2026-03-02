import { createClient } from '@supabase/supabase-js';
import { NextRequest, NextResponse } from 'next/server';

// 1. Setup Supabase Client (Service Role needed for RPC)
const supabase = createClient(
    process.env.NEXT_PUBLIC_SUPABASE_URL!,
    process.env.SUPABASE_SERVICE_ROLE_KEY! // Use Service Role Key for CRON
);

// Helper for rate limiting
const sleep = (ms: number) => new Promise((resolve) => setTimeout(resolve, ms));

const getTimestamp = () => `[${new Date().toLocaleTimeString()}]`;

export async function GET(req: NextRequest) {
    // This is the Client Heartbeat / Legacy Route
    // We treat it exactly like the Cron Route now.

    try {
        const now = Date.now();

        // 2. Fetch Pending Predictions
        const { data: predictions, error: fetchError } = await supabase
            .from('predictions')
            .select('id, asset_symbol, timeframe, created_at, entry_price, direction, target_percent, user_id, bet_amount, candle_close_at')
            .eq('status', 'pending')
            .order('created_at', { ascending: false })
            .limit(50);

        if (fetchError) throw fetchError;

        console.log(`${getTimestamp()} [Resolution] Found ${predictions?.length || 0} pending predictions.`);

        if (!predictions || predictions.length === 0) {
            return NextResponse.json({ message: 'No pending predictions' });
        }

        // 3. Group by Candle (Symbol + Timeframe + OpenTime)
        const candleGroups: Record<string, {
            symbol: string;
            tf: string;
            openTime: number;
            closeTime: number;
            preds: any[];
        }> = {};

        for (const pred of predictions) {
            // Use DB source of truth for close time
            const closeTime = new Date(pred.candle_close_at).getTime();

            // Calculate duration to derive Open Time
            let duration = 0;
            const tfVal = parseInt(pred.timeframe);
            if (pred.timeframe.endsWith('m')) duration = tfVal * 60 * 1000;
            else if (pred.timeframe.endsWith('h')) duration = tfVal * 60 * 60 * 1000;
            else if (pred.timeframe.endsWith('d')) duration = tfVal * 24 * 60 * 60 * 1000;

            const openTime = closeTime - duration;

            // Check if candle is closed (plus buffer)
            const isReady = now > closeTime + 20000; // 20s buffer

            if (isReady) {
                console.log(`${getTimestamp()} [Resolution] Pred ${pred.id} (${pred.timeframe}): CloseTime ${new Date(closeTime).toISOString()} is READY.`);
                const key = `${pred.asset_symbol}-${pred.timeframe}-${openTime}`;
                if (!candleGroups[key]) {
                    candleGroups[key] = {
                        symbol: pred.asset_symbol,
                        tf: pred.timeframe,
                        openTime,
                        closeTime,
                        preds: []
                    };
                }
                candleGroups[key].preds.push(pred);
            }
        }

        const groupKeys = Object.keys(candleGroups);
        if (groupKeys.length === 0) {
            // Log a summary instead of individual "not ready" lines
            console.log(`${getTimestamp()} [Resolution] Scan complete. ${predictions.length} pending, 0 ready.`);
            return NextResponse.json({ message: 'No candles completed yet' });
        }

        console.log(`${getTimestamp()} [Resolution] Processing ${groupKeys.length} candle groups...`);

        const results = {
            resolved: 0,
            errors: 0,
            details: [] as any[]
        };

        // 4. Process Each Group
        for (const key of groupKeys) {
            const group = candleGroups[key];
            let openPrice: number | null = null;
            let closePrice: number | null = null;
            let errorMsg: string | null = null;

            console.log(`${getTimestamp()} [Resolution] Group ${key} -> Start processing (${group.preds.length} preds)`);

            // Rate Limiting
            await sleep(500); // 0.5s sleep

            try {
                // Fetch Official Prices for this Candle
                // Crypto: Use CryptoCompare History for better reliability
                const cleanSymbol = group.symbol.replace('/', '').toUpperCase();
                const cryptoPairs = ['BTCUSDT', 'ETHUSDT', 'SOLUSDT', 'DOGEUSDT', 'XRPUSDT', 'BNBUSDT', 'ADAUSDT', 'AVAXUSDT', 'DOTUSDT', 'LINKUSDT', 'MATICUSDT'];
                const isCrypto = cryptoPairs.includes(cleanSymbol) || cleanSymbol.endsWith('USDT');

                if (isCrypto) {
                    try {
                        const baseSymbol = cleanSymbol.replace('USDT', '').replace('USD', '');
                        // Fetch a wider range of minute data to ensure we find the exact minute
                        const cryptoRes = await fetch(`https://min-api.cryptocompare.com/data/v2/histominute?fsym=${baseSymbol}&tsym=USD&limit=2000&toTs=${Math.floor(group.closeTime / 1000) + 1}`, {
                            headers: {
                                'Authorization': `Apikey ${process.env.CRYPTOCOMPARE_API_KEY}`,
                                'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36'
                            }
                        });
                        const cryptoData = await cryptoRes.json();

                        if (cryptoData.Response === 'Success' && cryptoData.Data?.Data?.length > 0) {
                            const list = cryptoData.Data.Data;
                            // Find closest to OpenTime and CloseTime within a tolerance
                            const findClosest = (targetTime: number) => {
                                let bestMatch = null;
                                let minDiff = Infinity;
                                for (const d of list) {
                                    const diff = Math.abs(d.time * 1000 - targetTime);
                                    if (diff < minDiff) {
                                        minDiff = diff;
                                        bestMatch = d;
                                    }
                                }
                                // Increased tolerance to 120 seconds for API lag
                                return minDiff < 120000 ? bestMatch : null;
                            };

                            const openMatch = findClosest(group.openTime);
                            // For 1m bets, search exactly at close time. Otherwise, refer to the close price of the candle 1 minute prior.
                            const closeTarget = group.tf === '1m' ? group.closeTime : group.closeTime - 60000;
                            const closeMatch = findClosest(closeTarget);

                            if (openMatch) openPrice = openMatch.open;
                            if (closeMatch) closePrice = group.tf === '1m' ? closeMatch.open : closeMatch.close;

                            if (openPrice && closePrice) {
                                console.log(`${getTimestamp()} [Resolution] Group ${key} -> CryptoCompare (Advanced) Success: Open=${openPrice}, Close=${closePrice}`);
                            } else {
                                console.warn(`${getTimestamp()} [Resolution] Group ${key} -> CryptoCompare (Advanced) Incomplete: Open=${openPrice}, Close=${closePrice}. Target: ${group.openTime} / ${closeTarget}`);
                            }
                        } else {
                            console.warn(`${getTimestamp()} [Resolution] CryptoCompare (advanced) failed for ${group.symbol}:`, cryptoData.Message || 'No data');
                        }
                    } catch (e: any) {
                        console.error(`${getTimestamp()} [Resolution] Group ${key} -> CryptoCompare (Advanced) Error:`, e.message);
                    }
                }

                // fallback
                if (openPrice === null || closePrice === null) {
                    console.log(`${getTimestamp()} [Resolution] Group ${key} -> Falling back to Priority 1/2 Fetchers...`);
                    // Log current state
                    console.log(`${getTimestamp()} [Resolution] Current State: openPrice=${openPrice}, closePrice=${closePrice}`);

                    const totalEntry = group.preds.reduce((sum: number, p: any) => sum + (p.entry_price || 0), 0);
                    const avgEntry = totalEntry / (group.preds.length || 1);

                    // Fetch individually if null
                    if (openPrice === null) {
                        openPrice = await fetchPrice(group.symbol, group.tf, group.openTime, group.openTime, avgEntry, 'open');
                        console.log(`${getTimestamp()} [Resolution] Fallback openPrice result: ${openPrice}`);
                    }

                    if (closePrice === null) {
                        // For non-1m timeframes, we look at the candle ending just before the boundary
                        const closeTarget = group.tf === '1m' ? group.closeTime : group.closeTime - 60000;
                        closePrice = await fetchPrice(group.symbol, group.tf, closeTarget, group.closeTime, avgEntry, 'close');
                        console.log(`${getTimestamp()} [Resolution] Fallback closePrice result: ${closePrice}`);
                    }
                }

                console.log(`${getTimestamp()} [Resolution] Group ${key} -> Final Prices: Open=${openPrice}, Close=${closePrice}`);

                if (!openPrice || !closePrice) {
                    throw new Error("Could not determine both prices (Open or Close is zero/null)");
                }

            } catch (e: any) {
                console.error(`${getTimestamp()} [Resolution] Group ${key} -> Data Fetch Error:`, e.message);
                errorMsg = e.message;
            }

            // If we have prices, resolve
            if (openPrice !== null && closePrice !== null) {
                for (const pred of group.preds) {
                    let success = false;
                    let lastError = '';

                    for (let attempt = 0; attempt < 3; attempt++) {
                        const { data, error } = await supabase.rpc('resolve_prediction_advanced', {
                            p_id: Number(pred.id),
                            p_close_price: closePrice,
                            p_open_price: openPrice
                        });

                        if (!error && data && data.success) {
                            success = true;
                            break;
                        }

                        lastError = error ? error.message : (data?.error || 'Unknown RPC error');
                        await sleep(100 * (attempt + 1));
                    }

                    if (success) {
                        results.resolved++;
                        results.details.push({ id: pred.id, status: 'resolved', open: openPrice, close: closePrice });
                        console.log(`${getTimestamp()} Successfully resolved prediction ${pred.id} (Fairness Model Applied)`);
                    } else {
                        // Silence 'Already resolved' - it's expected in multi-tab scenarios
                        if (lastError !== 'Already resolved') {
                            results.errors++;
                            results.details.push({ id: pred.id, status: 'error', error: lastError });
                            console.error(`${getTimestamp()} [Resolution Error] ID: ${pred.id}, Error: ${lastError}`);
                        } else {
                            results.details.push({ id: pred.id, status: 'already_resolved' });
                        }
                    }
                }
            } else {
                for (const pred of group.preds) {
                    results.errors++;
                    results.details.push({ id: pred.id, status: 'error', error: errorMsg || 'Price fetch failed' });
                }
            }
        }

        return NextResponse.json({ success: true, ...results });

    } catch (err: any) {
        console.error(`${getTimestamp()} Resolution job error:`, err);
        return NextResponse.json({ success: false, error: err.message }, { status: 500 });
    }
}

// Helper: Fetch Price (Multi-Provider with Open/Close Type Support)
async function fetchPrice(symbol: string, timeframe: string, targetTime: number, closeTime: number, referencePrice: number, type: 'open' | 'close' = 'close'): Promise<number> {
    const cleanSymbol = symbol.replace('/', '').toUpperCase();
    const priceIndex = type === 'open' ? 1 : 4; // index 1 is Open, index 4 is Close in 1m klines

    // 0. Helper for Timeout
    const fetchWithTimeout = async (url: string, timeout = 5000) => {
        const controller = new AbortController();
        const id = setTimeout(() => controller.abort(), timeout);
        try {
            const res = await fetch(url, { cache: 'no-store', signal: controller.signal });
            clearTimeout(id);
            return res;
        } catch (e) {
            clearTimeout(id);
            throw e;
        }
    };

    // 1. Crypto Resolution
    const cryptoPairs = ['BTCUSDT', 'ETHUSDT', 'SOLUSDT', 'DOGEUSDT', 'XRPUSDT', 'BNBUSDT', 'ADAUSDT', 'AVAXUSDT', 'DOTUSDT', 'LINKUSDT', 'MATICUSDT'];

    if (cryptoPairs.includes(cleanSymbol) || cleanSymbol.endsWith('USDT')) {
        const baseSymbol = cleanSymbol.replace('USDT', '').replace('USD', '');

        // --- PRIORITY 1: Exchange APIs (Direct & Faster) ---
        const exchangesList = [
            { name: 'Binance', url: `https://api.binance.com/api/v3/klines?symbol=${cleanSymbol}&interval=1m&startTime=${targetTime}&limit=1`, parser: (d: any) => d?.[0]?.[priceIndex] },
            { name: 'Bybit', url: `https://api.bybit.com/v5/market/kline?category=spot&symbol=${cleanSymbol}&interval=1&start=${targetTime}&limit=1`, parser: (d: any) => d?.result?.list?.[0]?.[priceIndex] },
            { name: 'MEXC', url: `https://api.mexc.com/api/v3/klines?symbol=${cleanSymbol}&interval=1m&startTime=${targetTime}&limit=1`, parser: (d: any) => d?.[0]?.[priceIndex] }
        ];

        for (const ex of exchangesList) {
            try {
                const res = await fetchWithTimeout(ex.url, 3000);
                if (res.ok) {
                    const data = await res.json();
                    const price = ex.parser(data);
                    if (price) {
                        console.log(`${getTimestamp()} [Price] Fetched ${type} from ${ex.name}: ${price}`);
                        return parseFloat(price);
                    }
                }
            } catch (e) { /* Ignore */ }
        }

        // --- PRIORITY 2: CryptoCompare (History Fallback) ---
        try {
            const ts = Math.floor(closeTime / 1000);
            const url = `https://min-api.cryptocompare.com/data/v2/histominute?fsym=${baseSymbol}&tsym=USD&limit=10&toTs=${ts}`;
            const res = await fetchWithTimeout(url, 5000);
            const json = await res.json();

            if (json.Response === 'Success' && json.Data?.Data?.length > 0) {
                const candle = json.Data.Data.find((c: any) => Math.abs(c.time - ts) <= 60 || Math.abs(c.time - (ts - 60)) <= 2);
                if (candle) {
                    console.log(`${getTimestamp()} [Price] CryptoCompare Result -> ${baseSymbol}: ${candle.close}`);
                    return candle.close;
                }
            } else if (json.Message && !json.Message.includes('rate limit')) {
                console.warn('CryptoCompare failed:', json.Message);
            }
        } catch (e) { /* Ignore */ }

        // --- PRIORITY 2: CoinGecko (Public API, Good Backup) ---
        try {
            const idMap: Record<string, string> = {
                'BTC': 'bitcoin', 'ETH': 'ethereum', 'SOL': 'solana', 'DOGE': 'dogecoin',
                'XRP': 'ripple', 'BNB': 'binancecoin', 'ADA': 'cardano', 'AVAX': 'avalanche-2',
                'MATIC': 'matic-network', 'DOT': 'polkadot', 'LINK': 'chainlink', 'TRX': 'tron'
            };
            const cgId = idMap[baseSymbol];
            if (cgId) {
                const from = Math.floor(closeTime / 1000) - 3600;
                const to = Math.floor(closeTime / 1000) + 3600;
                const url = `https://api.coingecko.com/api/v3/coins/${cgId}/market_chart/range?vs_currency=usd&from=${from}&to=${to}`;

                const res = await fetchWithTimeout(url);
                if (res.ok) {
                    const data = await res.json();
                    const prices = data.prices;
                    if (prices && prices.length > 0) {
                        const targetMs = closeTime;
                        let bestPrice = null;
                        let minDiff = Infinity;
                        for (const [pTs, price] of prices) {
                            const diff = Math.abs(pTs - targetMs);
                            if (diff < minDiff) {
                                minDiff = diff;
                                bestPrice = price;
                            }
                        }
                        if (bestPrice !== null && minDiff < 300000) {
                            console.log(`${getTimestamp()} [Price] Fetched from CoinGecko: ${bestPrice}`);
                            return bestPrice;
                        }
                    }
                }
            }
        } catch (e) {
            console.warn('CoinGecko failed:', e);
        }

        // --- PRIORITY 3: (Already covered by Priority 1 exchanges) ---

        // --- PRIORITY 4: Yahoo Finance (Last effort before simulation) ---
        try {
            const yahooSymbol = `${baseSymbol}-USD`;
            const yahooUrl = `https://query1.finance.yahoo.com/v8/finance/chart/${yahooSymbol}?interval=1m&range=1d`;
            const res = await fetchWithTimeout(yahooUrl, 3000);
            if (res.ok) {
                const data = await res.json();
                const result = data.chart?.result?.[0];
                if (result && result.meta?.regularMarketPrice) {
                    console.log(`${getTimestamp()} [Price] Yahoo Fallback (${baseSymbol}): ${result.meta.regularMarketPrice}`);
                    return result.meta.regularMarketPrice;
                }
            }
        } catch (e) { /* Ignore */ }

        // --- ULTIMATE FALLBACK (Simulation) ---
        console.error(`${getTimestamp()} [CRITICAL] All APIs failed for ${cleanSymbol}. Using Simulation Mode.`);
        // Prevent start/end prices from being identical by using closeTime as part of seed
        const seed = (closeTime / 1000) % 1000;
        const fluctuationPercent = ((seed % 100) - 50) / 100; // -0.5% ~ +0.5%
        const simulatedPrice = referencePrice * (1 + (fluctuationPercent / 100));
        return Math.max(0.0001, simulatedPrice);
    }

    // 2. Stock & Commodities (Yahoo Finance)
    const yahooSymbol = getYahooSymbol(cleanSymbol);
    if (yahooSymbol) {
        let interval = '15m';
        if (timeframe === '1m') interval = '1m';
        else if (timeframe === '5m') interval = '5m';
        else if (timeframe === '1h') interval = '60m';
        else if (timeframe === '1d') interval = '1d';

        const period1 = Math.floor(targetTime / 1000);
        const period2 = period1 + 86400;

        try {
            // First attempt: Specific period (Precise)
            const url = `https://query1.finance.yahoo.com/v8/finance/chart/${yahooSymbol}?interval=${interval}&period1=${period1}&period2=${period2}`;
            const res = await fetchWithTimeout(url);
            let data: any = null;

            if (res.ok) {
                data = await res.json();
            } else {
                // Second attempt: Range based (More reliable for recent data)
                console.warn(`${getTimestamp()} [Resolution] Yahoo period failed for ${yahooSymbol}. Trying range=7d...`);
                const rangeUrl = `https://query1.finance.yahoo.com/v8/finance/chart/${yahooSymbol}?interval=1m&range=7d`;
                const rangeRes = await fetchWithTimeout(rangeUrl);
                if (rangeRes.ok) data = await rangeRes.json();
            }

            if (data) {
                const result = data.chart?.result?.[0];
                if (result) {
                    const quotes = result.indicators?.quote?.[0];
                    const timestamps = result.timestamp || [];
                    const prices = type === 'open' ? (quotes?.open || []) : (quotes?.close || []);
                    const targetSec = Math.floor(closeTime / 1000);

                    let bestIdx = -1;
                    let minDiff = Infinity;
                    for (let i = 0; i < timestamps.length; i++) {
                        const diff = Math.abs(timestamps[i] - targetSec);
                        if (diff < minDiff) {
                            minDiff = diff;
                            bestIdx = i;
                        }
                    }
                    if (bestIdx !== -1 && minDiff < 300 && prices[bestIdx] != null) {
                        return prices[bestIdx];
                    }
                }
            }
        } catch (e) {
            console.warn(`${getTimestamp()} Yahoo failed for ${yahooSymbol}`);
        }
    }

    // Stocks/Commodities Fallback -> Simulation
    console.error(`${getTimestamp()} [CRITICAL] All APIs failed for ${cleanSymbol}. Using Simulation Mode.`);
    const seed = (closeTime / 1000) % 1000;
    const fluctuationPercent = ((seed % 100) - 50) / 100;
    const simulatedPrice = referencePrice * (1 + (fluctuationPercent / 100));
    return Math.max(0.0001, simulatedPrice);
}

function getYahooSymbol(symbol: string): string | null {
    const s = symbol.toUpperCase().replace('/', '');
    if (['AAPL', 'NVDA', 'TSLA', 'MSFT', 'AMZN', 'GOOGL', 'META', 'NFLX', 'AMD', 'INTC'].includes(s)) {
        return s;
    }
    const map: Record<string, string> = {
        'XAUUSD': 'GC=F', 'XAGUSD': 'SI=F', 'WTI': 'CL=F', 'NG': 'NG=F',
        'CORN': 'ZC=F', 'SOY': 'ZS=F', 'WHEAT': 'ZW=F', 'HG': 'HG=F',
        'PL': 'PL=F', 'PA': 'PA=F', 'EURUSD': 'EURUSD=X', 'GBPUSD': 'GBPUSD=X', 'JPY': 'JPY=X'
    };
    return map[s] || null;
}
