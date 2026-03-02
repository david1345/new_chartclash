-- Enable RLS on predictions table if not already enabled (it should be)
alter table public.predictions enable row level security;

-- Drop existing policy if it conflicts (or create a new specific one)
drop policy if exists "Users can update their own predictions" on public.predictions;

-- Create policy to allow users to update their own predictions (e.g. for adding comments)
create policy "Users can update their own predictions"
on public.predictions for update
using (auth.uid() = user_id)
with check (auth.uid() = user_id);

-- Verify policies
select * from pg_policies where tablename = 'predictions';
