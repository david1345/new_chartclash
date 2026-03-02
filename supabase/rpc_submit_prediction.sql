-- RPC: submit_prediction
-- Updated to calculate candle_close_at automatically

CREATE OR REPLACE FUNCTION submit_prediction(
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
BEGIN
  -- 1. Determine Interval & Candle Close Time
  IF p_timeframe = '1m' THEN v_interval := INTERVAL '1 minute';
  ELSIF p_timeframe = '5m' THEN v_interval := INTERVAL '5 minutes';
  ELSIF p_timeframe = '15m' THEN v_interval := INTERVAL '15 minutes';
  ELSIF p_timeframe = '1h' THEN v_interval := INTERVAL '1 hour';
  ELSIF p_timeframe = '4h' THEN v_interval := INTERVAL '4 hours';
  ELSIF p_timeframe = '1d' THEN v_interval := INTERVAL '1 day';
  ELSE 
     -- Default or fallback
     v_interval := INTERVAL '1 hour';
  END IF;

  -- date_bin returns the BIN START (floor). We want the CLOSE (ceiling), so we add the interval.
  -- Requires Postgres 14+. Supabase usually supports this.
  -- If date_bin is not available, we can use alternative, but let's assume PG14+.
  v_candle_close := date_bin(v_interval, now(), '2000-01-01'::timestamp with time zone) + v_interval;

  -- 2. Check User Points (Lock row)
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

  -- 3. Deduct Points
  UPDATE profiles 
  SET points = points - p_bet_amount 
  WHERE id = p_user_id;

  -- 4. Insert Prediction
  INSERT INTO predictions (
    user_id, 
    asset_symbol, 
    timeframe, 
    direction, 
    target_percent, 
    entry_price, 
    status, 
    bet_amount,
    candle_close_at,  -- ✅ Added
    created_at        -- Explicitly set to ensure alignment
  ) VALUES (
    p_user_id, 
    p_asset_symbol, 
    p_timeframe, 
    p_direction, 
    p_target_percent, 
    p_entry_price, 
    'pending', 
    p_bet_amount,
    v_candle_close,   -- ✅ Calculated Value
    now()
  ) RETURNING id INTO v_prediction_id;

  -- 5. Return Success Response
  RETURN jsonb_build_object(
    'success', true,
    'prediction_id', v_prediction_id,
    'new_points', v_user_points - p_bet_amount
  );
END;
$$ LANGUAGE plpgsql;
