
-- 1. Remove comment filter from get_ranked_insights RPC
-- 2. Add bonus score for predictions with comments (quality content)

CREATE OR REPLACE FUNCTION public.get_ranked_insights(
  p_asset_symbol TEXT DEFAULT NULL,
  p_timeframe TEXT DEFAULT NULL,
  p_sort_by TEXT DEFAULT 'TOP', -- 'TOP', 'NEW', 'RISING'
  p_limit INTEGER DEFAULT 20,
  p_offset INTEGER DEFAULT 0
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
  insight_score NUMERIC
) AS $$
BEGIN
  RETURN QUERY
  SELECT
    p.id,
    p.user_id,
    prof.username,
    prof.tier,
    -- Calculate Win Rate safely
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

    -- 🧠 IMPROVED INSIGHT SCORE ALGORITHM
    (
      (CASE WHEN p.status = 'WIN' THEN 40 ELSE 0 END) +
      (p.target_percent * 15) +
      (p.likes_count * 5) + -- Weighted higher
      (CASE WHEN p.comment IS NOT NULL AND length(p.comment) > 0 THEN 25 ELSE 0 END) + -- Bonus for reasoning
      (
        CASE WHEN prof.total_games > 0 THEN 
          (prof.total_wins::numeric / prof.total_games::numeric) * 100 * 0.2
        ELSE 0 END
      ) -
      (EXTRACT(EPOCH FROM (NOW() - p.created_at)) / 3600 * 1.5)
    )::numeric as insight_score

  FROM predictions p
  JOIN profiles prof ON p.user_id = prof.id
  WHERE 
    (p_asset_symbol IS NULL OR p.asset_symbol = p_asset_symbol) AND
    (p_timeframe IS NULL OR p.timeframe = p_timeframe)
    -- REMOVED: (p.comment IS NOT NULL AND length(p.comment) > 0)
    
  ORDER BY
    CASE WHEN p_sort_by = 'TOP' THEN 18 END DESC, 
    CASE WHEN p_sort_by = 'NEW' THEN p.created_at END DESC,
    CASE WHEN p_sort_by = 'RISING' THEN (p.likes_count * 10 - (EXTRACT(EPOCH FROM (NOW() - p.created_at)) / 3600 * 5)) END DESC,
    p.created_at DESC
  LIMIT p_limit OFFSET p_offset;
END;
$$ LANGUAGE plpgsql STABLE;

-- 3. Update submit_prediction RPC to accept p_comment
CREATE OR REPLACE FUNCTION public.submit_prediction(
    p_user_id UUID,
    p_asset_symbol TEXT,
    p_timeframe TEXT,
    p_direction TEXT,
    p_target_percent NUMERIC,
    p_entry_price NUMERIC,
    p_bet_amount INTEGER,
    p_comment TEXT DEFAULT NULL
)
RETURNS JSON LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
    v_current_points INTEGER;
    v_candle_duration BIGINT;
    v_prediction_id BIGINT;
BEGIN
    SELECT points INTO v_current_points FROM profiles WHERE id = p_user_id FOR UPDATE;
    IF v_current_points < p_bet_amount THEN
        RETURN json_build_object('success', false, 'error', 'Insufficient points');
    END IF;

    CASE
        WHEN p_timeframe = '1m' THEN v_candle_duration := 60;
        WHEN p_timeframe = '3m' THEN v_candle_duration := 180;
        WHEN p_timeframe = '5m' THEN v_candle_duration := 300;
        WHEN p_timeframe = '15m' THEN v_candle_duration := 900;
        WHEN p_timeframe = '1h' THEN v_candle_duration := 3600;
        WHEN p_timeframe = '4h' THEN v_candle_duration := 14400;
        WHEN p_timeframe = '1d' THEN v_candle_duration := 86400;
        ELSE v_candle_duration := 900;
    END CASE;

    UPDATE profiles SET points = v_current_points - p_bet_amount WHERE id = p_user_id;

    INSERT INTO predictions (user_id, asset_symbol, timeframe, direction, target_percent, entry_price, bet_amount, candle_close_at, comment)
    VALUES (p_user_id, p_asset_symbol, p_timeframe, p_direction, p_target_percent, p_entry_price, p_bet_amount, 
            to_timestamp(floor(extract(epoch from now()) / v_candle_duration) * v_candle_duration + v_candle_duration),
            p_comment)
    RETURNING id INTO v_prediction_id;

    RETURN json_build_object('success', true, 'prediction_id', v_prediction_id);
END;
$$;
