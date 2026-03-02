-- 1. Wipe everything in public
DROP SCHEMA public CASCADE;
CREATE SCHEMA public;

-- 2. Wipe everything in auth (Rows only, do NOT drop schema)
TRUNCATE auth.users CASCADE;
TRUNCATE auth.refresh_tokens CASCADE;
TRUNCATE auth.identities CASCADE;

-- 3. Restore standard Supabase permissions for public
GRANT ALL ON SCHEMA public TO postgres;
GRANT ALL ON SCHEMA public TO anon;
GRANT ALL ON SCHEMA public TO authenticated;
GRANT ALL ON SCHEMA public TO service_role;

-- 4. Re-apply Production Schema (Tables, RLS, Functions)
-- (This is based on the production baseline logic we aligned to)
