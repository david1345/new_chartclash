
-- ==========================================================
-- 🔙 UNDO SYNC & RESTORE FEB 17 WORKING STATE
-- ==========================================================
-- This script reverses the "Sync to Prod" changes and 
-- restores the DB to the state where prediction worked.

BEGIN;

-- 1. [COLUMNS] Drop production-only columns from predictions
ALTER TABLE public.predictions 
    DROP COLUMN IF EXISTS close_price,
    DROP COLUMN IF EXISTS profit_loss,
    DROP COLUMN IF EXISTS payout,
    DROP COLUMN IF EXISTS actual_change_percent,
    DROP COLUMN IF EXISTS is_target_hit,
    DROP COLUMN IF EXISTS multipliers,
    DROP COLUMN IF EXISTS entry_offset_seconds;

-- 2. [COLUMNS] Drop production-only columns from notifications
ALTER TABLE public.notifications 
    DROP COLUMN IF EXISTS points_change;

-- 3. [TABLES] Drop tables that were added to match Production
DROP TABLE IF EXISTS public.shares CASCADE;
DROP TABLE IF EXISTS public.bookmarks CASCADE;
DROP TABLE IF EXISTS public.likes CASCADE;
DROP TABLE IF EXISTS public.comments CASCADE;
DROP TABLE IF EXISTS public.posts CASCADE;
DROP TABLE IF EXISTS public.activity_logs CASCADE;
DROP TABLE IF EXISTS public.system_configs CASCADE;
DROP TABLE IF EXISTS public.users CASCADE;

-- 4. [RPC] Drop production-specific RPC
DROP FUNCTION IF EXISTS public.resolve_prediction_v4(BIGINT, NUMERIC, NUMERIC);

-- 5. [RPC] Restore PRECISE 2/17 submit_prediction (7 arguments)
DO $$ 
DECLARE 
    r RECORD;
BEGIN
    FOR r IN (SELECT oid::regprocedure FROM pg_proc WHERE proname = 'submit_prediction' AND pronamespace = 'public'::regnamespace) LOOP
        EXECUTE 'DROP FUNCTION ' || r.oid::regprocedure;
    END LOOP;
END $$;

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
    -- 1. Check Points
    SELECT points INTO v_current_points FROM profiles WHERE id = p_user_id FOR UPDATE;
    IF v_current_points < p_bet_amount THEN
        RETURN json_build_object('success', false, 'error', 'Insufficient points');
    END IF;

    -- 2. Calculate Alignment
    CASE 
        WHEN p_timeframe ~ '^\d+m$' THEN v_candle_duration := (regexp_replace(p_timeframe, '[^0-9]', '', 'g')::INTEGER) * 60;
        WHEN p_timeframe ~ '^\d+h$' THEN v_candle_duration := (regexp_replace(p_timeframe, '[^0-9]', '', 'g')::INTEGER) * 3600;
        WHEN p_timeframe ~ '^\d+d$' THEN v_candle_duration := (regexp_replace(p_timeframe, '[^0-9]', '', 'g')::INTEGER) * 86400;
        ELSE v_candle_duration := 900;
    END CASE;

    v_candle_close_at := to_timestamp(floor(extract(epoch from now()) / v_candle_duration) * v_candle_duration + v_candle_duration);

    -- 3. Insert Prediction (Stable Feb 17 version)
    INSERT INTO predictions (user_id, asset_symbol, timeframe, direction, target_percent, entry_price, bet_amount, status, candle_close_at)
    VALUES (p_user_id, p_asset_symbol, p_timeframe, p_direction, p_target_percent, p_entry_price, p_bet_amount, 'pending', v_candle_close_at)
    RETURNING id INTO v_prediction_id;

    -- 4. Deduct Points
    UPDATE profiles SET points = points - p_bet_amount WHERE id = p_user_id RETURNING points INTO v_new_points;
    
    RETURN json_build_object('success', true, 'prediction_id', v_prediction_id, 'new_points', v_new_points);
END;
$function$;

-- 6. [RPC] Clean up resolve_prediction_advanced overloads
DO $$ 
DECLARE 
    r RECORD;
BEGIN
    FOR r IN (SELECT oid::regprocedure FROM pg_proc WHERE proname = 'resolve_prediction_advanced' AND pronamespace = 'public'::regnamespace) LOOP
        EXECUTE 'DROP FUNCTION ' || r.oid::regprocedure;
    END LOOP;
END $$;

COMMIT;
