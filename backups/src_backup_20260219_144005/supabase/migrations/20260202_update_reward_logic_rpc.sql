-- 1. Ensure Streak Column Exists
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS streak INTEGER DEFAULT 0;

-- 2. Update Resolution RPC (Direction Win = Success)
CREATE OR REPLACE FUNCTION public.resolve_prediction_advanced(
    p_id BIGINT,
    p_close_price NUMERIC,
    p_crowd_multiplier NUMERIC DEFAULT 1.0
)
RETURNS JSON
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_prediction RECORD;
    v_profile RECORD;
    v_price_change NUMERIC;
    v_price_change_percent NUMERIC;
    v_status TEXT;
    v_payout INTEGER := 0;
    
    -- Decisions
    v_is_dir_correct BOOLEAN;
    v_is_target_hit BOOLEAN;
    
    -- Multipliers
    v_stake_mult NUMERIC;
    v_tf_mult NUMERIC;
    v_target_mult NUMERIC;
    v_streak_mult NUMERIC;
    v_crowd_mult NUMERIC;
    
    -- Constants
    c_base_win INTEGER := 40;
    c_target_bonus INTEGER := 60;
    c_loss_base INTEGER := 50;
    
    v_new_points INTEGER;
    v_new_streak INTEGER;
BEGIN
    -- 1. Fetch Prediction
    SELECT * INTO v_prediction FROM predictions WHERE id = p_id AND status = 'pending' FOR UPDATE;
    
    IF NOT FOUND THEN
        RETURN json_build_object('success', false, 'error', 'Prediction not found or already resolved');
    END IF;

    -- 2. Fetch Profile
    SELECT * INTO v_profile FROM profiles WHERE id = v_prediction.user_id FOR UPDATE;

    -- 3. Calculate Changes
    v_price_change := p_close_price - v_prediction.entry_price;
    v_price_change_percent := abs(v_price_change / v_prediction.entry_price * 100);

    -- 4. Check Conditions
    v_is_dir_correct := FALSE;
    IF v_prediction.direction = 'UP' AND v_price_change > 0 THEN v_is_dir_correct := TRUE; END IF;
    IF v_prediction.direction = 'DOWN' AND v_price_change < 0 THEN v_is_dir_correct := TRUE; END IF;

    v_is_target_hit := (v_price_change_percent >= v_prediction.target_percent);

    -- 5. Determine Multipliers
    
    -- A) Stake Multiplier: sqrt(bet/100), cap at 4.0
    v_stake_mult := LEAST(SQRT(v_prediction.bet_amount::NUMERIC / 100.0), 4.0);
    
    -- B) Timeframe Multiplier (User Config)
    CASE 
        WHEN v_prediction.timeframe = '1m' THEN v_tf_mult := 0.7;
        WHEN v_prediction.timeframe = '3m' THEN v_tf_mult := 0.85;
        WHEN v_prediction.timeframe = '5m' THEN v_tf_mult := 1.0;
        WHEN v_prediction.timeframe = '15m' THEN v_tf_mult := 1.3;
        WHEN v_prediction.timeframe = '30m' THEN v_tf_mult := 1.5; -- Interpolated
        WHEN v_prediction.timeframe = '1h' THEN v_tf_mult := 1.8;
        WHEN v_prediction.timeframe = '4h' THEN v_tf_mult := 2.5; -- Extrapolated
        WHEN v_prediction.timeframe = '1d' THEN v_tf_mult := 3.0;
        ELSE v_tf_mult := 1.0;
    END CASE;

    -- C) Target Multiplier (User Config)
    CASE 
        WHEN v_prediction.target_percent <= 0.3 THEN v_target_mult := 0.8;
        WHEN v_prediction.target_percent <= 0.5 THEN v_target_mult := 1.0;
        WHEN v_prediction.target_percent <= 0.8 THEN v_target_mult := 1.3;
        WHEN v_prediction.target_percent <= 1.0 THEN v_target_mult := 1.6;
        WHEN v_prediction.target_percent <= 1.5 THEN v_target_mult := 2.2;
        WHEN v_prediction.target_percent > 1.5 THEN v_target_mult := 3.0; -- Extrapolated
        ELSE v_target_mult := 1.3;
    END CASE;

    -- D) Streak Multiplier (User Config)
    -- 1-2: 1.0, 3: 1.2, 4: 1.35, 5: 1.55, 6+: 1.8
    IF v_profile.streak >= 6 THEN v_streak_mult := 1.8;
    ELSIF v_profile.streak = 5 THEN v_streak_mult := 1.55;
    ELSIF v_profile.streak = 4 THEN v_streak_mult := 1.35;
    ELSIF v_profile.streak = 3 THEN v_streak_mult := 1.2;
    ELSE v_streak_mult := 1.0;
    END IF;

    -- Crowd Multiplier (Passed from backend, defaults to 1.0)
    v_crowd_mult := p_crowd_multiplier;
    -- Sanity check
    IF v_crowd_mult IS NULL OR v_crowd_mult <= 0 THEN v_crowd_mult := 1.0; END IF;

    -- 6. Payout Logic
    IF v_prediction.entry_price = p_close_price THEN
        -- ND (No Move)
        v_status := 'ND';
        v_payout := v_prediction.bet_amount; -- Return Principal
    ELSIF v_is_dir_correct THEN
        -- WIN (Direction Match)
        v_status := 'WIN';
        
        -- Base Reward
        v_payout := c_base_win;
        
        -- Target Bonus?
        IF v_is_target_hit THEN
            v_payout := v_payout + c_target_bonus;
        END IF;
        
        -- Apply Multipliers
        -- Reward = (Base + Bonus) * TF * Target * Streak * Stake * Crowd
        v_payout := ROUND(v_payout * v_tf_mult * v_target_mult * v_streak_mult * v_stake_mult * v_crowd_mult);
        
        -- Add returned principal? 
        -- If user bets 100, and Payout is 100, they have 200.
        -- "Earn Points" usually implies Profit.
        -- So Total = Payout (Profit) + BetAmount (Principal).
        
        -- However, `profiles.points` updates are usually `old + delta`.
        -- If delta is POSITIVE, it's profit.
        -- If I bet 100. Points -= 100.
        -- If I win 50 profit. I need to receive 150.
        -- So v_payout MUST be Profit + Principal?
        -- No, let's treat `v_payout` as the *Net Change* to apply roughly?
        -- Standard: Return Principal + Profit.
        v_payout := v_payout + v_prediction.bet_amount;

    ELSE
        -- LOSS (Wrong Direction)
        v_status := 'LOSS';
        
        -- Loss Formula: 50 * TF * Stake
        -- Note: Loss implies *deduction from Principal* or *additional penalty*?
        -- Betting usually means "Lose Principal". (Loss = -BetAmount).
        -- User says "Loss = 50 * TF". 
        -- If Bet=100. Loss Calc = 50.
        -- This implies we Return (Bet - 50).
        -- i.e. Partial Refund.
        
        DECLARE v_loss_amt INTEGER;
        BEGIN
            v_loss_amt := ROUND(c_loss_base * v_tf_mult * v_stake_mult);
            -- Cap loss at bet amount? (Cannot lose more than you bet?)
            -- Or is it a penalty? usually capped at bet.
            v_loss_amt := LEAST(v_loss_amt, v_prediction.bet_amount);
            
            -- Payout = Principal - Loss
            v_payout := v_prediction.bet_amount - v_loss_amt;
            
            -- If Loss > Bet (e.g. leverage?), payout < 0? No, assume floor 0.
            IF v_payout < 0 THEN v_payout := 0; END IF;
        END;
    END IF;

    -- 7. Update Streak & Points
    v_new_points := v_profile.points + v_payout;
    
    IF v_status = 'WIN' THEN
        v_new_streak := v_profile.streak + 1;
    ELSIF v_status = 'LOSS' THEN
        v_new_streak := 0; 
    ELSE
        v_new_streak := v_profile.streak; -- ND preserves streak
    END IF;

    -- Update DB
    UPDATE profiles SET points = v_new_points, streak = v_new_streak WHERE id = v_prediction.user_id;
    
    UPDATE predictions 
    SET status = v_status, 
        actual_price = p_close_price, 
        profit = v_payout - v_prediction.bet_amount, -- Net Profit recording
        resolved_at = now() 
    WHERE id = p_id;

    RETURN json_build_object(
        'success', true, 
        'status', v_status, 
        'payout', v_payout, 
        'profit', v_payout - v_prediction.bet_amount
    );
END;
$$;
