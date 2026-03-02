-- ==============================================
-- 🚀 ChartClash Guest Migration RPC (V2)
-- MIGRATION: 2026xxxx_migrate_guest_data_v2.sql
-- ==============================================

-- Description: Migrates a user's local guest points and predictions to their DB account upon signup/first login.
-- Includes options to transfer points, transfer history, and ensures a minimum of 1000 points.

CREATE OR REPLACE FUNCTION migrate_guest_data(
    p_user_id UUID,
    p_guest_points NUMERIC,
    p_guest_predictions JSONB,
    p_transfer_points BOOLEAN DEFAULT TRUE,
    p_transfer_history BOOLEAN DEFAULT TRUE
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_total_points NUMERIC;
    v_prediction RECORD;
    v_inserted_count INT := 0;
BEGIN
    -- 1. Update Profile Points
    -- We assume the user profile exists (auth trigger creates it with 1000 points).
    -- If p_transfer_points is false, we don't touch their balance.
    -- If it's true, we give them GREATEST(p_guest_points, 1000) so they aren't penalized for losing as a guest.
    
    IF p_transfer_points THEN
        UPDATE profiles
        SET points = GREATEST(p_guest_points, 1000)
        WHERE id = p_user_id
        RETURNING points INTO v_total_points;
    ELSE
        SELECT points INTO v_total_points FROM profiles WHERE id = p_user_id;
    END IF;
    
    -- 2. Insert Guest Predictions
    IF p_transfer_history AND p_guest_predictions IS NOT NULL AND jsonb_array_length(p_guest_predictions) > 0 THEN
        FOR v_prediction IN SELECT * FROM jsonb_array_elements(p_guest_predictions)
        LOOP
            INSERT INTO predictions (
                user_id,
                asset_symbol,
                timeframe,
                direction,
                target_percent,
                entry_price,
                actual_price, 
                bet_amount,
                profit, 
                status,
                created_at,
                candle_close_at,
                resolved_at
            ) VALUES (
                p_user_id,
                v_prediction.value->>'asset_symbol',
                v_prediction.value->>'timeframe',
                v_prediction.value->>'direction',
                (v_prediction.value->>'target_percent')::NUMERIC,
                (v_prediction.value->>'entry_price')::NUMERIC,
                (v_prediction.value->>'actual_price')::NUMERIC,
                (v_prediction.value->>'bet_amount')::NUMERIC,
                (v_prediction.value->>'profit')::NUMERIC,
                CASE 
                    WHEN v_prediction.value->>'status' = 'ND' THEN 'ND'
                    WHEN v_prediction.value->>'status' = 'pending' THEN 'pending'
                    WHEN v_prediction.value->>'status' = 'WIN' THEN 'WIN'
                    WHEN v_prediction.value->>'status' = 'LOSS' THEN 'LOSS'
                    ELSE 'pending'
                END,
                (v_prediction.value->>'created_at')::TIMESTAMPTZ,
                (v_prediction.value->>'candle_close_at')::TIMESTAMPTZ,
                (v_prediction.value->>'resolved_at')::TIMESTAMPTZ
            );
            
            v_inserted_count := v_inserted_count + 1;
        END LOOP;
    END IF;
    
    -- Return success payload with summary
    RETURN jsonb_build_object(
        'success', true,
        'new_points_balance', v_total_points,
        'migrated_predictions_count', v_inserted_count,
        'message', 'Guest data migrated successfully'
    );
    
EXCEPTION WHEN OTHERS THEN
    -- If anything fails, return error payload
    RETURN jsonb_build_object(
        'success', false,
        'message', SQLERRM
    );
END;
$$;
