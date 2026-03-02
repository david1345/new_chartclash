-- ============================================================
-- PRODUCTION MIGRATION: AI Analyst Scheduler Settings
-- Date: 2026-02-20
-- Safe deployment with rollback support
-- ============================================================

-- STEP 1: Backup existing data (if table exists)
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.tables
               WHERE table_schema = 'public'
               AND table_name = 'scheduler_settings') THEN

        CREATE TABLE IF NOT EXISTS scheduler_settings_backup_20260220 AS
        SELECT * FROM scheduler_settings;

        RAISE NOTICE 'Backup created: scheduler_settings_backup_20260220';
    END IF;
END $$;

-- STEP 2: Create table with safe defaults
CREATE TABLE IF NOT EXISTS scheduler_settings (
    id SERIAL PRIMARY KEY,
    service_name TEXT NOT NULL UNIQUE,
    enabled BOOLEAN DEFAULT false, -- IMPORTANT: Default OFF for safety
    timeframes TEXT[] DEFAULT ARRAY['15m', '30m', '1h', '4h', '1d'],
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- STEP 3: Insert default settings (OFF by default)
INSERT INTO scheduler_settings (service_name, enabled, timeframes)
VALUES ('ai_analyst', false, ARRAY['15m', '30m', '1h', '4h', '1d'])
ON CONFLICT (service_name)
DO UPDATE SET
    timeframes = EXCLUDED.timeframes,
    updated_at = NOW();

-- STEP 4: Create read function
CREATE OR REPLACE FUNCTION get_scheduler_settings(p_service_name TEXT)
RETURNS TABLE (
    enabled BOOLEAN,
    timeframes TEXT[]
)
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
AS $$
BEGIN
    RETURN QUERY
    SELECT s.enabled, s.timeframes
    FROM scheduler_settings s
    WHERE s.service_name = p_service_name;
END;
$$;

-- STEP 5: Create update function
CREATE OR REPLACE FUNCTION update_scheduler_settings(
    p_service_name TEXT,
    p_enabled BOOLEAN DEFAULT NULL,
    p_timeframes TEXT[] DEFAULT NULL
)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    UPDATE scheduler_settings
    SET
        enabled = COALESCE(p_enabled, enabled),
        timeframes = COALESCE(p_timeframes, timeframes),
        updated_at = NOW()
    WHERE service_name = p_service_name;

    RETURN FOUND;
END;
$$;

-- STEP 6: Grant permissions
GRANT USAGE ON SCHEMA public TO authenticated;
GRANT SELECT ON scheduler_settings TO authenticated;
GRANT EXECUTE ON FUNCTION get_scheduler_settings(TEXT) TO authenticated;
GRANT EXECUTE ON FUNCTION update_scheduler_settings(TEXT, BOOLEAN, TEXT[]) TO service_role;

-- STEP 7: Enable RLS
ALTER TABLE scheduler_settings ENABLE ROW LEVEL SECURITY;

-- STEP 8: Drop old policies if exist
DROP POLICY IF EXISTS "Anyone can read scheduler settings" ON scheduler_settings;
DROP POLICY IF EXISTS "Service role can update scheduler settings" ON scheduler_settings;

-- STEP 9: Create policies
CREATE POLICY "Anyone can read scheduler settings"
    ON scheduler_settings FOR SELECT
    TO authenticated
    USING (true);

CREATE POLICY "Service role can update scheduler settings"
    ON scheduler_settings FOR UPDATE
    TO service_role
    USING (true);

-- STEP 10: Verify migration
DO $$
DECLARE
    v_count INTEGER;
    v_enabled BOOLEAN;
BEGIN
    -- Check table exists
    SELECT COUNT(*) INTO v_count FROM scheduler_settings;
    RAISE NOTICE 'scheduler_settings rows: %', v_count;

    -- Check default settings
    SELECT enabled INTO v_enabled FROM scheduler_settings WHERE service_name = 'ai_analyst';
    RAISE NOTICE 'ai_analyst enabled: % (should be false)', v_enabled;

    -- Verify it's OFF
    IF v_enabled = true THEN
        RAISE WARNING 'WARNING: Scheduler is enabled! This should be OFF initially.';
    ELSE
        RAISE NOTICE 'SUCCESS: Scheduler is safely disabled.';
    END IF;
END $$;

-- STEP 11: Test functions
SELECT get_scheduler_settings('ai_analyst') AS "Current Settings";

-- ============================================================
-- ROLLBACK SCRIPT (if needed)
-- ============================================================
-- Uncomment below to rollback:
/*
DROP POLICY IF EXISTS "Anyone can read scheduler settings" ON scheduler_settings;
DROP POLICY IF EXISTS "Service role can update scheduler settings" ON scheduler_settings;
DROP FUNCTION IF EXISTS get_scheduler_settings(TEXT);
DROP FUNCTION IF EXISTS update_scheduler_settings(TEXT, BOOLEAN, TEXT[]);
DROP TABLE IF EXISTS scheduler_settings;

-- Restore from backup
CREATE TABLE scheduler_settings AS SELECT * FROM scheduler_settings_backup_20260220;
DROP TABLE scheduler_settings_backup_20260220;
*/

-- ============================================================
-- POST-MIGRATION CHECKLIST
-- ============================================================
-- [ ] Migration executed successfully
-- [ ] Verify scheduler is OFF: SELECT * FROM scheduler_settings;
-- [ ] Test get function: SELECT get_scheduler_settings('ai_analyst');
-- [ ] Test update function: SELECT update_scheduler_settings('ai_analyst', false);
-- [ ] Admin page loads without errors
-- [ ] Toggle button works
-- ============================================================
