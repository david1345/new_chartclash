-- 🛠️ COMPREHENSIVE SCHEMA FIX & RESOLUTION SYNC
-- Targets: Development Environment (Sync with Production Expectations)
-- Updated: 2026-02-10

BEGIN;

-- 1. Ensure Profiles Table has required columns
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS streak INTEGER DEFAULT 0;
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS total_wins INTEGER DEFAULT 0;
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS total_games INTEGER DEFAULT 0;
-- streak_count is assumed to exist as Max Streak

-- 2. Ensure Predictions Table has required columns
ALTER TABLE public.predictions ADD COLUMN IF NOT EXISTS close_price NUMERIC;
ALTER TABLE public.predictions ADD COLUMN IF NOT EXISTS actual_change_percent NUMERIC;
ALTER TABLE public.predictions ADD COLUMN IF NOT EXISTS is_target_hit BOOLEAN DEFAULT FALSE;
ALTER TABLE public.predictions ADD COLUMN IF NOT EXISTS profit_loss NUMERIC;
ALTER TABLE public.predictions ADD COLUMN IF NOT EXISTS payout NUMERIC;
ALTER TABLE public.predictions ADD COLUMN IF NOT EXISTS streak INTEGER DEFAULT 0; -- Streak at time of resolution
ALTER TABLE public.predictions ADD COLUMN IF NOT EXISTS entry_offset_seconds INTEGER DEFAULT 0;

-- 3. Re-Apply Refined Resolution RPC (v5.1)
-- Fixed to use correct column names and handle potential nulls
DROP FUNCTION IF EXISTS public.resolve_prediction_advanced(bigint, numeric, numeric);

CREATE OR REPLACE FUNCTION public.resolve_prediction_advanced(
    p_id BIGINT,
    p_close_price NUMERIC,
    p_open_price NUMERIC
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

    -- Notification Vars
    v_notif_title TEXT;
    v_notif_msg TEXT;
    v_notif_type TEXT;
    v_reward_text TEXT;
BEGIN
    -- 1. Fetch Data
    SELECT * INTO v_prediction FROM predictions WHERE id = p_id AND status = 'pending' FOR UPDATE;
    IF NOT FOUND THEN RETURN json_build_object('success', false, 'error', 'Not found or already resolved'); END IF;

    SELECT * INTO v_profile FROM profiles WHERE id = v_prediction.user_id FOR UPDATE;
    IF NOT FOUND THEN RETURN json_build_object('success', false, 'error', 'User profile not found'); END IF;

    -- 2. Outcome Determination
    -- Force set actual price in case it's zero or slightly off from prediction entry
    v_is_win := (v_prediction.direction = 'UP' AND p_close_price > p_open_price) OR 
                (v_prediction.direction = 'DOWN' AND p_close_price < p_open_price);
    
    IF p_open_price = 0 THEN
        v_price_change_percent := 0;
    ELSE
        v_price_change_percent := abs(((p_close_price - p_open_price) / p_open_price) * 100);
    END IF;
    
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

        -- B. Late Entry Penalty
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

        -- Threshold for penalty (approx 13% elapsed)
        IF COALESCE(v_prediction.entry_offset_seconds, 0) > (v_duration_seconds / 7.5) THEN
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
            v_new_streak := COALESCE(v_profile.streak, 0) + 1;
        ELSE
            v_target_bonus := 0;
            v_new_streak := 0; 
        END IF;

        -- D. Streak Multipliers
        IF v_new_streak >= 5 THEN v_streak_mult := 2.5;
        ELSIF v_new_streak = 4 THEN v_streak_mult := 2.0;
        ELSIF v_new_streak = 3 THEN v_streak_mult := 1.6;
        ELSIF v_new_streak = 2 THEN v_streak_mult := 1.3;
        ELSE v_streak_mult := 1.0;
        END IF;

        -- E. Final Math
        v_base_profit := (v_prediction.bet_amount * 0.8 * v_tf_mult) + v_target_bonus;
        v_final_profit := v_base_profit * v_streak_mult * v_late_mult * c_house_edge;
        v_payout := v_prediction.bet_amount + ROUND(v_final_profit);

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
        v_new_streak := COALESCE(v_profile.streak, 0);
        
        v_notif_type := 'info';
        v_notif_title := v_prediction.asset_symbol || ' (' || v_prediction.timeframe || ') Neutral';
        v_notif_msg := 'Price unchanged. Bet refunded.';

    ELSE
        -- LOSS
        v_status := 'LOSS';
        v_payout := 0;
        v_final_profit := -v_prediction.bet_amount;
        v_new_streak := 0;

        v_notif_type := 'loss';
        v_notif_title := v_prediction.asset_symbol || ' (' || v_prediction.timeframe || ') Result';
        v_notif_msg := 'Prediction missed. Try again! (-' || v_prediction.bet_amount || ' pts)';
    END IF;

    -- Update Profile (Points + Streak)
    UPDATE profiles SET 
        points = points + v_payout, 
        streak = v_new_streak, 
        streak_count = GREATEST(COALESCE(streak_count, 0), v_new_streak),
        total_wins = COALESCE(total_wins, 0) + (CASE WHEN v_status = 'WIN' THEN 1 ELSE 0 END),
        total_games = COALESCE(total_games, 0) + 1
    WHERE id = v_prediction.user_id;

    -- 4. Insert Notification
    INSERT INTO public.notifications (user_id, type, title, message, points_change, is_read)
    VALUES (v_prediction.user_id, v_notif_type, v_notif_title, v_notif_msg, ROUND(v_final_profit), FALSE);

    -- 5. Final Prediction Update
    UPDATE predictions SET
        status = v_status,
        -- Use actual_price if close_price exists, fallback if needed
        actual_price = p_close_price,
        close_price = p_close_price,
        entry_price = p_open_price,
        payout = v_payout,
        profit = ROUND(v_final_profit),
        profit_loss = ROUND(v_final_profit),
        actual_change_percent = v_price_change_percent,
        is_target_hit = v_is_target_hit,
        streak = v_new_streak,
        resolved_at = now()
    WHERE id = p_id;

    RETURN json_build_object(
        'success', true, 
        'status', v_status, 
        'payout', v_payout,
        'profit', ROUND(v_final_profit),
        'is_late', v_late_mult < 1.0,
        'streak', v_new_streak
    );
END;
$$;

COMMIT;
