export type AssetType = 'CRYPTO' | 'STOCK' | 'COMMODITY';

export interface TradingHours {
    is24x7: boolean;
    timezone: string; // e.g. 'America/New_York'
    open?: string; // '09:30' (HH:MM in local time)
    close?: string; // '16:00'
    tradingDays?: number[]; // [1, 2, 3, 4, 5] (Mon=1, Sun=0)
}

export interface Asset {
    symbol: string;
    name: string;
    type: AssetType;
    tvSymbol: string;
    tradingHours: TradingHours;
}

// Default Hours
const CRYPTO_HOURS: TradingHours = { is24x7: true, timezone: 'UTC' };
const STOCK_HOURS: TradingHours = { is24x7: false, timezone: 'America/New_York', open: '09:30', close: '16:00', tradingDays: [1, 2, 3, 4, 5] };
// Commodities typically trade Sunday evening to Friday afternoon. Simplified here as roughly 23h/5d but lets stick to simpler 'is24x7: false' for simplicity for now.
const COMMODITY_HOURS: TradingHours = { is24x7: false, timezone: 'America/New_York', open: '18:00', close: '17:00', tradingDays: [1, 2, 3, 4, 5] }; // Very simplified

export const ASSETS: { [key: string]: Asset[] } = {
    CRYPTO: [
        { symbol: 'BTCUSDT', name: 'Bitcoin', type: 'CRYPTO', tvSymbol: 'BINANCE:BTCUSDT', tradingHours: CRYPTO_HOURS },
        { symbol: 'ETHUSDT', name: 'Ethereum', type: 'CRYPTO', tvSymbol: 'BINANCE:ETHUSDT', tradingHours: CRYPTO_HOURS },
        { symbol: 'SOLUSDT', name: 'Solana', type: 'CRYPTO', tvSymbol: 'BINANCE:SOLUSDT', tradingHours: CRYPTO_HOURS },
        { symbol: 'XRPUSDT', name: 'Ripple', type: 'CRYPTO', tvSymbol: 'BINANCE:XRPUSDT', tradingHours: CRYPTO_HOURS },
        { symbol: 'DOGEUSDT', name: 'Dogecoin', type: 'CRYPTO', tvSymbol: 'BINANCE:DOGEUSDT', tradingHours: CRYPTO_HOURS },
        { symbol: 'ADAUSDT', name: 'Cardano', type: 'CRYPTO', tvSymbol: 'BINANCE:ADAUSDT', tradingHours: CRYPTO_HOURS },
        { symbol: 'AVAXUSDT', name: 'Avalanche', type: 'CRYPTO', tvSymbol: 'BINANCE:AVAXUSDT', tradingHours: CRYPTO_HOURS },
        { symbol: 'DOTUSDT', name: 'Polkadot', type: 'CRYPTO', tvSymbol: 'BINANCE:DOTUSDT', tradingHours: CRYPTO_HOURS },
        { symbol: 'LINKUSDT', name: 'Chainlink', type: 'CRYPTO', tvSymbol: 'BINANCE:LINKUSDT', tradingHours: CRYPTO_HOURS },
        { symbol: 'MATICUSDT', name: 'Polygon', type: 'CRYPTO', tvSymbol: 'BINANCE:MATICUSDT', tradingHours: CRYPTO_HOURS },
    ],
    STOCKS: [
        { symbol: 'AAPL', name: 'Apple', type: 'STOCK', tvSymbol: 'NASDAQ:AAPL', tradingHours: STOCK_HOURS },
        { symbol: 'NVDA', name: 'Nvidia', type: 'STOCK', tvSymbol: 'NASDAQ:NVDA', tradingHours: STOCK_HOURS },
        { symbol: 'TSLA', name: 'Tesla', type: 'STOCK', tvSymbol: 'NASDAQ:TSLA', tradingHours: STOCK_HOURS },
        { symbol: 'MSFT', name: 'Microsoft', type: 'STOCK', tvSymbol: 'NASDAQ:MSFT', tradingHours: STOCK_HOURS },
        { symbol: 'AMZN', name: 'Amazon', type: 'STOCK', tvSymbol: 'NASDAQ:AMZN', tradingHours: STOCK_HOURS },
        { symbol: 'GOOGL', name: 'Google', type: 'STOCK', tvSymbol: 'NASDAQ:GOOGL', tradingHours: STOCK_HOURS },
        { symbol: 'META', name: 'Meta', type: 'STOCK', tvSymbol: 'NASDAQ:META', tradingHours: STOCK_HOURS },
        { symbol: 'NFLX', name: 'Netflix', type: 'STOCK', tvSymbol: 'NASDAQ:NFLX', tradingHours: STOCK_HOURS },
        { symbol: 'AMD', name: 'AMD', type: 'STOCK', tvSymbol: 'NASDAQ:AMD', tradingHours: STOCK_HOURS },
        { symbol: 'INTC', name: 'Intel', type: 'STOCK', tvSymbol: 'NASDAQ:INTC', tradingHours: STOCK_HOURS },
    ],
    COMMODITIES: [
        { symbol: 'XAUUSD', name: 'Gold', type: 'COMMODITY', tvSymbol: 'OANDA:XAUUSD', tradingHours: COMMODITY_HOURS },
        { symbol: 'XAGUSD', name: 'Silver', type: 'COMMODITY', tvSymbol: 'OANDA:XAGUSD', tradingHours: COMMODITY_HOURS },
        { symbol: 'WTI', name: 'Crude Oil', type: 'COMMODITY', tvSymbol: 'TVC:USOIL', tradingHours: COMMODITY_HOURS },
        { symbol: 'NG', name: 'Natural Gas', type: 'COMMODITY', tvSymbol: 'TVC:NATGAS', tradingHours: COMMODITY_HOURS },
        { symbol: 'CORN', name: 'Corn', type: 'COMMODITY', tvSymbol: 'TVC:CORN', tradingHours: COMMODITY_HOURS },
        { symbol: 'SOY', name: 'Soybeans', type: 'COMMODITY', tvSymbol: 'TVC:SOYBEAN', tradingHours: COMMODITY_HOURS },
        { symbol: 'WHEAT', name: 'Wheat', type: 'COMMODITY', tvSymbol: 'TVC:WHEAT', tradingHours: COMMODITY_HOURS },
        { symbol: 'HG', name: 'Copper', type: 'COMMODITY', tvSymbol: 'TVC:COPPER', tradingHours: COMMODITY_HOURS },
        { symbol: 'PL', name: 'Platinum', type: 'COMMODITY', tvSymbol: 'TVC:PLATINUM', tradingHours: COMMODITY_HOURS },
        { symbol: 'PA', name: 'Palladium', type: 'COMMODITY', tvSymbol: 'TVC:PALLADIUM', tradingHours: COMMODITY_HOURS },
    ]
};

