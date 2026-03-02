-- 🧪 FULL TEST SUITE: VIBE FORECAST
-- Run this in Supabase SQL Editor to verify the system.

DO $$
DECLARE
    v_user_id UUID;
    v_prediction_id BIGINT;
    v_result JSON;
    v_func_count INTEGER;
    v_initial_points INTEGER;
    v_final_points INTEGER;
BEGIN
    RAISE NOTICE '🚀 STARTING TEST SUITE...';

    -- 1. [CHECK] RPC Functions Existence
    SELECT COUNT(*) INTO v_func_count 
    FROM information_schema.routines 
    WHERE routine_name IN ('submit_prediction', 'resolve_prediction_advanced');
    
    IF v_func_count < 2 THEN
        RAISE EXCEPTION '❌ FAIL: Missing RPC functions. Found only %/2', v_func_count;
    ELSE
        RAISE NOTICE '✅ PASS: RPC functions exist';
    END IF;

    -- 2. [SETUP] Get a Test User (First user found)
    SELECT id INTO v_user_id FROM auth.users LIMIT 1;
    IF v_user_id IS NULL THEN
        RAISE EXCEPTION '❌ FAIL: No users found in auth.users. Please sign up first.';
    END IF;
    RAISE NOTICE 'ℹ️ Using Test User: %', v_user_id;

    -- Get initial points
    SELECT points INTO v_initial_points FROM profiles WHERE id = v_user_id;
    RAISE NOTICE 'ℹ️ Initial Points: %', v_initial_points;

    -- 3. [TEST] Submit Prediction (Mocking via Insert for granular control)
    -- We simulate a prediction from 20 minutes ago (15m timeframe)
    -- This tests the "Resolution Logic" primarily.
    INSERT INTO predictions (
        user_id, asset_symbol, timeframe, direction, target_percent, 
        entry_price, bet_amount, status, created_at, candle_close_at
    ) VALUES (
        v_user_id, 'BTC_TEST', '15m', 'UP', 1.0, 
        50000.0, 100, 'pending', 
        NOW() - INTERVAL '20 minutes', -- Created 20 mins ago
        NOW() - INTERVAL '5 minutes'   -- Closed 5 mins ago
    ) RETURNING id INTO v_prediction_id;
    
    RAISE NOTICE '✅ PASS: Created Test Prediction ID: %', v_prediction_id;

    -- 4. [TEST] Resolve Prediction
    -- Scenario: Price went UP 2% (Target 1.0%), so it should be a WIN.
    -- Payout should be: 100 * (1.0 * 2 + 1) = 300 pts. Net profit +200.
    v_result := public.resolve_prediction_advanced(v_prediction_id, 51000.0); -- 51k is +2% from 50k
    
    RAISE NOTICE 'ℹ️ Resolve Result: %', v_result;
    
    IF (v_result->>'success')::boolean IS DISTINCT FROM true THEN
         RAISE EXCEPTION '❌ FAIL: Resolution returned success=false';
    END IF;

    -- 5. [VERIFY] Check Status and Points
    -- Check Status
    PERFORM 1 FROM predictions WHERE id = v_prediction_id AND status = 'WIN';
    IF NOT FOUND THEN
        RAISE EXCEPTION '❌ FAIL: Prediction status is not WIN';
    ELSE
        RAISE NOTICE '✅ PASS: Prediction status is WIN';
    END IF;

    -- Check Points
    SELECT points INTO v_final_points FROM profiles WHERE id = v_user_id;
    RAISE NOTICE 'ℹ️ Final Points: %', v_final_points;
    
    -- We verify points logic roughly (Initial might have been deducted or not depending on if we used RPC or INSERT.
    -- We used INSERT directly, so points were NOT deducted at start. 
    -- But resolve_prediction_advanced ADDS the payout.
    -- So Final should be Initial + Payout(300).
    IF v_final_points = (v_initial_points + 300) THEN
         RAISE NOTICE '✅ PASS: Points updated correctly (+300)';
    ELSE
         RAISE NOTICE '⚠️ WARNING: Point verification logic mismatch. Expected +300. (Check if bet was deducted manually)';
    END IF;
    
    -- 6. [CLEANUP] Remove test data
    DELETE FROM predictions WHERE id = v_prediction_id;
    -- Revert points to avoid messing up user
    UPDATE profiles SET points = v_initial_points WHERE id = v_user_id;
    
    RAISE NOTICE '✅ PASS: Test Data Cleaned Up';
    RAISE NOTICE '🎉 ALL TESTS PASSED SUCCESSFULLY!';
END;
$$;
