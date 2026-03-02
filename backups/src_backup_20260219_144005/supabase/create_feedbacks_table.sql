-- ==============================================================================
-- 🛠️ FEEDBACKS TABLE (Bug Reporting & Suggestions)
-- ==============================================================================

-- 1. Create feedbacks table
CREATE TABLE IF NOT EXISTS public.feedbacks (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID REFERENCES auth.users(id) ON DELETE SET NULL,
    email TEXT NOT NULL,
    category TEXT NOT NULL CHECK (category IN ('bug', 'suggestion', 'other')),
    message TEXT NOT NULL CHECK (length(message) <= 2000),
    created_at TIMESTAMPTZ DEFAULT now()
);

-- 2. Enable RLS
ALTER TABLE public.feedbacks ENABLE ROW LEVEL SECURITY;

-- 3. Policies

-- Policy: Anyone (anon/auth) can insert feedback
DROP POLICY IF EXISTS "Anyone can submit feedback" ON public.feedbacks;
CREATE POLICY "Anyone can submit feedback"
ON public.feedbacks FOR INSERT
TO anon, authenticated
WITH CHECK (true);

-- Policy: Only authenticated users (admins) can read feedback
-- In this app, admins are identified by being authenticated users who access the dashboard
DROP POLICY IF EXISTS "Authenticated users can read feedback" ON public.feedbacks;
CREATE POLICY "Authenticated users can read feedback"
ON public.feedbacks FOR SELECT
TO authenticated
USING (true);

-- 4. Grants
GRANT INSERT, SELECT ON public.feedbacks TO anon, authenticated;
GRANT USAGE ON SCHEMA public TO anon, authenticated;
