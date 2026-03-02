
-- ==========================================================
-- 🔙 PRECISE DATABASE ROLLBACK TO FEBRUARY 17 STATE (v2)
-- ==========================================================

-- 1. [CLEANUP] Remove Feb 18+ Schema Changes
ALTER TABLE public.notifications DROP COLUMN IF EXISTS points_change;
DROP FUNCTION IF EXISTS public.get_top_leaders();
DROP FUNCTION IF EXISTS public.get_trending_assets();

-- 2. [CLEANUP] Safety check for activity_logs (Added on Feb 18)
-- If it exists, clean up 18th+ data. If not, ignore (as it shouldn't be there on Feb 17).
DO $$ 
BEGIN
    IF EXISTS (SELECT FROM pg_tables WHERE schemaname = 'public' AND tablename  = 'activity_logs') THEN
        DELETE FROM public.activity_logs WHERE created_at >= '2026-02-18 00:00:00+09';
    END IF;
END $$;

-- 3. [CLEANUP] Drop all overloads of submit_prediction to start clean
DO $$ 
DECLARE 
    r RECORD;
BEGIN
    FOR r IN (SELECT oid::regprocedure FROM pg_proc WHERE proname = 'submit_prediction' AND pronamespace = 'public'::regnamespace) LOOP
        EXECUTE 'DROP FUNCTION ' || r.oid::regprocedure;
    END LOOP;
END $$;

-- 4. [RESTORE] Restore submit_prediction to Feb 17 version (7 arguments)
-- Source: 20260206_fix_alignment.sql (Stable version used on Feb 17)
CREATE OR REPLACE FUNCTION public.submit_prediction(
    p_user_id UUID,
    p_asset_symbol TEXT,
    p_timeframe TEXT,
    p_direction TEXT,
    p_target_percent NUMERIC,
    p_entry_price NUMERIC,
    p_bet_amount INTEGER
)
RETURNS JSON
LANGUAGE plpgsql
SECURITY DEFINER
AS $function$
DECLARE
    v_current_points INTEGER;
    v_new_points INTEGER;
    v_candle_duration BIGINT;
    v_candle_close_at TIMESTAMP WITH TIME ZONE;
    v_prediction_id BIGINT;
BEGIN
    SELECT points INTO v_current_points FROM profiles WHERE id = p_user_id FOR UPDATE;

    IF v_current_points < p_bet_amount THEN
        RETURN json_build_object('success', false, 'error', 'Insufficient points');
    END IF;

    -- Calculate Alignment
    CASE 
        WHEN p_timeframe ~ '^\d+m$' THEN v_candle_duration := (regexp_replace(p_timeframe, '[^0-9]', '', 'g')::INTEGER) * 60;
        WHEN p_timeframe ~ '^\d+h$' THEN v_candle_duration := (regexp_replace(p_timeframe, '[^0-9]', '', 'g')::INTEGER) * 3600;
        WHEN p_timeframe ~ '^\d+d$' THEN v_candle_duration := (regexp_replace(p_timeframe, '[^0-9]', '', 'g')::INTEGER) * 86400;
        ELSE v_candle_duration := 900;
    END CASE;

    v_candle_close_at := to_timestamp(floor(extract(epoch from now()) / v_candle_duration) * v_candle_duration + v_candle_duration);

    INSERT INTO predictions (user_id, asset_symbol, timeframe, direction, target_percent, entry_price, bet_amount, status, candle_close_at)
    VALUES (p_user_id, p_asset_symbol, p_timeframe, p_direction, p_target_percent, p_entry_price, p_bet_amount, 'pending', v_candle_close_at)
    RETURNING id INTO v_prediction_id;

    UPDATE profiles SET points = points - p_bet_amount WHERE id = p_user_id RETURNING points INTO v_new_points;

    -- AUDIT LOG (Only if table exists, to avoid crashing if it was truly added on Feb 18)
    IF EXISTS (SELECT FROM pg_tables WHERE schemaname = 'public' AND tablename = 'activity_logs') THEN
        INSERT INTO activity_logs (user_id, action_type, asset_symbol, prediction_id, metadata)
        VALUES (p_user_id, 'BET', p_asset_symbol, v_prediction_id, json_build_object(
            'bet_amount', p_bet_amount,
            'entry_price', p_entry_price,
            'target_percent', p_target_percent,
            'timeframe', p_timeframe,
            'direction', p_direction,
            'candle_close_at', v_candle_close_at
        ));
    END IF;

    RETURN json_build_object('success', true, 'prediction_id', v_prediction_id, 'new_points', v_new_points);
END;
$function$;

-- 5. [CLEANUP] Drop all overloads of resolve_prediction_advanced
DO $$ 
DECLARE 
    r RECORD;
BEGIN
    FOR r IN (SELECT oid::regprocedure FROM pg_proc WHERE proname = 'resolve_prediction_advanced' AND pronamespace = 'public'::regnamespace) LOOP
        EXECUTE 'DROP FUNCTION ' || r.oid::regprocedure;
    END LOOP;
END $$;

-- 6. [RESTORE] Restore resolve_prediction_advanced to Feb 17 version (3 arguments)
-- Source: 20260216_fix_reward_formula.sql
CREATE OR REPLACE FUNCTION public.resolve_prediction_advanced(
    p_id bigint,
    p_close_price numeric,
    p_open_price numeric DEFAULT NULL
)
RETURNS JSON
LANGUAGE plpgsql
SECURITY DEFINER
AS $function$
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
    v_late_mult NUMERIC := 1.0; 
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
    IF v_open_price = 0 THEN v_price_change_percent := 0; ELSE v_price_change_percent := abs(v_price_change / v_open_price * 100); END IF;
    
    IF v_open_price = p_close_price THEN
        v_status := 'ND'; v_payout := v_prediction.bet_amount; v_profit_change := 0;
        v_new_streak := v_prediction.user_id; 
    ELSE
        v_is_dir_correct := (v_prediction.direction = 'UP' AND v_price_change > 0) OR (v_prediction.direction = 'DOWN' AND v_price_change < 0);
        v_is_target_hit := (v_price_change_percent >= v_prediction.target_percent);

        IF v_is_dir_correct THEN
            v_status := 'WIN';
            CASE 
                WHEN v_prediction.timeframe ~ '^\d+m$' THEN v_candle_duration := (regexp_replace(v_prediction.timeframe, '[^0-9]', '', 'g')::INTEGER) * 60;
                WHEN v_prediction.timeframe ~ '^\d+h$' THEN v_candle_duration := (regexp_replace(v_prediction.timeframe, '[^0-9]', '', 'g')::INTEGER) * 3600;
                WHEN v_prediction.timeframe ~ '^\d+d$' THEN v_candle_duration := (regexp_replace(v_prediction.timeframe, '[^0-9]', '', 'g')::INTEGER) * 86400;
                ELSE v_candle_duration := 900;
            END CASE;

            v_entry_offset_seconds := EXTRACT(EPOCH FROM (v_prediction.created_at - (v_prediction.candle_close_at - (v_candle_duration * interval '1 second'))));
            v_entry_ratio := v_entry_offset_seconds::numeric / v_candle_duration::numeric;

            IF v_entry_ratio < 0.33 THEN v_late_mult := 1.0;
            ELSIF v_entry_ratio < 0.66 THEN v_late_mult := 0.6;
            ELSIF v_entry_ratio < 0.90 THEN v_late_mult := 0.3;
            ELSE v_late_mult := 0.0; END IF;

            v_tf_mult := COALESCE((v_tf_mults->>v_prediction.timeframe)::numeric, 1.0);
            
            IF v_is_target_hit THEN
                SELECT (val->>'bonus')::int INTO v_target_bonus FROM jsonb_array_elements(v_target_bonuses) AS val WHERE (val->>'max')::numeric >= v_prediction.target_percent ORDER BY (val->>'max')::numeric ASC LIMIT 1;
                IF v_late_mult >= 1.0 THEN
                    SELECT streak + 1 INTO v_new_streak FROM profiles WHERE id = v_prediction.user_id;
                    v_streak_mult := COALESCE((v_streak_mults->>v_new_streak::text)::numeric, 1.0);
                ELSE
                    SELECT streak INTO v_new_streak FROM profiles WHERE id = v_prediction.user_id;
                    v_streak_mult := 1.0;
                END IF;
            ELSE
                v_target_bonus := 0; v_new_streak := 0; 
            END IF;

            v_profit_change := ROUND((v_prediction.bet_amount * v_base_profit_ratio * v_tf_mult * v_late_mult + v_target_bonus) * v_streak_mult * v_house_edge);
            v_payout := v_prediction.bet_amount + v_profit_change;
        ELSE
            v_status := 'LOSS'; v_payout := 0; v_profit_change := -v_prediction.bet_amount; v_new_streak := 0;
        END IF;
    END IF;
    
    update predictions set status = v_status, actual_price = p_close_price, entry_price = v_open_price, profit = v_profit_change, resolved_at = now() where id = p_id;
    update profiles set points = points + v_payout, total_games = total_games + 1, total_wins = total_wins + (CASE WHEN v_status = 'WIN' THEN 1 ELSE 0 END), streak = v_new_streak, total_earnings = total_earnings + v_profit_change where id = v_prediction.user_id;
    
    IF v_status = 'WIN' THEN v_notif_title := '✅ WIN: ' || v_prediction.asset_symbol; v_notif_msg := 'Earned ' || v_profit_change || ' pts. (' || v_status || ')';
    ELSIF v_status = 'LOSS' THEN v_notif_title := '❌ LOSS: ' || v_prediction.asset_symbol; v_notif_msg := 'Missed direction or target.';
    ELSE v_notif_title := 'Refund: No Change'; v_notif_msg := 'Stake returned.';
    END IF;

    INSERT INTO public.notifications (user_id, type, title, message, points_change, is_read) 
    VALUES (v_prediction.user_id, 'prediction_resolved', v_notif_title, v_notif_msg, v_profit_change, FALSE);

    IF EXISTS (SELECT FROM pg_tables WHERE schemaname = 'public' AND tablename = 'activity_logs') THEN
        INSERT INTO activity_logs (user_id, action_type, asset_symbol, prediction_id, metadata)
        VALUES (v_prediction.user_id, 'RESOLVE', v_prediction.asset_symbol, p_id, json_build_object(
            'status', v_status, 'profit', v_profit_change, 'late_mult', v_late_mult, 'target_hit', v_is_target_hit, 'streak', v_new_streak, 'entry_ratio', v_entry_ratio
        ));
    END IF;
    
    return json_build_object('success', true, 'status', v_status, 'profit', v_profit_change, 'late_mult', v_late_mult);
exception when others then
    return json_build_object('success', false, 'error', SQLERRM);
end;
$function$;
