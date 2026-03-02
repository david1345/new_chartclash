-- [FIX] Remove 2-param duplicate of resolve_prediction_advanced
-- This resolves: "Could not choose the best candidate function" ambiguity error
-- The correct 3-param version (p_id, p_close_price, p_open_price DEFAULT NULL) is kept intact.

DROP FUNCTION IF EXISTS public.resolve_prediction_advanced(bigint, numeric);
