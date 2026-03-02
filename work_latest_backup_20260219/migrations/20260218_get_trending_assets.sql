-- Create RPC to get trending assets based on pending prediction volume
-- Default limit increased to 100 to ensure we can find top assets for EACH category (Crypto, Stocks, Commodities)
CREATE OR REPLACE FUNCTION get_trending_assets(limit_count int)
RETURNS TABLE (
  symbol text,
  asset_type text,
  timeframe text,
  prediction_count bigint,
  total_volume bigint
) 
LANGUAGE plpgsql
AS $$
BEGIN
  RETURN QUERY
  SELECT 
    p.asset_symbol as symbol,
    MAX(p.asset_type) as asset_type, -- Mocking asset_type from predictions table structure if needed, or joining with assets table. Assuming consistent type per symbol.
    p.timeframe,
    COUNT(*) as prediction_count,
    COALESCE(SUM(p.bet_amount), 0) as total_volume
  FROM predictions p
  WHERE p.status = 'pending'
  GROUP BY p.asset_symbol, p.timeframe
  ORDER BY total_volume DESC, prediction_count DESC
  LIMIT limit_count;
END;
$$;
