INSERT INTO public.system_settings (key, value, description)
VALUES 
    ('house_edge', '0.995', 'Platform payout multiplier (0.5% fee)'),
    ('base_profit_ratio', '0.8', 'Base profit ratio (Win = 80% of bet)'),
    ('tf_multipliers', '{"1m": 1.0, "5m": 1.0, "15m": 1.0, "30m": 1.2, "1h": 1.5, "4h": 2.2, "1d": 3.0}', 'Timeframe-based multipliers'),
    ('target_bonuses', '[{"max": 0.5, "bonus": 8}, {"max": 1.0, "bonus": 16}, {"max": 1.5, "bonus": 24}, {"max": 99.0, "bonus": 32}]', 'Target percentage bonuses'),
    ('streak_milestones', '[{"count": 3, "bonus": 20}, {"count": 5, "bonus": 50}, {"count": 7, "bonus": 100}, {"count": 10, "bonus": 200}, {"count": 15, "bonus": 500}]', 'Streak milestone bonuses')
ON CONFLICT (key) DO UPDATE SET value = EXCLUDED.value;

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
    
    -- Configs (system_settings)
    v_house_edge NUMERIC;
    v_base_ratio NUMERIC;
    v_tf_mults JSONB;
    v_target_bonuses JSONB;
    v_streak_milestones JSONB;
    
    v_tf_mult NUMERIC := 1.0;
    v_late_mult NUMERIC := 1.0; 
    v_target_bonus INTEGER := 0;
    v_streak_bonus INTEGER := 0;
    v_profit_change INTEGER;
    v_payout INTEGER := 0;
    v_new_streak INTEGER;
    v_old_streak INTEGER;
    v_open_price NUMERIC;
    v_candle_duration INTEGER;
    v_entry_offset_seconds INTEGER;
    v_entry_ratio NUMERIC;
    v_is_streak_incrementable BOOLEAN := FALSE;
