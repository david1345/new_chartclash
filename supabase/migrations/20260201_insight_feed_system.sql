-- ==============================================================================
-- 🚀 INSIGHT FEED SYSTEM UPGRADE
-- Implements: Skill Stats, Prediction Likes, Ranking Algorithm
-- ==============================================================================

-- 1. Profile Stats for Badge System
ALTER TABLE public.profiles 
  ADD COLUMN IF NOT EXISTS total_games INTEGER DEFAULT 0,
  ADD COLUMN IF NOT EXISTS total_wins INTEGER DEFAULT 0;

-- 2. Prediction Interactions
-- We need to track likes on predictions specifically
CREATE TABLE IF NOT EXISTS public.prediction_likes (
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  prediction_id BIGINT REFERENCES public.predictions(id) ON DELETE CASCADE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  PRIMARY KEY (user_id, prediction_id)
);

ALTER TABLE public.prediction_likes ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Public view" ON prediction_likes FOR SELECT USING (true);
CREATE POLICY "Auth like" ON prediction_likes FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Auth unlike" ON prediction_likes FOR DELETE USING (auth.uid() = user_id);

-- Add interaction counts to predictions for performance (optional but recommended for sorting)
ALTER TABLE public.predictions
  ADD COLUMN IF NOT EXISTS likes_count INTEGER DEFAULT 0;

-- 3. Trigger to maintain likes_count
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

-- 4. UPDATE RESOLVE FUNCTION to track Stats
-- We drop the old one and redefine it to include Stats Update
DROP FUNCTION IF EXISTS public.resolve_prediction_advanced(bigint, numeric);

CREATE OR REPLACE FUNCTION public.resolve_prediction_advanced(
    p_id bigint,
    p_close_price numeric
)
RETURNS JSON
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
declare
    v_prediction record;
    v_price_change numeric;
    v_price_change_percent numeric;
    v_status text;
    v_payout integer := 0;
begin
    select * into v_prediction from predictions where id = p_id and status = 'pending' for update;
    
    if not found then return json_build_object('success', false, 'error', 'Prediction not found'); end if;
    
    v_price_change := p_close_price - v_prediction.entry_price;
    v_price_change_percent := abs(v_price_change / v_prediction.entry_price * 100);
    
    if v_prediction.direction = 'UP' then
        if v_price_change > 0 and v_price_change_percent >= v_prediction.target_percent then
            v_status := 'WIN';
            v_payout := v_prediction.bet_amount * (v_prediction.target_percent * 2 + 1);
        elsif v_price_change < 0 then
            v_status := 'LOSS';
        else
            v_status := 'ND';
            v_payout := v_prediction.bet_amount;
        end if;
    elsif v_prediction.direction = 'DOWN' then
        if v_price_change < 0 and v_price_change_percent >= v_prediction.target_percent then
            v_status := 'WIN';
            v_payout := v_prediction.bet_amount * (v_prediction.target_percent * 2 + 1);
        elsif v_price_change > 0 then
            v_status := 'LOSS';
        else
            v_status := 'ND';
            v_payout := v_prediction.bet_amount;
        end if;
    end if;
    
    -- Update Prediction
    update predictions
    set status = v_status, actual_price = p_close_price, profit = v_payout - v_prediction.bet_amount, resolved_at = now()
    where id = p_id;
    
    -- Update User Profile (Points + Stats)
    update profiles
    set 
        points = points + v_payout, -- Winning payout (0 if lost)
        total_games = total_games + 1,
        total_wins = total_wins + (CASE WHEN v_status = 'WIN' THEN 1 ELSE 0 END),
        streak_count = (CASE WHEN v_status = 'WIN' THEN streak_count + 1 ELSE 0 END),
        total_earnings = total_earnings + (v_payout - v_prediction.bet_amount) -- Net profit
    where id = v_prediction.user_id;
    
    return json_build_object('success', true, 'status', v_status, 'payout', v_payout);
exception when others then
    return json_build_object('success', false, 'error', SQLERRM);
end;
$$;


-- 5. RANKING ALGORITHM RPC
-- Returns predictions with enriched Insight Score and User Badge Data
CREATE OR REPLACE FUNCTION get_ranked_insights(
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
    
    -- 🧠 INSIGHT SCORE ALGORITHM
    -- terms: 
    -- 1. Result: WIN +40
    -- 2. Difficulty: Target% * 15
    -- 3. Social: Likes * 2
    -- 4. Time Decay: -1.5 per hour
    -- 5. User Authority: WinRate(0-100) * 0.2 -> max 20 pts
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
    -- Optional Filters
    (p_asset_symbol IS NULL OR p.asset_symbol = p_asset_symbol) AND
    (p_timeframe IS NULL OR p.timeframe = p_timeframe) AND
    -- Only show items with comments (Insights) or all? Prompt implies "Insights" are "predictions with reasoning".
    -- Let's show all, but those with comments look better.
    -- Or just filter where comment is not null? "Insight Feed" implies text.
    (p.comment IS NOT NULL AND length(p.comment) > 0)
    
  ORDER BY
    CASE WHEN p_sort_by = 'TOP' THEN 18 END DESC, -- Sort by insight_score (col 18)
    CASE WHEN p_sort_by = 'NEW' THEN p.created_at END DESC,
    CASE WHEN p_sort_by = 'RISING' THEN (p.likes_count * 10 - (EXTRACT(EPOCH FROM (NOW() - p.created_at)) / 3600 * 5)) END DESC, -- Simple rising logic
    
    -- Fallback sort
    p.created_at DESC
  LIMIT p_limit OFFSET p_offset;
END;
$$ LANGUAGE plpgsql STABLE;