export const TIMEFRAMES = ['15m', '30m', '1h', '4h', '1d'];

/**
 * Checks if the asset is currently tradable.
 * @param asset The asset object
 * @returns boolean
 */
export function isMarketOpen(asset: Asset): boolean {
    if (asset.tradingHours.is24x7) return true;

    const hourInfo = asset.tradingHours;
    if (!hourInfo.open || !hourInfo.close || !hourInfo.tradingDays) return true; // Fail safe

    // Get current time in target timezone
    const now = new Date();
    // Simplified checks to avoid complexity for now, reverting to original simple logic
    const day = now.getUTCDay(); // This is rough but matches original
    // The previous logic was known to be imperfect but we are reverting to "before changes".

    // Actually, I should restore the exact function that was there before.
    // Based on my view history in step 1721:

    const localTimeStr = now.toLocaleTimeString('en-US', { timeZone: hourInfo.timezone, hour12: false, hour: '2-digit', minute: '2-digit' });
    // ... logic was partially there but I am overwriting the whole file.
    // I will write a simple safe version or try to replicate what was there.
    // In step 1721, the file ended at line 108.

    // I will paste the content from step 1721 exactly.
    // Wait, step 1721 showed the content BEFORE my edits in step 1728.
    // Perfect. I will use the content from Step 1721.

    const options = { timeZone: hourInfo.timezone, weekday: 'short', hour12: false, hour: '2-digit', minute: '2-digit' } as const;
    const parts = new Intl.DateTimeFormat('en-US', options).formatToParts(now);

    const dayMap: { [key: string]: number } = { 'Sun': 0, 'Mon': 1, 'Tue': 2, 'Wed': 3, 'Thu': 4, 'Fri': 5, 'Sat': 6 };
    const currentDayPart = parts.find(p => p.type === 'weekday')?.value;
    const currentDay = currentDayPart ? dayMap[currentDayPart] : -1;

    if (!hourInfo.tradingDays.includes(currentDay)) return false;

    const currentHour = parts.find(p => p.type === 'hour')?.value || "00";
    const currentMinute = parts.find(p => p.type === 'minute')?.value || "00";
    const currentTimeStr = `${currentHour}:${currentMinute}`;

    return currentTimeStr >= hourInfo.open && currentTimeStr < hourInfo.close;
}
