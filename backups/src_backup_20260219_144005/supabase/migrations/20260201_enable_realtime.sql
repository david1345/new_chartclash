-- Enable Realtime for notifications table
-- This is required for the frontend to receive INSERT events
ALTER PUBLICATION supabase_realtime ADD TABLE public.notifications;