begin
    -- 1. Get Prediction
    select * into v_prediction from predictions where id = p_id and status = 'pending' for update;
    if not found then return json_build_object('success', false, 'error', 'Already resolved'); end if;
    
    -- 2. Fetch Configs
    SELECT (value->>0)::numeric INTO v_house_edge FROM system_settings WHERE key = 'house_edge';
    SELECT (value->>0)::numeric INTO v_base_ratio FROM system_settings WHERE key = 'base_profit_ratio';
    SELECT value INTO v_tf_mults FROM system_settings WHERE key = 'tf_multipliers';
    SELECT value INTO v_target_bonuses FROM system_settings WHERE key = 'target_bonuses';
    SELECT value INTO v_streak_milestones FROM system_settings WHERE key = 'streak_milestones';
    
    v_open_price := COALESCE(p_open_price, v_prediction.entry_price);
    v_price_change := p_close_price - v_open_price;
    IF v_open_price = 0 THEN v_price_change_percent := 0; ELSE v_price_change_percent := abs(v_price_change / v_open_price * 100); END IF;
    
    IF v_open_price = p_close_price THEN
        v_status := 'ND'; v_payout := v_prediction.bet_amount; v_profit_change := 0;
        SELECT streak INTO v_new_streak FROM profiles WHERE id = v_prediction.user_id;
    ELSE
        v_is_dir_correct := (v_prediction.direction = 'UP' AND v_price_change > 0) OR (v_prediction.direction = 'DOWN' AND v_price_change < 0);
        v_is_target_hit := (v_price_change_percent >= v_prediction.target_percent);

        IF v_is_dir_correct THEN
            v_status := 'WIN';
            
            -- [ZONE CALC]
            CASE 
                WHEN v_prediction.timeframe ~ '^\d+m$' THEN v_candle_duration := (regexp_replace(v_prediction.timeframe, '[^0-9]', '', 'g')::INTEGER) * 60;
                WHEN v_prediction.timeframe ~ '^\d+h$' THEN v_candle_duration := (regexp_replace(v_prediction.timeframe, '[^0-9]', '', 'g')::INTEGER) * 3600;
                WHEN v_prediction.timeframe ~ '^\d+d$' THEN v_candle_duration := (regexp_replace(v_prediction.timeframe, '[^0-9]', '', 'g')::INTEGER) * 86400;
                ELSE v_candle_duration := 900;
            END CASE;
            v_entry_offset_seconds := EXTRACT(EPOCH FROM (v_prediction.created_at - (v_prediction.candle_close_at - (v_candle_duration * interval '1 second'))));
            v_entry_ratio := v_entry_offset_seconds::numeric / v_candle_duration::numeric;
            
            IF v_entry_ratio < 0.33 THEN 
                v_late_mult := 1.0; v_is_streak_incrementable := TRUE;
            ELSIF v_entry_ratio < 0.66 THEN 
                v_late_mult := 0.6;
            ELSIF v_entry_ratio < 0.90 THEN 
                v_late_mult := 0.3;
            ELSE 
                v_late_mult := 0.0; 
            END IF;

            v_tf_mult := COALESCE((v_tf_mults->>v_prediction.timeframe)::numeric, 1.0);
            
            -- Streak Logic
            SELECT streak INTO v_old_streak FROM profiles WHERE id = v_prediction.user_id;
            IF v_is_streak_incrementable AND v_prediction.target_percent > 0 THEN
                v_new_streak := v_old_streak + 1;
            ELSE
                v_new_streak := v_old_streak;
            END IF;

            -- [BONUSES]
            IF v_new_streak >= 2 THEN v_streak_bonus := 3; END IF;
            
            -- Milestone Bonus (if incremented)
            IF v_new_streak > v_old_streak THEN
                DECLARE v_m_bonus INTEGER;
                BEGIN
                    SELECT (val->>'bonus')::int INTO v_m_bonus FROM jsonb_array_elements(v_streak_milestones) AS val WHERE (val->>'count')::int = v_new_streak;
                    IF FOUND THEN v_streak_bonus := v_streak_bonus + v_m_bonus; END IF;
                END;
            END IF;

            -- Target Bonus
            IF v_is_target_hit THEN
                SELECT (val->>'bonus')::int INTO v_target_bonus FROM jsonb_array_elements(v_target_bonuses) AS val WHERE (val->>'max')::numeric >= v_prediction.target_percent ORDER BY (val->>'max')::numeric ASC LIMIT 1;
            END IF;

            -- [FINAL CALC] (Matching src/lib/rewards.ts)
            v_profit_change := ROUND(((v_prediction.bet_amount * v_base_ratio) + COALESCE(v_target_bonus,0) + v_streak_bonus) * v_tf_mult * v_late_mult * v_house_edge);
            v_payout := v_prediction.bet_amount + v_profit_change;
        ELSE
            v_status := 'LOSS'; v_payout := 0; v_profit_change := -v_prediction.bet_amount; v_new_streak := 0;
        END IF;
    END IF;
    
    update predictions set status = v_status, actual_price = p_close_price, entry_price = v_open_price, profit = v_profit_change, resolved_at = now() where id = p_id;
    update profiles set points = points + v_payout, total_games = total_games + 1, total_wins = total_wins + (CASE WHEN v_status = 'WIN' THEN 1 ELSE 0 END), streak = v_new_streak, total_earnings = total_earnings + v_profit_change where id = v_prediction.user_id;
    
    INSERT INTO public.notifications (user_id, type, title, message, points_change, is_read) 
    VALUES (v_prediction.user_id, 'prediction_resolved', 'Prediction Resolved', format('%s prediction: %s (%s pts)', v_prediction.asset_symbol, v_status, v_profit_change), v_profit_change, FALSE);

    return json_build_object('success', true, 'status', v_status, 'profit', v_profit_change);
exception when others then
    return json_build_object('success', false, 'error', SQLERRM);
end;
$$;
