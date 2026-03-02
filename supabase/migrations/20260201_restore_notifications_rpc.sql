-- Restore RPC with Notification Insertion
-- This re-enables the "INSERT INTO notifications" block now that the table schema is fixed.

DROP FUNCTION IF EXISTS public.resolve_prediction_advanced(bigint, numeric);

CREATE OR REPLACE FUNCTION public.resolve_prediction_advanced(
    p_id BIGINT,
    p_close_price NUMERIC
)
RETURNS JSON
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_prediction RECORD;
    v_price_change NUMERIC;
    v_price_change_percent NUMERIC;
    v_status TEXT;
    v_payout INTEGER := 0;
    v_result JSON;
BEGIN
    -- 1. Fetch Prediction (Lock)
    SELECT * INTO v_prediction
    FROM predictions
    WHERE id = p_id AND status = 'pending'
    FOR UPDATE;
    
    IF NOT FOUND THEN
        RETURN json_build_object(
            'success', false,
            'error', 'Prediction not found or already resolved'
        );
    END IF;
    
    -- 2. Calculate Change
    v_price_change := p_close_price - v_prediction.entry_price;
    v_price_change_percent := abs(v_price_change / v_prediction.entry_price * 100);
    
    -- 3. Determine Outcome
    IF v_prediction.direction = 'UP' THEN
        IF v_price_change > 0 AND v_price_change_percent >= v_prediction.target_percent THEN
            v_status := 'WIN';
            v_payout := v_prediction.bet_amount * (v_prediction.target_percent * 2 + 1);
        ELSIF v_price_change < 0 THEN
            v_status := 'LOSS';
            v_payout := 0;
        ELSE
            v_status := 'ND';
            v_payout := v_prediction.bet_amount;
        END IF;
    ELSIF v_prediction.direction = 'DOWN' THEN
        IF v_price_change < 0 AND v_price_change_percent >= v_prediction.target_percent THEN
            v_status := 'WIN';
            v_payout := v_prediction.bet_amount * (v_prediction.target_percent * 2 + 1);
        ELSIF v_price_change > 0 THEN
            v_status := 'LOSS';
            v_payout := 0;
        ELSE
            v_status := 'ND';
            v_payout := v_prediction.bet_amount;
        END IF;
    END IF;
    
    -- 4. Update Prediction
    UPDATE predictions
    SET 
        status = v_status,
        actual_price = p_close_price,
        profit = v_payout - v_prediction.bet_amount,
        resolved_at = now()
    WHERE id = p_id;
    
    -- 5. Payout Points
    IF v_payout > 0 THEN
        UPDATE profiles
        SET points = points + v_payout
        WHERE id = v_prediction.user_id;
    END IF;
    
    -- 6. Create Notification (RESTORED)
    -- Ensure "prediction_id" column exists in table before running this!
    INSERT INTO notifications (user_id, type, message, prediction_id)
    VALUES (
        v_prediction.user_id,
        'prediction_resolved',
        format('%s prediction: %s (%s pts)', v_prediction.asset_symbol, v_status, v_payout - v_prediction.bet_amount),
        p_id
    );
    
    -- 7. Return Result
    v_result := json_build_object(
        'success', true,
        'status', v_status,
        'payout', v_payout,
        'profit', v_payout - v_prediction.bet_amount,
        'price_change_percent', v_price_change_percent
    );
    
    RETURN v_result;
    
EXCEPTION
    WHEN OTHERS THEN
        RETURN json_build_object(
            'success', false,
            'error', SQLERRM
        );
END;
$$;
