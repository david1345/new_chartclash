-- Update the function to handle new user signup with username from metadata
create or replace function public.handle_new_user()
returns trigger as $$
begin
  insert into public.profiles (id, email, username, points)
  values (
    new.id, 
    new.email, 
    coalesce(new.raw_user_meta_data->>'username', split_part(new.email, '@', 1)), 
    1000
  )
  on conflict (id) do update
  set email = excluded.email,
      username = coalesce(excluded.username, profiles.username);
  return new;
end;
$$ language plpgsql security definer;
