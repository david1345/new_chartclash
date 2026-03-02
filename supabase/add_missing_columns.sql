-- Add missing columns for resolution
-- These columns are required for the resolve_prediction_v4 function

BEGIN;

ALTER TABLE predictions ADD COLUMN IF NOT EXISTS close_price NUMERIC;
ALTER TABLE predictions ADD COLUMN IF NOT EXISTS profit_loss NUMERIC;
ALTER TABLE predictions ADD COLUMN IF NOT EXISTS payout NUMERIC;
ALTER TABLE predictions ADD COLUMN IF NOT EXISTS resolved_at TIMESTAMPTZ;

-- Verify
SELECT column_name, data_type 
FROM information_schema.columns 
WHERE table_name = 'predictions';

COMMIT;
