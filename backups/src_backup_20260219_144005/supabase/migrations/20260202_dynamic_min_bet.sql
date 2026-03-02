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
    v_min_bet INTEGER;
BEGIN
    -- 1. Check & Lock Points
    SELECT points INTO v_current_points
    FROM profiles
    WHERE id = p_user_id
    FOR UPDATE;

    -- 2. Calculate Dynamic Min Bet (1% of Points, Min 10)
    -- GREATEST(10, FLOOR(v_current_points * 0.01))
    v_min_bet := GREATEST(10, FLOOR(v_current_points * 0.01));

    -- 3. Validate Points
    IF v_current_points < p_bet_amount THEN
        RETURN json_build_object(
            'success', false,
            'error', 'Insufficient points',
            'current_points', v_current_points
        );
    END IF;

    -- 4. Min/Max Checks
    IF p_bet_amount < v_min_bet THEN
        RETURN json_build_object(
            'success', false,
            'error', format('Minimum bet is %s points (1%% of your holdings)', v_min_bet),
            'min_bet', v_min_bet
        );
    END IF;

    IF p_bet_amount > v_current_points * 0.2 AND v_current_points > 50 THEN
        RETURN json_build_object(
            'success', false,
            'error', 'Maximum bet is 20% of your points'
        );
    END IF;

    -- 5. Calculate Candle Close Time
    CASE p_timeframe
        WHEN '1m' THEN v_candle_duration := 60;
        WHEN '5m' THEN v_candle_duration := 300;
        WHEN '15m' THEN v_candle_duration := 900;
        WHEN '1h' THEN v_candle_duration := 3600;
        WHEN '4h' THEN v_candle_duration := 14400;
        WHEN '1d' THEN v_candle_duration := 86400;
        ELSE v_candle_duration := 900; -- Default 15m
    END CASE;

    -- Calculate close time (Assuming NOW() is close to open time or within candle)
    -- Ideally, frontend provides candle_open_time, but for simplicity/safety we rely on Server Time window
    -- A simple approach: Round up to next candle boundary based on server time?
    -- For this MVP, we just set duration from NOW. (Refine later for strict candle alignment)
    v_candle_close_at := NOW() + (v_candle_duration || ' seconds')::INTERVAL;

    -- 6. Insert Prediction
    INSERT INTO predictions (
        user_id, asset_symbol, timeframe, direction, 
        target_percent, entry_price, bet_amount, 
        status, candle_close_at
    )
    VALUES (
        p_user_id, p_asset_symbol, p_timeframe, p_direction, 
        p_target_percent, p_entry_price, p_bet_amount, 
        'pending', v_candle_close_at
    )
    RETURNING id INTO v_prediction_id;

    -- 7. Deduct Points
    UPDATE profiles
    SET points = points - p_bet_amount
    WHERE id = p_user_id
    RETURNING points INTO v_new_points;

    -- 8. Return Success
    RETURN json_build_object(
        'success', true,
        'prediction_id', v_prediction_id,
        'new_points', v_new_points,
        'min_bet', v_min_bet
    );
END;
$$;
