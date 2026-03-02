-- 🚀 ROBUST FIX: Clean up all overloads and Restore Prediction Functionality
-- This script drops ALL versions of submit_prediction to avoid "best candidate function" errors.

DO $$ 
DECLARE 
    r RECORD;
BEGIN
    -- Drop every function named 'submit_prediction' regardless of arguments
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
AS $$
DECLARE
    v_current_points INTEGER;
    v_new_points INTEGER;
    v_candle_duration BIGINT;
    v_candle_close_at TIMESTAMP WITH TIME ZONE;
    v_prediction_id BIGINT;
BEGIN
    -- 1. Check & Lock Points
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

    -- 3. Insert Prediction
    INSERT INTO predictions (user_id, asset_symbol, timeframe, direction, target_percent, entry_price, bet_amount, status, candle_close_at)
    VALUES (p_user_id, p_asset_symbol, p_timeframe, p_direction, p_target_percent, p_entry_price, p_bet_amount, 'pending', v_candle_close_at)
    RETURNING id INTO v_prediction_id;

    -- 4. Deduct Points
    UPDATE profiles SET points = points - p_bet_amount WHERE id = p_user_id RETURNING points INTO v_new_points;

    -- Audit Log skipped to avoid "Table Not Found" error
    
    RETURN json_build_object('success', true, 'prediction_id', v_prediction_id, 'new_points', v_new_points);
END;
$$;
