-- Deploy resolve_prediction_v4 (FULL VERSION WITH TARGET BONUS)
-- Includes: Multipliers, Streak Logic, Notifications, and Target Bonus

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
    v_user_profile RECORD;
    
    -- Status Vars
    v_status TEXT := 'LOSS';
    v_actual_change NUMERIC;
    v_is_target_hit BOOLEAN := FALSE;
    
    -- Econ Vars
    v_payout NUMERIC := 0;
    v_profit NUMERIC := 0;
    v_base_profit NUMERIC := 0;
    v_target_bonus NUMERIC := 0;
    v_new_points NUMERIC;
    
    -- Notification Vars
    v_notif_title TEXT;
    v_notif_msg TEXT;
    v_notif_type TEXT;
    v_notif_reward_text TEXT;

BEGIN
    -- 1. Get Prediction
    SELECT * INTO v_pred FROM predictions WHERE id = p_id;
    
    IF NOT FOUND THEN
        RETURN jsonb_build_object('success', false, 'error', 'Prediction not found');
    END IF;

    IF v_pred.status != 'pending' THEN
         RETURN jsonb_build_object('success', false, 'error', 'Prediction already resolved');
    END IF;

    -- 2. Get User Profile for Streak Logic
    SELECT * INTO v_user_profile FROM profiles WHERE id = v_pred.user_id;

    -- 3. Calculate Actual Change & Direction
    IF v_pred.entry_price = 0 THEN
      v_actual_change := 0;
    ELSE
      v_actual_change := ((p_close_price - v_pred.entry_price) / v_pred.entry_price) * 100;
    END IF;

    -- 4. Deterimine Win/Loss
    IF p_close_price = v_pred.entry_price THEN
        v_status := 'REFUND'; -- Or ND
    ELSIF (v_pred.direction = 'UP' AND p_close_price > v_pred.entry_price) OR
          (v_pred.direction = 'DOWN' AND p_close_price < v_pred.entry_price) THEN
       v_status := 'WIN';
    ELSE
       v_status := 'LOSS';
    END IF;

    -- 5. Check Target Hit
    IF v_status = 'WIN' AND ABS(v_actual_change) >= v_pred.target_percent THEN
        v_is_target_hit := TRUE;
    END IF;


    -- 6. Calculate Payouts
    
    IF v_status = 'WIN' THEN
       -- A. Base Profit (Direction)
       v_base_profit := v_pred.bet_amount * 0.8 * p_timeframe_multiplier;
       
       -- B. Target Bonus (Fixed)
       -- 0.5% -> 20pts
       -- 1.0% -> 40pts
       -- 1.5% -> 80pts
       -- 2.0% -> 120pts
       IF v_is_target_hit THEN
           IF v_pred.target_percent < 1.0 THEN v_target_bonus := 20;
           ELSIF v_pred.target_percent < 1.5 THEN v_target_bonus := 40;
           ELSIF v_pred.target_percent < 2.0 THEN v_target_bonus := 80;
           ELSE v_target_bonus := 120;
           END IF;
       END IF;

       -- Total Profit
       v_profit := v_base_profit + v_target_bonus;
       v_payout := v_pred.bet_amount + v_profit;
       
       v_notif_type := 'win';
       v_notif_title := '✅ Match Won!';
       
       IF v_is_target_hit THEN
           v_notif_msg := v_pred.asset_symbol || ': Perfect! Direction + Target Hit! 🎯';
           v_notif_reward_text := '+' || ROUND(v_profit) || ' pts (Bonus Included)';
       ELSE
           v_notif_msg := v_pred.asset_symbol || ': Direction Correct.';
           v_notif_reward_text := '+' || ROUND(v_profit) || ' pts';
       END IF;
       
    ELSIF v_status = 'LOSS' THEN
       v_profit := -v_pred.bet_amount;
       v_payout := 0;
       v_notif_type := 'loss';
       v_notif_title := '❌ Match Lost';
       v_notif_msg := v_pred.asset_symbol || ': Market moved against you.';
       v_notif_reward_text := ROUND(v_profit) || ' pts'; 
       
    ELSE -- REFUND
       v_profit := 0;
       v_payout := v_pred.bet_amount;
       v_notif_type := 'info';
       v_notif_title := 'Use Match Refunded';
       v_notif_msg := 'No price movement.';
       v_notif_reward_text := '+0 pts';
    END IF;

    -- 7. Update Prediction
    UPDATE predictions
    SET 
        status = v_status,
        close_price = p_close_price,
        actual_change_percent = v_actual_change,
        is_target_hit = v_is_target_hit,
        payout = v_payout,
        profit_loss = v_profit,
        resolved_at = NOW()
    WHERE id = p_id;

    -- 8. Update Profile (Points & Streak)
    UPDATE profiles
    SET 
        points = points + v_payout,
        streak = CASE 
            WHEN v_status = 'WIN' AND v_is_target_hit THEN streak + 1 
            WHEN v_status = 'WIN' THEN streak -- Keep streak but don't increment if target missed? Or increment? 
                                            -- Let's say Streak requires Target Hit for "Perfect Streak"? 
                                            -- Or just win is enough? Let's say Win is enough for simplicity.
                                            -- BUT Task.md said: "Perfect Streak: Only increments on Dir + Target Hit"
                                            -- So I will follow that.
            WHEN v_status = 'LOSS' THEN 0 
            ELSE streak 
            END
    WHERE id = v_pred.user_id
    RETURNING points INTO v_new_points;


    -- 9. Insert Notification
    INSERT INTO notifications (user_id, type, title, message, points_change, is_read)
    VALUES (
        v_pred.user_id, 
        v_notif_type, 
        v_notif_title, 
        v_notif_msg || ' (' || v_notif_reward_text || ')', 
        v_profit, 
        FALSE
    );

    -- 10. Return Result
    RETURN jsonb_build_object(
        'success', true,
        'status', v_status,
        'payout', v_payout,
        'profit', v_profit,
        'target_bonus', v_target_bonus,
        'new_balance', v_new_points
    );

EXCEPTION WHEN OTHERS THEN
    RETURN jsonb_build_object('success', false, 'error', SQLERRM);
END;
$$;
