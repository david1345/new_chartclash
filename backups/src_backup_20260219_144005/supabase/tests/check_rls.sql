-- RLS Diagnostic Script
-- Check if we can read predictions and profiles

BEGIN;

-- 1. Check Policies on Predictions
SELECT * FROM pg_policies WHERE tablename = 'predictions';

-- 2. Check Policies on Profiles
SELECT * FROM pg_policies WHERE tablename = 'profiles';

-- 3. Simulate READ as standard user
SET ROLE authenticated;
-- (In a real psql session we'd set request.jwt.claim.sub, but here we just check if SELECT works at all with policies enabled)

-- Just check if RLS is enabled
SELECT relname, relrowsecurity FROM pg_class WHERE relname IN ('predictions', 'profiles');

-- 4. Check actual visibility (Switch back to postgres/service_role to see all, then check count)
RESET ROLE;

SELECT count(*) as total_predictions FROM predictions;
SELECT count(*) as total_profiles FROM profiles;
SELECT count(*) as predictions_with_comments FROM predictions WHERE comment IS NOT NULL;

ROLLBACK;
