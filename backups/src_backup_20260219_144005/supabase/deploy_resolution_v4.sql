-- Deploy resolve_prediction_v4
-- Renaming to avoid signature/cache conflicts with previous versions

CREATE OR REPLACE FUNCTION public.resolve_prediction_v4(
    p_id BIGINT,
    p_close_price NUMERIC,
    p_timeframe_multiplier NUMERIC DEFAULT 1.0
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_pred RECORD;
    v_payout NUMERIC := 0;
    v_profit NUMERIC := 0;
    v_status TEXT := 'LOSS';
    v_user_id UUID;
    v_new_points NUMERIC;
    v_streak_bonus BOOLEAN := FALSE;
BEGIN
    -- 1. Get Prediction
    SELECT * INTO v_pred FROM predictions WHERE id = p_id;
    
    IF NOT FOUND THEN
        RETURN jsonb_build_object('success', false, 'error', 'Prediction not found');
    END IF;

    IF v_pred.status != 'pending' THEN
         RETURN jsonb_build_object('success', false, 'error', 'Prediction already resolved');
    END IF;

    v_user_id := v_pred.user_id;

    -- 2. Calculate Outcome
    IF (v_pred.direction = 'UP' AND p_close_price > v_pred.entry_price) OR
       (v_pred.direction = 'DOWN' AND p_close_price < v_pred.entry_price) THEN
       
       -- WIN
       v_status := 'WIN';
       v_profit := v_pred.bet_amount * 0.8 * p_timeframe_multiplier;
       v_payout := v_pred.bet_amount + v_profit;

    ELSEIF p_close_price = v_pred.entry_price THEN
        -- REFUND
        v_status := 'REFUND';
        v_payout := v_pred.bet_amount;
        v_profit := 0;
    ELSE
        -- LOSS
        v_status := 'LOSS';
        v_payout := 0;
        v_profit := -v_pred.bet_amount;
    END IF;

    -- 3. Update Prediction
    UPDATE predictions
    SET 
        status = v_status,
        close_price = p_close_price,
        payout = v_payout,
        profit_loss = v_profit,
        resolved_at = NOW()
    WHERE id = p_id;

    -- 4. Update Profile
    UPDATE profiles
    SET 
        points = points + v_profit,
        streak = CASE WHEN v_status = 'WIN' THEN streak + 1 WHEN v_status = 'LOSS' THEN 0 ELSE streak END
    WHERE id = v_user_id
    RETURNING points INTO v_new_points;

    -- 5. Return Result
    RETURN jsonb_build_object(
        'success', true,
        'status', v_status,
        'payout', v_payout,
        'new_balance', v_new_points
    );

EXCEPTION WHEN OTHERS THEN
    RETURN jsonb_build_object('success', false, 'error', SQLERRM);
END;
$$;
