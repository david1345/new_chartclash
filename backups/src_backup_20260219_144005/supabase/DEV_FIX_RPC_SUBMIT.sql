-- [RPC] Ultimate Submit Prediction (Supports AI Channels & Opinions)
-- This is needed for the Analyst Hub bots to function.

CREATE OR REPLACE FUNCTION public.submit_prediction(
  p_user_id UUID,
  p_asset_symbol TEXT,
  p_timeframe TEXT,
  p_direction TEXT,
  p_target_percent NUMERIC,
  p_entry_price NUMERIC,
  p_bet_amount INTEGER,
  p_is_opinion BOOLEAN DEFAULT FALSE,
  p_channel TEXT DEFAULT 'main'
) RETURNS JSONB 
LANGUAGE plpgsql 
SECURITY DEFINER 
AS $$
DECLARE
  v_user_points INTEGER;
  v_prediction_id BIGINT;
  v_interval INTERVAL;
  v_candle_close TIMESTAMP WITH TIME ZONE;
BEGIN
  -- 1. Timeframe Logic
  IF p_timeframe = '1m' THEN v_interval := INTERVAL '1 minute';
  ELSIF p_timeframe = '5m' THEN v_interval := INTERVAL '5 minutes';
  ELSIF p_timeframe = '15m' THEN v_interval := INTERVAL '15 minutes';
  ELSIF p_timeframe = '30m' THEN v_interval := INTERVAL '30 minutes';
  ELSIF p_timeframe = '1h' THEN v_interval := INTERVAL '1 hour';
  ELSIF p_timeframe = '4h' THEN v_interval := INTERVAL '4 hours';
  ELSIF p_timeframe = '1d' THEN v_interval := INTERVAL '1 day';
  ELSE v_interval := INTERVAL '15 minutes';
  END IF;

  v_candle_close := date_bin(v_interval, now(), '2000-01-01'::timestamp with time zone) + v_interval;

  -- 2. Bypass points check for AI opinions (p_bet_amount should be 0)
  IF NOT p_is_opinion THEN
      SELECT points INTO v_user_points FROM profiles WHERE id = p_user_id FOR UPDATE;
      IF v_user_points IS NULL THEN RAISE EXCEPTION 'User profile not found'; END IF;
      IF v_user_points < p_bet_amount THEN RAISE EXCEPTION 'Insufficient points'; END IF;

      -- Deduct Points
      UPDATE profiles SET points = points - p_bet_amount WHERE id = p_user_id;
  END IF;

  -- 3. Insert Prediction (Include channel and is_opinion)
  INSERT INTO predictions (
    user_id, asset_symbol, timeframe, direction, target_percent, 
    entry_price, status, bet_amount, candle_close_at, created_at,
    is_opinion, channel
  ) VALUES (
    p_user_id, p_asset_symbol, p_timeframe, p_direction, p_target_percent, 
    p_entry_price, 'pending', p_bet_amount, v_candle_close, now(),
    p_is_opinion, p_channel
  ) RETURNING id INTO v_prediction_id;

  RETURN jsonb_build_object(
    'success', true, 
    'prediction_id', v_prediction_id, 
    'is_opinion', p_is_opinion,
    'channel', p_channel
  );
END;
$$;
