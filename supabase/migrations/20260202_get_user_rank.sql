-- Create RPC to get user rank efficiently
CREATE OR REPLACE FUNCTION public.get_user_rank(p_user_id UUID)
RETURNS BIGINT
LANGUAGE sql
STABLE
AS $$
    SELECT rank
    FROM (
        SELECT 
            id, 
            RANK() OVER (ORDER BY points DESC) as rank
        FROM profiles
    ) as ranked_users
    WHERE id = p_user_id;
$$;
