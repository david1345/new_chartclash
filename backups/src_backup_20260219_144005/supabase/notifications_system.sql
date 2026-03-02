-- Notifications System Update

-- 1. Create Notifications Table
CREATE TABLE IF NOT EXISTS public.notifications (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES public.profiles(id) NOT NULL,
    type TEXT NOT NULL, -- 'win', 'loss', 'streak', 'rank', 'system'
    title TEXT NOT NULL,
    message TEXT NOT NULL,
    points_change INT DEFAULT 0,
    is_read BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Index for fast lookup by user
CREATE INDEX IF NOT EXISTS idx_notifications_user_id ON public.notifications(user_id);

-- RLS Policies
ALTER TABLE public.notifications ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own notifications" 
ON public.notifications FOR SELECT 
USING (auth.uid() = user_id);

-- Service Role (and RPC) can insert/update
CREATE POLICY "Service Role can manage notifications"
ON public.notifications FOR ALL
USING (auth.uid() = user_id); 

-- IMPORTANT: Enable Realtime
ALTER PUBLICATION supabase_realtime ADD TABLE notifications;

-- 2. Update Resolution RPC to insert notifications
DROP FUNCTION IF EXISTS public.resolve_prediction_advanced(bigint, numeric);

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
  
  -- Notification vars
  v_notif_title TEXT;
  v_notif_msg TEXT;
  v_notif_type TEXT;
  
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

  -- 5. 목표 달성 여부 (Target Hit)
  -- 승패가 우선, 목표 달성은 보너스/조건
  IF v_status = 'WIN' AND ABS(v_actual_change) >= COALESCE(v_pred.target_percent, 0) THEN
    v_is_target_hit := TRUE;
  END IF;
  
  -- 목표(Target Percent)를 달성하지 못했다면 WIN이어도 패배 처리하는 룰이라면 여기서 수정해야 함.
  -- 현재 Vibe Forecast 룰: "hit your volatility target".
  -- 즉, 방향이 맞아도 Target%에 도달 못하면 실패로 간주해야 함?
  -- Step 684 문구: "Forecast its next move, and hit your volatility target".
  -- Step 664 문구: "If the candle closes in your predicted direction and reaches your target, you earn points."
  -- 따라서 Target 미달성 시 'LOSE'로 처리해야 함!! (기존 로직 수정 필요?)
  -- 기존 로직(Step 734)은 v_status='WIN' 이면 보상 계산했음. Target Hit 여부는 v_is_target_hit 변수에만 담음.
  -- 룰을 엄격하게 적용: Target 미달성 = LOSE.
  
  IF v_status = 'WIN' AND v_is_target_hit = FALSE THEN
     v_status := 'LOSE'; -- 방향은 맞았으나 타겟 미달
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
    -- 현재 streak가 예: 2연승 중 -> 이번 승리로 3연승 달성 -> 보너스 적용?
    -- 보통 "현재 3연승 상태에서 이기면 보너스" vs "이번 승리로 3연승이 되면 보너스"
    -- 여기서는 직전 상태 기준(v_user_profile.streak_count)으로 계산됨. 
    -- 조금 더 관대하게: (streak_count + 1) 기준으로 줄 수도 있음. 현재는 보수적(직전 기준).
    IF COALESCE(v_user_profile.streak_count, 0) >= 2 THEN v_streak_mult := 1.1; END IF; -- 2연승 후 3번째 도전부터 보너스?
    IF COALESCE(v_user_profile.streak_count, 0) >= 4 THEN v_streak_mult := 1.3; END IF; -- 4연승 후 5번째 도전부터 보너스?
    
    -- NOTE: Step 734 기존 로직(3, 5) 유지하되, 약간 조정.
    -- 만약 Streak 보너스를 강조하고 싶다면 이번 판이 3번째(0->1->2->3) 승리일 때도 줘야 함.
    -- 일단 기존 로직 따름.

    -- 최종 보상 = 베팅액 * (가중치 곱) * 하우스엣지
    v_raw_reward := v_pred.bet_amount * v_tf_mult * v_vol_mult * v_streak_mult;
    v_final_reward := FLOOR(v_raw_reward * v_house_edge);
    
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
    
    -- Notification Prep (WIN)
    v_notif_type := 'win';
    v_notif_title := '✅ ' || v_pred.asset_symbol || ' ' || v_pred.timeframe || ' ' || v_pred.direction || ' Success';
    
    -- Streak Message check
    IF v_streak_mult > 1.0 THEN
       v_notif_msg := 'Target hit! Streak Bonus Active! 🔥 Reward: +' || v_final_reward || ' pts';
    ELSE
       v_notif_msg := 'Target hit. Great call! Reward: +' || v_final_reward || ' pts';
    END IF;
    
    -- Streak Milestone Notification (Optional separate, or combined)
    -- If (streak+1) is 3, 5, 10...
    -- Simpler to keep one notification per event.

  ELSIF v_status = 'LOSE' THEN
    UPDATE public.profiles 
    SET 
      streak_count = 0 -- 연승 초기화
    WHERE id = v_pred.user_id;

    -- Notification Prep (LOSE)
    v_notif_type := 'loss';
    v_notif_title := '❌ ' || v_pred.asset_symbol || ' ' || v_pred.timeframe || ' ' || v_pred.direction || ' Missed';
    v_notif_msg := 'Target missed. Points deducted: -' || v_pred.bet_amount || ' pts';
    v_final_reward := -1 * v_pred.bet_amount; -- For DB record (negative change)

  ELSIF v_status = 'ND' THEN -- 무효
    UPDATE public.profiles 
    SET points = points + v_pred.bet_amount -- 원금만 반환
    WHERE id = v_pred.user_id;
    
    -- Notification Prep (ND)
    v_notif_type := 'info';
    v_notif_title := 'Use ' || v_pred.asset_symbol || ' No Decision';
    v_notif_msg := 'Price did not change. Stake returned.';
    v_final_reward := 0;
  END IF;

  -- 8. Insert Notification
  INSERT INTO public.notifications (user_id, type, title, message, points_change, is_read)
  VALUES (v_pred.user_id, v_notif_type, v_notif_title, v_notif_msg, v_final_reward, FALSE);

  RETURN jsonb_build_object(
    'id', p_id, 
    'status', v_status, 
    'payout', v_final_reward,
    'actual_change', v_actual_change
  );
END;
$$;
