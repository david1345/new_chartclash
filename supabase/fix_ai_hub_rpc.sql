-- ==========================================================
-- AI HUB BUGFIXES: Fix ambiguous column & Comment length
-- ==========================================================

-- 1. Fix ambiguous column in get_analyst_rounds and use proper round_time for grouping
CREATE OR REPLACE FUNCTION public.get_analyst_rounds(p_asset_symbol TEXT, p_timeframe TEXT, p_channel TEXT DEFAULT 'analyst_hub')
RETURNS TABLE (round_time TIMESTAMP WITH TIME ZONE, post_count BIGINT) AS $$
BEGIN
  RETURN QUERY
  SELECT p.round_time as rt, COUNT(*) as pc
  FROM public.predictions p
  WHERE p.asset_symbol = p_asset_symbol AND p.timeframe = p_timeframe AND p.channel = p_channel AND p.is_opinion = TRUE
  GROUP BY p.round_time ORDER BY p.round_time DESC LIMIT 50;
END;
$$ LANGUAGE plpgsql STABLE SECURITY DEFINER;

-- 2. Expand comment length to allow detailed AI generated analysis
ALTER TABLE public.predictions DROP CONSTRAINT IF EXISTS check_comment_length;
ALTER TABLE public.predictions DROP CONSTRAINT IF EXISTS predictions_comment_check;
ALTER TABLE public.predictions ADD CONSTRAINT check_comment_length CHECK (char_length(comment) <= 2000);

-- 3. Fix get_ranked_insights_v2 to query by round_time instead of created_at
CREATE OR REPLACE FUNCTION public.get_ranked_insights_v2(
    p_asset_symbol TEXT,
    p_timeframe TEXT,
    p_round_time TIMESTAMP WITH TIME ZONE DEFAULT NULL,
    p_channel TEXT DEFAULT 'analyst_hub',
    p_limit INTEGER DEFAULT 10,
    p_is_opinion BOOLEAN DEFAULT TRUE,
    p_theme TEXT DEFAULT NULL
)
RETURNS TABLE (
    id BIGINT,
    user_id UUID,
    asset_symbol TEXT,
    timeframe TEXT,
    direction TEXT,
    target_percent NUMERIC,
    entry_price NUMERIC,
    status TEXT,
    bet_amount INTEGER,
    channel TEXT,
    is_opinion BOOLEAN,
    comment TEXT,
    created_at TIMESTAMP WITH TIME ZONE,
    candle_close_at TIMESTAMP WITH TIME ZONE,
    round_time TIMESTAMP WITH TIME ZONE,
    theme TEXT,
    username TEXT,
    avatar_url TEXT,
    win_rate NUMERIC,
    total_yield NUMERIC,
    total_games INTEGER,
    rank_score NUMERIC
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        p.id,
        p.user_id,
        p.asset_symbol,
        p.timeframe,
        p.direction,
        p.target_percent,
        p.entry_price,
        p.status,
        p.bet_amount,
        p.channel,
        p.is_opinion,
        p.comment,
        p.created_at,
        p.candle_close_at,
        p.round_time,
        p.theme,
        pr.username,
        pr.avatar_url,
        pr.win_rate,
        pr.total_yield,
        pr.total_games,
        -- Simple scoring algorithm: (win_rate * 0.5) + (total_games * 0.1)
        (COALESCE(pr.win_rate, 0) * 0.5 + COALESCE(pr.total_games, 0) * 0.1) AS rank_score
    FROM 
        public.predictions p
    LEFT JOIN 
        public.profiles pr ON p.user_id = pr.id
    WHERE 
        p.asset_symbol = p_asset_symbol
        AND p.timeframe = p_timeframe
        AND p.channel = p_channel
        AND p.is_opinion = p_is_opinion
        -- Use exact round_time matching if provided, else fetch latest
        AND (p_round_time IS NULL OR date_trunc('minute', p.round_time) = date_trunc('minute', p_round_time))
        AND (p_theme IS NULL OR p.theme = p_theme)
    ORDER BY 
        rank_score DESC,
        p.created_at DESC
    LIMIT p_limit;
END;
$$ LANGUAGE plpgsql STABLE SECURITY DEFINER;
