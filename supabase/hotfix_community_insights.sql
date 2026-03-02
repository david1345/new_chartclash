-- ==========================================
-- 🛠️ COMMUNITY INSIGHT FEED RESTORATION
-- Restores get_ranked_insights RPC and all dependencies
-- ==========================================

BEGIN;

-- 1. Ensure Profiles Table has stats columns
ALTER TABLE public.profiles 
  ADD COLUMN IF NOT EXISTS total_games INTEGER DEFAULT 0,
  ADD COLUMN IF NOT EXISTS total_wins INTEGER DEFAULT 0;

-- 2. Ensure Predictions Table has likes_count
ALTER TABLE public.predictions
  ADD COLUMN IF NOT EXISTS likes_count INTEGER DEFAULT 0;

-- 3. Restore Prediction Likes Infrastructure
CREATE TABLE IF NOT EXISTS public.prediction_likes (
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  prediction_id BIGINT REFERENCES public.predictions(id) ON DELETE CASCADE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  PRIMARY KEY (user_id, prediction_id)
);

ALTER TABLE public.prediction_likes ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Public view" ON prediction_likes;
CREATE POLICY "Public view" ON prediction_likes FOR SELECT USING (true);

DROP POLICY IF EXISTS "Auth like" ON prediction_likes;
CREATE POLICY "Auth like" ON prediction_likes FOR INSERT WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Auth unlike" ON prediction_likes;
CREATE POLICY "Auth unlike" ON prediction_likes FOR DELETE USING (auth.uid() = user_id);

-- Trigger to maintain likes_count
CREATE OR REPLACE FUNCTION update_prediction_likes_count()
RETURNS TRIGGER AS $$
BEGIN
  IF (TG_OP = 'INSERT') THEN
    UPDATE public.predictions SET likes_count = likes_count + 1 WHERE id = NEW.prediction_id;
  ELSIF (TG_OP = 'DELETE') THEN
    UPDATE public.predictions SET likes_count = likes_count - 1 WHERE id = OLD.prediction_id;
  END IF;
  RETURN NULL;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS on_prediction_like ON public.prediction_likes;
CREATE TRIGGER on_prediction_like
AFTER INSERT OR DELETE ON public.prediction_likes
FOR EACH ROW EXECUTE PROCEDURE update_prediction_likes_count();

-- 4. Restore get_ranked_insights RPC (Latest Unfiltered Version)
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
    -- Calculate Win Rate safely
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

    -- 🧠 IMPROVED INSIGHT SCORE ALGORITHM
    (
      (CASE WHEN p.status = 'WIN' THEN 40 ELSE 0 END) +
      (p.target_percent * 15) +
      (p.likes_count * 5) + -- Weighted higher
      (CASE WHEN p.comment IS NOT NULL AND length(p.comment) > 0 THEN 25 ELSE 0 END) + -- Bonus for reasoning
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
    (p_timeframe IS NULL OR p.timeframe = p_timeframe)
    
  ORDER BY
    CASE WHEN p_sort_by = 'TOP' THEN 18 END DESC, 
    CASE WHEN p_sort_by = 'NEW' THEN p.created_at END DESC,
    CASE WHEN p_sort_by = 'RISING' THEN (p.likes_count * 10 - (EXTRACT(EPOCH FROM (NOW() - p.created_at)) / 3600 * 5)) END DESC,
    p.created_at DESC
  LIMIT p_limit OFFSET p_offset;
END;
$$ LANGUAGE plpgsql STABLE;

COMMIT;
