-- ==============================================================================
-- 🔍 VIBE FORECAST: SYSTEM HEALTH CHECK & VERIFICATION
-- Run this script to ensure all critical DB components are active and correct.
-- ==============================================================================

DO $$
DECLARE
    v_missing_tables TEXT[] := '{}';
    v_missing_functions TEXT[] := '{}';
    v_missing_columns TEXT[] := '{}';
    v_report TEXT := '';
BEGIN
    -- 1. Check Tables
    IF NOT EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'profiles') THEN v_missing_tables := v_missing_tables || 'profiles'; END IF;
    IF NOT EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'predictions') THEN v_missing_tables := v_missing_tables || 'predictions'; END IF;
    IF NOT EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'notifications') THEN v_missing_tables := v_missing_tables || 'notifications'; END IF;
    IF NOT EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'feedbacks') THEN v_missing_tables := v_missing_tables || 'feedbacks'; END IF;

    -- 2. Check Essential RPCs
    IF NOT EXISTS (SELECT 1 FROM pg_proc JOIN pg_namespace n ON n.oid = pg_proc.pronamespace WHERE n.nspname = 'public' AND proname = 'submit_prediction') THEN v_missing_functions := v_missing_functions || 'submit_prediction'; END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_proc JOIN pg_namespace n ON n.oid = pg_proc.pronamespace WHERE n.nspname = 'public' AND proname = 'resolve_prediction_advanced') THEN v_missing_functions := v_missing_functions || 'resolve_prediction_advanced'; END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_proc JOIN pg_namespace n ON n.oid = pg_proc.pronamespace WHERE n.nspname = 'public' AND proname = 'get_user_rank') THEN v_missing_functions := v_missing_functions || 'get_user_rank'; END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_proc JOIN pg_namespace n ON n.oid = pg_proc.pronamespace WHERE n.nspname = 'public' AND proname = 'handle_new_user') THEN v_missing_functions := v_missing_functions || 'handle_new_user'; END IF;

    -- 3. Check Critical Columns
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'profiles' AND column_name = 'streak') THEN v_missing_columns := v_missing_columns || 'profiles.streak'; END IF;
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'predictions' AND column_name = 'candle_close_at') THEN v_missing_columns := v_missing_columns || 'predictions.candle_close_at'; END IF;

    -- 4. Generate Report
    IF array_length(v_missing_tables, 1) IS NULL AND array_length(v_missing_functions, 1) IS NULL AND array_length(v_missing_columns, 1) IS NULL THEN
        RAISE NOTICE '✅ SYSTEM HEALTH CHECK PASSED: All critical components found.';
    ELSE
        IF array_length(v_missing_tables, 1) > 0 THEN v_report := v_report || '❌ MISSING TABLES: ' || array_to_string(v_missing_tables, ', ') || E'\n'; END IF;
        IF array_length(v_missing_functions, 1) > 0 THEN v_report := v_report || '❌ MISSING RPCs: ' || array_to_string(v_missing_functions, ', ') || E'\n'; END IF;
        IF array_length(v_missing_columns, 1) > 0 THEN v_report := v_report || '❌ MISSING COLUMNS: ' || array_to_string(v_missing_columns, ', ') || E'\n'; END IF;
        
        RAISE EXCEPTION '🚨 SYSTEM HEALTH CHECK FAILED:%', v_report;
    END IF;
END $$;
