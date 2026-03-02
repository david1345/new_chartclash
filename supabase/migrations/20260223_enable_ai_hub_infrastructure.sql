-- ==========================================================
-- 🚀 PRODUCTION RECOVERY: AI HUB & LEADERBOARD INFRASTRUCTURE
-- Addresses Points 4, 5, 6
-- ==========================================================

-- 1. [POINT 6] AI HUB LOCK SYSTEM (Prevents duplicate cron runs)
CREATE TABLE IF NOT EXISTS public.scheduler_locks (
    id BIGSERIAL PRIMARY KEY,
    lock_key TEXT UNIQUE NOT NULL,
    locked_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    locked_by TEXT NOT NULL,
    expires_at TIMESTAMP WITH TIME ZONE NOT NULL,
    metadata JSONB DEFAULT '{}'::jsonb,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS public.api_call_tracker (
    id BIGSERIAL PRIMARY KEY,
    date DATE NOT NULL DEFAULT CURRENT_DATE,
    service TEXT NOT NULL, 
    call_count INTEGER NOT NULL DEFAULT 0,
    last_updated TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    metadata JSONB DEFAULT '{}'::jsonb,
    UNIQUE(date, service)
);

-- 2. [POINT 6] SCHEDULER SETTINGS (Enable/Disable AI Analyst)
CREATE TABLE IF NOT EXISTS public.scheduler_settings (
    id SERIAL PRIMARY KEY,
    service_name TEXT NOT NULL UNIQUE,
    enabled BOOLEAN DEFAULT false,
    timeframes TEXT[] DEFAULT ARRAY['15m', '30m', '1h', '4h', '1d'],
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 3. [POINT 6] INITIALIZE SETTINGS
INSERT INTO public.scheduler_settings (service_name, enabled, timeframes)
VALUES ('ai_analyst', true, ARRAY['15m', '30m', '1h', '4h', '1d'])
ON CONFLICT (service_name) DO UPDATE SET enabled = true;

-- 4. [POINT 6] LOCK & API RPCs
CREATE OR REPLACE FUNCTION acquire_scheduler_lock(p_lock_key TEXT, p_locked_by TEXT, p_ttl_seconds INTEGER DEFAULT 300)
RETURNS JSONB AS $$
DECLARE v_expires_at TIMESTAMP WITH TIME ZONE; v_existing_lock RECORD;
BEGIN
    v_expires_at := NOW() + (p_ttl_seconds || ' seconds')::INTERVAL;
    DELETE FROM public.scheduler_locks WHERE expires_at < NOW();
    SELECT * INTO v_existing_lock FROM public.scheduler_locks WHERE lock_key = p_lock_key FOR UPDATE SKIP LOCKED;
    IF FOUND AND v_existing_lock.expires_at > NOW() THEN
        RETURN jsonb_build_object('success', false, 'error', 'Lock already held', 'locked_by', v_existing_lock.locked_by);
    END IF;
    INSERT INTO public.scheduler_locks (lock_key, locked_by, expires_at) VALUES (p_lock_key, p_locked_by, v_expires_at)
    ON CONFLICT (lock_key) DO UPDATE SET locked_by = p_locked_by, locked_at = NOW(), expires_at = v_expires_at RETURNING * INTO v_existing_lock;
    RETURN jsonb_build_object('success', true, 'lock_id', v_existing_lock.id);
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION release_scheduler_lock(p_lock_key TEXT, p_locked_by TEXT)
RETURNS JSONB AS $$
DECLARE v_deleted INTEGER;
BEGIN
    DELETE FROM public.scheduler_locks WHERE lock_key = p_lock_key AND locked_by = p_locked_by;
    GET DIAGNOSTICS v_deleted = ROW_COUNT;
    RETURN jsonb_build_object('success', v_deleted > 0);
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION track_api_call(p_service TEXT DEFAULT 'openai', p_increment INTEGER DEFAULT 1)
RETURNS JSONB AS $$
DECLARE v_new_count INTEGER;
BEGIN
    INSERT INTO public.api_call_tracker (date, service, call_count) VALUES (CURRENT_DATE, p_service, p_increment)
    ON CONFLICT (date, service) DO UPDATE SET call_count = api_call_tracker.call_count + p_increment, last_updated = NOW()
    RETURNING call_count INTO v_new_count;
    RETURN jsonb_build_object('success', true, 'count', v_new_count);
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION can_make_api_call(p_service TEXT DEFAULT 'openai', p_max_daily INTEGER DEFAULT 3000)
RETURNS BOOLEAN AS $$
DECLARE v_count INTEGER;
BEGIN
    SELECT call_count INTO v_count FROM public.api_call_tracker WHERE date = CURRENT_DATE AND service = p_service;
    IF NOT FOUND THEN RETURN true; END IF;
    RETURN v_count < p_max_daily;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION get_api_usage(p_service TEXT DEFAULT 'openai', p_date DATE DEFAULT CURRENT_DATE)
RETURNS JSONB AS $$
DECLARE v_count INTEGER;
BEGIN
    SELECT call_count INTO v_count FROM public.api_call_tracker WHERE date = p_date AND service = p_service;
    RETURN jsonb_build_object('count', COALESCE(v_count, 0));
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION get_scheduler_settings(p_service_name TEXT)
RETURNS TABLE (enabled BOOLEAN, timeframes TEXT[]) AS $$
BEGIN
    RETURN QUERY SELECT s.enabled, s.timeframes FROM public.scheduler_settings s WHERE s.service_name = p_service_name;
END;
$$ LANGUAGE plpgsql STABLE;

-- 5. [POINT 6] AI HUB FETCH RPC
CREATE OR REPLACE FUNCTION public.get_analyst_rounds(p_asset_symbol TEXT, p_timeframe TEXT, p_channel TEXT DEFAULT 'analyst_hub')
RETURNS TABLE (round_time TIMESTAMP WITH TIME ZONE, post_count BIGINT) AS $$
BEGIN
  RETURN QUERY
  SELECT date_trunc('minute', created_at) as round_time, COUNT(*) as post_count
  FROM public.predictions
  WHERE asset_symbol = p_asset_symbol AND timeframe = p_timeframe AND channel = p_channel AND is_opinion = TRUE
  GROUP BY round_time ORDER BY round_time DESC LIMIT 50;
END;
$$ LANGUAGE plpgsql STABLE SECURITY DEFINER;

-- 6. [POINT 5] IMPROVED RANKED INSIGHTS (Supports LATEST sort)
CREATE OR REPLACE FUNCTION public.get_ranked_insights_v2(
  p_asset_symbol TEXT DEFAULT NULL,
  p_timeframe TEXT DEFAULT NULL,
  p_round_time TIMESTAMP WITH TIME ZONE DEFAULT NULL,
  p_sort_by TEXT DEFAULT 'TOP',
  p_limit INTEGER DEFAULT 20,
  p_is_opinion BOOLEAN DEFAULT TRUE,
  p_channel TEXT DEFAULT 'main'
)
RETURNS TABLE (
  id BIGINT, user_id UUID, username TEXT, tier TEXT, user_win_rate NUMERIC,
  user_total_games INTEGER, asset_symbol TEXT, timeframe TEXT, direction TEXT,
  target_percent NUMERIC, entry_price NUMERIC, status TEXT, profit INTEGER,
  created_at TIMESTAMP WITH TIME ZONE, resolved_at TIMESTAMP WITH TIME ZONE,
  comment TEXT, likes_count INTEGER, insight_score NUMERIC, is_opinion BOOLEAN
) AS $$
BEGIN
  RETURN QUERY
  SELECT sub.* FROM (
    SELECT
      p.id, p.user_id, prof.username, prof.tier,
      CASE WHEN prof.total_games > 0 THEN ROUND((prof.total_wins::numeric / prof.total_games::numeric) * 100, 1) ELSE 0 END as win_rate,
      prof.total_games, p.asset_symbol, p.timeframe, p.direction, p.target_percent, p.entry_price, p.status, p.profit,
      p.created_at, p.resolved_at, p.comment, COALESCE(p.likes_count, 0) as likes,
      ( (CASE WHEN p.status = 'WIN' THEN 40 ELSE 0 END) + (p.target_percent * 15) + (COALESCE(p.likes_count, 0) * 2) + 20 )::numeric as score,
      p.is_opinion
    FROM public.predictions p
    JOIN public.profiles prof ON p.user_id = prof.id
    WHERE (p_asset_symbol IS NULL OR p.asset_symbol = p_asset_symbol) 
      AND (p_timeframe IS NULL OR p.timeframe = p_timeframe) 
      AND (p_round_time IS NULL OR date_trunc('minute', p.created_at) = date_trunc('minute', p_round_time))
      AND (p.comment IS NOT NULL AND length(p.comment) > 0) 
      AND (p.is_opinion = p_is_opinion)
      AND (p.channel = p_channel)
  ) sub
  ORDER BY
    CASE WHEN p_sort_by = 'TOP' THEN sub.score END DESC,
    CASE WHEN p_sort_by = 'LATEST' THEN sub.created_at END DESC,
    sub.created_at DESC
  LIMIT p_limit;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER STABLE;

-- 7. [POINT 4] LEADERBOARD RECOVERY
CREATE OR REPLACE FUNCTION get_top_leaders(limit_count int DEFAULT 5)
RETURNS TABLE (id uuid, username text, avatar_url text, points int, total_wins int)
LANGUAGE sql SECURITY DEFINER SET search_path = public AS $$
  SELECT id, username, NULL as avatar_url, COALESCE(points, 0) as points, COALESCE(total_wins, 0) as total_wins
  FROM profiles
  WHERE points < 1000000 AND username NOT LIKE 'Analyst_%'
  ORDER BY points DESC LIMIT limit_count;
$$;

-- Grant permissions for all functions
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA public TO anon, authenticated, service_role;
