-- Add remaining missing columns for Robust Resolution (v4)

BEGIN;

-- Required for 'actual_change_percent'
ALTER TABLE predictions ADD COLUMN IF NOT EXISTS actual_change_percent NUMERIC;

-- Required for 'is_target_hit'
ALTER TABLE predictions ADD COLUMN IF NOT EXISTS is_target_hit BOOLEAN DEFAULT FALSE;

-- Required for 'multipliers' (metadata)
ALTER TABLE predictions ADD COLUMN IF NOT EXISTS multipliers JSONB DEFAULT '{}'::jsonb;

-- Verify
SELECT column_name, data_type 
FROM information_schema.columns 
WHERE table_name = 'predictions';

COMMIT;
