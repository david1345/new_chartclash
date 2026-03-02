
-- 핫픽스: 알림 테이블에 예측 ID 컬럼 추가
ALTER TABLE public.notifications ADD COLUMN IF NOT EXISTS prediction_id BIGINT;
ALTER TABLE public.notifications ADD COLUMN IF NOT EXISTS title TEXT; -- title 컬럼도 확인

-- 인덱스 추가 (성능 최적화)
CREATE INDEX IF NOT EXISTS idx_notifications_prediction_id ON public.notifications(prediction_id);

-- 권한 재설정 (혹시 모르니 다시 한번)
GRANT ALL ON public.notifications TO service_role, authenticated;
