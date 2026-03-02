-- ==============================================================================
-- 🤖 AI SIMULATION SYSTEM MIGRATION (Phase 1)
-- ==============================================================================

-- 1. Extend Profiles Table
ALTER TABLE public.profiles 
ADD COLUMN IF NOT EXISTS is_bot BOOLEAN DEFAULT FALSE,
ADD COLUMN IF NOT EXISTS bot_persona JSONB DEFAULT '{}'::jsonb;

-- 2. Optimize Bot Query Performance
CREATE INDEX IF NOT EXISTS idx_profiles_is_bot ON public.profiles(is_bot) WHERE is_bot = TRUE;

-- 3. Notification Support for Bots (Optional but good for audit)
ALTER TABLE public.notifications 
ADD COLUMN IF NOT EXISTS is_system_gen BOOLEAN DEFAULT FALSE;

-- 4. RPC to help batch-create or reset bots
CREATE OR REPLACE FUNCTION public.bulk_setup_bots(p_bot_data jsonb)
RETURNS void LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
    b jsonb;
BEGIN
    FOR b IN SELECT * FROM jsonb_array_elements(p_bot_data) LOOP
        -- Upsert into profiles (assuming auth.users were created)
        UPDATE public.profiles 
        SET 
            is_bot = TRUE,
            bot_persona = b->'persona',
            username = b->>'username',
            tier = b->>'tier'
        WHERE id = (b->>'id')::uuid;
    END LOOP;
END;
$$;

COMMENT ON COLUMN public.profiles.is_bot IS 'Flag to identify AI agents';
COMMENT ON COLUMN public.profiles.bot_persona IS 'Stores strategy, bias, and preferences for the bot';
