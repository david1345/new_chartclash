import { createClient } from '@supabase/supabase-js';
import { NextRequest, NextResponse } from 'next/server';
import {
    createRoundOnChain,
    getBetOnChain,
    getRoundOnChain,
    getWalletAddressFromTransaction,
    settleRoundOnChain
} from '@/lib/contract-server';
import { requireAdminOrCron } from '@/lib/server-access';

// 1. Setup Supabase Client (Service Role needed for RPC)
const supabase = createClient(
    process.env.NEXT_PUBLIC_SUPABASE_URL!,
    process.env.SUPABASE_SERVICE_ROLE_KEY! // Use Service Role Key for CRON
);

// Helper for rate limiting
const sleep = (ms: number) => new Promise((resolve) => setTimeout(resolve, ms));

const getTimestamp = () => `[${new Date().toLocaleTimeString()}]`;
const FEE_DENOM = 10_000;
const GREEN_FEE_BPS = 100;
const HOUSE_FEE_BPS = 300;

function getDurationMs(timeframe: string) {
    const tfVal = parseInt(timeframe, 10);
    if (timeframe.endsWith('m')) return tfVal * 60 * 1000;
    if (timeframe.endsWith('h')) return tfVal * 60 * 60 * 1000;
    if (timeframe.endsWith('d')) return tfVal * 24 * 60 * 60 * 1000;
    return 60 * 60 * 1000;
}

function parseTxHash(comment?: string | null) {
    if (!comment?.startsWith('tx:')) return null;
    const txHash = comment.slice(3).trim();
    return /^0x[a-fA-F0-9]{64}$/.test(txHash) ? txHash : null;
}

function getFallbackMirror(direction: 'UP' | 'DOWN', openPrice: number, closePrice: number, betAmount: number) {
    if (closePrice === openPrice) {
        return { status: 'ND', profit: 0 };
    }

    const isWin = direction === 'UP' ? closePrice > openPrice : closePrice < openPrice;
    return {
        status: isWin ? 'WIN' : 'LOSS',
        profit: isWin ? betAmount : -betAmount,
    };
}

function getOnChainMirror(params: {
    direction: 'UP' | 'DOWN';
    betAmount: number;
    round: {
        openPrice: number;
        closePrice: number;
        upPool: number;
        downPool: number;
        cancelled: boolean;
    };
    bet: {
        amount: number;
        zone: number;
    };
}) {
    const { direction, betAmount, round, bet } = params;

    if (round.cancelled || round.closePrice === round.openPrice || round.upPool === 0 || round.downPool === 0) {
        return { status: 'ND', profit: 0 };
    }

    const upWon = round.closePrice > round.openPrice;
    const didWin = direction === 'UP' ? upWon : !upWon;

    if (!didWin) {
        return { status: 'LOSS', profit: -betAmount };
    }

    const winPool = upWon ? round.upPool : round.downPool;
    const losePool = upWon ? round.downPool : round.upPool;
    const winnerLoseShare = (bet.amount * losePool) / winPool;
    const feeBps = bet.zone === 0 ? GREEN_FEE_BPS : HOUSE_FEE_BPS;
    const houseFee = (winnerLoseShare * feeBps) / FEE_DENOM;
    const payout = bet.amount + (winnerLoseShare - houseFee);

    return {
        status: 'WIN',
        profit: Math.round(payout - bet.amount),
    };
}

