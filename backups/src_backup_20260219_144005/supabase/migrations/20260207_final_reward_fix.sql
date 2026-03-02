-- Final Reward System Implementation (Hybrid Streak Bonus + Balanced Economy)

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
    v_target_bonus INTEGER := 0;
    v_streak_bonus INTEGER := 0;
    v_final_profit_pts NUMERIC := 0;
    v_payout INTEGER := 0;
    v_tf_mult NUMERIC;
    v_tf_duration BIGINT;
    v_entry_ratio NUMERIC;
    v_late_mult NUMERIC := 1.0;
    c_house_edge NUMERIC := 0.95;
    v_new_streak INTEGER := 0;
    v_open_price NUMERIC;
BEGIN
    SELECT * INTO v_prediction FROM predictions WHERE id = p_id AND status = 'pending' FOR UPDATE;
    IF NOT FOUND THEN RETURN json_build_object('success', false, 'error', 'Already resolved'); END IF;
    
    v_open_price := COALESCE(p_open_price, v_prediction.entry_price);
    SELECT * INTO v_profile FROM profiles WHERE id = v_prediction.user_id FOR UPDATE;

    -- 1. Determine if prediction is correct
    v_price_change := p_close_price - v_open_price;
    v_price_change_percent := abs(v_price_change / v_open_price * 100);
    v_is_dir_correct := (v_prediction.direction = 'UP' AND v_price_change > 0) OR (v_prediction.direction = 'DOWN' AND v_price_change < 0);
    v_is_target_hit := (v_price_change_percent >= v_prediction.target_percent);

    -- 2. Calculate Timeframe Duration & Multiplier
    CASE v_prediction.timeframe 
        WHEN '1m' THEN v_tf_duration := 60; v_tf_mult := 1.0;
        WHEN '5m' THEN v_tf_duration := 300; v_tf_mult := 1.0;
        WHEN '15m' THEN v_tf_duration := 900; v_tf_mult := 1.0;
        WHEN '30m' THEN v_tf_duration := 1800; v_tf_mult := 1.2;
        WHEN '1h' THEN v_tf_duration := 3600; v_tf_mult := 1.5;
        WHEN '4h' THEN v_tf_duration := 14400; v_tf_mult := 2.2;
        WHEN '1d' THEN v_tf_duration := 86400; v_tf_mult := 3.0;
        ELSE v_tf_duration := 900; v_tf_mult := 1.0;
    END CASE;

    -- 3. Calculate Late Entry Multiplier (Zone)
    -- ratio = (created_at - (candle_close_at - v_tf_duration)) / v_tf_duration
    v_entry_ratio := (extract(epoch from v_prediction.created_at) - (extract(epoch from v_prediction.candle_close_at) - v_tf_duration)) / v_tf_duration;
    
    IF v_entry_ratio < 0.33 THEN v_late_mult := 1.0;
    ELSIF v_entry_ratio < 0.66 THEN v_late_mult := 0.6;
    ELSIF v_entry_ratio < 0.90 THEN v_late_mult := 0.3;
    ELSE v_late_mult := 0; END IF;

    -- 4. Calculate Rewards if Correct
    IF v_is_dir_correct THEN
        v_status := 'WIN';
        
        -- Target Bonus
        IF v_is_target_hit AND v_prediction.target_percent > 0 THEN
            IF v_prediction.target_percent <= 0.5 THEN v_target_bonus := 8;
            ELSIF v_prediction.target_percent <= 1.0 THEN v_target_bonus := 16;
            ELSIF v_prediction.target_percent <= 1.5 THEN v_target_bonus := 24;
            ELSE v_target_bonus := 32;
            END IF;
        END IF;

        -- Streak Logic (Strict: Green Zone AND Target Hit required)
        IF v_late_mult = 1.0 AND v_is_target_hit THEN
            v_new_streak := v_profile.streak + 1;
            
            -- Streak Bonus (Option C: Hybrid)
            IF v_new_streak >= 2 THEN
                v_streak_bonus := v_streak_bonus + 3; -- Continuous
            END IF;
            
            -- Milestone
            IF v_new_streak = 3 THEN v_streak_bonus := v_streak_bonus + 20;
            ELSIF v_new_streak = 5 THEN v_streak_bonus := v_streak_bonus + 50;
            ELSIF v_new_streak = 7 THEN v_streak_bonus := v_streak_bonus + 100;
            ELSIF v_new_streak = 10 THEN v_streak_bonus := v_streak_bonus + 200;
            ELSIF v_new_streak = 15 THEN v_streak_bonus := v_streak_bonus + 500;
            END IF;
        ELSE
            -- Any other case (Late entry OR Missed Target) resets streak
            v_new_streak := 0;
        END IF;

        -- Final Calculation: (Bet*0.8 + Target + Streak) * TF * Late * Edge
        v_final_profit_pts := (v_prediction.bet_amount * 0.8 + v_target_bonus + v_streak_bonus) * v_tf_mult * v_late_mult * c_house_edge;
        v_payout := v_prediction.bet_amount + ROUND(v_final_profit_pts);
    ELSE
        v_status := 'LOSS';
        v_payout := 0;
        v_final_profit_pts := -v_prediction.bet_amount;
        v_new_streak := 0;
    END IF;

    -- 5. Final Updates
    UPDATE profiles SET points = points + v_payout, streak = v_new_streak WHERE id = v_prediction.user_id;
    UPDATE predictions SET 
        status = v_status, 
        actual_price = p_close_price, 
        entry_price = v_open_price, 
        profit = ROUND(v_final_profit_pts), 
        resolved_at = now() 
    WHERE id = p_id;
    
    INSERT INTO notifications (user_id, type, message, prediction_id)
    VALUES (v_prediction.user_id, 'prediction_resolved', format('%s: %s (%s pts)', v_prediction.asset_symbol, v_status, ROUND(v_final_profit_pts)), p_id);

    -- Audit Log
    INSERT INTO activity_logs (user_id, action_type, asset_symbol, prediction_id, metadata)
    VALUES (v_prediction.user_id, 'RESOLVE', v_prediction.asset_symbol, p_id, json_build_object(
        'status', v_status,
        'profit', ROUND(v_final_profit_pts),
        'payout', v_payout,
        'streak', v_new_streak,
        'tf_mult', v_tf_mult,
        'late_mult', v_late_mult,
        'target_bonus', v_target_bonus,
        'streak_bonus', v_streak_bonus
    ));

    RETURN json_build_object('success', true, 'status', v_status, 'profit', ROUND(v_final_profit_pts));
END;
$$;
