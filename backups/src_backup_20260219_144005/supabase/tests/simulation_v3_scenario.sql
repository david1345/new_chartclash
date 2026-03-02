-- Simulation Suite V3.0 (Fixed)
-- Purpose: Verify Economy V3.0 Logic & System Stability
-- Scenarios:
-- 1. User A (Standard Win): Bet 100, UP, TF=1h (1.2x), No Target. Result: 2.5% UP. -> Profit = 96. (+91 after tax)
-- 2. User B (Loss): Bet 100, DOWN, TF=15m. Result: 1% UP. -> Loss. Refund 0.
-- 3. User C (Bonus Win): Bet 100, UP, Target 1.0% (40pt). Result: 1.5% UP. -> Profit = (96 + 40) * 0.95 = 129.
-- 4. User D (No Decision): Bet 100, UP. Result: 0% Flat. -> Refund 100.
-- 5. User E (Streak): Already Streak 4. Win. -> New Streak 5 (Multiplier 2.5x).

DO $$
DECLARE
    u_a UUID; u_b UUID; u_c UUID; u_d UUID; u_e UUID;
    p_id_a BIGINT; p_id_b BIGINT; p_id_c BIGINT; p_id_d BIGINT; p_id_e BIGINT;
    r_json JSON;
BEGIN
    RAISE NOTICE '🚀 Starting V3.0 Simulation...';

    -- 0. Cleanup (Safe Delete)
    DELETE FROM predictions WHERE asset_symbol LIKE 'TEST-%';
    DELETE FROM profiles WHERE email LIKE 'sim_user_%@test.com';

    -- 1. Create Users
    INSERT INTO auth.users (id, email) VALUES (gen_random_uuid(), 'sim_user_a@test.com') RETURNING id INTO u_a;
    INSERT INTO auth.users (id, email) VALUES (gen_random_uuid(), 'sim_user_b@test.com') RETURNING id INTO u_b;
    INSERT INTO auth.users (id, email) VALUES (gen_random_uuid(), 'sim_user_c@test.com') RETURNING id INTO u_c;
    INSERT INTO auth.users (id, email) VALUES (gen_random_uuid(), 'sim_user_d@test.com') RETURNING id INTO u_d;
    INSERT INTO auth.users (id, email) VALUES (gen_random_uuid(), 'sim_user_e@test.com') RETURNING id INTO u_e;

    -- Profiles 
    INSERT INTO public.profiles (id, email, username, points, streak) VALUES 
    (u_a, 'sim_user_a@test.com', 'User A', 1000, 0),
    (u_b, 'sim_user_b@test.com', 'User B', 1000, 0),
    (u_c, 'sim_user_c@test.com', 'User C', 1000, 0), -- Setup for Bonus
    (u_d, 'sim_user_d@test.com', 'User D', 1000, 0),
    (u_e, 'sim_user_e@test.com', 'User E', 1000, 4) -- Start with Streak 4
    ON CONFLICT (id) DO UPDATE SET points=EXCLUDED.points, streak=EXCLUDED.streak;

    RAISE NOTICE '✅ Users Created.';

    -- 2. Place Bets (Direct Insert)
    -- FIX: Added candle_close_at (NOT NULL constraint)
    
    -- User A: Std Win (1h = 1.2x)
    INSERT INTO predictions (user_id, asset_symbol, timeframe, direction, target_percent, entry_price, bet_amount, status, candle_close_at)
    VALUES (u_a, 'TEST-BTC', '1h', 'UP', 0.5, 50000, 100, 'pending', NOW() + interval '1 hour') RETURNING id INTO p_id_a;

    -- User B: Loss
    INSERT INTO predictions (user_id, asset_symbol, timeframe, direction, target_percent, entry_price, bet_amount, status, candle_close_at)
    VALUES (u_b, 'TEST-ETH', '15m', 'DOWN', 0.5, 3000, 100, 'pending', NOW() + interval '15 minutes') RETURNING id INTO p_id_b;

    -- User C: Bonus Win (Target 1.0% = +40pt)
    INSERT INTO predictions (user_id, asset_symbol, timeframe, direction, target_percent, entry_price, bet_amount, status, candle_close_at)
    VALUES (u_c, 'TEST-SOL', '1h', 'UP', 1.0, 100, 100, 'pending', NOW() + interval '1 hour') RETURNING id INTO p_id_c;

    -- User D: ND
    INSERT INTO predictions (user_id, asset_symbol, timeframe, direction, target_percent, entry_price, bet_amount, status, candle_close_at)
    VALUES (u_d, 'TEST-XRP', '1h', 'UP', 0.5, 1.0, 100, 'pending', NOW() + interval '1 hour') RETURNING id INTO p_id_d;

    -- User E: Streak (4 -> 5)
    INSERT INTO predictions (user_id, asset_symbol, timeframe, direction, target_percent, entry_price, bet_amount, status, candle_close_at)
    VALUES (u_e, 'TEST-DOGE', '1h', 'UP', 0.5, 0.1, 100, 'pending', NOW() + interval '1 hour') RETURNING id INTO p_id_e;

    RAISE NOTICE '✅ Bets Placed.';

    -- 3. Resolve Scenarios (Simulating Market Outcomes)
    
    -- Step 2.1: Deduct Points First (To simulate reality where points are deducted at bet time)
    -- Since we did Direct Insert, trigger might not have run or we want to be sure via manual update for sim consistency.
    -- Assuming app logic deducts 100.
    UPDATE profiles SET points = points - 100 WHERE id IN (u_a, u_b, u_c, u_d, u_e);

    -- User A: Win (+2.5%)
    PERFORM resolve_prediction_advanced(p_id_a, 51250::NUMERIC, 1.0);

    -- User B: Loss (+1%) -> Wrong Dir
    PERFORM resolve_prediction_advanced(p_id_b, 3030::NUMERIC, 1.0);

    -- User C: Win (+1.5%) + Target Hit
    PERFORM resolve_prediction_advanced(p_id_c, 101.5::NUMERIC, 1.0);

    -- User D: ND (0%)
    PERFORM resolve_prediction_advanced(p_id_d, 1.0::NUMERIC, 1.0);

    -- User E: Win (+10%) + Target Hit
    PERFORM resolve_prediction_advanced(p_id_e, 0.11::NUMERIC, 1.0);

    RAISE NOTICE '✅ Resolution Complete.';

END $$;

-- 4. Verification Report
SELECT 
    p.username,
    u.email,
    p.points as final_points,
    p.streak as final_streak,
    pred.status,
    pred.profit,
    pred.asset_symbol
FROM profiles p
JOIN auth.users u ON u.id = p.id
LEFT JOIN predictions pred ON pred.user_id = p.id
WHERE u.email LIKE 'sim_user_%@test.com'
ORDER BY u.email;
