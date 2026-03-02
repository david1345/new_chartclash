-- Check pending bets and their readiness for resolution
SELECT 
    id, 
    asset_symbol, 
    timeframe, 
    status, 
    created_at, 
    candle_close_at,
    NOW() as server_time,
    EXTRACT(EPOCH FROM (candle_close_at - NOW())) as seconds_until_close
FROM predictions
WHERE status = 'pending'
ORDER BY candle_close_at ASC;
