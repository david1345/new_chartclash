-- 1. Restore Bet Amount Constraint
ALTER TABLE public.predictions 
  DROP CONSTRAINT IF EXISTS predictions_bet_amount_check;

ALTER TABLE public.predictions
  ADD CONSTRAINT predictions_bet_amount_check 
  CHECK (bet_amount > 0 AND bet_amount <= 1000);

-- 2. Clean up Likes System
DROP FUNCTION IF EXISTS public.toggle_prediction_like(p_prediction_id BIGINT);
DROP TABLE IF EXISTS public.prediction_likes CASCADE;

-- 3. Restore get_ranked_insights to original signature
-- Drop the new version with viewer_id and opinion support
DROP FUNCTION IF EXISTS public.get_ranked_insights(text, text, text, integer, integer, uuid);
DROP FUNCTION IF EXISTS public.get_ranked_insights(text, text, text, integer, integer);

-- Create the previous version
CREATE OR REPLACE FUNCTION public.get_ranked_insights(
  p_asset_symbol TEXT DEFAULT NULL,
  p_timeframe TEXT DEFAULT NULL,
  p_sort_by TEXT DEFAULT 'TOP', -- 'TOP', 'NEW', 'RISING'
  p_limit INTEGER DEFAULT 20,
  p_offset INTEGER DEFAULT 0
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
  insight_score NUMERIC
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
    )::numeric as insight_score
  FROM predictions p
  JOIN profiles prof ON p.user_id = prof.id
  WHERE 
    (p_asset_symbol IS NULL OR p.asset_symbol = p_asset_symbol) AND
    (p_timeframe IS NULL OR p.timeframe = p_timeframe) AND
    (p.comment IS NOT NULL AND length(p.comment) > 0)
  ORDER BY
    CASE WHEN p_sort_by = 'TOP' THEN 18 END DESC,
    CASE WHEN p_sort_by = 'NEW' THEN p.created_at END DESC,
    CASE WHEN p_sort_by = 'RISING' THEN (p.likes_count * 10 - (EXTRACT(EPOCH FROM (NOW() - p.created_at)) / 3600 * 5)) END DESC,
    p.created_at DESC
  LIMIT p_limit OFFSET p_offset;
END;
$$ LANGUAGE plpgsql STABLE;

-- 4. Remove extra columns (Dangerous but necessary for full rollback)
-- ALTER TABLE public.predictions DROP COLUMN IF EXISTS is_opinion;
-- ALTER TABLE public.predictions DROP COLUMN IF EXISTS likes_count;
-- Note: likes_count might have existed before our very last iteration, 
-- but we'll leave it if it was part of a previous 'stable' state.
-- Given the user wants to go back to "before dev insight", 
-- we should probably keep them if they were there on 2/1, but delete if they were added today.
-- To be safe, we'll just leave columns but revert logic.
