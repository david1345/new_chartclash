-- 🚀 Live Pulse Feed & Comment Fix
-- This SQL enables Realtime updates and allows users to update their own predictions (for comments)

-- 1. Enable Realtime for predictions table
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

-- 2. Set replica identity to FULL
-- Ensures Realtime events contain the full record (needed for UI updates)
ALTER TABLE public.predictions REPLICA IDENTITY FULL;

-- 3. Add missing UPDATE policy
-- Allows users to add/edit comments on their own predictions
DROP POLICY IF EXISTS "Users can update their own predictions." ON public.predictions;
CREATE POLICY "Users can update their own predictions." ON public.predictions
  FOR UPDATE USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);
