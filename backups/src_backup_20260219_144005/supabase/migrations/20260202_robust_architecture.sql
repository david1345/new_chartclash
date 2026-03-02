-- ==============================================================================
-- 🚀 VIBE FORECAST ROBUST ARCHITECTURE MIGRATION (2026-02-02)
-- Goal: Decouple Notification Logic from Financial Resolution using Triggers
-- ==============================================================================

-- 1. HARDEN NOTIFICATIONS TABLE (Safety First)
-- Make 'title' nullable so it never blocks an insert if missing
ALTER TABLE public.notifications ALTER COLUMN title DROP NOT NULL;
ALTER TABLE public.notifications ALTER COLUMN type SET DEFAULT 'info';

-- 2. CREATE AUTOMATED NOTIFICATION TRIGGER FUNCTION
-- This function runs automatically whenever a prediction is updated.
CREATE OR REPLACE FUNCTION public.handle_prediction_resolution_notify()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_title TEXT;
    v_message TEXT;
    v_type TEXT;
    v_net_profit NUMERIC;
BEGIN
    -- Only run if status changed from 'pending' to something else (WIN/LOSS/ND)
    IF OLD.status = 'pending' AND NEW.status IN ('WIN', 'LOSS', 'ND') THEN
        
        v_net_profit := NEW.profit; -- Adjusted profit from the prediction update
        
        -- Default Type
        IF NEW.status = 'WIN' THEN 
            v_type := 'win';
            v_title := 'Prediction Won! 🎉';
        ELSIF NEW.status = 'LOSS' THEN 
            v_type := 'loss';
            v_title := 'Prediction Lost';
        ELSE 
            v_type := 'info';
            v_title := 'Prediction Ended';
        END IF;

        -- Construct Message
        v_message := format('%s prediction: %s (%s pts)', NEW.asset_symbol, NEW.status, v_net_profit);

        -- Insert Notification (Safe Insert)
        INSERT INTO public.notifications (user_id, type, title, message, prediction_id)
        VALUES (NEW.user_id, v_type, v_title, v_message, NEW.id);
        
    END IF;
    
    RETURN NEW;
END;
$$;

-- 3. ATTACH TRIGGER TO PREDICTIONS TABLE
DROP TRIGGER IF EXISTS on_prediction_resolved ON public.predictions;
CREATE TRIGGER on_prediction_resolved
    AFTER UPDATE ON public.predictions
    FOR EACH ROW
    WHEN (OLD.status IS DISTINCT FROM NEW.status)
    EXECUTE FUNCTION public.handle_prediction_resolution_notify();


-- 4. SIMPLIFY RESOLUTION RPC (Core Financial Logic Only)
-- This function is now PURE logic. No side effects like notification inserts.
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
        RETURN json_build_object('success', false, 'error', 'Prediction not found or already resolved');
    END IF;
    
    -- 2. Calculate Change
    v_price_change := p_close_price - v_prediction.entry_price;
    v_price_change_percent := abs(v_price_change / v_prediction.entry_price * 100);
    
    -- 3. Determine Outcome (Win/Loss Logic)
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
    
    -- 4. Update Prediction (Triggers will fire HERE automatically)
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
    
    -- 6. Return Result (Success)
    v_result := json_build_object(
        'success', true,
        'status', v_status,
        'payout', v_payout,
        'price_change_percent', v_price_change_percent
    );
    
    RETURN v_result;
    
EXCEPTION
    WHEN OTHERS THEN
        RETURN json_build_object('success', false, 'error', SQLERRM);
END;
$$;
