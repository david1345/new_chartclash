-- 🔍 DATABASE SYNC AUDIT SCRIPT
-- Run this in both Production and Development SQL Editors to compare the state.

SELECT '--- [ SCHEMA INTEGRITY ] ---' as category;

-- 1. Check Public Tables (Should match)
SELECT 
    table_name, 
    (SELECT count(*) FROM public.profiles) as profiles_count,
    (SELECT count(*) FROM public.predictions) as predictions_count,
    (SELECT count(*) FROM public.notifications) as notifications_count
FROM information_schema.tables 
WHERE table_schema = 'public' 
AND table_name IN ('profiles', 'predictions', 'notifications');

-- 2. Check Auth Tables (Should match if users were migrated)
SELECT 
    'auth_sync' as check,
    (SELECT count(*) FROM auth.users) as users_count,
    (SELECT count(*) FROM auth.identities) as identities_count;

-- 3. Check Critical Logic (Functions)
SELECT 
    routine_name,
    CASE WHEN routine_name IS NOT NULL THEN '✅ EXISTS' ELSE '❌ MISSING' END as status
FROM information_schema.routines 
WHERE routine_schema = 'public' 
AND routine_name IN ('resolve_prediction_advanced', 'submit_prediction', 'handle_new_user');

-- 4. Identity Check (The specific issue we had)
SELECT 
    'identity_integrity' as check,
    count(*) filter (where i.id is null) as users_without_identity
FROM auth.users u
LEFT JOIN auth.identities i ON u.id = i.user_id;
