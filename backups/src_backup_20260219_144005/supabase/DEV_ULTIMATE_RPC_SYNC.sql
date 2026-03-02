-- ==============================================================================
-- 🤖 CHARTCLASH - DEV RPC SYNC (2026-02-16)
-- Run this in the Development Supabase SQL Editor to enable the AI Analyst Hub.
-- ==============================================================================

-- [1] Updated submit_prediction (Supports Channels & Opinions)
CREATE OR REPLACE FUNCTION public.submit_prediction(
  p_user_id UUID,
  p_asset_symbol TEXT,
  p_timeframe TEXT,
  p_direction TEXT,
  p_target_percent NUMERIC,
  p_entry_price NUMERIC,
  p_bet_amount INTEGER,
  p_is_opinion BOOLEAN DEFAULT FALSE,
  p_channel TEXT DEFAULT 'main'
) RETURNS JSONB 
LANGUAGE plpgsql 
SECURITY DEFINER 
AS $$
DECLARE
  v_user_points INTEGER;
  v_prediction_id BIGINT;
  v_interval INTERVAL;
  v_candle_close TIMESTAMP WITH TIME ZONE;
BEGIN
  IF p_timeframe = '1m' THEN v_interval := INTERVAL '1 minute';
  ELSIF p_timeframe = '5m' THEN v_interval := INTERVAL '5 minutes';
  ELSIF p_timeframe = '15m' THEN v_interval := INTERVAL '15 minutes';
  ELSIF p_timeframe = '30m' THEN v_interval := INTERVAL '30 minutes';
  ELSIF p_timeframe = '1h' THEN v_interval := INTERVAL '1 hour';
  ELSIF p_timeframe = '4h' THEN v_interval := INTERVAL '4 hours';
  ELSIF p_timeframe = '1d' THEN v_interval := INTERVAL '1 day';
  ELSE v_interval := INTERVAL '15 minutes';
  END IF;

  v_candle_close := date_bin(v_interval, now(), '2000-01-01'::timestamp with time zone) + v_interval;

  IF NOT p_is_opinion THEN
      SELECT points INTO v_user_points FROM profiles WHERE id = p_user_id FOR UPDATE;
      IF v_user_points IS NULL THEN RAISE EXCEPTION 'User profile not found'; END IF;
      IF v_user_points < p_bet_amount THEN RAISE EXCEPTION 'Insufficient points'; END IF;
      UPDATE profiles SET points = points - p_bet_amount WHERE id = p_user_id;
  END IF;

  INSERT INTO predictions (
    user_id, asset_symbol, timeframe, direction, target_percent, 
    entry_price, status, bet_amount, candle_close_at, created_at,
    is_opinion, channel
  ) VALUES (
    p_user_id, p_asset_symbol, p_timeframe, p_direction, p_target_percent, 
    p_entry_price, 'pending', p_bet_amount, v_candle_close, now(),
    p_is_opinion, p_channel
  ) RETURNING id INTO v_prediction_id;

  RETURN jsonb_build_object('success', true, 'prediction_id', v_prediction_id);
END;
$$;

-- [2] Updated get_ranked_insights (Supports p_channel Filter)
CREATE OR REPLACE FUNCTION public.get_ranked_insights(
  p_asset_symbol TEXT DEFAULT NULL,
  p_timeframe TEXT DEFAULT NULL,
  p_sort_by TEXT DEFAULT 'TOP',
  p_limit INTEGER DEFAULT 20,
  p_offset INTEGER DEFAULT 0,
  p_is_opinion BOOLEAN DEFAULT TRUE,
  p_channel TEXT DEFAULT 'main'
)
RETURNS TABLE (
  id BIGINT, user_id UUID, username TEXT, tier TEXT, user_win_rate NUMERIC,
  user_total_games INTEGER, asset_symbol TEXT, timeframe TEXT, direction TEXT,
  target_percent NUMERIC, entry_price NUMERIC, status TEXT, profit INTEGER,
  created_at TIMESTAMP WITH TIME ZONE, resolved_at TIMESTAMP WITH TIME ZONE,
  comment TEXT, likes_count INTEGER, insight_score NUMERIC, is_opinion BOOLEAN
) AS $$
BEGIN
  RETURN QUERY
  SELECT
    p.id, p.user_id, prof.username, prof.tier,
    CASE WHEN prof.total_games > 0 THEN ROUND((prof.total_wins::numeric / prof.total_games::numeric) * 100, 1) ELSE 0 END,
    prof.total_games, p.asset_symbol, p.timeframe, p.direction, p.target_percent, p.entry_price, p.status, p.profit,
    p.created_at, p.resolved_at, p.comment, COALESCE(p.likes_count, 0),
    (
      (CASE WHEN p.status = 'WIN' THEN 40 ELSE 0 END) + (p.target_percent * 15) + (COALESCE(p.likes_count, 0) * 2) + 20 -- Bonus for bots/opinions
    )::numeric,
    p.is_opinion
  FROM predictions p
  JOIN profiles prof ON p.user_id = prof.id
  WHERE (p_asset_symbol IS NULL OR p.asset_symbol = p_asset_symbol) 
    AND (p_timeframe IS NULL OR p.timeframe = p_timeframe) 
    AND (p.comment IS NOT NULL AND length(p.comment) > 0) 
    AND (p.is_opinion = p_is_opinion)
    AND (p.channel = p_channel)
  ORDER BY
    CASE WHEN p_sort_by = 'TOP' THEN 18 END DESC,
    p.created_at DESC
  LIMIT p_limit OFFSET p_offset;
END;
$$ LANGUAGE plpgsql STABLE;
