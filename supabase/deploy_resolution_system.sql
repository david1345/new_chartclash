-- 배포: 보상 및 정산 시스템 (Resolution System)
-- 이 스크립트는 예측 결과 정산에 필요한 컬럼을 추가하고, 핵심 정산 함수를 생성합니다.

-- 1. 필수 컬럼 추가 (안전하게 존재 여부 확인)
ALTER TABLE public.profiles 
  ADD COLUMN IF NOT EXISTS streak_count INT DEFAULT 0,
  ADD COLUMN IF NOT EXISTS total_earnings NUMERIC DEFAULT 0;

ALTER TABLE public.predictions 
  ADD COLUMN IF NOT EXISTS payout_amount INT DEFAULT 0,
  ADD COLUMN IF NOT EXISTS multipliers JSONB DEFAULT '{}'::jsonb,
  ADD COLUMN IF NOT EXISTS close_price NUMERIC,
  ADD COLUMN IF NOT EXISTS actual_change_percent NUMERIC,
  ADD COLUMN IF NOT EXISTS is_target_hit BOOLEAN DEFAULT FALSE,
  ADD COLUMN IF NOT EXISTS resolved_at TIMESTAMP WITH TIME ZONE;

-- 2. 정산 함수 정의 (resolve_prediction_advanced)
-- API에서 이 함수를 호출하여 승패를 판단하고 보상을 지급합니다.

CREATE OR REPLACE FUNCTION public.resolve_prediction_advanced(
  p_id BIGINT, 
  p_close_price NUMERIC
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_pred RECORD;
  v_user_profile RECORD;
  v_status TEXT;
  v_is_target_hit BOOLEAN := FALSE;
  v_actual_change NUMERIC;
  
  -- Multipliers (가중치)
  v_tf_mult NUMERIC := 1.0;
  v_vol_mult NUMERIC := 1.0;
  v_crowd_mult NUMERIC := 1.0;
  v_streak_mult NUMERIC := 1.0;
  v_house_edge NUMERIC := 0.92; -- 8% 수수료
  
  v_raw_reward NUMERIC;
  v_final_reward INT;
  
BEGIN
  -- 1. 예측 정보 조회
  SELECT * INTO v_pred FROM public.predictions WHERE id = p_id;
  IF NOT FOUND THEN RETURN jsonb_build_object('error', 'Prediction not found'); END IF;

  -- 2. User 조회
  SELECT * INTO v_user_profile FROM public.profiles WHERE id = v_pred.user_id;

  -- 3. 실현 수익률 계산
  -- entry_price가 0이면 에러 방지
  IF v_pred.entry_price = 0 THEN
      v_actual_change := 0;
  ELSE
      v_actual_change := ROUND(((p_close_price - v_pred.entry_price) / v_pred.entry_price) * 100, 4);
  END IF;

  -- 4. 승패 판정 (WIN/LOSE/ND)
  v_status := 'LOSE'; -- 기본값
  
  IF p_close_price = v_pred.entry_price THEN
    v_status := 'ND'; -- 무효 (가격 변동 없음)
  ELSIF v_pred.direction = 'UP' AND p_close_price > v_pred.entry_price THEN
    v_status := 'WIN';
  ELSIF v_pred.direction = 'DOWN' AND p_close_price < v_pred.entry_price THEN
    v_status := 'WIN';
  END IF;

  -- 5. 목표 달성 여부 (Target Hit) - 옵션: 목표 미달성시 보상 삭감 로직 등이 가능하나, 현재는 승패가 우선
  IF v_status = 'WIN' AND ABS(v_actual_change) >= COALESCE(v_pred.target_percent, 0) THEN
    v_is_target_hit := TRUE;
  END IF;

  -- 6. 보상 계산 (WIN인 경우에만)
  v_final_reward := 0;

  IF v_status = 'WIN' THEN
    -- A. Timeframe 가중치
    IF v_pred.timeframe = '15m' THEN v_tf_mult := 1.0;
    ELSIF v_pred.timeframe = '30m' THEN v_tf_mult := 1.2;
    ELSIF v_pred.timeframe = '1h' THEN v_tf_mult := 1.5;
    ELSIF v_pred.timeframe = '4h' THEN v_tf_mult := 2.2;
    ELSIF v_pred.timeframe = '1d' THEN v_tf_mult := 3.5;
    END IF;

    -- B. 목표 수익률 가중치 (난이도)
    IF v_pred.target_percent <= 0.5 THEN v_vol_mult := 1.0;
    ELSIF v_pred.target_percent <= 1.0 THEN v_vol_mult := 1.2;
    ELSIF v_pred.target_percent <= 1.5 THEN v_vol_mult := 1.5;
    ELSE v_vol_mult := 2.0;
    END IF;

    -- C. 연승 가중치
    IF COALESCE(v_user_profile.streak_count, 0) >= 3 THEN v_streak_mult := 1.1; END IF;
    IF COALESCE(v_user_profile.streak_count, 0) >= 5 THEN v_streak_mult := 1.3; END IF;

    -- 최종 보상 = 베팅액 * (가중치 곱) * 하우스엣지
    v_raw_reward := v_pred.bet_amount * v_tf_mult * v_vol_mult * v_streak_mult;
    v_final_reward := FLOOR(v_raw_reward * v_house_edge);
    
    -- 승리 시 베팅액 원금도 돌려줘야 함? 
    -- 보통 배당게임은 (원금 + 수익)을 지급하거나, 순수익만 지급.
    -- 여기서는 profiles.points가 '지갑' 개념이므로, 베팅 시 차감된 원금을 포함해서 돌려주거나, 
    -- 차감된 상태에서 순수익만 더해주는 방식.
    -- 로직: set points = points + v_pred.bet_amount (원금) + v_final_reward (수익)
  END IF;

  -- 7. DB 업데이트 (트랜잭션)
  
  -- 예측 결과 저장
  UPDATE public.predictions
  SET 
    close_price = p_close_price,
    actual_change_percent = v_actual_change,
    status = v_status,
    is_target_hit = v_is_target_hit,
    payout_amount = v_final_reward,
    resolved_at = NOW(),
    multipliers = jsonb_build_object(
      'timeframe', v_tf_mult,
      'volatility', v_vol_mult,
      'streak', v_streak_mult,
      'raw_payout', v_final_reward
    )
  WHERE id = p_id;

  -- 유저 포인트 및 전적 업데이트
  IF v_status = 'WIN' THEN
    UPDATE public.profiles 
    SET 
      points = points + v_pred.bet_amount + v_final_reward, -- 원금 반환 + 수익 지급
      streak_count = COALESCE(streak_count, 0) + 1,
      total_earnings = COALESCE(total_earnings, 0) + v_final_reward
    WHERE id = v_pred.user_id;
  ELSIF v_status = 'LOSE' THEN
    UPDATE public.profiles 
    SET 
      streak_count = 0 -- 연승 초기화
    WHERE id = v_pred.user_id;
  ELSIF v_status = 'ND' THEN -- 무효
    UPDATE public.profiles 
    SET points = points + v_pred.bet_amount -- 원금만 반환
    WHERE id = v_pred.user_id;
  END IF;

  RETURN jsonb_build_object(
    'id', p_id, 
    'status', v_status, 
    'payout', v_final_reward,
    'actual_change', v_actual_change
  );
END;
$$;
