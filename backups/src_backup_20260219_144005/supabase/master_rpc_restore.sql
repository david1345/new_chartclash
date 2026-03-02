-- ==============================================================================
-- 🛠️ MASTER RPC RESTORE (Stable Production Logic)
-- ==============================================================================

-- 1. Profiles 테이블 컬럼 보정 (누락된 통계 필드)
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS streak INTEGER DEFAULT 0;
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS streak_count INTEGER DEFAULT 0;
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS total_games INTEGER DEFAULT 0;
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS total_earnings INTEGER DEFAULT 0;

-- 1.5 테스트 유저 초기화 RPC (테스트 안정성용)
CREATE OR REPLACE FUNCTION public.reset_test_user(p_user_id UUID)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    DELETE FROM public.activity_logs WHERE user_id = p_user_id;
    DELETE FROM public.notifications WHERE user_id = p_user_id;
    DELETE FROM public.predictions WHERE user_id = p_user_id;
    UPDATE public.profiles SET 
        points = 1000, 
        streak = 0, 
        streak_count = 0, 
        total_games = 0, 
        total_wins = 0,
        total_earnings = 0
    WHERE id = p_user_id;
END;
$$;

-- 2. get_user_rank RPC
CREATE OR REPLACE FUNCTION public.get_user_rank(p_user_id UUID)
RETURNS BIGINT
LANGUAGE sql
STABLE
SECURITY DEFINER
AS $$
    SELECT rank
    FROM (
        SELECT id, RANK() OVER (ORDER BY points DESC) as rank
        FROM public.profiles
    ) as ranked_users
    WHERE id = p_user_id;
$$;

-- 3. submit_prediction RPC (Modified with SECURITY DEFINER for points update)
CREATE OR REPLACE FUNCTION public.submit_prediction(
  p_user_id UUID,
  p_asset_symbol TEXT,
  p_timeframe TEXT,
  p_direction TEXT,
  p_target_percent NUMERIC,
  p_entry_price NUMERIC,
  p_bet_amount INTEGER
) RETURNS JSONB AS $$
DECLARE
  v_user_points INTEGER;
  v_prediction_id BIGINT;
  v_interval INTERVAL;
  v_candle_close TIMESTAMP WITH TIME ZONE;
BEGIN
  -- Timeframe Logic
  IF p_timeframe = '1m' THEN v_interval := INTERVAL '1 minute';
  ELSIF p_timeframe = '5m' THEN v_interval := INTERVAL '5 minutes';
  ELSIF p_timeframe = '15m' THEN v_interval := INTERVAL '15 minutes';
  ELSIF p_timeframe = '30m' THEN v_interval := INTERVAL '30 minutes';
  ELSIF p_timeframe = '1h' THEN v_interval := INTERVAL '1 hour';
  ELSIF p_timeframe = '4h' THEN v_interval := INTERVAL '4 hours';
  ELSIF p_timeframe = '1d' THEN v_interval := INTERVAL '1 day';
  ELSE v_interval := INTERVAL '1 hour';
  END IF;

  v_candle_close := date_bin(v_interval, now(), '2000-01-01'::timestamp with time zone) + v_interval;

  -- User Points Check
  SELECT points INTO v_user_points FROM profiles WHERE id = p_user_id FOR UPDATE;
  IF v_user_points IS NULL THEN RAISE EXCEPTION 'User profile not found'; END IF;
  IF v_user_points < p_bet_amount THEN RAISE EXCEPTION 'Insufficient points. Current: %, Required: %', v_user_points, p_bet_amount; END IF;

  -- Deduct Points
  UPDATE profiles SET points = points - p_bet_amount WHERE id = p_user_id;

  -- Insert Prediction
  INSERT INTO predictions (
    user_id, asset_symbol, timeframe, direction, target_percent, 
    entry_price, status, bet_amount, candle_close_at, created_at
  ) VALUES (
    p_user_id, p_asset_symbol, p_timeframe, p_direction, p_target_percent, 
    p_entry_price, 'pending', p_bet_amount, v_candle_close, now()
  ) RETURNING id INTO v_prediction_id;

  RETURN jsonb_build_object('success', true, 'prediction_id', v_prediction_id, 'new_points', v_user_points - p_bet_amount);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 4. resolve_prediction_advanced RPC (Reward Logic with Multipliers)
