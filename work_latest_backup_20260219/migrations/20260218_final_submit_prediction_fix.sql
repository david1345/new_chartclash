
-- 1. DROP ALL POSSIBLE OVERLOADS of submit_prediction
-- This ensures there is NO ambiguity when calling the function.
DO $$ 
DECLARE 
    r RECORD;
BEGIN
    FOR r IN (
        SELECT n.nspname, p.proname, pg_get_function_identity_arguments(p.oid) as args
        FROM pg_proc p
        JOIN pg_namespace n ON p.pronamespace = n.oid
        WHERE p.proname = 'submit_prediction' 
          AND n.nspname = 'public'
    ) LOOP
        EXECUTE 'DROP FUNCTION public.submit_prediction(' || r.args || ')';
    END LOOP;
END $$;

-- 2. CREATE THE UNIFIED VERSION
-- This version handles all current requirements: points deduction, candle alignment, opinions, and channels.
CREATE OR REPLACE FUNCTION public.submit_prediction(
    p_user_id UUID,
    p_asset_symbol TEXT,
    p_timeframe TEXT,
    p_direction TEXT,
    p_target_percent NUMERIC,
    p_entry_price NUMERIC,
    p_bet_amount INTEGER,
    p_is_opinion BOOLEAN DEFAULT FALSE,
    p_channel TEXT DEFAULT 'main'
)
RETURNS SETOF public.predictions
LANGUAGE plpgsql
SECURITY DEFINER
AS $function$
DECLARE
    v_candle_duration INTEGER;
    v_round_start TIMESTAMP WITH TIME ZONE;
    v_candle_close TIMESTAMP WITH TIME ZONE;
    v_prediction_id BIGINT;
BEGIN
    -- 1. Validate Points (Only for real bets, not pure opinions if desired, 
    -- but usually opinions still have a bet amount or are just 0 bet)
    IF p_bet_amount > 0 THEN
        IF NOT EXISTS (
            SELECT 1 FROM public.profiles 
            WHERE id = p_user_id AND points >= p_bet_amount
        ) THEN
            RAISE EXCEPTION 'Insufficient points';
        END IF;

        -- Deduct Points
        UPDATE public.profiles 
        SET points = points - p_bet_amount 
        WHERE id = p_user_id;
    END IF;

    -- 2. Calculate Candle Alignment (Backend Alignment for Fairness)
    -- This logic derives the candle_close_at based on the current time and timeframe.
    CASE 
        WHEN p_timeframe ~ '^\d+m$' THEN 
            v_candle_duration := (regexp_replace(p_timeframe, '[^0-9]', '', 'g')::INTEGER) * 60;
        WHEN p_timeframe ~ '^\d+h$' THEN 
            v_candle_duration := (regexp_replace(p_timeframe, '[^0-9]', '', 'g')::INTEGER) * 3600;
        WHEN p_timeframe ~ '^\d+d$' THEN 
            v_candle_duration := (regexp_replace(p_timeframe, '[^0-9]', '', 'g')::INTEGER) * 86400;
        ELSE 
            v_candle_duration := 900; -- Default 15m
    END CASE;

    -- OpenTime = Current Time floored to duration
    v_round_start := to_timestamp(floor(extract(epoch from now()) / v_candle_duration) * v_candle_duration);
    v_candle_close := v_round_start + (v_candle_duration * interval '1 second');

    -- 3. Insert Prediction
    INSERT INTO public.predictions (
        user_id,
        asset_symbol,
        timeframe,
        direction,
        target_percent,
        entry_price,
        bet_amount,
        status,
        is_opinion,
        channel,
        candle_close_at,
        created_at
    )
    VALUES (
        p_user_id,
        p_asset_symbol,
        p_timeframe,
        p_direction,
        p_target_percent,
        p_entry_price,
        p_bet_amount,
        'pending',
        p_is_opinion,
        COALESCE(p_channel, 'main'),
        v_candle_close,
        NOW()
    )
    RETURNING id INTO v_prediction_id;

    -- 4. Audit Log (Optionally, if activity_logs table exists)
    -- INSERT INTO public.activity_logs (user_id, action_type, asset_symbol, prediction_id)
    -- VALUES (p_user_id, 'SUBMIT', p_asset_symbol, v_prediction_id);

    -- 5. Return the created prediction
    RETURN QUERY SELECT * FROM public.predictions WHERE id = v_prediction_id;
END;
$function$;
