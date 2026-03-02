-- [CRITICAL FIX] resolve_prediction_advanced: 보상 수식 오류 및 감쇠 로직(Fairness Model) 반영
CREATE OR REPLACE FUNCTION public.resolve_prediction_advanced(
    p_id bigint,
    p_close_price numeric,
    p_open_price numeric DEFAULT NULL
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
    v_is_dir_correct BOOLEAN;
    v_is_target_hit BOOLEAN;
    
    -- Configs
    v_house_edge NUMERIC;
    v_base_profit_ratio NUMERIC;
    v_tf_mults JSONB;
    v_target_bonuses JSONB;
    v_streak_mults JSONB;
    
    -- Calculation Variables
    v_tf_mult NUMERIC := 1.0;
    v_late_mult NUMERIC := 1.0; -- Fairness Model Multiplier
    v_target_bonus INTEGER := 0;
    v_streak_mult NUMERIC := 1.0;
    v_profit_change INTEGER;
    v_payout INTEGER := 0;
    v_new_streak INTEGER;
    v_open_price NUMERIC;
    v_candle_duration INTEGER;
    v_entry_offset_seconds INTEGER;
    v_entry_ratio NUMERIC;

    -- Notification vars
    v_notif_title TEXT;
    v_notif_msg TEXT;
begin
    -- 1. Get Prediction
    select * into v_prediction from predictions where id = p_id and status = 'pending' for update;
    if not found then return json_build_object('success', false, 'error', 'Already resolved'); end if;
    
    -- 2. Fetch System Configs
    SELECT (value->>0)::numeric INTO v_house_edge FROM system_configs WHERE key = 'house_edge';
    SELECT (value->>0)::numeric INTO v_base_profit_ratio FROM system_configs WHERE key = 'base_profit_ratio';
    SELECT value INTO v_tf_mults FROM system_configs WHERE key = 'tf_multipliers';
    SELECT value INTO v_target_bonuses FROM system_configs WHERE key = 'target_bonuses';
    SELECT value INTO v_streak_mults FROM system_configs WHERE key = 'streak_multipliers';
    
    v_open_price := COALESCE(p_open_price, v_prediction.entry_price);

    -- 3. Calculate Results
    v_price_change := p_close_price - v_open_price;
    IF v_open_price = 0 THEN 
        v_price_change_percent := 0; 
    ELSE 
        v_price_change_percent := abs(v_price_change / v_open_price * 100); 
    END IF;
    
    IF v_open_price = p_close_price THEN
        v_status := 'ND'; v_payout := v_prediction.bet_amount; v_profit_change := 0;
        -- Keep current streak
        SELECT streak INTO v_new_streak FROM profiles WHERE id = v_prediction.user_id;
    ELSE
        -- Direction & Target logic
        v_is_dir_correct := (v_prediction.direction = 'UP' AND v_price_change > 0) OR (v_prediction.direction = 'DOWN' AND v_price_change < 0);
        v_is_target_hit := (v_price_change_percent >= v_prediction.target_percent);

        IF v_is_dir_correct THEN
            v_status := 'WIN';
            
            -- [FAIRNESS MODEL] Calculate Late Entry Multiplier
            CASE 
                WHEN v_prediction.timeframe ~ '^\d+m$' THEN v_candle_duration := (regexp_replace(v_prediction.timeframe, '[^0-9]', '', 'g')::INTEGER) * 60;
                WHEN v_prediction.timeframe ~ '^\d+h$' THEN v_candle_duration := (regexp_replace(v_prediction.timeframe, '[^0-9]', '', 'g')::INTEGER) * 3600;
                WHEN v_prediction.timeframe ~ '^\d+d$' THEN v_candle_duration := (regexp_replace(v_prediction.timeframe, '[^0-9]', '', 'g')::INTEGER) * 86400;
                ELSE v_candle_duration := 900;
            END CASE;

            -- How many seconds after candle start was this bet placed?
            v_entry_offset_seconds := EXTRACT(EPOCH FROM (v_prediction.created_at - (v_prediction.candle_close_at - (v_candle_duration * interval '1 second'))));
            v_entry_ratio := v_entry_offset_seconds::numeric / v_candle_duration::numeric;

            IF v_entry_ratio < 0.33 THEN v_late_mult := 1.0;
            ELSIF v_entry_ratio < 0.66 THEN v_late_mult := 0.6;
            ELSIF v_entry_ratio < 0.90 THEN v_late_mult := 0.3;
            ELSE v_late_mult := 0.0; END IF;

            -- Apply TF Multiplier
            v_tf_mult := COALESCE((v_tf_mults->>v_prediction.timeframe)::numeric, 1.0);
            
            -- [FIX] Only calculate Target Bonus if actually hit
            IF v_is_target_hit THEN
                SELECT (val->>'bonus')::int INTO v_target_bonus 
                FROM jsonb_array_elements(v_target_bonuses) AS val 
                WHERE (val->>'max')::numeric >= v_prediction.target_percent 
                ORDER BY (val->>'max')::numeric ASC LIMIT 1;
                
                -- [FIX] Only increment streak if in GREEN ZONE (Early Entry)
                IF v_late_mult >= 1.0 THEN
                    SELECT streak + 1 INTO v_new_streak FROM profiles WHERE id = v_prediction.user_id;
                    v_streak_mult := COALESCE((v_streak_mults->>v_new_streak::text)::numeric, 1.0);
                ELSE
                    -- Keep current streak but no multiplier boost for late entries
                    SELECT streak INTO v_new_streak FROM profiles WHERE id = v_prediction.user_id;
                    v_streak_mult := 1.0;
                END IF;
            ELSE
                v_target_bonus := 0;
                v_new_streak := 0; -- Reset streak on target miss
            END IF;

            -- Final Payout Calculation
            -- Formula: ROUND((Bet * Ratio * TF * LateMult + Bonus) * StreakMult * HouseEdge)
            v_profit_change := ROUND((v_prediction.bet_amount * v_base_profit_ratio * v_tf_mult * v_late_mult + v_target_bonus) * v_streak_mult * v_house_edge);
            v_payout := v_prediction.bet_amount + v_profit_change;
        ELSE
            v_status := 'LOSS'; v_payout := 0; v_profit_change := -v_prediction.bet_amount; v_new_streak := 0;
        END IF;
    END IF;
    
    -- 4. Update Tables
    UPDATE predictions 
    SET status = v_status, 
        actual_price = p_close_price, 
        entry_price = v_open_price, 
        profit = v_profit_change, 
        resolved_at = now() 
    WHERE id = p_id;

    UPDATE profiles 
    SET points = points + v_payout, 
        total_games = total_games + 1, 
        total_wins = total_wins + (CASE WHEN v_status = 'WIN' THEN 1 ELSE 0 END), 
        streak = v_new_streak, 
        total_earnings = total_earnings + v_profit_change 
    WHERE id = v_prediction.user_id;
    
    -- 5. Create Notification
    IF v_status = 'WIN' THEN 
        v_notif_title := '✅ WIN: ' || v_prediction.asset_symbol; 
        v_notif_msg := 'Earned ' || v_profit_change || ' pts. (' || v_status || ')';
    ELSIF v_status = 'LOSS' THEN 
        v_notif_title := '❌ LOSS: ' || v_prediction.asset_symbol; 
        v_notif_msg := 'Missed direction or target.';
    ELSE 
        v_notif_title := 'Refund: No Change'; 
        v_notif_msg := 'Stake returned.';
    END IF;

    INSERT INTO public.notifications (user_id, type, title, message, points_change, is_read) 
    VALUES (v_prediction.user_id, 'prediction_resolved', v_notif_title, v_notif_msg, v_profit_change, FALSE);

    -- 6. Audit Log
    INSERT INTO activity_logs (user_id, action_type, asset_symbol, prediction_id, metadata)
    VALUES (v_prediction.user_id, 'RESOLVE', v_prediction.asset_symbol, p_id, json_build_object(
        'status', v_status, 
        'profit', v_profit_change, 
        'late_mult', v_late_mult, 
        'target_hit', v_is_target_hit, 
        'streak', v_new_streak,
        'entry_ratio', v_entry_ratio
    ));
    
    RETURN json_build_object('success', true, 'status', v_status, 'profit', v_profit_change, 'late_mult', v_late_mult);
exception when others then
    return json_build_object('success', false, 'error', SQLERRM);
end;
$$;
