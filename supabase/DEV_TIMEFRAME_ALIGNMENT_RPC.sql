
-- ==============================================================================
-- 🔗 CHARTCLASH - TIMEFRAME ALIGNMENT RPCS (2026-02-16)
-- Ensures "Rounds" are bucketed into clean candle start times (e.g., 10:00:00)
-- ==============================================================================

-- 1. Helper Function: Align any timestamp to its candle start
CREATE OR REPLACE FUNCTION public.align_to_candle_start(
    p_ts TIMESTAMP WITH TIME ZONE,
    p_timeframe TEXT
)
RETURNS TIMESTAMP WITH TIME ZONE
LANGUAGE plpgsql
IMMUTABLE
AS $$
DECLARE
    v_minutes INTEGER;
    v_hours INTEGER;
BEGIN
    CASE 
        WHEN p_timeframe = '15m' THEN
            RETURN date_trunc('hour', p_ts) + (floor(extract(minute from p_ts) / 15) * 15 * interval '1 minute');
        WHEN p_timeframe = '30m' THEN
            RETURN date_trunc('hour', p_ts) + (floor(extract(minute from p_ts) / 30) * 30 * interval '1 minute');
        WHEN p_timeframe = '1h' THEN
            RETURN date_trunc('hour', p_ts);
        WHEN p_timeframe = '4h' THEN
            RETURN date_trunc('hour', p_ts) - (extract(hour from p_ts)::int % 4 * interval '1 hour');
        WHEN p_timeframe = '1d' THEN
            RETURN date_trunc('day', p_ts);
        ELSE
            -- Default to minute truncation if not specified
            RETURN date_trunc('minute', p_ts);
    END CASE;
END;
$$;

-- 2. Updated Round Fetching: Group by Aligned Times
DROP FUNCTION IF EXISTS public.get_analyst_rounds(text, text, text);
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
        align_to_candle_start(created_at, p_timeframe) as aligned_round_time,
        count(*)::bigint as post_count
    FROM public.predictions
    WHERE asset_symbol = p_asset_symbol
      AND timeframe = p_timeframe
      AND channel = p_channel
    GROUP BY 1
    ORDER BY 1 DESC;
END;
$$ LANGUAGE plpgsql;

-- 3. Updated Insight Fetching: Search within the Round's Candle Window
DROP FUNCTION IF EXISTS public.get_ranked_insights_v2(text, text, timestamp with time zone, text, integer, boolean, text);
CREATE OR REPLACE FUNCTION public.get_ranked_insights_v2(
    p_asset_symbol TEXT DEFAULT NULL,
    p_timeframe TEXT DEFAULT NULL,
    p_round_time TIMESTAMP WITH TIME ZONE DEFAULT NULL,
    p_sort_by TEXT DEFAULT 'TOP',
    p_limit INTEGER DEFAULT 50,
    p_is_opinion BOOLEAN DEFAULT NULL,
    p_channel TEXT DEFAULT 'main'
)
RETURNS TABLE (
    id BIGINT,
    user_id UUID,
    username TEXT,
    tier TEXT,
    user_win_rate NUMERIC,
    asset_symbol TEXT,
    direction TEXT,
    target_percent NUMERIC,
    comment TEXT,
    status TEXT,
    likes_count BIGINT,
    insight_score NUMERIC,
    created_at TIMESTAMP WITH TIME ZONE,
    timeframe TEXT,
    entry_price NUMERIC
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        p.id,
        p.user_id,
        pr.username,
        pr.tier,
        CASE 
            WHEN pr.total_games > 0 THEN ROUND((pr.total_wins::numeric / pr.total_games::numeric) * 100, 1) 
            ELSE 0 
        END as user_win_rate,
        p.asset_symbol,
        p.direction,
        p.target_percent,
        p.comment,
        p.status,
        COALESCE(p.likes_count, 0)::BIGINT as likes_count,
        (p.target_percent * 10) as insight_score, -- Simplified score for now
        p.created_at,
        p.timeframe,
        p.entry_price
    FROM public.predictions p
    JOIN public.profiles pr ON p.user_id = pr.id
    WHERE (p_asset_symbol IS NULL OR p.asset_symbol = p_asset_symbol)
      AND (p_timeframe IS NULL OR p.timeframe = p_timeframe)
      AND (p_is_opinion IS NULL OR p.is_opinion = p_is_opinion)
      AND p.channel = p_channel
      -- [POINT] Bucket the posts made slightly after the start into the same round
      AND (p_round_time IS NULL OR align_to_candle_start(p.created_at, p.timeframe) = p_round_time)
    ORDER BY 
        CASE WHEN p_sort_by = 'NEW' THEN p.created_at END DESC,
        CASE WHEN p_sort_by = 'TOP' THEN (p.target_percent) END DESC
    LIMIT p_limit;
END;
$$ LANGUAGE plpgsql;
