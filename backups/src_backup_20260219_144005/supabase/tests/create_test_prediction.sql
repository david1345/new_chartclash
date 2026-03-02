-- Create a dummy pending prediction for testing
INSERT INTO predictions (
    user_id, asset_symbol, timeframe, direction, entry_price, 
    bet_amount, target_percent, status, created_at, candle_close_at
)
SELECT 
    id, 'TEST/USD', '1m', 'UP', 50000, 
    100, 1.0, 'pending', now(), now() - interval '1 minute'
FROM profiles 
LIMIT 1
RETURNING id;

-- Note: User needs to run this manually or I initiate resolution via API.
-- Actually, let's just create it and let the user trigger resolution via UI/API.