CREATE OR REPLACE FUNCTION public.resolve_prediction_advanced(
    p_id BIGINT,
    p_close_price NUMERIC,
    p_open_price NUMERIC DEFAULT NULL
)
RETURNS JSON
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_prediction RECORD;
    v_profile RECORD;
    v_price_change NUMERIC;
    v_price_change_percent NUMERIC;
    v_status TEXT;
    v_is_dir_correct BOOLEAN;
    v_is_target_hit BOOLEAN;
    v_final_profit NUMERIC := 0;
    v_payout INTEGER := 0;
    v_tf_mult NUMERIC;
    v_streak_mult NUMERIC;
    v_target_bonus INTEGER := 0;
    v_new_streak INTEGER;
    v_open_price NUMERIC;
    c_house_edge NUMERIC := 0.95;
BEGIN
    SELECT * INTO v_prediction FROM predictions WHERE id = p_id AND status = 'pending' FOR UPDATE;
    IF NOT FOUND THEN RETURN json_build_object('success', false, 'error', 'Already resolved'); END IF;
    
    v_open_price := COALESCE(p_open_price, v_prediction.entry_price);
    SELECT * INTO v_profile FROM profiles WHERE id = v_prediction.user_id FOR UPDATE;

    v_price_change := p_close_price - v_open_price;
    v_price_change_percent := abs(v_price_change / v_open_price * 100);

    v_is_dir_correct := (v_prediction.direction = 'UP' AND v_price_change > 0) OR (v_prediction.direction = 'DOWN' AND v_price_change < 0);
    v_is_target_hit := (v_price_change_percent >= v_prediction.target_percent);

    IF v_is_dir_correct THEN
        v_status := 'WIN';
        CASE v_prediction.timeframe 
            WHEN '30m' THEN v_tf_mult := 1.2; WHEN '1h' THEN v_tf_mult := 1.5; WHEN '4h' THEN v_tf_mult := 2.2; WHEN '1d' THEN v_tf_mult := 3.0; ELSE v_tf_mult := 1.0;
        END CASE;
        
        IF v_prediction.target_percent <= 0.5 THEN v_target_bonus := 20; ELSIF v_prediction.target_percent <= 1.0 THEN v_target_bonus := 40; ELSIF v_prediction.target_percent <= 1.5 THEN v_target_bonus := 70; ELSE v_target_bonus := 120; END IF;
            v_new_streak := COALESCE(v_profile.streak, 0) + 1;
        ELSE
            v_new_streak := 0;
        END IF;

        IF v_new_streak >= 5 THEN v_streak_mult := 2.5; ELSIF v_new_streak = 4 THEN v_streak_mult := 2.0; ELSIF v_new_streak = 3 THEN v_streak_mult := 1.6; ELSIF v_new_streak = 2 THEN v_streak_mult := 1.3; ELSE v_streak_mult := 1.0; END IF;
        
        v_final_profit := (v_prediction.bet_amount * 0.8 * v_tf_mult + v_target_bonus) * v_streak_mult * c_house_edge;
        v_payout := v_prediction.bet_amount + ROUND(v_final_profit);
    ELSIF v_price_change = 0 THEN
        v_status := 'ND'; v_payout := v_prediction.bet_amount; v_final_profit := 0; v_new_streak := COALESCE(v_profile.streak, 0);
    ELSE
        v_status := 'LOSS'; v_payout := 0; v_final_profit := -v_prediction.bet_amount; v_new_streak := 0;
    END IF;

    -- Update Profile Stats
    UPDATE profiles 
    SET points = points + v_payout, 
        streak = v_new_streak,
        streak_count = CASE WHEN v_new_streak > COALESCE(streak_count, 0) THEN v_new_streak ELSE streak_count END,
        total_games = COALESCE(total_games, 0) + 1,
        total_wins = CASE WHEN v_status = 'WIN' THEN COALESCE(total_wins, 0) + 1 ELSE total_wins END
    WHERE id = v_prediction.user_id;

    -- Update Prediction Result
    UPDATE predictions SET status = v_status, actual_price = p_close_price, entry_price = v_open_price, profit = ROUND(v_final_profit), resolved_at = now() WHERE id = p_id;
    
    -- Notification
    INSERT INTO notifications (user_id, type, message, prediction_id)
    VALUES (v_prediction.user_id, 'prediction_resolved', format('%s: %s (%s pts)', v_prediction.asset_symbol, v_status, ROUND(v_final_profit)), p_id);

    RETURN json_build_object('success', true, 'status', v_status, 'profit', ROUND(v_final_profit));
