-- Fix missing column in notifications table
ALTER TABLE public.notifications 
ADD COLUMN IF NOT EXISTS prediction_id BIGINT REFERENCES public.predictions(id);

-- Also ensure other potentially missing columns for safety
ALTER TABLE public.notifications 
ADD COLUMN IF NOT EXISTS type TEXT,
ADD COLUMN IF NOT EXISTS message TEXT,
ADD COLUMN IF NOT EXISTS read BOOLEAN DEFAULT false;

-- Re-enable Realtime (Commented out as it causes error if already added)
-- ALTER PUBLICATION supabase_realtime ADD TABLE public.notifications;
