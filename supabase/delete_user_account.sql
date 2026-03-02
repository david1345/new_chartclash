-- Function to allow a user to delete their own account
-- Requires 'security definer' to bypass RLS on auth.users (which is usually restricted)
create or replace function public.delete_user_account()
returns void as $$
declare
  target_user_id uuid;
begin
  target_user_id := auth.uid();
  
  if target_user_id is null then
    raise exception 'Not authorized';
  end if;

  -- 1. Delete profiles (cascades might handle this, but let's be explicit if needed)
  -- The schema.sql shows profiles has 'on delete cascade', so it's handled.
  
  -- 2. Delete the user from auth.users (Requires superuser/service_role logic or security definer)
  -- Note: In some Supabase setups, you might need to use a specific extension or 
  -- ensure the schema has permissions to modify auth.users.
  delete from auth.users where id = target_user_id;

end;
$$ language plpgsql security definer;
