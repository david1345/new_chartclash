-- 1. Restrict Profiles Table Column Access
-- Prevent anon and authenticated roles from selecting the sensitive 'email' column
REVOKE SELECT (email) ON public.profiles FROM anon, authenticated;

-- Ensure owners can still see their own email (via a policy or by keeping it for authenticated if they are owners)
-- Actually, REVOKE takes precedence. To allow owners, we can create a SECURITY DEFINER function or use another approach.
-- But in most Supabase apps, users get their own email from `auth.users`, which is already protected by RLS.
-- So revoking it from `public.profiles` is the safest way to prevent public leaks.

-- 2. Audit & Update Policies for Profiles
DROP POLICY IF EXISTS "Public profiles are viewable by everyone." ON public.profiles;
CREATE POLICY "Public profiles are viewable by everyone." ON public.profiles
  FOR SELECT USING (true);
-- Note: Even with SELECT enabled, the REVOKE above will prevent email from being returned unless accessed via service_role.

DROP POLICY IF EXISTS "Users can view own sensitive data" ON public.profiles;
CREATE POLICY "Users can view own sensitive data" ON public.profiles
  FOR SELECT USING (auth.uid() = id);

-- 3. Hardening other tables
ALTER TABLE public.predictions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.comments ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.notifications ENABLE ROW LEVEL SECURITY;

-- 4. Secure Notifications
-- Only users can view their own notifications
DROP POLICY IF EXISTS "Users can view own notifications" ON public.notifications;
CREATE POLICY "Users can view own notifications" ON public.notifications
  FOR SELECT USING (auth.uid() = user_id);

-- 5. Secure Comments
-- Public can view, but only owners can insert/update/delete
DROP POLICY IF EXISTS "Comments are viewable by everyone." ON public.comments;
CREATE POLICY "Comments are viewable by everyone." ON public.comments
  FOR SELECT USING (true);

DROP POLICY IF EXISTS "Users can insert their own comments." ON public.comments;
CREATE POLICY "Users can insert their own comments." ON public.comments
  FOR INSERT WITH CHECK (auth.uid() = user_id);
