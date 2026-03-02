SELECT 
    'schema_existence' as check,
    count(*) as count
FROM information_schema.schemata 
WHERE schema_name IN ('auth', 'public');

SELECT 
    'search_path' as check,
    current_setting('search_path') as value;

SELECT 
    'auth_permissions' as check,
    grantee, privilege_type, table_name
FROM information_schema.role_table_grants 
WHERE table_schema = 'auth' AND table_name = 'users'
AND grantee IN ('anon', 'authenticated', 'service_role', 'postgres', 'supabase_admin');

SELECT 
    'broken_triggers' as check,
    event_object_table, trigger_name, action_statement
FROM information_schema.triggers 
WHERE trigger_schema = 'auth';
