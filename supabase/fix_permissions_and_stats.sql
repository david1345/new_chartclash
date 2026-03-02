-- FORCE FIX RLS: Allow Public Read for Feed & Stats
-- This ensures everyone can see everyone's predictions and profiles.

BEGIN;

-- 1. Predictions Table
ALTER TABLE predictions ENABLE ROW LEVEL SECURITY;

-- Drop generic overlapping policies if they exist (names vary, so we try common ones)
DROP POLICY IF EXISTS "Enable read for all" ON predictions;
DROP POLICY IF EXISTS "Public can view all predictions" ON predictions;
DROP POLICY IF EXISTS "Users can view their own predictions" ON predictions;
DROP POLICY IF EXISTS "Anyone can select predictions" ON predictions;
-- Explicitly drop the policy we are about to create to ensure idempotency
DROP POLICY IF EXISTS "Anyone can view predictions" ON predictions;

-- CREATE MASTER READ POLICY
CREATE POLICY "Anyone can view predictions"
ON predictions FOR SELECT
USING (true); -- Public Read

-- Ensure Insert/Update is still protected
-- (We assume existing INSERT policies are fine: "Users can create their own")

-- 2. Profiles Table
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Public profiles are viewable by everyone" ON profiles;
DROP POLICY IF EXISTS "Users can view own profile" ON profiles;
-- Explicitly drop the policy we are about to create to ensure idempotency
DROP POLICY IF EXISTS "Anyone can view profiles" ON profiles;

-- CREATE MASTER READ POLICY
CREATE POLICY "Anyone can view profiles"
ON profiles FOR SELECT
USING (true);

-- 3. Verify
SELECT count(*) as "Predictions Count" FROM predictions;

COMMIT;
