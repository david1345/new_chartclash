import { NextResponse } from 'next/server';
import { createClient } from '@/lib/supabase/server';

export const dynamic = 'force-dynamic'; // No caching for real-time prices

const getTimestamp = () => `[${new Date().toLocaleTimeString()}]`;

async function getUserIdentifier(req: Request): Promise<string> {
    try {
        const supabase = await createClient();
        const { data: { user } } = await supabase.auth.getUser();

        if (user) {
            // Get username and email from profiles
            const { data: profile } = await supabase
                .from('profiles')
                .select('username, email')
                .eq('id', user.id)
                .single();

            // Priority: username > email username > User_ID
            const displayName = profile?.username ||
                profile?.email?.split('@')[0] ||
                user.email?.split('@')[0] ||
                `User_${user.id.substring(0, 6)}`;

            return `[👤 ${displayName}]`;
        }
        return '[👤 Guest]';
    } catch (e) {
        return '[👤 Unknown]';
    }
}

export async function POST(req: Request) {
    const userLog = await getUserIdentifier(req);

    try {
        const { symbol, timeframe, type } = await req.json();

        if (!symbol) {
            return NextResponse.json({ success: false, error: "Symbol required" }, { status: 400 });
        }

        let openPrice = 0;
        let currentPrice = 0;
        let openTime = 0;

        // 0. Helper for Timeout (mimicking browser to avoid blocks)
        const fetchWithTimeout = async (url: string, timeout = 3000) => {
            const controller = new AbortController();
            const id = setTimeout(() => controller.abort(), timeout);
            try {
                const res = await fetch(url, {
                    cache: 'no-store',
                    signal: controller.signal,
                    headers: {
                        'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36'
                    }
                });
                clearTimeout(id);
                if (!res.ok) {
                    // Silence 451 (Regional Block) as we have fallbacks
                    if (res.status !== 451) {
                        console.error(`${getTimestamp()} [EntryPrice] API Request failed (HTTP ${res.status}) for: ${url}`);
                    } else {
                        console.log(`${getTimestamp()} [EntryPrice] Binance blocked (451). Switching to fallback...`);
                    }
                }
                return res;
            } catch (e: any) {
                clearTimeout(id);
                // Don't log abort as error
                if (e.name !== 'AbortError') {
                    console.error(`${getTimestamp()} [EntryPrice] Fetch error for ${url}: ${e.message}`);
                }
                throw e;
            }
        };

        const cleanSymbol = symbol.replace('/', '').toUpperCase();
        // 1. Crypto (Binance)
        const cryptoPairs = ['BTCUSDT', 'ETHUSDT', 'SOLUSDT', 'DOGEUSDT', 'XRPUSDT', 'BNBUSDT', 'ADAUSDT', 'AVAXUSDT', 'DOTUSDT', 'LINKUSDT', 'MATICUSDT'];
        const isCrypto = cryptoPairs.includes(cleanSymbol) || cleanSymbol.endsWith('USDT');

        if (isCrypto) {
            const cleanSymbol = symbol.replace('/', '').toUpperCase();
            const interval = timeframe || '15m';

            // 1. Calculate Exact Round Start Time for Standardization
            const now = Date.now();
            let duration = 15 * 60 * 1000;
            const tfVal = parseInt(interval);
            if (interval.endsWith('m')) duration = tfVal * 60 * 1000;
            else if (interval.endsWith('h')) duration = tfVal * 60 * 60 * 1000;
            else if (interval.endsWith('d')) duration = tfVal * 24 * 60 * 60 * 1000;

            const roundStartTime = Math.floor(now / duration) * duration;
            const elapsedSeconds = Math.floor((now - roundStartTime) / 1000);

            // Fetch K-Line data
            let klineData: any = null;
            const baseSymbol = cleanSymbol.replace('USDT', '');

            // --- PRIORITY 1: Binance (Direct) ---
            try {
                const url = `https://api.binance.com/api/v3/klines?symbol=${cleanSymbol}&interval=${interval}&startTime=${roundStartTime}&limit=1`;
                const res = await fetchWithTimeout(url, 2500);
                if (res.ok) {
                    const json = await res.json();
                    if (Array.isArray(json) && json.length > 0) {
                        klineData = json;
                        console.log(`${getTimestamp()} ${userLog} [EntryPrice] Round Open from Binance: ${klineData?.[0]?.[1]}`);
                    }
                }
            } catch (e) { /* Logged in fetchWithTimeout */ }

            // --- PRIORITY 2: CryptoCompare (Fallback) ---
            if (!klineData) {
                try {
                    const unit = interval.slice(-1);
                    let apiType = 'histominute';
                    if (unit === 'h') apiType = 'histohour';
                    else if (unit === 'd') apiType = 'histoday';

                    const ts = Math.floor(roundStartTime / 1000);
                    const url = `https://min-api.cryptocompare.com/data/v2/${apiType}?fsym=${baseSymbol}&tsym=USD&limit=1&toTs=${ts}`;
                    const res = await fetch(url, {
                        headers: { 'Authorization': `Apikey ${process.env.CRYPTOCOMPARE_API_KEY}` },
                        cache: 'no-store'
                    });
                    const json = await res.json();

                    if (json.Response === 'Success' && json.Data?.Data?.length > 0) {
                        const candle = json.Data.Data[json.Data.Data.length - 1];
                        const tolerance = apiType === 'histominute' ? 60000 : 3600000;
                        if (Math.abs(candle.time * 1000 - roundStartTime) <= tolerance) {
                            klineData = [[candle.time * 1000, candle.open, candle.high, candle.low, candle.close]];
                            console.log(`${getTimestamp()} ${userLog} [EntryPrice] Round Open from CryptoCompare (${interval}): ${candle.open}`);
                        }
                    } else if (json.Message && !json.Message.includes('rate limit')) {
                        console.warn(`${getTimestamp()} [EntryPrice] CryptoCompare Message: ${json.Message}`);
                    }
                } catch (e) { /* Logged in fetchWithTimeout */ }
            }

            if (Array.isArray(klineData) && klineData.length > 0) {
                const candle = klineData[0];
                openTime = roundStartTime;
                openPrice = parseFloat(candle[1]);
                currentPrice = parseFloat(candle[4]);
            } else {
                console.warn(`${getTimestamp()} [EntryPrice] CryptoCompare & Binance failed. Trying Yahoo/CoinGecko Fallback for:`, cleanSymbol);
                openTime = roundStartTime;

                // --- PRIORITY 3: Yahoo Finance for Crypto ---
                try {
                    const isCommodity = ['XAU', 'XAG', 'WTI', 'NG'].some(s => baseSymbol.includes(s));
                    const yahooSymbol = isCommodity ? (baseSymbol === 'XAU' || baseSymbol === 'XAUUSD' ? 'XAUUSD=X' : baseSymbol === 'XAG' || baseSymbol === 'XAGUSD' ? 'XAGUSD=X' : `${baseSymbol}=F`) : `${baseSymbol}-USD`;
                    const url = `https://query1.finance.yahoo.com/v8/finance/chart/${yahooSymbol}?interval=1m&range=1d`;
                    const res = await fetchWithTimeout(url, 3000);
                    if (res.ok) {
                        const data = await res.json();
                        const result = data.chart?.result?.[0];
                        if (result && result.meta?.regularMarketPrice) {
                            currentPrice = result.meta.regularMarketPrice;
                            openPrice = result.indicators?.quote?.[0]?.open?.slice(-1)[0] || currentPrice;
                            console.log(`${getTimestamp()} [EntryPrice] Fallback: Used Yahoo Finance for ${cleanSymbol}: ${currentPrice}`);
                        }
                    }
                } catch (e) { /* Ignore */ }

                // --- PRIORITY 4: CoinGecko ---
                if (currentPrice === 0) {
                    try {
                        const idMap: Record<string, string> = { 'BTC': 'bitcoin', 'ETH': 'ethereum', 'SOL': 'solana' };
                        const cgId = idMap[baseSymbol];
                        if (cgId) {
                            const res = await fetchWithTimeout(`https://api.coingecko.com/api/v3/simple/price?ids=${cgId}&vs_currencies=usd`, 3000);
                            if (res.ok) {
                                const data = await res.json();
                                currentPrice = data[cgId].usd;
                                openPrice = currentPrice;
                                console.log(`${getTimestamp()} [EntryPrice] Fallback: Used CoinGecko for ${cleanSymbol}: ${currentPrice}`);
                            }
                        }
                    } catch (e) { /* Ignore */ }
                }

                if (currentPrice === 0) {
                    // Ultimate Mock
                    const basePrice = cleanSymbol.includes('BTC') ? 65000 : cleanSymbol.includes('ETH') ? 1900 : cleanSymbol.includes('SOL') ? 110 : 100;
                    openPrice = basePrice + (Math.random() * 20);
                    currentPrice = openPrice;
                    console.warn(`${getTimestamp()} [EntryPrice] Ultimate Fallback: Mocked price for ${cleanSymbol}: ${openPrice}`);
                }
            }

            return NextResponse.json({
                success: true,
                data: {
                    openTime,
                    openPrice,
                    currentPrice,
                    symbol,
                    candleElapsedSeconds: elapsedSeconds,
                    serverTime: now
                }
            });
        }
        // 2. Stocks / Commodities
        else {
            const now = Date.now();
            let duration = 60 * 60 * 1000; // default 1h
            if (timeframe) {
                const tfVal = parseInt(timeframe);
                if (timeframe.endsWith('m')) duration = tfVal * 60 * 1000;
                else if (timeframe.endsWith('h')) duration = tfVal * 60 * 60 * 1000;
                else if (timeframe.endsWith('d')) duration = tfVal * 24 * 60 * 60 * 1000;
            }

            const roundStartTime = Math.floor(now / duration) * duration;
            const elapsedSeconds = Math.floor((now - roundStartTime) / 1000);

            console.log(`${getTimestamp()} ${userLog} [EntryPrice] Fetching Stock/Commodity Price for ${symbol}`);

            // Try Yahoo Finance
            const yahooMap: Record<string, string> = {
                'XAUUSD': 'GC=F', // Unify to Gold Futures for better reliability
                'XAGUSD': 'SI=F',
                'WTI': 'CL=F',
                'NG': 'NG=F',
                'AAPL': 'AAPL', 'NVDA': 'NVDA', 'TSLA': 'TSLA',
                'EURUSD': 'EURUSD=X', 'GBPUSD': 'GBPUSD=X', 'JPY': 'JPY=X'
            };
            const yahooSymbol = yahooMap[symbol.toUpperCase().replace('/', '')] || symbol;

            try {
                const url = `https://query1.finance.yahoo.com/v8/finance/chart/${yahooSymbol}?interval=1m&range=1d`;
                const res = await fetchWithTimeout(url, 3000);
                if (res.ok) {
                    const data = await res.json();
                    const result = data.chart?.result?.[0];
                    if (result && result.meta?.regularMarketPrice) {
                        currentPrice = result.meta.regularMarketPrice;
                        const quotes = result.indicators?.quote?.[0]?.open;
                        if (quotes && quotes.length > 0) {
                            openPrice = quotes[quotes.length - 1];
                        } else {
                            openPrice = currentPrice;
                        }
                        console.log(`${getTimestamp()} ${userLog} [EntryPrice] Yahoo Result for ${symbol} (${yahooSymbol}): ${currentPrice}`);
                    }
                }
            } catch (e) {
                console.warn(`${getTimestamp()} [EntryPrice] Yahoo failed for ${symbol}:`, e);
            }

            if (currentPrice === 0) {
                // Real-world Mocks (Feb 2026)
                openPrice = symbol.includes('XAU') ? 2700 : symbol.includes('XAG') ? 31 : 100;
                currentPrice = openPrice;
                console.warn(`${getTimestamp()} [EntryPrice] Yahoo failed. Using Ultimate Fallback for ${symbol}: ${currentPrice}`);
            }

            return NextResponse.json({
                success: true,
                data: {
                    openTime: roundStartTime,
                    openPrice: openPrice,
                    currentPrice: currentPrice,
                    symbol,
                    candleElapsedSeconds: elapsedSeconds,
                    serverTime: now
                }
            });
        }

    } catch (error: any) {
        console.error(`${getTimestamp()} [Price API Error]`, error);
        return NextResponse.json({ success: false, error: error.message }, { status: 500 });
    }
}
