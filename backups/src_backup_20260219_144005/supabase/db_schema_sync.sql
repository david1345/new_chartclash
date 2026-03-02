-- ChartClash Database Schema Sync Script
-- Purpose: Add missing columns and sync naming conventions for development environment.

-- 1. PROFILES Table: Add missing gaming stats columns
ALTER TABLE public.profiles 
  ADD COLUMN IF NOT EXISTS total_games INTEGER DEFAULT 0,
  ADD COLUMN IF NOT EXISTS total_wins INTEGER DEFAULT 0,
  ADD COLUMN IF NOT EXISTS streak_count INTEGER DEFAULT 0,
  ADD COLUMN IF NOT EXISTS streak INTEGER DEFAULT 0,
  ADD COLUMN IF NOT EXISTS total_earnings INTEGER DEFAULT 0,
  ADD COLUMN IF NOT EXISTS tier TEXT DEFAULT 'bronze';

-- 2. NOTIFICATIONS Table: Sync with frontend expectations
-- Frontend (NotificationBell.tsx) expects: is_read, title, points_change

-- Ensure 'is_read' exists (Rename from 'read' if it exists, otherwise add)
DO $$ 
BEGIN 
  IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='notifications' AND column_name='read') THEN
    ALTER TABLE public.notifications RENAME COLUMN "read" TO "is_read";
  ELSE
    ALTER TABLE public.notifications ADD COLUMN IF NOT EXISTS is_read BOOLEAN DEFAULT false;
  END IF;
END $$;

-- Add other missing columns
ALTER TABLE public.notifications
  ADD COLUMN IF NOT EXISTS title TEXT,
  ADD COLUMN IF NOT EXISTS points_change INTEGER DEFAULT 0;

-- 3. Update Resolve Prediction RPC to use synced columns
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
    
    -- 2. Calculate Result
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
        v_notif_type := 'info';
        v_notif_title := 'Refund: Missed Target';
        v_notif_msg := 'Stake returned.';
    END IF;

    -- Use synced columns: is_read, title, points_change
    INSERT INTO public.notifications (user_id, type, title, message, points_change, is_read)
    VALUES (v_prediction.user_id, v_notif_type, v_notif_title, v_notif_msg, v_profit_change, FALSE);
    
    return json_build_object('success', true, 'status', v_status, 'payout', v_payout);
exception when others then
    return json_build_object('success', false, 'error', SQLERRM);
end;
$$;

-- 4. Confirm Columns (Informational)
DO $$
DECLARE
    r RECORD;
BEGIN
    FOR r IN (SELECT column_name FROM information_schema.columns WHERE table_name = 'profiles' AND column_name IN ('total_games', 'total_wins', 'streak_count')) LOOP
        RAISE NOTICE 'Profiles column confirmed: %', r.column_name;
    END LOOP;
END $$;
