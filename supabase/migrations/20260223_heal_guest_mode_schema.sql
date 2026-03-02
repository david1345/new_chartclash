-- ==========================================================
-- 🛠️ SCHEMA HEAL: GUEST MODE & TEMPORARY PROFILES
-- Restores missing columns and RPCs for Overhaul 2.0
-- ==========================================================

-- 1. Add missing flags to profiles
DO $$ 
BEGIN 
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='profiles' AND column_name='is_temporary') THEN
        ALTER TABLE public.profiles ADD COLUMN is_temporary BOOLEAN DEFAULT false;
    END IF;
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='profiles' AND column_name='is_bot') THEN
        ALTER TABLE public.profiles ADD COLUMN is_bot BOOLEAN DEFAULT false;
    END IF;
END $$;

-- 2. Index for performance
CREATE INDEX IF NOT EXISTS idx_profiles_is_temporary ON public.profiles(is_temporary) WHERE is_temporary = true;
CREATE INDEX IF NOT EXISTS idx_profiles_is_bot ON public.profiles(is_bot) WHERE is_bot = true;

-- 3. Upsert Temporary Profile RPC
-- Used by Guest Mode to sync progress to a database-backed "Shadow Profile"
CREATE OR REPLACE FUNCTION public.upsert_temporary_profile(
    p_id UUID,
    p_username TEXT,
    p_points INTEGER DEFAULT 1000
)
RETURNS JSONB AS $$
DECLARE
    v_result RECORD;
BEGIN
    INSERT INTO public.profiles (id, username, points, is_temporary, total_games, total_wins)
    VALUES (p_id, p_username, p_points, true, 0, 0)
    ON CONFLICT (id) DO UPDATE SET
        points = EXCLUDED.points,
        username = EXCLUDED.username
    RETURNING * INTO v_result;

    RETURN jsonb_build_object(
        'success', true,
        'profile', jsonb_build_object(
            'id', v_result.id,
            'username', v_result.username,
            'points', v_result.points
        )
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 4. Ensure RLS allows access to temporary profiles
-- Guests need to be able to see/update their own (even if not authenticated via Auth)
-- Since they use service_role or a special anon access for guest rounds
GRANT EXECUTE ON FUNCTION public.upsert_temporary_profile TO anon, authenticated, service_role;
