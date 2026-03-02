-- Increase comment length limit for AI analyst predictions
-- Previous limit: 140 characters (like a tweet)
-- New limit: 2000 characters (allows for detailed 5-7 sentence analysis)

-- Drop old constraint
ALTER TABLE public.predictions
DROP CONSTRAINT IF EXISTS predictions_comment_check;

-- Add new constraint with increased limit
ALTER TABLE public.predictions
ADD CONSTRAINT predictions_comment_check CHECK (char_length(comment) <= 2000);

-- Verify the change
SELECT constraint_name, check_clause
FROM information_schema.check_constraints
WHERE constraint_name = 'predictions_comment_check';
