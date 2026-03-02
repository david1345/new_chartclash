-- Remove duplicate notification trigger
-- The robust v4 function now handles notifications explicitly.
-- We must remove this trigger to prevent double notifications.

DROP TRIGGER IF EXISTS on_prediction_resolved ON public.predictions;
DROP FUNCTION IF EXISTS public.handle_prediction_resolution_notify();
