-- 🔔 Global English Localization (Final V2)
-- Migration: 20260210190000_translate_to_english.sql

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
    
    -- Notification Variables
    v_notif_title TEXT;
    v_notif_message TEXT;
    v_notif_type TEXT;
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

    -- 3. Calculate Rewards if Correct
    IF v_is_dir_correct THEN
        v_status := 'WIN';
        v_notif_type := 'win';
        
        -- Target Bonus
        IF v_is_target_hit AND v_prediction.target_percent > 0 THEN
            v_notif_message := 'Bullseye! Direction and target both smashed! 🎯';
            IF v_prediction.target_percent <= 0.5 THEN v_target_bonus := 8;
            ELSIF v_prediction.target_percent <= 1.0 THEN v_target_bonus := 16;
            ELSIF v_prediction.target_percent <= 1.5 THEN v_target_bonus := 24;
            ELSE v_target_bonus := 32;
            END IF;
        ELSE
            v_notif_message := 'Good call! You got the direction right. 💪';
        END IF;

        v_final_profit_pts := (v_prediction.bet_amount * 0.8 + v_target_bonus) * v_tf_mult * c_house_edge;
        v_payout := v_prediction.bet_amount + ROUND(v_final_profit_pts);
        v_new_streak := v_profile.streak + 1;
    ELSIF v_price_change = 0 THEN
        v_status := 'ND';
        v_notif_type := 'info';
        v_notif_message := 'Safe! No price change, points returned. 🛡️';
        v_payout := v_prediction.bet_amount;
        v_final_profit_pts := 0;
        v_new_streak := v_profile.streak;
    ELSE
        v_status := 'LOSS';
        v_notif_type := 'loss';
        v_notif_message := 'Unlucky! Stay sharp, you will nail the next one! 🍀';
        v_payout := 0;
        v_final_profit_pts := -v_prediction.bet_amount;
        v_new_streak := 0;
    END IF;

    -- 4. Final Updates
    UPDATE profiles SET points = points + v_payout, streak = v_new_streak WHERE id = v_prediction.user_id;
    UPDATE predictions SET 
        status = v_status, 
        actual_price = p_close_price, 
        entry_price = v_open_price, 
        profit = ROUND(v_final_profit_pts), 
        resolved_at = now() 
    WHERE id = p_id;
    
    -- English Title with Timeframe
    v_notif_title := format('%s (%s) Result', v_prediction.asset_symbol, v_prediction.timeframe);

    INSERT INTO notifications (user_id, type, title, message, points_change, prediction_id)
    VALUES (
        v_prediction.user_id, 
        v_notif_type, 
        v_notif_title, 
        format('%s (%+d pts)', v_notif_message, ROUND(v_final_profit_pts)),
        ROUND(v_final_profit_pts), 
        p_id
    );

    RETURN json_build_object('success', true, 'status', v_status, 'profit', ROUND(v_final_profit_pts));
END;
$$;