export async function GET(req: NextRequest) {
    const authError = await requireAdminOrCron(req);
    if (authError) return authError;

    try {
        const now = Date.now();

        // 2. Fetch Pending Predictions
        const { data: predictions, error: fetchError } = await supabase
            .from('predictions')
            .select('id, asset_symbol, timeframe, created_at, entry_price, direction, user_id, bet_amount, candle_close_at, comment')
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
            isReady: boolean;
            isUpcoming: boolean;
            preds: any[];
        }> = {};

        for (const pred of predictions) {
            const closeTime = new Date(pred.candle_close_at).getTime();
            const duration = getDurationMs(pred.timeframe);

            const openTime = closeTime - duration;
            const isReady = now > closeTime + 20000; // 20s buffer
            const isUpcoming = now < closeTime;     // Round still active

            console.log(`${getTimestamp()} [Debug] Pred ${pred.id}: closeTime=${new Date(closeTime).toISOString()}, now=${new Date(now).toISOString()}, isReady=${isReady}, diff=${now - closeTime}`);

            const key = `${pred.asset_symbol}-${pred.timeframe}-${openTime}`;
            if (!candleGroups[key]) {
                candleGroups[key] = {
                    symbol: pred.asset_symbol,
                    tf: pred.timeframe,
                    openTime,
                    closeTime,
                    isReady,
                    isUpcoming,
                    preds: []
                };
            }
            candleGroups[key].preds.push(pred);
        }

        const groupKeys = Object.keys(candleGroups);
        const results = {
            resolved: 0,
            created: 0,
            errors: 0,
            details: [] as any[]
        };

        if (groupKeys.length === 0) {
            console.log(`${getTimestamp()} [Resolution] Scan complete. 0 groups found.`);
            return NextResponse.json({ message: 'No candles to process' });
        }

        console.log(`${getTimestamp()} [Resolution] Processing ${groupKeys.length} candle groups...`);
        const txWalletCache: Record<string, string> = {};

        // 4. Process Each Group
        for (const key of groupKeys) {
            const group = candleGroups[key];
            let openPrice: number | null = null;
            let closePrice: number | null = null;

            console.log(`${getTimestamp()} [Resolution] Group ${key} -> State: isUpcoming=${group.isUpcoming}, isReady=${group.isReady}`);

            // Phase 1: Pre-creation (Upcoming Rounds)
            if (group.isUpcoming || group.isReady) {
                try {
                    const { data: existingRound } = await supabase
                        .from('rounds')
                        .select('on_chain_id, status')
                        .eq('asset', group.symbol)
                        .eq('timeframe', group.tf)
                        .eq('open_time', group.openTime)
                        .maybeSingle();

                    if (!existingRound?.on_chain_id) {
                        // Only create if closeTime is still in the future
                        if (group.closeTime > Date.now()) {
                            console.log(`${getTimestamp()} [OnChain] Pre-creating round for ${key}...`);
                            openPrice = await fetchPrice(group.symbol, group.tf, group.openTime, group.openTime, 0, 'open');
                            if (openPrice) {
                                const closeTimeSec = Math.floor(group.closeTime / 1000);
                                const onChainId = await createRoundOnChain(group.symbol, group.tf, openPrice, closeTimeSec);
                                await supabase.from('rounds').upsert({
                                    asset: group.symbol,
                                    timeframe: group.tf,
                                    open_time: group.openTime,
                                    close_time: group.closeTime,
                                    open_price: openPrice,
                                    on_chain_id: onChainId,
                                    status: 'open'
                                }, { onConflict: 'asset,timeframe,open_time' });
                                results.created++;
                                console.log(`${getTimestamp()} [OnChain] Round created: id=${onChainId}`);
                            }
                        }
                    }
                } catch (ce: any) {
                    console.error(`${getTimestamp()} [OnChain] Pre-creation failed for ${key}:`, ce.message);
                }
            }

            // Phase 2: Settlement (Closed Rounds)
            if (group.isReady) {
                await sleep(500);
                try {
                    // Fetch Prices
                    openPrice = await fetchPrice(group.symbol, group.tf, group.openTime, group.openTime, 0, 'open');
                    const closeTarget = group.tf === '1m' ? group.closeTime : group.closeTime - 60000;
                    closePrice = await fetchPrice(group.symbol, group.tf, closeTarget, group.closeTime, 0, 'close');

                    if (openPrice && closePrice) {
                        const { data: roundData } = await supabase
                            .from('rounds')
                            .select('on_chain_id, status')
                            .eq('asset', group.symbol)
                            .eq('timeframe', group.tf)
                            .eq('open_time', group.openTime)
                            .maybeSingle();

                        if (roundData?.on_chain_id && roundData.status !== 'settled') {
                            const settleTx = await settleRoundOnChain(roundData.on_chain_id, closePrice);
                            await supabase.from('rounds').update({
                                close_price: closePrice,
                                status: 'settled',
                                settle_tx: settleTx
                            }).eq('on_chain_id', roundData.on_chain_id);
                            console.log(`${getTimestamp()} [OnChain] Round ${roundData.on_chain_id} settled. tx=${settleTx}`);
                        }

                        let settledRound = null;
                        if (roundData?.on_chain_id) {
                            try {
                                settledRound = await getRoundOnChain(roundData.on_chain_id);
                            } catch (roundError: any) {
                                console.warn(`${getTimestamp()} [Mirror] Round fetch failed for ${roundData.on_chain_id}: ${roundError.message}`);
                            }
                        }

                        // Settlement in Supabase (mirror only, no off-chain balance payout)
                        for (const pred of group.preds) {
                            try {
                                const fallback = getFallbackMirror(
                                    pred.direction as 'UP' | 'DOWN',
                                    openPrice,
                                    closePrice,
                                    Number(pred.bet_amount)
                                );

                                let outcome = fallback;
                                const txHash = parseTxHash(pred.comment);

                                if (settledRound && roundData?.on_chain_id && txHash) {
                                    try {
                                        const walletAddress = txWalletCache[txHash] || await getWalletAddressFromTransaction(txHash);
                                        txWalletCache[txHash] = walletAddress;

                                        const bet = await getBetOnChain(roundData.on_chain_id, walletAddress);
                                        if (bet.amount > 0) {
                                            outcome = getOnChainMirror({
                                                direction: pred.direction as 'UP' | 'DOWN',
                                                betAmount: Number(pred.bet_amount),
                                                round: settledRound,
                                                bet,
                                            });
                                        }
                                    } catch (mirrorError: any) {
                                        console.warn(`${getTimestamp()} [Mirror] Falling back for prediction ${pred.id}: ${mirrorError.message}`);
                                    }
                                }

                                const { error: updateError } = await supabase
                                    .from('predictions')
                                    .update({
                                        status: outcome.status,
                                        actual_price: closePrice,
                                        profit: outcome.profit,
                                        resolved_at: new Date().toISOString(),
                                    })
                                    .eq('id', pred.id);

                                if (updateError) {
                                    throw updateError;
                                }

                                results.resolved++;
                                results.details.push({
                                    id: pred.id,
                                    status: outcome.status,
                                    open: openPrice,
                                    close: closePrice,
                                    profit: outcome.profit
                                });
                                console.log(`${getTimestamp()} Successfully resolved prediction ${pred.id}`);
                            } catch (predError: any) {
                                results.errors++;
                                results.details.push({ id: pred.id, status: 'error', error: predError.message });
                            }
                        }
                    } else {
                        throw new Error("Price fetch failed");
                    }
                } catch (se: any) {
                    console.error(`${getTimestamp()} [Resolution] Group ${key} failed:`, se.message);
                    for (const pred of group.preds) {
                        results.errors++;
                        results.details.push({ id: pred.id, status: 'error', error: se.message });
                    }
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

        // --- ALL APIS FAILED: Do NOT simulate. Leave predictions pending for next cycle. ---
        console.error(`${getTimestamp()} [CRITICAL] All APIs failed for ${cleanSymbol}. Prediction left pending for retry.`);
        throw new Error(`All price APIs failed for ${cleanSymbol}. Prediction left pending.`);
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

    // ALL APIS FAILED: Do NOT simulate. Throw so prediction stays pending for retry.
    console.error(`${getTimestamp()} [CRITICAL] All APIs failed for ${cleanSymbol}. Prediction left pending for retry.`);
    throw new Error(`All price APIs failed for ${cleanSymbol}. Prediction left pending.`);
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
