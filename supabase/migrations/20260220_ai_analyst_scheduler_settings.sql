-- AI Analyst Scheduler Settings
-- Allows admin to control automatic AI analysis generation

CREATE TABLE IF NOT EXISTS scheduler_settings (
    id SERIAL PRIMARY KEY,
    service_name TEXT NOT NULL UNIQUE,
    enabled BOOLEAN DEFAULT false,
    timeframes TEXT[] DEFAULT ARRAY['15m', '30m', '1h', '4h', '1d'],
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Insert default settings for AI Analyst scheduler
INSERT INTO scheduler_settings (service_name, enabled, timeframes)
VALUES ('ai_analyst', false, ARRAY['15m', '30m', '1h', '4h', '1d'])
ON CONFLICT (service_name) DO NOTHING;

-- Function to get scheduler settings
CREATE OR REPLACE FUNCTION get_scheduler_settings(p_service_name TEXT)
RETURNS TABLE (
    enabled BOOLEAN,
    timeframes TEXT[]
) AS $$
BEGIN
    RETURN QUERY
    SELECT s.enabled, s.timeframes
    FROM scheduler_settings s
    WHERE s.service_name = p_service_name;
END;
$$ LANGUAGE plpgsql STABLE;

-- Function to update scheduler settings
CREATE OR REPLACE FUNCTION update_scheduler_settings(
    p_service_name TEXT,
    p_enabled BOOLEAN DEFAULT NULL,
    p_timeframes TEXT[] DEFAULT NULL
)
RETURNS BOOLEAN AS $$
BEGIN
    UPDATE scheduler_settings
    SET
        enabled = COALESCE(p_enabled, enabled),
        timeframes = COALESCE(p_timeframes, timeframes),
        updated_at = NOW()
    WHERE service_name = p_service_name;

    RETURN FOUND;
END;
$$ LANGUAGE plpgsql;

-- Add RLS policies
ALTER TABLE scheduler_settings ENABLE ROW LEVEL SECURITY;

-- Only authenticated users can read
CREATE POLICY "Anyone can read scheduler settings"
    ON scheduler_settings FOR SELECT
    TO authenticated
    USING (true);

-- Only service role can update (admin via API)
CREATE POLICY "Service role can update scheduler settings"
    ON scheduler_settings FOR UPDATE
    TO service_role
    USING (true);
