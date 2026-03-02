-- Enable Realtime for profiles table
ALTER PUBLICATION supabase_realtime ADD TABLE public.profiles;

-- Ensure RLS is enabled and there is a policy for everyone to read
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Anyone can view profiles" ON public.profiles;
CREATE POLICY "Anyone can view profiles" ON public.profiles FOR SELECT USING (true);
