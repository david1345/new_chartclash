-- RPC: Get Market Sentiment Aggregation
CREATE OR REPLACE FUNCTION public.get_market_sentiment(p_hours INTEGER DEFAULT 24)
RETURNS TABLE (
    asset_symbol TEXT,
    total_votes BIGINT,
    bullish_votes BIGINT,
    bearish_votes BIGINT,
    bull_percent NUMERIC,
    bear_percent NUMERIC,
    avg_target NUMERIC
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    RETURN QUERY
    SELECT 
        p.asset_symbol,
        COUNT(*) as total_votes,
        COUNT(*) FILTER (WHERE p.direction = 'UP') as bullish_votes,
        COUNT(*) FILTER (WHERE p.direction = 'DOWN') as bearish_votes,
        ROUND((COUNT(*) FILTER (WHERE p.direction = 'UP')::NUMERIC / NULLIF(COUNT(*), 0) * 100), 1) as bull_percent,
        ROUND((COUNT(*) FILTER (WHERE p.direction = 'DOWN')::NUMERIC / NULLIF(COUNT(*), 0) * 100), 1) as bear_percent,
        ROUND(AVG(p.target_percent), 2) as avg_target
    FROM predictions p
    WHERE p.created_at >= (now() - (p_hours || ' hours')::INTERVAL)
    GROUP BY p.asset_symbol
    ORDER BY total_votes DESC;
END;
$$;
