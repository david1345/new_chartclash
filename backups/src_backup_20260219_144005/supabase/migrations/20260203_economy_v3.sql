-- Economy V3.0: Final Reward Structure
-- Philosophies:
-- 1. Direction Win = Main Profit (Bet * 0.8 * TF_Mult)
-- 2. Target Bonus = Fixed Points (Not Multiplicated, Optional Challenge)
-- 3. Perfect Streak = Only increments if BOTH Direction & Target hit.
-- 4. House Edge = 0.95 (5% Burn) on Net Profit.
-- 5. Loss = All-in (Payout 0).

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
    
    -- Status
    v_status TEXT;
    v_is_dir_correct BOOLEAN;
    v_is_target_hit BOOLEAN;
    
    -- Calculation Variables
    v_direction_profit NUMERIC := 0;
    v_target_bonus INTEGER := 0;
    v_base_profit NUMERIC := 0;
    v_final_profit NUMERIC := 0;
    v_payout INTEGER := 0;
    
    -- Multipliers
    v_tf_mult NUMERIC;
    v_streak_mult NUMERIC;
    c_house_edge NUMERIC := 0.95;
    
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
    
    -- Safe division for percent
    IF v_prediction.entry_price = 0 THEN
        v_price_change_percent := 0;
    ELSE
        v_price_change_percent := abs(v_price_change / v_prediction.entry_price * 100);
    END IF;

    -- 4. Outcome Determination
    IF v_prediction.entry_price = p_close_price THEN
        -- [NO DECISION] No Price Change
        -- Return Principal
        v_status := 'ND';
        v_payout := v_prediction.bet_amount;
        v_final_profit := 0;
        
        -- Streak Maintain (No Decision usually maintains streak)
        v_new_streak := v_profile.streak;
        
    ELSE
        -- Check Direction
        v_is_dir_correct := FALSE;
        IF v_prediction.direction = 'UP' AND v_price_change > 0 THEN v_is_dir_correct := TRUE; END IF;
        IF v_prediction.direction = 'DOWN' AND v_price_change < 0 THEN v_is_dir_correct := TRUE; END IF;
        
        -- Check Target (Bonus Quest)
        v_is_target_hit := (v_price_change_percent >= v_prediction.target_percent);

        IF v_is_dir_correct THEN
            -- [WIN]
            v_status := 'WIN';
            
            -- A. Timeframe Cons (0.8 * TF_Mult is base efficiency)
            -- 15m=1.0, 30m=1.1, 1h=1.2, 2h=1.3, 4h=1.5, 1d=1.8
            CASE 
                WHEN v_prediction.timeframe = '1m' THEN v_tf_mult := 1.0; -- Treat short like 15m base for now
                WHEN v_prediction.timeframe = '5m' THEN v_tf_mult := 1.0;
                WHEN v_prediction.timeframe = '15m' THEN v_tf_mult := 1.0;
                WHEN v_prediction.timeframe = '30m' THEN v_tf_mult := 1.1;
                WHEN v_prediction.timeframe = '1h' THEN v_tf_mult := 1.2;
                WHEN v_prediction.timeframe = '4h' THEN v_tf_mult := 1.5; -- Approximation
                WHEN v_prediction.timeframe = '1d' THEN v_tf_mult := 1.8;
                ELSE v_tf_mult := 1.2; -- Default 1h
            END CASE;
            
            -- Direction Profit = Bet * 0.8 * TF_Mult
            v_direction_profit := v_prediction.bet_amount * 0.8 * v_tf_mult;

            -- B. Target Bonus (Fixed)
            -- Only if Target Hit
            IF v_is_target_hit THEN
                CASE 
                    WHEN v_prediction.target_percent <= 0.5 THEN v_target_bonus := 20;
                    WHEN v_prediction.target_percent <= 1.0 THEN v_target_bonus := 40;
                    WHEN v_prediction.target_percent <= 1.5 THEN v_target_bonus := 70;
                    ELSE v_target_bonus := 120; -- > 1.5% and 2.0%
                END CASE;
            ELSE
                v_target_bonus := 0;
            END IF;

            -- Base Profit Sum
            v_base_profit := v_direction_profit + v_target_bonus;

            -- C. Perfect Streak (High Skill Only)
            -- Only counts if Direction + Target BOTH Hit
            IF v_is_target_hit THEN
                v_new_streak := v_profile.streak + 1;
            ELSE
                -- Win but missed target -> Streak Reset (High Standard)
                v_new_streak := 0;
            END IF;

            -- Determine Streak Multiplier based on Current Streak (Post-increment?)
            -- Usually rewards are based on *Current Completed* streak.
            -- Using v_new_streak for multiplier apply.
            IF v_new_streak >= 5 THEN v_streak_mult := 2.5;
            ELSIF v_new_streak = 4 THEN v_streak_mult := 2.0;
            ELSIF v_new_streak = 3 THEN v_streak_mult := 1.6;
            ELSIF v_new_streak = 2 THEN v_streak_mult := 1.3;
            ELSE v_streak_mult := 1.0; -- 0 or 1
            END IF;

            -- D. Final Calculation
            -- Profit = BaseProfit * StreakMult * HouseEdge
            v_final_profit := v_base_profit * v_streak_mult * c_house_edge;
            
            -- Payout = Principal + Profit
            v_payout := v_prediction.bet_amount + ROUND(v_final_profit);

        ELSE
            -- [LOSS]
            v_status := 'LOSS';
            v_payout := 0; -- All-in Loss
            v_final_profit := -v_prediction.bet_amount; -- Net is negative
            v_new_streak := 0;
        END IF;
    END IF;

    -- 5. Update DB
    UPDATE profiles SET points = points + v_payout, streak = v_new_streak WHERE id = v_prediction.user_id;

    UPDATE predictions 
    SET status = v_status, 
        actual_price = p_close_price, 
        profit = ROUND(v_final_profit), 
        resolved_at = now() 
    WHERE id = p_id;

    RETURN json_build_object(
        'success', true, 
        'status', v_status,
        'payout', v_payout,
        'profit', ROUND(v_final_profit),
        'streak', v_new_streak
    );
END;
$$;
