-- Add channel column to predictions table
-- This allows categorizing posts (e.g., 'analyst_hub' for AI specialized bots)
ALTER TABLE public.predictions 
ADD COLUMN IF NOT EXISTS channel TEXT DEFAULT 'main' NOT NULL;

-- Create index for faster hub filtering
CREATE INDEX IF NOT EXISTS idx_predictions_channel ON public.predictions(channel);

-- Update RLS if needed (usually true is enough for Select)
-- The existing policy already allows select using (true).
