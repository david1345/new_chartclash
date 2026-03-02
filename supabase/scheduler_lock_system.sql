-- Scheduler Lock & API Tracking System for Production
-- 상용망 스케줄러 중복 실행 방지 및 API 호출 추적

-- 1. Scheduler Locks Table
CREATE TABLE IF NOT EXISTS public.scheduler_locks (
    id BIGSERIAL PRIMARY KEY,
    lock_key TEXT UNIQUE NOT NULL,
    locked_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    locked_by TEXT NOT NULL, -- Instance ID or hostname
    expires_at TIMESTAMP WITH TIME ZONE NOT NULL,
    metadata JSONB DEFAULT '{}'::jsonb,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Index for fast lookup
CREATE INDEX IF NOT EXISTS idx_scheduler_locks_key ON public.scheduler_locks(lock_key);
CREATE INDEX IF NOT EXISTS idx_scheduler_locks_expires ON public.scheduler_locks(expires_at);

-- 2. API Call Tracker Table
CREATE TABLE IF NOT EXISTS public.api_call_tracker (
    id BIGSERIAL PRIMARY KEY,
    date DATE NOT NULL DEFAULT CURRENT_DATE,
    service TEXT NOT NULL, -- 'openai', 'anthropic', etc.
    call_count INTEGER NOT NULL DEFAULT 0,
    last_updated TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    metadata JSONB DEFAULT '{}'::jsonb,
    UNIQUE(date, service)
);

CREATE INDEX IF NOT EXISTS idx_api_tracker_date ON public.api_call_tracker(date, service);

-- 3. Function: Acquire Lock (중복 실행 방지)
CREATE OR REPLACE FUNCTION acquire_scheduler_lock(
    p_lock_key TEXT,
    p_locked_by TEXT,
    p_ttl_seconds INTEGER DEFAULT 300 -- 5분 기본 TTL
)
RETURNS JSONB AS $$
DECLARE
    v_expires_at TIMESTAMP WITH TIME ZONE;
    v_existing_lock RECORD;
BEGIN
    v_expires_at := NOW() + (p_ttl_seconds || ' seconds')::INTERVAL;

    -- Clean up expired locks first
    DELETE FROM public.scheduler_locks
    WHERE expires_at < NOW();

    -- Try to get existing lock
    SELECT * INTO v_existing_lock
    FROM public.scheduler_locks
    WHERE lock_key = p_lock_key
    FOR UPDATE SKIP LOCKED;

    -- Lock exists and not expired
    IF FOUND AND v_existing_lock.expires_at > NOW() THEN
        RETURN jsonb_build_object(
            'success', false,
            'error', 'Lock already held',
            'locked_by', v_existing_lock.locked_by,
            'expires_at', v_existing_lock.expires_at
        );
    END IF;

    -- Acquire or renew lock
    INSERT INTO public.scheduler_locks (lock_key, locked_by, expires_at)
    VALUES (p_lock_key, p_locked_by, v_expires_at)
    ON CONFLICT (lock_key) DO UPDATE
    SET locked_by = p_locked_by,
        locked_at = NOW(),
        expires_at = v_expires_at
    RETURNING * INTO v_existing_lock;

    RETURN jsonb_build_object(
        'success', true,
        'lock_id', v_existing_lock.id,
        'expires_at', v_existing_lock.expires_at
    );
END;
$$ LANGUAGE plpgsql;

-- 4. Function: Release Lock
CREATE OR REPLACE FUNCTION release_scheduler_lock(
    p_lock_key TEXT,
    p_locked_by TEXT
)
RETURNS JSONB AS $$
DECLARE
    v_deleted INTEGER;
BEGIN
    DELETE FROM public.scheduler_locks
    WHERE lock_key = p_lock_key
      AND locked_by = p_locked_by
      AND expires_at > NOW();

    GET DIAGNOSTICS v_deleted = ROW_COUNT;

    IF v_deleted > 0 THEN
        RETURN jsonb_build_object('success', true, 'message', 'Lock released');
    ELSE
        RETURN jsonb_build_object('success', false, 'error', 'Lock not found or already expired');
    END IF;
END;
$$ LANGUAGE plpgsql;

-- 5. Function: Track API Call
CREATE OR REPLACE FUNCTION track_api_call(
    p_service TEXT DEFAULT 'openai',
    p_increment INTEGER DEFAULT 1
)
RETURNS JSONB AS $$
DECLARE
    v_today DATE := CURRENT_DATE;
    v_new_count INTEGER;
BEGIN
    -- Upsert counter
    INSERT INTO public.api_call_tracker (date, service, call_count, last_updated)
    VALUES (v_today, p_service, p_increment, NOW())
    ON CONFLICT (date, service) DO UPDATE
    SET call_count = api_call_tracker.call_count + p_increment,
        last_updated = NOW()
    RETURNING call_count INTO v_new_count;

    RETURN jsonb_build_object(
        'success', true,
        'date', v_today,
        'service', p_service,
        'count', v_new_count
    );
END;
$$ LANGUAGE plpgsql;

-- 6. Function: Get API Usage
CREATE OR REPLACE FUNCTION get_api_usage(
    p_service TEXT DEFAULT 'openai',
    p_date DATE DEFAULT CURRENT_DATE
)
RETURNS JSONB AS $$
DECLARE
    v_count INTEGER;
BEGIN
    SELECT call_count INTO v_count
    FROM public.api_call_tracker
    WHERE date = p_date
      AND service = p_service;

    IF NOT FOUND THEN
        v_count := 0;
    END IF;

    RETURN jsonb_build_object(
        'date', p_date,
        'service', p_service,
        'count', v_count
    );
END;
$$ LANGUAGE plpgsql;

-- 7. Function: Check if under daily limit
CREATE OR REPLACE FUNCTION can_make_api_call(
    p_service TEXT DEFAULT 'openai',
    p_max_daily INTEGER DEFAULT 3000
)
RETURNS BOOLEAN AS $$
DECLARE
    v_count INTEGER;
BEGIN
    SELECT call_count INTO v_count
    FROM public.api_call_tracker
    WHERE date = CURRENT_DATE
      AND service = p_service;

    IF NOT FOUND THEN
        RETURN true;
    END IF;

    RETURN v_count < p_max_daily;
END;
$$ LANGUAGE plpgsql;

-- 8. Auto-cleanup job (Vercel Cron에서 호출)
CREATE OR REPLACE FUNCTION cleanup_old_locks_and_trackers()
RETURNS JSONB AS $$
DECLARE
    v_locks_deleted INTEGER;
    v_trackers_deleted INTEGER;
BEGIN
    -- Remove expired locks
    DELETE FROM public.scheduler_locks
    WHERE expires_at < NOW();
    GET DIAGNOSTICS v_locks_deleted = ROW_COUNT;

    -- Remove old API trackers (30일 이상)
    DELETE FROM public.api_call_tracker
    WHERE date < CURRENT_DATE - INTERVAL '30 days';
    GET DIAGNOSTICS v_trackers_deleted = ROW_COUNT;

    RETURN jsonb_build_object(
        'locks_deleted', v_locks_deleted,
        'trackers_deleted', v_trackers_deleted
    );
END;
$$ LANGUAGE plpgsql;

-- Grant permissions
ALTER TABLE public.scheduler_locks ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.api_call_tracker ENABLE ROW LEVEL SECURITY;

-- Allow service role to manage locks (for Cron jobs)
CREATE POLICY "Service role can manage locks"
ON public.scheduler_locks FOR ALL
USING (true)
WITH CHECK (true);

CREATE POLICY "Service role can manage trackers"
ON public.api_call_tracker FOR ALL
USING (true)
WITH CHECK (true);

-- Initial cleanup
SELECT cleanup_old_locks_and_trackers();
