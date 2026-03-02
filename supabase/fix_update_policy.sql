-- RESTORE UPDATE PERMISSIONS
-- Users need to be able to UPDATE their own predictions (to add comments)

BEGIN;

-- Drop checking for old policies to avoid error, just create the correct one
DROP POLICY IF EXISTS "Users can update their own predictions" ON predictions;

CREATE POLICY "Users can update their own predictions"
ON predictions FOR UPDATE
USING (auth.uid() = user_id)
WITH CHECK (auth.uid() = user_id);

COMMIT;
