-- Fix Account Deletion Foreign Key Constraints
-- This script adds ON DELETE CASCADE to tables referencing profiles or auth.users without it.

DO $$
BEGIN
    -- 1. Fix PREDICTIONS table
    ALTER TABLE public.predictions 
      DROP CONSTRAINT IF EXISTS predictions_user_id_fkey;

    ALTER TABLE public.predictions
      ADD CONSTRAINT predictions_user_id_fkey 
      FOREIGN KEY (user_id) 
      REFERENCES public.profiles(id) 
      ON DELETE CASCADE;

    -- 2. Fix NOTIFICATIONS table
    ALTER TABLE public.notifications 
      DROP CONSTRAINT IF EXISTS notifications_user_id_fkey;

    ALTER TABLE public.notifications
      ADD CONSTRAINT notifications_user_id_fkey 
      FOREIGN KEY (user_id) 
      REFERENCES public.profiles(id) 
      ON DELETE CASCADE;

    RAISE NOTICE 'Foreign key constraints for predictions and notifications updated with ON DELETE CASCADE.';
END $$;
