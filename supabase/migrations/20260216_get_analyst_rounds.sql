-- [RPC] Get Analyst Rounds
-- Returns distinct timestamps (rounded to minute) for groups of analyst insights.

CREATE OR REPLACE FUNCTION public.get_analyst_rounds(
  p_asset_symbol TEXT,
  p_timeframe TEXT,
  p_channel TEXT DEFAULT 'analyst_hub'
)
RETURNS TABLE (
  round_time TIMESTAMP WITH TIME ZONE,
  post_count BIGINT
) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    date_trunc('minute', created_at) as round_time,
    COUNT(*) as post_count
  FROM public.predictions
  WHERE asset_symbol = p_asset_symbol
    AND timeframe = p_timeframe
    AND channel = p_channel
    AND is_opinion = TRUE
  GROUP BY round_time
  ORDER BY round_time DESC
  LIMIT 50;
END;
$$ LANGUAGE plpgsql STABLE SECURITY DEFINER;