END;
$$;

-- 5. get_ranked_insights RPC (The Community Feed Core)
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
      (p.likes_count * 5) +
      (CASE WHEN p.comment IS NOT NULL AND length(p.comment) > 0 THEN 25 ELSE 0 END) +
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

-- 6. Explicit Table Grants & RLS (Final Safety Layer)
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.predictions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.notifications ADD COLUMN IF NOT EXISTS prediction_id BIGINT;
ALTER TABLE public.notifications ENABLE ROW LEVEL SECURITY;

-- 5.5 Feedbacks Table (Suggestion/Bug Reporting)
CREATE TABLE IF NOT EXISTS public.feedbacks (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID REFERENCES auth.users(id) ON DELETE SET NULL,
    email TEXT NOT NULL,
    category TEXT NOT NULL CHECK (category IN ('bug', 'suggestion', 'other')),
    message TEXT NOT NULL CHECK (length(message) <= 2000),
    created_at TIMESTAMPTZ DEFAULT now()
);
ALTER TABLE public.feedbacks ENABLE ROW LEVEL SECURITY;

-- Policies for Profiles
DROP POLICY IF EXISTS "Public view" ON public.profiles;
CREATE POLICY "Public view" ON public.profiles FOR SELECT USING (true);
DROP POLICY IF EXISTS "Self update" ON public.profiles;
CREATE POLICY "Self update" ON public.profiles FOR UPDATE USING (auth.uid() = id);

-- Policies for Predictions
DROP POLICY IF EXISTS "Public view predictions" ON public.predictions;
CREATE POLICY "Public view predictions" ON public.predictions FOR SELECT USING (true);
DROP POLICY IF EXISTS "Users insert predictions" ON public.predictions;
CREATE POLICY "Users insert predictions" ON public.predictions FOR INSERT WITH CHECK (auth.uid() = user_id);

-- Policies for Notifications
DROP POLICY IF EXISTS "Users view notifications" ON public.notifications;
CREATE POLICY "Users view notifications" ON public.notifications FOR SELECT USING (auth.uid() = user_id);
DROP POLICY IF EXISTS "System insert notifications" ON public.notifications;
CREATE POLICY "System insert notifications" ON public.notifications FOR INSERT WITH CHECK (true);

-- Policies for Feedbacks
DROP POLICY IF EXISTS "Anyone can submit feedback" ON public.feedbacks;
CREATE POLICY "Anyone can submit feedback" ON public.feedbacks FOR INSERT TO anon, authenticated WITH CHECK (true);
DROP POLICY IF EXISTS "Authenticated users can read feedback" ON public.feedbacks;
CREATE POLICY "Authenticated users can read feedback" ON public.feedbacks FOR SELECT TO authenticated USING (true);

-- Grants
GRANT ALL ON SCHEMA public TO postgres, authenticated, anon, service_role;
GRANT ALL ON ALL TABLES IN SCHEMA public TO postgres, authenticated, service_role;
GRANT SELECT, INSERT ON ALL TABLES IN SCHEMA public TO anon;
GRANT ALL ON ALL SEQUENCES IN SCHEMA public TO postgres, authenticated, service_role;
GRANT SELECT ON ALL SEQUENCES IN SCHEMA public TO anon;

-- Extra explicit grant for service_role to be absolutely sure
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON TABLES TO service_role;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON SEQUENCES TO service_role;
GRANT ALL ON public.profiles, public.predictions, public.notifications, public.feedbacks TO service_role;
GRANT INSERT, SELECT ON public.feedbacks TO anon, authenticated;
