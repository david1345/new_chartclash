export interface GuestPrediction {
    id: string;
    asset_symbol: string;
    timeframe: string;
    direction: "UP" | "DOWN";
    target_percent: number;
    entry_price: number;
    bet_amount: number;
    created_at: string;
    candle_close_at: string;
    status: "pending" | "WIN" | "LOSS" | "ND";
    actual_price?: number;
    profit?: number;
    resolved_at?: string;
    is_guest: boolean;
}
