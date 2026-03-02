-- ==========================================
-- ⚖️ FINAL FAIRNESS & ECONOMY V3.1 MERGE
-- ==========================================

-- 1. Schema Update
ALTER TABLE predictions ADD COLUMN IF NOT EXISTS entry_offset_seconds INTEGER DEFAULT 0;

-- 2. UPDATE: submit_prediction (Window Guard & Normalization)
DROP FUNCTION IF EXISTS public.submit_prediction(uuid, text, text, text, numeric, numeric, integer);

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
  v_round_start TIMESTAMP WITH TIME ZONE;
  v_round_end TIMESTAMP WITH TIME ZONE;
  v_now TIMESTAMP WITH TIME ZONE := now();
  v_offset_seconds INTEGER;
BEGIN
  -- A. Determine Interval
  CASE p_timeframe
    WHEN '1m' THEN v_interval := INTERVAL '1 minute';
    WHEN '5m' THEN v_interval := INTERVAL '5 minutes';
    WHEN '15m' THEN v_interval := INTERVAL '15 minutes';
    WHEN '30m' THEN v_interval := INTERVAL '30 minutes';
    WHEN '1h' THEN v_interval := INTERVAL '1 hour';
    WHEN '4h' THEN v_interval := INTERVAL '4 hours';
    WHEN '1d' THEN v_interval := INTERVAL '1 day';
    ELSE v_interval := INTERVAL '15 minutes';
  END CASE;

  -- B. Calculate Boundaries
  v_round_start := date_bin(v_interval, v_now, '2000-01-01'::timestamp with time zone);
  v_round_end := v_round_start + v_interval;
  v_offset_seconds := EXTRACT(EPOCH FROM (v_now - v_round_start))::INTEGER;

  -- B2. Duplicate Check (One Bet Per Round)
  IF EXISTS (
    SELECT 1 FROM predictions 
    WHERE user_id = p_user_id 
      AND asset_symbol = p_asset_symbol 
      AND timeframe = p_timeframe 
      AND candle_close_at = v_round_end
      AND status = 'pending'
  ) THEN
    RAISE EXCEPTION 'You have already participated in this round. Please wait for the next candle.';
  END IF;

  -- C. 1/3 Window Guard (Server-Side)
  IF v_offset_seconds > (EXTRACT(EPOCH FROM v_interval) / 3) THEN
    RAISE EXCEPTION 'Betting window closed for this round. Please wait for the next candle.';
  END IF;

  -- D. Points check
  SELECT points INTO v_user_points FROM profiles WHERE id = p_user_id FOR UPDATE;
  IF v_user_points IS NULL THEN RAISE EXCEPTION 'User profile not found.'; END IF;
  IF v_user_points < p_bet_amount THEN RAISE EXCEPTION 'Insufficient points.'; END IF;

  -- E. Execution
  UPDATE profiles SET points = points - p_bet_amount WHERE id = p_user_id;

  INSERT INTO predictions (
    user_id, asset_symbol, timeframe, direction, target_percent, 
    entry_price, status, bet_amount, candle_close_at, created_at,
    entry_offset_seconds
  ) VALUES (
    p_user_id, p_asset_symbol, p_timeframe, p_direction, p_target_percent, 
    p_entry_price, 'pending', p_bet_amount, v_round_end, v_now,
    v_offset_seconds
  ) RETURNING id INTO v_prediction_id;

  RETURN jsonb_build_object(
    'success', true,
    'prediction_id', v_prediction_id,
    'new_points', v_user_points - p_bet_amount,
    'round_start', v_round_start,
    'round_end', v_round_end
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;


-- 3. UPDATE: resolve_prediction_advanced (Economy + Fairness)
DROP FUNCTION IF EXISTS public.resolve_prediction_advanced(bigint, numeric, numeric);

CREATE OR REPLACE FUNCTION public.resolve_prediction_advanced(
    p_id BIGINT,
    p_close_price NUMERIC,
    p_open_price NUMERIC -- Requirement: Pass Open Price from Cron
)
RETURNS JSON
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_prediction RECORD;
    v_profile RECORD;
    v_is_win BOOLEAN;
    v_is_target_hit BOOLEAN;
    v_status TEXT;
    
    -- Econ Constants
    c_house_edge NUMERIC := 0.95;
    
    -- Calculation Vars
    v_price_change_percent NUMERIC;
    v_tf_mult NUMERIC := 1.0;
    v_late_mult NUMERIC := 1.0;
    v_streak_mult NUMERIC := 1.0;
    v_target_bonus INTEGER := 0;
    
    v_base_profit NUMERIC := 0;
    v_final_profit NUMERIC := 0;
    v_payout INTEGER := 0;
    v_new_streak INTEGER;
    v_duration_seconds INTEGER;
BEGIN
    -- 1. Fetch Data
    SELECT * INTO v_prediction FROM predictions WHERE id = p_id AND status = 'pending' FOR UPDATE;
    IF NOT FOUND THEN RETURN json_build_object('success', false, 'error', 'Not found'); END IF;

    SELECT * INTO v_profile FROM profiles WHERE id = v_prediction.user_id FOR UPDATE;

    -- 2. Outcome Determination (Standardized to p_open_price)
    v_is_win := (v_prediction.direction = 'UP' AND p_close_price > p_open_price) OR 
                (v_prediction.direction = 'DOWN' AND p_close_price < p_open_price);
    
    v_price_change_percent := abs(((p_close_price - p_open_price) / p_open_price) * 100);
    v_is_target_hit := v_is_win AND (v_price_change_percent >= v_prediction.target_percent);

    -- 3. Calculate Multipliers
    IF v_is_win THEN
        v_status := 'WIN';

        -- A. Timeframe Multiplier
        CASE 
            WHEN v_prediction.timeframe = '1m' THEN v_tf_mult := 1.0;
            WHEN v_prediction.timeframe = '5m' THEN v_tf_mult := 1.0;
            WHEN v_prediction.timeframe = '15m' THEN v_tf_mult := 1.0;
            WHEN v_prediction.timeframe = '30m' THEN v_tf_mult := 1.1;
            WHEN v_prediction.timeframe = '1h' THEN v_tf_mult := 1.2;
            WHEN v_prediction.timeframe = '4h' THEN v_tf_mult := 1.5;
            WHEN v_prediction.timeframe = '1d' THEN v_tf_mult := 1.8;
            ELSE v_tf_mult := 1.0;
        END CASE;

        -- B. Late Entry Penalty (1/7.5 duration threshold)
        CASE v_prediction.timeframe
            WHEN '1m' THEN v_duration_seconds := 60;
            WHEN '5m' THEN v_duration_seconds := 300;
            WHEN '15m' THEN v_duration_seconds := 900;
            WHEN '30m' THEN v_duration_seconds := 1800;
            WHEN '1h' THEN v_duration_seconds := 3600;
            WHEN '4h' THEN v_duration_seconds := 14400;
            WHEN '1d' THEN v_duration_seconds := 86400;
            ELSE v_duration_seconds := 900;
        END CASE;

        IF v_prediction.entry_offset_seconds > (v_duration_seconds / 7.5) THEN
            v_late_mult := 0.8;
        END IF;

        -- C. Target Bonus & Streak Logic
        IF v_is_target_hit THEN
            CASE 
                WHEN v_prediction.target_percent <= 0.5 THEN v_target_bonus := 20;
                WHEN v_prediction.target_percent <= 1.0 THEN v_target_bonus := 40;
                WHEN v_prediction.target_percent <= 1.5 THEN v_target_bonus := 70;
                ELSE v_target_bonus := 120;
            END CASE;
            v_new_streak := v_profile.streak + 1;
        ELSE
            v_target_bonus := 0;
            v_new_streak := 0; -- Target missed -> Streak Reset
        END IF;

        -- D. Streak Multipliers (Cyclic 0-5)
        IF v_new_streak >= 5 THEN v_streak_mult := 2.5;
        ELSIF v_new_streak = 4 THEN v_streak_mult := 2.0;
        ELSIF v_new_streak = 3 THEN v_streak_mult := 1.6;
        ELSIF v_new_streak = 2 THEN v_streak_mult := 1.3;
        ELSE v_streak_mult := 1.0;
        END IF;

        -- E. Final Math
        -- Profit = (Base Profit + Target Bonus) * StreakMult * LatePenalty * HouseEdge
        v_base_profit := (v_prediction.bet_amount * 0.8 * v_tf_mult) + v_target_bonus;
        v_final_profit := v_base_profit * v_streak_mult * v_late_mult * c_house_edge;
        v_payout := v_prediction.bet_amount + ROUND(v_final_profit);

        -- Cycle Reset after 5
        IF v_new_streak >= 5 THEN v_new_streak := 0; END IF;

        UPDATE profiles SET 
            points = points + v_payout, 
            streak = v_new_streak, 
            streak_count = GREATEST(COALESCE(streak_count, 0), v_new_streak),
            total_wins = COALESCE(total_wins, 0) + 1,
            total_games = COALESCE(total_games, 0) + 1
        WHERE id = v_prediction.user_id;
<<<<<<< Updated upstream:backups/src_backup_20260219_144005/supabase/apply_fairness_model.sql
=======

        -- F. Notifications Prep (WIN)
        v_notif_type := 'win';
        v_notif_title := v_prediction.asset_symbol || ' (' || v_prediction.timeframe || ') Result';
        v_reward_text := '+' || ROUND(v_final_profit) || ' pts';

        IF v_is_target_hit THEN
            v_notif_msg := 'Perfect! Direction + Target Hit! (' || v_reward_text || ')';
        ELSE
            v_notif_msg := 'Direction correct! Target missed. (' || v_reward_text || ')';
        END IF;

    ELSIF p_close_price = p_open_price THEN
        -- ND (Neutral / No Change)
        v_status := 'ND';
        v_payout := v_prediction.bet_amount;
        v_final_profit := 0;
        v_new_streak := v_profile.streak;
        
        UPDATE profiles SET 
            points = points + v_payout,
            total_games = COALESCE(total_games, 0) + 1 
        WHERE id = v_prediction.user_id;

        v_notif_type := 'info';
        v_notif_title := v_prediction.asset_symbol || ' (' || v_prediction.timeframe || ') Neutral';
        v_notif_msg := 'Price unchanged. Bet refunded.';

>>>>>>> Stashed changes:supabase/migrations/20260210162000_refine_notification_messages.sql
    ELSE
        -- LOSS
        v_status := 'LOSS';
        v_payout := 0;
        v_final_profit := -v_prediction.bet_amount;
        v_new_streak := 0;
        UPDATE profiles SET 
            streak = 0, 
            total_games = COALESCE(total_games, 0) + 1 
        WHERE id = v_prediction.user_id;
<<<<<<< Updated upstream:backups/src_backup_20260219_144005/supabase/apply_fairness_model.sql
=======

        v_notif_type := 'loss';
        v_notif_title := v_prediction.asset_symbol || ' (' || v_prediction.timeframe || ') Result';
        v_notif_msg := 'Prediction missed. Try again! (-' || v_prediction.bet_amount || ' pts)';
>>>>>>> Stashed changes:supabase/migrations/20260210162000_refine_notification_messages.sql
    END IF;

    -- Ensure streak column exists on predictions
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'predictions' AND column_name = 'streak') THEN
        ALTER TABLE predictions ADD COLUMN streak INTEGER DEFAULT 0;
    END IF;

    -- 4. Final Updates
    UPDATE predictions SET
        status = v_status,
        entry_price = p_open_price, -- Standardization
        close_price = p_close_price,
        payout = v_payout,
        profit = ROUND(v_final_profit),
        profit_loss = ROUND(v_final_profit),
        actual_change_percent = v_price_change_percent,
        is_target_hit = v_is_target_hit,
        streak = v_new_streak, -- Record streak at time of resolution
        resolved_at = now()
    WHERE id = p_id;

    RETURN json_build_object(
        'success', true, 
        'status', v_status, 
        'payout', v_payout,
        'is_late', v_late_mult < 1.0,
        'streak', v_new_streak
    );
END;
$$;
