
-- Final Resolution Logic Resolution (Hybrid Model: Direction Win + Target Bonus)
-- This aligns with the calculateReward logic in src/lib/rewards.ts

CREATE OR REPLACE FUNCTION public.resolve_prediction_advanced(
    p_id BIGINT,
    p_close_price NUMERIC,
    p_open_price NUMERIC DEFAULT NULL
)
RETURNS JSON LANGUAGE plpgsql SECURITY DEFINER AS $$
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
    v_new_streak_count INTEGER := 0;
    v_open_price NUMERIC;
    v_symbol_emoji TEXT;
BEGIN
    -- 1. Fetch data
    SELECT * INTO v_prediction FROM predictions WHERE id = p_id AND status = 'pending' FOR UPDATE;
    IF NOT FOUND THEN RETURN json_build_object('success', false, 'error', 'Already resolved'); END IF;
    
    SELECT * INTO v_profile FROM profiles WHERE id = v_prediction.user_id FOR UPDATE;

    v_open_price := COALESCE(p_open_price, v_prediction.entry_price);
    
    -- 2. Symbol Emoji
    v_symbol_emoji := CASE 
        WHEN v_prediction.asset_symbol ILIKE '%BTC%' THEN '₿'
        WHEN v_prediction.asset_symbol ILIKE '%ETH%' THEN 'Ξ'
        WHEN v_prediction.asset_symbol ILIKE '%SOL%' THEN '◎'
        ELSE '📈'
    END;

    -- 3. Determine Outcome
    v_price_change := p_close_price - v_open_price;
    v_price_change_percent := ABS(v_price_change / v_open_price * 100);
    
    v_is_dir_correct := (v_prediction.direction = 'UP' AND v_price_change > 0) OR (v_prediction.direction = 'DOWN' AND v_price_change < 0);
    v_is_target_hit := (v_price_change_percent >= v_prediction.target_percent);

    -- 4. Calculate Timeframe & Zone
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

    -- ratio = (created_at - (candle_close_at - v_tf_duration)) / v_tf_duration
    v_entry_ratio := (EXTRACT(EPOCH FROM v_prediction.created_at) - (EXTRACT(EPOCH FROM v_prediction.candle_close_at) - v_tf_duration)) / v_tf_duration;
    
    IF v_entry_ratio < 0.33 THEN v_late_mult := 1.0;
    ELSIF v_entry_ratio < 0.66 THEN v_late_mult := 0.6;
    ELSIF v_entry_ratio < 0.90 THEN v_late_mult := 0.3;
    ELSE v_late_mult := 0; END IF;

    -- 5. Logic
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

        -- Streak Bonus (Needs Green Zone AND Target Hit)
        -- This keeps streaks meaningful (only for high-quality predictions)
        IF v_late_mult = 1.0 AND v_is_target_hit THEN
            v_new_streak_count := v_profile.streak_count + 1;
            IF v_new_streak_count >= 2 THEN v_streak_bonus := v_streak_bonus + 3; END IF;
            
            -- Milestones
            IF v_new_streak_count = 3 THEN v_streak_bonus := v_streak_bonus + 20;
            ELSIF v_new_streak_count = 5 THEN v_streak_bonus := v_streak_bonus + 50;
            ELSIF v_new_streak_count = 7 THEN v_streak_bonus := v_streak_bonus + 100;
            ELSIF v_new_streak_count = 10 THEN v_streak_bonus := v_streak_bonus + 200;
            ELSIF v_new_streak_count = 15 THEN v_streak_bonus := v_streak_bonus + 500;
            END IF;
        ELSE
            -- Direction win is a WIN, but doesn't count towards/keep streak
            v_new_streak_count := 0;
        END IF;

        -- Final Calculation: (Bet*0.8 + Target + Streak) * TF * Late * Edge
        v_final_profit_pts := (v_prediction.bet_amount * 0.8 + v_target_bonus + v_streak_bonus) * v_tf_mult * v_late_mult * c_house_edge;
        v_payout := v_prediction.bet_amount + ROUND(v_final_profit_pts);
        
    ELSIF v_price_change = 0 THEN
        v_status := 'ND';
        v_payout := v_prediction.bet_amount; -- Refund
        v_final_profit_pts := 0;
        v_new_streak_count := 0;
    ELSE
        v_status := 'LOSS';
        v_payout := 0;
        v_final_profit_pts := -v_prediction.bet_amount;
        v_new_streak_count := 0;
    END IF;

    -- 6. Updates
    UPDATE profiles SET 
        points = points + v_payout, 
        streak_count = v_new_streak_count,
        total_games = total_games + 1,
        total_wins = total_wins + (CASE WHEN v_status = 'WIN' THEN 1 ELSE 0 END),
        total_earnings = total_earnings + ROUND(v_final_profit_pts)
    WHERE id = v_prediction.user_id;

    UPDATE predictions SET 
        status = v_status, 
        actual_price = p_close_price, 
        profit = ROUND(v_final_profit_pts), 
        resolved_at = now() 
    WHERE id = p_id;
    
    -- 7. Notification
    INSERT INTO notifications (user_id, type, title, message)
    VALUES (v_prediction.user_id, 'result', 
            CASE WHEN v_status = 'WIN' THEN '✅ WIN!' WHEN v_status = 'LOSS' THEN '❌ LOSS' ELSE '🤝 DRAW' END,
            format('%s %s result: %s (%s pts)', v_symbol_emoji, v_prediction.asset_symbol, v_status, ROUND(v_final_profit_pts)));

    RETURN json_build_object('success', true, 'status', v_status, 'profit', ROUND(v_final_profit_pts));
END;
$$;
