-- 🚀 Fix Realtime Identity for Predictions
-- This ensures that UPDATE events (like adding comments) contain all columns
-- so that client-side filters (e.g., asset_symbol) work correctly.

-- 1. Set replica identity to FULL
ALTER TABLE public.predictions REPLICA IDENTITY FULL;

-- 2. Ensure table is in publication (just in case)
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_publication_tables 
        WHERE pubname = 'supabase_realtime' 
        AND schemaname = 'public' 
        AND tablename = 'predictions'
    ) THEN
        ALTER PUBLICATION supabase_realtime ADD TABLE predictions;
    END IF;
END $$;
