-- ==========================================
-- 🛠️ ALPHA SYSTEM FINAL FIX & SEPARATION
-- ==========================================

-- 1. Relax Bet Amount Constraint (Crucial for Alpha Posting)
ALTER TABLE public.predictions 
DROP CONSTRAINT IF EXISTS predictions_bet_amount_check;

ALTER TABLE public.predictions
ADD CONSTRAINT predictions_bet_amount_check 
CHECK (bet_amount >= 0 AND bet_amount <= 1000);

-- 2. Ensure likes_count and is_opinion columns exist
ALTER TABLE public.predictions 
ADD COLUMN IF NOT EXISTS likes_count INTEGER DEFAULT 0,
ADD COLUMN IF NOT EXISTS is_opinion BOOLEAN DEFAULT FALSE;

-- 3. Data Migration: Mark entries with comments as opinions if they have bet_amount = 0
UPDATE public.predictions SET is_opinion = TRUE 
WHERE comment IS NOT NULL AND length(comment) > 0 AND bet_amount = 0;

-- 4. Create Unified ranked insights RPC with Opinion filtering
DROP FUNCTION IF EXISTS public.get_ranked_insights(text, text, text, integer, integer);
DROP FUNCTION IF EXISTS public.get_ranked_insights(text, text, text, integer, integer, uuid);

CREATE OR REPLACE FUNCTION public.get_ranked_insights(
  p_asset_symbol TEXT DEFAULT NULL,
  p_timeframe TEXT DEFAULT NULL,
  p_sort_by TEXT DEFAULT 'TOP',
  p_limit INTEGER DEFAULT 20,
  p_offset INTEGER DEFAULT 0,
  p_is_opinion BOOLEAN DEFAULT TRUE  -- Default to Community mode
)
RETURNS TABLE (
  id BIGINT,
  user_id UUID,
  username TEXT,
  tier TEXT,
  user_win_rate NUMERIC,
  user_total_games INTEGER,
  asset_symbol TEXT,
  timeframe TEXT,
  direction TEXT,
  target_percent NUMERIC,
  entry_price NUMERIC,
  status TEXT,
  profit INTEGER,
  created_at TIMESTAMP WITH TIME ZONE,
  resolved_at TIMESTAMP WITH TIME ZONE,
  comment TEXT,
  likes_count INTEGER,
  insight_score NUMERIC,
  is_opinion BOOLEAN
) AS $$
BEGIN
  RETURN QUERY
  SELECT
    p.id,
    p.user_id,
    prof.username,
    prof.tier,
    CASE WHEN prof.total_games > 0 THEN 
      ROUND((prof.total_wins::numeric / prof.total_games::numeric) * 100, 1)
    ELSE 0 END as user_win_rate,
    prof.total_games as user_total_games,
    p.asset_symbol,
    p.timeframe,
    p.direction,
    p.target_percent,
    p.entry_price,
    p.status,
    p.profit,
    p.created_at,
    p.resolved_at,
    p.comment,
    p.likes_count,
    (
      (CASE WHEN p.status = 'WIN' THEN 40 ELSE 0 END) +
      (p.target_percent * 15) +
      (p.likes_count * 2) +
      (
        CASE WHEN prof.total_games > 0 THEN 
          (prof.total_wins::numeric / prof.total_games::numeric) * 100 * 0.2 
        ELSE 0 END
      ) -
      (EXTRACT(EPOCH FROM (NOW() - p.created_at)) / 3600 * 1.5)
    )::numeric as insight_score,
    p.is_opinion

  FROM predictions p
  JOIN profiles prof ON p.user_id = prof.id
  WHERE 
    (p_asset_symbol IS NULL OR p.asset_symbol = p_asset_symbol) AND
    (p_timeframe IS NULL OR p.timeframe = p_timeframe) AND
    (p.comment IS NOT NULL AND length(p.comment) > 0) AND
    (p.is_opinion = p_is_opinion) -- Filter by opinion status
    
  ORDER BY
    CASE WHEN p_sort_by = 'TOP' THEN 18 END DESC,
    CASE WHEN p_sort_by = 'NEW' THEN p.created_at END DESC,
    CASE WHEN p_sort_by = 'RISING' THEN (p.likes_count * 10 - (EXTRACT(EPOCH FROM (NOW() - p.created_at)) / 3600 * 5)) END DESC,
    p.created_at DESC
  LIMIT p_limit OFFSET p_offset;
END;
$$ LANGUAGE plpgsql STABLE;
