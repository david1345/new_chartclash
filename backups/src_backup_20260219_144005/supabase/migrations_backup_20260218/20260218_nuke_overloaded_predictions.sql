
-- 1. DROP all possible overloaded signatures to clear ambiguity
DROP FUNCTION IF EXISTS public.submit_prediction(uuid, text, text, text, numeric, numeric, integer);
DROP FUNCTION IF EXISTS public.submit_prediction(uuid, text, text, text, numeric, numeric, integer, boolean, text);
DROP FUNCTION IF EXISTS public.submit_prediction(uuid, text, text, text, numeric, numeric, numeric);

-- 2. CREATE the clean version (No dependency on activity_logs)
CREATE OR REPLACE FUNCTION public.submit_prediction(
    p_user_id UUID,
    p_asset_symbol TEXT,
    p_timeframe TEXT,
    p_direction TEXT,
    p_bet_amount INTEGER,
    p_target_percent NUMERIC,
    p_entry_price NUMERIC
)
RETURNS SETOF prediction
LANGUAGE plpgsql
AS $function$
DECLARE
    v_prediction_id UUID;
    v_user_email TEXT;
BEGIN
    -- Check points
    IF NOT EXISTS (
        SELECT 1 FROM profiles 
        WHERE id = p_user_id AND points >= p_bet_amount
    ) THEN
        RAISE EXCEPTION 'Insufficient points';
    END IF;

    -- Update points
    UPDATE profiles 
    SET points = points - p_bet_amount 
    WHERE id = p_user_id;

    -- Create prediction
    INSERT INTO predictions (
        user_id,
        asset_symbol,
        timeframe,
        direction,
        bet_amount,
        target_percent,
        entry_price,
        status,
        created_at
    )
    VALUES (
        p_user_id,
        p_asset_symbol,
        p_timeframe,
        p_direction,
        p_bet_amount,
        p_target_percent,
        p_entry_price,
        'PENDING',
        NOW()
    )
    RETURNING id INTO v_prediction_id;

    -- Return the created prediction
    RETURN QUERY SELECT * FROM predictions WHERE id = v_prediction_id;
END;
$function$;
