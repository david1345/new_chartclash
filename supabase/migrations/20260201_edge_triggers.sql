-- 1. Enable pg_net extension for HTTP requests
create extension if not exists pg_net with schema extensions;

-- 2. Generic Function to Call Edge Function via pg_net
create or replace function notify_post_engagement()
returns trigger as $$
declare
  -- Replace with your actual project URL and Service Role Key securely
  edge_function_url text := 'https://[YOUR_PROJECT_REF].functions.supabase.co/recompute-score';
  service_role_key text := current_setting('app.settings.service_role_key', true); -- Or hardcode for testing if needed
begin
  -- Perform Async HTTP POST
  perform net.http_post(
    url := edge_function_url,
    headers := jsonb_build_object(
      'Content-Type', 'application/json',
      'Authorization', 'Bearer ' || service_role_key
    ),
    body := jsonb_build_object('postId', new.post_id)
  );
  return new;
end;
$$ language plpgsql;

-- 3. Triggers for Engagement Events
-- Like
create trigger on_like_created
after insert on likes
for each row execute procedure notify_post_engagement();

-- Comment
create trigger on_comment_created
after insert on comments
for each row execute procedure notify_post_engagement();

-- Bookmark
create trigger on_bookmark_created
after insert on bookmarks
for each row execute procedure notify_post_engagement();

-- Share (Assuming shares table exists)
create trigger on_share_created
after insert on shares
for each row execute procedure notify_post_engagement();
