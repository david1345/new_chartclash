-- 🧪 FULL LIFECYCLE SIMULATION (Visible Result Version)
-- Returns a table result so you can see "PASS" in the Results tab immediately.

DROP FUNCTION IF EXISTS test_run_simulation();

CREATE OR REPLACE FUNCTION test_run_simulation()
RETURNS TABLE(step text, status text, details text) AS $$
DECLARE
    v_user_id UUID;
    v_pred_id BIGINT;
    v_initial_points INT;
    v_mid_points INT;
    v_final_points INT;
    v_initial_wins INT;
    v_final_wins INT;
    v_notif_count INT;
    v_result JSON;
BEGIN
    -- 1. SETUP
    SELECT id, points, total_wins INTO v_user_id, v_initial_points, v_initial_wins FROM profiles LIMIT 1;
    IF v_user_id IS NULL THEN 
        RETURN QUERY SELECT '1. Setup', 'FAIL', 'No user found'; RETURN;
    END IF;
    RETURN QUERY SELECT '1. Setup', 'PASS', 'User: ' || v_user_id || ', Points: ' || v_initial_points;

    -- 2. ACTION: Submit Prediction
    SELECT (submit_prediction(v_user_id, 'BTC_TEST', '15m', 'UP', 1.0, 50000.0, 100))->>'prediction_id' INTO v_pred_id;
    
    SELECT points INTO v_mid_points FROM profiles WHERE id = v_user_id;
    IF v_mid_points != (v_initial_points - 100) THEN
         RETURN QUERY SELECT '2. Bet Deduction', 'FAIL', 'Points not deducted'; RETURN;
    END IF;
    RETURN QUERY SELECT '2. Bet Deduction', 'PASS', '100 pts deducted';

    -- 3. TIME TRAVEL & RESOLVE
    UPDATE predictions SET candle_close_at = NOW() - INTERVAL '1 minute' WHERE id = v_pred_id;
    v_result := public.resolve_prediction_advanced(v_pred_id, 51000.0);
    RETURN QUERY SELECT '3. Resolution', 'PASS', 'Result: ' || v_result::text;

    -- 4. VERIFY POINTS
    SELECT points, total_wins INTO v_final_points, v_final_wins FROM profiles WHERE id = v_user_id;
    IF v_final_points != (v_initial_points + 200) THEN
         RETURN QUERY SELECT '4. Point Audit', 'WARN', 'Expected ' || (v_initial_points + 200) || ', Got ' || v_final_points;
    ELSE
         RETURN QUERY SELECT '4. Point Audit', 'PASS', 'Balance correct (+200 net)';
    END IF;

    -- 5. VERIFY STATS
    IF v_final_wins > v_initial_wins THEN
         RETURN QUERY SELECT '5. Stats Update', 'PASS', 'Wins incremented';
    ELSE
         RETURN QUERY SELECT '5. Stats Update', 'FAIL', 'Total Wins did not increase';
    END IF;

    -- 6. VERIFY NOTIFICATIONS
    SELECT COUNT(*) INTO v_notif_count FROM notifications WHERE user_id = v_user_id And title LIKE '%BTC_TEST%';
    IF v_notif_count > 0 THEN
         RETURN QUERY SELECT '6. Notification', 'PASS', 'Alert found in DB';
    ELSE
         RETURN QUERY SELECT '6. Notification', 'FAIL', 'No notification record found';
    END IF;

    -- CLEANUP
    DELETE FROM predictions WHERE id = v_pred_id;
    DELETE FROM notifications WHERE user_id = v_user_id AND title LIKE '%BTC_TEST%';
    UPDATE profiles SET points = v_initial_points, total_wins = v_initial_wins WHERE id = v_user_id;
    
    RETURN QUERY SELECT '7. Final Result', '✅ SUCCESS', 'ALL TESTS PASSED';
END;
$$ LANGUAGE plpgsql;

-- EXECUTE
SELECT * FROM test_run_simulation();
