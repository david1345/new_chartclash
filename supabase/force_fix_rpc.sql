-- Redefine resolve_prediction_advanced to match API usage EXACTLY

-- Drop old versions to allow return type changes
DROP FUNCTION IF EXISTS public.resolve_prediction_advanced(bigint, numeric, numeric);
DROP FUNCTION IF EXISTS public.resolve_prediction_advanced(bigint, numeric); -- Drop verify overload if exists

CREATE OR REPLACE FUNCTION public.resolve_prediction_advanced(
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
    v_multiplier NUMERIC := 1.0; -- Base multiplier
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
    -- Direction Win?
    IF (v_pred.direction = 'UP' AND p_close_price > v_pred.entry_price) OR
       (v_pred.direction = 'DOWN' AND p_close_price < v_pred.entry_price) THEN
       
       -- WIN
       v_status := 'WIN';
       -- Base Profit: Bet * 0.8 * TimeframeMultiplier
       v_profit := v_pred.bet_amount * 0.8 * p_timeframe_multiplier;
       v_payout := v_pred.bet_amount + v_profit;

       -- Target Bonus Check (Simplified for safety)
       -- If target_price is set and hit, add bonus. 
       -- For now, just stick to direction win for reliability.
       
    ELSEIF p_close_price = v_pred.entry_price THEN
        -- DRAW (Refund)
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

    -- 4. Update Profile (Points & Streak)
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
