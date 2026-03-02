-- 1. Create a private_profiles table for sensitive data
create table if not exists public.private_profiles (
  id uuid not null references auth.users on delete cascade,
  email text,
  primary key (id)
);

-- 2. Migrate existing data
insert into public.private_profiles (id, email)
select id, email from public.profiles
on conflict (id) do nothing;

-- 3. Remove email from public.profiles
alter table public.profiles drop column if exists email;

-- 4. Enable RLS on private_profiles
alter table public.private_profiles enable row level security;

-- 5. Set RLS Policies for private_profiles
drop policy if exists "Admin or Owner can view private profile" on public.private_profiles;
create policy "Admin or Owner can view private profile" on public.private_profiles
  for select using (
    auth.uid() = id OR 
    auth.jwt() ->> 'email' = 'sjustone000@gmail.com'
  );

-- 6. Update handle_new_user trigger function
create or replace function public.handle_new_user()
returns trigger as $$
begin
  -- Public profile (no email)
  insert into public.profiles (id, username, points)
  values (
    new.id, 
    coalesce(new.raw_user_meta_data->>'username', split_part(new.email, '@', 1)), 
    1000
  )
  on conflict (id) do update
  set username = coalesce(excluded.username, profiles.username);

  -- Private profile (sensitive data)
  insert into public.private_profiles (id, email)
  values (new.id, new.email)
  on conflict (id) do update
  set email = excluded.email;

  return new;
end;
$$ language plpgsql security definer;
