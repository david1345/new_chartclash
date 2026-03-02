-- Inspect all predictions for BTCUSDT 30m
SELECT id, user_id, asset_symbol, timeframe, status, created_at, entry_price 
FROM predictions 
WHERE asset_symbol = 'BTCUSDT' AND timeframe = '30m'
ORDER BY created_at DESC;
