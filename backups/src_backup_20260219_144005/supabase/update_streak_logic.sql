-- Economy V3.1: Cyclic Streak Logic (0-5)
-- Goal: After hitting 5 consecutive perfect wins (Direction + Target), reset to 0.

DROP FUNCTION IF EXISTS public.resolve_prediction_advanced(bigint, numeric, numeric);

CREATE OR REPLACE FUNCTION public.resolve_prediction_advanced(
    p_id BIGINT,
    p_close_price NUMERIC,
    p_crowd_multiplier NUMERIC DEFAULT 1.0
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
    
    -- Status
    v_status TEXT;
    v_is_dir_correct BOOLEAN;
    v_is_target_hit BOOLEAN;
    
    -- Calculation Variables
    v_direction_profit NUMERIC := 0;
    v_target_bonus INTEGER := 0;
    v_base_profit NUMERIC := 0;
    v_final_profit NUMERIC := 0;
    v_payout INTEGER := 0;
    
    -- Multipliers
    v_tf_mult NUMERIC;
    v_streak_mult NUMERIC;
    c_house_edge NUMERIC := 0.95;
    
    v_new_streak INTEGER;
BEGIN
    -- 1. Fetch Prediction
    SELECT * INTO v_prediction FROM predictions WHERE id = p_id AND status = 'pending' FOR UPDATE;
    
    IF NOT FOUND THEN
        RETURN json_build_object('success', false, 'error', 'Prediction not found or already resolved');
    END IF;

    -- 2. Fetch Profile
    SELECT * INTO v_profile FROM profiles WHERE id = v_prediction.user_id FOR UPDATE;

    -- 3. Calculate Changes
    v_price_change := p_close_price - v_prediction.entry_price;
    
    IF v_prediction.entry_price = 0 THEN
        v_price_change_percent := 0;
    ELSE
        v_price_change_percent := abs(v_price_change / v_prediction.entry_price * 100);
    END IF;

    -- 4. Outcome Determination
    IF v_prediction.entry_price = p_close_price THEN
        -- [NO DECISION]
        v_status := 'ND';
        v_payout := v_prediction.bet_amount;
        v_final_profit := 0;
        v_new_streak := v_profile.streak;
        
    ELSE
        -- Check Direction
        v_is_dir_correct := (v_prediction.direction = 'UP' AND v_price_change > 0) OR (v_prediction.direction = 'DOWN' AND v_price_change < 0);
        
        -- Check Target
        v_is_target_hit := (v_price_change_percent >= v_prediction.target_percent);

        IF v_is_dir_correct THEN
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
                ELSE v_tf_mult := 1.2;
            END CASE;
            
            v_direction_profit := v_prediction.bet_amount * 0.8 * v_tf_mult;

            -- B. Target Bonus & Streak Increment
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
                v_new_streak := 0; -- Reset streak if target missed
            END IF;

            v_base_profit := v_direction_profit + v_target_bonus;

            -- C. Streak Multiplier & Cyclic Reset (0-5)
            IF v_new_streak >= 5 THEN 
                v_streak_mult := 2.5; -- Max reward level
                v_new_streak := 0;    -- Reset for next cycle after paying max bonus
            ELSIF v_new_streak = 4 THEN v_streak_mult := 2.0;
            ELSIF v_new_streak = 3 THEN v_streak_mult := 1.6;
            ELSIF v_new_streak = 2 THEN v_streak_mult := 1.3;
            ELSE v_streak_mult := 1.0;
            END IF;

            -- D. Final Payout Calculation
            v_final_profit := v_base_profit * v_streak_mult * c_house_edge;
            v_payout := v_prediction.bet_amount + ROUND(v_final_profit);

        ELSE
            -- [LOSS]
            v_status := 'LOSS';
            v_payout := 0;
            v_final_profit := -v_prediction.bet_amount;
            v_new_streak := 0;
        END IF;
    END IF;

    -- 5. Update DB
    UPDATE profiles SET points = points + v_payout, streak = v_new_streak WHERE id = v_prediction.user_id;

    UPDATE predictions 
    SET status = v_status, 
        actual_price = p_close_price, 
        profit = ROUND(v_final_profit), 
        resolved_at = now() 
    WHERE id = p_id;

    RETURN json_build_object(
        'success', true, 
        'status', v_status,
        'payout', v_payout,
        'profit', ROUND(v_final_profit),
        'streak', v_new_streak
    );
END;
$$;
