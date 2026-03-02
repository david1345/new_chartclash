-- ==================================================
-- 🏁 ULTIMATE ALPHA & SEPARATION SYSTEM FIX (FINAL)
-- ==================================================

-- [1] Relax ALL Constraints (Allow 0 for Alpha)
-- Note: Dropping by generic names as they are likely system-generated or known.
ALTER TABLE public.predictions DROP CONSTRAINT IF EXISTS predictions_bet_amount_check;
ALTER TABLE public.predictions DROP CONSTRAINT IF EXISTS predictions_entry_price_check;
ALTER TABLE public.predictions DROP CONSTRAINT IF EXISTS predictions_target_percent_check;

-- This handles inline checks by trying to drop common patterns if the above didn't catch them
DO $$ 
BEGIN 
    BEGIN
        ALTER TABLE public.predictions DROP CONSTRAINT IF EXISTS predictions_bet_amount_check1;
        ALTER TABLE public.predictions DROP CONSTRAINT IF EXISTS predictions_entry_price_check1;
    EXCEPTION WHEN OTHERS THEN NULL;
    END;
END $$;

-- [2] Re-add Relaxed Constraints
ALTER TABLE public.predictions ADD CONSTRAINT predictions_bet_amount_check CHECK (bet_amount >= 0 AND bet_amount <= 1000);
ALTER TABLE public.predictions ADD CONSTRAINT predictions_entry_price_check CHECK (entry_price >= 0);
ALTER TABLE public.predictions ADD CONSTRAINT predictions_target_percent_check CHECK (target_percent >= 0);

-- [3] Ensure Columns Exist
ALTER TABLE public.predictions ADD COLUMN IF NOT EXISTS likes_count INTEGER DEFAULT 0;
ALTER TABLE public.predictions ADD COLUMN IF NOT EXISTS is_opinion BOOLEAN DEFAULT FALSE;

-- [4] Update Legacy Data
UPDATE public.predictions SET is_opinion = TRUE 
WHERE comment IS NOT NULL AND (bet_amount = 0 OR entry_price = 0);

-- [5] Final Unified RPC with Opinion Filtering
DROP FUNCTION IF EXISTS public.get_ranked_insights(text, text, text, integer, integer);
DROP FUNCTION IF EXISTS public.get_ranked_insights(text, text, text, integer, integer, uuid);
DROP FUNCTION IF EXISTS public.get_ranked_insights(text, text, text, integer, integer, boolean);

CREATE OR REPLACE FUNCTION public.get_ranked_insights(
  p_asset_symbol TEXT DEFAULT NULL,
  p_timeframe TEXT DEFAULT NULL,
  p_sort_by TEXT DEFAULT 'TOP',
  p_limit INTEGER DEFAULT 20,
  p_offset INTEGER DEFAULT 0,
  p_is_opinion BOOLEAN DEFAULT TRUE,
  p_channel TEXT DEFAULT 'main'  -- Add channel support
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
  SELECT
    p.id, p.user_id, prof.username, prof.tier,
    CASE WHEN prof.total_games > 0 THEN ROUND((prof.total_wins::numeric / prof.total_games::numeric) * 100, 1) ELSE 0 END,
    prof.total_games, p.asset_symbol, p.timeframe, p.direction, p.target_percent, p.entry_price, p.status, p.profit,
    p.created_at, p.resolved_at, p.comment, p.likes_count,
    (
      (CASE WHEN p.status = 'WIN' THEN 40 ELSE 0 END) + (p.target_percent * 15) + (p.likes_count * 2) +
      (CASE WHEN prof.total_games > 0 THEN (prof.total_wins::numeric / prof.total_games::numeric) * 100 * 0.2 ELSE 0 END) -
      (EXTRACT(EPOCH FROM (NOW() - p.created_at)) / 3600 * 1.5)
    )::numeric,
    p.is_opinion
  FROM predictions p
  JOIN profiles prof ON p.user_id = prof.id
  WHERE (p_asset_symbol IS NULL OR p.asset_symbol = p_asset_symbol) 
    AND (p_timeframe IS NULL OR p.timeframe = p_timeframe) 
    AND (p.comment IS NOT NULL AND length(p.comment) > 0) 
    AND (p.is_opinion = p_is_opinion)
    AND (p.channel = p_channel) -- Filter by channel
  ORDER BY
    CASE WHEN p_sort_by = 'TOP' THEN 18 END DESC,
    CASE WHEN p_sort_by = 'NEW' THEN p.created_at END DESC,
    CASE WHEN p_sort_by = 'RISING' THEN (p.likes_count * 10 - (EXTRACT(EPOCH FROM (NOW() - p.created_at)) / 3600 * 5)) END DESC,
    p.created_at DESC
  LIMIT p_limit OFFSET p_offset;
END;
$$ LANGUAGE plpgsql STABLE;
