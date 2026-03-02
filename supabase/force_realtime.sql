-- 🚨 REALTIME FORCE RESET 🚀
-- 1. DROP and RE-ADD to publication to clear all stale settings
ALTER PUBLICATION supabase_realtime DROP TABLE IF EXISTS public.predictions;
ALTER PUBLICATION supabase_realtime ADD TABLE public.predictions;

-- 2. FORCE FULL IDENTITY
-- This is critical for Update filters to work correctly
ALTER TABLE public.predictions REPLICA IDENTITY FULL;

-- 3. ENSURE PERMISSIONS
GRANT SELECT ON public.predictions TO anon, authenticated;
GRANT UPDATE (comment) ON public.predictions TO authenticated;

-- 4. VERIFY (Optional: check if it's there)
-- SELECT * FROM pg_publication_tables WHERE pubname = 'supabase_realtime';
