-- Reset Predictions and Notifications for clean testing
TRUNCATE TABLE public.notifications CASCADE;
TRUNCATE TABLE public.predictions CASCADE;

-- Optional: Reset points to 1000 for all users so they can bet again
UPDATE profiles SET points = 1000;
