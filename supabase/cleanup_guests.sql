-- ==============================================================================
-- 🧹 GUEST ACCOUNT CLEANUP
-- ==============================================================================
-- 7일 이상 로그인하지 않은 익명 계정을 삭제합니다.
-- ==============================================================================

DO $$
DECLARE
    v_count INTEGER;
BEGIN
    -- 7일 이상 활동이 없는 익명 사용자(is_anonymous = true) 삭제
    -- auth.users 테이블의 last_sign_in_at 기준
    
    WITH to_delete AS (
        SELECT id 
        FROM auth.users 
        WHERE is_anonymous = true 
          AND (last_sign_in_at < NOW() - INTERVAL '7 days' OR last_sign_in_at IS NULL AND created_at < NOW() - INTERVAL '7 days')
    )
    DELETE FROM auth.users 
    WHERE id IN (SELECT id FROM to_delete);

    GET DIAGNOSTICS v_count = ROW_COUNT;
    RAISE NOTICE 'Deleted % abandoned guest accounts.', v_count;
END $$;
