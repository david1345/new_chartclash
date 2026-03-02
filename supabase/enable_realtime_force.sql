-- Force Enable Realtime for Predictions
-- This ensures the table broadcasts changes to the frontend.

BEGIN;

-- 1. Check if publication exists (it should by default in Supabase)
-- If not, creating it would be complex, but usually 'supabase_realtime' exists.
-- We just add the table to it.

ALTER PUBLICATION supabase_realtime ADD TABLE predictions;
ALTER PUBLICATION supabase_realtime ADD TABLE profiles; -- Just in case user updates name/avatar

-- 2. Verify
SELECT * FROM pg_publication_tables WHERE pubname = 'supabase_realtime';

COMMIT;
