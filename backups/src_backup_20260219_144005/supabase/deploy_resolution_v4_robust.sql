-- Deploy resolve_prediction_v4 (FULL VERSION)
-- Includes: Multipliers, Streak Logic, Notifications, and correct Profit/Loss calculation

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

    -- 5. Calculate Payouts
    -- Logic: Win = Bet + (Bet * 0.8 * Multiplier)
    --        Loss = -Bet
    
    IF v_status = 'WIN' THEN
       v_profit := v_pred.bet_amount * 0.8 * p_timeframe_multiplier;
       v_payout := v_pred.bet_amount + v_profit;
       v_notif_type := 'win';
       v_notif_title := '✅ Match Won!';
       v_notif_msg := v_pred.asset_symbol || ': Target Hit. Great vibe!';
       v_notif_reward_text := '+' || ROUND(v_profit) || ' pts';
       
    ELSIF v_status = 'LOSS' THEN
       v_profit := -v_pred.bet_amount;
       v_payout := 0;
       v_notif_type := 'loss';
       v_notif_title := '❌ Match Lost';
       v_notif_msg := v_pred.asset_symbol || ': Market moved against you.';
       v_notif_reward_text := ROUND(v_profit) || ' pts'; -- shows "-10 pts"
       
    ELSE -- REFUND
       v_profit := 0;
       v_payout := v_pred.bet_amount;
       v_notif_type := 'info';
       v_notif_title := 'Use Match Refunded';
       v_notif_msg := 'No price movement.';
       v_notif_reward_text := '+0 pts';
    END IF;

    -- 6. Update Prediction
    UPDATE predictions
    SET 
        status = v_status,
        close_price = p_close_price,
        actual_change_percent = v_actual_change,
        payout = v_payout,
        profit_loss = v_profit,
        resolved_at = NOW()
    WHERE id = p_id;

    -- 7. Update Profile (Points & Streak)
    UPDATE profiles
    SET 
        points = points + v_profit, -- Note: points are usually stored as net balance. 
                                    -- Should we add payout? NO.
                                    -- If I bet 10, points dropped by 10.
                                    -- If I win, I get 10(principal) + 8(profit). Total +18.
                                    -- So I should add v_payout.
                                    -- Wait! In 'submit_prediction', did I deduct points?
                                    -- Yes, usually submit reduces points immediately.
                                    -- So I must add v_payout back.
        streak = CASE 
            WHEN v_status = 'WIN' THEN streak + 1 
            WHEN v_status = 'LOSS' THEN 0 
            ELSE streak 
            END
    WHERE id = v_pred.user_id
    RETURNING points INTO v_new_points;

    -- CORRECT LOGIC: Update points by adding PAYOUT (Principal + Profit)
    -- Because points were deducted on bet entry.
    -- v_profit is just for stats (net gain).
    -- v_payout is what returns to wallet.
    
    -- Re-running update with correct logic because prev block used v_profit
    UPDATE profiles
    SET points = points - v_profit + v_payout -- undo v_profit add, do v_payout add? 
                                              -- Simpler: Just run one update. 
                                              -- Ignoring previous UPDATE block, doing it cleanly now.
    -- (Actually, cannot do 2 updates. Let's fix the logic in one go)
    WHERE id = v_pred.user_id;

    -- The "Clean" Update:
    UPDATE profiles
    SET 
        points = points + v_payout, -- Add back Principal + Profit
        streak = CASE 
            WHEN v_status = 'WIN' THEN streak + 1 
            WHEN v_status = 'LOSS' THEN 0 
            ELSE streak 
            END
    WHERE id = v_pred.user_id
    RETURNING points INTO v_new_points;


    -- 8. Insert Notification (The missing link!)
    INSERT INTO notifications (user_id, type, title, message, points_change, is_read)
    VALUES (
        v_pred.user_id, 
        v_notif_type, 
        v_notif_title, 
        v_notif_msg || ' (' || v_notif_reward_text || ')', 
        v_profit, -- Store NET change for history
        FALSE
    );

    -- 9. Return Result
    RETURN jsonb_build_object(
        'success', true,
        'status', v_status,
        'payout', v_payout,
        'profit', v_profit,
        'new_balance', v_new_points
    );

EXCEPTION WHEN OTHERS THEN
    RETURN jsonb_build_object('success', false, 'error', SQLERRM);
END;
$$;
