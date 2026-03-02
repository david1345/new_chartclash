-- ==========================================
-- 🚀 FINAL INSIGHT FEED SCHEMA & LOGIC FIX
-- Combined fix for missing columns, tables, and RPCs
-- ==========================================

BEGIN;

-- 1. FIX PROFILES TABLE
-- Add missing stats columns used by the Insight Feed
ALTER TABLE public.profiles 
  ADD COLUMN IF NOT EXISTS total_games INTEGER DEFAULT 0,
  ADD COLUMN IF NOT EXISTS total_wins INTEGER DEFAULT 0;

-- 2. FIX PREDICTIONS TABLE
-- Add likes_count for the ranking algorithm
ALTER TABLE public.predictions
  ADD COLUMN IF NOT EXISTS likes_count INTEGER DEFAULT 0;

-- 3. CREATE PREDICTION_LIKES TABLE
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

-- 4. TRIGGER: Maintain likes_count
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

-- 5. RPC: get_ranked_insights (The Feed Core)
CREATE OR REPLACE FUNCTION public.get_ranked_insights(
  p_asset_symbol TEXT DEFAULT NULL,
  p_timeframe TEXT DEFAULT NULL,
  p_sort_by TEXT DEFAULT 'TOP',
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
    
    -- 🧠 INSIGHT SCORE ALGORITHM
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

-- 6. RPC: resolve_prediction_advanced (Stable + Stats)
CREATE OR REPLACE FUNCTION public.resolve_prediction_advanced(
    p_id BIGINT,
    p_close_price NUMERIC,
    p_open_price NUMERIC DEFAULT NULL
)
RETURNS JSON LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
    v_prediction RECORD;
    v_status TEXT;
    v_payout INTEGER := 0;
    v_symbol_emoji TEXT;
BEGIN
    SELECT * INTO v_prediction FROM predictions WHERE id = p_id AND status = 'pending' FOR UPDATE;
    IF NOT FOUND THEN RETURN json_build_object('success', false, 'error', 'Not found'); END IF;

    v_symbol_emoji := CASE 
        WHEN v_prediction.asset_symbol ILIKE '%BTC%' THEN '₿'
        WHEN v_prediction.asset_symbol ILIKE '%ETH%' THEN 'Ξ'
        WHEN v_prediction.asset_symbol ILIKE '%SOL%' THEN '◎'
        ELSE '📈'
    END;

    IF v_prediction.direction = 'UP' THEN
        IF p_close_price > v_prediction.entry_price AND (abs(p_close_price - v_prediction.entry_price)/v_prediction.entry_price*100) >= v_prediction.target_percent THEN
            v_status := 'WIN';
            v_payout := v_prediction.bet_amount * (v_prediction.target_percent * 2 + 1);
        ELSIF p_close_price < v_prediction.entry_price THEN v_status := 'LOSS';
        ELSE v_status := 'ND'; v_payout := v_prediction.bet_amount; END IF;
    ELSE -- DOWN
        IF p_close_price < v_prediction.entry_price AND (abs(p_close_price - v_prediction.entry_price)/v_prediction.entry_price*100) >= v_prediction.target_percent THEN
            v_status := 'WIN';
            v_payout := v_prediction.bet_amount * (v_prediction.target_percent * 2 + 1);
        ELSIF p_close_price > v_prediction.entry_price THEN v_status := 'LOSS';
        ELSE v_status := 'ND'; v_payout := v_prediction.bet_amount; END IF;
    END IF;

    -- Update Prediction
    UPDATE predictions 
    SET status = v_status, actual_price = p_close_price, profit = v_payout - v_prediction.bet_amount, resolved_at = now() 
    WHERE id = p_id;
    
    -- Update User Profile (Points + Stats + Earnings)
    UPDATE profiles 
    SET 
        points = points + v_payout, 
        streak_count = CASE WHEN v_status = 'WIN' THEN streak_count + 1 ELSE 0 END,
        total_games = total_games + 1,
        total_wins = total_wins + (CASE WHEN v_status = 'WIN' THEN 1 ELSE 0 END),
        total_earnings = total_earnings + (v_payout - v_prediction.bet_amount)
    WHERE id = v_prediction.user_id;

    -- Send Notification
    INSERT INTO notifications (user_id, type, title, message)
    VALUES (v_prediction.user_id, 'result', 
            CASE WHEN v_status = 'WIN' THEN '✅ WIN!' ELSE '❌ LOSS' END,
            format('%s %s result: %s (%s pts)', v_symbol_emoji, v_prediction.asset_symbol, v_status, v_payout - v_prediction.bet_amount));

    RETURN json_build_object('success', true, 'status', v_status);
END;
$$;

COMMIT;
