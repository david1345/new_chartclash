-- 🛠️ REVERT TO PRODUCTION PACKAGE (SQL)
-- Run this in your Supabase SQL Editor to restore original English notifications.

CREATE OR REPLACE FUNCTION public.resolve_prediction_advanced(
    p_id BIGINT,
    p_close_price NUMERIC,
    p_open_price NUMERIC DEFAULT NULL
)
RETURNS JSON
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_prediction RECORD;
    v_profile RECORD;
    v_is_win BOOLEAN;
    v_status TEXT;
    v_payout INTEGER := 0;
    v_final_profit_pts NUMERIC := 0;
    v_open_price NUMERIC;
BEGIN
    -- 1. Fetch Prediction
    SELECT * INTO v_prediction FROM predictions WHERE id = p_id AND status = 'pending' FOR UPDATE;
    IF NOT FOUND THEN RETURN json_build_object('success', false, 'error', 'Already resolved'); END IF;
    
    v_open_price := COALESCE(p_open_price, v_prediction.entry_price);
    SELECT * INTO v_profile FROM profiles WHERE id = v_prediction.user_id FOR UPDATE;

    -- 2. Basic Win/Loss Logic (English-Only)
    v_is_win := (v_prediction.direction = 'UP' AND p_close_price > v_open_price) OR 
                (v_prediction.direction = 'DOWN' AND p_close_price < v_open_price);
    
    IF v_is_win THEN
        v_status := 'WIN';
        v_final_profit_pts := (v_prediction.bet_amount * 0.8); -- Base multiplier
        v_payout := v_prediction.bet_amount + ROUND(v_final_profit_pts);
    ELSE
        v_status := 'LOSS';
        v_payout := 0;
        v_final_profit_pts := -v_prediction.bet_amount;
    END IF;

    -- 3. Update Database
    UPDATE profiles SET points = points + v_payout, streak = (CASE WHEN v_is_win THEN streak + 1 ELSE 0 END) WHERE id = v_prediction.user_id;
    UPDATE predictions SET 
        status = v_status, 
        actual_price = p_close_price, 
        entry_price = v_open_price, 
        profit = ROUND(v_final_profit_pts), 
        resolved_at = now() 
    WHERE id = p_id;
    
    -- 4. Revert Notification to Original English Format
    -- Check if 'title' exists in your schema before running if unsure
    INSERT INTO notifications (user_id, type, title, message, points_change, is_read)
    VALUES (
        v_prediction.user_id, 
        LOWER(v_status), 
        v_prediction.asset_symbol || ' Result',
        format('%s: %s (%s pts)', v_prediction.asset_symbol, v_status, ROUND(v_final_profit_pts)),
        ROUND(v_final_profit_pts),
        FALSE
    );

    RETURN json_build_object('success', true, 'status', v_status, 'profit', ROUND(v_final_profit_pts));
END;
$$;
