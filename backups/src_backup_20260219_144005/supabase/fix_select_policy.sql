-- Allow anyone to read predictions (so the feed works)
create policy "Enable read access for all users"
on public.predictions for select
using (true);

-- Verify
select * from pg_policies where tablename = 'predictions';
