-- 1단계: 누락된 컬럼 추가
-- predictions 테이블에 필요한 컬럼들이 존재하는지 확인하고 추가합니다.

ALTER TABLE public.predictions
  ADD COLUMN IF NOT EXISTS timeframe TEXT NOT NULL DEFAULT '1h',
  ADD COLUMN IF NOT EXISTS comment TEXT,
  ADD COLUMN IF NOT EXISTS bet_amount INTEGER NOT NULL DEFAULT 10,
  ADD COLUMN IF NOT EXISTS candle_close_time TIMESTAMP WITH TIME ZONE;

-- 2단계: 트랜잭션 함수 구현 (포인트 차감 + 예측 저장 원자적 처리)
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
BEGIN
  -- 1. Check User Points (Lock row for update to prevent race conditions)
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

  -- 2. Deduct Points
  UPDATE profiles 
  SET points = points - p_bet_amount 
  WHERE id = p_user_id;

  -- 3. Insert Prediction
  INSERT INTO predictions (
    user_id, 
    asset_symbol, 
    timeframe, 
    direction, 
    target_percent, 
    entry_price, 
    status, 
    bet_amount
  ) VALUES (
    p_user_id, 
    p_asset_symbol, 
    p_timeframe, 
    p_direction, 
    p_target_percent, 
    p_entry_price, 
    'pending', 
    p_bet_amount
  ) RETURNING id INTO v_prediction_id;

  -- 4. Return Success Response
  RETURN jsonb_build_object(
    'success', true,
    'prediction_id', v_prediction_id,
    'new_points', v_user_points - p_bet_amount
  );
END;
$$ LANGUAGE plpgsql;

-- 3단계: 제약 조건 추가
-- 데이터 무결성을 위한 체크 제약조건을 추가합니다.

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
