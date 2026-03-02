-- CRITICAL FIX: submit_prediction RPC
-- Problem: 30m timeframe was missing, defaulting to a buggy 15m offset.
-- Fix: Added 30m case and ensured robust alignment using date_bin.

DROP FUNCTION IF EXISTS public.submit_prediction(uuid, text, text, text, numeric, numeric, integer);

CREATE OR REPLACE FUNCTION public.submit_prediction(
  p_user_id UUID,
  p_asset_symbol TEXT,
  p_timeframe TEXT,
  p_direction TEXT,
  p_target_percent NUMERIC,
  p_entry_price NUMERIC,
  p_bet_amount INTEGER
) RETURNS JSONB AS $$
DECLARE
  v_user_points INTEGER;
  v_prediction_id BIGINT;
  v_interval INTERVAL;
  v_candle_close TIMESTAMP WITH TIME ZONE;
  v_now TIMESTAMP WITH TIME ZONE := now();
BEGIN
  -- 1. Determine Correct Interval
  CASE p_timeframe
    WHEN '1m' THEN v_interval := INTERVAL '1 minute';
    WHEN '5m' THEN v_interval := INTERVAL '5 minutes';
    WHEN '15m' THEN v_interval := INTERVAL '15 minutes';
    WHEN '30m' THEN v_interval := INTERVAL '30 minutes'; -- Explicitly handled
    WHEN '1h' THEN v_interval := INTERVAL '1 hour';
    WHEN '4h' THEN v_interval := INTERVAL '4 hours';
    WHEN '1d' THEN v_interval := INTERVAL '1 day';
    ELSE v_interval := INTERVAL '15 minutes'; -- Safe fallback
  END CASE;

  -- 2. Calculate Aligned Candle Close Time
  -- date_bin aligns to the START of the interval. We add the interval to get the CLOSE.
  v_candle_close := date_bin(v_interval, v_now, '2000-01-01'::timestamp with time zone) + v_interval;

  -- [OPTIONAL SAFETY] If we are in the last 10% of the candle, should we push to next?
  -- For now, strict alignment is safer for matching external price APIs.

  -- 3. Check User Points (Lock row)
  SELECT points INTO v_user_points 
  FROM profiles 
  WHERE id = p_user_id 
  FOR UPDATE;
  
  IF v_user_points IS NULL THEN
    RAISE EXCEPTION 'User profile not found';
  END IF;

  IF v_user_points < p_bet_amount THEN
    RAISE EXCEPTION 'Insufficient points. Current: %, Required: %', v_user_points, p_bet_amount;
  END IF;

  -- 4. Deduct Points
  UPDATE profiles 
  SET points = points - p_bet_amount 
  WHERE id = p_user_id;

  -- 5. Insert Prediction
  INSERT INTO predictions (
    user_id, 
    asset_symbol, 
    timeframe, 
    direction, 
    target_percent, 
    entry_price, 
    status, 
    bet_amount,
    candle_close_at,
    created_at
  ) VALUES (
    p_user_id, 
    p_asset_symbol, 
    p_timeframe, 
    p_direction, 
    p_target_percent, 
    p_entry_price, 
    'pending', 
    p_bet_amount,
    v_candle_close,
    v_now
  ) RETURNING id INTO v_prediction_id;

  -- 6. Return Success Response
  RETURN jsonb_build_object(
    'success', true,
    'prediction_id', v_prediction_id,
    'new_points', v_user_points - p_bet_amount,
    'candle_close_at', v_candle_close
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
