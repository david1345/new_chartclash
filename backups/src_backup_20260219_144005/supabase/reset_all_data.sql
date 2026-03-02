-- ==============================================================================
-- 🧹 ROBUST DATABASE RESET SCRIPT
-- ==============================================================================
-- Safely truncates tables only if they exist.

DO $$
BEGIN
    -- 1. Truncate Core Tables (Assuming these ALWAYS exist)
    -- predictions, notifications are core to the app logic now.
    TRUNCATE TABLE public.notifications CASCADE;
    TRUNCATE TABLE public.predictions CASCADE;

    -- 2. Conditionally Truncate Community Tables (If deployed)
    IF EXISTS (SELECT FROM pg_tables WHERE schemaname = 'public' AND tablename = 'likes') THEN
        TRUNCATE TABLE public.likes CASCADE;
    END IF;

    IF EXISTS (SELECT FROM pg_tables WHERE schemaname = 'public' AND tablename = 'comments') THEN
        TRUNCATE TABLE public.comments CASCADE;
    END IF;

    IF EXISTS (SELECT FROM pg_tables WHERE schemaname = 'public' AND tablename = 'bookmarks') THEN
        TRUNCATE TABLE public.bookmarks CASCADE;
    END IF;
    
    IF EXISTS (SELECT FROM pg_tables WHERE schemaname = 'public' AND tablename = 'shares') THEN
        TRUNCATE TABLE public.shares CASCADE;
    END IF;

    IF EXISTS (SELECT FROM pg_tables WHERE schemaname = 'public' AND tablename = 'posts') THEN
        TRUNCATE TABLE public.posts CASCADE;
    END IF;

    -- 3. Reset User Points
    UPDATE profiles SET points = 1000;
    
END $$;
