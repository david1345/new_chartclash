-- leaderboard_fix.sql
-- 개발 환경 리더보드 복구를 위한 패치 스크립트

-- 1. Profiles 테이블 컬럼 추가 (누락된 통계 필드)
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS streak_count INTEGER DEFAULT 0 NOT NULL;
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS total_games INTEGER DEFAULT 0 NOT NULL;
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS total_wins INTEGER DEFAULT 0 NOT NULL;

-- 2. 순위 계산 RPC 함수 추가
CREATE OR REPLACE FUNCTION public.get_user_rank(p_user_id UUID)
RETURNS BIGINT
LANGUAGE sql
STABLE
AS $$
    SELECT rank
    FROM (
        SELECT 
            id, 
            RANK() OVER (ORDER BY points DESC) as rank
        FROM profiles
    ) as ranked_users
    WHERE id = p_user_id;
$$;

-- 3. 정산 로직 업데이트 (통계 누적 반영)
CREATE OR REPLACE FUNCTION public.resolve_prediction_advanced(
    p_id BIGINT,
    p_close_price NUMERIC,
    p_open_price NUMERIC DEFAULT NULL
)
RETURNS JSON
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_prediction RECORD;
    v_profile RECORD;
    v_price_change NUMERIC;
    v_price_change_percent NUMERIC;
    v_status TEXT;
    v_is_dir_correct BOOLEAN;
    v_is_target_hit BOOLEAN;
    v_direction_profit NUMERIC := 0;
    v_target_bonus INTEGER := 0;
    v_base_profit NUMERIC := 0;
    v_final_profit NUMERIC := 0;
    v_payout INTEGER := 0;
    v_tf_mult NUMERIC;
    v_streak_mult NUMERIC;
    c_house_edge NUMERIC := 0.95;
    v_new_streak INTEGER;
    v_open_price NUMERIC;
BEGIN
    SELECT * INTO v_prediction FROM predictions WHERE id = p_id AND status = 'pending' FOR UPDATE;
    IF NOT FOUND THEN RETURN json_build_object('success', false, 'error', 'Already resolved'); END IF;
    
    v_open_price := COALESCE(p_open_price, v_prediction.entry_price);
    SELECT * INTO v_profile FROM profiles WHERE id = v_prediction.user_id FOR UPDATE;

    v_price_change := p_close_price - v_open_price;
    v_price_change_percent := abs(v_price_change / v_open_price * 100);

    v_is_dir_correct := (v_prediction.direction = 'UP' AND v_price_change > 0) OR (v_prediction.direction = 'DOWN' AND v_price_change < 0);
    v_is_target_hit := (v_price_change_percent >= v_prediction.target_percent);

    IF v_is_dir_correct THEN
        v_status := 'WIN';
        CASE v_prediction.timeframe 
            WHEN '30m' THEN v_tf_mult := 1.2; WHEN '1h' THEN v_tf_mult := 1.5; WHEN '4h' THEN v_tf_mult := 2.2; WHEN '1d' THEN v_tf_mult := 3.0; ELSE v_tf_mult := 1.0;
        END CASE;
        v_direction_profit := v_prediction.bet_amount * 0.8 * v_tf_mult;
        IF v_is_target_hit THEN
            IF v_prediction.target_percent <= 0.5 THEN v_target_bonus := 20; ELSIF v_prediction.target_percent <= 1.0 THEN v_target_bonus := 40; ELSIF v_prediction.target_percent <= 1.5 THEN v_target_bonus := 70; ELSE v_target_bonus := 120; END IF;
            v_new_streak := v_profile.streak + 1;
        ELSE
            v_new_streak := 0;
        END IF;
        IF v_new_streak >= 5 THEN v_streak_mult := 2.5; ELSIF v_new_streak = 4 THEN v_streak_mult := 2.0; ELSIF v_new_streak = 3 THEN v_streak_mult := 1.6; ELSIF v_new_streak = 2 THEN v_streak_mult := 1.3; ELSE v_streak_mult := 1.0; END IF;
        v_final_profit := (v_direction_profit + v_target_bonus) * v_streak_mult * c_house_edge;
        v_payout := v_prediction.bet_amount + ROUND(v_final_profit);
    ELSIF v_price_change = 0 THEN
        v_status := 'ND'; v_payout := v_prediction.bet_amount; v_final_profit := 0; v_new_streak := v_profile.streak;
    ELSE
        v_status := 'LOSS'; v_payout := 0; v_final_profit := -v_prediction.bet_amount; v_new_streak := 0;
    END IF;

    UPDATE profiles 
    SET points = points + v_payout, 
        streak = v_new_streak,
        streak_count = CASE WHEN v_new_streak > streak_count THEN v_new_streak ELSE streak_count END,
        total_games = total_games + 1,
        total_wins = CASE WHEN v_status = 'WIN' THEN total_wins + 1 ELSE total_wins END
    WHERE id = v_prediction.user_id;

    UPDATE predictions SET status = v_status, actual_price = p_close_price, entry_price = v_open_price, profit = ROUND(v_final_profit), resolved_at = now() WHERE id = p_id;
    
    INSERT INTO notifications (user_id, type, message, prediction_id)
    VALUES (v_prediction.user_id, 'prediction_resolved', format('%s: %s (%s pts)', v_prediction.asset_symbol, v_status, ROUND(v_final_profit)), p_id);

    INSERT INTO activity_logs (user_id, action_type, asset_symbol, prediction_id, metadata)
    VALUES (v_prediction.user_id, 'RESOLVE', v_prediction.asset_symbol, p_id, json_build_object(
        'status', v_status, 'open_price', v_open_price, 'close_price', p_close_price, 'profit', ROUND(v_final_profit), 'payout', v_payout, 'streak', v_new_streak, 'is_target_hit', v_is_target_hit
    ));

    RETURN json_build_object('success', true, 'status', v_status, 'profit', ROUND(v_final_profit));
END;
$$;
