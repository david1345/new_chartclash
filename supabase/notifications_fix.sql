-- 🔥 FIX: Merge Notifications + Insight Stats + Resolution Logic
-- This redefines resolve_prediction_advanced to include EVERYTHING:
-- 1. Core Win/Loss Logic
-- 2. Insight Feed Stats (Total Games, Wins, Streaks)
-- 3. Notification System (Insert into notifications table)

CREATE OR REPLACE FUNCTION public.resolve_prediction_advanced(
    p_id bigint,
    p_close_price numeric
)
RETURNS JSON
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
declare
    v_prediction record;
    v_user_profile record;
    v_price_change numeric;
    v_price_change_percent numeric;
    v_status text;
    v_payout integer := 0;
    
    -- Notification vars
    v_notif_title TEXT;
    v_notif_msg TEXT;
    v_notif_type TEXT;
    v_profit_change INTEGER;
begin
    -- 1. Get Prediction
    select * into v_prediction from predictions where id = p_id and status = 'pending' for update;
    if not found then return json_build_object('success', false, 'error', 'Prediction not found'); end if;
    
    -- 2. Get User Profile (for streak info)
    select * into v_user_profile from profiles where id = v_prediction.user_id;

    -- 3. Calculate Result
    v_price_change := p_close_price - v_prediction.entry_price;
    v_price_change_percent := abs(v_price_change / v_prediction.entry_price * 100);
    
    if v_prediction.direction = 'UP' then
        if v_price_change > 0 and v_price_change_percent >= v_prediction.target_percent then
            v_status := 'WIN';
            v_payout := v_prediction.bet_amount * (v_prediction.target_percent * 2 + 1);
        elsif v_price_change < 0 then
            v_status := 'LOSS';
        else
            v_status := 'ND';
            v_payout := v_prediction.bet_amount;
        end if;
    elsif v_prediction.direction = 'DOWN' then
        if v_price_change < 0 and v_price_change_percent >= v_prediction.target_percent then
            v_status := 'WIN';
            v_payout := v_prediction.bet_amount * (v_prediction.target_percent * 2 + 1);
        elsif v_price_change > 0 then
            v_status := 'LOSS';
        else
            v_status := 'ND';
            v_payout := v_prediction.bet_amount;
        end if;
    end if;
    
    v_profit_change := v_payout - v_prediction.bet_amount;
    
    -- 4. Update Prediction
    update predictions
    set status = v_status, actual_price = p_close_price, profit = v_profit_change, resolved_at = now()
    where id = p_id;
    
    -- 5. Update User Profile (Points + Insight Stats)
    update profiles
    set 
        points = points + v_payout,
        total_games = total_games + 1,
        total_wins = total_wins + (CASE WHEN v_status = 'WIN' THEN 1 ELSE 0 END),
        streak_count = (CASE WHEN v_status = 'WIN' THEN streak_count + 1 ELSE 0 END),
        total_earnings = total_earnings + v_profit_change
    where id = v_prediction.user_id;
    
    -- 6. Create Notification
    IF v_status = 'WIN' THEN
        v_notif_type := 'win';
        v_notif_title := '✅ WIN: ' || v_prediction.asset_symbol;
        v_notif_msg := 'Direction & Target hit! Earned ' || v_payout || ' pts.';
    ELSIF v_status = 'LOSS' THEN
        v_notif_type := 'loss';
        v_notif_title := '❌ LOSS: ' || v_prediction.asset_symbol;
        v_notif_msg := 'Prediction missed target. Better luck next time.';
    ELSE
        -- ND (Refund) Cases
        v_notif_type := 'info';
        
        IF v_price_change = 0 THEN
             v_notif_title := 'Refund: No Movement';
             v_notif_msg := 'Price did not move. Stake returned.';
        ELSE
             v_notif_title := 'Refund: Missed Target';
             v_notif_msg := 'Direction correct but missed ' || v_prediction.target_percent || '% target. Stake returned.';
        END IF;
    END IF;

    -- Use INSERT if table exists, ignore error if not (Safety)
    BEGIN
        INSERT INTO public.notifications (user_id, type, title, message, points_change, is_read)
        VALUES (v_prediction.user_id, v_notif_type, v_notif_title, v_notif_msg, v_profit_change, FALSE);
    EXCEPTION WHEN OTHERS THEN
        -- Table might not exist yet, ignore to prevent transaction failure
        NULL; 
    END;
    
    return json_build_object('success', true, 'status', v_status, 'payout', v_payout);
exception when others then
    return json_build_object('success', false, 'error', SQLERRM);
end;
$$;
