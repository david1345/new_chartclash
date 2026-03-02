-- [RPC] Updated get_ranked_insights with Round (Timestamp) support
-- Allows filtering by asset, timeframe, and a specific time round.

CREATE OR REPLACE FUNCTION public.get_ranked_insights_v2(
  p_asset_symbol TEXT DEFAULT NULL,
  p_timeframe TEXT DEFAULT NULL,
  p_round_time TIMESTAMP WITH TIME ZONE DEFAULT NULL,
  p_sort_by TEXT DEFAULT 'TOP',
  p_limit INTEGER DEFAULT 20,
  p_is_opinion BOOLEAN DEFAULT TRUE,
  p_channel TEXT DEFAULT 'main'
)
RETURNS TABLE (
  id BIGINT, user_id UUID, username TEXT, tier TEXT, user_win_rate NUMERIC,
  user_total_games INTEGER, asset_symbol TEXT, timeframe TEXT, direction TEXT,
  target_percent NUMERIC, entry_price NUMERIC, status TEXT, profit INTEGER,
  created_at TIMESTAMP WITH TIME ZONE, resolved_at TIMESTAMP WITH TIME ZONE,
  comment TEXT, likes_count INTEGER, insight_score NUMERIC, is_opinion BOOLEAN
) AS $$
BEGIN
  RETURN QUERY
  SELECT * FROM (
    SELECT
      p.id, p.user_id, prof.username, prof.tier,
      CASE WHEN prof.total_games > 0 THEN ROUND((prof.total_wins::numeric / prof.total_games::numeric) * 100, 1) ELSE 0 END as win_rate,
      prof.total_games, p.asset_symbol, p.timeframe, p.direction, p.target_percent, p.entry_price, p.status, p.profit,
      p.created_at, p.resolved_at, p.comment, COALESCE(p.likes_count, 0) as likes,
      (
        (CASE WHEN p.status = 'WIN' THEN 40 ELSE 0 END) + (p.target_percent * 15) + (COALESCE(p.likes_count, 0) * 2) + 20
      )::numeric as score,
      p.is_opinion
    FROM public.predictions p
    JOIN public.profiles prof ON p.user_id = prof.id
    WHERE (p_asset_symbol IS NULL OR p.asset_symbol = p_asset_symbol) 
      AND (p_timeframe IS NULL OR p.timeframe = p_timeframe) 
      AND (p_round_time IS NULL OR date_trunc('minute', p.created_at) = date_trunc('minute', p_round_time)) -- Group by minute
      AND (p.comment IS NOT NULL AND length(p.comment) > 0) 
      AND (p.is_opinion = p_is_opinion)
      AND (p.channel = p_channel)
  ) sub
  ORDER BY
    CASE WHEN p_sort_by = 'TOP' THEN sub.score END DESC,
    sub.created_at DESC
  LIMIT p_limit;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER STABLE;

-- Ensure execute permission
GRANT EXECUTE ON FUNCTION public.get_ranked_insights_v2 TO anon, authenticated, service_role;
