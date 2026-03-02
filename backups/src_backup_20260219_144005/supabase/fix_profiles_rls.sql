-- Force enable public read on profiles for Leaderboard
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Public profiles are viewable by everyone." ON public.profiles;

CREATE POLICY "Public profiles are viewable by everyone." ON public.profiles
FOR SELECT
USING (true);

-- Verify
-- SELECT * FROM profiles;
