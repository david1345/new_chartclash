-- Create a secure RPC to fetch top leaders, bypassing RLS
CREATE OR REPLACE FUNCTION get_top_leaders(limit_count int DEFAULT 5)
RETURNS TABLE (
    id uuid,
    username text,
    avatar_url text,
    points int,
    total_wins int
)
LANGUAGE sql
SECURITY DEFINER -- Use security definer to access profiles bypassing RLS
SET search_path = public
AS $$
  SELECT 
    id, 
    username, 
    NULL as avatar_url, -- Column does not exist in profiles, returning NULL
    COALESCE(points, 0) as points, 
    COALESCE(total_wins, 0) as total_wins
  FROM profiles
  WHERE points < 1000000 -- Exclude AI users who have 1M+ points
  AND username NOT LIKE 'Analyst_%' -- Safety check for AI naming convention
  ORDER BY points DESC
  LIMIT limit_count;
$$;
