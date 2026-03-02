-- Check recently resolved predictions
SELECT id, asset_symbol, timeframe, status, bet_amount, close_price, profit_loss, payout, resolved_at
FROM predictions
WHERE status = 'WIN'
ORDER BY resolved_at DESC
LIMIT 10;
