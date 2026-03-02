-- 1. Atomic Toggle Function
CREATE OR REPLACE FUNCTION public.toggle_prediction_like(p_prediction_id BIGINT)
RETURNS JSON
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_user_id UUID := auth.uid();
    v_exists BOOLEAN;
    v_new_count INTEGER;
BEGIN
    IF v_user_id IS NULL THEN
        RETURN json_build_object('success', false, 'error', 'Unauthorized');
    END IF;

    -- Check if already liked
    SELECT EXISTS (
        SELECT 1 FROM public.prediction_likes 
        WHERE user_id = v_user_id AND prediction_id = p_prediction_id
    ) INTO v_exists;

    IF v_exists THEN
        -- Unlike
        DELETE FROM public.prediction_likes 
        WHERE user_id = v_user_id AND prediction_id = p_prediction_id;
    ELSE
        -- Like
        INSERT INTO public.prediction_likes (user_id, prediction_id)
        VALUES (v_user_id, p_prediction_id);
    END IF;

    -- Get updated count
    SELECT likes_count INTO v_new_count FROM public.predictions WHERE id = p_prediction_id;

    RETURN json_build_object(
        'success', true, 
        'action', CASE WHEN v_exists THEN 'unliked' ELSE 'liked' END,
        'likes_count', v_new_count
    );
END;
$$;

-- 2. Updated Ranking Algorithm with Viewer Context
-- We drop the old one and redefine it to include p_viewer_id
DROP FUNCTION IF EXISTS public.get_ranked_insights(text, text, text, integer, integer);

CREATE OR REPLACE FUNCTION public.get_ranked_insights(
  p_asset_symbol TEXT DEFAULT NULL,
  p_timeframe TEXT DEFAULT NULL,
  p_sort_by TEXT DEFAULT 'TOP', -- 'TOP', 'NEW', 'RISING'
  p_limit INTEGER DEFAULT 20,
  p_offset INTEGER DEFAULT 0,
  p_viewer_id UUID DEFAULT NULL
)
RETURNS TABLE (
  id BIGINT,
  user_id UUID,
  username TEXT,
  tier TEXT,
  user_win_rate NUMERIC,
  user_total_games INTEGER,
  asset_symbol TEXT,
  timeframe TEXT,
  direction TEXT,
  target_percent NUMERIC,
  entry_price NUMERIC,
  status TEXT,
  profit INTEGER,
  created_at TIMESTAMP WITH TIME ZONE,
  resolved_at TIMESTAMP WITH TIME ZONE,
  comment TEXT,
  likes_count INTEGER,
  insight_score NUMERIC,
  is_liked BOOLEAN
) AS $$
BEGIN
  RETURN QUERY
  SELECT
    p.id,
    p.user_id,
    prof.username,
    prof.tier,
    CASE WHEN prof.total_games > 0 THEN 
      ROUND((prof.total_wins::numeric / prof.total_games::numeric) * 100, 1)
    ELSE 0 END as user_win_rate,
    prof.total_games as user_total_games,
    p.asset_symbol,
    p.timeframe,
    p.direction,
    p.target_percent,
    p.entry_price,
    p.status,
    p.profit,
    p.created_at,
    p.resolved_at,
    p.comment,
    p.likes_count,
    (
      (CASE WHEN p.status = 'WIN' THEN 40 ELSE 0 END) +
      (p.target_percent * 15) +
      (p.likes_count * 2) +
      (
        CASE WHEN prof.total_games > 0 THEN 
          (prof.total_wins::numeric / prof.total_games::numeric) * 100 * 0.2 
        ELSE 0 END
      ) -
      (EXTRACT(EPOCH FROM (NOW() - p.created_at)) / 3600 * 1.5)
    )::numeric as insight_score,
    -- Check if current viewer has liked this
    EXISTS (
        SELECT 1 FROM public.prediction_likes pl 
        WHERE pl.prediction_id = p.id AND pl.user_id = p_viewer_id
    ) as is_liked

  FROM predictions p
  JOIN profiles prof ON p.user_id = prof.id
  WHERE 
    (p_asset_symbol IS NULL OR p.asset_symbol = p_asset_symbol) AND
    (p_timeframe IS NULL OR p.timeframe = p_timeframe) AND
    (p.comment IS NOT NULL AND length(p.comment) > 0)
    
  ORDER BY
    CASE WHEN p_sort_by = 'TOP' THEN 18 END DESC,
    CASE WHEN p_sort_by = 'NEW' THEN p.created_at END DESC,
    CASE WHEN p_sort_by = 'RISING' THEN (p.likes_count * 10 - (EXTRACT(EPOCH FROM (NOW() - p.created_at)) / 3600 * 5)) END DESC,
    p.created_at DESC
  LIMIT p_limit OFFSET p_offset;
END;
$$ LANGUAGE plpgsql STABLE;
