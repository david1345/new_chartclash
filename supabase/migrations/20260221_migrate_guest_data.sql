-- ==============================================
-- 🚀 ChartClash Guest Migration RPC
-- MIGRATION: 2026xxxx_migrate_guest_data.sql
-- ==============================================

-- Description: Migrates a user's local guest points and predictions to their DB account upon signup/first login.
-- Atomically updates the user's total_points in profiles, and inserts their guest prediction history.

CREATE OR REPLACE FUNCTION migrate_guest_data(
    p_user_id UUID,
    p_guest_points NUMERIC,
    p_guest_predictions JSONB
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
    -- We will overwrite their starting balance with what they earned as a guest.
    -- If they had LESS than 1000 points (lost it all), we still overwrite it, 
    -- but maybe we cap it at a minimum of 0 just in case.
    
    UPDATE profiles
    SET total_points = GREATEST(p_guest_points, 0)
    WHERE id = p_user_id
    RETURNING total_points INTO v_total_points;
    
    -- 2. Insert Guest Predictions
    -- Loop through the JSONB array of predictions and insert them.
    -- We map 'ND' (No Data/Draw) to 'REFUND' to match our DB enum or keep it as 'ND' if that's the DB check constraint.
    
    IF p_guest_predictions IS NOT NULL AND jsonb_array_length(p_guest_predictions) > 0 THEN
        FOR v_prediction IN SELECT * FROM jsonb_array_elements(p_guest_predictions)
        LOOP
            INSERT INTO predictions (
                user_id,
                asset_symbol,
                timeframe,
                direction,
                target_percent,
                entry_price,
                close_price, -- Map actual_price to close_price
                bet_amount,
                profit_loss, -- Map profit to profit_loss
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
                -- Map ND to REFUND or ND based on DB check constraint. The DB schema accepts 'WIN', 'LOSS', 'REFUND', 'pending'
                CASE 
                    WHEN v_prediction.value->>'status' = 'ND' THEN 'REFUND'
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
