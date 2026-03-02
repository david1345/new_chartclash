-- ==========================================
-- PRODUCTION HOTFIX: RESTORE SUBMIT_PREDICTION
-- ==========================================

-- 1. Drop the incorrect column that was accidentally added previously
ALTER TABLE public.predictions DROP COLUMN IF EXISTS candle_close_time;

-- 2. Ensure the correct column exists
ALTER TABLE public.predictions ADD COLUMN IF NOT EXISTS candle_close_at TIMESTAMP WITH TIME ZONE;
ALTER TABLE public.predictions ADD COLUMN IF NOT EXISTS timeframe TEXT NOT NULL DEFAULT '1h';
ALTER TABLE public.predictions ADD COLUMN IF NOT EXISTS comment TEXT;
ALTER TABLE public.predictions ADD COLUMN IF NOT EXISTS bet_amount INTEGER NOT NULL DEFAULT 10;

-- 3. Restore the correct submit_prediction RPC with DateTime calculation
DROP FUNCTION IF EXISTS submit_prediction(UUID, TEXT, TEXT, TEXT, NUMERIC, NUMERIC, INTEGER);

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
  v_now TIMESTAMP WITH TIME ZONE;
BEGIN
  v_now := now();

  -- 1. Determine Interval & Calculate Candle Close Time
  IF p_timeframe = '1m' THEN
    v_interval := INTERVAL '1 minute';
    v_candle_close := date_trunc('minute', v_now) + v_interval;
  ELSIF p_timeframe = '5m' THEN
    v_interval := INTERVAL '5 minutes';
    v_candle_close := date_trunc('hour', v_now) + (INTERVAL '5 minutes' * CEIL(EXTRACT(MINUTE FROM v_now) / 5.0));
  ELSIF p_timeframe = '15m' THEN
    v_interval := INTERVAL '15 minutes';
    v_candle_close := date_trunc('hour', v_now) + (INTERVAL '15 minutes' * CEIL(EXTRACT(MINUTE FROM v_now) / 15.0));
  ELSIF p_timeframe = '30m' THEN
    v_interval := INTERVAL '30 minutes';
    v_candle_close := date_trunc('hour', v_now) + (INTERVAL '30 minutes' * CEIL(EXTRACT(MINUTE FROM v_now) / 30.0));
  ELSIF p_timeframe = '1h' THEN
    v_interval := INTERVAL '1 hour';
    v_candle_close := date_trunc('hour', v_now) + v_interval;
  ELSIF p_timeframe = '4h' THEN
    v_interval := INTERVAL '4 hours';
    v_candle_close := date_trunc('day', v_now) + (INTERVAL '4 hours' * CEIL(EXTRACT(HOUR FROM v_now) / 4.0));
  ELSIF p_timeframe = '1d' THEN
    v_interval := INTERVAL '1 day';
    v_candle_close := date_trunc('day', v_now) + v_interval;
  ELSE
    -- Default to 1 hour
    v_interval := INTERVAL '1 hour';
    v_candle_close := date_trunc('hour', v_now) + v_interval;
  END IF;

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

  -- 5. Return Success Response
  RETURN jsonb_build_object(
    'success', true,
    'prediction_id', v_prediction_id,
    'new_points', v_user_points - p_bet_amount
  );
END;
$$ LANGUAGE plpgsql;

-- 4. Re-apply Integrity Constraints
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'check_direction') THEN
        ALTER TABLE predictions
          ADD CONSTRAINT check_direction CHECK (direction IN ('UP', 'DOWN'));
    END IF;

    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'check_comment_length') THEN
        ALTER TABLE predictions
          ADD CONSTRAINT check_comment_length CHECK (char_length(comment) <= 140);
    END IF;
END $$;
