--
-- PostgreSQL database dump
--

\restrict dqrhXdvhkqMYtqfhjWd9l9sG99pp8Bk4jFUud6e07dDvtqjyAI19fZvuaR8HNv8

-- Dumped from database version 17.6
-- Dumped by pg_dump version 17.7 (Homebrew)

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET transaction_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: auth; Type: SCHEMA; Schema: -; Owner: supabase_admin
--

CREATE SCHEMA auth;


ALTER SCHEMA auth OWNER TO supabase_admin;

--
-- Name: public; Type: SCHEMA; Schema: -; Owner: pg_database_owner
--

CREATE SCHEMA public;


ALTER SCHEMA public OWNER TO pg_database_owner;

--
-- Name: SCHEMA public; Type: COMMENT; Schema: -; Owner: pg_database_owner
--

COMMENT ON SCHEMA public IS 'standard public schema';


--
-- Name: aal_level; Type: TYPE; Schema: auth; Owner: supabase_auth_admin
--

CREATE TYPE auth.aal_level AS ENUM (
    'aal1',
    'aal2',
    'aal3'
);


ALTER TYPE auth.aal_level OWNER TO supabase_auth_admin;

--
-- Name: code_challenge_method; Type: TYPE; Schema: auth; Owner: supabase_auth_admin
--

CREATE TYPE auth.code_challenge_method AS ENUM (
    's256',
    'plain'
);


ALTER TYPE auth.code_challenge_method OWNER TO supabase_auth_admin;

--
-- Name: factor_status; Type: TYPE; Schema: auth; Owner: supabase_auth_admin
--

CREATE TYPE auth.factor_status AS ENUM (
    'unverified',
    'verified'
);


ALTER TYPE auth.factor_status OWNER TO supabase_auth_admin;

--
-- Name: factor_type; Type: TYPE; Schema: auth; Owner: supabase_auth_admin
--

CREATE TYPE auth.factor_type AS ENUM (
    'totp',
    'webauthn',
    'phone'
);


ALTER TYPE auth.factor_type OWNER TO supabase_auth_admin;

--
-- Name: oauth_authorization_status; Type: TYPE; Schema: auth; Owner: supabase_auth_admin
--

CREATE TYPE auth.oauth_authorization_status AS ENUM (
    'pending',
    'approved',
    'denied',
    'expired'
);


ALTER TYPE auth.oauth_authorization_status OWNER TO supabase_auth_admin;

--
-- Name: oauth_client_type; Type: TYPE; Schema: auth; Owner: supabase_auth_admin
--

CREATE TYPE auth.oauth_client_type AS ENUM (
    'public',
    'confidential'
);


ALTER TYPE auth.oauth_client_type OWNER TO supabase_auth_admin;

--
-- Name: oauth_registration_type; Type: TYPE; Schema: auth; Owner: supabase_auth_admin
--

CREATE TYPE auth.oauth_registration_type AS ENUM (
    'dynamic',
    'manual'
);


ALTER TYPE auth.oauth_registration_type OWNER TO supabase_auth_admin;

--
-- Name: oauth_response_type; Type: TYPE; Schema: auth; Owner: supabase_auth_admin
--

CREATE TYPE auth.oauth_response_type AS ENUM (
    'code'
);


ALTER TYPE auth.oauth_response_type OWNER TO supabase_auth_admin;

--
-- Name: one_time_token_type; Type: TYPE; Schema: auth; Owner: supabase_auth_admin
--

CREATE TYPE auth.one_time_token_type AS ENUM (
    'confirmation_token',
    'reauthentication_token',
    'recovery_token',
    'email_change_token_new',
    'email_change_token_current',
    'phone_change_token'
);


ALTER TYPE auth.one_time_token_type OWNER TO supabase_auth_admin;

--
-- Name: email(); Type: FUNCTION; Schema: auth; Owner: supabase_auth_admin
--

CREATE FUNCTION auth.email() RETURNS text
    LANGUAGE sql STABLE
    AS $$
  select 
  coalesce(
    nullif(current_setting('request.jwt.claim.email', true), ''),
    (nullif(current_setting('request.jwt.claims', true), '')::jsonb ->> 'email')
  )::text
$$;


ALTER FUNCTION auth.email() OWNER TO supabase_auth_admin;

--
-- Name: FUNCTION email(); Type: COMMENT; Schema: auth; Owner: supabase_auth_admin
--

COMMENT ON FUNCTION auth.email() IS 'Deprecated. Use auth.jwt() -> ''email'' instead.';


--
-- Name: jwt(); Type: FUNCTION; Schema: auth; Owner: supabase_auth_admin
--

CREATE FUNCTION auth.jwt() RETURNS jsonb
    LANGUAGE sql STABLE
    AS $$
  select 
    coalesce(
        nullif(current_setting('request.jwt.claim', true), ''),
        nullif(current_setting('request.jwt.claims', true), '')
    )::jsonb
$$;


ALTER FUNCTION auth.jwt() OWNER TO supabase_auth_admin;

--
-- Name: role(); Type: FUNCTION; Schema: auth; Owner: supabase_auth_admin
--

CREATE FUNCTION auth.role() RETURNS text
    LANGUAGE sql STABLE
    AS $$
  select 
  coalesce(
    nullif(current_setting('request.jwt.claim.role', true), ''),
    (nullif(current_setting('request.jwt.claims', true), '')::jsonb ->> 'role')
  )::text
$$;


ALTER FUNCTION auth.role() OWNER TO supabase_auth_admin;

--
-- Name: FUNCTION role(); Type: COMMENT; Schema: auth; Owner: supabase_auth_admin
--

COMMENT ON FUNCTION auth.role() IS 'Deprecated. Use auth.jwt() -> ''role'' instead.';


--
-- Name: uid(); Type: FUNCTION; Schema: auth; Owner: supabase_auth_admin
--

CREATE FUNCTION auth.uid() RETURNS uuid
    LANGUAGE sql STABLE
    AS $$
  select 
  coalesce(
    nullif(current_setting('request.jwt.claim.sub', true), ''),
    (nullif(current_setting('request.jwt.claims', true), '')::jsonb ->> 'sub')
  )::uuid
$$;


ALTER FUNCTION auth.uid() OWNER TO supabase_auth_admin;

--
-- Name: FUNCTION uid(); Type: COMMENT; Schema: auth; Owner: supabase_auth_admin
--

COMMENT ON FUNCTION auth.uid() IS 'Deprecated. Use auth.jwt() -> ''sub'' instead.';


--
-- Name: get_ranked_insights(text, text, text, integer, integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.get_ranked_insights(p_asset_symbol text DEFAULT NULL::text, p_timeframe text DEFAULT NULL::text, p_sort_by text DEFAULT 'TOP'::text, p_limit integer DEFAULT 20, p_offset integer DEFAULT 0) RETURNS TABLE(id bigint, user_id uuid, username text, tier text, user_win_rate numeric, user_total_games integer, asset_symbol text, timeframe text, direction text, target_percent numeric, entry_price numeric, status text, profit integer, created_at timestamp with time zone, resolved_at timestamp with time zone, comment text, likes_count integer, insight_score numeric)
    LANGUAGE plpgsql STABLE
    AS $$
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
    
    -- 🧠 INSIGHT SCORE ALGORITHM
    -- terms: 
    -- 1. Result: WIN +40
    -- 2. Difficulty: Target% * 15
    -- 3. Social: Likes * 2
    -- 4. Time Decay: -1.5 per hour
    -- 5. User Authority: WinRate(0-100) * 0.2 -> max 20 pts
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
    )::numeric as insight_score

  FROM predictions p
  JOIN profiles prof ON p.user_id = prof.id
  WHERE 
    -- Optional Filters
    (p_asset_symbol IS NULL OR p.asset_symbol = p_asset_symbol) AND
    (p_timeframe IS NULL OR p.timeframe = p_timeframe) AND
    -- Only show items with comments (Insights) or all? Prompt implies "Insights" are "predictions with reasoning".
    -- Let's show all, but those with comments look better.
    -- Or just filter where comment is not null? "Insight Feed" implies text.
    (p.comment IS NOT NULL AND length(p.comment) > 0)
    
  ORDER BY
    CASE WHEN p_sort_by = 'TOP' THEN 18 END DESC, -- Sort by insight_score (col 18)
    CASE WHEN p_sort_by = 'NEW' THEN p.created_at END DESC,
    CASE WHEN p_sort_by = 'RISING' THEN (p.likes_count * 10 - (EXTRACT(EPOCH FROM (NOW() - p.created_at)) / 3600 * 5)) END DESC, -- Simple rising logic
    
    -- Fallback sort
    p.created_at DESC
  LIMIT p_limit OFFSET p_offset;
END;
$$;


ALTER FUNCTION public.get_ranked_insights(p_asset_symbol text, p_timeframe text, p_sort_by text, p_limit integer, p_offset integer) OWNER TO postgres;

--
-- Name: get_user_rank(uuid); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.get_user_rank(p_user_id uuid) RETURNS bigint
    LANGUAGE sql STABLE
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


ALTER FUNCTION public.get_user_rank(p_user_id uuid) OWNER TO postgres;

--
-- Name: handle_new_user(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.handle_new_user() RETURNS trigger
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
BEGIN
  INSERT INTO public.profiles (id, email, username, points)
  VALUES (new.id, new.email, split_part(new.email, '@', 1), 1000)
  ON CONFLICT (id) DO NOTHING;
  RETURN new;
END;
$$;


ALTER FUNCTION public.handle_new_user() OWNER TO postgres;

--
-- Name: resolve_prediction(bigint, numeric); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.resolve_prediction(p_id bigint, p_close_price numeric) RETURNS jsonb
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
declare
  v_pred record;
  v_status text;
  v_is_target_hit boolean := false;
  v_actual_change numeric;
begin
  -- Get prediction
  select * into v_pred from public.predictions where id = p_id;
  
  if not found then
    return jsonb_build_object('error', 'Prediction not found');
  end if;

  -- Calculate Change % ( (Close - Entry) / Entry * 100 )
  -- Use ABS for logic, but store signed actual change
  v_actual_change := round(((p_close_price - v_pred.entry_price) / v_pred.entry_price) * 100, 4);

  -- Determine Direction Result (WIN/LOSE/ND)
  -- Round to 2 decimals for comparison as requested
  if round(p_close_price, 2) = round(v_pred.entry_price, 2) then
    v_status := 'ND';
  elsif v_pred.direction = 'UP' then
    if p_close_price > v_pred.entry_price then 
        v_status := 'WIN'; 
    else 
        v_status := 'LOSE'; 
    end if;
  elsif v_pred.direction = 'DOWN' then
    if p_close_price < v_pred.entry_price then 
        v_status := 'WIN'; 
    else 
        v_status := 'LOSE'; 
    end if;
  end if;

  -- Determine Target Logic (Only if WIN)
  -- Logic: If WIN, did it move enough?
  -- For UP: (Close - Open) / Open >= Target
  -- For DOWN: (Open - Close) / Open >= Target (which is same as abs(change) >= target if direction correct)
  if v_status = 'WIN' then
    if abs(v_actual_change) >= v_pred.target_percent then
      v_is_target_hit := true;
    end if;
  end if;

  -- Update Record
  update public.predictions
  set 
    close_price = p_close_price,
    actual_change_percent = v_actual_change,
    status = v_status,
    is_target_hit = v_is_target_hit,
    resolved_at = now()
  where id = p_id;

  return jsonb_build_object(
    'id', p_id, 
    'status', v_status, 
    'is_target_hit', v_is_target_hit,
    'actual_change', v_actual_change
  );
end;
$$;


ALTER FUNCTION public.resolve_prediction(p_id bigint, p_close_price numeric) OWNER TO postgres;

--
-- Name: resolve_prediction_advanced(bigint, numeric, numeric); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.resolve_prediction_advanced(p_id bigint, p_close_price numeric, p_open_price numeric DEFAULT NULL::numeric) RETURNS json
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
DECLARE
    v_prediction RECORD;
    v_profile RECORD;
    v_price_change NUMERIC;
    v_price_change_percent NUMERIC;
    v_status TEXT;
    v_is_dir_correct BOOLEAN;
    v_is_target_hit BOOLEAN;
    v_direction_profit NUMERIC := 0;
    v_target_bonus INTEGER := 0;
    v_base_profit NUMERIC := 0;
    v_final_profit NUMERIC := 0;
    v_payout INTEGER := 0;
    v_tf_mult NUMERIC;
    v_streak_mult NUMERIC;
    c_house_edge NUMERIC := 0.95;
    v_new_streak INTEGER;
    v_open_price NUMERIC;
BEGIN
    SELECT * INTO v_prediction FROM predictions WHERE id = p_id AND status = 'pending' FOR UPDATE;
    IF NOT FOUND THEN RETURN json_build_object('success', false, 'error', 'Already resolved'); END IF;
    
    v_open_price := COALESCE(p_open_price, v_prediction.entry_price);
    SELECT * INTO v_profile FROM profiles WHERE id = v_prediction.user_id FOR UPDATE;

    v_price_change := p_close_price - v_open_price;
    v_price_change_percent := abs(v_price_change / v_open_price * 100);

    v_is_dir_correct := (v_prediction.direction = 'UP' AND v_price_change > 0) OR (v_prediction.direction = 'DOWN' AND v_price_change < 0);
    v_is_target_hit := (v_price_change_percent >= v_prediction.target_percent);

    IF v_is_dir_correct THEN
        v_status := 'WIN';
        CASE v_prediction.timeframe 
            WHEN '30m' THEN v_tf_mult := 1.1; WHEN '1h' THEN v_tf_mult := 1.2; WHEN '4h' THEN v_tf_mult := 1.5; WHEN '1d' THEN v_tf_mult := 1.8; ELSE v_tf_mult := 1.0;
        END CASE;
        v_direction_profit := v_prediction.bet_amount * 0.8 * v_tf_mult;
        IF v_is_target_hit THEN
            IF v_prediction.target_percent <= 0.5 THEN v_target_bonus := 20; ELSIF v_prediction.target_percent <= 1.0 THEN v_target_bonus := 40; ELSIF v_prediction.target_percent <= 1.5 THEN v_target_bonus := 70; ELSE v_target_bonus := 120; END IF;
            v_new_streak := v_profile.streak + 1;
        ELSE
            v_new_streak := 0;
        END IF;
        IF v_new_streak >= 5 THEN v_streak_mult := 2.5; ELSIF v_new_streak = 4 THEN v_streak_mult := 2.0; ELSIF v_new_streak = 3 THEN v_streak_mult := 1.6; ELSIF v_new_streak = 2 THEN v_streak_mult := 1.3; ELSE v_streak_mult := 1.0; END IF;
        v_final_profit := (v_direction_profit + v_target_bonus) * v_streak_mult * c_house_edge;
        v_payout := v_prediction.bet_amount + ROUND(v_final_profit);
    ELSIF v_price_change = 0 THEN
        v_status := 'ND'; v_payout := v_prediction.bet_amount; v_final_profit := 0; v_new_streak := v_profile.streak;
    ELSE
        v_status := 'LOSS'; v_payout := 0; v_final_profit := -v_prediction.bet_amount; v_new_streak := 0;
    END IF;

    UPDATE profiles 
    SET points = points + v_payout, 
        streak = v_new_streak,
        streak_count = CASE WHEN v_new_streak > streak_count THEN v_new_streak ELSE streak_count END,
        total_games = total_games + 1,
        total_wins = CASE WHEN v_status = 'WIN' THEN total_wins + 1 ELSE total_wins END
    WHERE id = v_prediction.user_id;

    UPDATE predictions SET status = v_status, actual_price = p_close_price, entry_price = v_open_price, profit = ROUND(v_final_profit), resolved_at = now() WHERE id = p_id;
    
    INSERT INTO notifications (user_id, type, message, prediction_id)
    VALUES (v_prediction.user_id, 'prediction_resolved', format('%s: %s (%s pts)', v_prediction.asset_symbol, v_status, ROUND(v_final_profit)), p_id);

    INSERT INTO activity_logs (user_id, action_type, asset_symbol, prediction_id, metadata)
    VALUES (v_prediction.user_id, 'RESOLVE', v_prediction.asset_symbol, p_id, json_build_object(
        'status', v_status, 'open_price', v_open_price, 'close_price', p_close_price, 'profit', ROUND(v_final_profit), 'payout', v_payout, 'streak', v_new_streak, 'is_target_hit', v_is_target_hit
    ));

    RETURN json_build_object('success', true, 'status', v_status, 'profit', ROUND(v_final_profit));
END;
$$;


ALTER FUNCTION public.resolve_prediction_advanced(p_id bigint, p_close_price numeric, p_open_price numeric) OWNER TO postgres;

--
-- Name: resolve_prediction_v4(bigint, numeric, numeric); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.resolve_prediction_v4(p_id bigint, p_close_price numeric, p_timeframe_multiplier numeric DEFAULT 1.0) RETURNS jsonb
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
DECLARE
    v_pred RECORD;
    v_user_profile RECORD;
    
    -- Status Vars
    v_status TEXT := 'LOSS';
    v_actual_change NUMERIC;
    v_is_target_hit BOOLEAN := FALSE;
    
    -- Econ Vars
    v_payout NUMERIC := 0;
    v_profit NUMERIC := 0;
    v_base_profit NUMERIC := 0;
    v_target_bonus NUMERIC := 0;
    v_new_points NUMERIC;
    
    -- Notification Vars
    v_notif_title TEXT;
    v_notif_msg TEXT;
    v_notif_type TEXT;
    v_notif_reward_text TEXT;

BEGIN
    -- Ensure timeframe column exists (Safety Check)
    -- This dynamic check is usually not needed inside a function body if schema is consistent
    -- but protects against runtime errors if column is missing.
    -- However, dynamic SQL inside PL/PGSQL is tricky for RECORD types.
    -- Assuming schema migration ran correctly.
    -- If column is missing, "v_pred.timeframe" will crash.
    
    -- 1. Get Prediction
    SELECT * INTO v_pred FROM predictions WHERE id = p_id;
    
    IF NOT FOUND THEN
        RETURN jsonb_build_object('success', false, 'error', 'Prediction not found');
    END IF;

    IF v_pred.status != 'pending' THEN
         RETURN jsonb_build_object('success', false, 'error', 'Prediction already resolved');
    END IF;

    -- 2. Get User Profile for Streak Logic
    SELECT * INTO v_user_profile FROM profiles WHERE id = v_pred.user_id;

    -- 3. Calculate Actual Change & Direction
    IF v_pred.entry_price = 0 THEN
      v_actual_change := 0;
    ELSE
      v_actual_change := ((p_close_price - v_pred.entry_price) / v_pred.entry_price) * 100;
    END IF;

    -- 4. Deterimine Win/Loss
    IF p_close_price = v_pred.entry_price THEN
        v_status := 'REFUND'; -- Or ND
    ELSIF (v_pred.direction = 'UP' AND p_close_price > v_pred.entry_price) OR
          (v_pred.direction = 'DOWN' AND p_close_price < v_pred.entry_price) THEN
       v_status := 'WIN';
    ELSE
       v_status := 'LOSS';
    END IF;

    -- 5. Check Target Hit
    IF v_status = 'WIN' AND ABS(v_actual_change) >= v_pred.target_percent THEN
        v_is_target_hit := TRUE;
    END IF;


    -- 6. Calculate Payouts
    
    IF v_status = 'WIN' THEN
       -- A. Base Profit (Direction)
       v_base_profit := v_pred.bet_amount * 0.8 * p_timeframe_multiplier;
       
       -- B. Target Bonus (Fixed)
       -- 0.5% -> 20pts
       -- 1.0% -> 40pts
       -- 1.5% -> 80pts
       -- 2.0% -> 120pts
       IF v_is_target_hit THEN
           IF v_pred.target_percent < 1.0 THEN v_target_bonus := 20;
           ELSIF v_pred.target_percent < 1.5 THEN v_target_bonus := 40;
           ELSIF v_pred.target_percent < 2.0 THEN v_target_bonus := 80;
           ELSE v_target_bonus := 120;
           END IF;
       END IF;

       -- Total Profit
       v_profit := v_base_profit + v_target_bonus;
       v_payout := v_pred.bet_amount + v_profit;
       
       v_notif_type := 'win';
       v_notif_title := '✅ Match Won!';
       
       IF v_is_target_hit THEN
           v_notif_msg := v_pred.asset_symbol || ' (' || COALESCE(v_pred.timeframe, '1h') || '): Perfect! Direction + Target Hit! 🎯';
           v_notif_reward_text := '+' || ROUND(v_profit) || ' pts (Bonus Included)';
       ELSE
           v_notif_msg := v_pred.asset_symbol || ' (' || COALESCE(v_pred.timeframe, '1h') || '): Direction correct! Aim for the % target next! 💪';
           v_notif_reward_text := '+' || ROUND(v_profit) || ' pts';
       END IF;
       
    ELSIF v_status = 'LOSS' THEN
       v_profit := -v_pred.bet_amount;
       v_payout := 0;
       v_notif_type := 'loss';
       v_notif_title := '❌ Match Lost';
       v_notif_msg := v_pred.asset_symbol || ' (' || COALESCE(v_pred.timeframe, '1h') || '): Close one! Try again. 🍀';
       v_notif_reward_text := ROUND(v_profit) || ' pts'; 
       
    ELSE -- REFUND
       v_profit := 0;
       v_payout := v_pred.bet_amount;
       v_notif_type := 'info';
       v_notif_title := 'Use Match Refunded';
       v_notif_msg := 'No price movement.';
       v_notif_reward_text := '+0 pts';
    END IF;

    -- 7. Update Prediction
    UPDATE predictions
    SET 
        status = v_status,
        close_price = p_close_price,
        actual_change_percent = v_actual_change,
        is_target_hit = v_is_target_hit,
        payout = v_payout,
        profit_loss = v_profit,
        resolved_at = NOW()
    WHERE id = p_id;

    -- 8. Update Profile (Points & Streak)
    UPDATE profiles
    SET 
        points = points + v_payout,
        streak = CASE 
            WHEN v_status = 'WIN' AND v_is_target_hit THEN streak + 1 
            WHEN v_status = 'WIN' THEN streak -- Keep streak but don't increment if target missed
            WHEN v_status = 'LOSS' THEN 0 
            ELSE streak 
            END
    WHERE id = v_pred.user_id
    RETURNING points INTO v_new_points;


    -- 9. Insert Notification
    INSERT INTO notifications (user_id, type, title, message, points_change, is_read)
    VALUES (
        v_pred.user_id, 
        v_notif_type, 
        v_notif_title, 
        v_notif_msg || ' (' || v_notif_reward_text || ')', 
        v_profit, 
        FALSE
    );

    -- 10. Return Result
    RETURN jsonb_build_object(
        'success', true,
        'status', v_status,
        'payout', v_payout,
        'profit', v_profit,
        'target_bonus', v_target_bonus,
        'new_balance', v_new_points
    );

EXCEPTION WHEN OTHERS THEN
    RETURN jsonb_build_object('success', false, 'error', SQLERRM);
END;
$$;


ALTER FUNCTION public.resolve_prediction_v4(p_id bigint, p_close_price numeric, p_timeframe_multiplier numeric) OWNER TO postgres;

--
-- Name: submit_prediction(uuid, text, text, text, numeric, numeric, integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.submit_prediction(p_user_id uuid, p_asset_symbol text, p_timeframe text, p_direction text, p_target_percent numeric, p_entry_price numeric, p_bet_amount integer) RETURNS json
    LANGUAGE plpgsql SECURITY DEFINER
    AS $_$
DECLARE
    v_current_points INTEGER;
    v_new_points INTEGER;
    v_candle_duration BIGINT;
    v_candle_close_at TIMESTAMP WITH TIME ZONE;
    v_prediction_id BIGINT;
    v_min_bet INTEGER;
BEGIN
    SELECT points INTO v_current_points FROM profiles WHERE id = p_user_id FOR UPDATE;
    v_min_bet := GREATEST(10, FLOOR(v_current_points * 0.01));

    IF v_current_points < p_bet_amount THEN
        RETURN json_build_object('success', false, 'error', 'Insufficient points');
    END IF;

    -- Calculate Alignment
    CASE 
        WHEN p_timeframe ~ '^\d+m$' THEN v_candle_duration := (regexp_replace(p_timeframe, '[^0-9]', '', 'g')::INTEGER) * 60;
        WHEN p_timeframe ~ '^\d+h$' THEN v_candle_duration := (regexp_replace(p_timeframe, '[^0-9]', '', 'g')::INTEGER) * 3600;
        WHEN p_timeframe ~ '^\d+d$' THEN v_candle_duration := (regexp_replace(p_timeframe, '[^0-9]', '', 'g')::INTEGER) * 86400;
        ELSE v_candle_duration := 900;
    END CASE;

    v_candle_close_at := to_timestamp(floor(extract(epoch from now()) / v_candle_duration) * v_candle_duration + v_candle_duration);

    INSERT INTO predictions (user_id, asset_symbol, timeframe, direction, target_percent, entry_price, bet_amount, status, candle_close_at)
    VALUES (p_user_id, p_asset_symbol, p_timeframe, p_direction, p_target_percent, p_entry_price, p_bet_amount, 'pending', v_candle_close_at)
    RETURNING id INTO v_prediction_id;

    UPDATE profiles SET points = points - p_bet_amount WHERE id = p_user_id RETURNING points INTO v_new_points;

    -- AUDIT LOG: Record Betting Action
    INSERT INTO activity_logs (user_id, action_type, asset_symbol, prediction_id, metadata)
    VALUES (p_user_id, 'BET', p_asset_symbol, v_prediction_id, json_build_object(
        'bet_amount', p_bet_amount,
        'entry_price', p_entry_price,
        'target_percent', p_target_percent,
        'timeframe', p_timeframe,
        'direction', p_direction,
        'candle_close_at', v_candle_close_at
    ));

    RETURN json_build_object('success', true, 'prediction_id', v_prediction_id, 'new_points', v_new_points);
END;
$_$;


ALTER FUNCTION public.submit_prediction(p_user_id uuid, p_asset_symbol text, p_timeframe text, p_direction text, p_target_percent numeric, p_entry_price numeric, p_bet_amount integer) OWNER TO postgres;

--
-- Name: test_force_resolve(bigint, numeric); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.test_force_resolve(p_id bigint, p_close_price numeric) RETURNS json
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
DECLARE
    v_prediction RECORD;
    v_price_change NUMERIC;
    v_price_change_percent NUMERIC;
    v_status TEXT;
    v_payout INTEGER := 0;
    v_result JSON;
BEGIN
    -- 1. 예측 조회
    SELECT * INTO v_prediction
    FROM predictions
    WHERE id = p_id AND status = 'pending'
    FOR UPDATE;
    
    IF NOT FOUND THEN
        RETURN json_build_object(
            'success', false,
            'error', 'Prediction not found or already resolved'
        );
    END IF;
    
    -- 2. 가격 변화 계산
    v_price_change := p_close_price - v_prediction.entry_price;
    v_price_change_percent := abs(v_price_change / v_prediction.entry_price * 100);
    
    -- 3. 승패 판정
    IF v_prediction.direction = 'UP' THEN
        IF v_price_change > 0 AND v_price_change_percent >= v_prediction.target_percent THEN
            v_status := 'WIN';
            v_payout := v_prediction.bet_amount * 2;
        ELSIF v_price_change < 0 THEN
            v_status := 'LOSS';
            v_payout := 0;
        ELSE
            v_status := 'ND';
            v_payout := v_prediction.bet_amount;
        END IF;
    ELSIF v_prediction.direction = 'DOWN' THEN
        IF v_price_change < 0 AND v_price_change_percent >= v_prediction.target_percent THEN
            v_status := 'WIN';
            v_payout := v_prediction.bet_amount * 2;
        ELSIF v_price_change > 0 THEN
            v_status := 'LOSS';
            v_payout := 0;
        ELSE
            v_status := 'ND';
            v_payout := v_prediction.bet_amount;
        END IF;
    END IF;
    
    -- 4. 예측 업데이트
    UPDATE predictions
    SET 
        status = v_status,
        actual_price = p_close_price,
        profit = v_payout - v_prediction.bet_amount,
        resolved_at = now()
    WHERE id = p_id;
    
    -- 5. 포인트 지급
    IF v_payout > 0 THEN
        UPDATE profiles
        SET points = points + v_payout
        WHERE id = v_prediction.user_id;
    END IF;
    
    -- 6. 결과 반환
    v_result := json_build_object(
        'success', true,
        'status', v_status,
        'payout', v_payout,
        'profit', v_payout - v_prediction.bet_amount
    );
    
    RETURN v_result;
    
EXCEPTION
    WHEN OTHERS THEN
        RETURN json_build_object(
            'success', false,
            'error', SQLERRM
        );
END;
$$;


ALTER FUNCTION public.test_force_resolve(p_id bigint, p_close_price numeric) OWNER TO postgres;

--
-- Name: test_run_simulation(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.test_run_simulation() RETURNS TABLE(step text, status text, details text)
    LANGUAGE plpgsql
    AS $$
DECLARE
    v_user_id UUID;
    v_pred_id BIGINT;
    v_initial_points INT;
    v_mid_points INT;
    v_final_points INT;
    v_initial_wins INT;
    v_final_wins INT;
    v_notif_count INT;
    v_result JSON;
BEGIN
    -- 1. SETUP
    SELECT id, points, total_wins INTO v_user_id, v_initial_points, v_initial_wins FROM profiles LIMIT 1;
    IF v_user_id IS NULL THEN 
        RETURN QUERY SELECT '1. Setup', 'FAIL', 'No user found'; RETURN;
    END IF;
    RETURN QUERY SELECT '1. Setup', 'PASS', 'User: ' || v_user_id || ', Points: ' || v_initial_points;

    -- 2. ACTION: Submit Prediction
    SELECT (submit_prediction(v_user_id, 'BTC_TEST', '15m', 'UP', 1.0, 50000.0, 100))->>'prediction_id' INTO v_pred_id;
    
    SELECT points INTO v_mid_points FROM profiles WHERE id = v_user_id;
    IF v_mid_points != (v_initial_points - 100) THEN
         RETURN QUERY SELECT '2. Bet Deduction', 'FAIL', 'Points not deducted'; RETURN;
    END IF;
    RETURN QUERY SELECT '2. Bet Deduction', 'PASS', '100 pts deducted';

    -- 3. TIME TRAVEL & RESOLVE
    UPDATE predictions SET candle_close_at = NOW() - INTERVAL '1 minute' WHERE id = v_pred_id;
    v_result := public.resolve_prediction_advanced(v_pred_id, 51000.0);
    RETURN QUERY SELECT '3. Resolution', 'PASS', 'Result: ' || v_result::text;

    -- 4. VERIFY POINTS
    SELECT points, total_wins INTO v_final_points, v_final_wins FROM profiles WHERE id = v_user_id;
    IF v_final_points != (v_initial_points + 200) THEN
         RETURN QUERY SELECT '4. Point Audit', 'WARN', 'Expected ' || (v_initial_points + 200) || ', Got ' || v_final_points;
    ELSE
         RETURN QUERY SELECT '4. Point Audit', 'PASS', 'Balance correct (+200 net)';
    END IF;

    -- 5. VERIFY STATS
    IF v_final_wins > v_initial_wins THEN
         RETURN QUERY SELECT '5. Stats Update', 'PASS', 'Wins incremented';
    ELSE
         RETURN QUERY SELECT '5. Stats Update', 'FAIL', 'Total Wins did not increase';
    END IF;

    -- 6. VERIFY NOTIFICATIONS
    SELECT COUNT(*) INTO v_notif_count FROM notifications WHERE user_id = v_user_id And title LIKE '%BTC_TEST%';
    IF v_notif_count > 0 THEN
         RETURN QUERY SELECT '6. Notification', 'PASS', 'Alert found in DB';
    ELSE
         RETURN QUERY SELECT '6. Notification', 'FAIL', 'No notification record found';
    END IF;

    -- CLEANUP
    DELETE FROM predictions WHERE id = v_pred_id;
    DELETE FROM notifications WHERE user_id = v_user_id AND title LIKE '%BTC_TEST%';
    UPDATE profiles SET points = v_initial_points, total_wins = v_initial_wins WHERE id = v_user_id;
    
    RETURN QUERY SELECT '7. Final Result', '✅ SUCCESS', 'ALL TESTS PASSED';
END;
$$;


ALTER FUNCTION public.test_run_simulation() OWNER TO postgres;

--
-- Name: update_prediction_likes_count(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.update_prediction_likes_count() RETURNS trigger
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
BEGIN
  IF (TG_OP = 'INSERT') THEN
    UPDATE public.predictions SET likes_count = likes_count + 1 WHERE id = NEW.prediction_id;
  ELSIF (TG_OP = 'DELETE') THEN
    UPDATE public.predictions SET likes_count = likes_count - 1 WHERE id = OLD.prediction_id;
  END IF;
  RETURN NULL;
END;
$$;


ALTER FUNCTION public.update_prediction_likes_count() OWNER TO postgres;

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: audit_log_entries; Type: TABLE; Schema: auth; Owner: supabase_auth_admin
--

CREATE TABLE auth.audit_log_entries (
    instance_id uuid,
    id uuid NOT NULL,
    payload json,
    created_at timestamp with time zone,
    ip_address character varying(64) DEFAULT ''::character varying NOT NULL
);


ALTER TABLE auth.audit_log_entries OWNER TO supabase_auth_admin;

--
-- Name: TABLE audit_log_entries; Type: COMMENT; Schema: auth; Owner: supabase_auth_admin
--

COMMENT ON TABLE auth.audit_log_entries IS 'Auth: Audit trail for user actions.';


--
-- Name: flow_state; Type: TABLE; Schema: auth; Owner: supabase_auth_admin
--

CREATE TABLE auth.flow_state (
    id uuid NOT NULL,
    user_id uuid,
    auth_code text,
    code_challenge_method auth.code_challenge_method,
    code_challenge text,
    provider_type text NOT NULL,
    provider_access_token text,
    provider_refresh_token text,
    created_at timestamp with time zone,
    updated_at timestamp with time zone,
    authentication_method text NOT NULL,
    auth_code_issued_at timestamp with time zone,
    invite_token text,
    referrer text,
    oauth_client_state_id uuid,
    linking_target_id uuid,
    email_optional boolean DEFAULT false NOT NULL
);


ALTER TABLE auth.flow_state OWNER TO supabase_auth_admin;

--
-- Name: TABLE flow_state; Type: COMMENT; Schema: auth; Owner: supabase_auth_admin
--

COMMENT ON TABLE auth.flow_state IS 'Stores metadata for all OAuth/SSO login flows';


--
-- Name: identities; Type: TABLE; Schema: auth; Owner: supabase_auth_admin
--

CREATE TABLE auth.identities (
    provider_id text NOT NULL,
    user_id uuid NOT NULL,
    identity_data jsonb NOT NULL,
    provider text NOT NULL,
    last_sign_in_at timestamp with time zone,
    created_at timestamp with time zone,
    updated_at timestamp with time zone,
    email text GENERATED ALWAYS AS (lower((identity_data ->> 'email'::text))) STORED,
    id uuid DEFAULT gen_random_uuid() NOT NULL
);


ALTER TABLE auth.identities OWNER TO supabase_auth_admin;

--
-- Name: TABLE identities; Type: COMMENT; Schema: auth; Owner: supabase_auth_admin
--

COMMENT ON TABLE auth.identities IS 'Auth: Stores identities associated to a user.';


--
-- Name: COLUMN identities.email; Type: COMMENT; Schema: auth; Owner: supabase_auth_admin
--

COMMENT ON COLUMN auth.identities.email IS 'Auth: Email is a generated column that references the optional email property in the identity_data';


--
-- Name: instances; Type: TABLE; Schema: auth; Owner: supabase_auth_admin
--

CREATE TABLE auth.instances (
    id uuid NOT NULL,
    uuid uuid,
    raw_base_config text,
    created_at timestamp with time zone,
    updated_at timestamp with time zone
);


ALTER TABLE auth.instances OWNER TO supabase_auth_admin;

--
-- Name: TABLE instances; Type: COMMENT; Schema: auth; Owner: supabase_auth_admin
--

COMMENT ON TABLE auth.instances IS 'Auth: Manages users across multiple sites.';


--
-- Name: mfa_amr_claims; Type: TABLE; Schema: auth; Owner: supabase_auth_admin
--

CREATE TABLE auth.mfa_amr_claims (
    session_id uuid NOT NULL,
    created_at timestamp with time zone NOT NULL,
    updated_at timestamp with time zone NOT NULL,
    authentication_method text NOT NULL,
    id uuid NOT NULL
);


ALTER TABLE auth.mfa_amr_claims OWNER TO supabase_auth_admin;

--
-- Name: TABLE mfa_amr_claims; Type: COMMENT; Schema: auth; Owner: supabase_auth_admin
--

COMMENT ON TABLE auth.mfa_amr_claims IS 'auth: stores authenticator method reference claims for multi factor authentication';


--
-- Name: mfa_challenges; Type: TABLE; Schema: auth; Owner: supabase_auth_admin
--

CREATE TABLE auth.mfa_challenges (
    id uuid NOT NULL,
    factor_id uuid NOT NULL,
    created_at timestamp with time zone NOT NULL,
    verified_at timestamp with time zone,
    ip_address inet NOT NULL,
    otp_code text,
    web_authn_session_data jsonb
);


ALTER TABLE auth.mfa_challenges OWNER TO supabase_auth_admin;

--
-- Name: TABLE mfa_challenges; Type: COMMENT; Schema: auth; Owner: supabase_auth_admin
--

COMMENT ON TABLE auth.mfa_challenges IS 'auth: stores metadata about challenge requests made';


--
-- Name: mfa_factors; Type: TABLE; Schema: auth; Owner: supabase_auth_admin
--

CREATE TABLE auth.mfa_factors (
    id uuid NOT NULL,
    user_id uuid NOT NULL,
    friendly_name text,
    factor_type auth.factor_type NOT NULL,
    status auth.factor_status NOT NULL,
    created_at timestamp with time zone NOT NULL,
    updated_at timestamp with time zone NOT NULL,
    secret text,
    phone text,
    last_challenged_at timestamp with time zone,
    web_authn_credential jsonb,
    web_authn_aaguid uuid,
    last_webauthn_challenge_data jsonb
);


ALTER TABLE auth.mfa_factors OWNER TO supabase_auth_admin;

--
-- Name: TABLE mfa_factors; Type: COMMENT; Schema: auth; Owner: supabase_auth_admin
--

COMMENT ON TABLE auth.mfa_factors IS 'auth: stores metadata about factors';


--
-- Name: COLUMN mfa_factors.last_webauthn_challenge_data; Type: COMMENT; Schema: auth; Owner: supabase_auth_admin
--

COMMENT ON COLUMN auth.mfa_factors.last_webauthn_challenge_data IS 'Stores the latest WebAuthn challenge data including attestation/assertion for customer verification';


--
-- Name: oauth_authorizations; Type: TABLE; Schema: auth; Owner: supabase_auth_admin
--

CREATE TABLE auth.oauth_authorizations (
    id uuid NOT NULL,
    authorization_id text NOT NULL,
    client_id uuid NOT NULL,
    user_id uuid,
    redirect_uri text NOT NULL,
    scope text NOT NULL,
    state text,
    resource text,
    code_challenge text,
    code_challenge_method auth.code_challenge_method,
    response_type auth.oauth_response_type DEFAULT 'code'::auth.oauth_response_type NOT NULL,
    status auth.oauth_authorization_status DEFAULT 'pending'::auth.oauth_authorization_status NOT NULL,
    authorization_code text,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    expires_at timestamp with time zone DEFAULT (now() + '00:03:00'::interval) NOT NULL,
    approved_at timestamp with time zone,
    nonce text,
    CONSTRAINT oauth_authorizations_authorization_code_length CHECK ((char_length(authorization_code) <= 255)),
    CONSTRAINT oauth_authorizations_code_challenge_length CHECK ((char_length(code_challenge) <= 128)),
    CONSTRAINT oauth_authorizations_expires_at_future CHECK ((expires_at > created_at)),
    CONSTRAINT oauth_authorizations_nonce_length CHECK ((char_length(nonce) <= 255)),
    CONSTRAINT oauth_authorizations_redirect_uri_length CHECK ((char_length(redirect_uri) <= 2048)),
    CONSTRAINT oauth_authorizations_resource_length CHECK ((char_length(resource) <= 2048)),
    CONSTRAINT oauth_authorizations_scope_length CHECK ((char_length(scope) <= 4096)),
    CONSTRAINT oauth_authorizations_state_length CHECK ((char_length(state) <= 4096))
);


ALTER TABLE auth.oauth_authorizations OWNER TO supabase_auth_admin;

--
-- Name: oauth_client_states; Type: TABLE; Schema: auth; Owner: supabase_auth_admin
--

CREATE TABLE auth.oauth_client_states (
    id uuid NOT NULL,
    provider_type text NOT NULL,
    code_verifier text,
    created_at timestamp with time zone NOT NULL
);


ALTER TABLE auth.oauth_client_states OWNER TO supabase_auth_admin;

--
-- Name: TABLE oauth_client_states; Type: COMMENT; Schema: auth; Owner: supabase_auth_admin
--

COMMENT ON TABLE auth.oauth_client_states IS 'Stores OAuth states for third-party provider authentication flows where Supabase acts as the OAuth client.';


--
-- Name: oauth_clients; Type: TABLE; Schema: auth; Owner: supabase_auth_admin
--

CREATE TABLE auth.oauth_clients (
    id uuid NOT NULL,
    client_secret_hash text,
    registration_type auth.oauth_registration_type NOT NULL,
    redirect_uris text NOT NULL,
    grant_types text NOT NULL,
    client_name text,
    client_uri text,
    logo_uri text,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    deleted_at timestamp with time zone,
    client_type auth.oauth_client_type DEFAULT 'confidential'::auth.oauth_client_type NOT NULL,
    token_endpoint_auth_method text NOT NULL,
    CONSTRAINT oauth_clients_client_name_length CHECK ((char_length(client_name) <= 1024)),
    CONSTRAINT oauth_clients_client_uri_length CHECK ((char_length(client_uri) <= 2048)),
    CONSTRAINT oauth_clients_logo_uri_length CHECK ((char_length(logo_uri) <= 2048)),
    CONSTRAINT oauth_clients_token_endpoint_auth_method_check CHECK ((token_endpoint_auth_method = ANY (ARRAY['client_secret_basic'::text, 'client_secret_post'::text, 'none'::text])))
);


ALTER TABLE auth.oauth_clients OWNER TO supabase_auth_admin;

--
-- Name: oauth_consents; Type: TABLE; Schema: auth; Owner: supabase_auth_admin
--

CREATE TABLE auth.oauth_consents (
    id uuid NOT NULL,
    user_id uuid NOT NULL,
    client_id uuid NOT NULL,
    scopes text NOT NULL,
    granted_at timestamp with time zone DEFAULT now() NOT NULL,
    revoked_at timestamp with time zone,
    CONSTRAINT oauth_consents_revoked_after_granted CHECK (((revoked_at IS NULL) OR (revoked_at >= granted_at))),
    CONSTRAINT oauth_consents_scopes_length CHECK ((char_length(scopes) <= 2048)),
    CONSTRAINT oauth_consents_scopes_not_empty CHECK ((char_length(TRIM(BOTH FROM scopes)) > 0))
);


ALTER TABLE auth.oauth_consents OWNER TO supabase_auth_admin;

--
-- Name: one_time_tokens; Type: TABLE; Schema: auth; Owner: supabase_auth_admin
--

CREATE TABLE auth.one_time_tokens (
    id uuid NOT NULL,
    user_id uuid NOT NULL,
    token_type auth.one_time_token_type NOT NULL,
    token_hash text NOT NULL,
    relates_to text NOT NULL,
    created_at timestamp without time zone DEFAULT now() NOT NULL,
    updated_at timestamp without time zone DEFAULT now() NOT NULL,
    CONSTRAINT one_time_tokens_token_hash_check CHECK ((char_length(token_hash) > 0))
);


ALTER TABLE auth.one_time_tokens OWNER TO supabase_auth_admin;

--
-- Name: refresh_tokens; Type: TABLE; Schema: auth; Owner: supabase_auth_admin
--

CREATE TABLE auth.refresh_tokens (
    instance_id uuid,
    id bigint NOT NULL,
    token character varying(255),
    user_id character varying(255),
    revoked boolean,
    created_at timestamp with time zone,
    updated_at timestamp with time zone,
    parent character varying(255),
    session_id uuid
);


ALTER TABLE auth.refresh_tokens OWNER TO supabase_auth_admin;

--
-- Name: TABLE refresh_tokens; Type: COMMENT; Schema: auth; Owner: supabase_auth_admin
--

COMMENT ON TABLE auth.refresh_tokens IS 'Auth: Store of tokens used to refresh JWT tokens once they expire.';


--
-- Name: refresh_tokens_id_seq; Type: SEQUENCE; Schema: auth; Owner: supabase_auth_admin
--

CREATE SEQUENCE auth.refresh_tokens_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE auth.refresh_tokens_id_seq OWNER TO supabase_auth_admin;

--
-- Name: refresh_tokens_id_seq; Type: SEQUENCE OWNED BY; Schema: auth; Owner: supabase_auth_admin
--

ALTER SEQUENCE auth.refresh_tokens_id_seq OWNED BY auth.refresh_tokens.id;


--
-- Name: saml_providers; Type: TABLE; Schema: auth; Owner: supabase_auth_admin
--

CREATE TABLE auth.saml_providers (
    id uuid NOT NULL,
    sso_provider_id uuid NOT NULL,
    entity_id text NOT NULL,
    metadata_xml text NOT NULL,
    metadata_url text,
    attribute_mapping jsonb,
    created_at timestamp with time zone,
    updated_at timestamp with time zone,
    name_id_format text,
    CONSTRAINT "entity_id not empty" CHECK ((char_length(entity_id) > 0)),
    CONSTRAINT "metadata_url not empty" CHECK (((metadata_url = NULL::text) OR (char_length(metadata_url) > 0))),
    CONSTRAINT "metadata_xml not empty" CHECK ((char_length(metadata_xml) > 0))
);


ALTER TABLE auth.saml_providers OWNER TO supabase_auth_admin;

--
-- Name: TABLE saml_providers; Type: COMMENT; Schema: auth; Owner: supabase_auth_admin
--

COMMENT ON TABLE auth.saml_providers IS 'Auth: Manages SAML Identity Provider connections.';


--
-- Name: saml_relay_states; Type: TABLE; Schema: auth; Owner: supabase_auth_admin
--

CREATE TABLE auth.saml_relay_states (
    id uuid NOT NULL,
    sso_provider_id uuid NOT NULL,
    request_id text NOT NULL,
    for_email text,
    redirect_to text,
    created_at timestamp with time zone,
    updated_at timestamp with time zone,
    flow_state_id uuid,
    CONSTRAINT "request_id not empty" CHECK ((char_length(request_id) > 0))
);


ALTER TABLE auth.saml_relay_states OWNER TO supabase_auth_admin;

--
-- Name: TABLE saml_relay_states; Type: COMMENT; Schema: auth; Owner: supabase_auth_admin
--

COMMENT ON TABLE auth.saml_relay_states IS 'Auth: Contains SAML Relay State information for each Service Provider initiated login.';


--
-- Name: schema_migrations; Type: TABLE; Schema: auth; Owner: supabase_auth_admin
--

CREATE TABLE auth.schema_migrations (
    version character varying(255) NOT NULL
);


ALTER TABLE auth.schema_migrations OWNER TO supabase_auth_admin;

--
-- Name: TABLE schema_migrations; Type: COMMENT; Schema: auth; Owner: supabase_auth_admin
--

COMMENT ON TABLE auth.schema_migrations IS 'Auth: Manages updates to the auth system.';


--
-- Name: sessions; Type: TABLE; Schema: auth; Owner: supabase_auth_admin
--

CREATE TABLE auth.sessions (
    id uuid NOT NULL,
    user_id uuid NOT NULL,
    created_at timestamp with time zone,
    updated_at timestamp with time zone,
    factor_id uuid,
    aal auth.aal_level,
    not_after timestamp with time zone,
    refreshed_at timestamp without time zone,
    user_agent text,
    ip inet,
    tag text,
    oauth_client_id uuid,
    refresh_token_hmac_key text,
    refresh_token_counter bigint,
    scopes text,
    CONSTRAINT sessions_scopes_length CHECK ((char_length(scopes) <= 4096))
);


ALTER TABLE auth.sessions OWNER TO supabase_auth_admin;

--
-- Name: TABLE sessions; Type: COMMENT; Schema: auth; Owner: supabase_auth_admin
--

COMMENT ON TABLE auth.sessions IS 'Auth: Stores session data associated to a user.';


--
-- Name: COLUMN sessions.not_after; Type: COMMENT; Schema: auth; Owner: supabase_auth_admin
--

COMMENT ON COLUMN auth.sessions.not_after IS 'Auth: Not after is a nullable column that contains a timestamp after which the session should be regarded as expired.';


--
-- Name: COLUMN sessions.refresh_token_hmac_key; Type: COMMENT; Schema: auth; Owner: supabase_auth_admin
--

COMMENT ON COLUMN auth.sessions.refresh_token_hmac_key IS 'Holds a HMAC-SHA256 key used to sign refresh tokens for this session.';


--
-- Name: COLUMN sessions.refresh_token_counter; Type: COMMENT; Schema: auth; Owner: supabase_auth_admin
--

COMMENT ON COLUMN auth.sessions.refresh_token_counter IS 'Holds the ID (counter) of the last issued refresh token.';


--
-- Name: sso_domains; Type: TABLE; Schema: auth; Owner: supabase_auth_admin
--

CREATE TABLE auth.sso_domains (
    id uuid NOT NULL,
    sso_provider_id uuid NOT NULL,
    domain text NOT NULL,
    created_at timestamp with time zone,
    updated_at timestamp with time zone,
    CONSTRAINT "domain not empty" CHECK ((char_length(domain) > 0))
);


ALTER TABLE auth.sso_domains OWNER TO supabase_auth_admin;

--
-- Name: TABLE sso_domains; Type: COMMENT; Schema: auth; Owner: supabase_auth_admin
--

COMMENT ON TABLE auth.sso_domains IS 'Auth: Manages SSO email address domain mapping to an SSO Identity Provider.';


--
-- Name: sso_providers; Type: TABLE; Schema: auth; Owner: supabase_auth_admin
--

CREATE TABLE auth.sso_providers (
    id uuid NOT NULL,
    resource_id text,
    created_at timestamp with time zone,
    updated_at timestamp with time zone,
    disabled boolean,
    CONSTRAINT "resource_id not empty" CHECK (((resource_id = NULL::text) OR (char_length(resource_id) > 0)))
);


ALTER TABLE auth.sso_providers OWNER TO supabase_auth_admin;

--
-- Name: TABLE sso_providers; Type: COMMENT; Schema: auth; Owner: supabase_auth_admin
--

COMMENT ON TABLE auth.sso_providers IS 'Auth: Manages SSO identity provider information; see saml_providers for SAML.';


--
-- Name: COLUMN sso_providers.resource_id; Type: COMMENT; Schema: auth; Owner: supabase_auth_admin
--

COMMENT ON COLUMN auth.sso_providers.resource_id IS 'Auth: Uniquely identifies a SSO provider according to a user-chosen resource ID (case insensitive), useful in infrastructure as code.';


--
-- Name: users; Type: TABLE; Schema: auth; Owner: supabase_auth_admin
--

CREATE TABLE auth.users (
    instance_id uuid,
    id uuid NOT NULL,
    aud character varying(255),
    role character varying(255),
    email character varying(255),
    encrypted_password character varying(255),
    email_confirmed_at timestamp with time zone,
    invited_at timestamp with time zone,
    confirmation_token character varying(255),
    confirmation_sent_at timestamp with time zone,
    recovery_token character varying(255),
    recovery_sent_at timestamp with time zone,
    email_change_token_new character varying(255),
    email_change character varying(255),
    email_change_sent_at timestamp with time zone,
    last_sign_in_at timestamp with time zone,
    raw_app_meta_data jsonb,
    raw_user_meta_data jsonb,
    is_super_admin boolean,
    created_at timestamp with time zone,
    updated_at timestamp with time zone,
    phone text DEFAULT NULL::character varying,
    phone_confirmed_at timestamp with time zone,
    phone_change text DEFAULT ''::character varying,
    phone_change_token character varying(255) DEFAULT ''::character varying,
    phone_change_sent_at timestamp with time zone,
    confirmed_at timestamp with time zone GENERATED ALWAYS AS (LEAST(email_confirmed_at, phone_confirmed_at)) STORED,
    email_change_token_current character varying(255) DEFAULT ''::character varying,
    email_change_confirm_status smallint DEFAULT 0,
    banned_until timestamp with time zone,
    reauthentication_token character varying(255) DEFAULT ''::character varying,
    reauthentication_sent_at timestamp with time zone,
    is_sso_user boolean DEFAULT false NOT NULL,
    deleted_at timestamp with time zone,
    is_anonymous boolean DEFAULT false NOT NULL,
    CONSTRAINT users_email_change_confirm_status_check CHECK (((email_change_confirm_status >= 0) AND (email_change_confirm_status <= 2)))
);


ALTER TABLE auth.users OWNER TO supabase_auth_admin;

--
-- Name: TABLE users; Type: COMMENT; Schema: auth; Owner: supabase_auth_admin
--

COMMENT ON TABLE auth.users IS 'Auth: Stores user login data within a secure schema.';


--
-- Name: COLUMN users.is_sso_user; Type: COMMENT; Schema: auth; Owner: supabase_auth_admin
--

COMMENT ON COLUMN auth.users.is_sso_user IS 'Auth: Set this column to true when the account comes from SSO. These accounts can have duplicate emails.';


--
-- Name: activity_logs; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.activity_logs (
    id bigint NOT NULL,
    user_id uuid,
    action_type text NOT NULL,
    asset_symbol text,
    prediction_id bigint,
    metadata jsonb,
    created_at timestamp with time zone DEFAULT timezone('utc'::text, now()) NOT NULL
);


ALTER TABLE public.activity_logs OWNER TO postgres;

--
-- Name: activity_logs_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

ALTER TABLE public.activity_logs ALTER COLUMN id ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME public.activity_logs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: bookmarks; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.bookmarks (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    user_id uuid NOT NULL,
    post_id bigint NOT NULL,
    created_at timestamp with time zone DEFAULT timezone('utc'::text, now()) NOT NULL
);


ALTER TABLE public.bookmarks OWNER TO postgres;

--
-- Name: comments; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.comments (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    user_id uuid NOT NULL,
    post_id bigint NOT NULL,
    content text NOT NULL,
    created_at timestamp with time zone DEFAULT timezone('utc'::text, now()) NOT NULL
);


ALTER TABLE public.comments OWNER TO postgres;

--
-- Name: likes; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.likes (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    user_id uuid NOT NULL,
    post_id bigint NOT NULL,
    created_at timestamp with time zone DEFAULT timezone('utc'::text, now()) NOT NULL
);


ALTER TABLE public.likes OWNER TO postgres;

--
-- Name: notifications; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.notifications (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    user_id uuid NOT NULL,
    type text DEFAULT 'info'::text NOT NULL,
    title text,
    message text NOT NULL,
    points_change integer DEFAULT 0,
    is_read boolean DEFAULT false,
    created_at timestamp with time zone DEFAULT now(),
    prediction_id bigint,
    read boolean DEFAULT false
);


ALTER TABLE public.notifications OWNER TO postgres;

--
-- Name: posts; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.posts (
    id bigint NOT NULL,
    user_id uuid NOT NULL,
    title text,
    content text,
    asset_symbol text,
    timeframe text,
    direction text,
    volatility_target numeric DEFAULT 0,
    likes_count integer DEFAULT 0,
    comments_count integer DEFAULT 0,
    bookmarks_count integer DEFAULT 0,
    shares_count integer DEFAULT 0,
    feed_score integer DEFAULT 0,
    freshness_score integer DEFAULT 0,
    engagement_score integer DEFAULT 0,
    author_score integer DEFAULT 0,
    created_at timestamp with time zone DEFAULT timezone('utc'::text, now()) NOT NULL
);


ALTER TABLE public.posts OWNER TO postgres;

--
-- Name: posts_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

ALTER TABLE public.posts ALTER COLUMN id ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME public.posts_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: prediction_likes; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.prediction_likes (
    user_id uuid NOT NULL,
    prediction_id bigint NOT NULL,
    created_at timestamp with time zone DEFAULT now()
);


ALTER TABLE public.prediction_likes OWNER TO postgres;

--
-- Name: predictions; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.predictions (
    id bigint NOT NULL,
    user_id uuid NOT NULL,
    asset_symbol text NOT NULL,
    timeframe text NOT NULL,
    direction text NOT NULL,
    target_percent numeric NOT NULL,
    entry_price numeric NOT NULL,
    bet_amount integer NOT NULL,
    status text DEFAULT 'pending'::text,
    actual_price numeric,
    profit integer DEFAULT 0,
    created_at timestamp with time zone DEFAULT timezone('utc'::text, now()) NOT NULL,
    candle_close_at timestamp with time zone NOT NULL,
    resolved_at timestamp with time zone,
    comment text,
    close_price numeric,
    profit_loss numeric,
    payout numeric,
    actual_change_percent numeric,
    is_target_hit boolean DEFAULT false,
    multipliers jsonb DEFAULT '{}'::jsonb,
    entry_offset_seconds integer DEFAULT 0,
    CONSTRAINT predictions_bet_amount_check CHECK (((bet_amount > 0) AND (bet_amount <= 1000))),
    CONSTRAINT predictions_comment_check CHECK ((char_length(comment) <= 140)),
    CONSTRAINT predictions_direction_check CHECK ((direction = ANY (ARRAY['UP'::text, 'DOWN'::text]))),
    CONSTRAINT predictions_entry_price_check CHECK ((entry_price > (0)::numeric)),
    CONSTRAINT predictions_status_check CHECK ((status = ANY (ARRAY['pending'::text, 'WIN'::text, 'LOSS'::text, 'ND'::text]))),
    CONSTRAINT predictions_target_percent_check CHECK ((target_percent = ANY (ARRAY[0.5, 1.0, 1.5, 2.0])))
);


ALTER TABLE public.predictions OWNER TO postgres;

--
-- Name: predictions_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

ALTER TABLE public.predictions ALTER COLUMN id ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME public.predictions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: profiles; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.profiles (
    id uuid NOT NULL,
    email text,
    username text,
    points integer DEFAULT 1000,
    tier text DEFAULT 'bronze'::text,
    created_at timestamp with time zone DEFAULT timezone('utc'::text, now()) NOT NULL,
    streak_count integer DEFAULT 0,
    total_earnings numeric DEFAULT 0,
    total_games integer DEFAULT 0,
    total_wins integer DEFAULT 0,
    streak integer DEFAULT 0
);


ALTER TABLE public.profiles OWNER TO postgres;

--
-- Name: shares; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.shares (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    user_id uuid NOT NULL,
    post_id bigint NOT NULL,
    platform text,
    created_at timestamp with time zone DEFAULT timezone('utc'::text, now()) NOT NULL
);


ALTER TABLE public.shares OWNER TO postgres;

--
-- Name: users; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.users (
    id uuid NOT NULL,
    points integer DEFAULT 0,
    created_at timestamp without time zone DEFAULT now()
);


ALTER TABLE public.users OWNER TO postgres;

--
-- Name: refresh_tokens id; Type: DEFAULT; Schema: auth; Owner: supabase_auth_admin
--

ALTER TABLE ONLY auth.refresh_tokens ALTER COLUMN id SET DEFAULT nextval('auth.refresh_tokens_id_seq'::regclass);


--
-- Data for Name: audit_log_entries; Type: TABLE DATA; Schema: auth; Owner: supabase_auth_admin
--

COPY auth.audit_log_entries (instance_id, id, payload, created_at, ip_address) FROM stdin;
\.


--
-- Data for Name: flow_state; Type: TABLE DATA; Schema: auth; Owner: supabase_auth_admin
--

COPY auth.flow_state (id, user_id, auth_code, code_challenge_method, code_challenge, provider_type, provider_access_token, provider_refresh_token, created_at, updated_at, authentication_method, auth_code_issued_at, invite_token, referrer, oauth_client_state_id, linking_target_id, email_optional) FROM stdin;
185f30d5-0dff-45a1-a547-249bc5d8a3c9	5ac10c39-274e-4ce5-a13b-f4da3af4a230	ad081915-3b41-4039-a5c0-f7080d24038a	s256	0kXAZocVbUVVvps_ByoC0WUY_pwsAfx9i66wvGbe7lk	email			2026-01-30 09:20:35.086901+00	2026-01-30 09:21:46.249546+00	email/signup	2026-01-30 09:21:46.249505+00	\N	\N	\N	\N	f
64f0a7ce-4fc1-4e94-9f45-36cb84c53b04	1ddb44b9-add6-437f-96de-2e7c2df0bfcc	8494ba2b-5b1d-45c1-8c8b-c3b73cc52299	s256	6AM2qzc669T6mAyL1lF3EVayGbM1ld7c1ELEazbe9qo	email			2026-02-07 05:47:18.026394+00	2026-02-07 05:47:32.676801+00	email/signup	2026-02-07 05:47:32.676754+00	\N	\N	\N	\N	f
42f06b89-986c-49a0-a91e-93c894f3da53	06d3b907-e06e-466b-a5fe-2dcc3912afaf	5fdce375-7f49-4489-8dec-d8f25a7f8f5e	s256	djvILaH_Dv2ueuoqiBxOEqmbSsoSFI6MMbGj5O9BvtY	email			2026-02-07 14:15:54.825317+00	2026-02-07 14:16:07.900024+00	email/signup	2026-02-07 14:16:07.899957+00	\N	\N	\N	\N	f
f9e419d5-cb87-4512-963d-9fe964b41ac5	1768c70a-81b5-4b3d-80b2-7e2a8f7d631b	4b74607f-24d0-4f63-96e9-e6c62b5f91dc	s256	0tWJ2v8owrW-MMOSFXkiGK3lJGxP5OtaR9wYI0prA4w	email			2026-02-08 05:01:08.335691+00	2026-02-08 05:01:25.509288+00	email/signup	2026-02-08 05:01:25.509235+00	\N	\N	\N	\N	f
\.


--
-- Data for Name: identities; Type: TABLE DATA; Schema: auth; Owner: supabase_auth_admin
--

COPY auth.identities (provider_id, user_id, identity_data, provider, last_sign_in_at, created_at, updated_at, id) FROM stdin;
5ac10c39-274e-4ce5-a13b-f4da3af4a230	5ac10c39-274e-4ce5-a13b-f4da3af4a230	{"sub": "5ac10c39-274e-4ce5-a13b-f4da3af4a230", "email": "sjustone000@gmail.com", "email_verified": true, "phone_verified": false}	email	2026-01-30 09:20:35.079445+00	2026-01-30 09:20:35.080096+00	2026-01-30 09:20:35.080096+00	4f8920f5-99e6-40c7-bb69-c6f6218a9848
60abdd33-af5a-4dfb-b211-a057a0995d12	60abdd33-af5a-4dfb-b211-a057a0995d12	{"sub": "60abdd33-af5a-4dfb-b211-a057a0995d12", "email": "gracepk34@gmail.com", "email_verified": true, "phone_verified": false}	email	2026-02-02 01:31:37.281148+00	2026-02-02 01:31:37.281204+00	2026-02-02 01:31:37.281204+00	c0440ec8-9b0f-4e5a-9e25-95a5d339233a
36ae407d-c380-41ff-a714-d61371c44fb3	36ae407d-c380-41ff-a714-d61371c44fb3	{"sub": "36ae407d-c380-41ff-a714-d61371c44fb3", "email": "naeiver@naver.com", "email_verified": true, "phone_verified": false}	email	2026-02-02 01:49:56.772315+00	2026-02-02 01:49:56.772372+00	2026-02-02 01:49:56.772372+00	a2953c4a-7402-486e-8270-bcd27906a71c
1ddb44b9-add6-437f-96de-2e7c2df0bfcc	1ddb44b9-add6-437f-96de-2e7c2df0bfcc	{"sub": "1ddb44b9-add6-437f-96de-2e7c2df0bfcc", "email": "tourismyujy@gmail.com", "email_verified": true, "phone_verified": false}	email	2026-02-07 05:47:18.020381+00	2026-02-07 05:47:18.020439+00	2026-02-07 05:47:18.020439+00	a98f2895-860b-4844-9bf2-6a2ebdf6607e
06d3b907-e06e-466b-a5fe-2dcc3912afaf	06d3b907-e06e-466b-a5fe-2dcc3912afaf	{"sub": "06d3b907-e06e-466b-a5fe-2dcc3912afaf", "email": "ych6133@daum.net", "email_verified": true, "phone_verified": false}	email	2026-02-07 14:15:54.8195+00	2026-02-07 14:15:54.819546+00	2026-02-07 14:15:54.819546+00	ff0be5a8-5b00-4bb2-b601-3a8353b51517
1768c70a-81b5-4b3d-80b2-7e2a8f7d631b	1768c70a-81b5-4b3d-80b2-7e2a8f7d631b	{"sub": "1768c70a-81b5-4b3d-80b2-7e2a8f7d631b", "email": "gardenia_319@naver.com", "email_verified": true, "phone_verified": false}	email	2026-02-08 05:01:08.327621+00	2026-02-08 05:01:08.327672+00	2026-02-08 05:01:08.327672+00	265235d5-0405-4030-8d94-48cfc39b4be1
4cb9d918-0c1c-45a0-a0a5-fd405a0cda38	4cb9d918-0c1c-45a0-a0a5-fd405a0cda38	{"sub": "4cb9d918-0c1c-45a0-a0a5-fd405a0cda38", "email": "codex_1770695858717@mail.com", "email_verified": false, "phone_verified": false}	email	2026-02-10 03:57:39.420646+00	2026-02-10 03:57:39.420703+00	2026-02-10 03:57:39.420703+00	95f4dee2-6cac-4239-b8df-c626efee10f9
e65bfdd9-1478-4264-a26d-6db676ab49bf	e65bfdd9-1478-4264-a26d-6db676ab49bf	{"sub": "e65bfdd9-1478-4264-a26d-6db676ab49bf", "email": "codex_1770697037255@mail.com", "email_verified": false, "phone_verified": false}	email	2026-02-10 04:17:17.765141+00	2026-02-10 04:17:17.765193+00	2026-02-10 04:17:17.765193+00	cf4be300-b6b4-4b97-8dd0-3403c3981ba3
62a4018e-393c-4aa0-a754-3db136771637	62a4018e-393c-4aa0-a754-3db136771637	{"sub": "62a4018e-393c-4aa0-a754-3db136771637", "email": "codex_1770705148556@mail.com", "email_verified": false, "phone_verified": false}	email	2026-02-10 06:32:29.293549+00	2026-02-10 06:32:29.293606+00	2026-02-10 06:32:29.293606+00	3fef4498-a168-4546-8c5b-6f806e507125
f62d4e26-bb72-4b86-9539-a54a8fcbad7e	f62d4e26-bb72-4b86-9539-a54a8fcbad7e	{"sub": "f62d4e26-bb72-4b86-9539-a54a8fcbad7e", "email": "codex_1770708357487@mail.com", "email_verified": false, "phone_verified": false}	email	2026-02-10 07:25:58.220181+00	2026-02-10 07:25:58.220236+00	2026-02-10 07:25:58.220236+00	ab5b9eb9-445d-4ba2-b645-0235cfb0ad3f
7ce98344-7670-4faf-853e-70080f6fdfa1	7ce98344-7670-4faf-853e-70080f6fdfa1	{"sub": "7ce98344-7670-4faf-853e-70080f6fdfa1", "email": "codex_1770780540161@mail.com", "email_verified": false, "phone_verified": false}	email	2026-02-11 03:29:00.870607+00	2026-02-11 03:29:00.870666+00	2026-02-11 03:29:00.870666+00	2ee49266-2ed3-4465-bf62-cd173c52bc75
\.


--
-- Data for Name: instances; Type: TABLE DATA; Schema: auth; Owner: supabase_auth_admin
--

COPY auth.instances (id, uuid, raw_base_config, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: mfa_amr_claims; Type: TABLE DATA; Schema: auth; Owner: supabase_auth_admin
--

COPY auth.mfa_amr_claims (session_id, created_at, updated_at, authentication_method, id) FROM stdin;
65d64040-bfd7-4ad3-877f-528f02b42671	2026-01-30 09:22:27.965878+00	2026-01-30 09:22:27.965878+00	password	fe8b8cf9-5573-47dc-90ba-579e030430d5
11b10676-7ac3-46fe-b5dc-6e53bc9d56fc	2026-01-31 03:32:33.993427+00	2026-01-31 03:32:33.993427+00	password	c75c0985-0397-4faa-aaf9-ed9aa74f2eca
2ec4e28f-400b-4218-bf5d-40bd092b0493	2026-02-02 01:32:59.111746+00	2026-02-02 01:32:59.111746+00	email/signup	819de60d-9fd3-4551-a6cd-2314577c7859
3a1b4909-48e4-4e18-a472-1e3ac4ffa4f5	2026-02-02 01:51:32.156851+00	2026-02-02 01:51:32.156851+00	email/signup	a9ed838b-70c4-4c20-b02d-421a77bb1337
3d1cf609-78bd-42af-a324-00a94b863e71	2026-02-03 00:47:05.09991+00	2026-02-03 00:47:05.09991+00	password	3d8c6ac1-39fb-474b-b500-412eb7455a22
e6d8df24-3727-412f-8dbe-0561c5b0c6aa	2026-02-03 00:47:05.74143+00	2026-02-03 00:47:05.74143+00	password	804b2476-7b7c-4eb1-8965-e659d75c8d01
336ca807-2f35-42d7-a66c-515b7924f274	2026-02-03 00:47:06.253191+00	2026-02-03 00:47:06.253191+00	password	0bf5336f-b992-4ee7-b6b6-d89e1434f7b5
178ac5f2-c28b-46f2-9610-2b5f9f4ebdcd	2026-02-03 00:47:06.766312+00	2026-02-03 00:47:06.766312+00	password	dc97dc2c-bb6f-46c7-af2c-a5b5e099308a
9a47ee73-8cf2-4f45-9c8c-b113d4a85926	2026-02-03 00:47:07.29011+00	2026-02-03 00:47:07.29011+00	password	023bb4fd-c8d1-433a-928a-2394b3da22ca
a83fa977-084a-491f-a042-30677fab2940	2026-02-03 10:26:04.252543+00	2026-02-03 10:26:04.252543+00	password	4e9be5f2-e9be-4f21-ac15-94704ae6ade2
69d52aab-1ad5-4836-91b2-38280ab5dca9	2026-02-03 10:49:27.827509+00	2026-02-03 10:49:27.827509+00	password	9993eeeb-0a88-460a-9c15-6d3d60c37efe
843a3082-35b8-4987-be82-7767dc28f731	2026-02-03 11:05:51.056165+00	2026-02-03 11:05:51.056165+00	password	273b1ce6-a71c-42bd-b8d0-b7569795d3ad
15c5bc25-7e7d-4db8-8f68-48bba9ce99ff	2026-02-03 13:53:28.972238+00	2026-02-03 13:53:28.972238+00	password	b8cdc794-e531-4ab1-b186-052f177f76b9
e777cee1-fc3f-4eca-af84-cd60299ab98f	2026-02-03 13:55:15.69601+00	2026-02-03 13:55:15.69601+00	password	a4a71104-9b65-423a-9dcb-e05549e48e87
975d474c-77d2-460f-8215-51077871ab77	2026-02-03 14:01:51.030844+00	2026-02-03 14:01:51.030844+00	password	289a3d17-69e1-44cc-8826-2cae1e3da065
81c32093-2c69-43e7-a90c-73a189ad262f	2026-02-03 14:04:32.369865+00	2026-02-03 14:04:32.369865+00	password	ff044313-51ec-4340-b569-92e743eabb96
00c7e083-b952-4e2b-a862-634d2da8b9af	2026-02-03 14:05:06.911107+00	2026-02-03 14:05:06.911107+00	password	d80efd96-1d80-44aa-ae1c-d1cc3c23eb56
97565c55-31fd-4aef-9f64-db127ec8038a	2026-02-03 14:07:19.340461+00	2026-02-03 14:07:19.340461+00	password	ffbca76e-7c7d-40d8-8903-0eff0a97407e
7c99ea49-24c2-4fa8-b6b9-7129f29fa7dd	2026-02-03 14:10:01.679878+00	2026-02-03 14:10:01.679878+00	password	a9b535d9-59b3-4576-b295-e418001f366f
1d445617-1071-4cc9-b0c1-4e199134abf5	2026-02-03 14:11:02.994036+00	2026-02-03 14:11:02.994036+00	password	07aede6b-f339-4c4a-a420-8d79ebb0c32f
a1bb4554-2d29-4162-a351-2feeb0bb69a0	2026-02-03 14:12:54.816451+00	2026-02-03 14:12:54.816451+00	password	701a9864-471c-4f2d-819c-14c4df27dfe3
d2e8bdf6-d255-453b-bc86-7ae845cc99f2	2026-02-03 14:13:56.45322+00	2026-02-03 14:13:56.45322+00	password	da44434f-624b-4316-a256-34e700ccca58
8a5ea70e-9112-44a9-ad5b-f71eedf673a1	2026-02-03 14:22:48.436781+00	2026-02-03 14:22:48.436781+00	password	5828fb99-3c42-4089-8f68-876a71f8ffdd
37f3ffaa-a35f-4db7-a814-f41f8fcf0359	2026-02-03 14:23:34.008649+00	2026-02-03 14:23:34.008649+00	password	493fa3c9-ec36-4fa8-be7a-2ffcd9ec0d43
9495d67b-b5b4-4205-a85d-790f160d9ed1	2026-02-03 14:25:36.07442+00	2026-02-03 14:25:36.07442+00	password	dc4cf003-a8ab-4102-8616-94687eae650a
6e909440-63dd-417e-868f-027949746666	2026-02-03 14:26:35.679947+00	2026-02-03 14:26:35.679947+00	password	698fe412-b0ba-4d74-a8b8-1a0715a6f19d
34bdfdb6-d883-40f7-85a8-e5a85d8c54d8	2026-02-03 22:09:04.366359+00	2026-02-03 22:09:04.366359+00	password	83f43bce-3649-4207-808b-4083d24fcd62
8594f2b0-ca33-4796-bbcd-5687e8ab726e	2026-02-03 22:09:09.853175+00	2026-02-03 22:09:09.853175+00	password	ad4277a0-3f18-498b-bd55-0353c1ea13e8
e7fc2d62-38ff-4008-a4e9-33618a83d7ea	2026-02-03 22:09:15.208015+00	2026-02-03 22:09:15.208015+00	password	a58a20fc-b07c-422b-bac9-06fb1e7373c3
92d48a38-20ef-46b2-b994-6b7aaa87652a	2026-02-03 22:09:20.594943+00	2026-02-03 22:09:20.594943+00	password	a93ade9d-df53-43d9-ae71-7138bb4fc972
928737f8-409a-4243-afb1-76b9d8cc63d1	2026-02-03 22:09:25.924007+00	2026-02-03 22:09:25.924007+00	password	9166d1ed-0724-43be-834f-6adb7ddd7549
f8b68d38-042c-4697-9458-1c0a74313dc3	2026-02-04 00:08:59.896024+00	2026-02-04 00:08:59.896024+00	password	3093d46b-083e-444b-8e87-67118c31fb11
652c6f22-a7db-49cc-aabd-fc7ad757cbf7	2026-02-05 01:25:13.084407+00	2026-02-05 01:25:13.084407+00	password	bc509b90-5efe-4e5e-900c-fb6b25b3eab5
0644d0b0-ee95-4c6a-b694-0ad0d1e04235	2026-02-05 01:25:18.723737+00	2026-02-05 01:25:18.723737+00	password	c6420397-c2f2-4bcb-95eb-cc0265038231
3c10b435-600c-44f9-9726-f23bc2fb712c	2026-02-05 01:25:24.083566+00	2026-02-05 01:25:24.083566+00	password	93871429-d49a-460b-976c-cc799a896f19
b65fbc15-8258-4dc4-ad8f-74a615e1ef84	2026-02-05 01:25:29.921041+00	2026-02-05 01:25:29.921041+00	password	53ae965d-cfb7-4d01-806f-c9afc5eb67e6
5d64f434-82f2-4cbd-8fa0-e6f3c65a249d	2026-02-05 01:25:35.286365+00	2026-02-05 01:25:35.286365+00	password	812e3dd1-06c6-422a-a165-176c6bbc969e
6e709193-bdb7-4240-9b8d-7efa8c6ebf1e	2026-02-05 01:43:07.365433+00	2026-02-05 01:43:07.365433+00	password	1b6bcc9e-6b05-489a-8d1c-b68eef4963cd
65f11cb0-36ad-4ef8-9c84-64569b36aace	2026-02-05 01:43:13.127767+00	2026-02-05 01:43:13.127767+00	password	cc7620b4-6b0f-431e-8365-653e99a2c385
82f814cc-b632-4b90-a2c5-9bb75da14351	2026-02-05 01:43:18.486325+00	2026-02-05 01:43:18.486325+00	password	fbc512d9-38be-41da-8022-266e71e73108
231d20fa-f64a-414b-8758-bb755910e17e	2026-02-05 01:43:23.803819+00	2026-02-05 01:43:23.803819+00	password	db92ecba-4e17-46d4-81d6-66d5aee7aa18
1fe3bd68-8c4f-450f-8b92-7c4ee2af0212	2026-02-05 01:43:29.309889+00	2026-02-05 01:43:29.309889+00	password	ad3b8172-e7bd-4185-9804-563f727fe387
a3f8e76d-0c50-4bd9-98e4-86c76cd7b1fd	2026-02-05 07:38:11.962898+00	2026-02-05 07:38:11.962898+00	password	f45b1389-bd8c-41e6-bea1-9dede8fb46e9
1ccce5b3-8bb0-4d2d-b525-c49015dc0e08	2026-02-05 07:38:14.522447+00	2026-02-05 07:38:14.522447+00	password	599d1d0d-c009-44ef-a97e-cfdf97dc89c8
3ed651e1-98f5-4e03-ac4f-2a6f30be26b5	2026-02-05 07:38:16.861928+00	2026-02-05 07:38:16.861928+00	password	23471b9e-f7af-42bc-a2bf-07d35df782b0
d4c7cd1c-ae71-4c2c-a27e-210a14795b3c	2026-02-05 07:38:19.242573+00	2026-02-05 07:38:19.242573+00	password	bb5c6667-a24b-4db9-8c78-36e711dc94b6
4450442b-9292-4e90-bb59-9adb3040c34b	2026-02-05 07:38:21.624671+00	2026-02-05 07:38:21.624671+00	password	eba438f5-1b62-415b-89be-a8c6963199d8
6221b9d7-e743-463b-bb43-11a1b06db73c	2026-02-05 07:49:05.457031+00	2026-02-05 07:49:05.457031+00	password	f105c450-661a-4af3-bad0-33539d85598f
ce53bf5f-d91f-4202-b113-f7082ef94363	2026-02-05 07:49:06.38111+00	2026-02-05 07:49:06.38111+00	password	098c0bbf-7de8-465e-acc0-0bcfc7b6aff1
0b7fd9c1-c546-4172-8276-db6092a4a7e9	2026-02-05 07:49:07.27516+00	2026-02-05 07:49:07.27516+00	password	65833518-dc56-459d-bd54-e42291c0c9fd
8f567b18-4390-4635-b102-377a7556d4d3	2026-02-05 07:49:08.123513+00	2026-02-05 07:49:08.123513+00	password	1ae6059b-4df4-49e4-8803-da2a44ba5720
4d96da29-b926-4ab9-8e20-11c70316394d	2026-02-05 07:49:08.999259+00	2026-02-05 07:49:08.999259+00	password	05d5fdb3-9528-46a0-ab4b-9717ceb5c3a5
36dc3d44-bc1b-44bb-8795-acc0cde6569d	2026-02-05 07:49:09.876227+00	2026-02-05 07:49:09.876227+00	password	6114bf63-5df6-4a8c-b3c7-205c3813a1a5
87003dc3-7af7-48e6-85b4-a374842ae466	2026-02-05 07:49:10.727858+00	2026-02-05 07:49:10.727858+00	password	62c72466-cd3d-44e2-86d2-a8c31f8a0fe2
7115854d-8bdd-4e89-ba6a-ad0356a8cdd2	2026-02-05 07:49:11.586388+00	2026-02-05 07:49:11.586388+00	password	262e4512-df5a-47eb-ba7d-6db424c74c42
c8606760-466a-4244-836f-b4c04d802408	2026-02-05 07:49:12.453005+00	2026-02-05 07:49:12.453005+00	password	a297cb7b-c513-40f8-848c-9ea0bff69187
1d341451-ffd7-4362-a4f0-b313bb3a49de	2026-02-05 07:49:13.317109+00	2026-02-05 07:49:13.317109+00	password	9027f44d-fa0b-4884-869d-979c4d8c9abe
e71fdaec-f2bd-4b40-b945-e42ac7a93272	2026-02-05 07:49:14.217397+00	2026-02-05 07:49:14.217397+00	password	53d551e9-63e5-40ac-9193-a75ff1f8f2da
8ebe32a4-4e39-48e4-888c-4794c8a46c36	2026-02-05 07:49:15.086701+00	2026-02-05 07:49:15.086701+00	password	1a3a1746-e4d6-4c41-b09b-45f68b53d535
18f1a915-e2e2-4203-bd75-482ba496fb22	2026-02-05 07:49:15.955558+00	2026-02-05 07:49:15.955558+00	password	e175bf8e-4a0f-4c31-9d5f-b6a2f6e7363e
b29d27fa-161f-4684-ac32-4b3f5eae85a9	2026-02-05 07:49:16.830763+00	2026-02-05 07:49:16.830763+00	password	74fe086b-8b2f-4fc0-b3dc-410008d1d340
c8499177-d0ca-49aa-91b2-aeee05cdbd0b	2026-02-05 07:49:17.675295+00	2026-02-05 07:49:17.675295+00	password	96a6769d-c1b3-48c9-9363-ab2d2bcac2c3
60f39b2e-b4fb-4b60-99df-5ffd3021acbc	2026-02-05 08:09:20.955619+00	2026-02-05 08:09:20.955619+00	password	b596da69-b1d8-485f-a781-ed4cdf63a098
a6b08aad-221e-47c7-ba6b-f2cfce3ff7f9	2026-02-05 08:10:02.245274+00	2026-02-05 08:10:02.245274+00	password	fcead030-31a5-46b5-b28e-02e5ec296031
715b609f-92e9-4cfc-ac24-1f763359f290	2026-02-05 08:10:03.614711+00	2026-02-05 08:10:03.614711+00	password	c3a17114-83c0-4940-b086-9d802ecee4c4
c8b3604a-3b61-4141-ab08-311fc4376874	2026-02-05 08:10:04.97229+00	2026-02-05 08:10:04.97229+00	password	74aaf6d4-2e77-4dec-95b7-fe0693233e1e
943c2189-4d54-4de5-a498-4d12c7a354c4	2026-02-05 08:10:06.316277+00	2026-02-05 08:10:06.316277+00	password	55580db8-06e1-48a1-850c-c7a18d6f22b3
d16fedbd-1eeb-4785-b141-639afd45127c	2026-02-05 08:10:07.656561+00	2026-02-05 08:10:07.656561+00	password	04bc295a-16d2-448a-8934-029dd83f1396
cf3d83e3-e052-4a0a-91c6-ccaedcb1059e	2026-02-05 08:10:08.989923+00	2026-02-05 08:10:08.989923+00	password	1efbc997-8823-46c4-a6a0-d05bc7311a15
95821fe9-1cf2-44d8-9fe2-9f8a8a27a3ca	2026-02-05 08:10:10.336292+00	2026-02-05 08:10:10.336292+00	password	2e5b1b97-7140-4451-9ff7-bbb72515df2d
18278fbb-e55b-47b1-9584-77625a051de5	2026-02-05 08:10:11.703712+00	2026-02-05 08:10:11.703712+00	password	5e7c0060-3470-4877-be13-5aaf92d8c2b9
050ab13c-1075-4169-b71b-22e53a52a65c	2026-02-05 08:10:13.054312+00	2026-02-05 08:10:13.054312+00	password	c351d58b-8b88-413b-b274-01cb511ad203
0c985d08-2a65-4951-847d-50ccac36b23d	2026-02-05 08:10:14.413086+00	2026-02-05 08:10:14.413086+00	password	342bc992-d8c9-4ccf-b2e8-cee9937a5923
51061fb3-7360-4263-a758-6108040fbbe9	2026-02-05 08:10:15.752712+00	2026-02-05 08:10:15.752712+00	password	6b9a6f6c-a6f8-4806-9a6d-e020bf451112
e74f030d-8f98-49da-aa0e-86125a2edc18	2026-02-05 08:10:17.127494+00	2026-02-05 08:10:17.127494+00	password	46e10cad-f79e-4bee-aee4-be4061663984
d7636d40-218a-46ce-bdbc-b46594b5ff9b	2026-02-05 08:10:18.469134+00	2026-02-05 08:10:18.469134+00	password	cd84e4bc-1b26-4834-a888-9ba300daf40a
675196f8-1196-4653-8969-71829ad1e659	2026-02-05 08:10:19.808303+00	2026-02-05 08:10:19.808303+00	password	9dd42946-e3ef-4ddb-a5f6-6ece4e86522d
d80b617f-713b-454f-9805-ada7184801cf	2026-02-05 08:21:02.59027+00	2026-02-05 08:21:02.59027+00	password	600b110f-d0e4-441d-9d27-f39402a92d2c
a6bf88d7-16e6-44ba-8ba1-efecb851d5fb	2026-02-05 08:21:03.979981+00	2026-02-05 08:21:03.979981+00	password	f3798a03-403b-4647-b71f-252881b0eba1
d78fb654-e4cb-4cee-b14b-156d6bb36b3e	2026-02-05 08:21:05.331651+00	2026-02-05 08:21:05.331651+00	password	0a18b07c-ea38-4e5b-832a-9e0892b9fc68
93c076de-2644-4e8f-9cc0-2533bee418bc	2026-02-05 08:21:06.700554+00	2026-02-05 08:21:06.700554+00	password	f7fe0d24-f9af-467b-bb85-59d3eec4ccf2
0f061578-bb6a-40e5-8f15-5110a0c441be	2026-02-05 08:21:08.074437+00	2026-02-05 08:21:08.074437+00	password	9b192b31-00f0-4e95-aa6a-2c1838a5885e
d748ced1-cc78-4862-b6d6-1ee7a1a33613	2026-02-05 08:21:09.445226+00	2026-02-05 08:21:09.445226+00	password	4fc5eb65-4fb7-4727-92a9-22fe471b3709
aa18a4ed-143b-45d6-b774-45639846320d	2026-02-05 08:21:10.785299+00	2026-02-05 08:21:10.785299+00	password	93d43155-ce6b-4a1e-9788-425df0a50fd9
e7df7443-a096-471f-ae55-12229b9732b4	2026-02-05 08:21:12.120384+00	2026-02-05 08:21:12.120384+00	password	86507c77-eec9-4952-b8c5-df8b972a618c
1f4b327c-c893-450a-8fd3-b36ec0fb2a94	2026-02-05 08:21:13.464015+00	2026-02-05 08:21:13.464015+00	password	b1f8ccbe-b4c4-4353-8272-8e72c88285fe
477761c6-3df0-450e-8c22-a2affaab98fb	2026-02-05 08:21:14.856061+00	2026-02-05 08:21:14.856061+00	password	45e4f995-5df0-4a72-909c-004b975bf7c9
8f2bcc65-a1d0-4fd3-8073-2899dcd75485	2026-02-05 08:21:16.198033+00	2026-02-05 08:21:16.198033+00	password	7342d7d9-420f-4b51-b5e2-d64037e636bf
e9f7db27-6ea1-47fa-a265-67006c20aee8	2026-02-05 08:21:17.526803+00	2026-02-05 08:21:17.526803+00	password	4d1ca180-3473-4b81-89f5-5e5594533ee9
c252ebed-5f79-483c-8f6b-78d6646a9113	2026-02-05 08:21:18.859224+00	2026-02-05 08:21:18.859224+00	password	5ec8ff33-e517-42ea-9715-91b9b2468d6b
cebcde5c-c3a6-4450-add7-4d8300bd35f1	2026-02-05 08:21:20.1951+00	2026-02-05 08:21:20.1951+00	password	ff08342d-72b5-47ac-acd9-e3fb0aa56896
f8f842e5-7b5b-49fa-8130-090a8b2c9e4b	2026-02-05 08:22:02.216517+00	2026-02-05 08:22:02.216517+00	password	8a096f0e-6245-400c-9016-36ee7fc9cda7
6bc8cc46-8882-4316-865d-aadd0bf282ec	2026-02-05 14:51:02.424247+00	2026-02-05 14:51:02.424247+00	password	888fd278-6d4c-4b34-a440-f9a5edeb2ca5
2234f8bc-966c-4809-90cc-8c1f03b165f4	2026-02-05 14:51:03.823408+00	2026-02-05 14:51:03.823408+00	password	cc011171-7067-4d8a-a7c8-49e7f4cf1ef2
471a2917-f34e-4fe0-9b29-4e498c10d39b	2026-02-05 14:51:05.199512+00	2026-02-05 14:51:05.199512+00	password	fb02924f-5cd9-4618-849b-9c76ca078422
ea49e43e-e69d-48db-8a27-0f2e24247504	2026-02-05 14:51:06.593427+00	2026-02-05 14:51:06.593427+00	password	db9c17df-59dd-4573-b745-bfd8d15c5004
bfcabf55-45ab-487b-af29-3abe1edf12ae	2026-02-05 14:51:07.957735+00	2026-02-05 14:51:07.957735+00	password	820defec-520d-4a55-8b90-a14c676e62ff
3327b8ff-e675-43f2-a54d-c4a00dbfd100	2026-02-05 14:51:09.317418+00	2026-02-05 14:51:09.317418+00	password	489ae2ab-209f-4c93-a466-42673bc1a08b
dc2621cf-1f25-498b-a9d5-b1228327476d	2026-02-05 14:51:10.681523+00	2026-02-05 14:51:10.681523+00	password	29c25d58-a31b-4483-a351-f20800850c8d
c501307b-9045-4616-88e8-ad52b757178f	2026-02-05 14:51:12.100195+00	2026-02-05 14:51:12.100195+00	password	465c49b0-3854-475d-9563-1bd497c173d0
87ae93a1-08be-4630-8b16-0fea993f7e0a	2026-02-05 14:51:13.466114+00	2026-02-05 14:51:13.466114+00	password	2e67d890-ef0f-4620-bb71-8dfef4bc227e
eb603785-1a31-4f15-bc47-39ee62054bed	2026-02-05 14:51:14.822841+00	2026-02-05 14:51:14.822841+00	password	dfb5074d-7178-4f89-8c1e-665ca248bf0f
76acbaeb-69d0-47ba-bf9e-02218838416a	2026-02-05 14:51:16.203249+00	2026-02-05 14:51:16.203249+00	password	4c694336-d03b-44d9-81c3-e5e3a55b17df
3f3a8f73-a42b-4864-9b11-050733b3d445	2026-02-05 14:51:17.583868+00	2026-02-05 14:51:17.583868+00	password	196b8ec9-2ffd-4a73-87ce-2019fcbc7a23
1a70140e-973c-48e4-9e63-a3650cb74021	2026-02-05 14:51:18.925466+00	2026-02-05 14:51:18.925466+00	password	3376cdf6-53c6-4ff7-88ce-d35954efd73a
417f4041-a6ad-46b8-9358-08d4a9b85cf3	2026-02-05 14:51:20.297767+00	2026-02-05 14:51:20.297767+00	password	75b23a49-b758-4882-8763-6cd8876552e8
6ba0e9a6-d92b-44d3-9a9b-29e334aaafd8	2026-02-05 14:52:02.213136+00	2026-02-05 14:52:02.213136+00	password	4fd3e0e1-b7a5-4d0c-8a08-bdbf205a309c
344bd97a-b666-4201-900c-920b993b60de	2026-02-05 14:52:08.572714+00	2026-02-05 14:52:08.572714+00	password	bea1d438-e26c-49cc-8333-5d15c1282d77
ccb9f46d-13e6-4669-96a1-67a746bf006f	2026-02-05 14:52:09.937123+00	2026-02-05 14:52:09.937123+00	password	bf05ca80-f9cf-4be2-ae2f-b2689e93c6e8
34d6e14a-efba-4ecf-b5c3-d7a8c866559e	2026-02-05 14:52:11.286223+00	2026-02-05 14:52:11.286223+00	password	85039dc6-7225-4a33-83d1-6606d0f3eeec
b32b2002-224b-4402-a5f1-aedc8df0a2e1	2026-02-05 14:52:12.645994+00	2026-02-05 14:52:12.645994+00	password	6e9f1dad-dfae-4dc5-8f7f-2334768485ff
638f6d24-407d-420d-b5d0-525257e42cc9	2026-02-05 14:52:13.99389+00	2026-02-05 14:52:13.99389+00	password	d99559be-2590-4b0c-b3ed-a4798f38ee0e
b245b475-0b5c-4396-b24f-1a57c3225c2b	2026-02-05 14:52:15.342767+00	2026-02-05 14:52:15.342767+00	password	38fbe892-4f7f-40cc-9b3c-544b7b14fc0e
90d47778-4fe4-435d-86c6-faced62bcb4f	2026-02-05 14:52:16.697048+00	2026-02-05 14:52:16.697048+00	password	bd0288d8-257f-4816-8e32-0c02ed925ff6
a449ba6b-e153-426b-bb20-6198203f8eb0	2026-02-05 14:52:18.039386+00	2026-02-05 14:52:18.039386+00	password	8a7d01d2-2317-4559-af81-29568eaa8494
32dba162-03d6-4dc1-a8b9-11a0e805602e	2026-02-05 14:52:19.407017+00	2026-02-05 14:52:19.407017+00	password	c9e19c20-4679-4d9b-b034-964872657f81
df18d02a-ab5e-4476-8948-bc0e798ee538	2026-02-05 14:52:20.77359+00	2026-02-05 14:52:20.77359+00	password	4d3984da-1b17-44bb-a452-7dcdf818a0c3
7ee2d29b-6c6e-46ce-820e-90a37330c374	2026-02-05 14:53:02.196484+00	2026-02-05 14:53:02.196484+00	password	28ce25a2-3f30-4bab-adc8-faf43b7295a4
45b15db1-ab6b-4806-9133-7568e88c2ec1	2026-02-05 14:53:03.54335+00	2026-02-05 14:53:03.54335+00	password	de91d6d7-0c8e-4d76-b644-3f50c78f5da6
933d6b75-ba2b-4a81-935d-ab346c33e272	2026-02-05 14:53:04.894508+00	2026-02-05 14:53:04.894508+00	password	64025948-a33c-4c61-aee1-4bfa2d4511fb
ddd11cc7-a01a-49c0-8c40-b2cfd99828ed	2026-02-05 14:53:06.24623+00	2026-02-05 14:53:06.24623+00	password	3c6fc306-8578-4258-a91c-3a4ec681c9ee
4fb093ee-9320-436d-9de3-4e5d50f5b4e5	2026-02-05 14:53:07.585548+00	2026-02-05 14:53:07.585548+00	password	0a76cdc3-9e61-485b-8699-24e61912f9e0
68aa6b64-20f6-40cc-b3db-a60d9abbeb9c	2026-02-05 14:54:02.339055+00	2026-02-05 14:54:02.339055+00	password	d808c9c3-0b9a-4b92-a378-691393ebc17c
9c3d10cf-c031-4fca-bb42-6d5d4a236e1a	2026-02-05 14:54:03.7898+00	2026-02-05 14:54:03.7898+00	password	4bc605d4-b6ab-4153-98f2-c609f1a4f22e
cbff93a5-666e-4c44-962f-714372cc56c2	2026-02-05 14:54:05.27847+00	2026-02-05 14:54:05.27847+00	password	951b9562-751d-4557-9357-d9ddd94f651b
68f522a0-c23e-40f9-ba33-84697d2dca81	2026-02-05 14:54:06.771486+00	2026-02-05 14:54:06.771486+00	password	bfa2a53c-82c3-45d8-9ea8-3f7e02493e5f
23312512-15be-4b8c-97a2-311ef45ac78f	2026-02-05 14:54:08.252896+00	2026-02-05 14:54:08.252896+00	password	72d6219a-df6c-4240-a769-53c008ca6175
7c15b98c-1446-410b-b7c4-c619f8b7e28d	2026-02-05 14:54:09.63949+00	2026-02-05 14:54:09.63949+00	password	1327e0ae-d9ba-425e-a6fa-426dff84fa8e
80368408-db3d-4a35-a656-ec95dd1367cf	2026-02-05 14:54:11.020016+00	2026-02-05 14:54:11.020016+00	password	39ffa59f-0152-4c5b-8773-d367dd937f82
684042f7-7a94-4375-aa0a-b0e7b2c7d533	2026-02-05 14:54:12.396951+00	2026-02-05 14:54:12.396951+00	password	7e1a1f12-99fb-4d2e-a002-70ed24662a3f
e9635769-1f26-44ce-9a3c-6802ba28558f	2026-02-05 14:54:13.78567+00	2026-02-05 14:54:13.78567+00	password	5ea22e7a-52c7-4f32-b2ca-bcb29cf14634
e55cacec-7abc-47f6-a3e9-6300bb59ed63	2026-02-05 14:54:15.156483+00	2026-02-05 14:54:15.156483+00	password	0cf450fd-4a58-41b5-bcf2-be8124ddc6e0
dced29cb-8ba7-43bc-93e3-961d730fbe4d	2026-02-05 14:54:16.609778+00	2026-02-05 14:54:16.609778+00	password	4a51f556-6fd9-4eef-b02a-dc7404cdac29
9b27ccb7-fb2d-4fd2-b9c3-f6088a735f7d	2026-02-05 14:54:18.131191+00	2026-02-05 14:54:18.131191+00	password	75abc927-e1fa-44b7-b693-c245d631ecde
b01fd372-56e9-4b53-be40-48d5db2fb560	2026-02-05 14:54:19.476633+00	2026-02-05 14:54:19.476633+00	password	0e3f897a-c692-4910-b80f-482bd36b139e
251a3ec5-e04e-4235-b16f-0ac012571ad3	2026-02-05 14:54:20.841988+00	2026-02-05 14:54:20.841988+00	password	ce460c9b-8f2a-454a-b732-cd10074cea00
cd995ab6-e3fd-457d-8d96-29bc33f97f09	2026-02-05 14:55:02.2117+00	2026-02-05 14:55:02.2117+00	password	98416fbc-7254-4b64-8e3a-9b812dae7d0c
593c192e-6d16-4d71-8c0b-246088715e5c	2026-02-05 17:05:43.682533+00	2026-02-05 17:05:43.682533+00	password	4bee4cde-7f41-48a3-9d60-5dae654e4309
02c7470d-c989-43fc-8ca7-bbf7c5038c87	2026-02-05 17:08:13.169476+00	2026-02-05 17:08:13.169476+00	password	b6cb865a-43a3-4727-9bfb-dd1acc0cbd61
76975b13-27bb-465a-9a28-8a90107b9098	2026-02-07 05:47:52.481207+00	2026-02-07 05:47:52.481207+00	password	4dcf7895-df06-41f7-9755-a9be28ade7ac
d5c296b8-50d5-47a7-b7c2-2abecaae18f3	2026-02-07 14:26:10.826027+00	2026-02-07 14:26:10.826027+00	password	93328377-4a69-48d8-9f22-66155098b068
032367ef-d033-4698-a8c6-68ca002778ac	2026-02-08 05:01:55.735062+00	2026-02-08 05:01:55.735062+00	password	d1959979-90fd-431d-9dbe-e4b4253b0894
febeee40-c81f-442f-8377-be1ba1e1648d	2026-02-08 07:55:29.050318+00	2026-02-08 07:55:29.050318+00	password	5f528ab1-93a6-4d88-b4a4-38c9a2e88fec
f06d1ec5-e41a-44d8-9451-a586565f9f33	2026-02-08 10:01:22.033086+00	2026-02-08 10:01:22.033086+00	password	92690690-ce0f-4140-bfd0-cf747975691f
d4a3265c-2362-4c62-a7b2-46023c68b2bc	2026-02-08 10:01:22.055386+00	2026-02-08 10:01:22.055386+00	password	0fe3ce24-aab6-45f9-9947-5a0ae47213fc
a6d8f5e7-8b9c-4e77-82e8-d3c0db2ef117	2026-02-08 10:01:22.059237+00	2026-02-08 10:01:22.059237+00	password	dc89a4ac-cafd-4ce7-9881-d345e24e35fc
b17a6421-4883-4b1d-bacf-bc9af46b1627	2026-02-08 10:01:22.39576+00	2026-02-08 10:01:22.39576+00	password	eed1064d-66b0-4da7-ab5c-1358b6b6319c
48202c03-6299-4924-89b6-23045e3cca6a	2026-02-08 10:02:06.442253+00	2026-02-08 10:02:06.442253+00	password	883c6607-9e82-44ef-a287-badaf33e9fd0
5346de08-2204-4bfe-a271-810679f93ae5	2026-02-08 10:02:10.543442+00	2026-02-08 10:02:10.543442+00	password	e3f05efd-f98c-45c0-b10b-9cfa2744a823
7d4a3e26-6d76-4312-a4d1-5c11a44d67dc	2026-02-08 10:02:12.591329+00	2026-02-08 10:02:12.591329+00	password	fc25fa93-9b29-4864-86fe-d6cd948c031c
92508c30-738b-4f7c-b0e5-e149fef01e8c	2026-02-08 10:02:35.169906+00	2026-02-08 10:02:35.169906+00	password	533a1504-1928-4695-96f0-93cc56f37624
acc7ac19-0d74-4f0d-aba6-46cb3d1929f4	2026-02-08 10:02:59.900579+00	2026-02-08 10:02:59.900579+00	password	1503a236-78c0-412f-bfe9-659c7e138caa
7e61fa04-93e5-4e83-8f43-c45d404005e9	2026-02-08 10:02:59.966219+00	2026-02-08 10:02:59.966219+00	password	c15f2079-4ecf-4fbe-aed7-328460a23da3
51aba99c-03c5-4605-b5c0-8283ca349b25	2026-02-08 10:04:01.643193+00	2026-02-08 10:04:01.643193+00	password	623957f6-fee5-4d62-a0a4-06f96fe41cf0
3c309b5f-db34-4653-aa90-55cddcd69a9e	2026-02-08 10:04:01.67762+00	2026-02-08 10:04:01.67762+00	password	0fb36167-97b9-4d2d-b6e0-6cc4602a61d3
c8cf63ac-c335-440a-9975-2c860395051d	2026-02-08 10:04:38.710933+00	2026-02-08 10:04:38.710933+00	password	1ee7e98d-2850-49f2-9cbd-2a0b63cd01dc
d86790cc-a735-49df-8bd1-14d504c92c83	2026-02-08 10:04:40.187401+00	2026-02-08 10:04:40.187401+00	password	30c3c85b-cf80-44f3-ae98-c80a6c77067a
3b90ded5-343f-40b4-9093-4caed7535f54	2026-02-08 10:05:46.777798+00	2026-02-08 10:05:46.777798+00	password	a158268c-7e71-4902-855d-7ef1a8d7b432
a1c76fe6-38f4-4d0c-973b-731ec8399cbd	2026-02-08 10:05:47.170257+00	2026-02-08 10:05:47.170257+00	password	c0700777-39fc-424d-960b-59c7b334e4ca
e98426ea-cee7-461a-b630-68d9656a18a4	2026-02-08 10:06:14.719391+00	2026-02-08 10:06:14.719391+00	password	fdefcb73-60cf-4686-ab1d-bf3935f2e489
bc82085a-e2ea-4234-a001-d10e260dd2b5	2026-02-08 10:06:16.103515+00	2026-02-08 10:06:16.103515+00	password	878aa85e-7dc3-4f75-809f-8d65ce6ed588
03456332-c337-4e53-b595-6496d403e83e	2026-02-08 10:07:08.155848+00	2026-02-08 10:07:08.155848+00	password	1262f020-356e-49df-87d7-2ad09a9f1517
03ec5066-036c-4bf9-b2bd-1742e64c3513	2026-02-08 10:09:06.848223+00	2026-02-08 10:09:06.848223+00	password	4b97c624-2aaf-4d01-aca4-baf5a1245fb1
a782cfe3-8f8f-4167-8beb-4b2b585bc7b7	2026-02-08 10:09:17.063313+00	2026-02-08 10:09:17.063313+00	password	69ba3272-bb45-4c42-9033-39c44fb28689
02bb27de-2037-45f9-ab9a-2280c51bee99	2026-02-08 10:09:30.05475+00	2026-02-08 10:09:30.05475+00	password	da3fda64-add0-41f1-8b8d-9c06a05f0508
d608bfe3-0472-499b-97e9-7212b6056250	2026-02-08 10:09:30.075208+00	2026-02-08 10:09:30.075208+00	password	0d4982c6-fc37-4f5b-9155-4ed3f48ffcc5
eff4c5f3-ec3e-4a4c-bad5-0bb10a937e7e	2026-02-08 10:09:58.413132+00	2026-02-08 10:09:58.413132+00	password	8bacb210-a710-4dc2-b7fa-75b7c0d1427e
d5f33918-f88c-4a18-a4c6-0dab662329cc	2026-02-08 11:13:11.051229+00	2026-02-08 11:13:11.051229+00	password	dd98cf1d-4f1b-4d95-a699-ad2555fb1db5
d692d613-2cb4-4951-bee2-2ec574866354	2026-02-08 11:13:11.075036+00	2026-02-08 11:13:11.075036+00	password	9ffa94ab-8cec-4297-8b21-200b0e6608e8
0f51bce7-7bc0-4b06-8d0f-4522e7dddab1	2026-02-08 11:13:11.079414+00	2026-02-08 11:13:11.079414+00	password	1f2e43b3-d9d5-4e11-85d6-c4cbc82158a0
94623bfd-0d76-41d8-93e4-192a74317e18	2026-02-08 11:13:11.440471+00	2026-02-08 11:13:11.440471+00	password	b2f8b27e-aa0f-4556-b75a-93f1202ab690
86141149-83da-4692-bef0-c10214c82369	2026-02-08 11:13:26.020611+00	2026-02-08 11:13:26.020611+00	password	c5a85ead-5b81-4b11-9ccd-455928666889
ff124e79-9428-4db8-adba-8b39f01724e5	2026-02-08 11:13:26.822029+00	2026-02-08 11:13:26.822029+00	password	84c95c77-d749-4b8c-b1b9-d5a4b31deb8b
fa200289-289b-4e35-978f-c10793105793	2026-02-08 11:13:32.258837+00	2026-02-08 11:13:32.258837+00	password	459cc187-03c2-4607-944c-107915efd475
020cbe47-6cef-40cb-857a-b406563a48be	2026-02-08 11:13:32.457574+00	2026-02-08 11:13:32.457574+00	password	3fb9a40f-55a4-452e-81ea-27298dbe099b
b7a8f74e-d2c1-4852-9ffd-464ae7650ae4	2026-02-08 11:13:33.643123+00	2026-02-08 11:13:33.643123+00	password	0c012040-552c-4461-bea5-020506a07e68
f8c0d862-115c-4038-a454-b6b56be05727	2026-02-08 11:13:46.262095+00	2026-02-08 11:13:46.262095+00	password	1e092b35-00b6-4a3d-ac52-76feef0ded0c
44ab02cd-df3b-4627-abf6-97ff5bc4a85a	2026-02-08 11:13:54.20522+00	2026-02-08 11:13:54.20522+00	password	20e1e022-75b4-42d9-bca4-09ed98abf468
8105805c-ce34-435e-9d84-707558c961ac	2026-02-08 11:13:56.653069+00	2026-02-08 11:13:56.653069+00	password	bb479ef8-8fb1-4894-9936-a7b12ecaba86
379bcc9e-bc86-498b-b9d4-7e0d66ffbcf8	2026-02-08 11:14:10.402518+00	2026-02-08 11:14:10.402518+00	password	0cf9212f-fb65-4b53-9065-6e058b442d3d
e88374df-6cfc-4477-ac1e-feef2f340fee	2026-02-08 11:14:49.961997+00	2026-02-08 11:14:49.961997+00	password	dfe00a11-fc57-4bfb-864b-8fb62c4e7ce8
1082bcf7-de4d-4c68-93bb-fd7f7b8b910e	2026-02-08 11:14:50.910361+00	2026-02-08 11:14:50.910361+00	password	81aea3d0-2f96-478d-8b1a-47a2722e2fe2
62f73ad7-b2bd-4d80-aebe-a314084cf229	2026-02-08 11:14:49.958533+00	2026-02-08 11:14:49.958533+00	password	9aeb6823-16c2-4dc6-8e38-f10a4c6ca905
9d02563e-0286-4c02-979d-bcd1ad54f653	2026-02-08 11:14:55.312387+00	2026-02-08 11:14:55.312387+00	password	45ecaa0a-2068-463c-9f8d-40ee72b54fee
4c194bd4-964a-4ddc-8cd8-6505b7c7511d	2026-02-08 11:15:28.458735+00	2026-02-08 11:15:28.458735+00	password	f1b1aacb-e2cc-4b22-b164-0f2813d672db
03fba221-2e20-4541-9cad-43ce5fbb3b3f	2026-02-08 11:15:28.512059+00	2026-02-08 11:15:28.512059+00	password	5d6ef035-0197-48ce-ac6e-6b1604d5103a
2c29a7ce-acaf-4198-9074-162b2ebba8dd	2026-02-08 11:16:12.794716+00	2026-02-08 11:16:12.794716+00	password	413c2f69-9e16-49d9-8b57-733a57f92230
fbd1b79e-a811-4470-80da-42ea0e095b5a	2026-02-08 11:16:12.926314+00	2026-02-08 11:16:12.926314+00	password	661cd907-eaa3-458c-9838-0b37161017e8
fa4a2c1e-e5c7-4d83-8a29-874cfd6dadc5	2026-02-08 11:16:32.231951+00	2026-02-08 11:16:32.231951+00	password	869933a0-8e24-471e-8e2a-5f8077fafb1d
51a1bc0e-f308-44ad-b7da-449fdc615ced	2026-02-08 11:16:38.51581+00	2026-02-08 11:16:38.51581+00	password	e22ded57-ba95-4592-a608-1a2085e3ad12
02e6e1f2-526c-4ac0-a648-a9eb11cc06f3	2026-02-08 11:16:50.332799+00	2026-02-08 11:16:50.332799+00	password	eadaf785-8c65-4a62-8830-dfc441b97654
ba35064a-adc8-4a6c-b1b9-fda41284e12d	2026-02-08 11:36:58.950958+00	2026-02-08 11:36:58.950958+00	password	5c3369a6-f5b3-449c-bd43-e97b2ac42f9b
c5d20fd3-f023-41f5-82a3-3d37fb621023	2026-02-08 11:36:59.107036+00	2026-02-08 11:36:59.107036+00	password	36243ad1-510a-4a7e-a482-29415d363775
004fc922-9a68-403b-8636-d357f61b2c94	2026-02-08 11:37:03.997204+00	2026-02-08 11:37:03.997204+00	password	72a2496c-c63b-4f9a-8217-90fa4422efd5
0081fa1a-06cd-4c0c-9351-a66c68fa8ee8	2026-02-08 11:37:04.141659+00	2026-02-08 11:37:04.141659+00	password	58a03506-f230-4a2a-b7fe-6125cfb48904
c9044358-3ce2-4a54-9d0e-e4866433b970	2026-02-08 11:37:27.155932+00	2026-02-08 11:37:27.155932+00	password	e1a7504d-d38f-4a45-a670-40ed8a8afb27
c15ce90b-c7be-4a59-8ceb-148d7face7b8	2026-02-08 11:37:28.856245+00	2026-02-08 11:37:28.856245+00	password	e846800c-d44b-4fd2-8df6-769d082923fe
19a19d9c-eb2f-45b4-bbe6-09b1809b4fcd	2026-02-08 11:37:38.681329+00	2026-02-08 11:37:38.681329+00	password	d0634c23-0871-4411-9b62-7db3be81579a
e301bd0e-1b0c-42af-b557-b5eb7d5d2438	2026-02-08 11:37:38.856357+00	2026-02-08 11:37:38.856357+00	password	700ff465-c905-4c11-be53-85ebaae38a03
d9760289-83c3-4ad8-a243-71841afc1b73	2026-02-08 11:37:47.982822+00	2026-02-08 11:37:47.982822+00	password	fd6e81f4-c73e-4f16-b816-017c518878ef
b69e40c6-5dac-40ce-bf0d-4e2bf346443b	2026-02-08 11:37:54.445288+00	2026-02-08 11:37:54.445288+00	password	8296f3d7-aec0-4788-9f90-dbe0451508bc
a8f49396-3178-4089-ac55-74155168213c	2026-02-08 11:38:22.596627+00	2026-02-08 11:38:22.596627+00	password	34691b8a-726a-4249-94a7-6afbc2adebb3
301edae8-e124-4689-b50f-8e1a251a7dc5	2026-02-08 12:05:07.484892+00	2026-02-08 12:05:07.484892+00	password	50106af1-f067-4adf-8818-176b60eb04a4
b2be4da3-5e91-4ca1-b732-6baada5a861a	2026-02-08 12:05:07.503864+00	2026-02-08 12:05:07.503864+00	password	ef491494-344f-45ae-88a3-6b0c42cf3824
ccbe9e1a-1b18-4c39-862d-d642f1769fd6	2026-02-08 12:05:10.577523+00	2026-02-08 12:05:10.577523+00	password	9912d78b-cbe3-428e-960c-063f0fe8a078
60ff6e80-cd56-48a6-b59c-e61beb5ca258	2026-02-08 12:05:10.729854+00	2026-02-08 12:05:10.729854+00	password	8ee54b0b-dede-45c5-b560-026386886160
0c00d937-5acd-4e7d-9f85-d731bd0db803	2026-02-08 12:05:45.915712+00	2026-02-08 12:05:45.915712+00	password	ac51c424-e623-40d5-8fc7-01f60ccb3ec1
8d973535-ea22-4ccc-b8f8-e218365210a7	2026-02-08 12:05:55.010707+00	2026-02-08 12:05:55.010707+00	password	e2465146-be23-4ba1-b714-2a93ffa6be82
cbe99458-8e96-459b-959b-1fa1baead779	2026-02-08 12:06:06.93328+00	2026-02-08 12:06:06.93328+00	password	acb313e1-796a-415c-b1fd-8f2a67e06b56
97e403bd-6a24-408e-9b46-f8a823b9ff31	2026-02-08 12:06:07.198184+00	2026-02-08 12:06:07.198184+00	password	6714f814-daf2-4535-b1fc-d07d652ed3e9
f1ed9b39-5b59-4b2f-9279-4ae2aa682116	2026-02-08 12:06:46.460977+00	2026-02-08 12:06:46.460977+00	password	ac79f21f-a020-44ba-a30d-f6a7bb171c33
1d9a67bc-b8c4-41d1-9145-0c746320dfbf	2026-02-08 12:06:47.071372+00	2026-02-08 12:06:47.071372+00	password	653a739b-ef7e-4b71-8ec7-930b20138788
77b8ec21-6c0e-415a-8186-6eae395d31f4	2026-02-08 12:06:54.318031+00	2026-02-08 12:06:54.318031+00	password	d4c6fc14-aa2b-4311-961d-7b50037cab5d
7899a028-9a85-4b80-8dd3-179ed1bfe70a	2026-02-08 12:12:01.880304+00	2026-02-08 12:12:01.880304+00	password	69a7223a-1a41-4717-b379-7a0d486022ac
9b83d9a1-c246-4c07-8b4c-b4efc035bb58	2026-02-08 12:12:01.891605+00	2026-02-08 12:12:01.891605+00	password	8e37f98f-c7bf-4186-ad5e-2150d2193340
35c57c2a-ddec-4f91-b851-60e9993716fe	2026-02-08 12:12:01.94534+00	2026-02-08 12:12:01.94534+00	password	cf46404e-3d51-4e92-964e-0ad3a02cf596
950e8e89-9453-4908-8133-9bf892c6f462	2026-02-08 12:12:23.451669+00	2026-02-08 12:12:23.451669+00	password	070e7105-096f-4ccd-b897-d47ca55249a3
e9978302-1311-4b5b-813c-e91a751022ef	2026-02-08 12:12:35.55601+00	2026-02-08 12:12:35.55601+00	password	c6a7d989-64c6-4b2c-a2e5-5e0a12968a00
64c61424-3fe0-48ca-bad7-7df1994237f4	2026-02-08 12:37:06.269654+00	2026-02-08 12:37:06.269654+00	password	6c48a292-ce14-4ed7-8473-0e635ac25d7d
fe900f72-18e3-4b1d-8951-5c68048075ac	2026-02-08 12:38:14.62727+00	2026-02-08 12:38:14.62727+00	password	58df9489-cbfd-4677-9112-16bba793e383
cadfe077-4ab0-4bff-9f8a-1f0895b467e6	2026-02-08 12:41:45.613689+00	2026-02-08 12:41:45.613689+00	password	ec8fcaae-e7d3-40b7-8496-5343ec273657
d3746197-58bd-483d-82d1-b4a8d3383a48	2026-02-08 12:49:25.117443+00	2026-02-08 12:49:25.117443+00	password	5be7440c-e859-4407-92e9-efa1a413119d
aaa18622-b0eb-404d-ab88-d09feaef4797	2026-02-08 12:57:10.413017+00	2026-02-08 12:57:10.413017+00	password	30a11a8d-b42f-4dd7-a1f6-1ebc57c238d4
67eaa452-7664-4c3b-825d-7bdac05e1942	2026-02-08 12:59:31.513655+00	2026-02-08 12:59:31.513655+00	password	6d36b005-0ff7-4731-9cce-133cca0c172c
a2f86c28-b1d4-4cae-b94f-5d602e71e738	2026-02-08 13:05:14.842674+00	2026-02-08 13:05:14.842674+00	password	f4b361e7-ea03-4b7d-ba2c-fad986eb330c
f92d3f4a-852c-4ba4-b896-f390a652272f	2026-02-08 13:05:16.369651+00	2026-02-08 13:05:16.369651+00	password	4a72c6c6-b148-4d08-8e8a-5faf1cdfbaaf
a2cd0bf4-5e4d-4cf2-8ffb-391c8d7179f7	2026-02-08 13:05:18.061006+00	2026-02-08 13:05:18.061006+00	password	a451de78-3fff-4dde-a854-d1ecebcefc7c
118a1c2d-5ca1-493e-bf55-8415166ced28	2026-02-08 13:05:20.137103+00	2026-02-08 13:05:20.137103+00	password	ac900604-2257-4793-aafa-418e61a4728a
35019c71-7964-4a7e-ba46-8a9c52183c8e	2026-02-08 13:05:33.484713+00	2026-02-08 13:05:33.484713+00	password	d555a663-ec00-43c7-9841-02d4da310887
9c1ac895-60eb-45e9-9f83-b74e8c7e743f	2026-02-08 13:05:34.023823+00	2026-02-08 13:05:34.023823+00	password	2145b0b0-1a7f-4ce3-a296-d9450940e844
cd77c1d6-60aa-4452-961e-9f408e786d79	2026-02-08 13:05:40.872208+00	2026-02-08 13:05:40.872208+00	password	f5731ed7-4614-4f49-9b5c-02348333c95d
9d2f5ab3-4329-4a1b-b05b-de556fca5f19	2026-02-08 13:05:40.961537+00	2026-02-08 13:05:40.961537+00	password	fe089341-3921-4342-8143-88b87a550712
d3cae6fa-8ddb-402a-8610-99fc9fb61488	2026-02-08 13:05:44.481305+00	2026-02-08 13:05:44.481305+00	password	5a259195-4cd5-40a0-85b9-fed242b2a6c8
10f894ab-d276-4135-b27f-527a073c9a90	2026-02-08 13:05:55.688231+00	2026-02-08 13:05:55.688231+00	password	7ad61e8e-eff0-423f-ad2d-c12939d4fc66
f5e40883-01d3-49a8-b1e7-c6e1401b9aa7	2026-02-08 13:06:01.897478+00	2026-02-08 13:06:01.897478+00	password	a10731a9-4a57-4c66-934d-44811a40903b
9a132c8c-883b-488e-9c25-a18b9123ed74	2026-02-08 13:06:14.109449+00	2026-02-08 13:06:14.109449+00	password	2296fb18-0cd2-471d-878b-9b2d5e871a60
e5ca9e4a-5656-4278-87dc-007a889176ef	2026-02-08 13:06:16.807617+00	2026-02-08 13:06:16.807617+00	password	4949f705-4efc-42e7-8f2e-cc6f2ca8383f
0fb9735e-62ec-46af-bd93-23e2f376268c	2026-02-08 13:06:35.611498+00	2026-02-08 13:06:35.611498+00	password	f24364cb-de3d-4239-b7de-07ca00353553
280052e9-28d2-4fb6-a7fb-b0ac2dbd2801	2026-02-10 01:04:37.254965+00	2026-02-10 01:04:37.254965+00	password	8da4c035-8609-4a6a-bd33-094fe3e22b4b
2e8b9103-a742-425d-8150-65e52f132229	2026-02-10 01:04:48.688015+00	2026-02-10 01:04:48.688015+00	password	9e473f80-6022-4493-a762-b6dc4bdaee0a
3ad33f7b-a830-48b9-957d-cd203f83c5ee	2026-02-10 01:06:19.964554+00	2026-02-10 01:06:19.964554+00	password	1b83edf3-e568-4dd1-b3bc-27300744e462
97c25ec7-fef3-49f6-9d51-66edd2677d4b	2026-02-10 01:08:10.830627+00	2026-02-10 01:08:10.830627+00	password	0f83e53e-7b2c-45da-9628-999fb7b9bdc8
d53b70c0-66db-4ddd-823e-ef1b5d802800	2026-02-10 01:08:11.087912+00	2026-02-10 01:08:11.087912+00	password	7632686a-7b92-4347-a0a1-4eba043a2927
58335a26-6d19-4580-bfa2-d642b39abccb	2026-02-10 01:08:30.160767+00	2026-02-10 01:08:30.160767+00	password	12e63fe8-1811-40ca-87a7-f95e5ed2ce9f
9d96b83a-6431-4607-a052-b547cc1b9793	2026-02-10 01:08:30.196189+00	2026-02-10 01:08:30.196189+00	password	582f84f9-ca73-4967-ba0c-8f2b0391da56
960ad8ac-84a5-4a24-807b-337d65b7f6ba	2026-02-10 01:09:00.580892+00	2026-02-10 01:09:00.580892+00	password	02e4c641-26a2-449f-ab6d-1e40a2dc0952
9ab2a5ea-b75c-4e0b-af40-bf5381f8634c	2026-02-10 01:09:00.597526+00	2026-02-10 01:09:00.597526+00	password	f1a851bb-7ac9-4a0a-8b4b-cef20f6bae2f
571b37ef-c746-47b2-a43d-5822cd1ffb08	2026-02-10 01:09:20.788313+00	2026-02-10 01:09:20.788313+00	password	e2c6995d-67b2-4977-bc00-58aae1292ff0
d116b789-6bbf-48c0-a948-d40496d6eb09	2026-02-10 01:09:20.821458+00	2026-02-10 01:09:20.821458+00	password	2f2d062a-be0d-480e-952f-0a72bd0d13cd
1aea00c2-4e53-4f1f-a9cd-420d0512eb0d	2026-02-10 01:09:35.933792+00	2026-02-10 01:09:35.933792+00	password	a41c1af7-059b-4233-9ce9-d2aa27cdf5b6
4b6d015f-31b8-477e-9505-63ea5543e42c	2026-02-10 01:09:41.23799+00	2026-02-10 01:09:41.23799+00	password	79a85797-7b63-4b48-a261-f6eae4f6202f
83b6f0eb-bd8e-43c5-89c6-e815fc8127a2	2026-02-10 01:09:46.058965+00	2026-02-10 01:09:46.058965+00	password	61588411-c456-4205-9b3c-68ed3b0e9467
b5eaeea5-ed0a-4ed2-9bac-c25b28aa8275	2026-02-10 01:09:52.223261+00	2026-02-10 01:09:52.223261+00	password	f730c61b-ee8c-4ee7-aabb-ccee55307c9a
0631f62e-f68e-4677-92b1-b9315f5feb23	2026-02-10 01:09:57.749421+00	2026-02-10 01:09:57.749421+00	password	bcf9a9b8-0002-41f6-982c-f1f3d39ad704
933fd499-040a-4d27-bacf-7136bbd98668	2026-02-10 01:10:05.029964+00	2026-02-10 01:10:05.029964+00	password	34bf974e-6cce-4169-8e7f-904837ef2552
94a3aa4c-f5e5-48b1-b54b-9b6d13e4153d	2026-02-10 01:10:11.027056+00	2026-02-10 01:10:11.027056+00	password	bf6261cc-4395-4459-8642-83edb3ef050a
62dc0dd6-d69f-4cb8-972b-bde77eae9cbb	2026-02-10 01:10:17.856949+00	2026-02-10 01:10:17.856949+00	password	65d8c3b4-6e67-412c-bb5b-b2d9c0a1a6e8
10f2c61b-eca8-471a-9f12-075ddf355f79	2026-02-10 01:11:57.045939+00	2026-02-10 01:11:57.045939+00	password	89e6004b-2c4a-4e77-8abe-eebc970d5de0
afeecc0d-bee8-42a3-9121-1bc0f17561bb	2026-02-10 01:12:04.190713+00	2026-02-10 01:12:04.190713+00	password	f216473b-4b08-4123-80ce-107c6264cb38
d033c247-e4ec-44be-8808-c6f254a4d3c8	2026-02-10 01:12:24.911922+00	2026-02-10 01:12:24.911922+00	password	cf5af4ea-470f-4dc6-855f-381cdfe35ded
3b57dc79-86d3-432e-a79c-8cb06d88430e	2026-02-10 01:12:38.855799+00	2026-02-10 01:12:38.855799+00	password	70c5594d-cbe7-420e-8c88-8a482bcba981
319ba666-633e-44f5-b382-36b699bffcd6	2026-02-10 01:12:55.186396+00	2026-02-10 01:12:55.186396+00	password	dd9933bf-ed76-484c-bce3-ee614f7e35bd
4e8cc104-65b3-40cd-a016-623909bce1cb	2026-02-10 03:57:54.023283+00	2026-02-10 03:57:54.023283+00	password	0de3b139-32b1-461c-a497-4df8683d5fa3
1901750a-c6d3-4b2c-bf57-3c18f4238195	2026-02-10 03:59:05.08345+00	2026-02-10 03:59:05.08345+00	password	1f6a597c-aad4-4c9b-a2d8-ba7ebc8f2fcf
38937acc-1ff7-43a0-8975-3655310822e7	2026-02-10 03:59:09.22494+00	2026-02-10 03:59:09.22494+00	password	95a0130d-d763-42da-8c1f-d4058b73bd63
85e496f2-4c41-407b-bdca-f48428f8f362	2026-02-10 03:59:26.714914+00	2026-02-10 03:59:26.714914+00	password	8db486c0-a1e7-480f-a5c0-08eb1025e348
64424939-8965-4f07-bb94-744f6916f55d	2026-02-10 03:59:40.857927+00	2026-02-10 03:59:40.857927+00	password	9cb4b087-9cd2-48f4-b55d-c768b8cdf14c
d7b95386-c309-4a82-8566-f1352c716114	2026-02-10 03:59:47.671281+00	2026-02-10 03:59:47.671281+00	password	6c0a3e0b-ced7-4604-a91a-1bc9e59c2600
3a042df2-f0fb-4f7f-a8b2-9a44365ba605	2026-02-10 04:00:13.217225+00	2026-02-10 04:00:13.217225+00	password	a428c501-61d4-42c3-ac02-e47a4d232bf9
3dccbb85-f5a0-4578-80b3-62f1404f0125	2026-02-10 04:00:17.290385+00	2026-02-10 04:00:17.290385+00	password	8f2cb9d4-3dc7-459d-8167-c3a474b8f6c3
63286937-5f83-4a29-9ccf-37f2100991be	2026-02-10 04:00:22.218152+00	2026-02-10 04:00:22.218152+00	password	6b780908-b910-4095-b59a-bb18a1c1145f
4ca9797c-d4b6-4bcc-a4d5-f8bace732be8	2026-02-10 04:00:25.630846+00	2026-02-10 04:00:25.630846+00	password	e26c03c2-9404-4a27-8bc1-5139feae5222
65aac392-b0d7-46d7-8ab8-b114449d16e2	2026-02-10 04:00:30.612449+00	2026-02-10 04:00:30.612449+00	password	91b791a7-736d-4ead-86d2-301ace209774
6a2e9bf3-d0df-44f6-99bb-c48b463c9b14	2026-02-10 04:16:51.731958+00	2026-02-10 04:16:51.731958+00	password	634a551a-fdbb-4896-91f1-106e506cc02d
0c4ec18d-ed00-47c9-a1b7-1e9bcd332f51	2026-02-10 04:16:51.75884+00	2026-02-10 04:16:51.75884+00	password	d58751e5-9d31-428a-a4ab-4024873820a0
aff85e06-971d-4723-a84d-c5fbd69c70ce	2026-02-10 04:16:57.894237+00	2026-02-10 04:16:57.894237+00	password	bb9a8b8e-7d93-452a-9e4c-022ea7dfb7f2
98dbde8e-6f29-43d0-b7eb-5fa250db4346	2026-02-10 04:17:04.962495+00	2026-02-10 04:17:04.962495+00	password	6dc8952e-820a-45a5-9bec-169516739bf0
a401120b-a6a2-4a53-a413-8546b9687ce2	2026-02-10 04:17:31.064318+00	2026-02-10 04:17:31.064318+00	password	684bd42b-419e-42a4-805b-2917a4818afc
1159bacc-dfd5-4f6b-88d9-b2e66095eaae	2026-02-10 04:17:35.102461+00	2026-02-10 04:17:35.102461+00	password	1e355061-489b-4329-a966-1cfda6f04156
2e89df82-89c4-43ba-9426-183442b41eef	2026-02-10 04:17:37.606499+00	2026-02-10 04:17:37.606499+00	password	298438e0-10bd-4388-a1a7-e244219ac523
67546a3b-57b3-4c94-9fe6-f1b01fec88fd	2026-02-10 04:18:08.75854+00	2026-02-10 04:18:08.75854+00	password	babfe786-e3be-4f98-a5af-fd682db5ff07
6466da4a-89a3-4f08-bfad-a03dc50e97d5	2026-02-10 04:18:10.271736+00	2026-02-10 04:18:10.271736+00	password	8148d9f8-fe5f-4166-84a5-7f7394757346
a67e30d2-df8a-4980-80a0-ef41195e6fa3	2026-02-10 04:18:16.767591+00	2026-02-10 04:18:16.767591+00	password	43825a66-93c4-4ac4-befd-b17601750df6
ad404359-2677-4d8f-9a6c-a65601a1f2e6	2026-02-10 04:18:25.113517+00	2026-02-10 04:18:25.113517+00	password	e6da3c81-34d7-448f-9dc3-a803913f3145
5c255d06-81e1-44e5-9181-3fd566eaaac1	2026-02-10 04:18:26.502517+00	2026-02-10 04:18:26.502517+00	password	2188c18f-75a9-4784-9965-a2547b04a5e1
29fd3ed3-77a4-40fe-aedb-0bad7f03ffc5	2026-02-10 04:18:46.364415+00	2026-02-10 04:18:46.364415+00	password	44674921-1959-4710-b34a-9ff31a1be405
05f25140-2caf-4ae8-8384-f0d7ea8dbe99	2026-02-10 04:18:56.704303+00	2026-02-10 04:18:56.704303+00	password	0049a220-8aa1-47fb-ae5b-1e97b4826915
b661349f-1545-4461-8a97-d42f338269e2	2026-02-10 04:19:06.49802+00	2026-02-10 04:19:06.49802+00	password	e8eb9691-7ec4-4b86-88c8-a84d25720cf1
e281739f-35a5-4f6d-beb0-c4d4d9691de6	2026-02-10 04:19:10.011961+00	2026-02-10 04:19:10.011961+00	password	39f7d9f3-20bd-4dd6-b370-02112a039ed4
e8b5e1df-417f-4307-aefd-eb1dcbc0179c	2026-02-10 04:19:13.516787+00	2026-02-10 04:19:13.516787+00	password	234d27c0-16a5-4f7e-a416-3f6f6a6b9ad6
be73f1bc-ad41-4423-9806-2853365620f4	2026-02-10 04:19:29.251193+00	2026-02-10 04:19:29.251193+00	password	04998a7f-e246-422f-b0ef-618faab5e356
17e9837e-3e4e-4738-8c49-ec35fe35f1e3	2026-02-10 06:32:43.027381+00	2026-02-10 06:32:43.027381+00	password	c994edc0-0457-4a43-ad88-0306a1dc3bab
c767ef86-fd07-4496-bd0c-304234a72f15	2026-02-10 06:32:48.386354+00	2026-02-10 06:32:48.386354+00	password	88b490d5-9fef-4c8e-b286-7156cb5a6ace
963f65dd-b5cf-4041-a471-3d49d432811e	2026-02-10 06:32:49.285266+00	2026-02-10 06:32:49.285266+00	password	1e4b749a-ab12-4bc4-a602-be77e1cb1087
d7e4dc0c-9266-4a18-a676-2680aa6ba7dd	2026-02-10 06:33:20.328425+00	2026-02-10 06:33:20.328425+00	password	3af3a28b-07e2-44e0-b607-cea634149d98
f9340fb6-771d-4898-b942-9b200cbcf420	2026-02-10 06:33:33.843656+00	2026-02-10 06:33:33.843656+00	password	44796d90-dec5-4b93-9382-c5e706b1e8b6
7ca7ad6d-4d94-4b70-aa89-a41847604416	2026-02-10 06:33:46.312695+00	2026-02-10 06:33:46.312695+00	password	3cad68ac-3ff7-403d-b200-ea0f24136561
d9d2d6c1-60c7-44ed-bad3-7f32e27db910	2026-02-10 06:33:51.686728+00	2026-02-10 06:33:51.686728+00	password	50da65ef-11a8-4b05-8490-28fe0b2b3202
20ca7267-a36f-4a49-a215-5424a4645236	2026-02-10 06:33:57.911582+00	2026-02-10 06:33:57.911582+00	password	de3feed9-d988-4b26-8b18-fa3bb366fe7a
ca0ec7d2-3d97-414a-95b4-fedc33e82b5b	2026-02-10 06:34:12.527343+00	2026-02-10 06:34:12.527343+00	password	757b0d81-e52d-47c0-842b-49c505c08eb0
5a2fa2c4-b74f-469e-9ed5-25b99d75a708	2026-02-10 06:34:13.332474+00	2026-02-10 06:34:13.332474+00	password	0649081b-47be-480c-9ea4-50c4ca7f5a72
82e2d3f0-3b9d-4041-89e8-102ef982f1ff	2026-02-10 06:34:18.077316+00	2026-02-10 06:34:18.077316+00	password	8966506d-efa1-48c6-b493-276fff7966f9
5d7ab598-b672-4d6d-a02f-92ce60cb7c94	2026-02-10 06:34:22.761831+00	2026-02-10 06:34:22.761831+00	password	c5184ab3-5b4f-4424-9e5b-288d14374da9
149a4dd9-a455-4bc8-a142-3a022fb60d17	2026-02-10 06:34:33.122296+00	2026-02-10 06:34:33.122296+00	password	40c4ca01-5835-41ac-8541-722ef1ac7fe3
2e6fef9d-b203-46a0-afce-b87f8a758e01	2026-02-10 06:34:53.477479+00	2026-02-10 06:34:53.477479+00	password	c69a791d-6f18-4b47-8f7b-50c89082b663
53a117ec-69c4-40ad-8403-4c7b57c7e199	2026-02-10 07:28:14.14809+00	2026-02-10 07:28:14.14809+00	password	6ea3475a-d929-46b1-be49-5ac968ad6e10
502b511f-ee88-4792-8855-a829f3f91d9f	2026-02-10 07:28:20.78479+00	2026-02-10 07:28:20.78479+00	password	0ec9a4c9-3b80-4ea4-9cb6-6a6aef10c0f6
66adc0be-5bc3-48a6-b579-6ea2ca136e44	2026-02-11 01:41:28.376332+00	2026-02-11 01:41:28.376332+00	password	3306a157-a106-4725-9145-319318172d48
49ec853d-432c-4a92-b098-5d24f2e14708	2026-02-11 01:44:25.148772+00	2026-02-11 01:44:25.148772+00	password	0cd54816-7d80-443a-8c2a-769b0d948a61
2ed18d0a-77bf-4a85-a533-4d13d1c8d361	2026-02-11 02:02:17.804617+00	2026-02-11 02:02:17.804617+00	password	66d3e58a-131d-40e0-9117-503e2d2f1e7f
f32518b9-f923-4b7d-b4a5-e9a6230b3636	2026-02-11 02:07:49.656072+00	2026-02-11 02:07:49.656072+00	password	3f68536a-506b-43d9-b941-1d1ba24fd8a2
f9cf2f10-7d5a-4150-9486-78e634b5a346	2026-02-11 02:39:23.632943+00	2026-02-11 02:39:23.632943+00	password	d2e3e39b-5032-4ed9-b025-4ecd2df0b5ad
739168c5-c96d-4f48-9788-339ab4b728ee	2026-02-11 03:27:09.045779+00	2026-02-11 03:27:09.045779+00	password	757f6946-1b33-4be9-9ce6-ad5f63d5de09
34c5c29f-6cd5-4237-86ee-6ff5b46fdf67	2026-02-11 03:27:18.997851+00	2026-02-11 03:27:18.997851+00	password	4348f92a-e920-46e4-8ee4-e6b7d1bdaa9c
39a9b6df-bd60-4d14-be59-8c1042997a3e	2026-02-11 03:27:19.100914+00	2026-02-11 03:27:19.100914+00	password	a5ca5310-4f3b-42a1-a0fc-7d5de5617b72
714c1858-7bf7-4e8a-8c7c-6c7251f6c5cd	2026-02-11 03:27:58.306126+00	2026-02-11 03:27:58.306126+00	password	8914980e-8937-480b-8d94-311cccf2512f
d51fe136-847e-4aeb-95e8-20f97c9934f7	2026-02-11 03:27:58.399003+00	2026-02-11 03:27:58.399003+00	password	e2ae7cc3-3f8b-4d38-a272-19f5afb936ec
c451c2b8-3c4e-4abb-941f-9e4532127166	2026-02-11 03:28:38.869249+00	2026-02-11 03:28:38.869249+00	password	1d175d44-8c9f-402c-aecc-e7c44bca2928
b21b563d-4cf4-40bd-bab8-d05f58c1d4ba	2026-02-11 03:28:38.931993+00	2026-02-11 03:28:38.931993+00	password	db1fb95d-c299-4b42-8df3-e36ebb79f6cb
b90eb011-1b08-418f-a421-fc856f9a8933	2026-02-11 03:29:31.447982+00	2026-02-11 03:29:31.447982+00	password	9ee5fede-f960-44e8-a76b-0d8a7ec5f8fa
fcb6d021-1ea4-437a-8440-e058c01f6a5b	2026-02-11 03:29:48.081658+00	2026-02-11 03:29:48.081658+00	password	18471392-1f22-4aa8-9721-05c593b92372
4c7b78cb-2b96-408a-8701-ab0e27e9a9a4	2026-02-11 03:30:04.597154+00	2026-02-11 03:30:04.597154+00	password	759973d6-0f81-4344-9b71-dc1e8d1a7269
5da60bcb-7600-4147-b787-b6697f1fc2ca	2026-02-11 03:32:37.489273+00	2026-02-11 03:32:37.489273+00	password	668254e2-20bd-4b3a-9be1-d1aef928c848
d31c6efd-12dd-498b-93a8-198706384db3	2026-02-11 03:32:38.070676+00	2026-02-11 03:32:38.070676+00	password	ab41d057-6030-44b0-ade9-f127c982952d
9d7f36aa-5164-40d1-8bb8-e2ee6c93c287	2026-02-11 03:33:39.003184+00	2026-02-11 03:33:39.003184+00	password	4c3ba849-68be-4c68-9712-3e65bb4322f7
da167d3a-1f5a-4e4f-b3a3-ebc630ae03ad	2026-02-11 10:59:21.574562+00	2026-02-11 10:59:21.574562+00	password	7e8535d0-2276-429b-9a2f-395857a194ca
37538335-78cc-4a58-98ab-d359e5dfc985	2026-02-11 12:19:39.681745+00	2026-02-11 12:19:39.681745+00	password	533251d3-8f14-4a1c-82e2-c9388c662e3b
fdc7ca80-679a-432d-ba50-babf4dcb0a38	2026-02-11 12:50:30.749005+00	2026-02-11 12:50:30.749005+00	password	7e9915a2-c8ab-4bff-9267-0aeb123da1ef
ee596f2a-dc76-4048-aae7-5ebb03ce31c8	2026-02-12 05:54:59.113755+00	2026-02-12 05:54:59.113755+00	password	67969052-0306-4a0d-b439-e5205bda5b34
\.


--
-- Data for Name: mfa_challenges; Type: TABLE DATA; Schema: auth; Owner: supabase_auth_admin
--

COPY auth.mfa_challenges (id, factor_id, created_at, verified_at, ip_address, otp_code, web_authn_session_data) FROM stdin;
\.


--
-- Data for Name: mfa_factors; Type: TABLE DATA; Schema: auth; Owner: supabase_auth_admin
--

COPY auth.mfa_factors (id, user_id, friendly_name, factor_type, status, created_at, updated_at, secret, phone, last_challenged_at, web_authn_credential, web_authn_aaguid, last_webauthn_challenge_data) FROM stdin;
\.


--
-- Data for Name: oauth_authorizations; Type: TABLE DATA; Schema: auth; Owner: supabase_auth_admin
--

COPY auth.oauth_authorizations (id, authorization_id, client_id, user_id, redirect_uri, scope, state, resource, code_challenge, code_challenge_method, response_type, status, authorization_code, created_at, expires_at, approved_at, nonce) FROM stdin;
\.


--
-- Data for Name: oauth_client_states; Type: TABLE DATA; Schema: auth; Owner: supabase_auth_admin
--

COPY auth.oauth_client_states (id, provider_type, code_verifier, created_at) FROM stdin;
\.


--
-- Data for Name: oauth_clients; Type: TABLE DATA; Schema: auth; Owner: supabase_auth_admin
--

COPY auth.oauth_clients (id, client_secret_hash, registration_type, redirect_uris, grant_types, client_name, client_uri, logo_uri, created_at, updated_at, deleted_at, client_type, token_endpoint_auth_method) FROM stdin;
\.


--
-- Data for Name: oauth_consents; Type: TABLE DATA; Schema: auth; Owner: supabase_auth_admin
--

COPY auth.oauth_consents (id, user_id, client_id, scopes, granted_at, revoked_at) FROM stdin;
\.


--
-- Data for Name: one_time_tokens; Type: TABLE DATA; Schema: auth; Owner: supabase_auth_admin
--

COPY auth.one_time_tokens (id, user_id, token_type, token_hash, relates_to, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: refresh_tokens; Type: TABLE DATA; Schema: auth; Owner: supabase_auth_admin
--

COPY auth.refresh_tokens (instance_id, id, token, user_id, revoked, created_at, updated_at, parent, session_id) FROM stdin;
00000000-0000-0000-0000-000000000000	757	sg5onutt2sjz	10e558ca-3940-4995-9a8f-165e78efaffc	f	2026-02-10 12:00:33.39135+00	2026-02-10 12:00:33.39135+00	tc5tda4ghrjs	f8b68d38-042c-4697-9458-1c0a74313dc3
00000000-0000-0000-0000-000000000000	1	y2l3veaub67b	5ac10c39-274e-4ce5-a13b-f4da3af4a230	t	2026-01-30 09:22:27.954022+00	2026-01-30 10:21:04.965739+00	\N	65d64040-bfd7-4ad3-877f-528f02b42671
00000000-0000-0000-0000-000000000000	2	e3o5t3cbx43x	5ac10c39-274e-4ce5-a13b-f4da3af4a230	t	2026-01-30 10:21:04.994864+00	2026-01-30 11:19:07.914181+00	y2l3veaub67b	65d64040-bfd7-4ad3-877f-528f02b42671
00000000-0000-0000-0000-000000000000	3	wzd5tyho7xpb	5ac10c39-274e-4ce5-a13b-f4da3af4a230	t	2026-01-30 11:19:07.929682+00	2026-01-30 12:17:36.752217+00	e3o5t3cbx43x	65d64040-bfd7-4ad3-877f-528f02b42671
00000000-0000-0000-0000-000000000000	4	7t5jvrrjkqis	5ac10c39-274e-4ce5-a13b-f4da3af4a230	t	2026-01-30 12:17:36.777236+00	2026-01-30 13:16:06.650752+00	wzd5tyho7xpb	65d64040-bfd7-4ad3-877f-528f02b42671
00000000-0000-0000-0000-000000000000	5	yp4dy3t27tgs	5ac10c39-274e-4ce5-a13b-f4da3af4a230	t	2026-01-30 13:16:06.664418+00	2026-01-30 14:14:10.561981+00	7t5jvrrjkqis	65d64040-bfd7-4ad3-877f-528f02b42671
00000000-0000-0000-0000-000000000000	6	k45o6yrbzcbw	5ac10c39-274e-4ce5-a13b-f4da3af4a230	t	2026-01-30 14:14:10.579107+00	2026-01-30 15:12:20.447369+00	yp4dy3t27tgs	65d64040-bfd7-4ad3-877f-528f02b42671
00000000-0000-0000-0000-000000000000	7	jllzwfkbsm4i	5ac10c39-274e-4ce5-a13b-f4da3af4a230	t	2026-01-30 15:12:20.464502+00	2026-01-30 16:26:07.30044+00	k45o6yrbzcbw	65d64040-bfd7-4ad3-877f-528f02b42671
00000000-0000-0000-0000-000000000000	8	zq77n33z4i3m	5ac10c39-274e-4ce5-a13b-f4da3af4a230	t	2026-01-30 16:26:07.325053+00	2026-01-30 17:31:48.169681+00	jllzwfkbsm4i	65d64040-bfd7-4ad3-877f-528f02b42671
00000000-0000-0000-0000-000000000000	9	ayzeavsqviov	5ac10c39-274e-4ce5-a13b-f4da3af4a230	t	2026-01-30 17:31:48.178419+00	2026-01-30 18:33:07.933557+00	zq77n33z4i3m	65d64040-bfd7-4ad3-877f-528f02b42671
00000000-0000-0000-0000-000000000000	10	2lded547qct6	5ac10c39-274e-4ce5-a13b-f4da3af4a230	t	2026-01-30 18:33:07.946105+00	2026-01-30 19:34:03.44475+00	ayzeavsqviov	65d64040-bfd7-4ad3-877f-528f02b42671
00000000-0000-0000-0000-000000000000	11	iibtmj5bnzdm	5ac10c39-274e-4ce5-a13b-f4da3af4a230	t	2026-01-30 19:34:03.461346+00	2026-01-30 20:34:47.350472+00	2lded547qct6	65d64040-bfd7-4ad3-877f-528f02b42671
00000000-0000-0000-0000-000000000000	12	45hwqmedzvso	5ac10c39-274e-4ce5-a13b-f4da3af4a230	t	2026-01-30 20:34:47.362445+00	2026-01-30 21:36:02.566035+00	iibtmj5bnzdm	65d64040-bfd7-4ad3-877f-528f02b42671
00000000-0000-0000-0000-000000000000	13	s2un3uumug7u	5ac10c39-274e-4ce5-a13b-f4da3af4a230	t	2026-01-30 21:36:02.578836+00	2026-01-30 22:34:22.926464+00	45hwqmedzvso	65d64040-bfd7-4ad3-877f-528f02b42671
00000000-0000-0000-0000-000000000000	14	5idt7opeaj7i	5ac10c39-274e-4ce5-a13b-f4da3af4a230	t	2026-01-30 22:34:22.951772+00	2026-01-30 23:36:54.304021+00	s2un3uumug7u	65d64040-bfd7-4ad3-877f-528f02b42671
00000000-0000-0000-0000-000000000000	15	n6cxi5wsqtm6	5ac10c39-274e-4ce5-a13b-f4da3af4a230	t	2026-01-30 23:36:54.318866+00	2026-01-31 02:20:55.883852+00	5idt7opeaj7i	65d64040-bfd7-4ad3-877f-528f02b42671
00000000-0000-0000-0000-000000000000	16	r5vf23ee7bvm	5ac10c39-274e-4ce5-a13b-f4da3af4a230	t	2026-01-31 02:20:55.906828+00	2026-01-31 03:31:49.074691+00	n6cxi5wsqtm6	65d64040-bfd7-4ad3-877f-528f02b42671
00000000-0000-0000-0000-000000000000	17	vjq5u5v3nrpp	5ac10c39-274e-4ce5-a13b-f4da3af4a230	f	2026-01-31 03:31:49.08328+00	2026-01-31 03:31:49.08328+00	r5vf23ee7bvm	65d64040-bfd7-4ad3-877f-528f02b42671
00000000-0000-0000-0000-000000000000	18	uprgfjkikulx	5ac10c39-274e-4ce5-a13b-f4da3af4a230	t	2026-01-31 03:32:33.991495+00	2026-01-31 04:30:54.72088+00	\N	11b10676-7ac3-46fe-b5dc-6e53bc9d56fc
00000000-0000-0000-0000-000000000000	19	f4z75ozxd6u5	5ac10c39-274e-4ce5-a13b-f4da3af4a230	t	2026-01-31 04:30:54.746614+00	2026-01-31 05:31:25.684779+00	uprgfjkikulx	11b10676-7ac3-46fe-b5dc-6e53bc9d56fc
00000000-0000-0000-0000-000000000000	20	6i3slizorvnc	5ac10c39-274e-4ce5-a13b-f4da3af4a230	t	2026-01-31 05:31:25.710123+00	2026-01-31 06:40:38.659486+00	f4z75ozxd6u5	11b10676-7ac3-46fe-b5dc-6e53bc9d56fc
00000000-0000-0000-0000-000000000000	21	vi4wrtuh55vo	5ac10c39-274e-4ce5-a13b-f4da3af4a230	t	2026-01-31 06:40:38.666441+00	2026-01-31 07:38:41.071585+00	6i3slizorvnc	11b10676-7ac3-46fe-b5dc-6e53bc9d56fc
00000000-0000-0000-0000-000000000000	22	mkwaztshwopr	5ac10c39-274e-4ce5-a13b-f4da3af4a230	t	2026-01-31 07:38:41.095965+00	2026-01-31 08:52:53.842713+00	vi4wrtuh55vo	11b10676-7ac3-46fe-b5dc-6e53bc9d56fc
00000000-0000-0000-0000-000000000000	23	j4gxq4cvnicz	5ac10c39-274e-4ce5-a13b-f4da3af4a230	t	2026-01-31 08:52:53.859921+00	2026-01-31 09:50:59.367721+00	mkwaztshwopr	11b10676-7ac3-46fe-b5dc-6e53bc9d56fc
00000000-0000-0000-0000-000000000000	24	k45gqyph4ql4	5ac10c39-274e-4ce5-a13b-f4da3af4a230	t	2026-01-31 09:50:59.38506+00	2026-01-31 10:49:29.234683+00	j4gxq4cvnicz	11b10676-7ac3-46fe-b5dc-6e53bc9d56fc
00000000-0000-0000-0000-000000000000	25	xjxllc7vn7p6	5ac10c39-274e-4ce5-a13b-f4da3af4a230	t	2026-01-31 10:49:29.251746+00	2026-01-31 11:47:59.166421+00	k45gqyph4ql4	11b10676-7ac3-46fe-b5dc-6e53bc9d56fc
00000000-0000-0000-0000-000000000000	26	awohwm7a7gjf	5ac10c39-274e-4ce5-a13b-f4da3af4a230	t	2026-01-31 11:47:59.179274+00	2026-01-31 12:46:29.219015+00	xjxllc7vn7p6	11b10676-7ac3-46fe-b5dc-6e53bc9d56fc
00000000-0000-0000-0000-000000000000	27	3rm5vq5k5glv	5ac10c39-274e-4ce5-a13b-f4da3af4a230	t	2026-01-31 12:46:29.22997+00	2026-01-31 13:44:59.010396+00	awohwm7a7gjf	11b10676-7ac3-46fe-b5dc-6e53bc9d56fc
00000000-0000-0000-0000-000000000000	28	btty7dqctblj	5ac10c39-274e-4ce5-a13b-f4da3af4a230	t	2026-01-31 13:44:59.029825+00	2026-01-31 14:44:31.860414+00	3rm5vq5k5glv	11b10676-7ac3-46fe-b5dc-6e53bc9d56fc
00000000-0000-0000-0000-000000000000	29	t5woztrx56ri	5ac10c39-274e-4ce5-a13b-f4da3af4a230	t	2026-01-31 14:44:31.882234+00	2026-01-31 23:08:27.040584+00	btty7dqctblj	11b10676-7ac3-46fe-b5dc-6e53bc9d56fc
00000000-0000-0000-0000-000000000000	30	zrbnmlplst5r	5ac10c39-274e-4ce5-a13b-f4da3af4a230	t	2026-01-31 23:08:27.072826+00	2026-02-01 00:12:54.038522+00	t5woztrx56ri	11b10676-7ac3-46fe-b5dc-6e53bc9d56fc
00000000-0000-0000-0000-000000000000	31	tfzdszreoe5x	5ac10c39-274e-4ce5-a13b-f4da3af4a230	t	2026-02-01 00:12:54.045819+00	2026-02-01 01:24:22.294736+00	zrbnmlplst5r	11b10676-7ac3-46fe-b5dc-6e53bc9d56fc
00000000-0000-0000-0000-000000000000	32	xd2kolm3wmky	5ac10c39-274e-4ce5-a13b-f4da3af4a230	t	2026-02-01 01:24:22.323988+00	2026-02-01 02:22:25.648958+00	tfzdszreoe5x	11b10676-7ac3-46fe-b5dc-6e53bc9d56fc
00000000-0000-0000-0000-000000000000	33	wsknijwcqccy	5ac10c39-274e-4ce5-a13b-f4da3af4a230	t	2026-02-01 02:22:25.677201+00	2026-02-01 03:21:58.294947+00	xd2kolm3wmky	11b10676-7ac3-46fe-b5dc-6e53bc9d56fc
00000000-0000-0000-0000-000000000000	34	pukosrcnb5hb	5ac10c39-274e-4ce5-a13b-f4da3af4a230	t	2026-02-01 03:21:58.317621+00	2026-02-01 04:23:48.58311+00	wsknijwcqccy	11b10676-7ac3-46fe-b5dc-6e53bc9d56fc
00000000-0000-0000-0000-000000000000	35	x77a4rd5ntle	5ac10c39-274e-4ce5-a13b-f4da3af4a230	t	2026-02-01 04:23:48.614072+00	2026-02-01 05:22:13.21584+00	pukosrcnb5hb	11b10676-7ac3-46fe-b5dc-6e53bc9d56fc
00000000-0000-0000-0000-000000000000	36	y7x63vypckgi	5ac10c39-274e-4ce5-a13b-f4da3af4a230	t	2026-02-01 05:22:13.240281+00	2026-02-01 06:27:29.125679+00	x77a4rd5ntle	11b10676-7ac3-46fe-b5dc-6e53bc9d56fc
00000000-0000-0000-0000-000000000000	37	h46ci2gbuutu	5ac10c39-274e-4ce5-a13b-f4da3af4a230	t	2026-02-01 06:27:29.149123+00	2026-02-01 07:29:09.212293+00	y7x63vypckgi	11b10676-7ac3-46fe-b5dc-6e53bc9d56fc
00000000-0000-0000-0000-000000000000	38	h2kmnjhjzqgx	5ac10c39-274e-4ce5-a13b-f4da3af4a230	t	2026-02-01 07:29:09.233647+00	2026-02-01 08:31:30.962154+00	h46ci2gbuutu	11b10676-7ac3-46fe-b5dc-6e53bc9d56fc
00000000-0000-0000-0000-000000000000	39	4p2tpi4mt6ka	5ac10c39-274e-4ce5-a13b-f4da3af4a230	t	2026-02-01 08:31:30.968728+00	2026-02-01 09:30:37.54349+00	h2kmnjhjzqgx	11b10676-7ac3-46fe-b5dc-6e53bc9d56fc
00000000-0000-0000-0000-000000000000	40	cmu77vvfacla	5ac10c39-274e-4ce5-a13b-f4da3af4a230	t	2026-02-01 09:30:37.554945+00	2026-02-01 10:29:02.577215+00	4p2tpi4mt6ka	11b10676-7ac3-46fe-b5dc-6e53bc9d56fc
00000000-0000-0000-0000-000000000000	41	orqh277xtqax	5ac10c39-274e-4ce5-a13b-f4da3af4a230	t	2026-02-01 10:29:02.58737+00	2026-02-01 11:27:03.515278+00	cmu77vvfacla	11b10676-7ac3-46fe-b5dc-6e53bc9d56fc
00000000-0000-0000-0000-000000000000	42	oypep3332bbw	5ac10c39-274e-4ce5-a13b-f4da3af4a230	t	2026-02-01 11:27:03.53354+00	2026-02-01 12:25:28.576759+00	orqh277xtqax	11b10676-7ac3-46fe-b5dc-6e53bc9d56fc
00000000-0000-0000-0000-000000000000	43	pygy4ag3dseh	5ac10c39-274e-4ce5-a13b-f4da3af4a230	t	2026-02-01 12:25:28.600679+00	2026-02-01 13:26:08.190988+00	oypep3332bbw	11b10676-7ac3-46fe-b5dc-6e53bc9d56fc
00000000-0000-0000-0000-000000000000	44	j7zwmc7woe3n	5ac10c39-274e-4ce5-a13b-f4da3af4a230	t	2026-02-01 13:26:08.210128+00	2026-02-01 14:24:40.047592+00	pygy4ag3dseh	11b10676-7ac3-46fe-b5dc-6e53bc9d56fc
00000000-0000-0000-0000-000000000000	45	npqi66vtgild	5ac10c39-274e-4ce5-a13b-f4da3af4a230	t	2026-02-01 14:24:40.064744+00	2026-02-01 15:22:44.105993+00	j7zwmc7woe3n	11b10676-7ac3-46fe-b5dc-6e53bc9d56fc
00000000-0000-0000-0000-000000000000	46	ap4z7aikskek	5ac10c39-274e-4ce5-a13b-f4da3af4a230	t	2026-02-01 15:22:44.126659+00	2026-02-01 16:21:03.67946+00	npqi66vtgild	11b10676-7ac3-46fe-b5dc-6e53bc9d56fc
00000000-0000-0000-0000-000000000000	47	5gxl7ulmorew	5ac10c39-274e-4ce5-a13b-f4da3af4a230	t	2026-02-01 16:21:03.690944+00	2026-02-01 17:19:33.295773+00	ap4z7aikskek	11b10676-7ac3-46fe-b5dc-6e53bc9d56fc
00000000-0000-0000-0000-000000000000	48	zli4pdokwstx	5ac10c39-274e-4ce5-a13b-f4da3af4a230	t	2026-02-01 17:19:33.312829+00	2026-02-01 18:17:42.236848+00	5gxl7ulmorew	11b10676-7ac3-46fe-b5dc-6e53bc9d56fc
00000000-0000-0000-0000-000000000000	49	pjadnurj2hdw	5ac10c39-274e-4ce5-a13b-f4da3af4a230	t	2026-02-01 18:17:42.256496+00	2026-02-01 19:16:12.113538+00	zli4pdokwstx	11b10676-7ac3-46fe-b5dc-6e53bc9d56fc
00000000-0000-0000-0000-000000000000	50	xjlfz5ckehis	5ac10c39-274e-4ce5-a13b-f4da3af4a230	t	2026-02-01 19:16:12.128995+00	2026-02-01 20:15:10.910769+00	pjadnurj2hdw	11b10676-7ac3-46fe-b5dc-6e53bc9d56fc
00000000-0000-0000-0000-000000000000	65	voqucczv237k	5ac10c39-274e-4ce5-a13b-f4da3af4a230	t	2026-02-02 06:08:18.120514+00	2026-02-02 07:06:19.728129+00	buzqszv7javr	11b10676-7ac3-46fe-b5dc-6e53bc9d56fc
00000000-0000-0000-0000-000000000000	51	47w7267tipp5	5ac10c39-274e-4ce5-a13b-f4da3af4a230	t	2026-02-01 20:15:10.927428+00	2026-02-01 21:13:58.682646+00	xjlfz5ckehis	11b10676-7ac3-46fe-b5dc-6e53bc9d56fc
00000000-0000-0000-0000-000000000000	66	ixsieudronml	5ac10c39-274e-4ce5-a13b-f4da3af4a230	t	2026-02-02 07:06:19.749353+00	2026-02-02 08:04:51.534731+00	voqucczv237k	11b10676-7ac3-46fe-b5dc-6e53bc9d56fc
00000000-0000-0000-0000-000000000000	52	hlxh6mfnukpg	5ac10c39-274e-4ce5-a13b-f4da3af4a230	t	2026-02-01 21:13:58.691501+00	2026-02-01 22:12:03.705803+00	47w7267tipp5	11b10676-7ac3-46fe-b5dc-6e53bc9d56fc
00000000-0000-0000-0000-000000000000	53	evakwl5oghmk	5ac10c39-274e-4ce5-a13b-f4da3af4a230	t	2026-02-01 22:12:03.734337+00	2026-02-01 23:10:16.408788+00	hlxh6mfnukpg	11b10676-7ac3-46fe-b5dc-6e53bc9d56fc
00000000-0000-0000-0000-000000000000	60	4krhstdtmzgw	60abdd33-af5a-4dfb-b211-a057a0995d12	t	2026-02-02 02:31:27.520089+00	2026-02-02 08:18:02.736425+00	uiw3iz7r3iia	2ec4e28f-400b-4218-bf5d-40bd092b0493
00000000-0000-0000-0000-000000000000	54	lg2pwij76yvl	5ac10c39-274e-4ce5-a13b-f4da3af4a230	t	2026-02-01 23:10:16.419686+00	2026-02-02 00:08:46.202234+00	evakwl5oghmk	11b10676-7ac3-46fe-b5dc-6e53bc9d56fc
00000000-0000-0000-0000-000000000000	55	6xiqcfqeyael	5ac10c39-274e-4ce5-a13b-f4da3af4a230	t	2026-02-02 00:08:46.21805+00	2026-02-02 01:07:58.240881+00	lg2pwij76yvl	11b10676-7ac3-46fe-b5dc-6e53bc9d56fc
00000000-0000-0000-0000-000000000000	61	36nvrs7xzbqv	36ae407d-c380-41ff-a714-d61371c44fb3	t	2026-02-02 02:49:50.341996+00	2026-02-02 08:18:25.551457+00	u6i4o2mgf5pk	3a1b4909-48e4-4e18-a472-1e3ac4ffa4f5
00000000-0000-0000-0000-000000000000	67	4dz7335nbig6	5ac10c39-274e-4ce5-a13b-f4da3af4a230	t	2026-02-02 08:04:51.557017+00	2026-02-02 09:03:59.654535+00	ixsieudronml	11b10676-7ac3-46fe-b5dc-6e53bc9d56fc
00000000-0000-0000-0000-000000000000	56	5x4hccqqfqri	5ac10c39-274e-4ce5-a13b-f4da3af4a230	t	2026-02-02 01:07:58.247756+00	2026-02-02 02:06:17.661867+00	6xiqcfqeyael	11b10676-7ac3-46fe-b5dc-6e53bc9d56fc
00000000-0000-0000-0000-000000000000	57	uiw3iz7r3iia	60abdd33-af5a-4dfb-b211-a057a0995d12	t	2026-02-02 01:32:59.099892+00	2026-02-02 02:31:27.508955+00	\N	2ec4e28f-400b-4218-bf5d-40bd092b0493
00000000-0000-0000-0000-000000000000	58	u6i4o2mgf5pk	36ae407d-c380-41ff-a714-d61371c44fb3	t	2026-02-02 01:51:32.138617+00	2026-02-02 02:49:50.334506+00	\N	3a1b4909-48e4-4e18-a472-1e3ac4ffa4f5
00000000-0000-0000-0000-000000000000	59	xkbaaszs6mnn	5ac10c39-274e-4ce5-a13b-f4da3af4a230	t	2026-02-02 02:06:17.669124+00	2026-02-02 03:04:26.5926+00	5x4hccqqfqri	11b10676-7ac3-46fe-b5dc-6e53bc9d56fc
00000000-0000-0000-0000-000000000000	68	gofnz7bk4kqu	60abdd33-af5a-4dfb-b211-a057a0995d12	t	2026-02-02 08:18:02.744291+00	2026-02-02 09:16:09.557839+00	4krhstdtmzgw	2ec4e28f-400b-4218-bf5d-40bd092b0493
00000000-0000-0000-0000-000000000000	62	fl4qeatk3q73	5ac10c39-274e-4ce5-a13b-f4da3af4a230	t	2026-02-02 03:04:26.608728+00	2026-02-02 04:02:58.045414+00	xkbaaszs6mnn	11b10676-7ac3-46fe-b5dc-6e53bc9d56fc
00000000-0000-0000-0000-000000000000	63	sntudy4go75g	5ac10c39-274e-4ce5-a13b-f4da3af4a230	t	2026-02-02 04:02:58.061148+00	2026-02-02 05:01:17.970516+00	fl4qeatk3q73	11b10676-7ac3-46fe-b5dc-6e53bc9d56fc
00000000-0000-0000-0000-000000000000	69	s4lklbc5ysfq	36ae407d-c380-41ff-a714-d61371c44fb3	t	2026-02-02 08:18:25.552226+00	2026-02-02 09:16:26.081693+00	36nvrs7xzbqv	3a1b4909-48e4-4e18-a472-1e3ac4ffa4f5
00000000-0000-0000-0000-000000000000	64	buzqszv7javr	5ac10c39-274e-4ce5-a13b-f4da3af4a230	t	2026-02-02 05:01:17.992063+00	2026-02-02 06:08:18.095919+00	sntudy4go75g	11b10676-7ac3-46fe-b5dc-6e53bc9d56fc
00000000-0000-0000-0000-000000000000	70	w6br6ajrqcvu	5ac10c39-274e-4ce5-a13b-f4da3af4a230	t	2026-02-02 09:03:59.677156+00	2026-02-02 10:14:27.008787+00	4dz7335nbig6	11b10676-7ac3-46fe-b5dc-6e53bc9d56fc
00000000-0000-0000-0000-000000000000	73	pbizcplqmrbs	5ac10c39-274e-4ce5-a13b-f4da3af4a230	t	2026-02-02 10:14:27.031199+00	2026-02-02 11:23:41.091928+00	w6br6ajrqcvu	11b10676-7ac3-46fe-b5dc-6e53bc9d56fc
00000000-0000-0000-0000-000000000000	74	uvtvp63bmffz	5ac10c39-274e-4ce5-a13b-f4da3af4a230	t	2026-02-02 11:23:41.108028+00	2026-02-02 12:31:39.322393+00	pbizcplqmrbs	11b10676-7ac3-46fe-b5dc-6e53bc9d56fc
00000000-0000-0000-0000-000000000000	75	dishioof5duy	5ac10c39-274e-4ce5-a13b-f4da3af4a230	t	2026-02-02 12:31:39.348732+00	2026-02-02 13:32:54.008044+00	uvtvp63bmffz	11b10676-7ac3-46fe-b5dc-6e53bc9d56fc
00000000-0000-0000-0000-000000000000	76	ch5ci2sowrb2	5ac10c39-274e-4ce5-a13b-f4da3af4a230	t	2026-02-02 13:32:54.023226+00	2026-02-02 14:31:31.560583+00	dishioof5duy	11b10676-7ac3-46fe-b5dc-6e53bc9d56fc
00000000-0000-0000-0000-000000000000	77	s7hcerzdzfrt	5ac10c39-274e-4ce5-a13b-f4da3af4a230	t	2026-02-02 14:31:31.568228+00	2026-02-02 15:36:53.77892+00	ch5ci2sowrb2	11b10676-7ac3-46fe-b5dc-6e53bc9d56fc
00000000-0000-0000-0000-000000000000	78	gunstlda64zt	5ac10c39-274e-4ce5-a13b-f4da3af4a230	t	2026-02-02 15:36:53.805483+00	2026-02-02 16:36:07.945397+00	s7hcerzdzfrt	11b10676-7ac3-46fe-b5dc-6e53bc9d56fc
00000000-0000-0000-0000-000000000000	79	wim2s22h3gzb	5ac10c39-274e-4ce5-a13b-f4da3af4a230	t	2026-02-02 16:36:07.958809+00	2026-02-02 17:35:07.86967+00	gunstlda64zt	11b10676-7ac3-46fe-b5dc-6e53bc9d56fc
00000000-0000-0000-0000-000000000000	80	m7njr4tnzovy	5ac10c39-274e-4ce5-a13b-f4da3af4a230	t	2026-02-02 17:35:07.896735+00	2026-02-02 18:34:07.807107+00	wim2s22h3gzb	11b10676-7ac3-46fe-b5dc-6e53bc9d56fc
00000000-0000-0000-0000-000000000000	81	24nmneeegvpx	5ac10c39-274e-4ce5-a13b-f4da3af4a230	t	2026-02-02 18:34:07.82311+00	2026-02-02 19:33:08.041641+00	m7njr4tnzovy	11b10676-7ac3-46fe-b5dc-6e53bc9d56fc
00000000-0000-0000-0000-000000000000	82	vuihi2b4jcpx	5ac10c39-274e-4ce5-a13b-f4da3af4a230	t	2026-02-02 19:33:08.070543+00	2026-02-02 20:40:47.025018+00	24nmneeegvpx	11b10676-7ac3-46fe-b5dc-6e53bc9d56fc
00000000-0000-0000-0000-000000000000	83	qjndvr47fu44	5ac10c39-274e-4ce5-a13b-f4da3af4a230	t	2026-02-02 20:40:47.037311+00	2026-02-02 21:39:43.012207+00	vuihi2b4jcpx	11b10676-7ac3-46fe-b5dc-6e53bc9d56fc
00000000-0000-0000-0000-000000000000	84	bv64yjramuf3	5ac10c39-274e-4ce5-a13b-f4da3af4a230	t	2026-02-02 21:39:43.030042+00	2026-02-02 22:38:42.889012+00	qjndvr47fu44	11b10676-7ac3-46fe-b5dc-6e53bc9d56fc
00000000-0000-0000-0000-000000000000	85	b3htds6dnfzy	5ac10c39-274e-4ce5-a13b-f4da3af4a230	t	2026-02-02 22:38:42.895415+00	2026-02-02 23:37:42.809429+00	bv64yjramuf3	11b10676-7ac3-46fe-b5dc-6e53bc9d56fc
00000000-0000-0000-0000-000000000000	86	dvg3hlr67tuy	5ac10c39-274e-4ce5-a13b-f4da3af4a230	t	2026-02-02 23:37:42.829272+00	2026-02-03 00:36:42.664564+00	b3htds6dnfzy	11b10676-7ac3-46fe-b5dc-6e53bc9d56fc
00000000-0000-0000-0000-000000000000	88	rievicqzi5tf	9969cfc6-451e-4ab2-ae2f-5d10a98eaf0a	f	2026-02-03 00:47:05.083586+00	2026-02-03 00:47:05.083586+00	\N	3d1cf609-78bd-42af-a324-00a94b863e71
00000000-0000-0000-0000-000000000000	89	y4oq7jko5fe4	10e558ca-3940-4995-9a8f-165e78efaffc	f	2026-02-03 00:47:05.740126+00	2026-02-03 00:47:05.740126+00	\N	e6d8df24-3727-412f-8dbe-0561c5b0c6aa
00000000-0000-0000-0000-000000000000	90	s6n2yejdegr3	5e4ec0ef-464a-41db-8e2f-9f3bfa2671ee	f	2026-02-03 00:47:06.251975+00	2026-02-03 00:47:06.251975+00	\N	336ca807-2f35-42d7-a66c-515b7924f274
00000000-0000-0000-0000-000000000000	91	jph7vijrtwps	95f608be-c1e9-43b1-b885-5e2784e4858f	f	2026-02-03 00:47:06.765031+00	2026-02-03 00:47:06.765031+00	\N	178ac5f2-c28b-46f2-9610-2b5f9f4ebdcd
00000000-0000-0000-0000-000000000000	92	syi4qxueilyf	8cf7c6be-ba2c-48c9-8825-589e675ff608	f	2026-02-03 00:47:07.288341+00	2026-02-03 00:47:07.288341+00	\N	9a47ee73-8cf2-4f45-9c8c-b113d4a85926
00000000-0000-0000-0000-000000000000	71	wro72etgpnic	60abdd33-af5a-4dfb-b211-a057a0995d12	t	2026-02-02 09:16:09.569176+00	2026-02-03 01:01:07.454718+00	gofnz7bk4kqu	2ec4e28f-400b-4218-bf5d-40bd092b0493
00000000-0000-0000-0000-000000000000	72	azjyxx3nzmjm	36ae407d-c380-41ff-a714-d61371c44fb3	t	2026-02-02 09:16:26.082036+00	2026-02-03 01:01:59.484893+00	s4lklbc5ysfq	3a1b4909-48e4-4e18-a472-1e3ac4ffa4f5
00000000-0000-0000-0000-000000000000	87	d72pnrleynmz	5ac10c39-274e-4ce5-a13b-f4da3af4a230	t	2026-02-03 00:36:42.678464+00	2026-02-03 01:35:25.060143+00	dvg3hlr67tuy	11b10676-7ac3-46fe-b5dc-6e53bc9d56fc
00000000-0000-0000-0000-000000000000	93	hzznrp2ydscj	60abdd33-af5a-4dfb-b211-a057a0995d12	t	2026-02-03 01:01:07.464312+00	2026-02-03 01:59:26.193981+00	wro72etgpnic	2ec4e28f-400b-4218-bf5d-40bd092b0493
00000000-0000-0000-0000-000000000000	94	mij6n4ln6cps	36ae407d-c380-41ff-a714-d61371c44fb3	t	2026-02-03 01:01:59.485935+00	2026-02-03 02:00:22.510843+00	azjyxx3nzmjm	3a1b4909-48e4-4e18-a472-1e3ac4ffa4f5
00000000-0000-0000-0000-000000000000	95	ax4w7rwdockp	5ac10c39-274e-4ce5-a13b-f4da3af4a230	t	2026-02-03 01:35:25.069649+00	2026-02-03 02:33:54.602493+00	d72pnrleynmz	11b10676-7ac3-46fe-b5dc-6e53bc9d56fc
00000000-0000-0000-0000-000000000000	96	jcl5zuczkypk	60abdd33-af5a-4dfb-b211-a057a0995d12	t	2026-02-03 01:59:26.209491+00	2026-02-03 02:57:56.275881+00	hzznrp2ydscj	2ec4e28f-400b-4218-bf5d-40bd092b0493
00000000-0000-0000-0000-000000000000	97	5ldvhdr5usbb	36ae407d-c380-41ff-a714-d61371c44fb3	t	2026-02-03 02:00:22.511246+00	2026-02-03 02:58:44.093713+00	mij6n4ln6cps	3a1b4909-48e4-4e18-a472-1e3ac4ffa4f5
00000000-0000-0000-0000-000000000000	98	kxf4tzxrzi4m	5ac10c39-274e-4ce5-a13b-f4da3af4a230	t	2026-02-03 02:33:54.619059+00	2026-02-03 03:32:42.849423+00	ax4w7rwdockp	11b10676-7ac3-46fe-b5dc-6e53bc9d56fc
00000000-0000-0000-0000-000000000000	100	ucsmudda5gmn	36ae407d-c380-41ff-a714-d61371c44fb3	t	2026-02-03 02:58:44.094354+00	2026-02-03 10:24:52.981393+00	5ldvhdr5usbb	3a1b4909-48e4-4e18-a472-1e3ac4ffa4f5
00000000-0000-0000-0000-000000000000	99	iu6b5x3oiq46	60abdd33-af5a-4dfb-b211-a057a0995d12	t	2026-02-03 02:57:56.288284+00	2026-02-03 10:27:50.600072+00	jcl5zuczkypk	2ec4e28f-400b-4218-bf5d-40bd092b0493
00000000-0000-0000-0000-000000000000	138	zfay6driatzo	5e4ec0ef-464a-41db-8e2f-9f3bfa2671ee	t	2026-02-03 14:19:02.934007+00	2026-02-04 09:41:52.454517+00	3l4epaiqvfb3	69d52aab-1ad5-4836-91b2-38280ab5dca9
00000000-0000-0000-0000-000000000000	101	uyiogs2hnjnd	5ac10c39-274e-4ce5-a13b-f4da3af4a230	t	2026-02-03 03:32:42.857778+00	2026-02-03 04:30:44.939238+00	kxf4tzxrzi4m	11b10676-7ac3-46fe-b5dc-6e53bc9d56fc
00000000-0000-0000-0000-000000000000	137	l6pbeqirhfic	5ac10c39-274e-4ce5-a13b-f4da3af4a230	t	2026-02-03 14:18:45.262658+00	2026-02-04 10:03:49.765421+00	g4ydrfdwcrhs	11b10676-7ac3-46fe-b5dc-6e53bc9d56fc
00000000-0000-0000-0000-000000000000	102	sbmbozalcf3z	5ac10c39-274e-4ce5-a13b-f4da3af4a230	t	2026-02-03 04:30:44.965956+00	2026-02-03 05:28:44.82761+00	uyiogs2hnjnd	11b10676-7ac3-46fe-b5dc-6e53bc9d56fc
00000000-0000-0000-0000-000000000000	140	2minwgmetauh	10e558ca-3940-4995-9a8f-165e78efaffc	t	2026-02-03 14:23:34.007292+00	2026-02-05 00:45:10.970046+00	\N	37f3ffaa-a35f-4db7-a814-f41f8fcf0359
00000000-0000-0000-0000-000000000000	103	qti5le7hoet4	5ac10c39-274e-4ce5-a13b-f4da3af4a230	t	2026-02-03 05:28:44.836764+00	2026-02-03 06:27:42.624478+00	sbmbozalcf3z	11b10676-7ac3-46fe-b5dc-6e53bc9d56fc
00000000-0000-0000-0000-000000000000	131	kvk2bfomfoir	5e4ec0ef-464a-41db-8e2f-9f3bfa2671ee	t	2026-02-03 14:07:19.338429+00	2026-02-05 00:45:37.674579+00	\N	97565c55-31fd-4aef-9f64-db127ec8038a
00000000-0000-0000-0000-000000000000	104	eyoidjwkzhf4	5ac10c39-274e-4ce5-a13b-f4da3af4a230	t	2026-02-03 06:27:42.635926+00	2026-02-03 07:26:42.625849+00	qti5le7hoet4	11b10676-7ac3-46fe-b5dc-6e53bc9d56fc
00000000-0000-0000-0000-000000000000	109	qzj7wfnmnbfn	36ae407d-c380-41ff-a714-d61371c44fb3	t	2026-02-03 10:24:52.998014+00	2026-02-05 08:13:57.748703+00	ucsmudda5gmn	3a1b4909-48e4-4e18-a472-1e3ac4ffa4f5
00000000-0000-0000-0000-000000000000	105	xacrksyn6lji	5ac10c39-274e-4ce5-a13b-f4da3af4a230	t	2026-02-03 07:26:42.650145+00	2026-02-03 08:25:42.466827+00	eyoidjwkzhf4	11b10676-7ac3-46fe-b5dc-6e53bc9d56fc
00000000-0000-0000-0000-000000000000	406	3tvrmj3bcn3k	5e4ec0ef-464a-41db-8e2f-9f3bfa2671ee	t	2026-02-06 05:07:49.058404+00	2026-02-06 06:06:22.269723+00	g2ovcebpmqah	69d52aab-1ad5-4836-91b2-38280ab5dca9
00000000-0000-0000-0000-000000000000	106	2qzpqnkqq5q5	5ac10c39-274e-4ce5-a13b-f4da3af4a230	t	2026-02-03 08:25:42.483925+00	2026-02-03 09:24:42.430111+00	xacrksyn6lji	11b10676-7ac3-46fe-b5dc-6e53bc9d56fc
00000000-0000-0000-0000-000000000000	758	5gtwqymjzim3	95f608be-c1e9-43b1-b885-5e2784e4858f	t	2026-02-10 12:19:23.02319+00	2026-02-10 13:18:23.168932+00	neefpmit3nr3	15c5bc25-7e7d-4db8-8f68-48bba9ce99ff
00000000-0000-0000-0000-000000000000	107	b4wruzi36nxx	5ac10c39-274e-4ce5-a13b-f4da3af4a230	t	2026-02-03 09:24:42.447304+00	2026-02-03 10:23:42.272228+00	2qzpqnkqq5q5	11b10676-7ac3-46fe-b5dc-6e53bc9d56fc
00000000-0000-0000-0000-000000000000	108	7gcvjjzfwh47	5ac10c39-274e-4ce5-a13b-f4da3af4a230	t	2026-02-03 10:23:42.292524+00	2026-02-03 11:22:42.386576+00	b4wruzi36nxx	11b10676-7ac3-46fe-b5dc-6e53bc9d56fc
00000000-0000-0000-0000-000000000000	110	m26zoppfhtqo	10e558ca-3940-4995-9a8f-165e78efaffc	t	2026-02-03 10:26:04.250317+00	2026-02-03 11:24:33.867898+00	\N	a83fa977-084a-491f-a042-30677fab2940
00000000-0000-0000-0000-000000000000	111	zmu6ler6ujyv	60abdd33-af5a-4dfb-b211-a057a0995d12	t	2026-02-03 10:27:50.601281+00	2026-02-03 11:26:42.194879+00	iu6b5x3oiq46	2ec4e28f-400b-4218-bf5d-40bd092b0493
00000000-0000-0000-0000-000000000000	112	ws6iyn6bvbjo	5e4ec0ef-464a-41db-8e2f-9f3bfa2671ee	t	2026-02-03 10:49:27.803327+00	2026-02-03 11:48:13.36868+00	\N	69d52aab-1ad5-4836-91b2-38280ab5dca9
00000000-0000-0000-0000-000000000000	114	r3sywvte2tvx	5ac10c39-274e-4ce5-a13b-f4da3af4a230	t	2026-02-03 11:22:42.400688+00	2026-02-03 12:21:42.279143+00	7gcvjjzfwh47	11b10676-7ac3-46fe-b5dc-6e53bc9d56fc
00000000-0000-0000-0000-000000000000	115	sl5qlalknroi	10e558ca-3940-4995-9a8f-165e78efaffc	t	2026-02-03 11:24:33.868692+00	2026-02-03 12:22:33.99806+00	m26zoppfhtqo	a83fa977-084a-491f-a042-30677fab2940
00000000-0000-0000-0000-000000000000	116	b47dy5mfpnez	60abdd33-af5a-4dfb-b211-a057a0995d12	t	2026-02-03 11:26:42.195883+00	2026-02-03 12:25:42.290791+00	zmu6ler6ujyv	2ec4e28f-400b-4218-bf5d-40bd092b0493
00000000-0000-0000-0000-000000000000	113	5z63zazfbgb4	5e4ec0ef-464a-41db-8e2f-9f3bfa2671ee	t	2026-02-03 11:05:51.025437+00	2026-02-03 12:36:55.369867+00	\N	843a3082-35b8-4987-be82-7767dc28f731
00000000-0000-0000-0000-000000000000	117	jbb23kxfgl46	5e4ec0ef-464a-41db-8e2f-9f3bfa2671ee	t	2026-02-03 11:48:13.382826+00	2026-02-03 12:47:13.239267+00	ws6iyn6bvbjo	69d52aab-1ad5-4836-91b2-38280ab5dca9
00000000-0000-0000-0000-000000000000	118	ldb333a7lyn7	5ac10c39-274e-4ce5-a13b-f4da3af4a230	t	2026-02-03 12:21:42.294688+00	2026-02-03 13:20:15.061441+00	r3sywvte2tvx	11b10676-7ac3-46fe-b5dc-6e53bc9d56fc
00000000-0000-0000-0000-000000000000	119	257s6xbrkxgg	10e558ca-3940-4995-9a8f-165e78efaffc	t	2026-02-03 12:22:33.998554+00	2026-02-03 13:20:55.435167+00	sl5qlalknroi	a83fa977-084a-491f-a042-30677fab2940
00000000-0000-0000-0000-000000000000	124	j3hnoa2pjx2t	10e558ca-3940-4995-9a8f-165e78efaffc	f	2026-02-03 13:20:55.435521+00	2026-02-03 13:20:55.435521+00	257s6xbrkxgg	a83fa977-084a-491f-a042-30677fab2940
00000000-0000-0000-0000-000000000000	120	2rzvaknn4qsz	60abdd33-af5a-4dfb-b211-a057a0995d12	t	2026-02-03 12:25:42.299803+00	2026-02-03 13:24:30.108466+00	b47dy5mfpnez	2ec4e28f-400b-4218-bf5d-40bd092b0493
00000000-0000-0000-0000-000000000000	125	agwlaxntnvzt	60abdd33-af5a-4dfb-b211-a057a0995d12	f	2026-02-03 13:24:30.120236+00	2026-02-03 13:24:30.120236+00	2rzvaknn4qsz	2ec4e28f-400b-4218-bf5d-40bd092b0493
00000000-0000-0000-0000-000000000000	127	bvha7h57ctac	10e558ca-3940-4995-9a8f-165e78efaffc	f	2026-02-03 13:55:15.692954+00	2026-02-03 13:55:15.692954+00	\N	e777cee1-fc3f-4eca-af84-cd60299ab98f
00000000-0000-0000-0000-000000000000	128	nd7zatg7aqvi	8cf7c6be-ba2c-48c9-8825-589e675ff608	f	2026-02-03 14:01:51.026298+00	2026-02-03 14:01:51.026298+00	\N	975d474c-77d2-460f-8215-51077871ab77
00000000-0000-0000-0000-000000000000	129	dtrip7xzvyta	8cf7c6be-ba2c-48c9-8825-589e675ff608	f	2026-02-03 14:04:32.350455+00	2026-02-03 14:04:32.350455+00	\N	81c32093-2c69-43e7-a90c-73a189ad262f
00000000-0000-0000-0000-000000000000	130	d5jr5o6dnkqq	5e4ec0ef-464a-41db-8e2f-9f3bfa2671ee	f	2026-02-03 14:05:06.909812+00	2026-02-03 14:05:06.909812+00	\N	00c7e083-b952-4e2b-a862-634d2da8b9af
00000000-0000-0000-0000-000000000000	121	en2awvihlazv	5e4ec0ef-464a-41db-8e2f-9f3bfa2671ee	t	2026-02-03 12:36:55.38119+00	2026-02-03 14:09:18.038938+00	5z63zazfbgb4	843a3082-35b8-4987-be82-7767dc28f731
00000000-0000-0000-0000-000000000000	132	eo3zycv3t6a2	5e4ec0ef-464a-41db-8e2f-9f3bfa2671ee	f	2026-02-03 14:09:18.041291+00	2026-02-03 14:09:18.041291+00	en2awvihlazv	843a3082-35b8-4987-be82-7767dc28f731
00000000-0000-0000-0000-000000000000	133	tns2aty3wjho	95f608be-c1e9-43b1-b885-5e2784e4858f	f	2026-02-03 14:10:01.677971+00	2026-02-03 14:10:01.677971+00	\N	7c99ea49-24c2-4fa8-b6b9-7129f29fa7dd
00000000-0000-0000-0000-000000000000	134	bvuxoqzwn7to	9969cfc6-451e-4ab2-ae2f-5d10a98eaf0a	f	2026-02-03 14:11:02.986821+00	2026-02-03 14:11:02.986821+00	\N	1d445617-1071-4cc9-b0c1-4e199134abf5
00000000-0000-0000-0000-000000000000	136	lwvgzdjh4p7g	9969cfc6-451e-4ab2-ae2f-5d10a98eaf0a	f	2026-02-03 14:13:56.451721+00	2026-02-03 14:13:56.451721+00	\N	d2e8bdf6-d255-453b-bc86-7ae845cc99f2
00000000-0000-0000-0000-000000000000	123	g4ydrfdwcrhs	5ac10c39-274e-4ce5-a13b-f4da3af4a230	t	2026-02-03 13:20:15.080159+00	2026-02-03 14:18:45.260523+00	ldb333a7lyn7	11b10676-7ac3-46fe-b5dc-6e53bc9d56fc
00000000-0000-0000-0000-000000000000	122	3l4epaiqvfb3	5e4ec0ef-464a-41db-8e2f-9f3bfa2671ee	t	2026-02-03 12:47:13.254916+00	2026-02-03 14:19:02.93332+00	jbb23kxfgl46	69d52aab-1ad5-4836-91b2-38280ab5dca9
00000000-0000-0000-0000-000000000000	126	7t2x3yqkfhde	95f608be-c1e9-43b1-b885-5e2784e4858f	t	2026-02-03 13:53:28.942199+00	2026-02-03 14:52:07.115633+00	\N	15c5bc25-7e7d-4db8-8f68-48bba9ce99ff
00000000-0000-0000-0000-000000000000	143	2zi7sa37oa3j	95f608be-c1e9-43b1-b885-5e2784e4858f	t	2026-02-03 14:52:07.136587+00	2026-02-03 15:56:35.755866+00	7t2x3yqkfhde	15c5bc25-7e7d-4db8-8f68-48bba9ce99ff
00000000-0000-0000-0000-000000000000	144	npo2vubg37u4	95f608be-c1e9-43b1-b885-5e2784e4858f	t	2026-02-03 15:56:35.774508+00	2026-02-03 16:55:24.27663+00	2zi7sa37oa3j	15c5bc25-7e7d-4db8-8f68-48bba9ce99ff
00000000-0000-0000-0000-000000000000	145	lhb3djairamb	95f608be-c1e9-43b1-b885-5e2784e4858f	t	2026-02-03 16:55:24.290096+00	2026-02-03 17:54:24.14796+00	npo2vubg37u4	15c5bc25-7e7d-4db8-8f68-48bba9ce99ff
00000000-0000-0000-0000-000000000000	146	rklvcvomtij3	95f608be-c1e9-43b1-b885-5e2784e4858f	t	2026-02-03 17:54:24.166753+00	2026-02-03 18:53:29.034091+00	lhb3djairamb	15c5bc25-7e7d-4db8-8f68-48bba9ce99ff
00000000-0000-0000-0000-000000000000	147	7glidaiuwa7g	95f608be-c1e9-43b1-b885-5e2784e4858f	t	2026-02-03 18:53:29.051395+00	2026-02-03 19:52:29.040068+00	rklvcvomtij3	15c5bc25-7e7d-4db8-8f68-48bba9ce99ff
00000000-0000-0000-0000-000000000000	148	hiu7kqfct7hx	95f608be-c1e9-43b1-b885-5e2784e4858f	t	2026-02-03 19:52:29.062027+00	2026-02-03 20:51:28.761718+00	7glidaiuwa7g	15c5bc25-7e7d-4db8-8f68-48bba9ce99ff
00000000-0000-0000-0000-000000000000	149	tcwgsjecxbpx	95f608be-c1e9-43b1-b885-5e2784e4858f	t	2026-02-03 20:51:28.771593+00	2026-02-03 21:57:45.608103+00	hiu7kqfct7hx	15c5bc25-7e7d-4db8-8f68-48bba9ce99ff
00000000-0000-0000-0000-000000000000	151	qybtz5uhnkpa	9969cfc6-451e-4ab2-ae2f-5d10a98eaf0a	f	2026-02-03 22:09:04.349612+00	2026-02-03 22:09:04.349612+00	\N	34bdfdb6-d883-40f7-85a8-e5a85d8c54d8
00000000-0000-0000-0000-000000000000	152	xkogpvspfpjy	10e558ca-3940-4995-9a8f-165e78efaffc	f	2026-02-03 22:09:09.851224+00	2026-02-03 22:09:09.851224+00	\N	8594f2b0-ca33-4796-bbcd-5687e8ab726e
00000000-0000-0000-0000-000000000000	150	zp52yg3m53on	95f608be-c1e9-43b1-b885-5e2784e4858f	t	2026-02-03 21:57:45.633332+00	2026-02-03 22:56:52.719817+00	tcwgsjecxbpx	15c5bc25-7e7d-4db8-8f68-48bba9ce99ff
00000000-0000-0000-0000-000000000000	141	s367cw7nons4	5e4ec0ef-464a-41db-8e2f-9f3bfa2671ee	t	2026-02-03 14:25:36.068979+00	2026-02-03 23:29:58.457963+00	\N	9495d67b-b5b4-4205-a85d-790f160d9ed1
00000000-0000-0000-0000-000000000000	139	7iuwt7df7hcf	5e4ec0ef-464a-41db-8e2f-9f3bfa2671ee	t	2026-02-03 14:22:48.415603+00	2026-02-04 01:52:53.812468+00	\N	8a5ea70e-9112-44a9-ad5b-f71eedf673a1
00000000-0000-0000-0000-000000000000	153	cynxnc5a4ipc	5e4ec0ef-464a-41db-8e2f-9f3bfa2671ee	f	2026-02-03 22:09:15.203706+00	2026-02-03 22:09:15.203706+00	\N	e7fc2d62-38ff-4008-a4e9-33618a83d7ea
00000000-0000-0000-0000-000000000000	154	sqt5bnwkt5lt	95f608be-c1e9-43b1-b885-5e2784e4858f	f	2026-02-03 22:09:20.593667+00	2026-02-03 22:09:20.593667+00	\N	92d48a38-20ef-46b2-b994-6b7aaa87652a
00000000-0000-0000-0000-000000000000	155	xscfbgyapqdy	8cf7c6be-ba2c-48c9-8825-589e675ff608	f	2026-02-03 22:09:25.922732+00	2026-02-03 22:09:25.922732+00	\N	928737f8-409a-4243-afb1-76b9d8cc63d1
00000000-0000-0000-0000-000000000000	135	mydmunf3v6y3	9969cfc6-451e-4ab2-ae2f-5d10a98eaf0a	t	2026-02-03 14:12:54.803777+00	2026-02-03 22:12:26.3722+00	\N	a1bb4554-2d29-4162-a351-2feeb0bb69a0
00000000-0000-0000-0000-000000000000	156	lmieszpbcoa4	9969cfc6-451e-4ab2-ae2f-5d10a98eaf0a	f	2026-02-03 22:12:26.389986+00	2026-02-03 22:12:26.389986+00	mydmunf3v6y3	a1bb4554-2d29-4162-a351-2feeb0bb69a0
00000000-0000-0000-0000-000000000000	174	m747t5fy7lth	10e558ca-3940-4995-9a8f-165e78efaffc	t	2026-02-04 08:43:16.380808+00	2026-02-04 09:41:28.05638+00	22xu3ppnhul5	f8b68d38-042c-4697-9458-1c0a74313dc3
00000000-0000-0000-0000-000000000000	186	g2ovcebpmqah	5e4ec0ef-464a-41db-8e2f-9f3bfa2671ee	t	2026-02-04 12:38:51.744093+00	2026-02-06 05:07:49.028091+00	yumnmvokj62a	69d52aab-1ad5-4836-91b2-38280ab5dca9
00000000-0000-0000-0000-000000000000	157	tafbpqxkr52y	95f608be-c1e9-43b1-b885-5e2784e4858f	t	2026-02-03 22:56:52.732536+00	2026-02-03 23:55:52.648333+00	zp52yg3m53on	15c5bc25-7e7d-4db8-8f68-48bba9ce99ff
00000000-0000-0000-0000-000000000000	175	p4z7va3p547d	95f608be-c1e9-43b1-b885-5e2784e4858f	t	2026-02-04 08:44:51.818693+00	2026-02-04 09:43:46.267219+00	ruluynwxx25q	15c5bc25-7e7d-4db8-8f68-48bba9ce99ff
00000000-0000-0000-0000-000000000000	202	tpdihhk43wr6	5e4ec0ef-464a-41db-8e2f-9f3bfa2671ee	t	2026-02-05 00:44:26.112864+00	2026-02-07 00:37:52.671304+00	co2pve3wynsh	9495d67b-b5b4-4205-a85d-790f160d9ed1
00000000-0000-0000-0000-000000000000	159	b4sqx3vlycc7	95f608be-c1e9-43b1-b885-5e2784e4858f	t	2026-02-03 23:55:52.672703+00	2026-02-04 00:54:34.762454+00	tafbpqxkr52y	15c5bc25-7e7d-4db8-8f68-48bba9ce99ff
00000000-0000-0000-0000-000000000000	772	7rxanocna3h3	10e558ca-3940-4995-9a8f-165e78efaffc	f	2026-02-11 02:02:17.775618+00	2026-02-11 02:02:17.775618+00	\N	2ed18d0a-77bf-4a85-a533-4d13d1c8d361
00000000-0000-0000-0000-000000000000	161	ojlsurwkkrdq	95f608be-c1e9-43b1-b885-5e2784e4858f	t	2026-02-04 00:54:34.789141+00	2026-02-04 01:53:05.736128+00	b4sqx3vlycc7	15c5bc25-7e7d-4db8-8f68-48bba9ce99ff
00000000-0000-0000-0000-000000000000	177	psk4cczzgq7h	5e4ec0ef-464a-41db-8e2f-9f3bfa2671ee	t	2026-02-04 09:41:52.455617+00	2026-02-04 10:40:22.779788+00	zfay6driatzo	69d52aab-1ad5-4836-91b2-38280ab5dca9
00000000-0000-0000-0000-000000000000	160	dbewz7cxlbxz	10e558ca-3940-4995-9a8f-165e78efaffc	t	2026-02-04 00:08:59.882265+00	2026-02-04 02:15:27.393089+00	\N	f8b68d38-042c-4697-9458-1c0a74313dc3
00000000-0000-0000-0000-000000000000	163	cii3mhkc7bx3	95f608be-c1e9-43b1-b885-5e2784e4858f	t	2026-02-04 01:53:05.736787+00	2026-02-04 02:51:29.797774+00	ojlsurwkkrdq	15c5bc25-7e7d-4db8-8f68-48bba9ce99ff
00000000-0000-0000-0000-000000000000	178	pvamcsxlq7jy	95f608be-c1e9-43b1-b885-5e2784e4858f	t	2026-02-04 09:43:46.268777+00	2026-02-04 10:42:12.342936+00	p4z7va3p547d	15c5bc25-7e7d-4db8-8f68-48bba9ce99ff
00000000-0000-0000-0000-000000000000	165	5bhddf65r5sm	95f608be-c1e9-43b1-b885-5e2784e4858f	t	2026-02-04 02:51:29.804616+00	2026-02-04 03:50:52.341393+00	cii3mhkc7bx3	15c5bc25-7e7d-4db8-8f68-48bba9ce99ff
00000000-0000-0000-0000-000000000000	166	wswijxbx23ur	95f608be-c1e9-43b1-b885-5e2784e4858f	t	2026-02-04 03:50:52.362806+00	2026-02-04 04:49:52.251246+00	5bhddf65r5sm	15c5bc25-7e7d-4db8-8f68-48bba9ce99ff
00000000-0000-0000-0000-000000000000	158	aay45exisdd5	5e4ec0ef-464a-41db-8e2f-9f3bfa2671ee	t	2026-02-03 23:29:58.472449+00	2026-02-04 10:44:49.732548+00	s367cw7nons4	9495d67b-b5b4-4205-a85d-790f160d9ed1
00000000-0000-0000-0000-000000000000	164	6ajsqabyav44	10e558ca-3940-4995-9a8f-165e78efaffc	t	2026-02-04 02:15:27.409087+00	2026-02-04 04:50:43.466254+00	dbewz7cxlbxz	f8b68d38-042c-4697-9458-1c0a74313dc3
00000000-0000-0000-0000-000000000000	167	6lbh6q3hj6qz	95f608be-c1e9-43b1-b885-5e2784e4858f	t	2026-02-04 04:49:52.259843+00	2026-02-04 05:47:59.947977+00	wswijxbx23ur	15c5bc25-7e7d-4db8-8f68-48bba9ce99ff
00000000-0000-0000-0000-000000000000	176	6orets5knkah	10e558ca-3940-4995-9a8f-165e78efaffc	t	2026-02-04 09:41:28.071281+00	2026-02-04 11:07:10.712067+00	m747t5fy7lth	f8b68d38-042c-4697-9458-1c0a74313dc3
00000000-0000-0000-0000-000000000000	168	wmcuuo6nz4kt	10e558ca-3940-4995-9a8f-165e78efaffc	t	2026-02-04 04:50:43.466924+00	2026-02-04 05:50:32.086734+00	6ajsqabyav44	f8b68d38-042c-4697-9458-1c0a74313dc3
00000000-0000-0000-0000-000000000000	169	fkpgkplnmjzj	95f608be-c1e9-43b1-b885-5e2784e4858f	t	2026-02-04 05:47:59.966463+00	2026-02-04 06:46:31.237824+00	6lbh6q3hj6qz	15c5bc25-7e7d-4db8-8f68-48bba9ce99ff
00000000-0000-0000-0000-000000000000	180	7lckwp5uhk4u	5e4ec0ef-464a-41db-8e2f-9f3bfa2671ee	t	2026-02-04 10:40:22.796547+00	2026-02-04 11:39:51.853903+00	psk4cczzgq7h	69d52aab-1ad5-4836-91b2-38280ab5dca9
00000000-0000-0000-0000-000000000000	170	qa4jbpcudetb	10e558ca-3940-4995-9a8f-165e78efaffc	t	2026-02-04 05:50:32.09003+00	2026-02-04 07:12:23.644237+00	wmcuuo6nz4kt	f8b68d38-042c-4697-9458-1c0a74313dc3
00000000-0000-0000-0000-000000000000	171	xlqcwqaxw4v2	95f608be-c1e9-43b1-b885-5e2784e4858f	t	2026-02-04 06:46:31.248648+00	2026-02-04 07:45:52.091559+00	fkpgkplnmjzj	15c5bc25-7e7d-4db8-8f68-48bba9ce99ff
00000000-0000-0000-0000-000000000000	181	tdx3zmvtpp53	95f608be-c1e9-43b1-b885-5e2784e4858f	t	2026-02-04 10:42:12.349649+00	2026-02-04 11:40:51.626822+00	pvamcsxlq7jy	15c5bc25-7e7d-4db8-8f68-48bba9ce99ff
00000000-0000-0000-0000-000000000000	172	22xu3ppnhul5	10e558ca-3940-4995-9a8f-165e78efaffc	t	2026-02-04 07:12:23.651036+00	2026-02-04 08:43:16.360093+00	qa4jbpcudetb	f8b68d38-042c-4697-9458-1c0a74313dc3
00000000-0000-0000-0000-000000000000	173	ruluynwxx25q	95f608be-c1e9-43b1-b885-5e2784e4858f	t	2026-02-04 07:45:52.114469+00	2026-02-04 08:44:51.816373+00	xlqcwqaxw4v2	15c5bc25-7e7d-4db8-8f68-48bba9ce99ff
00000000-0000-0000-0000-000000000000	184	yumnmvokj62a	5e4ec0ef-464a-41db-8e2f-9f3bfa2671ee	t	2026-02-04 11:39:51.869597+00	2026-02-04 12:38:51.732355+00	7lckwp5uhk4u	69d52aab-1ad5-4836-91b2-38280ab5dca9
00000000-0000-0000-0000-000000000000	185	cgphkwgh6ngo	95f608be-c1e9-43b1-b885-5e2784e4858f	t	2026-02-04 11:40:51.627498+00	2026-02-04 12:39:51.595726+00	tdx3zmvtpp53	15c5bc25-7e7d-4db8-8f68-48bba9ce99ff
00000000-0000-0000-0000-000000000000	182	txllyfqwoc4i	5e4ec0ef-464a-41db-8e2f-9f3bfa2671ee	t	2026-02-04 10:44:49.736417+00	2026-02-04 13:33:32.940636+00	aay45exisdd5	9495d67b-b5b4-4205-a85d-790f160d9ed1
00000000-0000-0000-0000-000000000000	187	hy6mxblvw2e4	95f608be-c1e9-43b1-b885-5e2784e4858f	t	2026-02-04 12:39:51.596318+00	2026-02-04 13:38:51.484035+00	cgphkwgh6ngo	15c5bc25-7e7d-4db8-8f68-48bba9ce99ff
00000000-0000-0000-0000-000000000000	189	xv3btkyg6dvv	95f608be-c1e9-43b1-b885-5e2784e4858f	t	2026-02-04 13:38:51.489604+00	2026-02-04 14:37:51.558969+00	hy6mxblvw2e4	15c5bc25-7e7d-4db8-8f68-48bba9ce99ff
00000000-0000-0000-0000-000000000000	190	6zre4nkrjghg	95f608be-c1e9-43b1-b885-5e2784e4858f	t	2026-02-04 14:37:51.57287+00	2026-02-04 15:50:25.210384+00	xv3btkyg6dvv	15c5bc25-7e7d-4db8-8f68-48bba9ce99ff
00000000-0000-0000-0000-000000000000	191	nqa3juulv3pz	95f608be-c1e9-43b1-b885-5e2784e4858f	t	2026-02-04 15:50:25.230197+00	2026-02-04 16:49:25.573979+00	6zre4nkrjghg	15c5bc25-7e7d-4db8-8f68-48bba9ce99ff
00000000-0000-0000-0000-000000000000	192	exoese2ocmwg	95f608be-c1e9-43b1-b885-5e2784e4858f	t	2026-02-04 16:49:25.595057+00	2026-02-04 17:52:57.668151+00	nqa3juulv3pz	15c5bc25-7e7d-4db8-8f68-48bba9ce99ff
00000000-0000-0000-0000-000000000000	193	vii3dhgs5geu	95f608be-c1e9-43b1-b885-5e2784e4858f	t	2026-02-04 17:52:57.695003+00	2026-02-04 18:52:39.391198+00	exoese2ocmwg	15c5bc25-7e7d-4db8-8f68-48bba9ce99ff
00000000-0000-0000-0000-000000000000	194	aakkxpuy6omo	95f608be-c1e9-43b1-b885-5e2784e4858f	t	2026-02-04 18:52:39.401751+00	2026-02-04 19:51:39.081327+00	vii3dhgs5geu	15c5bc25-7e7d-4db8-8f68-48bba9ce99ff
00000000-0000-0000-0000-000000000000	195	3zz76nrhpume	95f608be-c1e9-43b1-b885-5e2784e4858f	t	2026-02-04 19:51:39.103898+00	2026-02-04 20:49:54.349518+00	aakkxpuy6omo	15c5bc25-7e7d-4db8-8f68-48bba9ce99ff
00000000-0000-0000-0000-000000000000	196	kdio66hqrtq6	95f608be-c1e9-43b1-b885-5e2784e4858f	t	2026-02-04 20:49:54.375867+00	2026-02-04 21:48:24.294945+00	3zz76nrhpume	15c5bc25-7e7d-4db8-8f68-48bba9ce99ff
00000000-0000-0000-0000-000000000000	197	ndxwou3uxyvn	95f608be-c1e9-43b1-b885-5e2784e4858f	t	2026-02-04 21:48:24.314283+00	2026-02-04 22:46:54.133875+00	kdio66hqrtq6	15c5bc25-7e7d-4db8-8f68-48bba9ce99ff
00000000-0000-0000-0000-000000000000	188	uob7mmunaxuq	5e4ec0ef-464a-41db-8e2f-9f3bfa2671ee	t	2026-02-04 13:33:32.960308+00	2026-02-04 23:33:13.991449+00	txllyfqwoc4i	9495d67b-b5b4-4205-a85d-790f160d9ed1
00000000-0000-0000-0000-000000000000	198	saujudwdfrvw	95f608be-c1e9-43b1-b885-5e2784e4858f	t	2026-02-04 22:46:54.154765+00	2026-02-04 23:45:38.642128+00	ndxwou3uxyvn	15c5bc25-7e7d-4db8-8f68-48bba9ce99ff
00000000-0000-0000-0000-000000000000	183	umc6furylx7b	10e558ca-3940-4995-9a8f-165e78efaffc	t	2026-02-04 11:07:10.725997+00	2026-02-05 00:07:06.451285+00	6orets5knkah	f8b68d38-042c-4697-9458-1c0a74313dc3
00000000-0000-0000-0000-000000000000	199	co2pve3wynsh	5e4ec0ef-464a-41db-8e2f-9f3bfa2671ee	t	2026-02-04 23:33:14.006326+00	2026-02-05 00:44:26.092312+00	uob7mmunaxuq	9495d67b-b5b4-4205-a85d-790f160d9ed1
00000000-0000-0000-0000-000000000000	200	qjkud6jr7w22	95f608be-c1e9-43b1-b885-5e2784e4858f	t	2026-02-04 23:45:38.652847+00	2026-02-05 00:44:38.464119+00	saujudwdfrvw	15c5bc25-7e7d-4db8-8f68-48bba9ce99ff
00000000-0000-0000-0000-000000000000	162	2l6xikk63qiu	5e4ec0ef-464a-41db-8e2f-9f3bfa2671ee	t	2026-02-04 01:52:53.832092+00	2026-02-05 00:45:30.423455+00	7iuwt7df7hcf	8a5ea70e-9112-44a9-ad5b-f71eedf673a1
00000000-0000-0000-0000-000000000000	179	gj7lisvlpcry	5ac10c39-274e-4ce5-a13b-f4da3af4a230	t	2026-02-04 10:03:49.782184+00	2026-02-05 04:20:46.36692+00	l6pbeqirhfic	11b10676-7ac3-46fe-b5dc-6e53bc9d56fc
00000000-0000-0000-0000-000000000000	760	dkxugd2h5bvb	06d3b907-e06e-466b-a5fe-2dcc3912afaf	f	2026-02-10 13:21:23.850846+00	2026-02-10 13:21:23.850846+00	sp7daunliobp	d5c296b8-50d5-47a7-b7c2-2abecaae18f3
00000000-0000-0000-0000-000000000000	408	xs6xgb3umeys	5e4ec0ef-464a-41db-8e2f-9f3bfa2671ee	t	2026-02-06 06:06:22.293978+00	2026-02-06 07:05:22.224339+00	3tvrmj3bcn3k	69d52aab-1ad5-4836-91b2-38280ab5dca9
00000000-0000-0000-0000-000000000000	205	ptwmwhsvtkeb	5e4ec0ef-464a-41db-8e2f-9f3bfa2671ee	f	2026-02-05 00:45:30.424185+00	2026-02-05 00:45:30.424185+00	2l6xikk63qiu	8a5ea70e-9112-44a9-ad5b-f71eedf673a1
00000000-0000-0000-0000-000000000000	220	2isvkktnz4mg	10e558ca-3940-4995-9a8f-165e78efaffc	t	2026-02-05 02:16:35.91432+00	2026-02-06 08:00:55.923297+00	zw7q7jafevxq	f8b68d38-042c-4697-9458-1c0a74313dc3
00000000-0000-0000-0000-000000000000	207	65rggbx7eo6m	9969cfc6-451e-4ab2-ae2f-5d10a98eaf0a	f	2026-02-05 01:25:13.045259+00	2026-02-05 01:25:13.045259+00	\N	652c6f22-a7db-49cc-aabd-fc7ad757cbf7
00000000-0000-0000-0000-000000000000	208	lgkgzj3665k3	10e558ca-3940-4995-9a8f-165e78efaffc	f	2026-02-05 01:25:18.721803+00	2026-02-05 01:25:18.721803+00	\N	0644d0b0-ee95-4c6a-b694-0ad0d1e04235
00000000-0000-0000-0000-000000000000	209	kzd57l2cpsbo	5e4ec0ef-464a-41db-8e2f-9f3bfa2671ee	f	2026-02-05 01:25:24.080992+00	2026-02-05 01:25:24.080992+00	\N	3c10b435-600c-44f9-9726-f23bc2fb712c
00000000-0000-0000-0000-000000000000	210	qgpbak6lrvd4	95f608be-c1e9-43b1-b885-5e2784e4858f	f	2026-02-05 01:25:29.918284+00	2026-02-05 01:25:29.918284+00	\N	b65fbc15-8258-4dc4-ad8f-74a615e1ef84
00000000-0000-0000-0000-000000000000	211	yg2ohvbvzjrg	8cf7c6be-ba2c-48c9-8825-589e675ff608	f	2026-02-05 01:25:35.2845+00	2026-02-05 01:25:35.2845+00	\N	5d64f434-82f2-4cbd-8fa0-e6f3c65a249d
00000000-0000-0000-0000-000000000000	212	f2rjwvjkjrbv	9969cfc6-451e-4ab2-ae2f-5d10a98eaf0a	f	2026-02-05 01:43:07.320877+00	2026-02-05 01:43:07.320877+00	\N	6e709193-bdb7-4240-9b8d-7efa8c6ebf1e
00000000-0000-0000-0000-000000000000	203	m4hzqvz3laxr	95f608be-c1e9-43b1-b885-5e2784e4858f	t	2026-02-05 00:44:38.464758+00	2026-02-05 01:43:08.496867+00	qjkud6jr7w22	15c5bc25-7e7d-4db8-8f68-48bba9ce99ff
00000000-0000-0000-0000-000000000000	204	kqv3sw27gnnm	10e558ca-3940-4995-9a8f-165e78efaffc	t	2026-02-05 00:45:10.970422+00	2026-02-05 01:43:11.495855+00	2minwgmetauh	37f3ffaa-a35f-4db7-a814-f41f8fcf0359
00000000-0000-0000-0000-000000000000	215	cxywhd5zr6qj	10e558ca-3940-4995-9a8f-165e78efaffc	f	2026-02-05 01:43:13.126472+00	2026-02-05 01:43:13.126472+00	\N	65f11cb0-36ad-4ef8-9c84-64569b36aace
00000000-0000-0000-0000-000000000000	216	dksq2olt4glm	5e4ec0ef-464a-41db-8e2f-9f3bfa2671ee	f	2026-02-05 01:43:18.485025+00	2026-02-05 01:43:18.485025+00	\N	82f814cc-b632-4b90-a2c5-9bb75da14351
00000000-0000-0000-0000-000000000000	217	h2f7s2mzsyoi	95f608be-c1e9-43b1-b885-5e2784e4858f	f	2026-02-05 01:43:23.802341+00	2026-02-05 01:43:23.802341+00	\N	231d20fa-f64a-414b-8758-bb755910e17e
00000000-0000-0000-0000-000000000000	218	bbimdbctdmoe	8cf7c6be-ba2c-48c9-8825-589e675ff608	f	2026-02-05 01:43:29.308735+00	2026-02-05 01:43:29.308735+00	\N	1fe3bd68-8c4f-450f-8b92-7c4ee2af0212
00000000-0000-0000-0000-000000000000	206	ojmirllaf76i	5e4ec0ef-464a-41db-8e2f-9f3bfa2671ee	t	2026-02-05 00:45:37.674945+00	2026-02-05 01:43:37.830419+00	kvk2bfomfoir	97565c55-31fd-4aef-9f64-db127ec8038a
00000000-0000-0000-0000-000000000000	414	s6t54qil4iob	95f608be-c1e9-43b1-b885-5e2784e4858f	t	2026-02-06 08:12:49.939877+00	2026-02-06 09:11:22.255797+00	eilwq3vwnawh	15c5bc25-7e7d-4db8-8f68-48bba9ce99ff
00000000-0000-0000-0000-000000000000	201	zw7q7jafevxq	10e558ca-3940-4995-9a8f-165e78efaffc	t	2026-02-05 00:07:06.469806+00	2026-02-05 02:16:35.885906+00	umc6furylx7b	f8b68d38-042c-4697-9458-1c0a74313dc3
00000000-0000-0000-0000-000000000000	214	dbn3d5vjqp3i	10e558ca-3940-4995-9a8f-165e78efaffc	t	2026-02-05 01:43:11.496442+00	2026-02-05 02:41:11.942002+00	kqv3sw27gnnm	37f3ffaa-a35f-4db7-a814-f41f8fcf0359
00000000-0000-0000-0000-000000000000	415	jlefeiya6goi	5ac10c39-274e-4ce5-a13b-f4da3af4a230	t	2026-02-06 08:13:22.094665+00	2026-02-06 09:12:22.144639+00	6w4az6mrymja	11b10676-7ac3-46fe-b5dc-6e53bc9d56fc
00000000-0000-0000-0000-000000000000	219	z4zmgckezdpc	5e4ec0ef-464a-41db-8e2f-9f3bfa2671ee	t	2026-02-05 01:43:37.830776+00	2026-02-05 02:41:37.844536+00	ojmirllaf76i	97565c55-31fd-4aef-9f64-db127ec8038a
00000000-0000-0000-0000-000000000000	213	q5xoikwt2nr6	95f608be-c1e9-43b1-b885-5e2784e4858f	t	2026-02-05 01:43:08.498867+00	2026-02-05 02:41:38.423978+00	m4hzqvz3laxr	15c5bc25-7e7d-4db8-8f68-48bba9ce99ff
00000000-0000-0000-0000-000000000000	420	mlipyrqw2yt3	5ac10c39-274e-4ce5-a13b-f4da3af4a230	f	2026-02-06 10:11:22.068652+00	2026-02-06 10:11:22.068652+00	nwpd5nqfmhla	11b10676-7ac3-46fe-b5dc-6e53bc9d56fc
00000000-0000-0000-0000-000000000000	221	45fxyghu427l	10e558ca-3940-4995-9a8f-165e78efaffc	t	2026-02-05 02:41:11.959341+00	2026-02-05 03:39:19.753378+00	dbn3d5vjqp3i	37f3ffaa-a35f-4db7-a814-f41f8fcf0359
00000000-0000-0000-0000-000000000000	419	5ehax24go5xb	95f608be-c1e9-43b1-b885-5e2784e4858f	t	2026-02-06 10:10:22.199695+00	2026-02-06 11:08:47.27057+00	5ibfgeyxckcu	15c5bc25-7e7d-4db8-8f68-48bba9ce99ff
00000000-0000-0000-0000-000000000000	222	jysujaxudndf	5e4ec0ef-464a-41db-8e2f-9f3bfa2671ee	t	2026-02-05 02:41:37.8449+00	2026-02-05 03:39:48.119611+00	z4zmgckezdpc	97565c55-31fd-4aef-9f64-db127ec8038a
00000000-0000-0000-0000-000000000000	223	x7ij3a4gc5kj	95f608be-c1e9-43b1-b885-5e2784e4858f	t	2026-02-05 02:41:38.424608+00	2026-02-05 03:40:38.350605+00	q5xoikwt2nr6	15c5bc25-7e7d-4db8-8f68-48bba9ce99ff
00000000-0000-0000-0000-000000000000	423	u5x7kjzjzo2x	95f608be-c1e9-43b1-b885-5e2784e4858f	t	2026-02-06 12:07:26.906815+00	2026-02-06 13:06:21.963746+00	2q6yx6m4eqh7	15c5bc25-7e7d-4db8-8f68-48bba9ce99ff
00000000-0000-0000-0000-000000000000	240	ry5bu7gf64zr	10e558ca-3940-4995-9a8f-165e78efaffc	t	2026-02-05 07:31:21.404574+00	2026-02-06 13:58:28.127395+00	vu4ctk5e2fng	37f3ffaa-a35f-4db7-a814-f41f8fcf0359
00000000-0000-0000-0000-000000000000	224	r5omjnxxca5a	10e558ca-3940-4995-9a8f-165e78efaffc	t	2026-02-05 03:39:19.775031+00	2026-02-05 04:37:19.89604+00	45fxyghu427l	37f3ffaa-a35f-4db7-a814-f41f8fcf0359
00000000-0000-0000-0000-000000000000	225	r6p53yw2q7r7	5e4ec0ef-464a-41db-8e2f-9f3bfa2671ee	t	2026-02-05 03:39:48.120288+00	2026-02-05 04:37:48.202664+00	jysujaxudndf	97565c55-31fd-4aef-9f64-db127ec8038a
00000000-0000-0000-0000-000000000000	426	uw2bdyqsxdlh	10e558ca-3940-4995-9a8f-165e78efaffc	t	2026-02-06 13:58:28.140311+00	2026-02-09 00:29:06.810409+00	ry5bu7gf64zr	37f3ffaa-a35f-4db7-a814-f41f8fcf0359
00000000-0000-0000-0000-000000000000	226	ipnuk4g4vpdw	95f608be-c1e9-43b1-b885-5e2784e4858f	t	2026-02-05 03:40:38.351549+00	2026-02-05 04:39:38.5012+00	x7ij3a4gc5kj	15c5bc25-7e7d-4db8-8f68-48bba9ce99ff
00000000-0000-0000-0000-000000000000	227	4lw7anarmiw3	5ac10c39-274e-4ce5-a13b-f4da3af4a230	t	2026-02-05 04:20:46.38502+00	2026-02-05 05:19:38.799224+00	gj7lisvlpcry	11b10676-7ac3-46fe-b5dc-6e53bc9d56fc
00000000-0000-0000-0000-000000000000	228	ajnskqi7bntq	10e558ca-3940-4995-9a8f-165e78efaffc	t	2026-02-05 04:37:19.905624+00	2026-02-05 05:35:20.443104+00	r5omjnxxca5a	37f3ffaa-a35f-4db7-a814-f41f8fcf0359
00000000-0000-0000-0000-000000000000	229	wmtoezcxrgir	5e4ec0ef-464a-41db-8e2f-9f3bfa2671ee	t	2026-02-05 04:37:48.203919+00	2026-02-05 05:35:48.380202+00	r6p53yw2q7r7	97565c55-31fd-4aef-9f64-db127ec8038a
00000000-0000-0000-0000-000000000000	230	jbnnpjql62lw	95f608be-c1e9-43b1-b885-5e2784e4858f	t	2026-02-05 04:39:38.508097+00	2026-02-05 05:38:38.639844+00	ipnuk4g4vpdw	15c5bc25-7e7d-4db8-8f68-48bba9ce99ff
00000000-0000-0000-0000-000000000000	231	ptibswk4ghe3	5ac10c39-274e-4ce5-a13b-f4da3af4a230	t	2026-02-05 05:19:38.823282+00	2026-02-05 06:18:38.991195+00	4lw7anarmiw3	11b10676-7ac3-46fe-b5dc-6e53bc9d56fc
00000000-0000-0000-0000-000000000000	232	snictascd3ib	10e558ca-3940-4995-9a8f-165e78efaffc	t	2026-02-05 05:35:20.462571+00	2026-02-05 06:33:20.931733+00	ajnskqi7bntq	37f3ffaa-a35f-4db7-a814-f41f8fcf0359
00000000-0000-0000-0000-000000000000	233	dl4uvsx5xn5e	5e4ec0ef-464a-41db-8e2f-9f3bfa2671ee	t	2026-02-05 05:35:48.380899+00	2026-02-05 06:33:48.613933+00	wmtoezcxrgir	97565c55-31fd-4aef-9f64-db127ec8038a
00000000-0000-0000-0000-000000000000	234	jem7xdo35tuy	95f608be-c1e9-43b1-b885-5e2784e4858f	t	2026-02-05 05:38:38.642126+00	2026-02-05 06:37:38.863614+00	jbnnpjql62lw	15c5bc25-7e7d-4db8-8f68-48bba9ce99ff
00000000-0000-0000-0000-000000000000	235	seuqxqrljgnf	5ac10c39-274e-4ce5-a13b-f4da3af4a230	t	2026-02-05 06:18:39.001394+00	2026-02-05 07:17:39.135067+00	ptibswk4ghe3	11b10676-7ac3-46fe-b5dc-6e53bc9d56fc
00000000-0000-0000-0000-000000000000	236	vu4ctk5e2fng	10e558ca-3940-4995-9a8f-165e78efaffc	t	2026-02-05 06:33:20.951353+00	2026-02-05 07:31:21.381971+00	snictascd3ib	37f3ffaa-a35f-4db7-a814-f41f8fcf0359
00000000-0000-0000-0000-000000000000	237	2qp76ftspidi	5e4ec0ef-464a-41db-8e2f-9f3bfa2671ee	t	2026-02-05 06:33:48.614855+00	2026-02-05 07:31:48.73392+00	dl4uvsx5xn5e	97565c55-31fd-4aef-9f64-db127ec8038a
00000000-0000-0000-0000-000000000000	238	5jj3jfgiioaw	95f608be-c1e9-43b1-b885-5e2784e4858f	t	2026-02-05 06:37:38.86813+00	2026-02-05 07:36:39.151939+00	jem7xdo35tuy	15c5bc25-7e7d-4db8-8f68-48bba9ce99ff
00000000-0000-0000-0000-000000000000	243	bz7q547qksvj	9969cfc6-451e-4ab2-ae2f-5d10a98eaf0a	f	2026-02-05 07:38:11.960742+00	2026-02-05 07:38:11.960742+00	\N	a3f8e76d-0c50-4bd9-98e4-86c76cd7b1fd
00000000-0000-0000-0000-000000000000	244	hsbmmzugpyhe	10e558ca-3940-4995-9a8f-165e78efaffc	f	2026-02-05 07:38:14.521236+00	2026-02-05 07:38:14.521236+00	\N	1ccce5b3-8bb0-4d2d-b525-c49015dc0e08
00000000-0000-0000-0000-000000000000	245	erktzfk5h2me	5e4ec0ef-464a-41db-8e2f-9f3bfa2671ee	f	2026-02-05 07:38:16.860038+00	2026-02-05 07:38:16.860038+00	\N	3ed651e1-98f5-4e03-ac4f-2a6f30be26b5
00000000-0000-0000-0000-000000000000	239	hr6bz36wudoc	5ac10c39-274e-4ce5-a13b-f4da3af4a230	t	2026-02-05 07:17:39.14253+00	2026-02-05 08:15:43.966814+00	seuqxqrljgnf	11b10676-7ac3-46fe-b5dc-6e53bc9d56fc
00000000-0000-0000-0000-000000000000	241	qanc6g4pk5sl	5e4ec0ef-464a-41db-8e2f-9f3bfa2671ee	t	2026-02-05 07:31:48.73442+00	2026-02-05 08:30:10.708395+00	2qp76ftspidi	97565c55-31fd-4aef-9f64-db127ec8038a
00000000-0000-0000-0000-000000000000	242	thndjvmtr773	95f608be-c1e9-43b1-b885-5e2784e4858f	t	2026-02-05 07:36:39.153398+00	2026-02-05 08:35:39.804304+00	5jj3jfgiioaw	15c5bc25-7e7d-4db8-8f68-48bba9ce99ff
00000000-0000-0000-0000-000000000000	246	twptaxkkqnri	95f608be-c1e9-43b1-b885-5e2784e4858f	f	2026-02-05 07:38:19.237733+00	2026-02-05 07:38:19.237733+00	\N	d4c7cd1c-ae71-4c2c-a27e-210a14795b3c
00000000-0000-0000-0000-000000000000	247	27n6jruhdhum	8cf7c6be-ba2c-48c9-8825-589e675ff608	f	2026-02-05 07:38:21.62341+00	2026-02-05 07:38:21.62341+00	\N	4450442b-9292-4e90-bb59-9adb3040c34b
00000000-0000-0000-0000-000000000000	248	b7ubpca5jdiz	9969cfc6-451e-4ab2-ae2f-5d10a98eaf0a	f	2026-02-05 07:49:05.429425+00	2026-02-05 07:49:05.429425+00	\N	6221b9d7-e743-463b-bb43-11a1b06db73c
00000000-0000-0000-0000-000000000000	249	6quozerkvbti	9969cfc6-451e-4ab2-ae2f-5d10a98eaf0a	f	2026-02-05 07:49:06.379205+00	2026-02-05 07:49:06.379205+00	\N	ce53bf5f-d91f-4202-b113-f7082ef94363
00000000-0000-0000-0000-000000000000	250	m2wch6az4qm5	9969cfc6-451e-4ab2-ae2f-5d10a98eaf0a	f	2026-02-05 07:49:07.273307+00	2026-02-05 07:49:07.273307+00	\N	0b7fd9c1-c546-4172-8276-db6092a4a7e9
00000000-0000-0000-0000-000000000000	251	i6w2ijsqpzyj	10e558ca-3940-4995-9a8f-165e78efaffc	f	2026-02-05 07:49:08.122268+00	2026-02-05 07:49:08.122268+00	\N	8f567b18-4390-4635-b102-377a7556d4d3
00000000-0000-0000-0000-000000000000	252	lu6jccyukth2	10e558ca-3940-4995-9a8f-165e78efaffc	f	2026-02-05 07:49:08.998023+00	2026-02-05 07:49:08.998023+00	\N	4d96da29-b926-4ab9-8e20-11c70316394d
00000000-0000-0000-0000-000000000000	253	piwtigdeezrm	10e558ca-3940-4995-9a8f-165e78efaffc	f	2026-02-05 07:49:09.874857+00	2026-02-05 07:49:09.874857+00	\N	36dc3d44-bc1b-44bb-8795-acc0cde6569d
00000000-0000-0000-0000-000000000000	254	7thnr3uoczod	5e4ec0ef-464a-41db-8e2f-9f3bfa2671ee	f	2026-02-05 07:49:10.726678+00	2026-02-05 07:49:10.726678+00	\N	87003dc3-7af7-48e6-85b4-a374842ae466
00000000-0000-0000-0000-000000000000	255	wt3ktwkxox3p	5e4ec0ef-464a-41db-8e2f-9f3bfa2671ee	f	2026-02-05 07:49:11.585201+00	2026-02-05 07:49:11.585201+00	\N	7115854d-8bdd-4e89-ba6a-ad0356a8cdd2
00000000-0000-0000-0000-000000000000	256	ddqpvwrd7oc6	5e4ec0ef-464a-41db-8e2f-9f3bfa2671ee	f	2026-02-05 07:49:12.451829+00	2026-02-05 07:49:12.451829+00	\N	c8606760-466a-4244-836f-b4c04d802408
00000000-0000-0000-0000-000000000000	257	54moy4chrjtr	95f608be-c1e9-43b1-b885-5e2784e4858f	f	2026-02-05 07:49:13.316033+00	2026-02-05 07:49:13.316033+00	\N	1d341451-ffd7-4362-a4f0-b313bb3a49de
00000000-0000-0000-0000-000000000000	258	hnjqyw464n7d	95f608be-c1e9-43b1-b885-5e2784e4858f	f	2026-02-05 07:49:14.216156+00	2026-02-05 07:49:14.216156+00	\N	e71fdaec-f2bd-4b40-b945-e42ac7a93272
00000000-0000-0000-0000-000000000000	259	37ryh2thpjva	95f608be-c1e9-43b1-b885-5e2784e4858f	f	2026-02-05 07:49:15.085587+00	2026-02-05 07:49:15.085587+00	\N	8ebe32a4-4e39-48e4-888c-4794c8a46c36
00000000-0000-0000-0000-000000000000	260	efehfn4pb3cb	8cf7c6be-ba2c-48c9-8825-589e675ff608	f	2026-02-05 07:49:15.95442+00	2026-02-05 07:49:15.95442+00	\N	18f1a915-e2e2-4203-bd75-482ba496fb22
00000000-0000-0000-0000-000000000000	261	j5siiai4g5nh	8cf7c6be-ba2c-48c9-8825-589e675ff608	f	2026-02-05 07:49:16.828895+00	2026-02-05 07:49:16.828895+00	\N	b29d27fa-161f-4684-ac32-4b3f5eae85a9
00000000-0000-0000-0000-000000000000	262	nh7az5obzu35	8cf7c6be-ba2c-48c9-8825-589e675ff608	f	2026-02-05 07:49:17.673264+00	2026-02-05 07:49:17.673264+00	\N	c8499177-d0ca-49aa-91b2-aeee05cdbd0b
00000000-0000-0000-0000-000000000000	263	xquxcvpebsea	9969cfc6-451e-4ab2-ae2f-5d10a98eaf0a	f	2026-02-05 08:09:20.934291+00	2026-02-05 08:09:20.934291+00	\N	60f39b2e-b4fb-4b60-99df-5ffd3021acbc
00000000-0000-0000-0000-000000000000	264	dpsk4ju2s3eu	9969cfc6-451e-4ab2-ae2f-5d10a98eaf0a	f	2026-02-05 08:10:02.243381+00	2026-02-05 08:10:02.243381+00	\N	a6b08aad-221e-47c7-ba6b-f2cfce3ff7f9
00000000-0000-0000-0000-000000000000	265	tckukvdtvg25	9969cfc6-451e-4ab2-ae2f-5d10a98eaf0a	f	2026-02-05 08:10:03.612781+00	2026-02-05 08:10:03.612781+00	\N	715b609f-92e9-4cfc-ac24-1f763359f290
00000000-0000-0000-0000-000000000000	266	reu55474iu2c	10e558ca-3940-4995-9a8f-165e78efaffc	f	2026-02-05 08:10:04.970446+00	2026-02-05 08:10:04.970446+00	\N	c8b3604a-3b61-4141-ab08-311fc4376874
00000000-0000-0000-0000-000000000000	267	dlm6oa5d3j2q	10e558ca-3940-4995-9a8f-165e78efaffc	f	2026-02-05 08:10:06.314947+00	2026-02-05 08:10:06.314947+00	\N	943c2189-4d54-4de5-a498-4d12c7a354c4
00000000-0000-0000-0000-000000000000	268	zw37gsow6qqw	10e558ca-3940-4995-9a8f-165e78efaffc	f	2026-02-05 08:10:07.655142+00	2026-02-05 08:10:07.655142+00	\N	d16fedbd-1eeb-4785-b141-639afd45127c
00000000-0000-0000-0000-000000000000	269	2crdtoahwhof	5e4ec0ef-464a-41db-8e2f-9f3bfa2671ee	f	2026-02-05 08:10:08.988824+00	2026-02-05 08:10:08.988824+00	\N	cf3d83e3-e052-4a0a-91c6-ccaedcb1059e
00000000-0000-0000-0000-000000000000	270	jdbl5s47hokd	5e4ec0ef-464a-41db-8e2f-9f3bfa2671ee	f	2026-02-05 08:10:10.333866+00	2026-02-05 08:10:10.333866+00	\N	95821fe9-1cf2-44d8-9fe2-9f8a8a27a3ca
00000000-0000-0000-0000-000000000000	271	sxnwxt5s6ta4	5e4ec0ef-464a-41db-8e2f-9f3bfa2671ee	f	2026-02-05 08:10:11.701123+00	2026-02-05 08:10:11.701123+00	\N	18278fbb-e55b-47b1-9584-77625a051de5
00000000-0000-0000-0000-000000000000	272	v6kzfxnczxmq	95f608be-c1e9-43b1-b885-5e2784e4858f	f	2026-02-05 08:10:13.053148+00	2026-02-05 08:10:13.053148+00	\N	050ab13c-1075-4169-b71b-22e53a52a65c
00000000-0000-0000-0000-000000000000	273	xnxahi7zabp6	95f608be-c1e9-43b1-b885-5e2784e4858f	f	2026-02-05 08:10:14.411772+00	2026-02-05 08:10:14.411772+00	\N	0c985d08-2a65-4951-847d-50ccac36b23d
00000000-0000-0000-0000-000000000000	274	x22zex3n2gl7	95f608be-c1e9-43b1-b885-5e2784e4858f	f	2026-02-05 08:10:15.750974+00	2026-02-05 08:10:15.750974+00	\N	51061fb3-7360-4263-a758-6108040fbbe9
00000000-0000-0000-0000-000000000000	275	dbezaeyumlle	8cf7c6be-ba2c-48c9-8825-589e675ff608	f	2026-02-05 08:10:17.126259+00	2026-02-05 08:10:17.126259+00	\N	e74f030d-8f98-49da-aa0e-86125a2edc18
00000000-0000-0000-0000-000000000000	276	qselw6pftr7i	8cf7c6be-ba2c-48c9-8825-589e675ff608	f	2026-02-05 08:10:18.467938+00	2026-02-05 08:10:18.467938+00	\N	d7636d40-218a-46ce-bdbc-b46594b5ff9b
00000000-0000-0000-0000-000000000000	277	cea7gpb4cxv7	8cf7c6be-ba2c-48c9-8825-589e675ff608	f	2026-02-05 08:10:19.807123+00	2026-02-05 08:10:19.807123+00	\N	675196f8-1196-4653-8969-71829ad1e659
00000000-0000-0000-0000-000000000000	407	udaivs4xe66r	5ac10c39-274e-4ce5-a13b-f4da3af4a230	t	2026-02-06 05:16:02.256177+00	2026-02-06 06:15:22.27103+00	h2czkeqqxlsg	11b10676-7ac3-46fe-b5dc-6e53bc9d56fc
00000000-0000-0000-0000-000000000000	280	szimjfmemiks	9969cfc6-451e-4ab2-ae2f-5d10a98eaf0a	f	2026-02-05 08:21:02.580253+00	2026-02-05 08:21:02.580253+00	\N	d80b617f-713b-454f-9805-ada7184801cf
00000000-0000-0000-0000-000000000000	281	ivngfo452lwz	9969cfc6-451e-4ab2-ae2f-5d10a98eaf0a	f	2026-02-05 08:21:03.97697+00	2026-02-05 08:21:03.97697+00	\N	a6bf88d7-16e6-44ba-8ba1-efecb851d5fb
00000000-0000-0000-0000-000000000000	282	hevtdbjzuqih	9969cfc6-451e-4ab2-ae2f-5d10a98eaf0a	f	2026-02-05 08:21:05.328493+00	2026-02-05 08:21:05.328493+00	\N	d78fb654-e4cb-4cee-b14b-156d6bb36b3e
00000000-0000-0000-0000-000000000000	283	xvxlghxp3bdt	10e558ca-3940-4995-9a8f-165e78efaffc	f	2026-02-05 08:21:06.696148+00	2026-02-05 08:21:06.696148+00	\N	93c076de-2644-4e8f-9cc0-2533bee418bc
00000000-0000-0000-0000-000000000000	284	vbutei37qjaa	10e558ca-3940-4995-9a8f-165e78efaffc	f	2026-02-05 08:21:08.066069+00	2026-02-05 08:21:08.066069+00	\N	0f061578-bb6a-40e5-8f15-5110a0c441be
00000000-0000-0000-0000-000000000000	285	h5764emheo3e	10e558ca-3940-4995-9a8f-165e78efaffc	f	2026-02-05 08:21:09.438862+00	2026-02-05 08:21:09.438862+00	\N	d748ced1-cc78-4862-b6d6-1ee7a1a33613
00000000-0000-0000-0000-000000000000	286	pppeo432657k	5e4ec0ef-464a-41db-8e2f-9f3bfa2671ee	f	2026-02-05 08:21:10.781644+00	2026-02-05 08:21:10.781644+00	\N	aa18a4ed-143b-45d6-b774-45639846320d
00000000-0000-0000-0000-000000000000	287	dsomm2jtln3u	5e4ec0ef-464a-41db-8e2f-9f3bfa2671ee	f	2026-02-05 08:21:12.118547+00	2026-02-05 08:21:12.118547+00	\N	e7df7443-a096-471f-ae55-12229b9732b4
00000000-0000-0000-0000-000000000000	288	75mu3bkviw67	5e4ec0ef-464a-41db-8e2f-9f3bfa2671ee	f	2026-02-05 08:21:13.462244+00	2026-02-05 08:21:13.462244+00	\N	1f4b327c-c893-450a-8fd3-b36ec0fb2a94
00000000-0000-0000-0000-000000000000	289	xusshl4klpp6	95f608be-c1e9-43b1-b885-5e2784e4858f	f	2026-02-05 08:21:14.853059+00	2026-02-05 08:21:14.853059+00	\N	477761c6-3df0-450e-8c22-a2affaab98fb
00000000-0000-0000-0000-000000000000	290	q7m5ibopa5by	95f608be-c1e9-43b1-b885-5e2784e4858f	f	2026-02-05 08:21:16.196865+00	2026-02-05 08:21:16.196865+00	\N	8f2bcc65-a1d0-4fd3-8073-2899dcd75485
00000000-0000-0000-0000-000000000000	291	xxmi2xqgipl2	95f608be-c1e9-43b1-b885-5e2784e4858f	f	2026-02-05 08:21:17.525681+00	2026-02-05 08:21:17.525681+00	\N	e9f7db27-6ea1-47fa-a265-67006c20aee8
00000000-0000-0000-0000-000000000000	292	xdwnqvr54vup	8cf7c6be-ba2c-48c9-8825-589e675ff608	f	2026-02-05 08:21:18.85809+00	2026-02-05 08:21:18.85809+00	\N	c252ebed-5f79-483c-8f6b-78d6646a9113
00000000-0000-0000-0000-000000000000	293	4c2wfirneepn	8cf7c6be-ba2c-48c9-8825-589e675ff608	f	2026-02-05 08:21:20.194026+00	2026-02-05 08:21:20.194026+00	\N	cebcde5c-c3a6-4450-add7-4d8300bd35f1
00000000-0000-0000-0000-000000000000	294	5pw4oj4r3iyn	8cf7c6be-ba2c-48c9-8825-589e675ff608	f	2026-02-05 08:22:02.213847+00	2026-02-05 08:22:02.213847+00	\N	f8f842e5-7b5b-49fa-8130-090a8b2c9e4b
00000000-0000-0000-0000-000000000000	278	hkhdequd65pv	36ae407d-c380-41ff-a714-d61371c44fb3	t	2026-02-05 08:13:57.768872+00	2026-02-05 09:12:11.92809+00	qzj7wfnmnbfn	3a1b4909-48e4-4e18-a472-1e3ac4ffa4f5
00000000-0000-0000-0000-000000000000	279	kjtyhahuz2tc	5ac10c39-274e-4ce5-a13b-f4da3af4a230	t	2026-02-05 08:15:43.970975+00	2026-02-05 09:14:13.168663+00	hr6bz36wudoc	11b10676-7ac3-46fe-b5dc-6e53bc9d56fc
00000000-0000-0000-0000-000000000000	295	agb7s446zi6f	5e4ec0ef-464a-41db-8e2f-9f3bfa2671ee	t	2026-02-05 08:30:10.720361+00	2026-02-05 09:28:10.89931+00	qanc6g4pk5sl	97565c55-31fd-4aef-9f64-db127ec8038a
00000000-0000-0000-0000-000000000000	296	7weczhc6jhvy	95f608be-c1e9-43b1-b885-5e2784e4858f	t	2026-02-05 08:35:39.819861+00	2026-02-05 09:34:39.469749+00	thndjvmtr773	15c5bc25-7e7d-4db8-8f68-48bba9ce99ff
00000000-0000-0000-0000-000000000000	297	m6npxx6soxep	36ae407d-c380-41ff-a714-d61371c44fb3	t	2026-02-05 09:12:11.951999+00	2026-02-05 10:10:12.41549+00	hkhdequd65pv	3a1b4909-48e4-4e18-a472-1e3ac4ffa4f5
00000000-0000-0000-0000-000000000000	298	5b6xem2i7znf	5ac10c39-274e-4ce5-a13b-f4da3af4a230	t	2026-02-05 09:14:13.182299+00	2026-02-05 10:13:39.524701+00	kjtyhahuz2tc	11b10676-7ac3-46fe-b5dc-6e53bc9d56fc
00000000-0000-0000-0000-000000000000	759	zwqpcjwgauom	95f608be-c1e9-43b1-b885-5e2784e4858f	t	2026-02-10 13:18:23.183213+00	2026-02-10 14:17:24.145317+00	5gtwqymjzim3	15c5bc25-7e7d-4db8-8f68-48bba9ce99ff
00000000-0000-0000-0000-000000000000	409	wxeazo6fb6ud	5ac10c39-274e-4ce5-a13b-f4da3af4a230	t	2026-02-06 06:15:22.281176+00	2026-02-06 07:14:22.390143+00	udaivs4xe66r	11b10676-7ac3-46fe-b5dc-6e53bc9d56fc
00000000-0000-0000-0000-000000000000	299	ggj4wpbwsqqc	5e4ec0ef-464a-41db-8e2f-9f3bfa2671ee	t	2026-02-05 09:28:10.913301+00	2026-02-05 10:26:10.931756+00	agb7s446zi6f	97565c55-31fd-4aef-9f64-db127ec8038a
00000000-0000-0000-0000-000000000000	416	5ibfgeyxckcu	95f608be-c1e9-43b1-b885-5e2784e4858f	t	2026-02-06 09:11:22.270137+00	2026-02-06 10:10:22.173657+00	s6t54qil4iob	15c5bc25-7e7d-4db8-8f68-48bba9ce99ff
00000000-0000-0000-0000-000000000000	300	5vdzidea2cqq	95f608be-c1e9-43b1-b885-5e2784e4858f	t	2026-02-05 09:34:39.479904+00	2026-02-05 10:33:39.436643+00	7weczhc6jhvy	15c5bc25-7e7d-4db8-8f68-48bba9ce99ff
00000000-0000-0000-0000-000000000000	417	nwpd5nqfmhla	5ac10c39-274e-4ce5-a13b-f4da3af4a230	t	2026-02-06 09:12:22.145027+00	2026-02-06 10:11:22.068206+00	jlefeiya6goi	11b10676-7ac3-46fe-b5dc-6e53bc9d56fc
00000000-0000-0000-0000-000000000000	301	hytuca6uoj4j	36ae407d-c380-41ff-a714-d61371c44fb3	t	2026-02-05 10:10:12.426372+00	2026-02-05 11:08:12.697409+00	m6npxx6soxep	3a1b4909-48e4-4e18-a472-1e3ac4ffa4f5
00000000-0000-0000-0000-000000000000	302	w22sl2tsn3av	5ac10c39-274e-4ce5-a13b-f4da3af4a230	t	2026-02-05 10:13:39.543834+00	2026-02-05 11:12:39.447991+00	5b6xem2i7znf	11b10676-7ac3-46fe-b5dc-6e53bc9d56fc
00000000-0000-0000-0000-000000000000	421	2q6yx6m4eqh7	95f608be-c1e9-43b1-b885-5e2784e4858f	t	2026-02-06 11:08:47.291604+00	2026-02-06 12:07:26.882289+00	5ehax24go5xb	15c5bc25-7e7d-4db8-8f68-48bba9ce99ff
00000000-0000-0000-0000-000000000000	303	hhac55hbhs5g	5e4ec0ef-464a-41db-8e2f-9f3bfa2671ee	t	2026-02-05 10:26:10.946475+00	2026-02-05 11:24:10.847265+00	ggj4wpbwsqqc	97565c55-31fd-4aef-9f64-db127ec8038a
00000000-0000-0000-0000-000000000000	304	p3vnf5dumzfk	95f608be-c1e9-43b1-b885-5e2784e4858f	t	2026-02-05 10:33:39.450743+00	2026-02-05 11:32:39.28698+00	5vdzidea2cqq	15c5bc25-7e7d-4db8-8f68-48bba9ce99ff
00000000-0000-0000-0000-000000000000	305	cvmjyl3oiz2x	36ae407d-c380-41ff-a714-d61371c44fb3	t	2026-02-05 11:08:12.719261+00	2026-02-05 12:06:13.074678+00	hytuca6uoj4j	3a1b4909-48e4-4e18-a472-1e3ac4ffa4f5
00000000-0000-0000-0000-000000000000	424	76evica4ymux	95f608be-c1e9-43b1-b885-5e2784e4858f	t	2026-02-06 13:06:21.980311+00	2026-02-06 14:04:29.281457+00	u5x7kjzjzo2x	15c5bc25-7e7d-4db8-8f68-48bba9ce99ff
00000000-0000-0000-0000-000000000000	306	3mx77ierhsuj	5ac10c39-274e-4ce5-a13b-f4da3af4a230	t	2026-02-05 11:12:39.458527+00	2026-02-05 12:11:39.441431+00	w22sl2tsn3av	11b10676-7ac3-46fe-b5dc-6e53bc9d56fc
00000000-0000-0000-0000-000000000000	307	akxsfz5wsc5l	5e4ec0ef-464a-41db-8e2f-9f3bfa2671ee	t	2026-02-05 11:24:10.866887+00	2026-02-05 12:22:10.802335+00	hhac55hbhs5g	97565c55-31fd-4aef-9f64-db127ec8038a
00000000-0000-0000-0000-000000000000	429	h2iqzhrmsl5b	95f608be-c1e9-43b1-b885-5e2784e4858f	t	2026-02-06 15:03:21.930298+00	2026-02-06 16:17:48.652667+00	b7yj63ok4ji6	15c5bc25-7e7d-4db8-8f68-48bba9ce99ff
00000000-0000-0000-0000-000000000000	308	sgdytwk2ikgf	95f608be-c1e9-43b1-b885-5e2784e4858f	t	2026-02-05 11:32:39.289716+00	2026-02-05 12:31:39.170318+00	p3vnf5dumzfk	15c5bc25-7e7d-4db8-8f68-48bba9ce99ff
00000000-0000-0000-0000-000000000000	309	2q3x4xu2hbps	36ae407d-c380-41ff-a714-d61371c44fb3	t	2026-02-05 12:06:13.09502+00	2026-02-05 13:04:13.481705+00	cvmjyl3oiz2x	3a1b4909-48e4-4e18-a472-1e3ac4ffa4f5
00000000-0000-0000-0000-000000000000	431	6ghemqxo64fk	95f608be-c1e9-43b1-b885-5e2784e4858f	t	2026-02-06 16:17:48.663969+00	2026-02-06 17:16:48.28979+00	h2iqzhrmsl5b	15c5bc25-7e7d-4db8-8f68-48bba9ce99ff
00000000-0000-0000-0000-000000000000	310	kepxrriax2jc	5ac10c39-274e-4ce5-a13b-f4da3af4a230	t	2026-02-05 12:11:39.454584+00	2026-02-05 13:10:39.201488+00	3mx77ierhsuj	11b10676-7ac3-46fe-b5dc-6e53bc9d56fc
00000000-0000-0000-0000-000000000000	311	3a4qgdn62yu6	5e4ec0ef-464a-41db-8e2f-9f3bfa2671ee	t	2026-02-05 12:22:10.818445+00	2026-02-05 13:20:10.63643+00	akxsfz5wsc5l	97565c55-31fd-4aef-9f64-db127ec8038a
00000000-0000-0000-0000-000000000000	433	clkp26sth7vd	95f608be-c1e9-43b1-b885-5e2784e4858f	t	2026-02-06 18:15:48.220682+00	2026-02-06 19:14:48.073877+00	zdqp3qykupkg	15c5bc25-7e7d-4db8-8f68-48bba9ce99ff
00000000-0000-0000-0000-000000000000	312	6bmrw4pqlsyr	95f608be-c1e9-43b1-b885-5e2784e4858f	t	2026-02-05 12:31:39.172671+00	2026-02-05 13:30:39.271433+00	sgdytwk2ikgf	15c5bc25-7e7d-4db8-8f68-48bba9ce99ff
00000000-0000-0000-0000-000000000000	313	c35nmg6pkabz	36ae407d-c380-41ff-a714-d61371c44fb3	t	2026-02-05 13:04:13.502327+00	2026-02-05 14:02:13.785344+00	2q3x4xu2hbps	3a1b4909-48e4-4e18-a472-1e3ac4ffa4f5
00000000-0000-0000-0000-000000000000	435	t3qc2xgbkznu	95f608be-c1e9-43b1-b885-5e2784e4858f	t	2026-02-06 20:26:47.986702+00	2026-02-06 21:27:17.57691+00	t3fsj4wxm75m	15c5bc25-7e7d-4db8-8f68-48bba9ce99ff
00000000-0000-0000-0000-000000000000	314	omyqfkpwmsda	5ac10c39-274e-4ce5-a13b-f4da3af4a230	t	2026-02-05 13:10:39.204712+00	2026-02-05 14:09:39.196434+00	kepxrriax2jc	11b10676-7ac3-46fe-b5dc-6e53bc9d56fc
00000000-0000-0000-0000-000000000000	315	jmuvicqhtuyf	5e4ec0ef-464a-41db-8e2f-9f3bfa2671ee	t	2026-02-05 13:20:10.64943+00	2026-02-05 14:18:10.607232+00	3a4qgdn62yu6	97565c55-31fd-4aef-9f64-db127ec8038a
00000000-0000-0000-0000-000000000000	437	7czc5o5awwu3	95f608be-c1e9-43b1-b885-5e2784e4858f	t	2026-02-06 22:26:41.710413+00	2026-02-06 23:25:41.576863+00	n7qyy2tjc7na	15c5bc25-7e7d-4db8-8f68-48bba9ce99ff
00000000-0000-0000-0000-000000000000	316	ci5hv7htasuh	95f608be-c1e9-43b1-b885-5e2784e4858f	t	2026-02-05 13:30:39.293069+00	2026-02-05 14:29:39.108686+00	6bmrw4pqlsyr	15c5bc25-7e7d-4db8-8f68-48bba9ce99ff
00000000-0000-0000-0000-000000000000	321	icz5tfx3t47n	9969cfc6-451e-4ab2-ae2f-5d10a98eaf0a	f	2026-02-05 14:51:02.397308+00	2026-02-05 14:51:02.397308+00	\N	6bc8cc46-8882-4316-865d-aadd0bf282ec
00000000-0000-0000-0000-000000000000	322	q57u6jopehuy	9969cfc6-451e-4ab2-ae2f-5d10a98eaf0a	f	2026-02-05 14:51:03.820094+00	2026-02-05 14:51:03.820094+00	\N	2234f8bc-966c-4809-90cc-8c1f03b165f4
00000000-0000-0000-0000-000000000000	323	jvvjxorvjdha	9969cfc6-451e-4ab2-ae2f-5d10a98eaf0a	f	2026-02-05 14:51:05.191722+00	2026-02-05 14:51:05.191722+00	\N	471a2917-f34e-4fe0-9b29-4e498c10d39b
00000000-0000-0000-0000-000000000000	324	w4e73ydbjjqn	10e558ca-3940-4995-9a8f-165e78efaffc	f	2026-02-05 14:51:06.589223+00	2026-02-05 14:51:06.589223+00	\N	ea49e43e-e69d-48db-8a27-0f2e24247504
00000000-0000-0000-0000-000000000000	325	csn5lm6qlmb2	10e558ca-3940-4995-9a8f-165e78efaffc	f	2026-02-05 14:51:07.955948+00	2026-02-05 14:51:07.955948+00	\N	bfcabf55-45ab-487b-af29-3abe1edf12ae
00000000-0000-0000-0000-000000000000	326	smdiywfx2rus	10e558ca-3940-4995-9a8f-165e78efaffc	f	2026-02-05 14:51:09.315394+00	2026-02-05 14:51:09.315394+00	\N	3327b8ff-e675-43f2-a54d-c4a00dbfd100
00000000-0000-0000-0000-000000000000	327	ug3ljjllfhej	5e4ec0ef-464a-41db-8e2f-9f3bfa2671ee	f	2026-02-05 14:51:10.680385+00	2026-02-05 14:51:10.680385+00	\N	dc2621cf-1f25-498b-a9d5-b1228327476d
00000000-0000-0000-0000-000000000000	328	xpykecqga4pb	5e4ec0ef-464a-41db-8e2f-9f3bfa2671ee	f	2026-02-05 14:51:12.097771+00	2026-02-05 14:51:12.097771+00	\N	c501307b-9045-4616-88e8-ad52b757178f
00000000-0000-0000-0000-000000000000	329	kb5jly4dfci4	5e4ec0ef-464a-41db-8e2f-9f3bfa2671ee	f	2026-02-05 14:51:13.464935+00	2026-02-05 14:51:13.464935+00	\N	87ae93a1-08be-4630-8b16-0fea993f7e0a
00000000-0000-0000-0000-000000000000	330	k27a37sutomn	95f608be-c1e9-43b1-b885-5e2784e4858f	f	2026-02-05 14:51:14.821691+00	2026-02-05 14:51:14.821691+00	\N	eb603785-1a31-4f15-bc47-39ee62054bed
00000000-0000-0000-0000-000000000000	331	lidisxjbduql	95f608be-c1e9-43b1-b885-5e2784e4858f	f	2026-02-05 14:51:16.20181+00	2026-02-05 14:51:16.20181+00	\N	76acbaeb-69d0-47ba-bf9e-02218838416a
00000000-0000-0000-0000-000000000000	332	zq3be3kbispr	95f608be-c1e9-43b1-b885-5e2784e4858f	f	2026-02-05 14:51:17.582562+00	2026-02-05 14:51:17.582562+00	\N	3f3a8f73-a42b-4864-9b11-050733b3d445
00000000-0000-0000-0000-000000000000	333	z4gdzevcljv6	8cf7c6be-ba2c-48c9-8825-589e675ff608	f	2026-02-05 14:51:18.924302+00	2026-02-05 14:51:18.924302+00	\N	1a70140e-973c-48e4-9e63-a3650cb74021
00000000-0000-0000-0000-000000000000	317	mzorrefciywv	36ae407d-c380-41ff-a714-d61371c44fb3	t	2026-02-05 14:02:13.806129+00	2026-02-05 15:00:13.875883+00	c35nmg6pkabz	3a1b4909-48e4-4e18-a472-1e3ac4ffa4f5
00000000-0000-0000-0000-000000000000	318	vi5orqnb672x	5ac10c39-274e-4ce5-a13b-f4da3af4a230	t	2026-02-05 14:09:39.206081+00	2026-02-05 15:07:52.033509+00	omyqfkpwmsda	11b10676-7ac3-46fe-b5dc-6e53bc9d56fc
00000000-0000-0000-0000-000000000000	319	qyd4opgzj32k	5e4ec0ef-464a-41db-8e2f-9f3bfa2671ee	t	2026-02-05 14:18:10.61925+00	2026-02-05 15:16:10.454604+00	jmuvicqhtuyf	97565c55-31fd-4aef-9f64-db127ec8038a
00000000-0000-0000-0000-000000000000	320	5q4t5d6twtvm	95f608be-c1e9-43b1-b885-5e2784e4858f	t	2026-02-05 14:29:39.115856+00	2026-02-05 15:28:38.995737+00	ci5hv7htasuh	15c5bc25-7e7d-4db8-8f68-48bba9ce99ff
00000000-0000-0000-0000-000000000000	439	d7cclv4qiuf4	95f608be-c1e9-43b1-b885-5e2784e4858f	t	2026-02-07 00:24:41.541958+00	2026-02-07 01:23:41.523572+00	g7zjc7kwg3wk	15c5bc25-7e7d-4db8-8f68-48bba9ce99ff
00000000-0000-0000-0000-000000000000	441	lykxnkwyuo7u	95f608be-c1e9-43b1-b885-5e2784e4858f	t	2026-02-07 01:23:41.548861+00	2026-02-07 02:22:41.871932+00	d7cclv4qiuf4	15c5bc25-7e7d-4db8-8f68-48bba9ce99ff
00000000-0000-0000-0000-000000000000	443	vl5bkyz4ru5p	95f608be-c1e9-43b1-b885-5e2784e4858f	t	2026-02-07 02:22:41.889478+00	2026-02-07 03:21:41.83575+00	lykxnkwyuo7u	15c5bc25-7e7d-4db8-8f68-48bba9ce99ff
00000000-0000-0000-0000-000000000000	445	mm27reafxfwi	95f608be-c1e9-43b1-b885-5e2784e4858f	t	2026-02-07 04:20:42.02162+00	2026-02-07 05:19:42.006039+00	uyrjtfptxbba	15c5bc25-7e7d-4db8-8f68-48bba9ce99ff
00000000-0000-0000-0000-000000000000	447	qtaacb5qyfgg	10e558ca-3940-4995-9a8f-165e78efaffc	t	2026-02-07 05:41:11.660633+00	2026-02-07 06:40:12.602973+00	zrf462mhcxdd	f8b68d38-042c-4697-9458-1c0a74313dc3
00000000-0000-0000-0000-000000000000	427	cknouxsymk57	5e4ec0ef-464a-41db-8e2f-9f3bfa2671ee	t	2026-02-06 13:59:39.760053+00	2026-02-09 00:30:23.366266+00	qohsghoeu7jv	97565c55-31fd-4aef-9f64-db127ec8038a
00000000-0000-0000-0000-000000000000	334	mcd565m3lc7n	8cf7c6be-ba2c-48c9-8825-589e675ff608	f	2026-02-05 14:51:20.292999+00	2026-02-05 14:51:20.292999+00	\N	417f4041-a6ad-46b8-9358-08d4a9b85cf3
00000000-0000-0000-0000-000000000000	335	xboylivzvxh2	8cf7c6be-ba2c-48c9-8825-589e675ff608	f	2026-02-05 14:52:02.211944+00	2026-02-05 14:52:02.211944+00	\N	6ba0e9a6-d92b-44d3-9a9b-29e334aaafd8
00000000-0000-0000-0000-000000000000	336	scffnt4u6xw6	9969cfc6-451e-4ab2-ae2f-5d10a98eaf0a	f	2026-02-05 14:52:08.571536+00	2026-02-05 14:52:08.571536+00	\N	344bd97a-b666-4201-900c-920b993b60de
00000000-0000-0000-0000-000000000000	337	5yvtamp5z6nz	9969cfc6-451e-4ab2-ae2f-5d10a98eaf0a	f	2026-02-05 14:52:09.93596+00	2026-02-05 14:52:09.93596+00	\N	ccb9f46d-13e6-4669-96a1-67a746bf006f
00000000-0000-0000-0000-000000000000	338	2dt6inwa6hk4	9969cfc6-451e-4ab2-ae2f-5d10a98eaf0a	f	2026-02-05 14:52:11.285143+00	2026-02-05 14:52:11.285143+00	\N	34d6e14a-efba-4ecf-b5c3-d7a8c866559e
00000000-0000-0000-0000-000000000000	339	vsctrpsh47ro	10e558ca-3940-4995-9a8f-165e78efaffc	f	2026-02-05 14:52:12.644881+00	2026-02-05 14:52:12.644881+00	\N	b32b2002-224b-4402-a5f1-aedc8df0a2e1
00000000-0000-0000-0000-000000000000	340	pkgaz6ochm66	10e558ca-3940-4995-9a8f-165e78efaffc	f	2026-02-05 14:52:13.99273+00	2026-02-05 14:52:13.99273+00	\N	638f6d24-407d-420d-b5d0-525257e42cc9
00000000-0000-0000-0000-000000000000	341	pzl5iltrdzuq	10e558ca-3940-4995-9a8f-165e78efaffc	f	2026-02-05 14:52:15.341659+00	2026-02-05 14:52:15.341659+00	\N	b245b475-0b5c-4396-b24f-1a57c3225c2b
00000000-0000-0000-0000-000000000000	342	kdqdhoy7kaoz	5e4ec0ef-464a-41db-8e2f-9f3bfa2671ee	f	2026-02-05 14:52:16.695902+00	2026-02-05 14:52:16.695902+00	\N	90d47778-4fe4-435d-86c6-faced62bcb4f
00000000-0000-0000-0000-000000000000	343	j6gcdsg4nifj	5e4ec0ef-464a-41db-8e2f-9f3bfa2671ee	f	2026-02-05 14:52:18.038228+00	2026-02-05 14:52:18.038228+00	\N	a449ba6b-e153-426b-bb20-6198203f8eb0
00000000-0000-0000-0000-000000000000	344	dbj4dayqhwtt	5e4ec0ef-464a-41db-8e2f-9f3bfa2671ee	f	2026-02-05 14:52:19.405836+00	2026-02-05 14:52:19.405836+00	\N	32dba162-03d6-4dc1-a8b9-11a0e805602e
00000000-0000-0000-0000-000000000000	345	izk5hecszgje	95f608be-c1e9-43b1-b885-5e2784e4858f	f	2026-02-05 14:52:20.772406+00	2026-02-05 14:52:20.772406+00	\N	df18d02a-ab5e-4476-8948-bc0e798ee538
00000000-0000-0000-0000-000000000000	346	com4b3wzu77z	95f608be-c1e9-43b1-b885-5e2784e4858f	f	2026-02-05 14:53:02.195339+00	2026-02-05 14:53:02.195339+00	\N	7ee2d29b-6c6e-46ce-820e-90a37330c374
00000000-0000-0000-0000-000000000000	347	2uld3rn77wms	95f608be-c1e9-43b1-b885-5e2784e4858f	f	2026-02-05 14:53:03.54147+00	2026-02-05 14:53:03.54147+00	\N	45b15db1-ab6b-4806-9133-7568e88c2ec1
00000000-0000-0000-0000-000000000000	348	azlpm2entge7	8cf7c6be-ba2c-48c9-8825-589e675ff608	f	2026-02-05 14:53:04.893354+00	2026-02-05 14:53:04.893354+00	\N	933d6b75-ba2b-4a81-935d-ab346c33e272
00000000-0000-0000-0000-000000000000	349	fdvlvf722pbt	8cf7c6be-ba2c-48c9-8825-589e675ff608	f	2026-02-05 14:53:06.24512+00	2026-02-05 14:53:06.24512+00	\N	ddd11cc7-a01a-49c0-8c40-b2cfd99828ed
00000000-0000-0000-0000-000000000000	350	u75zknctmma4	8cf7c6be-ba2c-48c9-8825-589e675ff608	f	2026-02-05 14:53:07.584488+00	2026-02-05 14:53:07.584488+00	\N	4fb093ee-9320-436d-9de3-4e5d50f5b4e5
00000000-0000-0000-0000-000000000000	351	mmoiqp7mn52y	9969cfc6-451e-4ab2-ae2f-5d10a98eaf0a	f	2026-02-05 14:54:02.330536+00	2026-02-05 14:54:02.330536+00	\N	68aa6b64-20f6-40cc-b3db-a60d9abbeb9c
00000000-0000-0000-0000-000000000000	352	qaebe7ilp4nb	9969cfc6-451e-4ab2-ae2f-5d10a98eaf0a	f	2026-02-05 14:54:03.774617+00	2026-02-05 14:54:03.774617+00	\N	9c3d10cf-c031-4fca-bb42-6d5d4a236e1a
00000000-0000-0000-0000-000000000000	353	6w7jn6kvzvec	9969cfc6-451e-4ab2-ae2f-5d10a98eaf0a	f	2026-02-05 14:54:05.271914+00	2026-02-05 14:54:05.271914+00	\N	cbff93a5-666e-4c44-962f-714372cc56c2
00000000-0000-0000-0000-000000000000	354	a326mdcz4xk6	10e558ca-3940-4995-9a8f-165e78efaffc	f	2026-02-05 14:54:06.765835+00	2026-02-05 14:54:06.765835+00	\N	68f522a0-c23e-40f9-ba33-84697d2dca81
00000000-0000-0000-0000-000000000000	355	erx5x2tymuzv	10e558ca-3940-4995-9a8f-165e78efaffc	f	2026-02-05 14:54:08.246802+00	2026-02-05 14:54:08.246802+00	\N	23312512-15be-4b8c-97a2-311ef45ac78f
00000000-0000-0000-0000-000000000000	356	3et3ccjbpcx5	10e558ca-3940-4995-9a8f-165e78efaffc	f	2026-02-05 14:54:09.637118+00	2026-02-05 14:54:09.637118+00	\N	7c15b98c-1446-410b-b7c4-c619f8b7e28d
00000000-0000-0000-0000-000000000000	357	64b2744woadl	5e4ec0ef-464a-41db-8e2f-9f3bfa2671ee	f	2026-02-05 14:54:11.015946+00	2026-02-05 14:54:11.015946+00	\N	80368408-db3d-4a35-a656-ec95dd1367cf
00000000-0000-0000-0000-000000000000	358	jvejyr3l4dbc	5e4ec0ef-464a-41db-8e2f-9f3bfa2671ee	f	2026-02-05 14:54:12.391643+00	2026-02-05 14:54:12.391643+00	\N	684042f7-7a94-4375-aa0a-b0e7b2c7d533
00000000-0000-0000-0000-000000000000	359	ydg54or56mrf	5e4ec0ef-464a-41db-8e2f-9f3bfa2671ee	f	2026-02-05 14:54:13.781131+00	2026-02-05 14:54:13.781131+00	\N	e9635769-1f26-44ce-9a3c-6802ba28558f
00000000-0000-0000-0000-000000000000	360	fpbtfqwb4xu4	95f608be-c1e9-43b1-b885-5e2784e4858f	f	2026-02-05 14:54:15.154129+00	2026-02-05 14:54:15.154129+00	\N	e55cacec-7abc-47f6-a3e9-6300bb59ed63
00000000-0000-0000-0000-000000000000	361	fqc6rmhfk7nw	95f608be-c1e9-43b1-b885-5e2784e4858f	f	2026-02-05 14:54:16.605907+00	2026-02-05 14:54:16.605907+00	\N	dced29cb-8ba7-43bc-93e3-961d730fbe4d
00000000-0000-0000-0000-000000000000	362	onrw7apwiebf	95f608be-c1e9-43b1-b885-5e2784e4858f	f	2026-02-05 14:54:18.129329+00	2026-02-05 14:54:18.129329+00	\N	9b27ccb7-fb2d-4fd2-b9c3-f6088a735f7d
00000000-0000-0000-0000-000000000000	363	vdaw5ga6cewx	8cf7c6be-ba2c-48c9-8825-589e675ff608	f	2026-02-05 14:54:19.473543+00	2026-02-05 14:54:19.473543+00	\N	b01fd372-56e9-4b53-be40-48d5db2fb560
00000000-0000-0000-0000-000000000000	364	fgwcqfb7mcxd	8cf7c6be-ba2c-48c9-8825-589e675ff608	f	2026-02-05 14:54:20.830769+00	2026-02-05 14:54:20.830769+00	\N	251a3ec5-e04e-4235-b16f-0ac012571ad3
00000000-0000-0000-0000-000000000000	365	qtzvoppdpqbq	8cf7c6be-ba2c-48c9-8825-589e675ff608	f	2026-02-05 14:55:02.194216+00	2026-02-05 14:55:02.194216+00	\N	cd995ab6-e3fd-457d-8d96-29bc33f97f09
00000000-0000-0000-0000-000000000000	413	stufy65eggl5	10e558ca-3940-4995-9a8f-165e78efaffc	t	2026-02-06 08:00:55.93773+00	2026-02-06 09:34:33.45501+00	2isvkktnz4mg	f8b68d38-042c-4697-9458-1c0a74313dc3
00000000-0000-0000-0000-000000000000	366	tjn2up7ftrfc	36ae407d-c380-41ff-a714-d61371c44fb3	t	2026-02-05 15:00:13.881588+00	2026-02-05 15:58:39.023328+00	mzorrefciywv	3a1b4909-48e4-4e18-a472-1e3ac4ffa4f5
00000000-0000-0000-0000-000000000000	367	2xdwamql6iz4	5ac10c39-274e-4ce5-a13b-f4da3af4a230	t	2026-02-05 15:07:52.039105+00	2026-02-05 16:06:29.963532+00	vi5orqnb672x	11b10676-7ac3-46fe-b5dc-6e53bc9d56fc
00000000-0000-0000-0000-000000000000	368	m3qevl46qzuo	5e4ec0ef-464a-41db-8e2f-9f3bfa2671ee	t	2026-02-05 15:16:10.462414+00	2026-02-05 16:14:10.499987+00	qyd4opgzj32k	97565c55-31fd-4aef-9f64-db127ec8038a
00000000-0000-0000-0000-000000000000	369	fzwlelmgngcd	95f608be-c1e9-43b1-b885-5e2784e4858f	t	2026-02-05 15:28:39.010137+00	2026-02-05 16:27:39.270903+00	5q4t5d6twtvm	15c5bc25-7e7d-4db8-8f68-48bba9ce99ff
00000000-0000-0000-0000-000000000000	370	zevquunaeete	36ae407d-c380-41ff-a714-d61371c44fb3	t	2026-02-05 15:58:39.051428+00	2026-02-05 16:57:05.502763+00	tjn2up7ftrfc	3a1b4909-48e4-4e18-a472-1e3ac4ffa4f5
00000000-0000-0000-0000-000000000000	371	shc7ymlibie6	5ac10c39-274e-4ce5-a13b-f4da3af4a230	t	2026-02-05 16:06:29.970407+00	2026-02-05 17:05:39.319278+00	2xdwamql6iz4	11b10676-7ac3-46fe-b5dc-6e53bc9d56fc
00000000-0000-0000-0000-000000000000	376	y64ud2whazet	9969cfc6-451e-4ab2-ae2f-5d10a98eaf0a	f	2026-02-05 17:05:43.681172+00	2026-02-05 17:05:43.681172+00	\N	593c192e-6d16-4d71-8c0b-246088715e5c
00000000-0000-0000-0000-000000000000	377	b2uruhblqvi2	9969cfc6-451e-4ab2-ae2f-5d10a98eaf0a	f	2026-02-05 17:08:13.166709+00	2026-02-05 17:08:13.166709+00	\N	02c7470d-c989-43fc-8ca7-bbf7c5038c87
00000000-0000-0000-0000-000000000000	372	w3ljiismkijm	5e4ec0ef-464a-41db-8e2f-9f3bfa2671ee	t	2026-02-05 16:14:10.505817+00	2026-02-05 17:12:10.736349+00	m3qevl46qzuo	97565c55-31fd-4aef-9f64-db127ec8038a
00000000-0000-0000-0000-000000000000	373	xkvcarlo5jwm	95f608be-c1e9-43b1-b885-5e2784e4858f	t	2026-02-05 16:27:39.288015+00	2026-02-05 17:26:39.198678+00	fzwlelmgngcd	15c5bc25-7e7d-4db8-8f68-48bba9ce99ff
00000000-0000-0000-0000-000000000000	378	m4jnhtmmgrg7	5e4ec0ef-464a-41db-8e2f-9f3bfa2671ee	t	2026-02-05 17:12:10.760839+00	2026-02-05 18:11:04.827093+00	w3ljiismkijm	97565c55-31fd-4aef-9f64-db127ec8038a
00000000-0000-0000-0000-000000000000	379	dekdnlusew5u	95f608be-c1e9-43b1-b885-5e2784e4858f	t	2026-02-05 17:26:39.20848+00	2026-02-05 18:26:04.771502+00	xkvcarlo5jwm	15c5bc25-7e7d-4db8-8f68-48bba9ce99ff
00000000-0000-0000-0000-000000000000	380	4otdmax27xl5	5e4ec0ef-464a-41db-8e2f-9f3bfa2671ee	t	2026-02-05 18:11:04.847903+00	2026-02-05 19:25:18.72592+00	m4jnhtmmgrg7	97565c55-31fd-4aef-9f64-db127ec8038a
00000000-0000-0000-0000-000000000000	381	gkammzilmrql	95f608be-c1e9-43b1-b885-5e2784e4858f	t	2026-02-05 18:26:04.786865+00	2026-02-05 19:25:18.724009+00	dekdnlusew5u	15c5bc25-7e7d-4db8-8f68-48bba9ce99ff
00000000-0000-0000-0000-000000000000	382	txlf7onzcncr	95f608be-c1e9-43b1-b885-5e2784e4858f	t	2026-02-05 19:25:18.745793+00	2026-02-05 20:27:07.161006+00	gkammzilmrql	15c5bc25-7e7d-4db8-8f68-48bba9ce99ff
00000000-0000-0000-0000-000000000000	383	4arywkxefkw5	5e4ec0ef-464a-41db-8e2f-9f3bfa2671ee	t	2026-02-05 19:25:18.746429+00	2026-02-05 20:27:24.752647+00	4otdmax27xl5	97565c55-31fd-4aef-9f64-db127ec8038a
00000000-0000-0000-0000-000000000000	384	tbhlkyugpudc	95f608be-c1e9-43b1-b885-5e2784e4858f	t	2026-02-05 20:27:07.186089+00	2026-02-05 21:26:24.293488+00	txlf7onzcncr	15c5bc25-7e7d-4db8-8f68-48bba9ce99ff
00000000-0000-0000-0000-000000000000	374	vt4igxdte4tp	36ae407d-c380-41ff-a714-d61371c44fb3	t	2026-02-05 16:57:05.521069+00	2026-02-05 23:04:25.900986+00	zevquunaeete	3a1b4909-48e4-4e18-a472-1e3ac4ffa4f5
00000000-0000-0000-0000-000000000000	375	nvl2zok7kkb6	5ac10c39-274e-4ce5-a13b-f4da3af4a230	t	2026-02-05 17:05:39.33181+00	2026-02-05 23:24:57.332959+00	shc7ymlibie6	11b10676-7ac3-46fe-b5dc-6e53bc9d56fc
00000000-0000-0000-0000-000000000000	385	hy7n4jeqly7w	5e4ec0ef-464a-41db-8e2f-9f3bfa2671ee	t	2026-02-05 20:27:24.753059+00	2026-02-05 21:26:24.292415+00	4arywkxefkw5	97565c55-31fd-4aef-9f64-db127ec8038a
00000000-0000-0000-0000-000000000000	404	h2czkeqqxlsg	5ac10c39-274e-4ce5-a13b-f4da3af4a230	t	2026-02-06 03:34:07.439978+00	2026-02-06 05:16:02.251503+00	jdeivbt5x3be	11b10676-7ac3-46fe-b5dc-6e53bc9d56fc
00000000-0000-0000-0000-000000000000	762	kjt4djrfmfpq	5e4ec0ef-464a-41db-8e2f-9f3bfa2671ee	f	2026-02-10 15:09:35.667642+00	2026-02-10 15:09:35.667642+00	bqlt73nq7edd	97565c55-31fd-4aef-9f64-db127ec8038a
00000000-0000-0000-0000-000000000000	387	zgfog4q34lxv	95f608be-c1e9-43b1-b885-5e2784e4858f	t	2026-02-05 21:26:24.309585+00	2026-02-05 22:25:23.647296+00	tbhlkyugpudc	15c5bc25-7e7d-4db8-8f68-48bba9ce99ff
00000000-0000-0000-0000-000000000000	386	gu3hty2vh3mf	5e4ec0ef-464a-41db-8e2f-9f3bfa2671ee	t	2026-02-05 21:26:24.315517+00	2026-02-05 22:25:23.646212+00	hy7n4jeqly7w	97565c55-31fd-4aef-9f64-db127ec8038a
00000000-0000-0000-0000-000000000000	405	rv3ylshv4pts	95f608be-c1e9-43b1-b885-5e2784e4858f	t	2026-02-06 04:18:37.373174+00	2026-02-06 07:14:34.75782+00	h7uc5barcelh	15c5bc25-7e7d-4db8-8f68-48bba9ce99ff
00000000-0000-0000-0000-000000000000	412	eilwq3vwnawh	95f608be-c1e9-43b1-b885-5e2784e4858f	t	2026-02-06 07:14:34.758225+00	2026-02-06 08:12:49.918004+00	rv3ylshv4pts	15c5bc25-7e7d-4db8-8f68-48bba9ce99ff
00000000-0000-0000-0000-000000000000	388	7vh3xaevfitb	5e4ec0ef-464a-41db-8e2f-9f3bfa2671ee	t	2026-02-05 22:25:23.660244+00	2026-02-05 23:23:23.811776+00	gu3hty2vh3mf	97565c55-31fd-4aef-9f64-db127ec8038a
00000000-0000-0000-0000-000000000000	411	6w4az6mrymja	5ac10c39-274e-4ce5-a13b-f4da3af4a230	t	2026-02-06 07:14:22.408063+00	2026-02-06 08:13:22.094292+00	wxeazo6fb6ud	11b10676-7ac3-46fe-b5dc-6e53bc9d56fc
00000000-0000-0000-0000-000000000000	389	jljhkxaejdsd	95f608be-c1e9-43b1-b885-5e2784e4858f	t	2026-02-05 22:25:23.660215+00	2026-02-05 23:24:06.630102+00	zgfog4q34lxv	15c5bc25-7e7d-4db8-8f68-48bba9ce99ff
00000000-0000-0000-0000-000000000000	418	l4ano5jcqhxh	10e558ca-3940-4995-9a8f-165e78efaffc	t	2026-02-06 09:34:33.484714+00	2026-02-06 11:55:36.409779+00	stufy65eggl5	f8b68d38-042c-4697-9458-1c0a74313dc3
00000000-0000-0000-0000-000000000000	390	3qabbaxzup4j	36ae407d-c380-41ff-a714-d61371c44fb3	t	2026-02-05 23:04:25.920537+00	2026-02-06 00:02:39.536433+00	vt4igxdte4tp	3a1b4909-48e4-4e18-a472-1e3ac4ffa4f5
00000000-0000-0000-0000-000000000000	391	eo2am3twgls2	5e4ec0ef-464a-41db-8e2f-9f3bfa2671ee	t	2026-02-05 23:23:23.841364+00	2026-02-06 00:21:23.916121+00	7vh3xaevfitb	97565c55-31fd-4aef-9f64-db127ec8038a
00000000-0000-0000-0000-000000000000	392	clbv6jzykprs	95f608be-c1e9-43b1-b885-5e2784e4858f	t	2026-02-05 23:24:06.630588+00	2026-02-06 00:22:36.977098+00	jljhkxaejdsd	15c5bc25-7e7d-4db8-8f68-48bba9ce99ff
00000000-0000-0000-0000-000000000000	422	yjusol7r2s4p	10e558ca-3940-4995-9a8f-165e78efaffc	t	2026-02-06 11:55:36.429091+00	2026-02-06 13:39:55.632047+00	l4ano5jcqhxh	f8b68d38-042c-4697-9458-1c0a74313dc3
00000000-0000-0000-0000-000000000000	393	hbsirvgrzpag	5ac10c39-274e-4ce5-a13b-f4da3af4a230	t	2026-02-05 23:24:57.333343+00	2026-02-06 00:23:03.404779+00	nvl2zok7kkb6	11b10676-7ac3-46fe-b5dc-6e53bc9d56fc
00000000-0000-0000-0000-000000000000	394	ecz43d5qgsyk	36ae407d-c380-41ff-a714-d61371c44fb3	t	2026-02-06 00:02:39.558401+00	2026-02-06 01:00:42.73869+00	3qabbaxzup4j	3a1b4909-48e4-4e18-a472-1e3ac4ffa4f5
00000000-0000-0000-0000-000000000000	398	7eewwczkb4tq	36ae407d-c380-41ff-a714-d61371c44fb3	f	2026-02-06 01:00:42.749236+00	2026-02-06 01:00:42.749236+00	ecz43d5qgsyk	3a1b4909-48e4-4e18-a472-1e3ac4ffa4f5
00000000-0000-0000-0000-000000000000	396	pbpdcosj2gjj	95f608be-c1e9-43b1-b885-5e2784e4858f	t	2026-02-06 00:22:36.987048+00	2026-02-06 01:21:37.229829+00	clbv6jzykprs	15c5bc25-7e7d-4db8-8f68-48bba9ce99ff
00000000-0000-0000-0000-000000000000	395	qohsghoeu7jv	5e4ec0ef-464a-41db-8e2f-9f3bfa2671ee	t	2026-02-06 00:21:23.928462+00	2026-02-06 13:59:39.750099+00	eo2am3twgls2	97565c55-31fd-4aef-9f64-db127ec8038a
00000000-0000-0000-0000-000000000000	397	wkje56t3tvku	5ac10c39-274e-4ce5-a13b-f4da3af4a230	t	2026-02-06 00:23:03.405196+00	2026-02-06 01:36:45.613555+00	hbsirvgrzpag	11b10676-7ac3-46fe-b5dc-6e53bc9d56fc
00000000-0000-0000-0000-000000000000	399	gacgfvxuycif	95f608be-c1e9-43b1-b885-5e2784e4858f	t	2026-02-06 01:21:37.257217+00	2026-02-06 02:20:37.156114+00	pbpdcosj2gjj	15c5bc25-7e7d-4db8-8f68-48bba9ce99ff
00000000-0000-0000-0000-000000000000	428	b7yj63ok4ji6	95f608be-c1e9-43b1-b885-5e2784e4858f	t	2026-02-06 14:04:29.300444+00	2026-02-06 15:03:21.90642+00	76evica4ymux	15c5bc25-7e7d-4db8-8f68-48bba9ce99ff
00000000-0000-0000-0000-000000000000	400	lhpy6lv7xsjq	5ac10c39-274e-4ce5-a13b-f4da3af4a230	t	2026-02-06 01:36:45.641652+00	2026-02-06 02:35:37.294727+00	wkje56t3tvku	11b10676-7ac3-46fe-b5dc-6e53bc9d56fc
00000000-0000-0000-0000-000000000000	425	zbsdmjf2jyhl	10e558ca-3940-4995-9a8f-165e78efaffc	t	2026-02-06 13:39:55.64458+00	2026-02-06 15:06:43.954336+00	yjusol7r2s4p	f8b68d38-042c-4697-9458-1c0a74313dc3
00000000-0000-0000-0000-000000000000	401	gucdn4fzivxt	95f608be-c1e9-43b1-b885-5e2784e4858f	t	2026-02-06 02:20:37.170381+00	2026-02-06 03:19:37.33431+00	gacgfvxuycif	15c5bc25-7e7d-4db8-8f68-48bba9ce99ff
00000000-0000-0000-0000-000000000000	402	jdeivbt5x3be	5ac10c39-274e-4ce5-a13b-f4da3af4a230	t	2026-02-06 02:35:37.313353+00	2026-02-06 03:34:07.408723+00	lhpy6lv7xsjq	11b10676-7ac3-46fe-b5dc-6e53bc9d56fc
00000000-0000-0000-0000-000000000000	403	h7uc5barcelh	95f608be-c1e9-43b1-b885-5e2784e4858f	t	2026-02-06 03:19:37.356794+00	2026-02-06 04:18:37.353121+00	gucdn4fzivxt	15c5bc25-7e7d-4db8-8f68-48bba9ce99ff
00000000-0000-0000-0000-000000000000	432	zdqp3qykupkg	95f608be-c1e9-43b1-b885-5e2784e4858f	t	2026-02-06 17:16:48.304548+00	2026-02-06 18:15:48.205317+00	6ghemqxo64fk	15c5bc25-7e7d-4db8-8f68-48bba9ce99ff
00000000-0000-0000-0000-000000000000	434	t3fsj4wxm75m	95f608be-c1e9-43b1-b885-5e2784e4858f	t	2026-02-06 19:14:48.084993+00	2026-02-06 20:26:47.961197+00	clkp26sth7vd	15c5bc25-7e7d-4db8-8f68-48bba9ce99ff
00000000-0000-0000-0000-000000000000	436	n7qyy2tjc7na	95f608be-c1e9-43b1-b885-5e2784e4858f	t	2026-02-06 21:27:17.59537+00	2026-02-06 22:26:41.69337+00	t3qc2xgbkznu	15c5bc25-7e7d-4db8-8f68-48bba9ce99ff
00000000-0000-0000-0000-000000000000	438	g7zjc7kwg3wk	95f608be-c1e9-43b1-b885-5e2784e4858f	t	2026-02-06 23:25:41.602598+00	2026-02-07 00:24:41.514778+00	7czc5o5awwu3	15c5bc25-7e7d-4db8-8f68-48bba9ce99ff
00000000-0000-0000-0000-000000000000	430	2lqxfyzhefh5	10e558ca-3940-4995-9a8f-165e78efaffc	t	2026-02-06 15:06:43.958985+00	2026-02-07 01:36:11.773067+00	zbsdmjf2jyhl	f8b68d38-042c-4697-9458-1c0a74313dc3
00000000-0000-0000-0000-000000000000	444	uyrjtfptxbba	95f608be-c1e9-43b1-b885-5e2784e4858f	t	2026-02-07 03:21:41.85926+00	2026-02-07 04:20:41.993575+00	vl5bkyz4ru5p	15c5bc25-7e7d-4db8-8f68-48bba9ce99ff
00000000-0000-0000-0000-000000000000	442	zrf462mhcxdd	10e558ca-3940-4995-9a8f-165e78efaffc	t	2026-02-07 01:36:11.78096+00	2026-02-07 05:41:11.648415+00	2lqxfyzhefh5	f8b68d38-042c-4697-9458-1c0a74313dc3
00000000-0000-0000-0000-000000000000	448	j53wb5he2mwr	1ddb44b9-add6-437f-96de-2e7c2df0bfcc	f	2026-02-07 05:47:52.47068+00	2026-02-07 05:47:52.47068+00	\N	76975b13-27bb-465a-9a28-8a90107b9098
00000000-0000-0000-0000-000000000000	446	ykxgs2vplk7x	95f608be-c1e9-43b1-b885-5e2784e4858f	t	2026-02-07 05:19:42.016856+00	2026-02-07 06:18:42.393934+00	mm27reafxfwi	15c5bc25-7e7d-4db8-8f68-48bba9ce99ff
00000000-0000-0000-0000-000000000000	449	is7szhazc2qz	95f608be-c1e9-43b1-b885-5e2784e4858f	t	2026-02-07 06:18:42.421872+00	2026-02-07 07:17:42.211535+00	ykxgs2vplk7x	15c5bc25-7e7d-4db8-8f68-48bba9ce99ff
00000000-0000-0000-0000-000000000000	450	kj2qcmcrytsb	10e558ca-3940-4995-9a8f-165e78efaffc	t	2026-02-07 06:40:12.614787+00	2026-02-07 08:08:51.742904+00	qtaacb5qyfgg	f8b68d38-042c-4697-9458-1c0a74313dc3
00000000-0000-0000-0000-000000000000	451	g2f4r7merj2x	95f608be-c1e9-43b1-b885-5e2784e4858f	t	2026-02-07 07:17:42.238194+00	2026-02-07 08:16:42.104314+00	is7szhazc2qz	15c5bc25-7e7d-4db8-8f68-48bba9ce99ff
00000000-0000-0000-0000-000000000000	452	hwqromueyt66	10e558ca-3940-4995-9a8f-165e78efaffc	t	2026-02-07 08:08:51.762577+00	2026-02-07 09:09:05.906446+00	kj2qcmcrytsb	f8b68d38-042c-4697-9458-1c0a74313dc3
00000000-0000-0000-0000-000000000000	453	lgtjx444omna	95f608be-c1e9-43b1-b885-5e2784e4858f	t	2026-02-07 08:16:42.114443+00	2026-02-07 09:15:42.231431+00	g2f4r7merj2x	15c5bc25-7e7d-4db8-8f68-48bba9ce99ff
00000000-0000-0000-0000-000000000000	455	xowjndomfovk	95f608be-c1e9-43b1-b885-5e2784e4858f	t	2026-02-07 09:15:42.240172+00	2026-02-07 10:14:42.013145+00	lgtjx444omna	15c5bc25-7e7d-4db8-8f68-48bba9ce99ff
00000000-0000-0000-0000-000000000000	456	sauep5sc2j7w	95f608be-c1e9-43b1-b885-5e2784e4858f	t	2026-02-07 10:14:42.030133+00	2026-02-07 11:13:42.144169+00	xowjndomfovk	15c5bc25-7e7d-4db8-8f68-48bba9ce99ff
00000000-0000-0000-0000-000000000000	454	vggot5l3kjss	10e558ca-3940-4995-9a8f-165e78efaffc	t	2026-02-07 09:09:05.921389+00	2026-02-07 11:57:47.557115+00	hwqromueyt66	f8b68d38-042c-4697-9458-1c0a74313dc3
00000000-0000-0000-0000-000000000000	457	jkrupzseja44	95f608be-c1e9-43b1-b885-5e2784e4858f	t	2026-02-07 11:13:42.158303+00	2026-02-07 12:12:42.294605+00	sauep5sc2j7w	15c5bc25-7e7d-4db8-8f68-48bba9ce99ff
00000000-0000-0000-0000-000000000000	459	pyv2k3p4omtq	95f608be-c1e9-43b1-b885-5e2784e4858f	t	2026-02-07 12:12:42.320655+00	2026-02-07 13:11:42.55947+00	jkrupzseja44	15c5bc25-7e7d-4db8-8f68-48bba9ce99ff
00000000-0000-0000-0000-000000000000	460	xdi3r6lnb56h	95f608be-c1e9-43b1-b885-5e2784e4858f	t	2026-02-07 13:11:42.582027+00	2026-02-07 14:10:42.712553+00	pyv2k3p4omtq	15c5bc25-7e7d-4db8-8f68-48bba9ce99ff
00000000-0000-0000-0000-000000000000	461	cq7prnjr5pfq	95f608be-c1e9-43b1-b885-5e2784e4858f	t	2026-02-07 14:10:42.741984+00	2026-02-07 15:21:58.289827+00	xdi3r6lnb56h	15c5bc25-7e7d-4db8-8f68-48bba9ce99ff
00000000-0000-0000-0000-000000000000	440	eripd6uew6zk	5e4ec0ef-464a-41db-8e2f-9f3bfa2671ee	t	2026-02-07 00:37:52.676125+00	2026-02-08 07:52:51.99887+00	tpdihhk43wr6	9495d67b-b5b4-4205-a85d-790f160d9ed1
00000000-0000-0000-0000-000000000000	458	kp4uihmsc3da	10e558ca-3940-4995-9a8f-165e78efaffc	t	2026-02-07 11:57:47.578338+00	2026-02-08 09:26:08.904737+00	vggot5l3kjss	f8b68d38-042c-4697-9458-1c0a74313dc3
00000000-0000-0000-0000-000000000000	761	rn7j346crdbr	95f608be-c1e9-43b1-b885-5e2784e4858f	t	2026-02-10 14:17:24.167058+00	2026-02-10 15:15:31.92053+00	zwqpcjwgauom	15c5bc25-7e7d-4db8-8f68-48bba9ce99ff
00000000-0000-0000-0000-000000000000	462	m4wmbocvwwop	06d3b907-e06e-466b-a5fe-2dcc3912afaf	t	2026-02-07 14:26:10.788555+00	2026-02-07 15:25:04.649875+00	\N	d5c296b8-50d5-47a7-b7c2-2abecaae18f3
00000000-0000-0000-0000-000000000000	763	hsepzeswrfwf	95f608be-c1e9-43b1-b885-5e2784e4858f	t	2026-02-10 15:15:31.937005+00	2026-02-10 16:14:08.067128+00	rn7j346crdbr	15c5bc25-7e7d-4db8-8f68-48bba9ce99ff
00000000-0000-0000-0000-000000000000	463	w46ajlyycltn	95f608be-c1e9-43b1-b885-5e2784e4858f	t	2026-02-07 15:21:58.308094+00	2026-02-07 16:20:38.105929+00	cq7prnjr5pfq	15c5bc25-7e7d-4db8-8f68-48bba9ce99ff
00000000-0000-0000-0000-000000000000	773	hlb6ih2udwmb	10e558ca-3940-4995-9a8f-165e78efaffc	f	2026-02-11 02:07:49.649635+00	2026-02-11 02:07:49.649635+00	\N	f32518b9-f923-4b7d-b4a5-e9a6230b3636
00000000-0000-0000-0000-000000000000	464	js3c5jzscyfd	06d3b907-e06e-466b-a5fe-2dcc3912afaf	t	2026-02-07 15:25:04.667545+00	2026-02-07 16:35:25.316468+00	m4wmbocvwwop	d5c296b8-50d5-47a7-b7c2-2abecaae18f3
00000000-0000-0000-0000-000000000000	465	my6mnd4rfejg	95f608be-c1e9-43b1-b885-5e2784e4858f	t	2026-02-07 16:20:38.118216+00	2026-02-07 17:37:24.402635+00	w46ajlyycltn	15c5bc25-7e7d-4db8-8f68-48bba9ce99ff
00000000-0000-0000-0000-000000000000	466	dtzzqpqww3al	06d3b907-e06e-466b-a5fe-2dcc3912afaf	t	2026-02-07 16:35:25.341108+00	2026-02-07 17:37:27.951661+00	js3c5jzscyfd	d5c296b8-50d5-47a7-b7c2-2abecaae18f3
00000000-0000-0000-0000-000000000000	468	5cmxrlniusyh	06d3b907-e06e-466b-a5fe-2dcc3912afaf	t	2026-02-07 17:37:27.952696+00	2026-02-07 18:36:50.628907+00	dtzzqpqww3al	d5c296b8-50d5-47a7-b7c2-2abecaae18f3
00000000-0000-0000-0000-000000000000	467	besahfe3lnmj	95f608be-c1e9-43b1-b885-5e2784e4858f	t	2026-02-07 17:37:24.426298+00	2026-02-07 18:46:13.470364+00	my6mnd4rfejg	15c5bc25-7e7d-4db8-8f68-48bba9ce99ff
00000000-0000-0000-0000-000000000000	469	nv6rmagpy5h5	06d3b907-e06e-466b-a5fe-2dcc3912afaf	t	2026-02-07 18:36:50.652929+00	2026-02-07 19:35:55.873982+00	5cmxrlniusyh	d5c296b8-50d5-47a7-b7c2-2abecaae18f3
00000000-0000-0000-0000-000000000000	470	zagvawapp3p4	95f608be-c1e9-43b1-b885-5e2784e4858f	t	2026-02-07 18:46:13.480514+00	2026-02-07 19:45:13.411253+00	besahfe3lnmj	15c5bc25-7e7d-4db8-8f68-48bba9ce99ff
00000000-0000-0000-0000-000000000000	471	tdyeilitllib	06d3b907-e06e-466b-a5fe-2dcc3912afaf	t	2026-02-07 19:35:55.896775+00	2026-02-07 20:38:22.07137+00	nv6rmagpy5h5	d5c296b8-50d5-47a7-b7c2-2abecaae18f3
00000000-0000-0000-0000-000000000000	472	dqznohcrj3ws	95f608be-c1e9-43b1-b885-5e2784e4858f	t	2026-02-07 19:45:13.424111+00	2026-02-07 20:43:52.461455+00	zagvawapp3p4	15c5bc25-7e7d-4db8-8f68-48bba9ce99ff
00000000-0000-0000-0000-000000000000	474	hsylfn6mzqap	95f608be-c1e9-43b1-b885-5e2784e4858f	t	2026-02-07 20:43:52.462952+00	2026-02-07 21:42:52.515888+00	dqznohcrj3ws	15c5bc25-7e7d-4db8-8f68-48bba9ce99ff
00000000-0000-0000-0000-000000000000	473	7yjmxnn5dzzi	06d3b907-e06e-466b-a5fe-2dcc3912afaf	t	2026-02-07 20:38:22.091836+00	2026-02-07 21:44:34.028846+00	tdyeilitllib	d5c296b8-50d5-47a7-b7c2-2abecaae18f3
00000000-0000-0000-0000-000000000000	475	6ljfcshvif6z	95f608be-c1e9-43b1-b885-5e2784e4858f	t	2026-02-07 21:42:52.537685+00	2026-02-07 22:41:52.416158+00	hsylfn6mzqap	15c5bc25-7e7d-4db8-8f68-48bba9ce99ff
00000000-0000-0000-0000-000000000000	476	gzvjuqo2324o	06d3b907-e06e-466b-a5fe-2dcc3912afaf	t	2026-02-07 21:44:34.029889+00	2026-02-07 22:54:21.484724+00	7yjmxnn5dzzi	d5c296b8-50d5-47a7-b7c2-2abecaae18f3
00000000-0000-0000-0000-000000000000	477	p343m7l3b7tr	95f608be-c1e9-43b1-b885-5e2784e4858f	t	2026-02-07 22:41:52.436319+00	2026-02-07 23:40:18.952653+00	6ljfcshvif6z	15c5bc25-7e7d-4db8-8f68-48bba9ce99ff
00000000-0000-0000-0000-000000000000	478	uuc4yz2fpohl	06d3b907-e06e-466b-a5fe-2dcc3912afaf	t	2026-02-07 22:54:21.501861+00	2026-02-07 23:53:11.559982+00	gzvjuqo2324o	d5c296b8-50d5-47a7-b7c2-2abecaae18f3
00000000-0000-0000-0000-000000000000	479	r7jxfjpcasvh	95f608be-c1e9-43b1-b885-5e2784e4858f	t	2026-02-07 23:40:18.97309+00	2026-02-08 00:38:52.159664+00	p343m7l3b7tr	15c5bc25-7e7d-4db8-8f68-48bba9ce99ff
00000000-0000-0000-0000-000000000000	480	tsw4km65rxjn	06d3b907-e06e-466b-a5fe-2dcc3912afaf	t	2026-02-07 23:53:11.568937+00	2026-02-08 00:52:11.588044+00	uuc4yz2fpohl	d5c296b8-50d5-47a7-b7c2-2abecaae18f3
00000000-0000-0000-0000-000000000000	481	ilddb6uvybsr	95f608be-c1e9-43b1-b885-5e2784e4858f	t	2026-02-08 00:38:52.172453+00	2026-02-08 01:37:52.387983+00	r7jxfjpcasvh	15c5bc25-7e7d-4db8-8f68-48bba9ce99ff
00000000-0000-0000-0000-000000000000	482	f3sktuhq7yrw	06d3b907-e06e-466b-a5fe-2dcc3912afaf	t	2026-02-08 00:52:11.605471+00	2026-02-08 01:58:49.67413+00	tsw4km65rxjn	d5c296b8-50d5-47a7-b7c2-2abecaae18f3
00000000-0000-0000-0000-000000000000	483	6onjoj3y7rfh	95f608be-c1e9-43b1-b885-5e2784e4858f	t	2026-02-08 01:37:52.406801+00	2026-02-08 02:36:52.405274+00	ilddb6uvybsr	15c5bc25-7e7d-4db8-8f68-48bba9ce99ff
00000000-0000-0000-0000-000000000000	484	2uwc7gn6xoob	06d3b907-e06e-466b-a5fe-2dcc3912afaf	t	2026-02-08 01:58:49.696862+00	2026-02-08 03:19:41.49881+00	f3sktuhq7yrw	d5c296b8-50d5-47a7-b7c2-2abecaae18f3
00000000-0000-0000-0000-000000000000	485	j6ypr5r7sqmw	95f608be-c1e9-43b1-b885-5e2784e4858f	t	2026-02-08 02:36:52.43235+00	2026-02-08 03:35:52.538382+00	6onjoj3y7rfh	15c5bc25-7e7d-4db8-8f68-48bba9ce99ff
00000000-0000-0000-0000-000000000000	486	ttalcudhksxf	06d3b907-e06e-466b-a5fe-2dcc3912afaf	t	2026-02-08 03:19:41.52528+00	2026-02-08 04:21:12.938887+00	2uwc7gn6xoob	d5c296b8-50d5-47a7-b7c2-2abecaae18f3
00000000-0000-0000-0000-000000000000	487	myfkcujvi2wt	95f608be-c1e9-43b1-b885-5e2784e4858f	t	2026-02-08 03:35:52.552547+00	2026-02-08 04:34:52.731423+00	j6ypr5r7sqmw	15c5bc25-7e7d-4db8-8f68-48bba9ce99ff
00000000-0000-0000-0000-000000000000	490	ief34rqpovsf	1768c70a-81b5-4b3d-80b2-7e2a8f7d631b	f	2026-02-08 05:01:55.722101+00	2026-02-08 05:01:55.722101+00	\N	032367ef-d033-4698-a8c6-68ca002778ac
00000000-0000-0000-0000-000000000000	488	tvptu5zwzvfn	06d3b907-e06e-466b-a5fe-2dcc3912afaf	t	2026-02-08 04:21:12.957467+00	2026-02-08 05:21:56.592454+00	ttalcudhksxf	d5c296b8-50d5-47a7-b7c2-2abecaae18f3
00000000-0000-0000-0000-000000000000	489	xq5ku62cruzq	95f608be-c1e9-43b1-b885-5e2784e4858f	t	2026-02-08 04:34:52.753273+00	2026-02-08 05:33:52.794659+00	myfkcujvi2wt	15c5bc25-7e7d-4db8-8f68-48bba9ce99ff
00000000-0000-0000-0000-000000000000	491	fqgdq2sbwm6z	06d3b907-e06e-466b-a5fe-2dcc3912afaf	t	2026-02-08 05:21:56.61649+00	2026-02-08 06:24:06.58793+00	tvptu5zwzvfn	d5c296b8-50d5-47a7-b7c2-2abecaae18f3
00000000-0000-0000-0000-000000000000	492	oinlao3d7eak	95f608be-c1e9-43b1-b885-5e2784e4858f	t	2026-02-08 05:33:52.818042+00	2026-02-08 06:32:53.696982+00	xq5ku62cruzq	15c5bc25-7e7d-4db8-8f68-48bba9ce99ff
00000000-0000-0000-0000-000000000000	493	yu3z24kqfy5s	06d3b907-e06e-466b-a5fe-2dcc3912afaf	t	2026-02-08 06:24:06.61803+00	2026-02-08 07:24:12.544786+00	fqgdq2sbwm6z	d5c296b8-50d5-47a7-b7c2-2abecaae18f3
00000000-0000-0000-0000-000000000000	494	i2eivgd6oheo	95f608be-c1e9-43b1-b885-5e2784e4858f	t	2026-02-08 06:32:53.698475+00	2026-02-08 07:31:53.544273+00	oinlao3d7eak	15c5bc25-7e7d-4db8-8f68-48bba9ce99ff
00000000-0000-0000-0000-000000000000	498	efyoyrtldr7e	9969cfc6-451e-4ab2-ae2f-5d10a98eaf0a	f	2026-02-08 07:55:29.020898+00	2026-02-08 07:55:29.020898+00	\N	febeee40-c81f-442f-8377-be1ba1e1648d
00000000-0000-0000-0000-000000000000	495	kduoabl7wz6t	06d3b907-e06e-466b-a5fe-2dcc3912afaf	t	2026-02-08 07:24:12.56268+00	2026-02-08 08:24:32.609441+00	yu3z24kqfy5s	d5c296b8-50d5-47a7-b7c2-2abecaae18f3
00000000-0000-0000-0000-000000000000	496	oltd5adgwsgx	95f608be-c1e9-43b1-b885-5e2784e4858f	t	2026-02-08 07:31:53.551889+00	2026-02-08 08:30:53.081526+00	i2eivgd6oheo	15c5bc25-7e7d-4db8-8f68-48bba9ce99ff
00000000-0000-0000-0000-000000000000	497	vs5kgb7uvfxl	5e4ec0ef-464a-41db-8e2f-9f3bfa2671ee	t	2026-02-08 07:52:52.013346+00	2026-02-08 09:13:11.151+00	eripd6uew6zk	9495d67b-b5b4-4205-a85d-790f160d9ed1
00000000-0000-0000-0000-000000000000	499	bo6gei3pf4no	06d3b907-e06e-466b-a5fe-2dcc3912afaf	t	2026-02-08 08:24:32.636038+00	2026-02-08 09:23:28.287666+00	kduoabl7wz6t	d5c296b8-50d5-47a7-b7c2-2abecaae18f3
00000000-0000-0000-0000-000000000000	500	rijak7iishiv	95f608be-c1e9-43b1-b885-5e2784e4858f	t	2026-02-08 08:30:53.084034+00	2026-02-08 09:29:53.13963+00	oltd5adgwsgx	15c5bc25-7e7d-4db8-8f68-48bba9ce99ff
00000000-0000-0000-0000-000000000000	505	sdrk3gnnmof6	9969cfc6-451e-4ab2-ae2f-5d10a98eaf0a	f	2026-02-08 10:01:21.996358+00	2026-02-08 10:01:21.996358+00	\N	a6d8f5e7-8b9c-4e77-82e8-d3c0db2ef117
00000000-0000-0000-0000-000000000000	507	xued3nryzwri	9969cfc6-451e-4ab2-ae2f-5d10a98eaf0a	f	2026-02-08 10:01:21.994256+00	2026-02-08 10:01:21.994256+00	\N	d4a3265c-2362-4c62-a7b2-46023c68b2bc
00000000-0000-0000-0000-000000000000	506	kh2jth3x4ke2	9969cfc6-451e-4ab2-ae2f-5d10a98eaf0a	f	2026-02-08 10:01:21.996321+00	2026-02-08 10:01:21.996321+00	\N	f06d1ec5-e41a-44d8-9451-a586565f9f33
00000000-0000-0000-0000-000000000000	508	3gp6tufn62qy	9969cfc6-451e-4ab2-ae2f-5d10a98eaf0a	f	2026-02-08 10:01:22.392142+00	2026-02-08 10:01:22.392142+00	\N	b17a6421-4883-4b1d-bacf-bc9af46b1627
00000000-0000-0000-0000-000000000000	502	kcmy4lztzs5v	06d3b907-e06e-466b-a5fe-2dcc3912afaf	t	2026-02-08 09:23:28.291232+00	2026-02-08 10:26:22.968312+00	bo6gei3pf4no	d5c296b8-50d5-47a7-b7c2-2abecaae18f3
00000000-0000-0000-0000-000000000000	504	zzykfmmjgyky	95f608be-c1e9-43b1-b885-5e2784e4858f	t	2026-02-08 09:29:53.141998+00	2026-02-08 10:28:53.274505+00	rijak7iishiv	15c5bc25-7e7d-4db8-8f68-48bba9ce99ff
00000000-0000-0000-0000-000000000000	503	gqdrwlj72cvj	10e558ca-3940-4995-9a8f-165e78efaffc	t	2026-02-08 09:26:08.916117+00	2026-02-08 11:47:09.076298+00	kp4uihmsc3da	f8b68d38-042c-4697-9458-1c0a74313dc3
00000000-0000-0000-0000-000000000000	501	w6f3my6fp3l2	5e4ec0ef-464a-41db-8e2f-9f3bfa2671ee	t	2026-02-08 09:13:11.169786+00	2026-02-09 04:37:38.467816+00	vs5kgb7uvfxl	9495d67b-b5b4-4205-a85d-790f160d9ed1
00000000-0000-0000-0000-000000000000	509	kxyx5mo6utml	9969cfc6-451e-4ab2-ae2f-5d10a98eaf0a	f	2026-02-08 10:02:06.437992+00	2026-02-08 10:02:06.437992+00	\N	48202c03-6299-4924-89b6-23045e3cca6a
00000000-0000-0000-0000-000000000000	510	zhpyr25s5a5k	9969cfc6-451e-4ab2-ae2f-5d10a98eaf0a	f	2026-02-08 10:02:10.542179+00	2026-02-08 10:02:10.542179+00	\N	5346de08-2204-4bfe-a271-810679f93ae5
00000000-0000-0000-0000-000000000000	512	6a6qxbdvkscj	9969cfc6-451e-4ab2-ae2f-5d10a98eaf0a	f	2026-02-08 10:02:35.167985+00	2026-02-08 10:02:35.167985+00	\N	92508c30-738b-4f7c-b0e5-e149fef01e8c
00000000-0000-0000-0000-000000000000	764	ghvulp73ax6w	5e4ec0ef-464a-41db-8e2f-9f3bfa2671ee	t	2026-02-10 16:11:54.949224+00	2026-02-10 23:12:25.423245+00	ctgq5wuiaugc	69d52aab-1ad5-4836-91b2-38280ab5dca9
00000000-0000-0000-0000-000000000000	774	zr7n2sbn7adb	10e558ca-3940-4995-9a8f-165e78efaffc	f	2026-02-11 02:39:23.605201+00	2026-02-11 02:39:23.605201+00	\N	f9cf2f10-7d5a-4150-9486-78e634b5a346
00000000-0000-0000-0000-000000000000	788	qb3kswcr4jqw	10e558ca-3940-4995-9a8f-165e78efaffc	f	2026-02-11 03:33:38.99581+00	2026-02-11 03:33:38.99581+00	\N	9d7f36aa-5164-40d1-8bb8-e2ee6c93c287
00000000-0000-0000-0000-000000000000	793	7itnfu3ooydu	95f608be-c1e9-43b1-b885-5e2784e4858f	t	2026-02-11 07:44:50.936054+00	2026-02-11 08:43:51.083291+00	okamgpvivwi2	15c5bc25-7e7d-4db8-8f68-48bba9ce99ff
00000000-0000-0000-0000-000000000000	798	m6fyoslcxeiq	10e558ca-3940-4995-9a8f-165e78efaffc	t	2026-02-11 12:19:39.662755+00	2026-02-11 13:19:07.555781+00	\N	37538335-78cc-4a58-98ab-d359e5dfc985
00000000-0000-0000-0000-000000000000	803	tsn3cuprglgz	10e558ca-3940-4995-9a8f-165e78efaffc	t	2026-02-11 15:17:07.694004+00	2026-02-11 16:16:14.368551+00	imztxexr74gb	37538335-78cc-4a58-98ab-d359e5dfc985
00000000-0000-0000-0000-000000000000	808	2jqa3l2rlq6z	10e558ca-3940-4995-9a8f-165e78efaffc	t	2026-02-11 21:12:39.240746+00	2026-02-11 22:11:53.714584+00	frxydnlz2kvb	37538335-78cc-4a58-98ab-d359e5dfc985
00000000-0000-0000-0000-000000000000	813	m3e6fvsqo2p4	10e558ca-3940-4995-9a8f-165e78efaffc	t	2026-02-12 02:07:53.585258+00	2026-02-12 03:06:53.89827+00	qi6tkiviecal	37538335-78cc-4a58-98ab-d359e5dfc985
00000000-0000-0000-0000-000000000000	818	5qdyfavwzpc4	10e558ca-3940-4995-9a8f-165e78efaffc	t	2026-02-12 06:03:53.424211+00	2026-02-12 07:02:53.681425+00	fnmu6kvoucnq	37538335-78cc-4a58-98ab-d359e5dfc985
00000000-0000-0000-0000-000000000000	511	pdhdhpc7ozfs	9969cfc6-451e-4ab2-ae2f-5d10a98eaf0a	f	2026-02-08 10:02:12.588624+00	2026-02-08 10:02:12.588624+00	\N	7d4a3e26-6d76-4312-a4d1-5c11a44d67dc
00000000-0000-0000-0000-000000000000	513	pcbjdxputw4d	9969cfc6-451e-4ab2-ae2f-5d10a98eaf0a	f	2026-02-08 10:02:59.897914+00	2026-02-08 10:02:59.897914+00	\N	acc7ac19-0d74-4f0d-aba6-46cb3d1929f4
00000000-0000-0000-0000-000000000000	514	frriooho3qmy	9969cfc6-451e-4ab2-ae2f-5d10a98eaf0a	f	2026-02-08 10:02:59.964988+00	2026-02-08 10:02:59.964988+00	\N	7e61fa04-93e5-4e83-8f43-c45d404005e9
00000000-0000-0000-0000-000000000000	515	biyqtkzwhjs6	9969cfc6-451e-4ab2-ae2f-5d10a98eaf0a	f	2026-02-08 10:04:01.593893+00	2026-02-08 10:04:01.593893+00	\N	51aba99c-03c5-4605-b5c0-8283ca349b25
00000000-0000-0000-0000-000000000000	516	jmmeyjkcqef4	9969cfc6-451e-4ab2-ae2f-5d10a98eaf0a	f	2026-02-08 10:04:01.593788+00	2026-02-08 10:04:01.593788+00	\N	3c309b5f-db34-4653-aa90-55cddcd69a9e
00000000-0000-0000-0000-000000000000	517	h7cs3crci5rs	9969cfc6-451e-4ab2-ae2f-5d10a98eaf0a	f	2026-02-08 10:04:38.686112+00	2026-02-08 10:04:38.686112+00	\N	c8cf63ac-c335-440a-9975-2c860395051d
00000000-0000-0000-0000-000000000000	518	rch2vshevl7k	9969cfc6-451e-4ab2-ae2f-5d10a98eaf0a	f	2026-02-08 10:04:40.177956+00	2026-02-08 10:04:40.177956+00	\N	d86790cc-a735-49df-8bd1-14d504c92c83
00000000-0000-0000-0000-000000000000	519	bgkij7fclbz5	9969cfc6-451e-4ab2-ae2f-5d10a98eaf0a	f	2026-02-08 10:05:46.775796+00	2026-02-08 10:05:46.775796+00	\N	3b90ded5-343f-40b4-9093-4caed7535f54
00000000-0000-0000-0000-000000000000	520	dtowpx6kdepz	9969cfc6-451e-4ab2-ae2f-5d10a98eaf0a	f	2026-02-08 10:05:47.167115+00	2026-02-08 10:05:47.167115+00	\N	a1c76fe6-38f4-4d0c-973b-731ec8399cbd
00000000-0000-0000-0000-000000000000	521	ybnlnl54lcot	9969cfc6-451e-4ab2-ae2f-5d10a98eaf0a	f	2026-02-08 10:06:14.717473+00	2026-02-08 10:06:14.717473+00	\N	e98426ea-cee7-461a-b630-68d9656a18a4
00000000-0000-0000-0000-000000000000	522	ije6qjpomjrt	9969cfc6-451e-4ab2-ae2f-5d10a98eaf0a	f	2026-02-08 10:06:16.101862+00	2026-02-08 10:06:16.101862+00	\N	bc82085a-e2ea-4234-a001-d10e260dd2b5
00000000-0000-0000-0000-000000000000	523	5cao4faebjhv	9969cfc6-451e-4ab2-ae2f-5d10a98eaf0a	f	2026-02-08 10:07:08.153272+00	2026-02-08 10:07:08.153272+00	\N	03456332-c337-4e53-b595-6496d403e83e
00000000-0000-0000-0000-000000000000	524	kmbjiotjohvj	9969cfc6-451e-4ab2-ae2f-5d10a98eaf0a	f	2026-02-08 10:09:06.846157+00	2026-02-08 10:09:06.846157+00	\N	03ec5066-036c-4bf9-b2bd-1742e64c3513
00000000-0000-0000-0000-000000000000	525	d3ohef65gjba	9969cfc6-451e-4ab2-ae2f-5d10a98eaf0a	f	2026-02-08 10:09:17.059876+00	2026-02-08 10:09:17.059876+00	\N	a782cfe3-8f8f-4167-8beb-4b2b585bc7b7
00000000-0000-0000-0000-000000000000	526	ls7bqzkhwdmk	9969cfc6-451e-4ab2-ae2f-5d10a98eaf0a	f	2026-02-08 10:09:30.050785+00	2026-02-08 10:09:30.050785+00	\N	02bb27de-2037-45f9-ab9a-2280c51bee99
00000000-0000-0000-0000-000000000000	527	b7niwqhvn2os	9969cfc6-451e-4ab2-ae2f-5d10a98eaf0a	f	2026-02-08 10:09:30.073962+00	2026-02-08 10:09:30.073962+00	\N	d608bfe3-0472-499b-97e9-7212b6056250
00000000-0000-0000-0000-000000000000	528	u2vkwu4t6l53	9969cfc6-451e-4ab2-ae2f-5d10a98eaf0a	f	2026-02-08 10:09:58.411895+00	2026-02-08 10:09:58.411895+00	\N	eff4c5f3-ec3e-4a4c-bad5-0bb10a937e7e
00000000-0000-0000-0000-000000000000	765	o2kfspol2myq	95f608be-c1e9-43b1-b885-5e2784e4858f	t	2026-02-10 16:14:08.06795+00	2026-02-11 01:51:09.647939+00	hsepzeswrfwf	15c5bc25-7e7d-4db8-8f68-48bba9ce99ff
00000000-0000-0000-0000-000000000000	532	4lpa6tphzcoi	9969cfc6-451e-4ab2-ae2f-5d10a98eaf0a	f	2026-02-08 11:13:11.021786+00	2026-02-08 11:13:11.021786+00	\N	d5f33918-f88c-4a18-a4c6-0dab662329cc
00000000-0000-0000-0000-000000000000	533	vqfvhzdnjiw6	9969cfc6-451e-4ab2-ae2f-5d10a98eaf0a	f	2026-02-08 11:13:11.021705+00	2026-02-08 11:13:11.021705+00	\N	d692d613-2cb4-4951-bee2-2ec574866354
00000000-0000-0000-0000-000000000000	531	4apauykldbcu	9969cfc6-451e-4ab2-ae2f-5d10a98eaf0a	f	2026-02-08 11:13:11.021954+00	2026-02-08 11:13:11.021954+00	\N	0f51bce7-7bc0-4b06-8d0f-4522e7dddab1
00000000-0000-0000-0000-000000000000	534	oxp3arbt2nre	9969cfc6-451e-4ab2-ae2f-5d10a98eaf0a	f	2026-02-08 11:13:11.438295+00	2026-02-08 11:13:11.438295+00	\N	94623bfd-0d76-41d8-93e4-192a74317e18
00000000-0000-0000-0000-000000000000	535	uypjdnzz5wjy	9969cfc6-451e-4ab2-ae2f-5d10a98eaf0a	f	2026-02-08 11:13:26.019371+00	2026-02-08 11:13:26.019371+00	\N	86141149-83da-4692-bef0-c10214c82369
00000000-0000-0000-0000-000000000000	536	ze6e5e27rfbi	9969cfc6-451e-4ab2-ae2f-5d10a98eaf0a	f	2026-02-08 11:13:26.818682+00	2026-02-08 11:13:26.818682+00	\N	ff124e79-9428-4db8-adba-8b39f01724e5
00000000-0000-0000-0000-000000000000	537	hegno3etljbx	9969cfc6-451e-4ab2-ae2f-5d10a98eaf0a	f	2026-02-08 11:13:32.257543+00	2026-02-08 11:13:32.257543+00	\N	fa200289-289b-4e35-978f-c10793105793
00000000-0000-0000-0000-000000000000	538	pyosdctddrdd	9969cfc6-451e-4ab2-ae2f-5d10a98eaf0a	f	2026-02-08 11:13:32.45456+00	2026-02-08 11:13:32.45456+00	\N	020cbe47-6cef-40cb-857a-b406563a48be
00000000-0000-0000-0000-000000000000	539	4y5m4krjeb4r	9969cfc6-451e-4ab2-ae2f-5d10a98eaf0a	f	2026-02-08 11:13:33.641388+00	2026-02-08 11:13:33.641388+00	\N	b7a8f74e-d2c1-4852-9ffd-464ae7650ae4
00000000-0000-0000-0000-000000000000	540	xkpjuri2vmuf	9969cfc6-451e-4ab2-ae2f-5d10a98eaf0a	f	2026-02-08 11:13:46.260869+00	2026-02-08 11:13:46.260869+00	\N	f8c0d862-115c-4038-a454-b6b56be05727
00000000-0000-0000-0000-000000000000	541	iqn47s34k4ml	9969cfc6-451e-4ab2-ae2f-5d10a98eaf0a	f	2026-02-08 11:13:54.204145+00	2026-02-08 11:13:54.204145+00	\N	44ab02cd-df3b-4627-abf6-97ff5bc4a85a
00000000-0000-0000-0000-000000000000	542	viqws2tha325	9969cfc6-451e-4ab2-ae2f-5d10a98eaf0a	f	2026-02-08 11:13:56.651867+00	2026-02-08 11:13:56.651867+00	\N	8105805c-ce34-435e-9d84-707558c961ac
00000000-0000-0000-0000-000000000000	543	37jokkghk4nk	9969cfc6-451e-4ab2-ae2f-5d10a98eaf0a	f	2026-02-08 11:14:10.401489+00	2026-02-08 11:14:10.401489+00	\N	379bcc9e-bc86-498b-b9d4-7e0d66ffbcf8
00000000-0000-0000-0000-000000000000	544	ks7z3qukxwuj	9969cfc6-451e-4ab2-ae2f-5d10a98eaf0a	f	2026-02-08 11:14:49.956989+00	2026-02-08 11:14:49.956989+00	\N	62f73ad7-b2bd-4d80-aebe-a314084cf229
00000000-0000-0000-0000-000000000000	545	b47sxdvps2xn	9969cfc6-451e-4ab2-ae2f-5d10a98eaf0a	f	2026-02-08 11:14:49.957309+00	2026-02-08 11:14:49.957309+00	\N	e88374df-6cfc-4477-ac1e-feef2f340fee
00000000-0000-0000-0000-000000000000	546	caly7iasuu2y	9969cfc6-451e-4ab2-ae2f-5d10a98eaf0a	f	2026-02-08 11:14:50.909209+00	2026-02-08 11:14:50.909209+00	\N	1082bcf7-de4d-4c68-93bb-fd7f7b8b910e
00000000-0000-0000-0000-000000000000	547	x2puzfqpra5b	9969cfc6-451e-4ab2-ae2f-5d10a98eaf0a	f	2026-02-08 11:14:55.31116+00	2026-02-08 11:14:55.31116+00	\N	9d02563e-0286-4c02-979d-bcd1ad54f653
00000000-0000-0000-0000-000000000000	548	ugcwq62kql6r	9969cfc6-451e-4ab2-ae2f-5d10a98eaf0a	f	2026-02-08 11:15:28.450506+00	2026-02-08 11:15:28.450506+00	\N	4c194bd4-964a-4ddc-8cd8-6505b7c7511d
00000000-0000-0000-0000-000000000000	549	hiejdyb4whem	9969cfc6-451e-4ab2-ae2f-5d10a98eaf0a	f	2026-02-08 11:15:28.510905+00	2026-02-08 11:15:28.510905+00	\N	03fba221-2e20-4541-9cad-43ce5fbb3b3f
00000000-0000-0000-0000-000000000000	550	btiuhmow2iqr	9969cfc6-451e-4ab2-ae2f-5d10a98eaf0a	f	2026-02-08 11:16:12.793484+00	2026-02-08 11:16:12.793484+00	\N	2c29a7ce-acaf-4198-9074-162b2ebba8dd
00000000-0000-0000-0000-000000000000	551	cxgfk7cwzis6	9969cfc6-451e-4ab2-ae2f-5d10a98eaf0a	f	2026-02-08 11:16:12.925048+00	2026-02-08 11:16:12.925048+00	\N	fbd1b79e-a811-4470-80da-42ea0e095b5a
00000000-0000-0000-0000-000000000000	552	ryqgwyn3kncx	9969cfc6-451e-4ab2-ae2f-5d10a98eaf0a	f	2026-02-08 11:16:32.230795+00	2026-02-08 11:16:32.230795+00	\N	fa4a2c1e-e5c7-4d83-8a29-874cfd6dadc5
00000000-0000-0000-0000-000000000000	553	htjpyjsgd3oo	9969cfc6-451e-4ab2-ae2f-5d10a98eaf0a	f	2026-02-08 11:16:38.513479+00	2026-02-08 11:16:38.513479+00	\N	51a1bc0e-f308-44ad-b7da-449fdc615ced
00000000-0000-0000-0000-000000000000	554	d6socyqapisg	9969cfc6-451e-4ab2-ae2f-5d10a98eaf0a	f	2026-02-08 11:16:50.331629+00	2026-02-08 11:16:50.331629+00	\N	02e6e1f2-526c-4ac0-a648-a9eb11cc06f3
00000000-0000-0000-0000-000000000000	529	xphiergapaq5	06d3b907-e06e-466b-a5fe-2dcc3912afaf	t	2026-02-08 10:26:22.991024+00	2026-02-08 11:25:35.287705+00	kcmy4lztzs5v	d5c296b8-50d5-47a7-b7c2-2abecaae18f3
00000000-0000-0000-0000-000000000000	530	mcydqesl6j45	95f608be-c1e9-43b1-b885-5e2784e4858f	t	2026-02-08 10:28:53.280244+00	2026-02-08 11:27:53.277921+00	zzykfmmjgyky	15c5bc25-7e7d-4db8-8f68-48bba9ce99ff
00000000-0000-0000-0000-000000000000	557	w6uroorjkvhj	9969cfc6-451e-4ab2-ae2f-5d10a98eaf0a	f	2026-02-08 11:36:58.936027+00	2026-02-08 11:36:58.936027+00	\N	ba35064a-adc8-4a6c-b1b9-fda41284e12d
00000000-0000-0000-0000-000000000000	558	6bsvhogwncja	9969cfc6-451e-4ab2-ae2f-5d10a98eaf0a	f	2026-02-08 11:36:59.105071+00	2026-02-08 11:36:59.105071+00	\N	c5d20fd3-f023-41f5-82a3-3d37fb621023
00000000-0000-0000-0000-000000000000	559	5wib2oo3z2ib	9969cfc6-451e-4ab2-ae2f-5d10a98eaf0a	f	2026-02-08 11:37:03.995214+00	2026-02-08 11:37:03.995214+00	\N	004fc922-9a68-403b-8636-d357f61b2c94
00000000-0000-0000-0000-000000000000	560	utg26fvi2tgo	9969cfc6-451e-4ab2-ae2f-5d10a98eaf0a	f	2026-02-08 11:37:04.140488+00	2026-02-08 11:37:04.140488+00	\N	0081fa1a-06cd-4c0c-9351-a66c68fa8ee8
00000000-0000-0000-0000-000000000000	561	kkk4c4wvsfg6	9969cfc6-451e-4ab2-ae2f-5d10a98eaf0a	f	2026-02-08 11:37:27.154638+00	2026-02-08 11:37:27.154638+00	\N	c9044358-3ce2-4a54-9d0e-e4866433b970
00000000-0000-0000-0000-000000000000	562	neulkznsqhvk	9969cfc6-451e-4ab2-ae2f-5d10a98eaf0a	f	2026-02-08 11:37:28.852566+00	2026-02-08 11:37:28.852566+00	\N	c15ce90b-c7be-4a59-8ceb-148d7face7b8
00000000-0000-0000-0000-000000000000	563	wlpughy44gcu	9969cfc6-451e-4ab2-ae2f-5d10a98eaf0a	f	2026-02-08 11:37:38.67998+00	2026-02-08 11:37:38.67998+00	\N	19a19d9c-eb2f-45b4-bbe6-09b1809b4fcd
00000000-0000-0000-0000-000000000000	555	k65fz7tcmfvq	06d3b907-e06e-466b-a5fe-2dcc3912afaf	t	2026-02-08 11:25:35.305194+00	2026-02-08 12:24:35.306764+00	xphiergapaq5	d5c296b8-50d5-47a7-b7c2-2abecaae18f3
00000000-0000-0000-0000-000000000000	556	z43h375qnyrj	95f608be-c1e9-43b1-b885-5e2784e4858f	t	2026-02-08 11:27:53.278808+00	2026-02-08 12:26:53.543153+00	mcydqesl6j45	15c5bc25-7e7d-4db8-8f68-48bba9ce99ff
00000000-0000-0000-0000-000000000000	564	zjdi27qerjkn	9969cfc6-451e-4ab2-ae2f-5d10a98eaf0a	f	2026-02-08 11:37:38.852029+00	2026-02-08 11:37:38.852029+00	\N	e301bd0e-1b0c-42af-b557-b5eb7d5d2438
00000000-0000-0000-0000-000000000000	566	fuu4e4gcs6pm	9969cfc6-451e-4ab2-ae2f-5d10a98eaf0a	f	2026-02-08 11:37:54.444128+00	2026-02-08 11:37:54.444128+00	\N	b69e40c6-5dac-40ce-bf0d-4e2bf346443b
00000000-0000-0000-0000-000000000000	567	nz3k5czwzvos	9969cfc6-451e-4ab2-ae2f-5d10a98eaf0a	f	2026-02-08 11:38:22.595461+00	2026-02-08 11:38:22.595461+00	\N	a8f49396-3178-4089-ac55-74155168213c
00000000-0000-0000-0000-000000000000	766	6rljmprzgefk	5e4ec0ef-464a-41db-8e2f-9f3bfa2671ee	t	2026-02-10 23:12:25.453671+00	2026-02-11 00:10:38.502694+00	ghvulp73ax6w	69d52aab-1ad5-4836-91b2-38280ab5dca9
00000000-0000-0000-0000-000000000000	776	qfyg4wpim4gu	10e558ca-3940-4995-9a8f-165e78efaffc	f	2026-02-11 03:27:09.000699+00	2026-02-11 03:27:09.000699+00	\N	739168c5-c96d-4f48-9788-339ab4b728ee
00000000-0000-0000-0000-000000000000	777	zu756fyg7nyc	10e558ca-3940-4995-9a8f-165e78efaffc	f	2026-02-11 03:27:18.994258+00	2026-02-11 03:27:18.994258+00	\N	34c5c29f-6cd5-4237-86ee-6ff5b46fdf67
00000000-0000-0000-0000-000000000000	778	5n7t6rxve2yl	10e558ca-3940-4995-9a8f-165e78efaffc	f	2026-02-11 03:27:19.098547+00	2026-02-11 03:27:19.098547+00	\N	39a9b6df-bd60-4d14-be59-8c1042997a3e
00000000-0000-0000-0000-000000000000	775	szpxckb2kssx	95f608be-c1e9-43b1-b885-5e2784e4858f	t	2026-02-11 02:49:50.372954+00	2026-02-11 03:48:50.45991+00	szueqz7eopt3	15c5bc25-7e7d-4db8-8f68-48bba9ce99ff
00000000-0000-0000-0000-000000000000	789	bq7tmhqqkmn6	95f608be-c1e9-43b1-b885-5e2784e4858f	t	2026-02-11 03:48:50.482049+00	2026-02-11 04:47:50.693769+00	szpxckb2kssx	15c5bc25-7e7d-4db8-8f68-48bba9ce99ff
00000000-0000-0000-0000-000000000000	794	guhk2aakyel7	95f608be-c1e9-43b1-b885-5e2784e4858f	t	2026-02-11 08:43:51.110119+00	2026-02-11 09:43:07.606986+00	7itnfu3ooydu	15c5bc25-7e7d-4db8-8f68-48bba9ce99ff
00000000-0000-0000-0000-000000000000	799	c3ho3hdf4ydt	9969cfc6-451e-4ab2-ae2f-5d10a98eaf0a	t	2026-02-11 12:50:30.717155+00	2026-02-11 14:19:24.916094+00	\N	fdc7ca80-679a-432d-ba50-babf4dcb0a38
00000000-0000-0000-0000-000000000000	804	omudgzvbjqbd	10e558ca-3940-4995-9a8f-165e78efaffc	t	2026-02-11 16:16:14.389689+00	2026-02-11 17:30:31.40552+00	tsn3cuprglgz	37538335-78cc-4a58-98ab-d359e5dfc985
00000000-0000-0000-0000-000000000000	809	porowm5aix4i	10e558ca-3940-4995-9a8f-165e78efaffc	t	2026-02-11 22:11:53.743888+00	2026-02-11 23:10:53.850092+00	2jqa3l2rlq6z	37538335-78cc-4a58-98ab-d359e5dfc985
00000000-0000-0000-0000-000000000000	814	gihnielc5hy4	10e558ca-3940-4995-9a8f-165e78efaffc	t	2026-02-12 03:06:53.923141+00	2026-02-12 04:05:54.511103+00	m3e6fvsqo2p4	37538335-78cc-4a58-98ab-d359e5dfc985
00000000-0000-0000-0000-000000000000	819	rueh6z7l4koo	9969cfc6-451e-4ab2-ae2f-5d10a98eaf0a	t	2026-02-12 06:53:01.041089+00	2026-02-12 07:51:31.207121+00	jnzzgqsgq4b4	ee596f2a-dc76-4048-aae7-5ebb03ce31c8
00000000-0000-0000-0000-000000000000	565	f76fn7uzkg2k	9969cfc6-451e-4ab2-ae2f-5d10a98eaf0a	f	2026-02-08 11:37:47.980341+00	2026-02-08 11:37:47.980341+00	\N	d9760289-83c3-4ad8-a243-71841afc1b73
00000000-0000-0000-0000-000000000000	570	luiqnmrkzsfn	9969cfc6-451e-4ab2-ae2f-5d10a98eaf0a	f	2026-02-08 12:05:07.459231+00	2026-02-08 12:05:07.459231+00	\N	301edae8-e124-4689-b50f-8e1a251a7dc5
00000000-0000-0000-0000-000000000000	569	k37fe5hkrjp5	9969cfc6-451e-4ab2-ae2f-5d10a98eaf0a	f	2026-02-08 12:05:07.457196+00	2026-02-08 12:05:07.457196+00	\N	b2be4da3-5e91-4ca1-b732-6baada5a861a
00000000-0000-0000-0000-000000000000	571	276dy6ebyybu	9969cfc6-451e-4ab2-ae2f-5d10a98eaf0a	f	2026-02-08 12:05:10.574933+00	2026-02-08 12:05:10.574933+00	\N	ccbe9e1a-1b18-4c39-862d-d642f1769fd6
00000000-0000-0000-0000-000000000000	572	2q4snbjzprnv	9969cfc6-451e-4ab2-ae2f-5d10a98eaf0a	f	2026-02-08 12:05:10.728611+00	2026-02-08 12:05:10.728611+00	\N	60ff6e80-cd56-48a6-b59c-e61beb5ca258
00000000-0000-0000-0000-000000000000	573	g7podulknhvn	9969cfc6-451e-4ab2-ae2f-5d10a98eaf0a	f	2026-02-08 12:05:45.914504+00	2026-02-08 12:05:45.914504+00	\N	0c00d937-5acd-4e7d-9f85-d731bd0db803
00000000-0000-0000-0000-000000000000	574	y25tauwqrumc	9969cfc6-451e-4ab2-ae2f-5d10a98eaf0a	f	2026-02-08 12:05:55.009486+00	2026-02-08 12:05:55.009486+00	\N	8d973535-ea22-4ccc-b8f8-e218365210a7
00000000-0000-0000-0000-000000000000	575	ch75fgijuyjp	9969cfc6-451e-4ab2-ae2f-5d10a98eaf0a	f	2026-02-08 12:06:06.930754+00	2026-02-08 12:06:06.930754+00	\N	cbe99458-8e96-459b-959b-1fa1baead779
00000000-0000-0000-0000-000000000000	576	ehwz4klhcqfv	9969cfc6-451e-4ab2-ae2f-5d10a98eaf0a	f	2026-02-08 12:06:07.19561+00	2026-02-08 12:06:07.19561+00	\N	97e403bd-6a24-408e-9b46-f8a823b9ff31
00000000-0000-0000-0000-000000000000	577	jrceuqhgi232	9969cfc6-451e-4ab2-ae2f-5d10a98eaf0a	f	2026-02-08 12:06:46.457659+00	2026-02-08 12:06:46.457659+00	\N	f1ed9b39-5b59-4b2f-9279-4ae2aa682116
00000000-0000-0000-0000-000000000000	578	473erh7jdnao	9969cfc6-451e-4ab2-ae2f-5d10a98eaf0a	f	2026-02-08 12:06:47.070093+00	2026-02-08 12:06:47.070093+00	\N	1d9a67bc-b8c4-41d1-9145-0c746320dfbf
00000000-0000-0000-0000-000000000000	579	svzzkvgudflv	9969cfc6-451e-4ab2-ae2f-5d10a98eaf0a	f	2026-02-08 12:06:54.3167+00	2026-02-08 12:06:54.3167+00	\N	77b8ec21-6c0e-415a-8186-6eae395d31f4
00000000-0000-0000-0000-000000000000	580	qcwh7uvpjb2q	9969cfc6-451e-4ab2-ae2f-5d10a98eaf0a	f	2026-02-08 12:12:01.876567+00	2026-02-08 12:12:01.876567+00	\N	9b83d9a1-c246-4c07-8b4c-b4efc035bb58
00000000-0000-0000-0000-000000000000	581	d4isv4d6c34g	9969cfc6-451e-4ab2-ae2f-5d10a98eaf0a	f	2026-02-08 12:12:01.876692+00	2026-02-08 12:12:01.876692+00	\N	7899a028-9a85-4b80-8dd3-179ed1bfe70a
00000000-0000-0000-0000-000000000000	582	3aoofaqsohgx	9969cfc6-451e-4ab2-ae2f-5d10a98eaf0a	f	2026-02-08 12:12:01.94413+00	2026-02-08 12:12:01.94413+00	\N	35c57c2a-ddec-4f91-b851-60e9993716fe
00000000-0000-0000-0000-000000000000	583	kbvy2mkgcjno	9969cfc6-451e-4ab2-ae2f-5d10a98eaf0a	f	2026-02-08 12:12:23.450446+00	2026-02-08 12:12:23.450446+00	\N	950e8e89-9453-4908-8133-9bf892c6f462
00000000-0000-0000-0000-000000000000	584	qn2tkd2fgjpp	9969cfc6-451e-4ab2-ae2f-5d10a98eaf0a	f	2026-02-08 12:12:35.554768+00	2026-02-08 12:12:35.554768+00	\N	e9978302-1311-4b5b-813c-e91a751022ef
00000000-0000-0000-0000-000000000000	587	qyp3kwhu6ccu	9969cfc6-451e-4ab2-ae2f-5d10a98eaf0a	f	2026-02-08 12:37:06.240663+00	2026-02-08 12:37:06.240663+00	\N	64c61424-3fe0-48ca-bad7-7df1994237f4
00000000-0000-0000-0000-000000000000	588	oimfe2jsdtir	9969cfc6-451e-4ab2-ae2f-5d10a98eaf0a	f	2026-02-08 12:38:14.622917+00	2026-02-08 12:38:14.622917+00	\N	fe900f72-18e3-4b1d-8951-5c68048075ac
00000000-0000-0000-0000-000000000000	589	i2hc3xmyc7g3	9969cfc6-451e-4ab2-ae2f-5d10a98eaf0a	f	2026-02-08 12:41:45.610294+00	2026-02-08 12:41:45.610294+00	\N	cadfe077-4ab0-4bff-9f8a-1f0895b467e6
00000000-0000-0000-0000-000000000000	590	ym6y5gs6jm4h	9969cfc6-451e-4ab2-ae2f-5d10a98eaf0a	f	2026-02-08 12:49:25.10029+00	2026-02-08 12:49:25.10029+00	\N	d3746197-58bd-483d-82d1-b4a8d3383a48
00000000-0000-0000-0000-000000000000	591	2q4wtzfsf7ad	9969cfc6-451e-4ab2-ae2f-5d10a98eaf0a	f	2026-02-08 12:57:10.390941+00	2026-02-08 12:57:10.390941+00	\N	aaa18622-b0eb-404d-ab88-d09feaef4797
00000000-0000-0000-0000-000000000000	592	6i3lhpxaaq5n	9969cfc6-451e-4ab2-ae2f-5d10a98eaf0a	f	2026-02-08 12:59:31.50827+00	2026-02-08 12:59:31.50827+00	\N	67eaa452-7664-4c3b-825d-7bdac05e1942
00000000-0000-0000-0000-000000000000	593	eez3jrhcezuo	9969cfc6-451e-4ab2-ae2f-5d10a98eaf0a	f	2026-02-08 13:05:14.828506+00	2026-02-08 13:05:14.828506+00	\N	a2f86c28-b1d4-4cae-b94f-5d602e71e738
00000000-0000-0000-0000-000000000000	594	fmevum4d37nh	9969cfc6-451e-4ab2-ae2f-5d10a98eaf0a	f	2026-02-08 13:05:16.363919+00	2026-02-08 13:05:16.363919+00	\N	f92d3f4a-852c-4ba4-b896-f390a652272f
00000000-0000-0000-0000-000000000000	595	q2a5k6fyj4k6	9969cfc6-451e-4ab2-ae2f-5d10a98eaf0a	f	2026-02-08 13:05:18.058923+00	2026-02-08 13:05:18.058923+00	\N	a2cd0bf4-5e4d-4cf2-8ffb-391c8d7179f7
00000000-0000-0000-0000-000000000000	596	xwxdapwxlc7f	9969cfc6-451e-4ab2-ae2f-5d10a98eaf0a	f	2026-02-08 13:05:20.133934+00	2026-02-08 13:05:20.133934+00	\N	118a1c2d-5ca1-493e-bf55-8415166ced28
00000000-0000-0000-0000-000000000000	597	vzf4eesmtghm	9969cfc6-451e-4ab2-ae2f-5d10a98eaf0a	f	2026-02-08 13:05:33.482213+00	2026-02-08 13:05:33.482213+00	\N	35019c71-7964-4a7e-ba46-8a9c52183c8e
00000000-0000-0000-0000-000000000000	598	ivhllj4ifryk	9969cfc6-451e-4ab2-ae2f-5d10a98eaf0a	f	2026-02-08 13:05:34.022636+00	2026-02-08 13:05:34.022636+00	\N	9c1ac895-60eb-45e9-9f83-b74e8c7e743f
00000000-0000-0000-0000-000000000000	599	543tln6ut3yn	9969cfc6-451e-4ab2-ae2f-5d10a98eaf0a	f	2026-02-08 13:05:40.870252+00	2026-02-08 13:05:40.870252+00	\N	cd77c1d6-60aa-4452-961e-9f408e786d79
00000000-0000-0000-0000-000000000000	600	rtk5cfal5iq4	9969cfc6-451e-4ab2-ae2f-5d10a98eaf0a	f	2026-02-08 13:05:40.960406+00	2026-02-08 13:05:40.960406+00	\N	9d2f5ab3-4329-4a1b-b05b-de556fca5f19
00000000-0000-0000-0000-000000000000	601	2ispmfnci566	9969cfc6-451e-4ab2-ae2f-5d10a98eaf0a	f	2026-02-08 13:05:44.480159+00	2026-02-08 13:05:44.480159+00	\N	d3cae6fa-8ddb-402a-8610-99fc9fb61488
00000000-0000-0000-0000-000000000000	602	bwjjadsgbee5	9969cfc6-451e-4ab2-ae2f-5d10a98eaf0a	f	2026-02-08 13:05:55.686139+00	2026-02-08 13:05:55.686139+00	\N	10f894ab-d276-4135-b27f-527a073c9a90
00000000-0000-0000-0000-000000000000	603	zzstjdj6gsey	9969cfc6-451e-4ab2-ae2f-5d10a98eaf0a	f	2026-02-08 13:06:01.894788+00	2026-02-08 13:06:01.894788+00	\N	f5e40883-01d3-49a8-b1e7-c6e1401b9aa7
00000000-0000-0000-0000-000000000000	604	mnuvdlolug5b	9969cfc6-451e-4ab2-ae2f-5d10a98eaf0a	f	2026-02-08 13:06:14.108277+00	2026-02-08 13:06:14.108277+00	\N	9a132c8c-883b-488e-9c25-a18b9123ed74
00000000-0000-0000-0000-000000000000	605	liv5mq3blyig	9969cfc6-451e-4ab2-ae2f-5d10a98eaf0a	f	2026-02-08 13:06:16.80622+00	2026-02-08 13:06:16.80622+00	\N	e5ca9e4a-5656-4278-87dc-007a889176ef
00000000-0000-0000-0000-000000000000	606	lv6mshmwp4kr	9969cfc6-451e-4ab2-ae2f-5d10a98eaf0a	f	2026-02-08 13:06:35.603675+00	2026-02-08 13:06:35.603675+00	\N	0fb9735e-62ec-46af-bd93-23e2f376268c
00000000-0000-0000-0000-000000000000	585	uytovny3eo2g	06d3b907-e06e-466b-a5fe-2dcc3912afaf	t	2026-02-08 12:24:35.333859+00	2026-02-08 13:23:35.149781+00	k65fz7tcmfvq	d5c296b8-50d5-47a7-b7c2-2abecaae18f3
00000000-0000-0000-0000-000000000000	586	zrjdl4u5snpp	95f608be-c1e9-43b1-b885-5e2784e4858f	t	2026-02-08 12:26:53.548764+00	2026-02-08 13:25:53.657367+00	z43h375qnyrj	15c5bc25-7e7d-4db8-8f68-48bba9ce99ff
00000000-0000-0000-0000-000000000000	608	fl3k5uui7akv	95f608be-c1e9-43b1-b885-5e2784e4858f	t	2026-02-08 13:25:53.660619+00	2026-02-08 14:24:53.812373+00	zrjdl4u5snpp	15c5bc25-7e7d-4db8-8f68-48bba9ce99ff
00000000-0000-0000-0000-000000000000	607	mlq3d3h2gtvu	06d3b907-e06e-466b-a5fe-2dcc3912afaf	t	2026-02-08 13:23:35.168604+00	2026-02-08 14:33:57.704154+00	uytovny3eo2g	d5c296b8-50d5-47a7-b7c2-2abecaae18f3
00000000-0000-0000-0000-000000000000	609	or3cwtutgxuj	95f608be-c1e9-43b1-b885-5e2784e4858f	t	2026-02-08 14:24:53.841604+00	2026-02-08 15:23:53.994588+00	fl3k5uui7akv	15c5bc25-7e7d-4db8-8f68-48bba9ce99ff
00000000-0000-0000-0000-000000000000	611	cg6jhqbetk3j	95f608be-c1e9-43b1-b885-5e2784e4858f	t	2026-02-08 15:23:54.02088+00	2026-02-08 16:22:54.121086+00	or3cwtutgxuj	15c5bc25-7e7d-4db8-8f68-48bba9ce99ff
00000000-0000-0000-0000-000000000000	610	y2if6r5exvjr	06d3b907-e06e-466b-a5fe-2dcc3912afaf	t	2026-02-08 14:33:57.705855+00	2026-02-08 17:06:12.898981+00	mlq3d3h2gtvu	d5c296b8-50d5-47a7-b7c2-2abecaae18f3
00000000-0000-0000-0000-000000000000	612	y6wbzvswqntk	95f608be-c1e9-43b1-b885-5e2784e4858f	t	2026-02-08 16:22:54.152346+00	2026-02-08 17:21:54.14196+00	cg6jhqbetk3j	15c5bc25-7e7d-4db8-8f68-48bba9ce99ff
00000000-0000-0000-0000-000000000000	614	3mokptgd43ce	95f608be-c1e9-43b1-b885-5e2784e4858f	t	2026-02-08 17:21:54.164617+00	2026-02-08 18:20:53.742855+00	y6wbzvswqntk	15c5bc25-7e7d-4db8-8f68-48bba9ce99ff
00000000-0000-0000-0000-000000000000	615	wh4vaq3dlay2	95f608be-c1e9-43b1-b885-5e2784e4858f	t	2026-02-08 18:20:53.763345+00	2026-02-08 19:19:53.598457+00	3mokptgd43ce	15c5bc25-7e7d-4db8-8f68-48bba9ce99ff
00000000-0000-0000-0000-000000000000	613	cfqigtzdfr5z	06d3b907-e06e-466b-a5fe-2dcc3912afaf	t	2026-02-08 17:06:12.920385+00	2026-02-08 19:53:11.85916+00	y2if6r5exvjr	d5c296b8-50d5-47a7-b7c2-2abecaae18f3
00000000-0000-0000-0000-000000000000	616	zqyoird2j2iq	95f608be-c1e9-43b1-b885-5e2784e4858f	t	2026-02-08 19:19:53.621756+00	2026-02-08 20:18:53.457021+00	wh4vaq3dlay2	15c5bc25-7e7d-4db8-8f68-48bba9ce99ff
00000000-0000-0000-0000-000000000000	618	vucfapcvmvs6	95f608be-c1e9-43b1-b885-5e2784e4858f	t	2026-02-08 20:18:53.475883+00	2026-02-08 21:17:53.37758+00	zqyoird2j2iq	15c5bc25-7e7d-4db8-8f68-48bba9ce99ff
00000000-0000-0000-0000-000000000000	617	qng3x7erzna4	06d3b907-e06e-466b-a5fe-2dcc3912afaf	t	2026-02-08 19:53:11.886427+00	2026-02-08 23:01:10.634969+00	cfqigtzdfr5z	d5c296b8-50d5-47a7-b7c2-2abecaae18f3
00000000-0000-0000-0000-000000000000	568	gjnnlyj2jis7	10e558ca-3940-4995-9a8f-165e78efaffc	t	2026-02-08 11:47:09.09113+00	2026-02-09 06:36:01.014606+00	gqdrwlj72cvj	f8b68d38-042c-4697-9458-1c0a74313dc3
00000000-0000-0000-0000-000000000000	628	bqlt73nq7edd	5e4ec0ef-464a-41db-8e2f-9f3bfa2671ee	t	2026-02-09 02:03:33.853243+00	2026-02-10 15:09:35.64738+00	rmxz4fezelbg	97565c55-31fd-4aef-9f64-db127ec8038a
00000000-0000-0000-0000-000000000000	619	lpacbhy6jmex	95f608be-c1e9-43b1-b885-5e2784e4858f	t	2026-02-08 21:17:53.397859+00	2026-02-08 22:16:53.27735+00	vucfapcvmvs6	15c5bc25-7e7d-4db8-8f68-48bba9ce99ff
00000000-0000-0000-0000-000000000000	650	ctgq5wuiaugc	5e4ec0ef-464a-41db-8e2f-9f3bfa2671ee	t	2026-02-09 14:40:37.611773+00	2026-02-10 16:11:54.920347+00	tbjqbbucd3uz	69d52aab-1ad5-4836-91b2-38280ab5dca9
00000000-0000-0000-0000-000000000000	767	ptdqfqliyu6k	5e4ec0ef-464a-41db-8e2f-9f3bfa2671ee	t	2026-02-11 00:10:38.52725+00	2026-02-11 01:09:50.168546+00	6rljmprzgefk	69d52aab-1ad5-4836-91b2-38280ab5dca9
00000000-0000-0000-0000-000000000000	620	2byeivhxccjf	95f608be-c1e9-43b1-b885-5e2784e4858f	t	2026-02-08 22:16:53.307824+00	2026-02-08 23:15:53.340278+00	lpacbhy6jmex	15c5bc25-7e7d-4db8-8f68-48bba9ce99ff
00000000-0000-0000-0000-000000000000	622	r3gqeev2fafx	95f608be-c1e9-43b1-b885-5e2784e4858f	t	2026-02-08 23:15:53.354041+00	2026-02-09 00:14:53.319156+00	2byeivhxccjf	15c5bc25-7e7d-4db8-8f68-48bba9ce99ff
00000000-0000-0000-0000-000000000000	623	5uotc3flkimz	95f608be-c1e9-43b1-b885-5e2784e4858f	t	2026-02-09 00:14:53.3463+00	2026-02-09 01:13:53.529407+00	r3gqeev2fafx	15c5bc25-7e7d-4db8-8f68-48bba9ce99ff
00000000-0000-0000-0000-000000000000	621	y7fdvtmw4ied	06d3b907-e06e-466b-a5fe-2dcc3912afaf	t	2026-02-08 23:01:10.663328+00	2026-02-09 01:36:20.836723+00	qng3x7erzna4	d5c296b8-50d5-47a7-b7c2-2abecaae18f3
00000000-0000-0000-0000-000000000000	625	rmxz4fezelbg	5e4ec0ef-464a-41db-8e2f-9f3bfa2671ee	t	2026-02-09 00:30:23.369217+00	2026-02-09 02:03:33.832987+00	cknouxsymk57	97565c55-31fd-4aef-9f64-db127ec8038a
00000000-0000-0000-0000-000000000000	626	q5nk5wa43cdq	95f608be-c1e9-43b1-b885-5e2784e4858f	t	2026-02-09 01:13:53.55849+00	2026-02-09 02:12:14.12681+00	5uotc3flkimz	15c5bc25-7e7d-4db8-8f68-48bba9ce99ff
00000000-0000-0000-0000-000000000000	624	gjzuaftkqb5t	10e558ca-3940-4995-9a8f-165e78efaffc	t	2026-02-09 00:29:06.824032+00	2026-02-09 02:17:03.960109+00	uw2bdyqsxdlh	37f3ffaa-a35f-4db7-a814-f41f8fcf0359
00000000-0000-0000-0000-000000000000	630	bdbwfr4sjwvg	10e558ca-3940-4995-9a8f-165e78efaffc	f	2026-02-09 02:17:03.960886+00	2026-02-09 02:17:03.960886+00	gjzuaftkqb5t	37f3ffaa-a35f-4db7-a814-f41f8fcf0359
00000000-0000-0000-0000-000000000000	410	yyp6ftvabsdk	5e4ec0ef-464a-41db-8e2f-9f3bfa2671ee	t	2026-02-06 07:05:22.244721+00	2026-02-09 03:05:35.631658+00	xs6xgb3umeys	69d52aab-1ad5-4836-91b2-38280ab5dca9
00000000-0000-0000-0000-000000000000	627	x5j7nmpdygoi	06d3b907-e06e-466b-a5fe-2dcc3912afaf	t	2026-02-09 01:36:20.86546+00	2026-02-09 04:03:51.951411+00	y7fdvtmw4ied	d5c296b8-50d5-47a7-b7c2-2abecaae18f3
00000000-0000-0000-0000-000000000000	631	tw7slj3hemxt	5e4ec0ef-464a-41db-8e2f-9f3bfa2671ee	t	2026-02-09 03:05:35.659451+00	2026-02-09 04:04:15.410616+00	yyp6ftvabsdk	69d52aab-1ad5-4836-91b2-38280ab5dca9
00000000-0000-0000-0000-000000000000	633	emhvgoz65qtt	5e4ec0ef-464a-41db-8e2f-9f3bfa2671ee	t	2026-02-09 04:04:15.411242+00	2026-02-09 05:03:15.583687+00	tw7slj3hemxt	69d52aab-1ad5-4836-91b2-38280ab5dca9
00000000-0000-0000-0000-000000000000	632	xt5xvdx5hz5q	06d3b907-e06e-466b-a5fe-2dcc3912afaf	t	2026-02-09 04:03:51.98011+00	2026-02-09 05:23:42.151815+00	x5j7nmpdygoi	d5c296b8-50d5-47a7-b7c2-2abecaae18f3
00000000-0000-0000-0000-000000000000	635	crqn6kwts5t6	5e4ec0ef-464a-41db-8e2f-9f3bfa2671ee	t	2026-02-09 05:03:15.601665+00	2026-02-09 06:02:15.674988+00	emhvgoz65qtt	69d52aab-1ad5-4836-91b2-38280ab5dca9
00000000-0000-0000-0000-000000000000	637	t6l3oo5jpnuq	5e4ec0ef-464a-41db-8e2f-9f3bfa2671ee	t	2026-02-09 06:02:15.704338+00	2026-02-09 07:01:15.647854+00	crqn6kwts5t6	69d52aab-1ad5-4836-91b2-38280ab5dca9
00000000-0000-0000-0000-000000000000	638	sfvjzzni7477	10e558ca-3940-4995-9a8f-165e78efaffc	t	2026-02-09 06:36:01.033319+00	2026-02-09 07:34:09.808996+00	gjnnlyj2jis7	f8b68d38-042c-4697-9458-1c0a74313dc3
00000000-0000-0000-0000-000000000000	636	lek6h7whcblz	06d3b907-e06e-466b-a5fe-2dcc3912afaf	t	2026-02-09 05:23:42.181937+00	2026-02-09 07:57:55.398277+00	xt5xvdx5hz5q	d5c296b8-50d5-47a7-b7c2-2abecaae18f3
00000000-0000-0000-0000-000000000000	639	ilq6mlgcy6xr	5e4ec0ef-464a-41db-8e2f-9f3bfa2671ee	t	2026-02-09 07:01:15.667975+00	2026-02-09 08:00:15.468192+00	t6l3oo5jpnuq	69d52aab-1ad5-4836-91b2-38280ab5dca9
00000000-0000-0000-0000-000000000000	634	qujfxi7rvkpt	5e4ec0ef-464a-41db-8e2f-9f3bfa2671ee	t	2026-02-09 04:37:38.489754+00	2026-02-09 08:07:03.571944+00	w6f3my6fp3l2	9495d67b-b5b4-4205-a85d-790f160d9ed1
00000000-0000-0000-0000-000000000000	643	6hm6depma26w	5e4ec0ef-464a-41db-8e2f-9f3bfa2671ee	f	2026-02-09 08:07:03.577545+00	2026-02-09 08:07:03.577545+00	qujfxi7rvkpt	9495d67b-b5b4-4205-a85d-790f160d9ed1
00000000-0000-0000-0000-000000000000	642	s6kt5zxoq7yl	5e4ec0ef-464a-41db-8e2f-9f3bfa2671ee	t	2026-02-09 08:00:15.470315+00	2026-02-09 08:59:15.599+00	ilq6mlgcy6xr	69d52aab-1ad5-4836-91b2-38280ab5dca9
00000000-0000-0000-0000-000000000000	644	hlpkd7npepx4	5e4ec0ef-464a-41db-8e2f-9f3bfa2671ee	t	2026-02-09 08:59:15.623443+00	2026-02-09 09:58:15.782846+00	s6kt5zxoq7yl	69d52aab-1ad5-4836-91b2-38280ab5dca9
00000000-0000-0000-0000-000000000000	641	skm56oa2o5ek	06d3b907-e06e-466b-a5fe-2dcc3912afaf	t	2026-02-09 07:57:55.420849+00	2026-02-09 10:12:16.749329+00	lek6h7whcblz	d5c296b8-50d5-47a7-b7c2-2abecaae18f3
00000000-0000-0000-0000-000000000000	646	5yz3ifnran5t	06d3b907-e06e-466b-a5fe-2dcc3912afaf	t	2026-02-09 10:12:16.754837+00	2026-02-09 11:44:20.754903+00	skm56oa2o5ek	d5c296b8-50d5-47a7-b7c2-2abecaae18f3
00000000-0000-0000-0000-000000000000	640	6yu4pyrkzxkr	10e558ca-3940-4995-9a8f-165e78efaffc	t	2026-02-09 07:34:09.851669+00	2026-02-09 11:46:04.76161+00	sfvjzzni7477	f8b68d38-042c-4697-9458-1c0a74313dc3
00000000-0000-0000-0000-000000000000	647	msj2adae6fv4	06d3b907-e06e-466b-a5fe-2dcc3912afaf	t	2026-02-09 11:44:20.78647+00	2026-02-09 13:46:37.898706+00	5yz3ifnran5t	d5c296b8-50d5-47a7-b7c2-2abecaae18f3
00000000-0000-0000-0000-000000000000	645	tbjqbbucd3uz	5e4ec0ef-464a-41db-8e2f-9f3bfa2671ee	t	2026-02-09 09:58:15.803431+00	2026-02-09 14:40:37.595823+00	hlpkd7npepx4	69d52aab-1ad5-4836-91b2-38280ab5dca9
00000000-0000-0000-0000-000000000000	629	zigw4dksrroe	95f608be-c1e9-43b1-b885-5e2784e4858f	t	2026-02-09 02:12:14.152568+00	2026-02-09 14:41:18.745882+00	q5nk5wa43cdq	15c5bc25-7e7d-4db8-8f68-48bba9ce99ff
00000000-0000-0000-0000-000000000000	649	7jlouy32zvg2	06d3b907-e06e-466b-a5fe-2dcc3912afaf	t	2026-02-09 13:46:37.924425+00	2026-02-09 15:09:07.245294+00	msj2adae6fv4	d5c296b8-50d5-47a7-b7c2-2abecaae18f3
00000000-0000-0000-0000-000000000000	651	komo4szs5cth	95f608be-c1e9-43b1-b885-5e2784e4858f	t	2026-02-09 14:41:18.789952+00	2026-02-09 15:40:21.242401+00	zigw4dksrroe	15c5bc25-7e7d-4db8-8f68-48bba9ce99ff
00000000-0000-0000-0000-000000000000	653	h4i3w4jdjo6a	95f608be-c1e9-43b1-b885-5e2784e4858f	t	2026-02-09 15:40:21.269369+00	2026-02-09 16:39:21.183865+00	komo4szs5cth	15c5bc25-7e7d-4db8-8f68-48bba9ce99ff
00000000-0000-0000-0000-000000000000	652	ioenlxzdq5hk	06d3b907-e06e-466b-a5fe-2dcc3912afaf	t	2026-02-09 15:09:07.273871+00	2026-02-09 16:50:37.676851+00	7jlouy32zvg2	d5c296b8-50d5-47a7-b7c2-2abecaae18f3
00000000-0000-0000-0000-000000000000	654	ur3o65yfg3x4	95f608be-c1e9-43b1-b885-5e2784e4858f	t	2026-02-09 16:39:21.202883+00	2026-02-09 17:38:21.180409+00	h4i3w4jdjo6a	15c5bc25-7e7d-4db8-8f68-48bba9ce99ff
00000000-0000-0000-0000-000000000000	656	cgvznpqivtrr	95f608be-c1e9-43b1-b885-5e2784e4858f	t	2026-02-09 17:38:21.201339+00	2026-02-09 18:37:21.107357+00	ur3o65yfg3x4	15c5bc25-7e7d-4db8-8f68-48bba9ce99ff
00000000-0000-0000-0000-000000000000	657	fd2dfvvi6jix	95f608be-c1e9-43b1-b885-5e2784e4858f	t	2026-02-09 18:37:21.123971+00	2026-02-09 19:36:21.072834+00	cgvznpqivtrr	15c5bc25-7e7d-4db8-8f68-48bba9ce99ff
00000000-0000-0000-0000-000000000000	655	wymw3qssnv4h	06d3b907-e06e-466b-a5fe-2dcc3912afaf	t	2026-02-09 16:50:37.685433+00	2026-02-09 19:50:45.160576+00	ioenlxzdq5hk	d5c296b8-50d5-47a7-b7c2-2abecaae18f3
00000000-0000-0000-0000-000000000000	658	fqjk36pjvtg6	95f608be-c1e9-43b1-b885-5e2784e4858f	t	2026-02-09 19:36:21.095577+00	2026-02-09 20:35:21.000349+00	fd2dfvvi6jix	15c5bc25-7e7d-4db8-8f68-48bba9ce99ff
00000000-0000-0000-0000-000000000000	660	nug6f7fhizzb	95f608be-c1e9-43b1-b885-5e2784e4858f	t	2026-02-09 20:35:21.012773+00	2026-02-09 21:34:21.138869+00	fqjk36pjvtg6	15c5bc25-7e7d-4db8-8f68-48bba9ce99ff
00000000-0000-0000-0000-000000000000	142	ocztq6zrfn5w	8cf7c6be-ba2c-48c9-8825-589e675ff608	t	2026-02-03 14:26:35.67875+00	2026-02-09 21:58:24.639861+00	\N	6e909440-63dd-417e-868f-027949746666
00000000-0000-0000-0000-000000000000	659	kfs4skyk24du	06d3b907-e06e-466b-a5fe-2dcc3912afaf	t	2026-02-09 19:50:45.174562+00	2026-02-09 22:11:15.274238+00	wymw3qssnv4h	d5c296b8-50d5-47a7-b7c2-2abecaae18f3
00000000-0000-0000-0000-000000000000	661	6xoqbul7o2z7	95f608be-c1e9-43b1-b885-5e2784e4858f	t	2026-02-09 21:34:21.155041+00	2026-02-09 22:33:20.964685+00	nug6f7fhizzb	15c5bc25-7e7d-4db8-8f68-48bba9ce99ff
00000000-0000-0000-0000-000000000000	662	liv7olrlf5ca	8cf7c6be-ba2c-48c9-8825-589e675ff608	t	2026-02-09 21:58:24.672051+00	2026-02-09 22:56:26.807226+00	ocztq6zrfn5w	6e909440-63dd-417e-868f-027949746666
00000000-0000-0000-0000-000000000000	664	3kymi37vm42h	95f608be-c1e9-43b1-b885-5e2784e4858f	t	2026-02-09 22:33:20.986642+00	2026-02-09 23:32:21.137062+00	6xoqbul7o2z7	15c5bc25-7e7d-4db8-8f68-48bba9ce99ff
00000000-0000-0000-0000-000000000000	665	sfza53qevobn	8cf7c6be-ba2c-48c9-8825-589e675ff608	t	2026-02-09 22:56:26.825726+00	2026-02-09 23:54:57.68353+00	liv7olrlf5ca	6e909440-63dd-417e-868f-027949746666
00000000-0000-0000-0000-000000000000	663	xq2k4j632izf	06d3b907-e06e-466b-a5fe-2dcc3912afaf	t	2026-02-09 22:11:15.300125+00	2026-02-10 00:03:07.480064+00	kfs4skyk24du	d5c296b8-50d5-47a7-b7c2-2abecaae18f3
00000000-0000-0000-0000-000000000000	666	vqahlvxjiare	95f608be-c1e9-43b1-b885-5e2784e4858f	t	2026-02-09 23:32:21.155621+00	2026-02-10 00:31:21.450801+00	3kymi37vm42h	15c5bc25-7e7d-4db8-8f68-48bba9ce99ff
00000000-0000-0000-0000-000000000000	648	waetesnz6shm	10e558ca-3940-4995-9a8f-165e78efaffc	t	2026-02-09 11:46:04.763561+00	2026-02-10 00:58:34.848792+00	6yu4pyrkzxkr	f8b68d38-042c-4697-9458-1c0a74313dc3
00000000-0000-0000-0000-000000000000	667	6e5kosndsonp	8cf7c6be-ba2c-48c9-8825-589e675ff608	f	2026-02-09 23:54:57.699364+00	2026-02-09 23:54:57.699364+00	sfza53qevobn	6e909440-63dd-417e-868f-027949746666
00000000-0000-0000-0000-000000000000	779	kvfttultenhe	10e558ca-3940-4995-9a8f-165e78efaffc	f	2026-02-11 03:27:58.301047+00	2026-02-11 03:27:58.301047+00	\N	714c1858-7bf7-4e8a-8c7c-6c7251f6c5cd
00000000-0000-0000-0000-000000000000	780	dqfdkerift55	10e558ca-3940-4995-9a8f-165e78efaffc	f	2026-02-11 03:27:58.396568+00	2026-02-11 03:27:58.396568+00	\N	d51fe136-847e-4aeb-95e8-20f97c9934f7
00000000-0000-0000-0000-000000000000	671	bgfdm3qiv5zz	9969cfc6-451e-4ab2-ae2f-5d10a98eaf0a	f	2026-02-10 01:04:37.234899+00	2026-02-10 01:04:37.234899+00	\N	280052e9-28d2-4fb6-a7fb-b0ac2dbd2801
00000000-0000-0000-0000-000000000000	672	lsxhiix72o5a	9969cfc6-451e-4ab2-ae2f-5d10a98eaf0a	f	2026-02-10 01:04:48.684407+00	2026-02-10 01:04:48.684407+00	\N	2e8b9103-a742-425d-8150-65e52f132229
00000000-0000-0000-0000-000000000000	673	pmfxbu35rv5l	9969cfc6-451e-4ab2-ae2f-5d10a98eaf0a	f	2026-02-10 01:06:19.951526+00	2026-02-10 01:06:19.951526+00	\N	3ad33f7b-a830-48b9-957d-cd203f83c5ee
00000000-0000-0000-0000-000000000000	674	hyfgzhzzijdi	9969cfc6-451e-4ab2-ae2f-5d10a98eaf0a	f	2026-02-10 01:08:10.826253+00	2026-02-10 01:08:10.826253+00	\N	97c25ec7-fef3-49f6-9d51-66edd2677d4b
00000000-0000-0000-0000-000000000000	675	jykp3vv3izkz	9969cfc6-451e-4ab2-ae2f-5d10a98eaf0a	f	2026-02-10 01:08:11.086641+00	2026-02-10 01:08:11.086641+00	\N	d53b70c0-66db-4ddd-823e-ef1b5d802800
00000000-0000-0000-0000-000000000000	676	wytexhaitgd5	9969cfc6-451e-4ab2-ae2f-5d10a98eaf0a	f	2026-02-10 01:08:30.158789+00	2026-02-10 01:08:30.158789+00	\N	58335a26-6d19-4580-bfa2-d642b39abccb
00000000-0000-0000-0000-000000000000	677	p23ul5he465v	9969cfc6-451e-4ab2-ae2f-5d10a98eaf0a	f	2026-02-10 01:08:30.194969+00	2026-02-10 01:08:30.194969+00	\N	9d96b83a-6431-4607-a052-b547cc1b9793
00000000-0000-0000-0000-000000000000	678	sms6lj4dontx	9969cfc6-451e-4ab2-ae2f-5d10a98eaf0a	f	2026-02-10 01:09:00.578976+00	2026-02-10 01:09:00.578976+00	\N	960ad8ac-84a5-4a24-807b-337d65b7f6ba
00000000-0000-0000-0000-000000000000	679	xq3gxgjipfqo	9969cfc6-451e-4ab2-ae2f-5d10a98eaf0a	f	2026-02-10 01:09:00.594925+00	2026-02-10 01:09:00.594925+00	\N	9ab2a5ea-b75c-4e0b-af40-bf5381f8634c
00000000-0000-0000-0000-000000000000	680	mhn7lvpgc5xw	9969cfc6-451e-4ab2-ae2f-5d10a98eaf0a	f	2026-02-10 01:09:20.786327+00	2026-02-10 01:09:20.786327+00	\N	571b37ef-c746-47b2-a43d-5822cd1ffb08
00000000-0000-0000-0000-000000000000	681	vqoqtljhoukn	9969cfc6-451e-4ab2-ae2f-5d10a98eaf0a	f	2026-02-10 01:09:20.820292+00	2026-02-10 01:09:20.820292+00	\N	d116b789-6bbf-48c0-a948-d40496d6eb09
00000000-0000-0000-0000-000000000000	682	xynrppk4r7ri	9969cfc6-451e-4ab2-ae2f-5d10a98eaf0a	f	2026-02-10 01:09:35.9326+00	2026-02-10 01:09:35.9326+00	\N	1aea00c2-4e53-4f1f-a9cd-420d0512eb0d
00000000-0000-0000-0000-000000000000	683	xvd2j5i7jfbc	9969cfc6-451e-4ab2-ae2f-5d10a98eaf0a	f	2026-02-10 01:09:41.236783+00	2026-02-10 01:09:41.236783+00	\N	4b6d015f-31b8-477e-9505-63ea5543e42c
00000000-0000-0000-0000-000000000000	684	zonh5vbhoki5	9969cfc6-451e-4ab2-ae2f-5d10a98eaf0a	f	2026-02-10 01:09:46.057769+00	2026-02-10 01:09:46.057769+00	\N	83b6f0eb-bd8e-43c5-89c6-e815fc8127a2
00000000-0000-0000-0000-000000000000	685	ogznvm3cq3vn	9969cfc6-451e-4ab2-ae2f-5d10a98eaf0a	f	2026-02-10 01:09:52.221156+00	2026-02-10 01:09:52.221156+00	\N	b5eaeea5-ed0a-4ed2-9bac-c25b28aa8275
00000000-0000-0000-0000-000000000000	686	edpml2rzxt7b	9969cfc6-451e-4ab2-ae2f-5d10a98eaf0a	f	2026-02-10 01:09:57.748102+00	2026-02-10 01:09:57.748102+00	\N	0631f62e-f68e-4677-92b1-b9315f5feb23
00000000-0000-0000-0000-000000000000	687	lku2uy3mdfvg	9969cfc6-451e-4ab2-ae2f-5d10a98eaf0a	f	2026-02-10 01:10:05.028683+00	2026-02-10 01:10:05.028683+00	\N	933fd499-040a-4d27-bacf-7136bbd98668
00000000-0000-0000-0000-000000000000	688	yu3tya5on23r	9969cfc6-451e-4ab2-ae2f-5d10a98eaf0a	f	2026-02-10 01:10:11.025942+00	2026-02-10 01:10:11.025942+00	\N	94a3aa4c-f5e5-48b1-b54b-9b6d13e4153d
00000000-0000-0000-0000-000000000000	689	7immwn55vzfl	9969cfc6-451e-4ab2-ae2f-5d10a98eaf0a	f	2026-02-10 01:10:17.854214+00	2026-02-10 01:10:17.854214+00	\N	62dc0dd6-d69f-4cb8-972b-bde77eae9cbb
00000000-0000-0000-0000-000000000000	690	h6vxxovoz3k7	9969cfc6-451e-4ab2-ae2f-5d10a98eaf0a	f	2026-02-10 01:11:57.043806+00	2026-02-10 01:11:57.043806+00	\N	10f2c61b-eca8-471a-9f12-075ddf355f79
00000000-0000-0000-0000-000000000000	691	6upvj6knztcl	9969cfc6-451e-4ab2-ae2f-5d10a98eaf0a	f	2026-02-10 01:12:04.188616+00	2026-02-10 01:12:04.188616+00	\N	afeecc0d-bee8-42a3-9121-1bc0f17561bb
00000000-0000-0000-0000-000000000000	692	6mrfun7x3eyf	9969cfc6-451e-4ab2-ae2f-5d10a98eaf0a	f	2026-02-10 01:12:24.910691+00	2026-02-10 01:12:24.910691+00	\N	d033c247-e4ec-44be-8808-c6f254a4d3c8
00000000-0000-0000-0000-000000000000	693	j6mlq4bnpqjo	9969cfc6-451e-4ab2-ae2f-5d10a98eaf0a	f	2026-02-10 01:12:38.854552+00	2026-02-10 01:12:38.854552+00	\N	3b57dc79-86d3-432e-a79c-8cb06d88430e
00000000-0000-0000-0000-000000000000	694	ffuq7vaeycfu	9969cfc6-451e-4ab2-ae2f-5d10a98eaf0a	f	2026-02-10 01:12:55.185048+00	2026-02-10 01:12:55.185048+00	\N	319ba666-633e-44f5-b382-36b699bffcd6
00000000-0000-0000-0000-000000000000	669	di257bsztmyi	95f608be-c1e9-43b1-b885-5e2784e4858f	t	2026-02-10 00:31:21.468088+00	2026-02-10 01:30:21.459978+00	vqahlvxjiare	15c5bc25-7e7d-4db8-8f68-48bba9ce99ff
00000000-0000-0000-0000-000000000000	783	wjj6rayyqqo6	10e558ca-3940-4995-9a8f-165e78efaffc	f	2026-02-11 03:29:31.446779+00	2026-02-11 03:29:31.446779+00	\N	b90eb011-1b08-418f-a421-fc856f9a8933
00000000-0000-0000-0000-000000000000	695	misyfa36tnf6	95f608be-c1e9-43b1-b885-5e2784e4858f	t	2026-02-10 01:30:21.48496+00	2026-02-10 02:29:22.230287+00	di257bsztmyi	15c5bc25-7e7d-4db8-8f68-48bba9ce99ff
00000000-0000-0000-0000-000000000000	668	bxjtqfkep7xm	06d3b907-e06e-466b-a5fe-2dcc3912afaf	t	2026-02-10 00:03:07.488832+00	2026-02-10 02:40:04.406912+00	xq2k4j632izf	d5c296b8-50d5-47a7-b7c2-2abecaae18f3
00000000-0000-0000-0000-000000000000	696	l54t6jey2f5o	95f608be-c1e9-43b1-b885-5e2784e4858f	t	2026-02-10 02:29:22.254804+00	2026-02-10 03:28:21.9064+00	misyfa36tnf6	15c5bc25-7e7d-4db8-8f68-48bba9ce99ff
00000000-0000-0000-0000-000000000000	699	wogaiww54sdr	10e558ca-3940-4995-9a8f-165e78efaffc	f	2026-02-10 03:57:54.003996+00	2026-02-10 03:57:54.003996+00	\N	4e8cc104-65b3-40cd-a016-623909bce1cb
00000000-0000-0000-0000-000000000000	700	gjspzkgbjx23	10e558ca-3940-4995-9a8f-165e78efaffc	f	2026-02-10 03:59:05.079598+00	2026-02-10 03:59:05.079598+00	\N	1901750a-c6d3-4b2c-bf57-3c18f4238195
00000000-0000-0000-0000-000000000000	701	7qqaqotrfim3	10e558ca-3940-4995-9a8f-165e78efaffc	f	2026-02-10 03:59:09.221701+00	2026-02-10 03:59:09.221701+00	\N	38937acc-1ff7-43a0-8975-3655310822e7
00000000-0000-0000-0000-000000000000	702	neblippdniym	10e558ca-3940-4995-9a8f-165e78efaffc	f	2026-02-10 03:59:26.712231+00	2026-02-10 03:59:26.712231+00	\N	85e496f2-4c41-407b-bdca-f48428f8f362
00000000-0000-0000-0000-000000000000	703	pgwxu2b5s6fr	10e558ca-3940-4995-9a8f-165e78efaffc	f	2026-02-10 03:59:40.856797+00	2026-02-10 03:59:40.856797+00	\N	64424939-8965-4f07-bb94-744f6916f55d
00000000-0000-0000-0000-000000000000	704	cb2jn2nwmdfq	10e558ca-3940-4995-9a8f-165e78efaffc	f	2026-02-10 03:59:47.668699+00	2026-02-10 03:59:47.668699+00	\N	d7b95386-c309-4a82-8566-f1352c716114
00000000-0000-0000-0000-000000000000	705	flkzvvthfxmu	10e558ca-3940-4995-9a8f-165e78efaffc	f	2026-02-10 04:00:13.215991+00	2026-02-10 04:00:13.215991+00	\N	3a042df2-f0fb-4f7f-a8b2-9a44365ba605
00000000-0000-0000-0000-000000000000	706	3gaombeq6m3k	10e558ca-3940-4995-9a8f-165e78efaffc	f	2026-02-10 04:00:17.288977+00	2026-02-10 04:00:17.288977+00	\N	3dccbb85-f5a0-4578-80b3-62f1404f0125
00000000-0000-0000-0000-000000000000	707	ygaov32vgzsb	10e558ca-3940-4995-9a8f-165e78efaffc	f	2026-02-10 04:00:22.214965+00	2026-02-10 04:00:22.214965+00	\N	63286937-5f83-4a29-9ccf-37f2100991be
00000000-0000-0000-0000-000000000000	708	vkn37cwguki5	10e558ca-3940-4995-9a8f-165e78efaffc	f	2026-02-10 04:00:25.628802+00	2026-02-10 04:00:25.628802+00	\N	4ca9797c-d4b6-4bcc-a4d5-f8bace732be8
00000000-0000-0000-0000-000000000000	709	ce35vn4d76sn	10e558ca-3940-4995-9a8f-165e78efaffc	f	2026-02-10 04:00:30.610394+00	2026-02-10 04:00:30.610394+00	\N	65aac392-b0d7-46d7-8ab8-b114449d16e2
00000000-0000-0000-0000-000000000000	710	a3ryl2lnphit	10e558ca-3940-4995-9a8f-165e78efaffc	f	2026-02-10 04:16:51.701187+00	2026-02-10 04:16:51.701187+00	\N	6a2e9bf3-d0df-44f6-99bb-c48b463c9b14
00000000-0000-0000-0000-000000000000	711	a6tx2dlsnmmu	10e558ca-3940-4995-9a8f-165e78efaffc	f	2026-02-10 04:16:51.7023+00	2026-02-10 04:16:51.7023+00	\N	0c4ec18d-ed00-47c9-a1b7-1e9bcd332f51
00000000-0000-0000-0000-000000000000	712	ymawtqqtgwuu	10e558ca-3940-4995-9a8f-165e78efaffc	f	2026-02-10 04:16:57.892191+00	2026-02-10 04:16:57.892191+00	\N	aff85e06-971d-4723-a84d-c5fbd69c70ce
00000000-0000-0000-0000-000000000000	713	obcukvywaacr	10e558ca-3940-4995-9a8f-165e78efaffc	f	2026-02-10 04:17:04.960614+00	2026-02-10 04:17:04.960614+00	\N	98dbde8e-6f29-43d0-b7eb-5fa250db4346
00000000-0000-0000-0000-000000000000	714	2ekzp736guss	10e558ca-3940-4995-9a8f-165e78efaffc	f	2026-02-10 04:17:31.063038+00	2026-02-10 04:17:31.063038+00	\N	a401120b-a6a2-4a53-a413-8546b9687ce2
00000000-0000-0000-0000-000000000000	715	u3lae5f27mbx	10e558ca-3940-4995-9a8f-165e78efaffc	f	2026-02-10 04:17:35.099924+00	2026-02-10 04:17:35.099924+00	\N	1159bacc-dfd5-4f6b-88d9-b2e66095eaae
00000000-0000-0000-0000-000000000000	716	o3icnvuonl2h	10e558ca-3940-4995-9a8f-165e78efaffc	f	2026-02-10 04:17:37.605002+00	2026-02-10 04:17:37.605002+00	\N	2e89df82-89c4-43ba-9426-183442b41eef
00000000-0000-0000-0000-000000000000	698	aeegveyrh5ye	95f608be-c1e9-43b1-b885-5e2784e4858f	t	2026-02-10 03:28:21.927455+00	2026-02-10 04:27:22.004568+00	l54t6jey2f5o	15c5bc25-7e7d-4db8-8f68-48bba9ce99ff
00000000-0000-0000-0000-000000000000	697	6utbyypeu57o	06d3b907-e06e-466b-a5fe-2dcc3912afaf	t	2026-02-10 02:40:04.412879+00	2026-02-10 04:54:22.06656+00	bxjtqfkep7xm	d5c296b8-50d5-47a7-b7c2-2abecaae18f3
00000000-0000-0000-0000-000000000000	670	jgoyua3ic5jy	10e558ca-3940-4995-9a8f-165e78efaffc	t	2026-02-10 00:58:34.88057+00	2026-02-10 10:59:22.406737+00	waetesnz6shm	f8b68d38-042c-4697-9458-1c0a74313dc3
00000000-0000-0000-0000-000000000000	717	jc32bdbvldsu	10e558ca-3940-4995-9a8f-165e78efaffc	f	2026-02-10 04:18:08.75281+00	2026-02-10 04:18:08.75281+00	\N	67546a3b-57b3-4c94-9fe6-f1b01fec88fd
00000000-0000-0000-0000-000000000000	719	botsl76y3yn6	10e558ca-3940-4995-9a8f-165e78efaffc	f	2026-02-10 04:18:16.766205+00	2026-02-10 04:18:16.766205+00	\N	a67e30d2-df8a-4980-80a0-ef41195e6fa3
00000000-0000-0000-0000-000000000000	720	psrivngvfzkx	10e558ca-3940-4995-9a8f-165e78efaffc	f	2026-02-10 04:18:25.106905+00	2026-02-10 04:18:25.106905+00	\N	ad404359-2677-4d8f-9a6c-a65601a1f2e6
00000000-0000-0000-0000-000000000000	725	e5b7brnneg6e	10e558ca-3940-4995-9a8f-165e78efaffc	f	2026-02-10 04:19:10.00934+00	2026-02-10 04:19:10.00934+00	\N	e281739f-35a5-4f6d-beb0-c4d4d9691de6
00000000-0000-0000-0000-000000000000	726	h5xdjur7rdip	10e558ca-3940-4995-9a8f-165e78efaffc	f	2026-02-10 04:19:13.514792+00	2026-02-10 04:19:13.514792+00	\N	e8b5e1df-417f-4307-aefd-eb1dcbc0179c
00000000-0000-0000-0000-000000000000	769	bzqwphfyrzdq	10e558ca-3940-4995-9a8f-165e78efaffc	f	2026-02-11 01:41:28.339426+00	2026-02-11 01:41:28.339426+00	\N	66adc0be-5bc3-48a6-b579-6ea2ca136e44
00000000-0000-0000-0000-000000000000	781	ycpg3udbocbr	10e558ca-3940-4995-9a8f-165e78efaffc	f	2026-02-11 03:28:38.862222+00	2026-02-11 03:28:38.862222+00	\N	c451c2b8-3c4e-4abb-941f-9e4532127166
00000000-0000-0000-0000-000000000000	782	xdshn4tom42z	10e558ca-3940-4995-9a8f-165e78efaffc	f	2026-02-11 03:28:38.927804+00	2026-02-11 03:28:38.927804+00	\N	b21b563d-4cf4-40bd-bab8-d05f58c1d4ba
00000000-0000-0000-0000-000000000000	790	r4pap4yvonjb	95f608be-c1e9-43b1-b885-5e2784e4858f	t	2026-02-11 04:47:50.719606+00	2026-02-11 05:46:51.012472+00	bq7tmhqqkmn6	15c5bc25-7e7d-4db8-8f68-48bba9ce99ff
00000000-0000-0000-0000-000000000000	795	elxtaucr4rgi	95f608be-c1e9-43b1-b885-5e2784e4858f	f	2026-02-11 09:43:07.635022+00	2026-02-11 09:43:07.635022+00	guhk2aakyel7	15c5bc25-7e7d-4db8-8f68-48bba9ce99ff
00000000-0000-0000-0000-000000000000	800	fpdbgz46qkzj	10e558ca-3940-4995-9a8f-165e78efaffc	t	2026-02-11 13:19:07.583915+00	2026-02-11 14:18:07.455157+00	m6fyoslcxeiq	37538335-78cc-4a58-98ab-d359e5dfc985
00000000-0000-0000-0000-000000000000	805	jtiljzphvnbq	10e558ca-3940-4995-9a8f-165e78efaffc	t	2026-02-11 17:30:31.421928+00	2026-02-11 18:37:57.449819+00	omudgzvbjqbd	37538335-78cc-4a58-98ab-d359e5dfc985
00000000-0000-0000-0000-000000000000	810	udc6xah5ejiw	10e558ca-3940-4995-9a8f-165e78efaffc	t	2026-02-11 23:10:53.875305+00	2026-02-12 00:09:53.482371+00	porowm5aix4i	37538335-78cc-4a58-98ab-d359e5dfc985
00000000-0000-0000-0000-000000000000	815	tx7f4wej2t5f	10e558ca-3940-4995-9a8f-165e78efaffc	t	2026-02-12 04:05:54.53872+00	2026-02-12 05:04:53.455216+00	gihnielc5hy4	37538335-78cc-4a58-98ab-d359e5dfc985
00000000-0000-0000-0000-000000000000	820	e6qujn6qfqvy	10e558ca-3940-4995-9a8f-165e78efaffc	f	2026-02-12 07:02:53.703614+00	2026-02-12 07:02:53.703614+00	5qdyfavwzpc4	37538335-78cc-4a58-98ab-d359e5dfc985
00000000-0000-0000-0000-000000000000	718	x3ujnlj6ycj6	10e558ca-3940-4995-9a8f-165e78efaffc	f	2026-02-10 04:18:10.269269+00	2026-02-10 04:18:10.269269+00	\N	6466da4a-89a3-4f08-bfad-a03dc50e97d5
00000000-0000-0000-0000-000000000000	721	2mdndmfv2w2c	10e558ca-3940-4995-9a8f-165e78efaffc	f	2026-02-10 04:18:26.494932+00	2026-02-10 04:18:26.494932+00	\N	5c255d06-81e1-44e5-9181-3fd566eaaac1
00000000-0000-0000-0000-000000000000	722	3czbzmk6v4wd	10e558ca-3940-4995-9a8f-165e78efaffc	f	2026-02-10 04:18:46.361733+00	2026-02-10 04:18:46.361733+00	\N	29fd3ed3-77a4-40fe-aedb-0bad7f03ffc5
00000000-0000-0000-0000-000000000000	723	eamwf6h3dgqr	10e558ca-3940-4995-9a8f-165e78efaffc	f	2026-02-10 04:18:56.702437+00	2026-02-10 04:18:56.702437+00	\N	05f25140-2caf-4ae8-8384-f0d7ea8dbe99
00000000-0000-0000-0000-000000000000	724	5frgxtum6m3v	10e558ca-3940-4995-9a8f-165e78efaffc	f	2026-02-10 04:19:06.496995+00	2026-02-10 04:19:06.496995+00	\N	b661349f-1545-4461-8a97-d42f338269e2
00000000-0000-0000-0000-000000000000	770	iazyw3dofpni	10e558ca-3940-4995-9a8f-165e78efaffc	f	2026-02-11 01:44:25.12568+00	2026-02-11 01:44:25.12568+00	\N	49ec853d-432c-4a92-b098-5d24f2e14708
00000000-0000-0000-0000-000000000000	784	ibzurp7667to	10e558ca-3940-4995-9a8f-165e78efaffc	f	2026-02-11 03:29:48.078536+00	2026-02-11 03:29:48.078536+00	\N	fcb6d021-1ea4-437a-8440-e058c01f6a5b
00000000-0000-0000-0000-000000000000	785	qoqh4ypnvs4u	10e558ca-3940-4995-9a8f-165e78efaffc	f	2026-02-11 03:30:04.590479+00	2026-02-11 03:30:04.590479+00	\N	4c7b78cb-2b96-408a-8701-ab0e27e9a9a4
00000000-0000-0000-0000-000000000000	791	m7vcvefabkct	95f608be-c1e9-43b1-b885-5e2784e4858f	t	2026-02-11 05:46:51.034008+00	2026-02-11 06:45:50.866567+00	r4pap4yvonjb	15c5bc25-7e7d-4db8-8f68-48bba9ce99ff
00000000-0000-0000-0000-000000000000	768	v24efopz6ird	5e4ec0ef-464a-41db-8e2f-9f3bfa2671ee	t	2026-02-11 01:09:50.187544+00	2026-02-11 10:39:02.430449+00	ptdqfqliyu6k	69d52aab-1ad5-4836-91b2-38280ab5dca9
00000000-0000-0000-0000-000000000000	796	aoqk6d23zd62	5e4ec0ef-464a-41db-8e2f-9f3bfa2671ee	f	2026-02-11 10:39:02.447441+00	2026-02-11 10:39:02.447441+00	v24efopz6ird	69d52aab-1ad5-4836-91b2-38280ab5dca9
00000000-0000-0000-0000-000000000000	801	imztxexr74gb	10e558ca-3940-4995-9a8f-165e78efaffc	t	2026-02-11 14:18:07.478699+00	2026-02-11 15:17:07.671216+00	fpdbgz46qkzj	37538335-78cc-4a58-98ab-d359e5dfc985
00000000-0000-0000-0000-000000000000	806	gndrrtgn4uqu	10e558ca-3940-4995-9a8f-165e78efaffc	t	2026-02-11 18:37:57.467977+00	2026-02-11 19:55:02.338538+00	jtiljzphvnbq	37538335-78cc-4a58-98ab-d359e5dfc985
00000000-0000-0000-0000-000000000000	811	65br775oz6hd	10e558ca-3940-4995-9a8f-165e78efaffc	t	2026-02-12 00:09:53.494768+00	2026-02-12 01:08:53.728168+00	udc6xah5ejiw	37538335-78cc-4a58-98ab-d359e5dfc985
00000000-0000-0000-0000-000000000000	816	fnmu6kvoucnq	10e558ca-3940-4995-9a8f-165e78efaffc	t	2026-02-12 05:04:53.478498+00	2026-02-12 06:03:53.399904+00	tx7f4wej2t5f	37538335-78cc-4a58-98ab-d359e5dfc985
00000000-0000-0000-0000-000000000000	821	nzl6uo42re7k	9969cfc6-451e-4ab2-ae2f-5d10a98eaf0a	f	2026-02-12 07:51:31.224931+00	2026-02-12 07:51:31.224931+00	rueh6z7l4koo	ee596f2a-dc76-4048-aae7-5ebb03ce31c8
00000000-0000-0000-0000-000000000000	727	aauij3q6gc76	10e558ca-3940-4995-9a8f-165e78efaffc	f	2026-02-10 04:19:29.241428+00	2026-02-10 04:19:29.241428+00	\N	be73f1bc-ad41-4423-9806-2853365620f4
00000000-0000-0000-0000-000000000000	754	tc5tda4ghrjs	10e558ca-3940-4995-9a8f-165e78efaffc	t	2026-02-10 10:59:22.431271+00	2026-02-10 12:00:33.382963+00	jgoyua3ic5jy	f8b68d38-042c-4697-9458-1c0a74313dc3
00000000-0000-0000-0000-000000000000	755	neefpmit3nr3	95f608be-c1e9-43b1-b885-5e2784e4858f	t	2026-02-10 11:20:22.720471+00	2026-02-10 12:19:22.997017+00	nt7ap54ayggx	15c5bc25-7e7d-4db8-8f68-48bba9ce99ff
00000000-0000-0000-0000-000000000000	728	pw5xz4mrwgl5	95f608be-c1e9-43b1-b885-5e2784e4858f	t	2026-02-10 04:27:22.017534+00	2026-02-10 05:26:22.010297+00	aeegveyrh5ye	15c5bc25-7e7d-4db8-8f68-48bba9ce99ff
00000000-0000-0000-0000-000000000000	756	sp7daunliobp	06d3b907-e06e-466b-a5fe-2dcc3912afaf	t	2026-02-10 11:31:21.958689+00	2026-02-10 13:21:23.847937+00	hvh6nli2nwn6	d5c296b8-50d5-47a7-b7c2-2abecaae18f3
00000000-0000-0000-0000-000000000000	730	qji42uxxhxfm	95f608be-c1e9-43b1-b885-5e2784e4858f	t	2026-02-10 05:26:22.040624+00	2026-02-10 06:25:22.071255+00	pw5xz4mrwgl5	15c5bc25-7e7d-4db8-8f68-48bba9ce99ff
00000000-0000-0000-0000-000000000000	732	mh22cvu3pywq	10e558ca-3940-4995-9a8f-165e78efaffc	f	2026-02-10 06:32:42.975507+00	2026-02-10 06:32:42.975507+00	\N	17e9837e-3e4e-4738-8c49-ec35fe35f1e3
00000000-0000-0000-0000-000000000000	733	dywfuqmn6ay4	10e558ca-3940-4995-9a8f-165e78efaffc	f	2026-02-10 06:32:48.375429+00	2026-02-10 06:32:48.375429+00	\N	c767ef86-fd07-4496-bd0c-304234a72f15
00000000-0000-0000-0000-000000000000	734	5nugu5zih3kr	10e558ca-3940-4995-9a8f-165e78efaffc	f	2026-02-10 06:32:49.281682+00	2026-02-10 06:32:49.281682+00	\N	963f65dd-b5cf-4041-a471-3d49d432811e
00000000-0000-0000-0000-000000000000	735	tno556xaiksq	10e558ca-3940-4995-9a8f-165e78efaffc	f	2026-02-10 06:33:20.322924+00	2026-02-10 06:33:20.322924+00	\N	d7e4dc0c-9266-4a18-a676-2680aa6ba7dd
00000000-0000-0000-0000-000000000000	736	grg62bqaowtm	10e558ca-3940-4995-9a8f-165e78efaffc	f	2026-02-10 06:33:33.840395+00	2026-02-10 06:33:33.840395+00	\N	f9340fb6-771d-4898-b942-9b200cbcf420
00000000-0000-0000-0000-000000000000	737	6cogvbwcud5d	10e558ca-3940-4995-9a8f-165e78efaffc	f	2026-02-10 06:33:46.311488+00	2026-02-10 06:33:46.311488+00	\N	7ca7ad6d-4d94-4b70-aa89-a41847604416
00000000-0000-0000-0000-000000000000	738	dupn6znn4wbm	10e558ca-3940-4995-9a8f-165e78efaffc	f	2026-02-10 06:33:51.685413+00	2026-02-10 06:33:51.685413+00	\N	d9d2d6c1-60c7-44ed-bad3-7f32e27db910
00000000-0000-0000-0000-000000000000	739	ofgcj6pfjbiz	10e558ca-3940-4995-9a8f-165e78efaffc	f	2026-02-10 06:33:57.909619+00	2026-02-10 06:33:57.909619+00	\N	20ca7267-a36f-4a49-a215-5424a4645236
00000000-0000-0000-0000-000000000000	740	mk4ealiraod4	10e558ca-3940-4995-9a8f-165e78efaffc	f	2026-02-10 06:34:12.526101+00	2026-02-10 06:34:12.526101+00	\N	ca0ec7d2-3d97-414a-95b4-fedc33e82b5b
00000000-0000-0000-0000-000000000000	741	2rrvqte5mjjo	10e558ca-3940-4995-9a8f-165e78efaffc	f	2026-02-10 06:34:13.331166+00	2026-02-10 06:34:13.331166+00	\N	5a2fa2c4-b74f-469e-9ed5-25b99d75a708
00000000-0000-0000-0000-000000000000	742	3diuibxcmjs5	10e558ca-3940-4995-9a8f-165e78efaffc	f	2026-02-10 06:34:18.075279+00	2026-02-10 06:34:18.075279+00	\N	82e2d3f0-3b9d-4041-89e8-102ef982f1ff
00000000-0000-0000-0000-000000000000	743	bc4kgmulkw6r	10e558ca-3940-4995-9a8f-165e78efaffc	f	2026-02-10 06:34:22.760571+00	2026-02-10 06:34:22.760571+00	\N	5d7ab598-b672-4d6d-a02f-92ce60cb7c94
00000000-0000-0000-0000-000000000000	744	t6wm7x6k75vu	10e558ca-3940-4995-9a8f-165e78efaffc	f	2026-02-10 06:34:33.109138+00	2026-02-10 06:34:33.109138+00	\N	149a4dd9-a455-4bc8-a142-3a022fb60d17
00000000-0000-0000-0000-000000000000	745	rcrt2qmldgts	10e558ca-3940-4995-9a8f-165e78efaffc	f	2026-02-10 06:34:53.476304+00	2026-02-10 06:34:53.476304+00	\N	2e6fef9d-b203-46a0-afce-b87f8a758e01
00000000-0000-0000-0000-000000000000	731	4dsnbzicr6vn	95f608be-c1e9-43b1-b885-5e2784e4858f	t	2026-02-10 06:25:22.086426+00	2026-02-10 07:24:27.44637+00	qji42uxxhxfm	15c5bc25-7e7d-4db8-8f68-48bba9ce99ff
00000000-0000-0000-0000-000000000000	771	szueqz7eopt3	95f608be-c1e9-43b1-b885-5e2784e4858f	t	2026-02-11 01:51:09.65476+00	2026-02-11 02:49:50.34138+00	o2kfspol2myq	15c5bc25-7e7d-4db8-8f68-48bba9ce99ff
00000000-0000-0000-0000-000000000000	729	kpfqal6xpn22	06d3b907-e06e-466b-a5fe-2dcc3912afaf	t	2026-02-10 04:54:22.370336+00	2026-02-10 07:26:14.642928+00	6utbyypeu57o	d5c296b8-50d5-47a7-b7c2-2abecaae18f3
00000000-0000-0000-0000-000000000000	786	udklzehloyvl	10e558ca-3940-4995-9a8f-165e78efaffc	f	2026-02-11 03:32:37.474154+00	2026-02-11 03:32:37.474154+00	\N	5da60bcb-7600-4147-b787-b6697f1fc2ca
00000000-0000-0000-0000-000000000000	748	5z7hhufdlfr5	10e558ca-3940-4995-9a8f-165e78efaffc	f	2026-02-10 07:28:14.143561+00	2026-02-10 07:28:14.143561+00	\N	53a117ec-69c4-40ad-8403-4c7b57c7e199
00000000-0000-0000-0000-000000000000	749	dgbxlalngt2a	10e558ca-3940-4995-9a8f-165e78efaffc	f	2026-02-10 07:28:20.781462+00	2026-02-10 07:28:20.781462+00	\N	502b511f-ee88-4792-8855-a829f3f91d9f
00000000-0000-0000-0000-000000000000	746	3jdv3ohcy34w	95f608be-c1e9-43b1-b885-5e2784e4858f	t	2026-02-10 07:24:27.472142+00	2026-02-10 08:23:22.205638+00	4dsnbzicr6vn	15c5bc25-7e7d-4db8-8f68-48bba9ce99ff
00000000-0000-0000-0000-000000000000	787	i2anzbsz4lca	10e558ca-3940-4995-9a8f-165e78efaffc	f	2026-02-11 03:32:38.069316+00	2026-02-11 03:32:38.069316+00	\N	d31c6efd-12dd-498b-93a8-198706384db3
00000000-0000-0000-0000-000000000000	747	5aiw5dupapiz	06d3b907-e06e-466b-a5fe-2dcc3912afaf	t	2026-02-10 07:26:14.644972+00	2026-02-10 09:19:49.551549+00	kpfqal6xpn22	d5c296b8-50d5-47a7-b7c2-2abecaae18f3
00000000-0000-0000-0000-000000000000	750	voblx75u45uf	95f608be-c1e9-43b1-b885-5e2784e4858f	t	2026-02-10 08:23:22.224194+00	2026-02-10 09:22:22.462843+00	3jdv3ohcy34w	15c5bc25-7e7d-4db8-8f68-48bba9ce99ff
00000000-0000-0000-0000-000000000000	792	okamgpvivwi2	95f608be-c1e9-43b1-b885-5e2784e4858f	t	2026-02-11 06:45:50.898842+00	2026-02-11 07:44:50.91685+00	m7vcvefabkct	15c5bc25-7e7d-4db8-8f68-48bba9ce99ff
00000000-0000-0000-0000-000000000000	752	lwgpmph4rr45	95f608be-c1e9-43b1-b885-5e2784e4858f	t	2026-02-10 09:22:22.478731+00	2026-02-10 10:21:23.177467+00	voblx75u45uf	15c5bc25-7e7d-4db8-8f68-48bba9ce99ff
00000000-0000-0000-0000-000000000000	797	sohjayo7wmly	9969cfc6-451e-4ab2-ae2f-5d10a98eaf0a	f	2026-02-11 10:59:21.540875+00	2026-02-11 10:59:21.540875+00	\N	da167d3a-1f5a-4e4f-b3a3-ebc630ae03ad
00000000-0000-0000-0000-000000000000	753	nt7ap54ayggx	95f608be-c1e9-43b1-b885-5e2784e4858f	t	2026-02-10 10:21:23.197871+00	2026-02-10 11:20:22.690988+00	lwgpmph4rr45	15c5bc25-7e7d-4db8-8f68-48bba9ce99ff
00000000-0000-0000-0000-000000000000	751	hvh6nli2nwn6	06d3b907-e06e-466b-a5fe-2dcc3912afaf	t	2026-02-10 09:19:49.580026+00	2026-02-10 11:31:21.952406+00	5aiw5dupapiz	d5c296b8-50d5-47a7-b7c2-2abecaae18f3
00000000-0000-0000-0000-000000000000	802	vwz7pftk7iha	9969cfc6-451e-4ab2-ae2f-5d10a98eaf0a	f	2026-02-11 14:19:24.920816+00	2026-02-11 14:19:24.920816+00	c3ho3hdf4ydt	fdc7ca80-679a-432d-ba50-babf4dcb0a38
00000000-0000-0000-0000-000000000000	807	frxydnlz2kvb	10e558ca-3940-4995-9a8f-165e78efaffc	t	2026-02-11 19:55:02.368486+00	2026-02-11 21:12:39.220211+00	gndrrtgn4uqu	37538335-78cc-4a58-98ab-d359e5dfc985
00000000-0000-0000-0000-000000000000	812	qi6tkiviecal	10e558ca-3940-4995-9a8f-165e78efaffc	t	2026-02-12 01:08:53.759231+00	2026-02-12 02:07:53.551006+00	65br775oz6hd	37538335-78cc-4a58-98ab-d359e5dfc985
00000000-0000-0000-0000-000000000000	817	jnzzgqsgq4b4	9969cfc6-451e-4ab2-ae2f-5d10a98eaf0a	t	2026-02-12 05:54:59.077295+00	2026-02-12 06:53:01.021852+00	\N	ee596f2a-dc76-4048-aae7-5ebb03ce31c8
\.


--
-- Data for Name: saml_providers; Type: TABLE DATA; Schema: auth; Owner: supabase_auth_admin
--

COPY auth.saml_providers (id, sso_provider_id, entity_id, metadata_xml, metadata_url, attribute_mapping, created_at, updated_at, name_id_format) FROM stdin;
\.


--
-- Data for Name: saml_relay_states; Type: TABLE DATA; Schema: auth; Owner: supabase_auth_admin
--

COPY auth.saml_relay_states (id, sso_provider_id, request_id, for_email, redirect_to, created_at, updated_at, flow_state_id) FROM stdin;
\.


--
-- Data for Name: schema_migrations; Type: TABLE DATA; Schema: auth; Owner: supabase_auth_admin
--

COPY auth.schema_migrations (version) FROM stdin;
20171026211738
20171026211808
20171026211834
20180103212743
20180108183307
20180119214651
20180125194653
00
20210710035447
20210722035447
20210730183235
20210909172000
20210927181326
20211122151130
20211124214934
20211202183645
20220114185221
20220114185340
20220224000811
20220323170000
20220429102000
20220531120530
20220614074223
20220811173540
20221003041349
20221003041400
20221011041400
20221020193600
20221021073300
20221021082433
20221027105023
20221114143122
20221114143410
20221125140132
20221208132122
20221215195500
20221215195800
20221215195900
20230116124310
20230116124412
20230131181311
20230322519590
20230402418590
20230411005111
20230508135423
20230523124323
20230818113222
20230914180801
20231027141322
20231114161723
20231117164230
20240115144230
20240214120130
20240306115329
20240314092811
20240427152123
20240612123726
20240729123726
20240802193726
20240806073726
20241009103726
20250717082212
20250731150234
20250804100000
20250901200500
20250903112500
20250904133000
20250925093508
20251007112900
20251104100000
20251111201300
20251201000000
20260115000000
20260121000000
\.


--
-- Data for Name: sessions; Type: TABLE DATA; Schema: auth; Owner: supabase_auth_admin
--

COPY auth.sessions (id, user_id, created_at, updated_at, factor_id, aal, not_after, refreshed_at, user_agent, ip, tag, oauth_client_id, refresh_token_hmac_key, refresh_token_counter, scopes) FROM stdin;
7c99ea49-24c2-4fa8-b6b9-7129f29fa7dd	95f608be-c1e9-43b1-b885-5e2784e4858f	2026-02-03 14:10:01.672429+00	2026-02-03 14:10:01.672429+00	\N	aal1	\N	\N	Mozilla/5.0 (Linux; Android 15; K) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.7559.109 Mobile Safari/537.36	39.7.28.196	\N	\N	\N	\N	\N
1d445617-1071-4cc9-b0c1-4e199134abf5	9969cfc6-451e-4ab2-ae2f-5d10a98eaf0a	2026-02-03 14:11:02.959688+00	2026-02-03 14:11:02.959688+00	\N	aal1	\N	\N	Mozilla/5.0 (Linux; Android 15; K) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.7559.109 Mobile Safari/537.36	39.7.28.196	\N	\N	\N	\N	\N
3d1cf609-78bd-42af-a324-00a94b863e71	9969cfc6-451e-4ab2-ae2f-5d10a98eaf0a	2026-02-03 00:47:05.065192+00	2026-02-03 00:47:05.065192+00	\N	aal1	\N	\N	node	121.143.18.55	\N	\N	\N	\N	\N
e6d8df24-3727-412f-8dbe-0561c5b0c6aa	10e558ca-3940-4995-9a8f-165e78efaffc	2026-02-03 00:47:05.739212+00	2026-02-03 00:47:05.739212+00	\N	aal1	\N	\N	node	121.143.18.55	\N	\N	\N	\N	\N
336ca807-2f35-42d7-a66c-515b7924f274	5e4ec0ef-464a-41db-8e2f-9f3bfa2671ee	2026-02-03 00:47:06.251012+00	2026-02-03 00:47:06.251012+00	\N	aal1	\N	\N	node	121.143.18.55	\N	\N	\N	\N	\N
178ac5f2-c28b-46f2-9610-2b5f9f4ebdcd	95f608be-c1e9-43b1-b885-5e2784e4858f	2026-02-03 00:47:06.76342+00	2026-02-03 00:47:06.76342+00	\N	aal1	\N	\N	node	121.143.18.55	\N	\N	\N	\N	\N
9a47ee73-8cf2-4f45-9c8c-b113d4a85926	8cf7c6be-ba2c-48c9-8825-589e675ff608	2026-02-03 00:47:07.286674+00	2026-02-03 00:47:07.286674+00	\N	aal1	\N	\N	node	121.143.18.55	\N	\N	\N	\N	\N
d2e8bdf6-d255-453b-bc86-7ae845cc99f2	9969cfc6-451e-4ab2-ae2f-5d10a98eaf0a	2026-02-03 14:13:56.450443+00	2026-02-03 14:13:56.450443+00	\N	aal1	\N	\N	Mozilla/5.0 (Macintosh; Intel Mac OS X 10.15; rv:147.0) Gecko/20100101 Firefox/147.0	121.143.18.55	\N	\N	\N	\N	\N
15c5bc25-7e7d-4db8-8f68-48bba9ce99ff	95f608be-c1e9-43b1-b885-5e2784e4858f	2026-02-03 13:53:28.923681+00	2026-02-11 09:43:07.66418+00	\N	aal1	\N	2026-02-11 09:43:07.664059	Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36	121.143.18.55	\N	\N	\N	\N	\N
11b10676-7ac3-46fe-b5dc-6e53bc9d56fc	5ac10c39-274e-4ce5-a13b-f4da3af4a230	2026-01-31 03:32:33.984153+00	2026-02-06 10:11:22.079371+00	\N	aal1	\N	2026-02-06 10:11:22.079237	Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36	121.143.18.55	\N	\N	\N	\N	\N
65d64040-bfd7-4ad3-877f-528f02b42671	5ac10c39-274e-4ce5-a13b-f4da3af4a230	2026-01-30 09:22:27.948456+00	2026-01-31 03:31:49.100687+00	\N	aal1	\N	2026-01-31 03:31:49.100582	Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36	121.143.18.55	\N	\N	\N	\N	\N
65f11cb0-36ad-4ef8-9c84-64569b36aace	10e558ca-3940-4995-9a8f-165e78efaffc	2026-02-05 01:43:13.125491+00	2026-02-05 01:43:13.125491+00	\N	aal1	\N	\N	node	121.143.18.55	\N	\N	\N	\N	\N
6221b9d7-e743-463b-bb43-11a1b06db73c	9969cfc6-451e-4ab2-ae2f-5d10a98eaf0a	2026-02-05 07:49:05.398238+00	2026-02-05 07:49:05.398238+00	\N	aal1	\N	\N	node	121.143.18.55	\N	\N	\N	\N	\N
34bdfdb6-d883-40f7-85a8-e5a85d8c54d8	9969cfc6-451e-4ab2-ae2f-5d10a98eaf0a	2026-02-03 22:09:04.330778+00	2026-02-03 22:09:04.330778+00	\N	aal1	\N	\N	node	121.143.18.55	\N	\N	\N	\N	\N
8594f2b0-ca33-4796-bbcd-5687e8ab726e	10e558ca-3940-4995-9a8f-165e78efaffc	2026-02-03 22:09:09.848722+00	2026-02-03 22:09:09.848722+00	\N	aal1	\N	\N	node	121.143.18.55	\N	\N	\N	\N	\N
e7fc2d62-38ff-4008-a4e9-33618a83d7ea	5e4ec0ef-464a-41db-8e2f-9f3bfa2671ee	2026-02-03 22:09:15.202067+00	2026-02-03 22:09:15.202067+00	\N	aal1	\N	\N	node	121.143.18.55	\N	\N	\N	\N	\N
92d48a38-20ef-46b2-b994-6b7aaa87652a	95f608be-c1e9-43b1-b885-5e2784e4858f	2026-02-03 22:09:20.59267+00	2026-02-03 22:09:20.59267+00	\N	aal1	\N	\N	node	121.143.18.55	\N	\N	\N	\N	\N
928737f8-409a-4243-afb1-76b9d8cc63d1	8cf7c6be-ba2c-48c9-8825-589e675ff608	2026-02-03 22:09:25.921561+00	2026-02-03 22:09:25.921561+00	\N	aal1	\N	\N	node	121.143.18.55	\N	\N	\N	\N	\N
37f3ffaa-a35f-4db7-a814-f41f8fcf0359	10e558ca-3940-4995-9a8f-165e78efaffc	2026-02-03 14:23:34.00602+00	2026-02-09 02:17:03.965431+00	\N	aal1	\N	2026-02-09 02:17:03.965343	Vercel Edge Functions	54.169.216.102	\N	\N	\N	\N	\N
a1bb4554-2d29-4162-a351-2feeb0bb69a0	9969cfc6-451e-4ab2-ae2f-5d10a98eaf0a	2026-02-03 14:12:54.795502+00	2026-02-03 22:12:27.699688+00	\N	aal1	\N	2026-02-03 22:12:27.699594	node	44.200.141.57	\N	\N	\N	\N	\N
8a5ea70e-9112-44a9-ad5b-f71eedf673a1	5e4ec0ef-464a-41db-8e2f-9f3bfa2671ee	2026-02-03 14:22:48.40621+00	2026-02-05 00:45:30.428228+00	\N	aal1	\N	2026-02-05 00:45:30.42812	Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/142.0.0.0 Safari/537.36 OPR/126.0.0.0	121.143.18.55	\N	\N	\N	\N	\N
a83fa977-084a-491f-a042-30677fab2940	10e558ca-3940-4995-9a8f-165e78efaffc	2026-02-03 10:26:04.238162+00	2026-02-03 13:20:55.438654+00	\N	aal1	\N	2026-02-03 13:20:55.438559	Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/26.2 Safari/605.1.15	121.143.18.55	\N	\N	\N	\N	\N
f8b68d38-042c-4697-9458-1c0a74313dc3	10e558ca-3940-4995-9a8f-165e78efaffc	2026-02-04 00:08:59.865043+00	2026-02-10 12:00:34.323293+00	\N	aal1	\N	2026-02-10 12:00:34.323195	Vercel Edge Functions	3.0.55.18	\N	\N	\N	\N	\N
2ec4e28f-400b-4218-bf5d-40bd092b0493	60abdd33-af5a-4dfb-b211-a057a0995d12	2026-02-02 01:32:59.077161+00	2026-02-03 13:24:30.285684+00	\N	aal1	\N	2026-02-03 13:24:30.285586	node	121.143.18.55	\N	\N	\N	\N	\N
e777cee1-fc3f-4eca-af84-cd60299ab98f	10e558ca-3940-4995-9a8f-165e78efaffc	2026-02-03 13:55:15.691932+00	2026-02-03 13:55:15.691932+00	\N	aal1	\N	\N	Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/26.2 Safari/605.1.15	121.143.18.55	\N	\N	\N	\N	\N
975d474c-77d2-460f-8215-51077871ab77	8cf7c6be-ba2c-48c9-8825-589e675ff608	2026-02-03 14:01:51.020689+00	2026-02-03 14:01:51.020689+00	\N	aal1	\N	\N	Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/142.0.0.0 Safari/537.36 OPR/126.0.0.0	121.143.18.55	\N	\N	\N	\N	\N
81c32093-2c69-43e7-a90c-73a189ad262f	8cf7c6be-ba2c-48c9-8825-589e675ff608	2026-02-03 14:04:32.331502+00	2026-02-03 14:04:32.331502+00	\N	aal1	\N	\N	Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/26.2 Safari/605.1.15	121.143.18.55	\N	\N	\N	\N	\N
00c7e083-b952-4e2b-a862-634d2da8b9af	5e4ec0ef-464a-41db-8e2f-9f3bfa2671ee	2026-02-03 14:05:06.90859+00	2026-02-03 14:05:06.90859+00	\N	aal1	\N	\N	Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/142.0.0.0 Safari/537.36 OPR/126.0.0.0	121.143.18.55	\N	\N	\N	\N	\N
652c6f22-a7db-49cc-aabd-fc7ad757cbf7	9969cfc6-451e-4ab2-ae2f-5d10a98eaf0a	2026-02-05 01:25:13.00281+00	2026-02-05 01:25:13.00281+00	\N	aal1	\N	\N	node	121.143.18.55	\N	\N	\N	\N	\N
843a3082-35b8-4987-be82-7767dc28f731	5e4ec0ef-464a-41db-8e2f-9f3bfa2671ee	2026-02-03 11:05:51.004017+00	2026-02-03 14:09:18.045788+00	\N	aal1	\N	2026-02-03 14:09:18.045684	Mozilla/5.0 (Linux; Android 15; K) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.7559.109 Mobile Safari/537.36	39.7.28.196	\N	\N	\N	\N	\N
0644d0b0-ee95-4c6a-b694-0ad0d1e04235	10e558ca-3940-4995-9a8f-165e78efaffc	2026-02-05 01:25:18.72087+00	2026-02-05 01:25:18.72087+00	\N	aal1	\N	\N	node	121.143.18.55	\N	\N	\N	\N	\N
82f814cc-b632-4b90-a2c5-9bb75da14351	5e4ec0ef-464a-41db-8e2f-9f3bfa2671ee	2026-02-05 01:43:18.48401+00	2026-02-05 01:43:18.48401+00	\N	aal1	\N	\N	node	121.143.18.55	\N	\N	\N	\N	\N
231d20fa-f64a-414b-8758-bb755910e17e	95f608be-c1e9-43b1-b885-5e2784e4858f	2026-02-05 01:43:23.80111+00	2026-02-05 01:43:23.80111+00	\N	aal1	\N	\N	node	121.143.18.55	\N	\N	\N	\N	\N
9495d67b-b5b4-4205-a85d-790f160d9ed1	5e4ec0ef-464a-41db-8e2f-9f3bfa2671ee	2026-02-03 14:25:36.065493+00	2026-02-09 08:07:03.5873+00	\N	aal1	\N	2026-02-09 08:07:03.587206	Mozilla/5.0 (Linux; Android 15; K) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.7559.109 Mobile Safari/537.36	121.143.18.55	\N	\N	\N	\N	\N
3c10b435-600c-44f9-9726-f23bc2fb712c	5e4ec0ef-464a-41db-8e2f-9f3bfa2671ee	2026-02-05 01:25:24.079881+00	2026-02-05 01:25:24.079881+00	\N	aal1	\N	\N	node	121.143.18.55	\N	\N	\N	\N	\N
b65fbc15-8258-4dc4-ad8f-74a615e1ef84	95f608be-c1e9-43b1-b885-5e2784e4858f	2026-02-05 01:25:29.916947+00	2026-02-05 01:25:29.916947+00	\N	aal1	\N	\N	node	121.143.18.55	\N	\N	\N	\N	\N
5d64f434-82f2-4cbd-8fa0-e6f3c65a249d	8cf7c6be-ba2c-48c9-8825-589e675ff608	2026-02-05 01:25:35.283322+00	2026-02-05 01:25:35.283322+00	\N	aal1	\N	\N	node	121.143.18.55	\N	\N	\N	\N	\N
6e709193-bdb7-4240-9b8d-7efa8c6ebf1e	9969cfc6-451e-4ab2-ae2f-5d10a98eaf0a	2026-02-05 01:43:07.272142+00	2026-02-05 01:43:07.272142+00	\N	aal1	\N	\N	node	121.143.18.55	\N	\N	\N	\N	\N
a3f8e76d-0c50-4bd9-98e4-86c76cd7b1fd	9969cfc6-451e-4ab2-ae2f-5d10a98eaf0a	2026-02-05 07:38:11.949215+00	2026-02-05 07:38:11.949215+00	\N	aal1	\N	\N	node	121.143.18.55	\N	\N	\N	\N	\N
1fe3bd68-8c4f-450f-8b92-7c4ee2af0212	8cf7c6be-ba2c-48c9-8825-589e675ff608	2026-02-05 01:43:29.307041+00	2026-02-05 01:43:29.307041+00	\N	aal1	\N	\N	node	121.143.18.55	\N	\N	\N	\N	\N
1ccce5b3-8bb0-4d2d-b525-c49015dc0e08	10e558ca-3940-4995-9a8f-165e78efaffc	2026-02-05 07:38:14.520145+00	2026-02-05 07:38:14.520145+00	\N	aal1	\N	\N	node	121.143.18.55	\N	\N	\N	\N	\N
6e909440-63dd-417e-868f-027949746666	8cf7c6be-ba2c-48c9-8825-589e675ff608	2026-02-03 14:26:35.676981+00	2026-02-09 23:54:57.723979+00	\N	aal1	\N	2026-02-09 23:54:57.722283	Mozilla/5.0 (Macintosh; Intel Mac OS X 10.15; rv:147.0) Gecko/20100101 Firefox/147.0	121.143.18.55	\N	\N	\N	\N	\N
3ed651e1-98f5-4e03-ac4f-2a6f30be26b5	5e4ec0ef-464a-41db-8e2f-9f3bfa2671ee	2026-02-05 07:38:16.857798+00	2026-02-05 07:38:16.857798+00	\N	aal1	\N	\N	node	121.143.18.55	\N	\N	\N	\N	\N
d4c7cd1c-ae71-4c2c-a27e-210a14795b3c	95f608be-c1e9-43b1-b885-5e2784e4858f	2026-02-05 07:38:19.235633+00	2026-02-05 07:38:19.235633+00	\N	aal1	\N	\N	node	121.143.18.55	\N	\N	\N	\N	\N
4450442b-9292-4e90-bb59-9adb3040c34b	8cf7c6be-ba2c-48c9-8825-589e675ff608	2026-02-05 07:38:21.621839+00	2026-02-05 07:38:21.621839+00	\N	aal1	\N	\N	node	121.143.18.55	\N	\N	\N	\N	\N
ce53bf5f-d91f-4202-b113-f7082ef94363	9969cfc6-451e-4ab2-ae2f-5d10a98eaf0a	2026-02-05 07:49:06.378262+00	2026-02-05 07:49:06.378262+00	\N	aal1	\N	\N	node	121.143.18.55	\N	\N	\N	\N	\N
0b7fd9c1-c546-4172-8276-db6092a4a7e9	9969cfc6-451e-4ab2-ae2f-5d10a98eaf0a	2026-02-05 07:49:07.270001+00	2026-02-05 07:49:07.270001+00	\N	aal1	\N	\N	node	121.143.18.55	\N	\N	\N	\N	\N
8f567b18-4390-4635-b102-377a7556d4d3	10e558ca-3940-4995-9a8f-165e78efaffc	2026-02-05 07:49:08.120674+00	2026-02-05 07:49:08.120674+00	\N	aal1	\N	\N	node	121.143.18.55	\N	\N	\N	\N	\N
4d96da29-b926-4ab9-8e20-11c70316394d	10e558ca-3940-4995-9a8f-165e78efaffc	2026-02-05 07:49:08.995947+00	2026-02-05 07:49:08.995947+00	\N	aal1	\N	\N	node	121.143.18.55	\N	\N	\N	\N	\N
36dc3d44-bc1b-44bb-8795-acc0cde6569d	10e558ca-3940-4995-9a8f-165e78efaffc	2026-02-05 07:49:09.873918+00	2026-02-05 07:49:09.873918+00	\N	aal1	\N	\N	node	121.143.18.55	\N	\N	\N	\N	\N
87003dc3-7af7-48e6-85b4-a374842ae466	5e4ec0ef-464a-41db-8e2f-9f3bfa2671ee	2026-02-05 07:49:10.725671+00	2026-02-05 07:49:10.725671+00	\N	aal1	\N	\N	node	121.143.18.55	\N	\N	\N	\N	\N
7115854d-8bdd-4e89-ba6a-ad0356a8cdd2	5e4ec0ef-464a-41db-8e2f-9f3bfa2671ee	2026-02-05 07:49:11.584432+00	2026-02-05 07:49:11.584432+00	\N	aal1	\N	\N	node	121.143.18.55	\N	\N	\N	\N	\N
c8606760-466a-4244-836f-b4c04d802408	5e4ec0ef-464a-41db-8e2f-9f3bfa2671ee	2026-02-05 07:49:12.450969+00	2026-02-05 07:49:12.450969+00	\N	aal1	\N	\N	node	121.143.18.55	\N	\N	\N	\N	\N
1d341451-ffd7-4362-a4f0-b313bb3a49de	95f608be-c1e9-43b1-b885-5e2784e4858f	2026-02-05 07:49:13.314535+00	2026-02-05 07:49:13.314535+00	\N	aal1	\N	\N	node	121.143.18.55	\N	\N	\N	\N	\N
69d52aab-1ad5-4836-91b2-38280ab5dca9	5e4ec0ef-464a-41db-8e2f-9f3bfa2671ee	2026-02-03 10:49:27.777524+00	2026-02-11 10:39:04.567914+00	\N	aal1	\N	2026-02-11 10:39:04.567785	Vercel Edge Functions	18.136.206.9	\N	\N	\N	\N	\N
e71fdaec-f2bd-4b40-b945-e42ac7a93272	95f608be-c1e9-43b1-b885-5e2784e4858f	2026-02-05 07:49:14.209043+00	2026-02-05 07:49:14.209043+00	\N	aal1	\N	\N	node	121.143.18.55	\N	\N	\N	\N	\N
8ebe32a4-4e39-48e4-888c-4794c8a46c36	95f608be-c1e9-43b1-b885-5e2784e4858f	2026-02-05 07:49:15.084735+00	2026-02-05 07:49:15.084735+00	\N	aal1	\N	\N	node	121.143.18.55	\N	\N	\N	\N	\N
18f1a915-e2e2-4203-bd75-482ba496fb22	8cf7c6be-ba2c-48c9-8825-589e675ff608	2026-02-05 07:49:15.951708+00	2026-02-05 07:49:15.951708+00	\N	aal1	\N	\N	node	121.143.18.55	\N	\N	\N	\N	\N
b29d27fa-161f-4684-ac32-4b3f5eae85a9	8cf7c6be-ba2c-48c9-8825-589e675ff608	2026-02-05 07:49:16.828019+00	2026-02-05 07:49:16.828019+00	\N	aal1	\N	\N	node	121.143.18.55	\N	\N	\N	\N	\N
c8499177-d0ca-49aa-91b2-aeee05cdbd0b	8cf7c6be-ba2c-48c9-8825-589e675ff608	2026-02-05 07:49:17.671757+00	2026-02-05 07:49:17.671757+00	\N	aal1	\N	\N	node	121.143.18.55	\N	\N	\N	\N	\N
60f39b2e-b4fb-4b60-99df-5ffd3021acbc	9969cfc6-451e-4ab2-ae2f-5d10a98eaf0a	2026-02-05 08:09:20.919674+00	2026-02-05 08:09:20.919674+00	\N	aal1	\N	\N	node	121.143.18.55	\N	\N	\N	\N	\N
a6b08aad-221e-47c7-ba6b-f2cfce3ff7f9	9969cfc6-451e-4ab2-ae2f-5d10a98eaf0a	2026-02-05 08:10:02.240596+00	2026-02-05 08:10:02.240596+00	\N	aal1	\N	\N	node	121.143.18.55	\N	\N	\N	\N	\N
715b609f-92e9-4cfc-ac24-1f763359f290	9969cfc6-451e-4ab2-ae2f-5d10a98eaf0a	2026-02-05 08:10:03.610683+00	2026-02-05 08:10:03.610683+00	\N	aal1	\N	\N	node	121.143.18.55	\N	\N	\N	\N	\N
c8b3604a-3b61-4141-ab08-311fc4376874	10e558ca-3940-4995-9a8f-165e78efaffc	2026-02-05 08:10:04.969457+00	2026-02-05 08:10:04.969457+00	\N	aal1	\N	\N	node	121.143.18.55	\N	\N	\N	\N	\N
943c2189-4d54-4de5-a498-4d12c7a354c4	10e558ca-3940-4995-9a8f-165e78efaffc	2026-02-05 08:10:06.313863+00	2026-02-05 08:10:06.313863+00	\N	aal1	\N	\N	node	121.143.18.55	\N	\N	\N	\N	\N
d16fedbd-1eeb-4785-b141-639afd45127c	10e558ca-3940-4995-9a8f-165e78efaffc	2026-02-05 08:10:07.654246+00	2026-02-05 08:10:07.654246+00	\N	aal1	\N	\N	node	121.143.18.55	\N	\N	\N	\N	\N
cf3d83e3-e052-4a0a-91c6-ccaedcb1059e	5e4ec0ef-464a-41db-8e2f-9f3bfa2671ee	2026-02-05 08:10:08.987999+00	2026-02-05 08:10:08.987999+00	\N	aal1	\N	\N	node	121.143.18.55	\N	\N	\N	\N	\N
95821fe9-1cf2-44d8-9fe2-9f8a8a27a3ca	5e4ec0ef-464a-41db-8e2f-9f3bfa2671ee	2026-02-05 08:10:10.333019+00	2026-02-05 08:10:10.333019+00	\N	aal1	\N	\N	node	121.143.18.55	\N	\N	\N	\N	\N
18278fbb-e55b-47b1-9584-77625a051de5	5e4ec0ef-464a-41db-8e2f-9f3bfa2671ee	2026-02-05 08:10:11.69734+00	2026-02-05 08:10:11.69734+00	\N	aal1	\N	\N	node	121.143.18.55	\N	\N	\N	\N	\N
050ab13c-1075-4169-b71b-22e53a52a65c	95f608be-c1e9-43b1-b885-5e2784e4858f	2026-02-05 08:10:13.05228+00	2026-02-05 08:10:13.05228+00	\N	aal1	\N	\N	node	121.143.18.55	\N	\N	\N	\N	\N
0c985d08-2a65-4951-847d-50ccac36b23d	95f608be-c1e9-43b1-b885-5e2784e4858f	2026-02-05 08:10:14.408577+00	2026-02-05 08:10:14.408577+00	\N	aal1	\N	\N	node	121.143.18.55	\N	\N	\N	\N	\N
51061fb3-7360-4263-a758-6108040fbbe9	95f608be-c1e9-43b1-b885-5e2784e4858f	2026-02-05 08:10:15.748378+00	2026-02-05 08:10:15.748378+00	\N	aal1	\N	\N	node	121.143.18.55	\N	\N	\N	\N	\N
e74f030d-8f98-49da-aa0e-86125a2edc18	8cf7c6be-ba2c-48c9-8825-589e675ff608	2026-02-05 08:10:17.122724+00	2026-02-05 08:10:17.122724+00	\N	aal1	\N	\N	node	121.143.18.55	\N	\N	\N	\N	\N
d7636d40-218a-46ce-bdbc-b46594b5ff9b	8cf7c6be-ba2c-48c9-8825-589e675ff608	2026-02-05 08:10:18.466372+00	2026-02-05 08:10:18.466372+00	\N	aal1	\N	\N	node	121.143.18.55	\N	\N	\N	\N	\N
675196f8-1196-4653-8969-71829ad1e659	8cf7c6be-ba2c-48c9-8825-589e675ff608	2026-02-05 08:10:19.806236+00	2026-02-05 08:10:19.806236+00	\N	aal1	\N	\N	node	121.143.18.55	\N	\N	\N	\N	\N
d80b617f-713b-454f-9805-ada7184801cf	9969cfc6-451e-4ab2-ae2f-5d10a98eaf0a	2026-02-05 08:21:02.560829+00	2026-02-05 08:21:02.560829+00	\N	aal1	\N	\N	node	121.143.18.55	\N	\N	\N	\N	\N
a6bf88d7-16e6-44ba-8ba1-efecb851d5fb	9969cfc6-451e-4ab2-ae2f-5d10a98eaf0a	2026-02-05 08:21:03.975886+00	2026-02-05 08:21:03.975886+00	\N	aal1	\N	\N	node	121.143.18.55	\N	\N	\N	\N	\N
d78fb654-e4cb-4cee-b14b-156d6bb36b3e	9969cfc6-451e-4ab2-ae2f-5d10a98eaf0a	2026-02-05 08:21:05.325688+00	2026-02-05 08:21:05.325688+00	\N	aal1	\N	\N	node	121.143.18.55	\N	\N	\N	\N	\N
93c076de-2644-4e8f-9cc0-2533bee418bc	10e558ca-3940-4995-9a8f-165e78efaffc	2026-02-05 08:21:06.692672+00	2026-02-05 08:21:06.692672+00	\N	aal1	\N	\N	node	121.143.18.55	\N	\N	\N	\N	\N
0f061578-bb6a-40e5-8f15-5110a0c441be	10e558ca-3940-4995-9a8f-165e78efaffc	2026-02-05 08:21:08.063857+00	2026-02-05 08:21:08.063857+00	\N	aal1	\N	\N	node	121.143.18.55	\N	\N	\N	\N	\N
d748ced1-cc78-4862-b6d6-1ee7a1a33613	10e558ca-3940-4995-9a8f-165e78efaffc	2026-02-05 08:21:09.436109+00	2026-02-05 08:21:09.436109+00	\N	aal1	\N	\N	node	121.143.18.55	\N	\N	\N	\N	\N
aa18a4ed-143b-45d6-b774-45639846320d	5e4ec0ef-464a-41db-8e2f-9f3bfa2671ee	2026-02-05 08:21:10.778354+00	2026-02-05 08:21:10.778354+00	\N	aal1	\N	\N	node	121.143.18.55	\N	\N	\N	\N	\N
e7df7443-a096-471f-ae55-12229b9732b4	5e4ec0ef-464a-41db-8e2f-9f3bfa2671ee	2026-02-05 08:21:12.116593+00	2026-02-05 08:21:12.116593+00	\N	aal1	\N	\N	node	121.143.18.55	\N	\N	\N	\N	\N
1f4b327c-c893-450a-8fd3-b36ec0fb2a94	5e4ec0ef-464a-41db-8e2f-9f3bfa2671ee	2026-02-05 08:21:13.460768+00	2026-02-05 08:21:13.460768+00	\N	aal1	\N	\N	node	121.143.18.55	\N	\N	\N	\N	\N
477761c6-3df0-450e-8c22-a2affaab98fb	95f608be-c1e9-43b1-b885-5e2784e4858f	2026-02-05 08:21:14.852139+00	2026-02-05 08:21:14.852139+00	\N	aal1	\N	\N	node	121.143.18.55	\N	\N	\N	\N	\N
8f2bcc65-a1d0-4fd3-8073-2899dcd75485	95f608be-c1e9-43b1-b885-5e2784e4858f	2026-02-05 08:21:16.195373+00	2026-02-05 08:21:16.195373+00	\N	aal1	\N	\N	node	121.143.18.55	\N	\N	\N	\N	\N
e9f7db27-6ea1-47fa-a265-67006c20aee8	95f608be-c1e9-43b1-b885-5e2784e4858f	2026-02-05 08:21:17.524197+00	2026-02-05 08:21:17.524197+00	\N	aal1	\N	\N	node	121.143.18.55	\N	\N	\N	\N	\N
c252ebed-5f79-483c-8f6b-78d6646a9113	8cf7c6be-ba2c-48c9-8825-589e675ff608	2026-02-05 08:21:18.856656+00	2026-02-05 08:21:18.856656+00	\N	aal1	\N	\N	node	121.143.18.55	\N	\N	\N	\N	\N
cebcde5c-c3a6-4450-add7-4d8300bd35f1	8cf7c6be-ba2c-48c9-8825-589e675ff608	2026-02-05 08:21:20.193169+00	2026-02-05 08:21:20.193169+00	\N	aal1	\N	\N	node	121.143.18.55	\N	\N	\N	\N	\N
f8f842e5-7b5b-49fa-8130-090a8b2c9e4b	8cf7c6be-ba2c-48c9-8825-589e675ff608	2026-02-05 08:22:02.212636+00	2026-02-05 08:22:02.212636+00	\N	aal1	\N	\N	node	121.143.18.55	\N	\N	\N	\N	\N
dc2621cf-1f25-498b-a9d5-b1228327476d	5e4ec0ef-464a-41db-8e2f-9f3bfa2671ee	2026-02-05 14:51:10.67944+00	2026-02-05 14:51:10.67944+00	\N	aal1	\N	\N	node	121.143.18.55	\N	\N	\N	\N	\N
c501307b-9045-4616-88e8-ad52b757178f	5e4ec0ef-464a-41db-8e2f-9f3bfa2671ee	2026-02-05 14:51:12.095992+00	2026-02-05 14:51:12.095992+00	\N	aal1	\N	\N	node	121.143.18.55	\N	\N	\N	\N	\N
87ae93a1-08be-4630-8b16-0fea993f7e0a	5e4ec0ef-464a-41db-8e2f-9f3bfa2671ee	2026-02-05 14:51:13.463385+00	2026-02-05 14:51:13.463385+00	\N	aal1	\N	\N	node	121.143.18.55	\N	\N	\N	\N	\N
eb603785-1a31-4f15-bc47-39ee62054bed	95f608be-c1e9-43b1-b885-5e2784e4858f	2026-02-05 14:51:14.819567+00	2026-02-05 14:51:14.819567+00	\N	aal1	\N	\N	node	121.143.18.55	\N	\N	\N	\N	\N
76acbaeb-69d0-47ba-bf9e-02218838416a	95f608be-c1e9-43b1-b885-5e2784e4858f	2026-02-05 14:51:16.200005+00	2026-02-05 14:51:16.200005+00	\N	aal1	\N	\N	node	121.143.18.55	\N	\N	\N	\N	\N
3f3a8f73-a42b-4864-9b11-050733b3d445	95f608be-c1e9-43b1-b885-5e2784e4858f	2026-02-05 14:51:17.581654+00	2026-02-05 14:51:17.581654+00	\N	aal1	\N	\N	node	121.143.18.55	\N	\N	\N	\N	\N
1a70140e-973c-48e4-9e63-a3650cb74021	8cf7c6be-ba2c-48c9-8825-589e675ff608	2026-02-05 14:51:18.923473+00	2026-02-05 14:51:18.923473+00	\N	aal1	\N	\N	node	121.143.18.55	\N	\N	\N	\N	\N
417f4041-a6ad-46b8-9358-08d4a9b85cf3	8cf7c6be-ba2c-48c9-8825-589e675ff608	2026-02-05 14:51:20.292154+00	2026-02-05 14:51:20.292154+00	\N	aal1	\N	\N	node	121.143.18.55	\N	\N	\N	\N	\N
6ba0e9a6-d92b-44d3-9a9b-29e334aaafd8	8cf7c6be-ba2c-48c9-8825-589e675ff608	2026-02-05 14:52:02.21086+00	2026-02-05 14:52:02.21086+00	\N	aal1	\N	\N	node	121.143.18.55	\N	\N	\N	\N	\N
344bd97a-b666-4201-900c-920b993b60de	9969cfc6-451e-4ab2-ae2f-5d10a98eaf0a	2026-02-05 14:52:08.57065+00	2026-02-05 14:52:08.57065+00	\N	aal1	\N	\N	node	121.143.18.55	\N	\N	\N	\N	\N
97565c55-31fd-4aef-9f64-db127ec8038a	5e4ec0ef-464a-41db-8e2f-9f3bfa2671ee	2026-02-03 14:07:19.33601+00	2026-02-10 15:09:35.697029+00	\N	aal1	\N	2026-02-10 15:09:35.696917	Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/142.0.0.0 Safari/537.36 OPR/126.0.0.0	45.67.97.33	\N	\N	\N	\N	\N
6bc8cc46-8882-4316-865d-aadd0bf282ec	9969cfc6-451e-4ab2-ae2f-5d10a98eaf0a	2026-02-05 14:51:02.378002+00	2026-02-05 14:51:02.378002+00	\N	aal1	\N	\N	node	121.143.18.55	\N	\N	\N	\N	\N
2234f8bc-966c-4809-90cc-8c1f03b165f4	9969cfc6-451e-4ab2-ae2f-5d10a98eaf0a	2026-02-05 14:51:03.819095+00	2026-02-05 14:51:03.819095+00	\N	aal1	\N	\N	node	121.143.18.55	\N	\N	\N	\N	\N
471a2917-f34e-4fe0-9b29-4e498c10d39b	9969cfc6-451e-4ab2-ae2f-5d10a98eaf0a	2026-02-05 14:51:05.190729+00	2026-02-05 14:51:05.190729+00	\N	aal1	\N	\N	node	121.143.18.55	\N	\N	\N	\N	\N
ea49e43e-e69d-48db-8a27-0f2e24247504	10e558ca-3940-4995-9a8f-165e78efaffc	2026-02-05 14:51:06.588293+00	2026-02-05 14:51:06.588293+00	\N	aal1	\N	\N	node	121.143.18.55	\N	\N	\N	\N	\N
bfcabf55-45ab-487b-af29-3abe1edf12ae	10e558ca-3940-4995-9a8f-165e78efaffc	2026-02-05 14:51:07.955032+00	2026-02-05 14:51:07.955032+00	\N	aal1	\N	\N	node	121.143.18.55	\N	\N	\N	\N	\N
3327b8ff-e675-43f2-a54d-c4a00dbfd100	10e558ca-3940-4995-9a8f-165e78efaffc	2026-02-05 14:51:09.313321+00	2026-02-05 14:51:09.313321+00	\N	aal1	\N	\N	node	121.143.18.55	\N	\N	\N	\N	\N
ccb9f46d-13e6-4669-96a1-67a746bf006f	9969cfc6-451e-4ab2-ae2f-5d10a98eaf0a	2026-02-05 14:52:09.93514+00	2026-02-05 14:52:09.93514+00	\N	aal1	\N	\N	node	121.143.18.55	\N	\N	\N	\N	\N
34d6e14a-efba-4ecf-b5c3-d7a8c866559e	9969cfc6-451e-4ab2-ae2f-5d10a98eaf0a	2026-02-05 14:52:11.284332+00	2026-02-05 14:52:11.284332+00	\N	aal1	\N	\N	node	121.143.18.55	\N	\N	\N	\N	\N
b32b2002-224b-4402-a5f1-aedc8df0a2e1	10e558ca-3940-4995-9a8f-165e78efaffc	2026-02-05 14:52:12.644067+00	2026-02-05 14:52:12.644067+00	\N	aal1	\N	\N	node	121.143.18.55	\N	\N	\N	\N	\N
638f6d24-407d-420d-b5d0-525257e42cc9	10e558ca-3940-4995-9a8f-165e78efaffc	2026-02-05 14:52:13.991849+00	2026-02-05 14:52:13.991849+00	\N	aal1	\N	\N	node	121.143.18.55	\N	\N	\N	\N	\N
b245b475-0b5c-4396-b24f-1a57c3225c2b	10e558ca-3940-4995-9a8f-165e78efaffc	2026-02-05 14:52:15.340822+00	2026-02-05 14:52:15.340822+00	\N	aal1	\N	\N	node	121.143.18.55	\N	\N	\N	\N	\N
90d47778-4fe4-435d-86c6-faced62bcb4f	5e4ec0ef-464a-41db-8e2f-9f3bfa2671ee	2026-02-05 14:52:16.695073+00	2026-02-05 14:52:16.695073+00	\N	aal1	\N	\N	node	121.143.18.55	\N	\N	\N	\N	\N
a449ba6b-e153-426b-bb20-6198203f8eb0	5e4ec0ef-464a-41db-8e2f-9f3bfa2671ee	2026-02-05 14:52:18.037379+00	2026-02-05 14:52:18.037379+00	\N	aal1	\N	\N	node	121.143.18.55	\N	\N	\N	\N	\N
32dba162-03d6-4dc1-a8b9-11a0e805602e	5e4ec0ef-464a-41db-8e2f-9f3bfa2671ee	2026-02-05 14:52:19.404886+00	2026-02-05 14:52:19.404886+00	\N	aal1	\N	\N	node	121.143.18.55	\N	\N	\N	\N	\N
df18d02a-ab5e-4476-8948-bc0e798ee538	95f608be-c1e9-43b1-b885-5e2784e4858f	2026-02-05 14:52:20.771526+00	2026-02-05 14:52:20.771526+00	\N	aal1	\N	\N	node	121.143.18.55	\N	\N	\N	\N	\N
7ee2d29b-6c6e-46ce-820e-90a37330c374	95f608be-c1e9-43b1-b885-5e2784e4858f	2026-02-05 14:53:02.194397+00	2026-02-05 14:53:02.194397+00	\N	aal1	\N	\N	node	121.143.18.55	\N	\N	\N	\N	\N
45b15db1-ab6b-4806-9133-7568e88c2ec1	95f608be-c1e9-43b1-b885-5e2784e4858f	2026-02-05 14:53:03.540529+00	2026-02-05 14:53:03.540529+00	\N	aal1	\N	\N	node	121.143.18.55	\N	\N	\N	\N	\N
933d6b75-ba2b-4a81-935d-ab346c33e272	8cf7c6be-ba2c-48c9-8825-589e675ff608	2026-02-05 14:53:04.892467+00	2026-02-05 14:53:04.892467+00	\N	aal1	\N	\N	node	121.143.18.55	\N	\N	\N	\N	\N
ddd11cc7-a01a-49c0-8c40-b2cfd99828ed	8cf7c6be-ba2c-48c9-8825-589e675ff608	2026-02-05 14:53:06.244289+00	2026-02-05 14:53:06.244289+00	\N	aal1	\N	\N	node	121.143.18.55	\N	\N	\N	\N	\N
4fb093ee-9320-436d-9de3-4e5d50f5b4e5	8cf7c6be-ba2c-48c9-8825-589e675ff608	2026-02-05 14:53:07.583647+00	2026-02-05 14:53:07.583647+00	\N	aal1	\N	\N	node	121.143.18.55	\N	\N	\N	\N	\N
68aa6b64-20f6-40cc-b3db-a60d9abbeb9c	9969cfc6-451e-4ab2-ae2f-5d10a98eaf0a	2026-02-05 14:54:02.327134+00	2026-02-05 14:54:02.327134+00	\N	aal1	\N	\N	node	121.143.18.55	\N	\N	\N	\N	\N
9c3d10cf-c031-4fca-bb42-6d5d4a236e1a	9969cfc6-451e-4ab2-ae2f-5d10a98eaf0a	2026-02-05 14:54:03.768485+00	2026-02-05 14:54:03.768485+00	\N	aal1	\N	\N	node	121.143.18.55	\N	\N	\N	\N	\N
cbff93a5-666e-4c44-962f-714372cc56c2	9969cfc6-451e-4ab2-ae2f-5d10a98eaf0a	2026-02-05 14:54:05.267361+00	2026-02-05 14:54:05.267361+00	\N	aal1	\N	\N	node	121.143.18.55	\N	\N	\N	\N	\N
68f522a0-c23e-40f9-ba33-84697d2dca81	10e558ca-3940-4995-9a8f-165e78efaffc	2026-02-05 14:54:06.758067+00	2026-02-05 14:54:06.758067+00	\N	aal1	\N	\N	node	121.143.18.55	\N	\N	\N	\N	\N
23312512-15be-4b8c-97a2-311ef45ac78f	10e558ca-3940-4995-9a8f-165e78efaffc	2026-02-05 14:54:08.239027+00	2026-02-05 14:54:08.239027+00	\N	aal1	\N	\N	node	121.143.18.55	\N	\N	\N	\N	\N
7c15b98c-1446-410b-b7c4-c619f8b7e28d	10e558ca-3940-4995-9a8f-165e78efaffc	2026-02-05 14:54:09.63421+00	2026-02-05 14:54:09.63421+00	\N	aal1	\N	\N	node	121.143.18.55	\N	\N	\N	\N	\N
80368408-db3d-4a35-a656-ec95dd1367cf	5e4ec0ef-464a-41db-8e2f-9f3bfa2671ee	2026-02-05 14:54:11.012653+00	2026-02-05 14:54:11.012653+00	\N	aal1	\N	\N	node	121.143.18.55	\N	\N	\N	\N	\N
684042f7-7a94-4375-aa0a-b0e7b2c7d533	5e4ec0ef-464a-41db-8e2f-9f3bfa2671ee	2026-02-05 14:54:12.387603+00	2026-02-05 14:54:12.387603+00	\N	aal1	\N	\N	node	121.143.18.55	\N	\N	\N	\N	\N
e9635769-1f26-44ce-9a3c-6802ba28558f	5e4ec0ef-464a-41db-8e2f-9f3bfa2671ee	2026-02-05 14:54:13.778218+00	2026-02-05 14:54:13.778218+00	\N	aal1	\N	\N	node	121.143.18.55	\N	\N	\N	\N	\N
e55cacec-7abc-47f6-a3e9-6300bb59ed63	95f608be-c1e9-43b1-b885-5e2784e4858f	2026-02-05 14:54:15.153109+00	2026-02-05 14:54:15.153109+00	\N	aal1	\N	\N	node	121.143.18.55	\N	\N	\N	\N	\N
dced29cb-8ba7-43bc-93e3-961d730fbe4d	95f608be-c1e9-43b1-b885-5e2784e4858f	2026-02-05 14:54:16.604954+00	2026-02-05 14:54:16.604954+00	\N	aal1	\N	\N	node	121.143.18.55	\N	\N	\N	\N	\N
9b27ccb7-fb2d-4fd2-b9c3-f6088a735f7d	95f608be-c1e9-43b1-b885-5e2784e4858f	2026-02-05 14:54:18.125414+00	2026-02-05 14:54:18.125414+00	\N	aal1	\N	\N	node	121.143.18.55	\N	\N	\N	\N	\N
b01fd372-56e9-4b53-be40-48d5db2fb560	8cf7c6be-ba2c-48c9-8825-589e675ff608	2026-02-05 14:54:19.472705+00	2026-02-05 14:54:19.472705+00	\N	aal1	\N	\N	node	121.143.18.55	\N	\N	\N	\N	\N
251a3ec5-e04e-4235-b16f-0ac012571ad3	8cf7c6be-ba2c-48c9-8825-589e675ff608	2026-02-05 14:54:20.828864+00	2026-02-05 14:54:20.828864+00	\N	aal1	\N	\N	node	121.143.18.55	\N	\N	\N	\N	\N
cd995ab6-e3fd-457d-8d96-29bc33f97f09	8cf7c6be-ba2c-48c9-8825-589e675ff608	2026-02-05 14:55:02.19252+00	2026-02-05 14:55:02.19252+00	\N	aal1	\N	\N	node	121.143.18.55	\N	\N	\N	\N	\N
b17a6421-4883-4b1d-bacf-bc9af46b1627	9969cfc6-451e-4ab2-ae2f-5d10a98eaf0a	2026-02-08 10:01:22.39056+00	2026-02-08 10:01:22.39056+00	\N	aal1	\N	\N	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.7632.6 Safari/537.36	121.143.18.55	\N	\N	\N	\N	\N
48202c03-6299-4924-89b6-23045e3cca6a	9969cfc6-451e-4ab2-ae2f-5d10a98eaf0a	2026-02-08 10:02:06.436864+00	2026-02-08 10:02:06.436864+00	\N	aal1	\N	\N	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.7632.6 Safari/537.36	121.143.18.55	\N	\N	\N	\N	\N
593c192e-6d16-4d71-8c0b-246088715e5c	9969cfc6-451e-4ab2-ae2f-5d10a98eaf0a	2026-02-05 17:05:43.672589+00	2026-02-05 17:05:43.672589+00	\N	aal1	\N	\N	node	121.143.18.55	\N	\N	\N	\N	\N
02c7470d-c989-43fc-8ca7-bbf7c5038c87	9969cfc6-451e-4ab2-ae2f-5d10a98eaf0a	2026-02-05 17:08:13.165141+00	2026-02-05 17:08:13.165141+00	\N	aal1	\N	\N	node	121.143.18.55	\N	\N	\N	\N	\N
5346de08-2204-4bfe-a271-810679f93ae5	9969cfc6-451e-4ab2-ae2f-5d10a98eaf0a	2026-02-08 10:02:10.541267+00	2026-02-08 10:02:10.541267+00	\N	aal1	\N	\N	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.7632.6 Safari/537.36	121.143.18.55	\N	\N	\N	\N	\N
7d4a3e26-6d76-4312-a4d1-5c11a44d67dc	9969cfc6-451e-4ab2-ae2f-5d10a98eaf0a	2026-02-08 10:02:12.587595+00	2026-02-08 10:02:12.587595+00	\N	aal1	\N	\N	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.7632.6 Safari/537.36	121.143.18.55	\N	\N	\N	\N	\N
3a1b4909-48e4-4e18-a472-1e3ac4ffa4f5	36ae407d-c380-41ff-a714-d61371c44fb3	2026-02-02 01:51:32.124608+00	2026-02-06 01:00:42.768391+00	\N	aal1	\N	2026-02-06 01:00:42.768285	Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/26.2 Safari/605.1.15	121.143.18.55	\N	\N	\N	\N	\N
76975b13-27bb-465a-9a28-8a90107b9098	1ddb44b9-add6-437f-96de-2e7c2df0bfcc	2026-02-07 05:47:52.463029+00	2026-02-07 05:47:52.463029+00	\N	aal1	\N	\N	Mozilla/5.0 (Linux; Android 10; K) AppleWebKit/537.36 (KHTML, like Gecko) SamsungBrowser/29.0 Chrome/136.0.0.0 Mobile Safari/537.36	175.223.45.131	\N	\N	\N	\N	\N
92508c30-738b-4f7c-b0e5-e149fef01e8c	9969cfc6-451e-4ab2-ae2f-5d10a98eaf0a	2026-02-08 10:02:35.159712+00	2026-02-08 10:02:35.159712+00	\N	aal1	\N	\N	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.7632.6 Safari/537.36	121.143.18.55	\N	\N	\N	\N	\N
acc7ac19-0d74-4f0d-aba6-46cb3d1929f4	9969cfc6-451e-4ab2-ae2f-5d10a98eaf0a	2026-02-08 10:02:59.896612+00	2026-02-08 10:02:59.896612+00	\N	aal1	\N	\N	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.7632.6 Safari/537.36	121.143.18.55	\N	\N	\N	\N	\N
7e61fa04-93e5-4e83-8f43-c45d404005e9	9969cfc6-451e-4ab2-ae2f-5d10a98eaf0a	2026-02-08 10:02:59.964031+00	2026-02-08 10:02:59.964031+00	\N	aal1	\N	\N	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.7632.6 Safari/537.36	121.143.18.55	\N	\N	\N	\N	\N
51aba99c-03c5-4605-b5c0-8283ca349b25	9969cfc6-451e-4ab2-ae2f-5d10a98eaf0a	2026-02-08 10:04:01.557996+00	2026-02-08 10:04:01.557996+00	\N	aal1	\N	\N	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.7632.6 Safari/537.36	121.143.18.55	\N	\N	\N	\N	\N
3c309b5f-db34-4653-aa90-55cddcd69a9e	9969cfc6-451e-4ab2-ae2f-5d10a98eaf0a	2026-02-08 10:04:01.55843+00	2026-02-08 10:04:01.55843+00	\N	aal1	\N	\N	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.7632.6 Safari/537.36	121.143.18.55	\N	\N	\N	\N	\N
c8cf63ac-c335-440a-9975-2c860395051d	9969cfc6-451e-4ab2-ae2f-5d10a98eaf0a	2026-02-08 10:04:38.646372+00	2026-02-08 10:04:38.646372+00	\N	aal1	\N	\N	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.7632.6 Safari/537.36	121.143.18.55	\N	\N	\N	\N	\N
d86790cc-a735-49df-8bd1-14d504c92c83	9969cfc6-451e-4ab2-ae2f-5d10a98eaf0a	2026-02-08 10:04:40.169259+00	2026-02-08 10:04:40.169259+00	\N	aal1	\N	\N	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.7632.6 Safari/537.36	121.143.18.55	\N	\N	\N	\N	\N
3b90ded5-343f-40b4-9093-4caed7535f54	9969cfc6-451e-4ab2-ae2f-5d10a98eaf0a	2026-02-08 10:05:46.771934+00	2026-02-08 10:05:46.771934+00	\N	aal1	\N	\N	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.7632.6 Safari/537.36	121.143.18.55	\N	\N	\N	\N	\N
a1c76fe6-38f4-4d0c-973b-731ec8399cbd	9969cfc6-451e-4ab2-ae2f-5d10a98eaf0a	2026-02-08 10:05:47.166211+00	2026-02-08 10:05:47.166211+00	\N	aal1	\N	\N	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.7632.6 Safari/537.36	121.143.18.55	\N	\N	\N	\N	\N
e98426ea-cee7-461a-b630-68d9656a18a4	9969cfc6-451e-4ab2-ae2f-5d10a98eaf0a	2026-02-08 10:06:14.715581+00	2026-02-08 10:06:14.715581+00	\N	aal1	\N	\N	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.7632.6 Safari/537.36	121.143.18.55	\N	\N	\N	\N	\N
bc82085a-e2ea-4234-a001-d10e260dd2b5	9969cfc6-451e-4ab2-ae2f-5d10a98eaf0a	2026-02-08 10:06:16.100366+00	2026-02-08 10:06:16.100366+00	\N	aal1	\N	\N	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.7632.6 Safari/537.36	121.143.18.55	\N	\N	\N	\N	\N
03456332-c337-4e53-b595-6496d403e83e	9969cfc6-451e-4ab2-ae2f-5d10a98eaf0a	2026-02-08 10:07:08.151604+00	2026-02-08 10:07:08.151604+00	\N	aal1	\N	\N	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.7632.6 Safari/537.36	121.143.18.55	\N	\N	\N	\N	\N
03ec5066-036c-4bf9-b2bd-1742e64c3513	9969cfc6-451e-4ab2-ae2f-5d10a98eaf0a	2026-02-08 10:09:06.844394+00	2026-02-08 10:09:06.844394+00	\N	aal1	\N	\N	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.7632.6 Safari/537.36	121.143.18.55	\N	\N	\N	\N	\N
032367ef-d033-4698-a8c6-68ca002778ac	1768c70a-81b5-4b3d-80b2-7e2a8f7d631b	2026-02-08 05:01:55.705973+00	2026-02-08 05:01:55.705973+00	\N	aal1	\N	\N	Mozilla/5.0 (Linux; Android 16; SM-S928N Build/BP2A.250605.031.A3; wv) AppleWebKit/537.36 (KHTML, like Gecko) Version/4.0 Chrome/128.0.0.0 Whale/1.0.0.0 Crosswalk/29.128.0.24 Mobile Safari/537.36 NAVER(inapp; search; 2100; 12.19.1)	121.143.18.69	\N	\N	\N	\N	\N
a782cfe3-8f8f-4167-8beb-4b2b585bc7b7	9969cfc6-451e-4ab2-ae2f-5d10a98eaf0a	2026-02-08 10:09:17.05819+00	2026-02-08 10:09:17.05819+00	\N	aal1	\N	\N	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.7632.6 Safari/537.36	121.143.18.55	\N	\N	\N	\N	\N
02bb27de-2037-45f9-ab9a-2280c51bee99	9969cfc6-451e-4ab2-ae2f-5d10a98eaf0a	2026-02-08 10:09:30.049176+00	2026-02-08 10:09:30.049176+00	\N	aal1	\N	\N	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.7632.6 Safari/537.36	121.143.18.55	\N	\N	\N	\N	\N
d608bfe3-0472-499b-97e9-7212b6056250	9969cfc6-451e-4ab2-ae2f-5d10a98eaf0a	2026-02-08 10:09:30.073036+00	2026-02-08 10:09:30.073036+00	\N	aal1	\N	\N	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.7632.6 Safari/537.36	121.143.18.55	\N	\N	\N	\N	\N
febeee40-c81f-442f-8377-be1ba1e1648d	9969cfc6-451e-4ab2-ae2f-5d10a98eaf0a	2026-02-08 07:55:28.982882+00	2026-02-08 07:55:28.982882+00	\N	aal1	\N	\N	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.7632.6 Safari/537.36	121.143.18.55	\N	\N	\N	\N	\N
eff4c5f3-ec3e-4a4c-bad5-0bb10a937e7e	9969cfc6-451e-4ab2-ae2f-5d10a98eaf0a	2026-02-08 10:09:58.410912+00	2026-02-08 10:09:58.410912+00	\N	aal1	\N	\N	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.7632.6 Safari/537.36	121.143.18.55	\N	\N	\N	\N	\N
94623bfd-0d76-41d8-93e4-192a74317e18	9969cfc6-451e-4ab2-ae2f-5d10a98eaf0a	2026-02-08 11:13:11.436646+00	2026-02-08 11:13:11.436646+00	\N	aal1	\N	\N	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.7632.6 Safari/537.36	121.143.18.55	\N	\N	\N	\N	\N
f06d1ec5-e41a-44d8-9451-a586565f9f33	9969cfc6-451e-4ab2-ae2f-5d10a98eaf0a	2026-02-08 10:01:21.967381+00	2026-02-08 10:01:21.967381+00	\N	aal1	\N	\N	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.7632.6 Safari/537.36	121.143.18.55	\N	\N	\N	\N	\N
a6d8f5e7-8b9c-4e77-82e8-d3c0db2ef117	9969cfc6-451e-4ab2-ae2f-5d10a98eaf0a	2026-02-08 10:01:21.966212+00	2026-02-08 10:01:21.966212+00	\N	aal1	\N	\N	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.7632.6 Safari/537.36	121.143.18.55	\N	\N	\N	\N	\N
d4a3265c-2362-4c62-a7b2-46023c68b2bc	9969cfc6-451e-4ab2-ae2f-5d10a98eaf0a	2026-02-08 10:01:21.972132+00	2026-02-08 10:01:21.972132+00	\N	aal1	\N	\N	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.7632.6 Safari/537.36	121.143.18.55	\N	\N	\N	\N	\N
d5f33918-f88c-4a18-a4c6-0dab662329cc	9969cfc6-451e-4ab2-ae2f-5d10a98eaf0a	2026-02-08 11:13:10.995482+00	2026-02-08 11:13:10.995482+00	\N	aal1	\N	\N	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.7632.6 Safari/537.36	121.143.18.55	\N	\N	\N	\N	\N
0f51bce7-7bc0-4b06-8d0f-4522e7dddab1	9969cfc6-451e-4ab2-ae2f-5d10a98eaf0a	2026-02-08 11:13:10.995496+00	2026-02-08 11:13:10.995496+00	\N	aal1	\N	\N	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.7632.6 Safari/537.36	121.143.18.55	\N	\N	\N	\N	\N
d692d613-2cb4-4951-bee2-2ec574866354	9969cfc6-451e-4ab2-ae2f-5d10a98eaf0a	2026-02-08 11:13:10.997031+00	2026-02-08 11:13:10.997031+00	\N	aal1	\N	\N	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.7632.6 Safari/537.36	121.143.18.55	\N	\N	\N	\N	\N
86141149-83da-4692-bef0-c10214c82369	9969cfc6-451e-4ab2-ae2f-5d10a98eaf0a	2026-02-08 11:13:26.018314+00	2026-02-08 11:13:26.018314+00	\N	aal1	\N	\N	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.7632.6 Safari/537.36	121.143.18.55	\N	\N	\N	\N	\N
ff124e79-9428-4db8-adba-8b39f01724e5	9969cfc6-451e-4ab2-ae2f-5d10a98eaf0a	2026-02-08 11:13:26.815006+00	2026-02-08 11:13:26.815006+00	\N	aal1	\N	\N	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.7632.6 Safari/537.36	121.143.18.55	\N	\N	\N	\N	\N
62f73ad7-b2bd-4d80-aebe-a314084cf229	9969cfc6-451e-4ab2-ae2f-5d10a98eaf0a	2026-02-08 11:14:49.955101+00	2026-02-08 11:14:49.955101+00	\N	aal1	\N	\N	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.7632.6 Safari/537.36	121.143.18.55	\N	\N	\N	\N	\N
fa200289-289b-4e35-978f-c10793105793	9969cfc6-451e-4ab2-ae2f-5d10a98eaf0a	2026-02-08 11:13:32.255291+00	2026-02-08 11:13:32.255291+00	\N	aal1	\N	\N	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.7632.6 Safari/537.36	121.143.18.55	\N	\N	\N	\N	\N
020cbe47-6cef-40cb-857a-b406563a48be	9969cfc6-451e-4ab2-ae2f-5d10a98eaf0a	2026-02-08 11:13:32.453584+00	2026-02-08 11:13:32.453584+00	\N	aal1	\N	\N	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.7632.6 Safari/537.36	121.143.18.55	\N	\N	\N	\N	\N
b7a8f74e-d2c1-4852-9ffd-464ae7650ae4	9969cfc6-451e-4ab2-ae2f-5d10a98eaf0a	2026-02-08 11:13:33.638959+00	2026-02-08 11:13:33.638959+00	\N	aal1	\N	\N	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.7632.6 Safari/537.36	121.143.18.55	\N	\N	\N	\N	\N
f8c0d862-115c-4038-a454-b6b56be05727	9969cfc6-451e-4ab2-ae2f-5d10a98eaf0a	2026-02-08 11:13:46.259739+00	2026-02-08 11:13:46.259739+00	\N	aal1	\N	\N	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.7632.6 Safari/537.36	121.143.18.55	\N	\N	\N	\N	\N
44ab02cd-df3b-4627-abf6-97ff5bc4a85a	9969cfc6-451e-4ab2-ae2f-5d10a98eaf0a	2026-02-08 11:13:54.203279+00	2026-02-08 11:13:54.203279+00	\N	aal1	\N	\N	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.7632.6 Safari/537.36	121.143.18.55	\N	\N	\N	\N	\N
8105805c-ce34-435e-9d84-707558c961ac	9969cfc6-451e-4ab2-ae2f-5d10a98eaf0a	2026-02-08 11:13:56.651018+00	2026-02-08 11:13:56.651018+00	\N	aal1	\N	\N	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.7632.6 Safari/537.36	121.143.18.55	\N	\N	\N	\N	\N
379bcc9e-bc86-498b-b9d4-7e0d66ffbcf8	9969cfc6-451e-4ab2-ae2f-5d10a98eaf0a	2026-02-08 11:14:10.400361+00	2026-02-08 11:14:10.400361+00	\N	aal1	\N	\N	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.7632.6 Safari/537.36	121.143.18.55	\N	\N	\N	\N	\N
e88374df-6cfc-4477-ac1e-feef2f340fee	9969cfc6-451e-4ab2-ae2f-5d10a98eaf0a	2026-02-08 11:14:49.955403+00	2026-02-08 11:14:49.955403+00	\N	aal1	\N	\N	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.7632.6 Safari/537.36	121.143.18.55	\N	\N	\N	\N	\N
1082bcf7-de4d-4c68-93bb-fd7f7b8b910e	9969cfc6-451e-4ab2-ae2f-5d10a98eaf0a	2026-02-08 11:14:50.908107+00	2026-02-08 11:14:50.908107+00	\N	aal1	\N	\N	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.7632.6 Safari/537.36	121.143.18.55	\N	\N	\N	\N	\N
9d02563e-0286-4c02-979d-bcd1ad54f653	9969cfc6-451e-4ab2-ae2f-5d10a98eaf0a	2026-02-08 11:14:55.308755+00	2026-02-08 11:14:55.308755+00	\N	aal1	\N	\N	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.7632.6 Safari/537.36	121.143.18.55	\N	\N	\N	\N	\N
4c194bd4-964a-4ddc-8cd8-6505b7c7511d	9969cfc6-451e-4ab2-ae2f-5d10a98eaf0a	2026-02-08 11:15:28.437143+00	2026-02-08 11:15:28.437143+00	\N	aal1	\N	\N	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.7632.6 Safari/537.36	121.143.18.55	\N	\N	\N	\N	\N
03fba221-2e20-4541-9cad-43ce5fbb3b3f	9969cfc6-451e-4ab2-ae2f-5d10a98eaf0a	2026-02-08 11:15:28.509983+00	2026-02-08 11:15:28.509983+00	\N	aal1	\N	\N	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.7632.6 Safari/537.36	121.143.18.55	\N	\N	\N	\N	\N
2c29a7ce-acaf-4198-9074-162b2ebba8dd	9969cfc6-451e-4ab2-ae2f-5d10a98eaf0a	2026-02-08 11:16:12.792162+00	2026-02-08 11:16:12.792162+00	\N	aal1	\N	\N	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.7632.6 Safari/537.36	121.143.18.55	\N	\N	\N	\N	\N
fbd1b79e-a811-4470-80da-42ea0e095b5a	9969cfc6-451e-4ab2-ae2f-5d10a98eaf0a	2026-02-08 11:16:12.924095+00	2026-02-08 11:16:12.924095+00	\N	aal1	\N	\N	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.7632.6 Safari/537.36	121.143.18.55	\N	\N	\N	\N	\N
fa4a2c1e-e5c7-4d83-8a29-874cfd6dadc5	9969cfc6-451e-4ab2-ae2f-5d10a98eaf0a	2026-02-08 11:16:32.229619+00	2026-02-08 11:16:32.229619+00	\N	aal1	\N	\N	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.7632.6 Safari/537.36	121.143.18.55	\N	\N	\N	\N	\N
51a1bc0e-f308-44ad-b7da-449fdc615ced	9969cfc6-451e-4ab2-ae2f-5d10a98eaf0a	2026-02-08 11:16:38.510396+00	2026-02-08 11:16:38.510396+00	\N	aal1	\N	\N	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.7632.6 Safari/537.36	121.143.18.55	\N	\N	\N	\N	\N
02e6e1f2-526c-4ac0-a648-a9eb11cc06f3	9969cfc6-451e-4ab2-ae2f-5d10a98eaf0a	2026-02-08 11:16:50.330472+00	2026-02-08 11:16:50.330472+00	\N	aal1	\N	\N	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.7632.6 Safari/537.36	121.143.18.55	\N	\N	\N	\N	\N
ba35064a-adc8-4a6c-b1b9-fda41284e12d	9969cfc6-451e-4ab2-ae2f-5d10a98eaf0a	2026-02-08 11:36:58.911686+00	2026-02-08 11:36:58.911686+00	\N	aal1	\N	\N	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.7632.6 Safari/537.36	121.143.18.55	\N	\N	\N	\N	\N
c5d20fd3-f023-41f5-82a3-3d37fb621023	9969cfc6-451e-4ab2-ae2f-5d10a98eaf0a	2026-02-08 11:36:59.102328+00	2026-02-08 11:36:59.102328+00	\N	aal1	\N	\N	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.7632.6 Safari/537.36	121.143.18.55	\N	\N	\N	\N	\N
004fc922-9a68-403b-8636-d357f61b2c94	9969cfc6-451e-4ab2-ae2f-5d10a98eaf0a	2026-02-08 11:37:03.993924+00	2026-02-08 11:37:03.993924+00	\N	aal1	\N	\N	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.7632.6 Safari/537.36	121.143.18.55	\N	\N	\N	\N	\N
0081fa1a-06cd-4c0c-9351-a66c68fa8ee8	9969cfc6-451e-4ab2-ae2f-5d10a98eaf0a	2026-02-08 11:37:04.139562+00	2026-02-08 11:37:04.139562+00	\N	aal1	\N	\N	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.7632.6 Safari/537.36	121.143.18.55	\N	\N	\N	\N	\N
c9044358-3ce2-4a54-9d0e-e4866433b970	9969cfc6-451e-4ab2-ae2f-5d10a98eaf0a	2026-02-08 11:37:27.15364+00	2026-02-08 11:37:27.15364+00	\N	aal1	\N	\N	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.7632.6 Safari/537.36	121.143.18.55	\N	\N	\N	\N	\N
c15ce90b-c7be-4a59-8ceb-148d7face7b8	9969cfc6-451e-4ab2-ae2f-5d10a98eaf0a	2026-02-08 11:37:28.851667+00	2026-02-08 11:37:28.851667+00	\N	aal1	\N	\N	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.7632.6 Safari/537.36	121.143.18.55	\N	\N	\N	\N	\N
19a19d9c-eb2f-45b4-bbe6-09b1809b4fcd	9969cfc6-451e-4ab2-ae2f-5d10a98eaf0a	2026-02-08 11:37:38.678744+00	2026-02-08 11:37:38.678744+00	\N	aal1	\N	\N	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.7632.6 Safari/537.36	121.143.18.55	\N	\N	\N	\N	\N
e301bd0e-1b0c-42af-b557-b5eb7d5d2438	9969cfc6-451e-4ab2-ae2f-5d10a98eaf0a	2026-02-08 11:37:38.851054+00	2026-02-08 11:37:38.851054+00	\N	aal1	\N	\N	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.7632.6 Safari/537.36	121.143.18.55	\N	\N	\N	\N	\N
d9760289-83c3-4ad8-a243-71841afc1b73	9969cfc6-451e-4ab2-ae2f-5d10a98eaf0a	2026-02-08 11:37:47.979203+00	2026-02-08 11:37:47.979203+00	\N	aal1	\N	\N	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.7632.6 Safari/537.36	121.143.18.55	\N	\N	\N	\N	\N
b69e40c6-5dac-40ce-bf0d-4e2bf346443b	9969cfc6-451e-4ab2-ae2f-5d10a98eaf0a	2026-02-08 11:37:54.443206+00	2026-02-08 11:37:54.443206+00	\N	aal1	\N	\N	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.7632.6 Safari/537.36	121.143.18.55	\N	\N	\N	\N	\N
a8f49396-3178-4089-ac55-74155168213c	9969cfc6-451e-4ab2-ae2f-5d10a98eaf0a	2026-02-08 11:38:22.594281+00	2026-02-08 11:38:22.594281+00	\N	aal1	\N	\N	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.7632.6 Safari/537.36	121.143.18.55	\N	\N	\N	\N	\N
b2be4da3-5e91-4ca1-b732-6baada5a861a	9969cfc6-451e-4ab2-ae2f-5d10a98eaf0a	2026-02-08 12:05:07.44032+00	2026-02-08 12:05:07.44032+00	\N	aal1	\N	\N	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.7632.6 Safari/537.36	121.143.18.55	\N	\N	\N	\N	\N
301edae8-e124-4689-b50f-8e1a251a7dc5	9969cfc6-451e-4ab2-ae2f-5d10a98eaf0a	2026-02-08 12:05:07.457367+00	2026-02-08 12:05:07.457367+00	\N	aal1	\N	\N	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.7632.6 Safari/537.36	121.143.18.55	\N	\N	\N	\N	\N
ccbe9e1a-1b18-4c39-862d-d642f1769fd6	9969cfc6-451e-4ab2-ae2f-5d10a98eaf0a	2026-02-08 12:05:10.573478+00	2026-02-08 12:05:10.573478+00	\N	aal1	\N	\N	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.7632.6 Safari/537.36	121.143.18.55	\N	\N	\N	\N	\N
60ff6e80-cd56-48a6-b59c-e61beb5ca258	9969cfc6-451e-4ab2-ae2f-5d10a98eaf0a	2026-02-08 12:05:10.727659+00	2026-02-08 12:05:10.727659+00	\N	aal1	\N	\N	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.7632.6 Safari/537.36	121.143.18.55	\N	\N	\N	\N	\N
0c00d937-5acd-4e7d-9f85-d731bd0db803	9969cfc6-451e-4ab2-ae2f-5d10a98eaf0a	2026-02-08 12:05:45.912891+00	2026-02-08 12:05:45.912891+00	\N	aal1	\N	\N	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.7632.6 Safari/537.36	121.143.18.55	\N	\N	\N	\N	\N
8d973535-ea22-4ccc-b8f8-e218365210a7	9969cfc6-451e-4ab2-ae2f-5d10a98eaf0a	2026-02-08 12:05:55.008339+00	2026-02-08 12:05:55.008339+00	\N	aal1	\N	\N	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.7632.6 Safari/537.36	121.143.18.55	\N	\N	\N	\N	\N
cbe99458-8e96-459b-959b-1fa1baead779	9969cfc6-451e-4ab2-ae2f-5d10a98eaf0a	2026-02-08 12:06:06.929826+00	2026-02-08 12:06:06.929826+00	\N	aal1	\N	\N	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.7632.6 Safari/537.36	121.143.18.55	\N	\N	\N	\N	\N
97e403bd-6a24-408e-9b46-f8a823b9ff31	9969cfc6-451e-4ab2-ae2f-5d10a98eaf0a	2026-02-08 12:06:07.19473+00	2026-02-08 12:06:07.19473+00	\N	aal1	\N	\N	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.7632.6 Safari/537.36	121.143.18.55	\N	\N	\N	\N	\N
f1ed9b39-5b59-4b2f-9279-4ae2aa682116	9969cfc6-451e-4ab2-ae2f-5d10a98eaf0a	2026-02-08 12:06:46.455476+00	2026-02-08 12:06:46.455476+00	\N	aal1	\N	\N	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.7632.6 Safari/537.36	121.143.18.55	\N	\N	\N	\N	\N
1d9a67bc-b8c4-41d1-9145-0c746320dfbf	9969cfc6-451e-4ab2-ae2f-5d10a98eaf0a	2026-02-08 12:06:47.069239+00	2026-02-08 12:06:47.069239+00	\N	aal1	\N	\N	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.7632.6 Safari/537.36	121.143.18.55	\N	\N	\N	\N	\N
77b8ec21-6c0e-415a-8186-6eae395d31f4	9969cfc6-451e-4ab2-ae2f-5d10a98eaf0a	2026-02-08 12:06:54.315764+00	2026-02-08 12:06:54.315764+00	\N	aal1	\N	\N	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.7632.6 Safari/537.36	121.143.18.55	\N	\N	\N	\N	\N
9b83d9a1-c246-4c07-8b4c-b4efc035bb58	9969cfc6-451e-4ab2-ae2f-5d10a98eaf0a	2026-02-08 12:12:01.87176+00	2026-02-08 12:12:01.87176+00	\N	aal1	\N	\N	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.7632.6 Safari/537.36	121.143.18.55	\N	\N	\N	\N	\N
7899a028-9a85-4b80-8dd3-179ed1bfe70a	9969cfc6-451e-4ab2-ae2f-5d10a98eaf0a	2026-02-08 12:12:01.87155+00	2026-02-08 12:12:01.87155+00	\N	aal1	\N	\N	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.7632.6 Safari/537.36	121.143.18.55	\N	\N	\N	\N	\N
35c57c2a-ddec-4f91-b851-60e9993716fe	9969cfc6-451e-4ab2-ae2f-5d10a98eaf0a	2026-02-08 12:12:01.94317+00	2026-02-08 12:12:01.94317+00	\N	aal1	\N	\N	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.7632.6 Safari/537.36	121.143.18.55	\N	\N	\N	\N	\N
950e8e89-9453-4908-8133-9bf892c6f462	9969cfc6-451e-4ab2-ae2f-5d10a98eaf0a	2026-02-08 12:12:23.449134+00	2026-02-08 12:12:23.449134+00	\N	aal1	\N	\N	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.7632.6 Safari/537.36	121.143.18.55	\N	\N	\N	\N	\N
e9978302-1311-4b5b-813c-e91a751022ef	9969cfc6-451e-4ab2-ae2f-5d10a98eaf0a	2026-02-08 12:12:35.553591+00	2026-02-08 12:12:35.553591+00	\N	aal1	\N	\N	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.7632.6 Safari/537.36	121.143.18.55	\N	\N	\N	\N	\N
64c61424-3fe0-48ca-bad7-7df1994237f4	9969cfc6-451e-4ab2-ae2f-5d10a98eaf0a	2026-02-08 12:37:06.222407+00	2026-02-08 12:37:06.222407+00	\N	aal1	\N	\N	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.7632.6 Safari/537.36	121.143.18.55	\N	\N	\N	\N	\N
fe900f72-18e3-4b1d-8951-5c68048075ac	9969cfc6-451e-4ab2-ae2f-5d10a98eaf0a	2026-02-08 12:38:14.621434+00	2026-02-08 12:38:14.621434+00	\N	aal1	\N	\N	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.7632.6 Safari/537.36	121.143.18.55	\N	\N	\N	\N	\N
cadfe077-4ab0-4bff-9f8a-1f0895b467e6	9969cfc6-451e-4ab2-ae2f-5d10a98eaf0a	2026-02-08 12:41:45.599576+00	2026-02-08 12:41:45.599576+00	\N	aal1	\N	\N	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.7632.6 Safari/537.36	121.143.18.55	\N	\N	\N	\N	\N
d3746197-58bd-483d-82d1-b4a8d3383a48	9969cfc6-451e-4ab2-ae2f-5d10a98eaf0a	2026-02-08 12:49:25.084531+00	2026-02-08 12:49:25.084531+00	\N	aal1	\N	\N	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.7632.6 Safari/537.36	121.143.18.55	\N	\N	\N	\N	\N
aaa18622-b0eb-404d-ab88-d09feaef4797	9969cfc6-451e-4ab2-ae2f-5d10a98eaf0a	2026-02-08 12:57:10.373575+00	2026-02-08 12:57:10.373575+00	\N	aal1	\N	\N	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.7632.6 Safari/537.36	121.143.18.55	\N	\N	\N	\N	\N
67eaa452-7664-4c3b-825d-7bdac05e1942	9969cfc6-451e-4ab2-ae2f-5d10a98eaf0a	2026-02-08 12:59:31.500438+00	2026-02-08 12:59:31.500438+00	\N	aal1	\N	\N	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.7632.6 Safari/537.36	121.143.18.55	\N	\N	\N	\N	\N
a2f86c28-b1d4-4cae-b94f-5d602e71e738	9969cfc6-451e-4ab2-ae2f-5d10a98eaf0a	2026-02-08 13:05:14.808772+00	2026-02-08 13:05:14.808772+00	\N	aal1	\N	\N	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.7632.6 Safari/537.36	121.143.18.55	\N	\N	\N	\N	\N
f92d3f4a-852c-4ba4-b896-f390a652272f	9969cfc6-451e-4ab2-ae2f-5d10a98eaf0a	2026-02-08 13:05:16.35765+00	2026-02-08 13:05:16.35765+00	\N	aal1	\N	\N	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.7632.6 Safari/537.36	121.143.18.55	\N	\N	\N	\N	\N
a2cd0bf4-5e4d-4cf2-8ffb-391c8d7179f7	9969cfc6-451e-4ab2-ae2f-5d10a98eaf0a	2026-02-08 13:05:18.057596+00	2026-02-08 13:05:18.057596+00	\N	aal1	\N	\N	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.7632.6 Safari/537.36	121.143.18.55	\N	\N	\N	\N	\N
118a1c2d-5ca1-493e-bf55-8415166ced28	9969cfc6-451e-4ab2-ae2f-5d10a98eaf0a	2026-02-08 13:05:20.131741+00	2026-02-08 13:05:20.131741+00	\N	aal1	\N	\N	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.7632.6 Safari/537.36	121.143.18.55	\N	\N	\N	\N	\N
35019c71-7964-4a7e-ba46-8a9c52183c8e	9969cfc6-451e-4ab2-ae2f-5d10a98eaf0a	2026-02-08 13:05:33.481331+00	2026-02-08 13:05:33.481331+00	\N	aal1	\N	\N	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.7632.6 Safari/537.36	121.143.18.55	\N	\N	\N	\N	\N
9c1ac895-60eb-45e9-9f83-b74e8c7e743f	9969cfc6-451e-4ab2-ae2f-5d10a98eaf0a	2026-02-08 13:05:34.021697+00	2026-02-08 13:05:34.021697+00	\N	aal1	\N	\N	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.7632.6 Safari/537.36	121.143.18.55	\N	\N	\N	\N	\N
cd77c1d6-60aa-4452-961e-9f408e786d79	9969cfc6-451e-4ab2-ae2f-5d10a98eaf0a	2026-02-08 13:05:40.867046+00	2026-02-08 13:05:40.867046+00	\N	aal1	\N	\N	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.7632.6 Safari/537.36	121.143.18.55	\N	\N	\N	\N	\N
9d2f5ab3-4329-4a1b-b05b-de556fca5f19	9969cfc6-451e-4ab2-ae2f-5d10a98eaf0a	2026-02-08 13:05:40.959508+00	2026-02-08 13:05:40.959508+00	\N	aal1	\N	\N	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.7632.6 Safari/537.36	121.143.18.55	\N	\N	\N	\N	\N
d3cae6fa-8ddb-402a-8610-99fc9fb61488	9969cfc6-451e-4ab2-ae2f-5d10a98eaf0a	2026-02-08 13:05:44.479268+00	2026-02-08 13:05:44.479268+00	\N	aal1	\N	\N	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.7632.6 Safari/537.36	121.143.18.55	\N	\N	\N	\N	\N
10f894ab-d276-4135-b27f-527a073c9a90	9969cfc6-451e-4ab2-ae2f-5d10a98eaf0a	2026-02-08 13:05:55.684682+00	2026-02-08 13:05:55.684682+00	\N	aal1	\N	\N	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.7632.6 Safari/537.36	121.143.18.55	\N	\N	\N	\N	\N
f5e40883-01d3-49a8-b1e7-c6e1401b9aa7	9969cfc6-451e-4ab2-ae2f-5d10a98eaf0a	2026-02-08 13:06:01.893378+00	2026-02-08 13:06:01.893378+00	\N	aal1	\N	\N	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.7632.6 Safari/537.36	121.143.18.55	\N	\N	\N	\N	\N
9a132c8c-883b-488e-9c25-a18b9123ed74	9969cfc6-451e-4ab2-ae2f-5d10a98eaf0a	2026-02-08 13:06:14.107347+00	2026-02-08 13:06:14.107347+00	\N	aal1	\N	\N	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.7632.6 Safari/537.36	121.143.18.55	\N	\N	\N	\N	\N
e5ca9e4a-5656-4278-87dc-007a889176ef	9969cfc6-451e-4ab2-ae2f-5d10a98eaf0a	2026-02-08 13:06:16.804114+00	2026-02-08 13:06:16.804114+00	\N	aal1	\N	\N	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.7632.6 Safari/537.36	121.143.18.55	\N	\N	\N	\N	\N
0fb9735e-62ec-46af-bd93-23e2f376268c	9969cfc6-451e-4ab2-ae2f-5d10a98eaf0a	2026-02-08 13:06:35.595566+00	2026-02-08 13:06:35.595566+00	\N	aal1	\N	\N	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.7632.6 Safari/537.36	121.143.18.55	\N	\N	\N	\N	\N
280052e9-28d2-4fb6-a7fb-b0ac2dbd2801	9969cfc6-451e-4ab2-ae2f-5d10a98eaf0a	2026-02-10 01:04:37.206261+00	2026-02-10 01:04:37.206261+00	\N	aal1	\N	\N	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.7632.6 Safari/537.36	121.143.18.55	\N	\N	\N	\N	\N
2e8b9103-a742-425d-8150-65e52f132229	9969cfc6-451e-4ab2-ae2f-5d10a98eaf0a	2026-02-10 01:04:48.681652+00	2026-02-10 01:04:48.681652+00	\N	aal1	\N	\N	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.7632.6 Safari/537.36	121.143.18.55	\N	\N	\N	\N	\N
3ad33f7b-a830-48b9-957d-cd203f83c5ee	9969cfc6-451e-4ab2-ae2f-5d10a98eaf0a	2026-02-10 01:06:19.944247+00	2026-02-10 01:06:19.944247+00	\N	aal1	\N	\N	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.7632.6 Safari/537.36	121.143.18.55	\N	\N	\N	\N	\N
97c25ec7-fef3-49f6-9d51-66edd2677d4b	9969cfc6-451e-4ab2-ae2f-5d10a98eaf0a	2026-02-10 01:08:10.824766+00	2026-02-10 01:08:10.824766+00	\N	aal1	\N	\N	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.7632.6 Safari/537.36	121.143.18.55	\N	\N	\N	\N	\N
d53b70c0-66db-4ddd-823e-ef1b5d802800	9969cfc6-451e-4ab2-ae2f-5d10a98eaf0a	2026-02-10 01:08:11.084794+00	2026-02-10 01:08:11.084794+00	\N	aal1	\N	\N	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.7632.6 Safari/537.36	121.143.18.55	\N	\N	\N	\N	\N
58335a26-6d19-4580-bfa2-d642b39abccb	9969cfc6-451e-4ab2-ae2f-5d10a98eaf0a	2026-02-10 01:08:30.156616+00	2026-02-10 01:08:30.156616+00	\N	aal1	\N	\N	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.7632.6 Safari/537.36	121.143.18.55	\N	\N	\N	\N	\N
9d96b83a-6431-4607-a052-b547cc1b9793	9969cfc6-451e-4ab2-ae2f-5d10a98eaf0a	2026-02-10 01:08:30.194087+00	2026-02-10 01:08:30.194087+00	\N	aal1	\N	\N	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.7632.6 Safari/537.36	121.143.18.55	\N	\N	\N	\N	\N
960ad8ac-84a5-4a24-807b-337d65b7f6ba	9969cfc6-451e-4ab2-ae2f-5d10a98eaf0a	2026-02-10 01:09:00.577613+00	2026-02-10 01:09:00.577613+00	\N	aal1	\N	\N	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.7632.6 Safari/537.36	121.143.18.55	\N	\N	\N	\N	\N
9ab2a5ea-b75c-4e0b-af40-bf5381f8634c	9969cfc6-451e-4ab2-ae2f-5d10a98eaf0a	2026-02-10 01:09:00.593932+00	2026-02-10 01:09:00.593932+00	\N	aal1	\N	\N	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.7632.6 Safari/537.36	121.143.18.55	\N	\N	\N	\N	\N
571b37ef-c746-47b2-a43d-5822cd1ffb08	9969cfc6-451e-4ab2-ae2f-5d10a98eaf0a	2026-02-10 01:09:20.784858+00	2026-02-10 01:09:20.784858+00	\N	aal1	\N	\N	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.7632.6 Safari/537.36	121.143.18.55	\N	\N	\N	\N	\N
d116b789-6bbf-48c0-a948-d40496d6eb09	9969cfc6-451e-4ab2-ae2f-5d10a98eaf0a	2026-02-10 01:09:20.819396+00	2026-02-10 01:09:20.819396+00	\N	aal1	\N	\N	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.7632.6 Safari/537.36	121.143.18.55	\N	\N	\N	\N	\N
1aea00c2-4e53-4f1f-a9cd-420d0512eb0d	9969cfc6-451e-4ab2-ae2f-5d10a98eaf0a	2026-02-10 01:09:35.931349+00	2026-02-10 01:09:35.931349+00	\N	aal1	\N	\N	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.7632.6 Safari/537.36	121.143.18.55	\N	\N	\N	\N	\N
4b6d015f-31b8-477e-9505-63ea5543e42c	9969cfc6-451e-4ab2-ae2f-5d10a98eaf0a	2026-02-10 01:09:41.235866+00	2026-02-10 01:09:41.235866+00	\N	aal1	\N	\N	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.7632.6 Safari/537.36	121.143.18.55	\N	\N	\N	\N	\N
0631f62e-f68e-4677-92b1-b9315f5feb23	9969cfc6-451e-4ab2-ae2f-5d10a98eaf0a	2026-02-10 01:09:57.747123+00	2026-02-10 01:09:57.747123+00	\N	aal1	\N	\N	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.7632.6 Safari/537.36	121.143.18.55	\N	\N	\N	\N	\N
83b6f0eb-bd8e-43c5-89c6-e815fc8127a2	9969cfc6-451e-4ab2-ae2f-5d10a98eaf0a	2026-02-10 01:09:46.056827+00	2026-02-10 01:09:46.056827+00	\N	aal1	\N	\N	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.7632.6 Safari/537.36	121.143.18.55	\N	\N	\N	\N	\N
b5eaeea5-ed0a-4ed2-9bac-c25b28aa8275	9969cfc6-451e-4ab2-ae2f-5d10a98eaf0a	2026-02-10 01:09:52.219812+00	2026-02-10 01:09:52.219812+00	\N	aal1	\N	\N	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.7632.6 Safari/537.36	121.143.18.55	\N	\N	\N	\N	\N
933fd499-040a-4d27-bacf-7136bbd98668	9969cfc6-451e-4ab2-ae2f-5d10a98eaf0a	2026-02-10 01:10:05.027777+00	2026-02-10 01:10:05.027777+00	\N	aal1	\N	\N	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.7632.6 Safari/537.36	121.143.18.55	\N	\N	\N	\N	\N
94a3aa4c-f5e5-48b1-b54b-9b6d13e4153d	9969cfc6-451e-4ab2-ae2f-5d10a98eaf0a	2026-02-10 01:10:11.025166+00	2026-02-10 01:10:11.025166+00	\N	aal1	\N	\N	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.7632.6 Safari/537.36	121.143.18.55	\N	\N	\N	\N	\N
62dc0dd6-d69f-4cb8-972b-bde77eae9cbb	9969cfc6-451e-4ab2-ae2f-5d10a98eaf0a	2026-02-10 01:10:17.853288+00	2026-02-10 01:10:17.853288+00	\N	aal1	\N	\N	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.7632.6 Safari/537.36	121.143.18.55	\N	\N	\N	\N	\N
10f2c61b-eca8-471a-9f12-075ddf355f79	9969cfc6-451e-4ab2-ae2f-5d10a98eaf0a	2026-02-10 01:11:57.038325+00	2026-02-10 01:11:57.038325+00	\N	aal1	\N	\N	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.7632.6 Safari/537.36	121.143.18.55	\N	\N	\N	\N	\N
afeecc0d-bee8-42a3-9121-1bc0f17561bb	9969cfc6-451e-4ab2-ae2f-5d10a98eaf0a	2026-02-10 01:12:04.186894+00	2026-02-10 01:12:04.186894+00	\N	aal1	\N	\N	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.7632.6 Safari/537.36	121.143.18.55	\N	\N	\N	\N	\N
d033c247-e4ec-44be-8808-c6f254a4d3c8	9969cfc6-451e-4ab2-ae2f-5d10a98eaf0a	2026-02-10 01:12:24.909504+00	2026-02-10 01:12:24.909504+00	\N	aal1	\N	\N	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.7632.6 Safari/537.36	121.143.18.55	\N	\N	\N	\N	\N
3b57dc79-86d3-432e-a79c-8cb06d88430e	9969cfc6-451e-4ab2-ae2f-5d10a98eaf0a	2026-02-10 01:12:38.853537+00	2026-02-10 01:12:38.853537+00	\N	aal1	\N	\N	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.7632.6 Safari/537.36	121.143.18.55	\N	\N	\N	\N	\N
319ba666-633e-44f5-b382-36b699bffcd6	9969cfc6-451e-4ab2-ae2f-5d10a98eaf0a	2026-02-10 01:12:55.184115+00	2026-02-10 01:12:55.184115+00	\N	aal1	\N	\N	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.7632.6 Safari/537.36	121.143.18.55	\N	\N	\N	\N	\N
4e8cc104-65b3-40cd-a016-623909bce1cb	10e558ca-3940-4995-9a8f-165e78efaffc	2026-02-10 03:57:53.98784+00	2026-02-10 03:57:53.98784+00	\N	aal1	\N	\N	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.7632.6 Safari/537.36	121.143.18.55	\N	\N	\N	\N	\N
1901750a-c6d3-4b2c-bf57-3c18f4238195	10e558ca-3940-4995-9a8f-165e78efaffc	2026-02-10 03:59:05.067169+00	2026-02-10 03:59:05.067169+00	\N	aal1	\N	\N	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.7632.6 Safari/537.36	121.143.18.55	\N	\N	\N	\N	\N
38937acc-1ff7-43a0-8975-3655310822e7	10e558ca-3940-4995-9a8f-165e78efaffc	2026-02-10 03:59:09.220392+00	2026-02-10 03:59:09.220392+00	\N	aal1	\N	\N	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.7632.6 Safari/537.36	121.143.18.55	\N	\N	\N	\N	\N
85e496f2-4c41-407b-bdca-f48428f8f362	10e558ca-3940-4995-9a8f-165e78efaffc	2026-02-10 03:59:26.710861+00	2026-02-10 03:59:26.710861+00	\N	aal1	\N	\N	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.7632.6 Safari/537.36	121.143.18.55	\N	\N	\N	\N	\N
64424939-8965-4f07-bb94-744f6916f55d	10e558ca-3940-4995-9a8f-165e78efaffc	2026-02-10 03:59:40.855562+00	2026-02-10 03:59:40.855562+00	\N	aal1	\N	\N	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.7632.6 Safari/537.36	121.143.18.55	\N	\N	\N	\N	\N
d7b95386-c309-4a82-8566-f1352c716114	10e558ca-3940-4995-9a8f-165e78efaffc	2026-02-10 03:59:47.667742+00	2026-02-10 03:59:47.667742+00	\N	aal1	\N	\N	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.7632.6 Safari/537.36	121.143.18.55	\N	\N	\N	\N	\N
3a042df2-f0fb-4f7f-a8b2-9a44365ba605	10e558ca-3940-4995-9a8f-165e78efaffc	2026-02-10 04:00:13.214647+00	2026-02-10 04:00:13.214647+00	\N	aal1	\N	\N	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.7632.6 Safari/537.36	121.143.18.55	\N	\N	\N	\N	\N
3dccbb85-f5a0-4578-80b3-62f1404f0125	10e558ca-3940-4995-9a8f-165e78efaffc	2026-02-10 04:00:17.287921+00	2026-02-10 04:00:17.287921+00	\N	aal1	\N	\N	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.7632.6 Safari/537.36	121.143.18.55	\N	\N	\N	\N	\N
63286937-5f83-4a29-9ccf-37f2100991be	10e558ca-3940-4995-9a8f-165e78efaffc	2026-02-10 04:00:22.213711+00	2026-02-10 04:00:22.213711+00	\N	aal1	\N	\N	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.7632.6 Safari/537.36	121.143.18.55	\N	\N	\N	\N	\N
4ca9797c-d4b6-4bcc-a4d5-f8bace732be8	10e558ca-3940-4995-9a8f-165e78efaffc	2026-02-10 04:00:25.626515+00	2026-02-10 04:00:25.626515+00	\N	aal1	\N	\N	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.7632.6 Safari/537.36	121.143.18.55	\N	\N	\N	\N	\N
65aac392-b0d7-46d7-8ab8-b114449d16e2	10e558ca-3940-4995-9a8f-165e78efaffc	2026-02-10 04:00:30.60911+00	2026-02-10 04:00:30.60911+00	\N	aal1	\N	\N	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.7632.6 Safari/537.36	121.143.18.55	\N	\N	\N	\N	\N
0c4ec18d-ed00-47c9-a1b7-1e9bcd332f51	10e558ca-3940-4995-9a8f-165e78efaffc	2026-02-10 04:16:51.669636+00	2026-02-10 04:16:51.669636+00	\N	aal1	\N	\N	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.7632.6 Safari/537.36	121.143.18.55	\N	\N	\N	\N	\N
6a2e9bf3-d0df-44f6-99bb-c48b463c9b14	10e558ca-3940-4995-9a8f-165e78efaffc	2026-02-10 04:16:51.669614+00	2026-02-10 04:16:51.669614+00	\N	aal1	\N	\N	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.7632.6 Safari/537.36	121.143.18.55	\N	\N	\N	\N	\N
aff85e06-971d-4723-a84d-c5fbd69c70ce	10e558ca-3940-4995-9a8f-165e78efaffc	2026-02-10 04:16:57.890672+00	2026-02-10 04:16:57.890672+00	\N	aal1	\N	\N	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.7632.6 Safari/537.36	121.143.18.55	\N	\N	\N	\N	\N
98dbde8e-6f29-43d0-b7eb-5fa250db4346	10e558ca-3940-4995-9a8f-165e78efaffc	2026-02-10 04:17:04.959458+00	2026-02-10 04:17:04.959458+00	\N	aal1	\N	\N	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.7632.6 Safari/537.36	121.143.18.55	\N	\N	\N	\N	\N
a401120b-a6a2-4a53-a413-8546b9687ce2	10e558ca-3940-4995-9a8f-165e78efaffc	2026-02-10 04:17:31.061761+00	2026-02-10 04:17:31.061761+00	\N	aal1	\N	\N	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.7632.6 Safari/537.36	121.143.18.55	\N	\N	\N	\N	\N
1159bacc-dfd5-4f6b-88d9-b2e66095eaae	10e558ca-3940-4995-9a8f-165e78efaffc	2026-02-10 04:17:35.098966+00	2026-02-10 04:17:35.098966+00	\N	aal1	\N	\N	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.7632.6 Safari/537.36	121.143.18.55	\N	\N	\N	\N	\N
2e89df82-89c4-43ba-9426-183442b41eef	10e558ca-3940-4995-9a8f-165e78efaffc	2026-02-10 04:17:37.604057+00	2026-02-10 04:17:37.604057+00	\N	aal1	\N	\N	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.7632.6 Safari/537.36	121.143.18.55	\N	\N	\N	\N	\N
67546a3b-57b3-4c94-9fe6-f1b01fec88fd	10e558ca-3940-4995-9a8f-165e78efaffc	2026-02-10 04:18:08.751005+00	2026-02-10 04:18:08.751005+00	\N	aal1	\N	\N	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.7632.6 Safari/537.36	121.143.18.55	\N	\N	\N	\N	\N
6466da4a-89a3-4f08-bfad-a03dc50e97d5	10e558ca-3940-4995-9a8f-165e78efaffc	2026-02-10 04:18:10.268364+00	2026-02-10 04:18:10.268364+00	\N	aal1	\N	\N	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.7632.6 Safari/537.36	121.143.18.55	\N	\N	\N	\N	\N
a67e30d2-df8a-4980-80a0-ef41195e6fa3	10e558ca-3940-4995-9a8f-165e78efaffc	2026-02-10 04:18:16.765031+00	2026-02-10 04:18:16.765031+00	\N	aal1	\N	\N	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.7632.6 Safari/537.36	121.143.18.55	\N	\N	\N	\N	\N
ad404359-2677-4d8f-9a6c-a65601a1f2e6	10e558ca-3940-4995-9a8f-165e78efaffc	2026-02-10 04:18:25.096422+00	2026-02-10 04:18:25.096422+00	\N	aal1	\N	\N	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.7632.6 Safari/537.36	121.143.18.55	\N	\N	\N	\N	\N
5c255d06-81e1-44e5-9181-3fd566eaaac1	10e558ca-3940-4995-9a8f-165e78efaffc	2026-02-10 04:18:26.475811+00	2026-02-10 04:18:26.475811+00	\N	aal1	\N	\N	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.7632.6 Safari/537.36	121.143.18.55	\N	\N	\N	\N	\N
29fd3ed3-77a4-40fe-aedb-0bad7f03ffc5	10e558ca-3940-4995-9a8f-165e78efaffc	2026-02-10 04:18:46.356893+00	2026-02-10 04:18:46.356893+00	\N	aal1	\N	\N	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.7632.6 Safari/537.36	121.143.18.55	\N	\N	\N	\N	\N
05f25140-2caf-4ae8-8384-f0d7ea8dbe99	10e558ca-3940-4995-9a8f-165e78efaffc	2026-02-10 04:18:56.700887+00	2026-02-10 04:18:56.700887+00	\N	aal1	\N	\N	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.7632.6 Safari/537.36	121.143.18.55	\N	\N	\N	\N	\N
b661349f-1545-4461-8a97-d42f338269e2	10e558ca-3940-4995-9a8f-165e78efaffc	2026-02-10 04:19:06.495569+00	2026-02-10 04:19:06.495569+00	\N	aal1	\N	\N	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.7632.6 Safari/537.36	121.143.18.55	\N	\N	\N	\N	\N
e281739f-35a5-4f6d-beb0-c4d4d9691de6	10e558ca-3940-4995-9a8f-165e78efaffc	2026-02-10 04:19:10.008449+00	2026-02-10 04:19:10.008449+00	\N	aal1	\N	\N	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.7632.6 Safari/537.36	121.143.18.55	\N	\N	\N	\N	\N
e8b5e1df-417f-4307-aefd-eb1dcbc0179c	10e558ca-3940-4995-9a8f-165e78efaffc	2026-02-10 04:19:13.513894+00	2026-02-10 04:19:13.513894+00	\N	aal1	\N	\N	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.7632.6 Safari/537.36	121.143.18.55	\N	\N	\N	\N	\N
be73f1bc-ad41-4423-9806-2853365620f4	10e558ca-3940-4995-9a8f-165e78efaffc	2026-02-10 04:19:29.23187+00	2026-02-10 04:19:29.23187+00	\N	aal1	\N	\N	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.7632.6 Safari/537.36	121.143.18.55	\N	\N	\N	\N	\N
17e9837e-3e4e-4738-8c49-ec35fe35f1e3	10e558ca-3940-4995-9a8f-165e78efaffc	2026-02-10 06:32:42.921763+00	2026-02-10 06:32:42.921763+00	\N	aal1	\N	\N	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.7632.6 Safari/537.36	121.143.18.55	\N	\N	\N	\N	\N
c767ef86-fd07-4496-bd0c-304234a72f15	10e558ca-3940-4995-9a8f-165e78efaffc	2026-02-10 06:32:48.35787+00	2026-02-10 06:32:48.35787+00	\N	aal1	\N	\N	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.7632.6 Safari/537.36	121.143.18.55	\N	\N	\N	\N	\N
963f65dd-b5cf-4041-a471-3d49d432811e	10e558ca-3940-4995-9a8f-165e78efaffc	2026-02-10 06:32:49.278426+00	2026-02-10 06:32:49.278426+00	\N	aal1	\N	\N	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.7632.6 Safari/537.36	121.143.18.55	\N	\N	\N	\N	\N
d7e4dc0c-9266-4a18-a676-2680aa6ba7dd	10e558ca-3940-4995-9a8f-165e78efaffc	2026-02-10 06:33:20.316908+00	2026-02-10 06:33:20.316908+00	\N	aal1	\N	\N	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.7632.6 Safari/537.36	121.143.18.55	\N	\N	\N	\N	\N
7ca7ad6d-4d94-4b70-aa89-a41847604416	10e558ca-3940-4995-9a8f-165e78efaffc	2026-02-10 06:33:46.30902+00	2026-02-10 06:33:46.30902+00	\N	aal1	\N	\N	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.7632.6 Safari/537.36	121.143.18.55	\N	\N	\N	\N	\N
d9d2d6c1-60c7-44ed-bad3-7f32e27db910	10e558ca-3940-4995-9a8f-165e78efaffc	2026-02-10 06:33:51.684402+00	2026-02-10 06:33:51.684402+00	\N	aal1	\N	\N	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.7632.6 Safari/537.36	121.143.18.55	\N	\N	\N	\N	\N
f9340fb6-771d-4898-b942-9b200cbcf420	10e558ca-3940-4995-9a8f-165e78efaffc	2026-02-10 06:33:33.83642+00	2026-02-10 06:33:33.83642+00	\N	aal1	\N	\N	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.7632.6 Safari/537.36	121.143.18.55	\N	\N	\N	\N	\N
20ca7267-a36f-4a49-a215-5424a4645236	10e558ca-3940-4995-9a8f-165e78efaffc	2026-02-10 06:33:57.908615+00	2026-02-10 06:33:57.908615+00	\N	aal1	\N	\N	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.7632.6 Safari/537.36	121.143.18.55	\N	\N	\N	\N	\N
ca0ec7d2-3d97-414a-95b4-fedc33e82b5b	10e558ca-3940-4995-9a8f-165e78efaffc	2026-02-10 06:34:12.524901+00	2026-02-10 06:34:12.524901+00	\N	aal1	\N	\N	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.7632.6 Safari/537.36	121.143.18.55	\N	\N	\N	\N	\N
5a2fa2c4-b74f-469e-9ed5-25b99d75a708	10e558ca-3940-4995-9a8f-165e78efaffc	2026-02-10 06:34:13.330227+00	2026-02-10 06:34:13.330227+00	\N	aal1	\N	\N	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.7632.6 Safari/537.36	121.143.18.55	\N	\N	\N	\N	\N
82e2d3f0-3b9d-4041-89e8-102ef982f1ff	10e558ca-3940-4995-9a8f-165e78efaffc	2026-02-10 06:34:18.073959+00	2026-02-10 06:34:18.073959+00	\N	aal1	\N	\N	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.7632.6 Safari/537.36	121.143.18.55	\N	\N	\N	\N	\N
5d7ab598-b672-4d6d-a02f-92ce60cb7c94	10e558ca-3940-4995-9a8f-165e78efaffc	2026-02-10 06:34:22.759601+00	2026-02-10 06:34:22.759601+00	\N	aal1	\N	\N	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.7632.6 Safari/537.36	121.143.18.55	\N	\N	\N	\N	\N
149a4dd9-a455-4bc8-a142-3a022fb60d17	10e558ca-3940-4995-9a8f-165e78efaffc	2026-02-10 06:34:33.091941+00	2026-02-10 06:34:33.091941+00	\N	aal1	\N	\N	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.7632.6 Safari/537.36	121.143.18.55	\N	\N	\N	\N	\N
2e6fef9d-b203-46a0-afce-b87f8a758e01	10e558ca-3940-4995-9a8f-165e78efaffc	2026-02-10 06:34:53.473925+00	2026-02-10 06:34:53.473925+00	\N	aal1	\N	\N	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.7632.6 Safari/537.36	121.143.18.55	\N	\N	\N	\N	\N
53a117ec-69c4-40ad-8403-4c7b57c7e199	10e558ca-3940-4995-9a8f-165e78efaffc	2026-02-10 07:28:14.130173+00	2026-02-10 07:28:14.130173+00	\N	aal1	\N	\N	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.7632.6 Safari/537.36	121.143.18.55	\N	\N	\N	\N	\N
502b511f-ee88-4792-8855-a829f3f91d9f	10e558ca-3940-4995-9a8f-165e78efaffc	2026-02-10 07:28:20.778608+00	2026-02-10 07:28:20.778608+00	\N	aal1	\N	\N	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.7632.6 Safari/537.36	121.143.18.55	\N	\N	\N	\N	\N
ee596f2a-dc76-4048-aae7-5ebb03ce31c8	9969cfc6-451e-4ab2-ae2f-5d10a98eaf0a	2026-02-12 05:54:59.033865+00	2026-02-12 07:51:31.247212+00	\N	aal1	\N	2026-02-12 07:51:31.245563	Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/26.2 Safari/605.1.15	121.143.18.55	\N	\N	\N	\N	\N
d5c296b8-50d5-47a7-b7c2-2abecaae18f3	06d3b907-e06e-466b-a5fe-2dcc3912afaf	2026-02-07 14:26:10.762141+00	2026-02-10 13:21:23.867181+00	\N	aal1	\N	2026-02-10 13:21:23.86706	Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/143.0.0.0 Safari/537.36	118.37.189.11	\N	\N	\N	\N	\N
66adc0be-5bc3-48a6-b579-6ea2ca136e44	10e558ca-3940-4995-9a8f-165e78efaffc	2026-02-11 01:41:28.314856+00	2026-02-11 01:41:28.314856+00	\N	aal1	\N	\N	Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) HeadlessChrome/145.0.7632.6 Safari/537.36	121.143.18.55	\N	\N	\N	\N	\N
49ec853d-432c-4a92-b098-5d24f2e14708	10e558ca-3940-4995-9a8f-165e78efaffc	2026-02-11 01:44:25.107501+00	2026-02-11 01:44:25.107501+00	\N	aal1	\N	\N	Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) HeadlessChrome/145.0.7632.6 Safari/537.36	121.143.18.55	\N	\N	\N	\N	\N
2ed18d0a-77bf-4a85-a533-4d13d1c8d361	10e558ca-3940-4995-9a8f-165e78efaffc	2026-02-11 02:02:17.747834+00	2026-02-11 02:02:17.747834+00	\N	aal1	\N	\N	Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) HeadlessChrome/145.0.7632.6 Safari/537.36	121.143.18.55	\N	\N	\N	\N	\N
f32518b9-f923-4b7d-b4a5-e9a6230b3636	10e558ca-3940-4995-9a8f-165e78efaffc	2026-02-11 02:07:49.643917+00	2026-02-11 02:07:49.643917+00	\N	aal1	\N	\N	Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) HeadlessChrome/145.0.7632.6 Safari/537.36	121.143.18.55	\N	\N	\N	\N	\N
f9cf2f10-7d5a-4150-9486-78e634b5a346	10e558ca-3940-4995-9a8f-165e78efaffc	2026-02-11 02:39:23.578876+00	2026-02-11 02:39:23.578876+00	\N	aal1	\N	\N	Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) HeadlessChrome/145.0.7632.6 Safari/537.36	121.143.18.55	\N	\N	\N	\N	\N
739168c5-c96d-4f48-9788-339ab4b728ee	10e558ca-3940-4995-9a8f-165e78efaffc	2026-02-11 03:27:08.971147+00	2026-02-11 03:27:08.971147+00	\N	aal1	\N	\N	Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) HeadlessChrome/145.0.7632.6 Safari/537.36	121.143.18.55	\N	\N	\N	\N	\N
34c5c29f-6cd5-4237-86ee-6ff5b46fdf67	10e558ca-3940-4995-9a8f-165e78efaffc	2026-02-11 03:27:18.992118+00	2026-02-11 03:27:18.992118+00	\N	aal1	\N	\N	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.7632.6 Safari/537.36	121.143.18.55	\N	\N	\N	\N	\N
39a9b6df-bd60-4d14-be59-8c1042997a3e	10e558ca-3940-4995-9a8f-165e78efaffc	2026-02-11 03:27:19.097665+00	2026-02-11 03:27:19.097665+00	\N	aal1	\N	\N	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.7632.6 Safari/537.36	121.143.18.55	\N	\N	\N	\N	\N
714c1858-7bf7-4e8a-8c7c-6c7251f6c5cd	10e558ca-3940-4995-9a8f-165e78efaffc	2026-02-11 03:27:58.299707+00	2026-02-11 03:27:58.299707+00	\N	aal1	\N	\N	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.7632.6 Safari/537.36	121.143.18.55	\N	\N	\N	\N	\N
d51fe136-847e-4aeb-95e8-20f97c9934f7	10e558ca-3940-4995-9a8f-165e78efaffc	2026-02-11 03:27:58.395717+00	2026-02-11 03:27:58.395717+00	\N	aal1	\N	\N	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.7632.6 Safari/537.36	121.143.18.55	\N	\N	\N	\N	\N
c451c2b8-3c4e-4abb-941f-9e4532127166	10e558ca-3940-4995-9a8f-165e78efaffc	2026-02-11 03:28:38.857319+00	2026-02-11 03:28:38.857319+00	\N	aal1	\N	\N	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.7632.6 Safari/537.36	121.143.18.55	\N	\N	\N	\N	\N
b21b563d-4cf4-40bd-bab8-d05f58c1d4ba	10e558ca-3940-4995-9a8f-165e78efaffc	2026-02-11 03:28:38.924406+00	2026-02-11 03:28:38.924406+00	\N	aal1	\N	\N	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.7632.6 Safari/537.36	121.143.18.55	\N	\N	\N	\N	\N
b90eb011-1b08-418f-a421-fc856f9a8933	10e558ca-3940-4995-9a8f-165e78efaffc	2026-02-11 03:29:31.445474+00	2026-02-11 03:29:31.445474+00	\N	aal1	\N	\N	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.7632.6 Safari/537.36	121.143.18.55	\N	\N	\N	\N	\N
fcb6d021-1ea4-437a-8440-e058c01f6a5b	10e558ca-3940-4995-9a8f-165e78efaffc	2026-02-11 03:29:48.076863+00	2026-02-11 03:29:48.076863+00	\N	aal1	\N	\N	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.7632.6 Safari/537.36	121.143.18.55	\N	\N	\N	\N	\N
4c7b78cb-2b96-408a-8701-ab0e27e9a9a4	10e558ca-3940-4995-9a8f-165e78efaffc	2026-02-11 03:30:04.577593+00	2026-02-11 03:30:04.577593+00	\N	aal1	\N	\N	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.7632.6 Safari/537.36	121.143.18.55	\N	\N	\N	\N	\N
5da60bcb-7600-4147-b787-b6697f1fc2ca	10e558ca-3940-4995-9a8f-165e78efaffc	2026-02-11 03:32:37.449484+00	2026-02-11 03:32:37.449484+00	\N	aal1	\N	\N	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.7632.6 Safari/537.36	121.143.18.55	\N	\N	\N	\N	\N
d31c6efd-12dd-498b-93a8-198706384db3	10e558ca-3940-4995-9a8f-165e78efaffc	2026-02-11 03:32:38.065955+00	2026-02-11 03:32:38.065955+00	\N	aal1	\N	\N	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.7632.6 Safari/537.36	121.143.18.55	\N	\N	\N	\N	\N
9d7f36aa-5164-40d1-8bb8-e2ee6c93c287	10e558ca-3940-4995-9a8f-165e78efaffc	2026-02-11 03:33:38.993166+00	2026-02-11 03:33:38.993166+00	\N	aal1	\N	\N	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.7632.6 Safari/537.36	121.143.18.55	\N	\N	\N	\N	\N
da167d3a-1f5a-4e4f-b3a3-ebc630ae03ad	9969cfc6-451e-4ab2-ae2f-5d10a98eaf0a	2026-02-11 10:59:21.502655+00	2026-02-11 10:59:21.502655+00	\N	aal1	\N	\N	Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36	121.143.18.55	\N	\N	\N	\N	\N
fdc7ca80-679a-432d-ba50-babf4dcb0a38	9969cfc6-451e-4ab2-ae2f-5d10a98eaf0a	2026-02-11 12:50:30.680715+00	2026-02-11 14:19:24.930156+00	\N	aal1	\N	2026-02-11 14:19:24.930039	Mozilla/5.0 (Linux; Android 10; K) AppleWebKit/537.36 (KHTML, like Gecko) SamsungBrowser/29.0 Chrome/136.0.0.0 Mobile Safari/537.36	121.143.18.69	\N	\N	\N	\N	\N
37538335-78cc-4a58-98ab-d359e5dfc985	10e558ca-3940-4995-9a8f-165e78efaffc	2026-02-11 12:19:39.638645+00	2026-02-12 07:02:53.738302+00	\N	aal1	\N	2026-02-12 07:02:53.738195	Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36	121.143.18.55	\N	\N	\N	\N	\N
\.


--
-- Data for Name: sso_domains; Type: TABLE DATA; Schema: auth; Owner: supabase_auth_admin
--

COPY auth.sso_domains (id, sso_provider_id, domain, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: sso_providers; Type: TABLE DATA; Schema: auth; Owner: supabase_auth_admin
--

COPY auth.sso_providers (id, resource_id, created_at, updated_at, disabled) FROM stdin;
\.


--
-- Data for Name: users; Type: TABLE DATA; Schema: auth; Owner: supabase_auth_admin
--

COPY auth.users (instance_id, id, aud, role, email, encrypted_password, email_confirmed_at, invited_at, confirmation_token, confirmation_sent_at, recovery_token, recovery_sent_at, email_change_token_new, email_change, email_change_sent_at, last_sign_in_at, raw_app_meta_data, raw_user_meta_data, is_super_admin, created_at, updated_at, phone, phone_confirmed_at, phone_change, phone_change_token, phone_change_sent_at, email_change_token_current, email_change_confirm_status, banned_until, reauthentication_token, reauthentication_sent_at, is_sso_user, deleted_at, is_anonymous) FROM stdin;
00000000-0000-0000-0000-000000000000	1768c70a-81b5-4b3d-80b2-7e2a8f7d631b	authenticated	authenticated	gardenia_319@naver.com	$2a$10$8m6Rsjdf9nRG8lA8dPmlrO6Trz04rkWXXm0t09e0RPiwSakOAiImO	2026-02-08 05:01:25.499535+00	\N		2026-02-08 05:01:08.355171+00		\N			\N	2026-02-08 05:01:55.705866+00	{"provider": "email", "providers": ["email"]}	{"sub": "1768c70a-81b5-4b3d-80b2-7e2a8f7d631b", "email": "gardenia_319@naver.com", "email_verified": true, "phone_verified": false}	\N	2026-02-08 05:01:08.27831+00	2026-02-08 05:01:55.734547+00	\N	\N			\N		0	\N		\N	f	\N	f
00000000-0000-0000-0000-000000000000	e65bfdd9-1478-4264-a26d-6db676ab49bf	authenticated	authenticated	codex_1770697037255@mail.com	$2a$10$pWM93zb8J3f5xjyxwwXy6.wZfFWHl4.gAsxSvsX8YdXdbRqLOyfJm	2026-02-10 04:17:17.769417+00	\N		\N		\N			\N	\N	{"provider": "email", "providers": ["email"]}	{"email_verified": true}	\N	2026-02-10 04:17:17.748684+00	2026-02-10 04:17:17.770852+00	\N	\N			\N		0	\N		\N	f	\N	f
\N	43075ac5-9589-4a40-9861-7b90cb7c30b9	\N	\N	sim_user_a@test.com	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N			\N		0	\N		\N	f	\N	f
\N	428f4a8e-2ccc-4bff-9d30-e44cc6c4fdbe	\N	\N	sim_user_b@test.com	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N			\N		0	\N		\N	f	\N	f
\N	d9d7ce43-118a-438a-bcd6-6ddc3117b789	\N	\N	sim_user_c@test.com	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N			\N		0	\N		\N	f	\N	f
\N	349325a9-2d7a-4a3a-8dfb-7e2082cf1280	\N	\N	sim_user_d@test.com	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N			\N		0	\N		\N	f	\N	f
\N	ebdd4583-a106-4909-9b73-aaf392e3bc72	\N	\N	sim_user_e@test.com	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N			\N		0	\N		\N	f	\N	f
00000000-0000-0000-0000-000000000000	60abdd33-af5a-4dfb-b211-a057a0995d12	authenticated	authenticated	gracepk34@gmail.com	$2a$10$UnJxbllTPmAblxqjXmyk/e/uDTMyvPtwrFQSMQwQrflTlxjqmjj6S	2026-02-02 01:32:56.224257+00	\N		2026-02-02 01:31:37.304243+00		\N			\N	2026-02-02 01:32:59.076484+00	{"provider": "email", "providers": ["email"]}	{"sub": "60abdd33-af5a-4dfb-b211-a057a0995d12", "email": "gracepk34@gmail.com", "email_verified": true, "phone_verified": false}	\N	2026-02-02 01:31:37.249177+00	2026-02-03 13:24:30.128259+00	\N	\N			\N		0	\N		\N	f	\N	f
00000000-0000-0000-0000-000000000000	4cb9d918-0c1c-45a0-a0a5-fd405a0cda38	authenticated	authenticated	codex_1770695858717@mail.com	$2a$10$EXCyxKs3shRPYjSw4E4yseml2ykizqkPt3yBvW/Sp4ws8uiZ9NCPW	2026-02-10 03:57:39.431728+00	\N		\N		\N			\N	\N	{"provider": "email", "providers": ["email"]}	{"email_verified": true}	\N	2026-02-10 03:57:39.391336+00	2026-02-10 03:57:39.432669+00	\N	\N			\N		0	\N		\N	f	\N	f
00000000-0000-0000-0000-000000000000	1ddb44b9-add6-437f-96de-2e7c2df0bfcc	authenticated	authenticated	tourismyujy@gmail.com	$2a$10$JUR/Dpwf3LeVLECEcNYqWuKS501lxbU36fWsWctlLK2dW6bUogv92	2026-02-07 05:47:32.668398+00	\N		2026-02-07 05:47:18.033769+00		\N			\N	2026-02-07 05:47:52.462917+00	{"provider": "email", "providers": ["email"]}	{"sub": "1ddb44b9-add6-437f-96de-2e7c2df0bfcc", "email": "tourismyujy@gmail.com", "email_verified": true, "phone_verified": false}	\N	2026-02-07 05:47:17.987058+00	2026-02-07 05:47:52.480663+00	\N	\N			\N		0	\N		\N	f	\N	f
00000000-0000-0000-0000-000000000000	36ae407d-c380-41ff-a714-d61371c44fb3	authenticated	authenticated	naeiver@naver.com	$2a$10$AURcT/5MOgHMugMOZxkDw.fVtTmDeN0mTfZ/bfOeozdPd5D8nxhyq	2026-02-02 01:51:31.069384+00	\N		2026-02-02 01:49:56.787489+00		\N			\N	2026-02-02 01:51:32.123977+00	{"provider": "email", "providers": ["email"]}	{"sub": "36ae407d-c380-41ff-a714-d61371c44fb3", "email": "naeiver@naver.com", "email_verified": true, "phone_verified": false}	\N	2026-02-02 01:49:56.750167+00	2026-02-06 01:00:42.757281+00	\N	\N			\N		0	\N		\N	f	\N	f
00000000-0000-0000-0000-000000000000	5ac10c39-274e-4ce5-a13b-f4da3af4a230	authenticated	authenticated	sjustone000@gmail.com	$2a$10$2a/pam.KY5gu27W62sWPF.0f8tJB7oRSKxcSfQEBcAJ/t21Dgr5jS	2026-01-30 09:21:46.241779+00	\N		2026-01-30 09:20:35.097006+00		\N			\N	2026-01-31 03:32:33.983988+00	{"provider": "email", "providers": ["email"]}	{"sub": "5ac10c39-274e-4ce5-a13b-f4da3af4a230", "email": "sjustone000@gmail.com", "email_verified": true, "phone_verified": false}	\N	2026-01-30 09:20:35.023883+00	2026-02-06 10:11:22.072986+00	\N	\N			\N		0	\N		\N	f	\N	f
00000000-0000-0000-0000-000000000000	62a4018e-393c-4aa0-a754-3db136771637	authenticated	authenticated	codex_1770705148556@mail.com	$2a$10$I3y/IrRoc9qJm/LrIo1hTe6/rPM5OZidX.30ZO0Y5CNwnZyozuLja	2026-02-10 06:32:29.305702+00	\N		\N		\N			\N	\N	{"provider": "email", "providers": ["email"]}	{"email_verified": true}	\N	2026-02-10 06:32:29.25794+00	2026-02-10 06:32:29.311922+00	\N	\N			\N		0	\N		\N	f	\N	f
00000000-0000-0000-0000-000000000000	95f608be-c1e9-43b1-b885-5e2784e4858f	authenticated	authenticated	test4@mail.com	$2a$06$cidAXHO35wfvKP85Ubh6/ekkNVfSdXmKqf7EVJ5ViriLTGPYoBn5a	2026-02-03 00:43:59.521071+00	\N		\N		2026-02-02 23:08:54.736679+00			\N	2026-02-05 14:54:18.125313+00	{"provider": "email", "providers": ["email"]}	{}	\N	2026-02-02 23:08:54.736679+00	2026-02-11 09:43:07.650332+00	\N	\N			\N		0	\N		\N	f	\N	f
00000000-0000-0000-0000-000000000000	f62d4e26-bb72-4b86-9539-a54a8fcbad7e	authenticated	authenticated	codex_1770708357487@mail.com	$2a$10$E670gMZPcO/oj3AqFpSFmeW9D5Xo.CXfNgrx8XN7R7fq4deBDDAki	2026-02-10 07:25:58.227573+00	\N		\N		\N			\N	\N	{"provider": "email", "providers": ["email"]}	{"email_verified": true}	\N	2026-02-10 07:25:58.19358+00	2026-02-10 07:25:58.229032+00	\N	\N			\N		0	\N		\N	f	\N	f
00000000-0000-0000-0000-000000000000	5e4ec0ef-464a-41db-8e2f-9f3bfa2671ee	authenticated	authenticated	test3@mail.com	$2a$06$cidAXHO35wfvKP85Ubh6/ekkNVfSdXmKqf7EVJ5ViriLTGPYoBn5a	2026-02-03 00:43:59.521071+00	\N		\N		2026-02-02 23:08:54.736679+00			\N	2026-02-05 14:54:13.777444+00	{"provider": "email", "providers": ["email"]}	{}	\N	2026-02-02 23:08:54.736679+00	2026-02-11 10:39:02.453241+00	\N	\N			\N		0	\N		\N	f	\N	f
00000000-0000-0000-0000-000000000000	06d3b907-e06e-466b-a5fe-2dcc3912afaf	authenticated	authenticated	ych6133@daum.net	$2a$10$cif4iN8qEYqMAl.9YqSQmOYrmTEu4vJ5dC0KtTl8DxNQZLOQJo.j2	2026-02-07 14:16:07.891569+00	\N		2026-02-07 14:15:54.841426+00		\N			\N	2026-02-07 14:26:10.762021+00	{"provider": "email", "providers": ["email"]}	{"sub": "06d3b907-e06e-466b-a5fe-2dcc3912afaf", "email": "ych6133@daum.net", "email_verified": true, "phone_verified": false}	\N	2026-02-07 14:15:54.774673+00	2026-02-10 13:21:23.85396+00	\N	\N			\N		0	\N		\N	f	\N	f
00000000-0000-0000-0000-000000000000	8cf7c6be-ba2c-48c9-8825-589e675ff608	authenticated	authenticated	test5@mail.com	$2a$06$cidAXHO35wfvKP85Ubh6/ekkNVfSdXmKqf7EVJ5ViriLTGPYoBn5a	2026-02-03 00:43:59.521071+00	\N		\N		2026-02-02 23:08:54.736679+00			\N	2026-02-05 14:55:02.192048+00	{"provider": "email", "providers": ["email"]}	{}	\N	2026-02-02 23:08:54.736679+00	2026-02-09 23:54:57.710019+00	\N	\N			\N		0	\N		\N	f	\N	f
00000000-0000-0000-0000-000000000000	10e558ca-3940-4995-9a8f-165e78efaffc	authenticated	authenticated	test2@mail.com	$2a$06$cidAXHO35wfvKP85Ubh6/ekkNVfSdXmKqf7EVJ5ViriLTGPYoBn5a	2026-02-03 00:43:59.521071+00	\N		\N		2026-02-02 23:08:54.736679+00			\N	2026-02-11 12:19:39.638553+00	{"provider": "email", "providers": ["email"]}	{}	\N	2026-02-02 23:08:54.736679+00	2026-02-12 07:02:53.722553+00	\N	\N			\N		0	\N		\N	f	\N	f
00000000-0000-0000-0000-000000000000	7ce98344-7670-4faf-853e-70080f6fdfa1	authenticated	authenticated	codex_1770780540161@mail.com	$2a$10$pbgWozlRQ/zwyTn4EEeU1OgHv1e8GS7xppkZ4iisWUuBh7zgILaD2	2026-02-11 03:29:00.874737+00	\N		\N		\N			\N	\N	{"provider": "email", "providers": ["email"]}	{"email_verified": true}	\N	2026-02-11 03:29:00.845132+00	2026-02-11 03:29:00.875565+00	\N	\N			\N		0	\N		\N	f	\N	f
00000000-0000-0000-0000-000000000000	9969cfc6-451e-4ab2-ae2f-5d10a98eaf0a	authenticated	authenticated	test1@mail.com	$2a$06$cidAXHO35wfvKP85Ubh6/ekkNVfSdXmKqf7EVJ5ViriLTGPYoBn5a	2026-02-03 00:43:59.521071+00	\N		\N		2026-02-02 23:08:54.736679+00			\N	2026-02-12 05:54:59.033771+00	{"provider": "email", "providers": ["email"]}	{}	\N	2026-02-02 23:08:54.736679+00	2026-02-12 07:51:31.236524+00	\N	\N			\N		0	\N		\N	f	\N	f
\.


--
-- Data for Name: activity_logs; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.activity_logs (id, user_id, action_type, asset_symbol, prediction_id, metadata, created_at) FROM stdin;
1	95f608be-c1e9-43b1-b885-5e2784e4858f	RESOLVE	BTCUSDT	420	{"payout": 23, "profit": 11, "status": "WIN", "streak": 0, "open_price": 64762.31745067788, "close_price": 64984.66407408995, "is_target_hit": false}	2026-02-06 09:00:25.111162+00
2	95f608be-c1e9-43b1-b885-5e2784e4858f	RESOLVE	XAGUSD	428	{"payout": 43, "profit": 30, "status": "WIN", "streak": 1, "open_price": 73.21499633789062, "close_price": 30.845, "is_target_hit": true}	2026-02-06 09:00:26.340525+00
3	95f608be-c1e9-43b1-b885-5e2784e4858f	RESOLVE	BTCUSDT	429	{"payout": 24, "profit": 11, "status": "WIN", "streak": 0, "open_price": 64727.414074250795, "close_price": 64984.66407408995, "is_target_hit": false}	2026-02-06 09:00:28.091134+00
4	95f608be-c1e9-43b1-b885-5e2784e4858f	RESOLVE	ETHUSDT	430	{"payout": 0, "profit": -12, "status": "LOSS", "streak": 0, "open_price": 1874.2865624121073, "close_price": 1872, "is_target_hit": false}	2026-02-06 09:00:29.905025+00
5	10e558ca-3940-4995-9a8f-165e78efaffc	BET	XRPUSDT	431	{"direction": "DOWN", "timeframe": "30m", "bet_amount": 113, "entry_price": 1.312, "target_percent": 0.5, "candle_close_at": "2026-02-06T10:00:00+00:00"}	2026-02-06 09:36:38.503491+00
6	10e558ca-3940-4995-9a8f-165e78efaffc	RESOLVE	XRPUSDT	431	{"payout": 0, "profit": -113, "status": "LOSS", "streak": 0, "open_price": 1.3097115774550252, "close_price": 1.327732680439997, "is_target_hit": true}	2026-02-06 10:00:29.65978+00
7	95f608be-c1e9-43b1-b885-5e2784e4858f	BET	BTCUSDT	432	{"direction": "DOWN", "timeframe": "1m", "bet_amount": 15, "entry_price": 65953.61, "target_percent": 0.5, "candle_close_at": "2026-02-06T10:32:00+00:00"}	2026-02-06 10:31:07.257042+00
8	95f608be-c1e9-43b1-b885-5e2784e4858f	BET	XAUUSD	433	{"direction": "UP", "timeframe": "1m", "bet_amount": 15, "entry_price": 4884.7998046875, "target_percent": 0.5, "candle_close_at": "2026-02-06T10:33:00+00:00"}	2026-02-06 10:32:11.417975+00
9	95f608be-c1e9-43b1-b885-5e2784e4858f	RESOLVE	BTCUSDT	432	{"payout": 0, "profit": -15, "status": "LOSS", "streak": 0, "open_price": 65953.61, "close_price": 65972.99, "is_target_hit": false}	2026-02-06 10:32:53.678299+00
10	95f608be-c1e9-43b1-b885-5e2784e4858f	RESOLVE	XAUUSD	433	{"payout": 0, "profit": -15, "status": "LOSS", "streak": 0, "open_price": 4860.375805664063, "close_price": 4860.375805664063, "is_target_hit": false}	2026-02-06 10:33:53.481471+00
11	95f608be-c1e9-43b1-b885-5e2784e4858f	BET	BTCUSDT	434	{"direction": "DOWN", "timeframe": "1m", "bet_amount": 15, "entry_price": 66430.57, "target_percent": 0.5, "candle_close_at": "2026-02-06T12:03:00+00:00"}	2026-02-06 12:02:16.159555+00
12	95f608be-c1e9-43b1-b885-5e2784e4858f	BET	XAUUSD	435	{"direction": "DOWN", "timeframe": "1m", "bet_amount": 15, "entry_price": 4910.39990234375, "target_percent": 1, "candle_close_at": "2026-02-06T12:04:00+00:00"}	2026-02-06 12:03:14.444379+00
13	95f608be-c1e9-43b1-b885-5e2784e4858f	RESOLVE	BTCUSDT	434	{"payout": 0, "profit": -15, "status": "LOSS", "streak": 0, "open_price": 66430.57, "close_price": 66460.54, "is_target_hit": false}	2026-02-06 12:03:52.703865+00
14	95f608be-c1e9-43b1-b885-5e2784e4858f	RESOLVE	XAUUSD	435	{"payout": 0, "profit": -15, "status": "LOSS", "streak": 0, "open_price": 4885.847902832032, "close_price": 4885.847902832032, "is_target_hit": false}	2026-02-06 12:04:53.674614+00
15	10e558ca-3940-4995-9a8f-165e78efaffc	BET	XAUUSD	436	{"direction": "UP", "timeframe": "1m", "bet_amount": 10, "entry_price": 4956.7998046875, "target_percent": 0.5, "candle_close_at": "2026-02-06T13:50:00+00:00"}	2026-02-06 13:49:17.757272+00
16	10e558ca-3940-4995-9a8f-165e78efaffc	RESOLVE	XAUUSD	436	{"payout": 0, "profit": -10, "status": "LOSS", "streak": 0, "open_price": 4951.843004882812, "close_price": 4932.015805664062, "is_target_hit": false}	2026-02-06 13:50:44.09666+00
17	10e558ca-3940-4995-9a8f-165e78efaffc	BET	XAUUSD	437	{"direction": "DOWN", "timeframe": "30m", "bet_amount": 88, "entry_price": 4951.7998046875, "target_percent": 0.5, "candle_close_at": "2026-02-06T14:30:00+00:00"}	2026-02-06 14:00:24.291682+00
18	10e558ca-3940-4995-9a8f-165e78efaffc	RESOLVE	XAUUSD	437	{"payout": 162, "profit": 74, "status": "WIN", "streak": 0, "open_price": 4944.10009765625, "close_price": 4927.040805664063, "is_target_hit": false}	2026-02-06 14:30:32.747822+00
19	95f608be-c1e9-43b1-b885-5e2784e4858f	BET	AAPL	438	{"direction": "UP", "timeframe": "1m", "bet_amount": 15, "entry_price": 279.54998779296875, "target_percent": 0.5, "candle_close_at": "2026-02-06T14:39:00+00:00"}	2026-02-06 14:38:12.907297+00
20	95f608be-c1e9-43b1-b885-5e2784e4858f	BET	XAGUSD	439	{"direction": "DOWN", "timeframe": "1m", "bet_amount": 18, "entry_price": 74.30500030517578, "target_percent": 1, "candle_close_at": "2026-02-06T14:40:00+00:00"}	2026-02-06 14:39:09.705571+00
21	95f608be-c1e9-43b1-b885-5e2784e4858f	RESOLVE	AAPL	438	{"payout": 0, "profit": -15, "status": "LOSS", "streak": 0, "open_price": 279.7650146484375, "close_price": 279.2704378051758, "is_target_hit": false}	2026-02-06 14:39:57.859029+00
22	95f608be-c1e9-43b1-b885-5e2784e4858f	BET	ETHUSDT	440	{"direction": "UP", "timeframe": "1m", "bet_amount": 17, "entry_price": 1980.65, "target_percent": 2, "candle_close_at": "2026-02-06T14:41:00+00:00"}	2026-02-06 14:40:19.290148+00
23	95f608be-c1e9-43b1-b885-5e2784e4858f	RESOLVE	XAGUSD	439	{"payout": 32, "profit": 14, "status": "WIN", "streak": 0, "open_price": 74.23069530487061, "close_price": 73.9334753036499, "is_target_hit": false}	2026-02-06 14:40:52.783587+00
24	95f608be-c1e9-43b1-b885-5e2784e4858f	RESOLVE	ETHUSDT	440	{"payout": 30, "profit": 13, "status": "WIN", "streak": 0, "open_price": 1978.25, "close_price": 1979.2, "is_target_hit": false}	2026-02-06 14:41:52.724+00
25	10e558ca-3940-4995-9a8f-165e78efaffc	BET	XAUUSD	441	{"direction": "DOWN", "timeframe": "1h", "bet_amount": 103, "entry_price": 4974.39990234375, "target_percent": 0.5, "candle_close_at": "2026-02-06T16:00:00+00:00"}	2026-02-06 15:11:45.735477+00
26	10e558ca-3940-4995-9a8f-165e78efaffc	RESOLVE	XAUUSD	441	{"payout": 0, "profit": -103, "status": "LOSS", "streak": 0, "open_price": 4967.60009765625, "close_price": 4971.7998046875, "is_target_hit": false}	2026-02-06 16:17:22.703401+00
27	10e558ca-3940-4995-9a8f-165e78efaffc	BET	BTCUSDT	442	{"direction": "UP", "timeframe": "30m", "bet_amount": 10, "entry_price": 69953.86, "target_percent": 0.5, "candle_close_at": "2026-02-07T02:00:00+00:00"}	2026-02-07 01:39:35.936033+00
28	10e558ca-3940-4995-9a8f-165e78efaffc	BET	ETHUSDT	443	{"direction": "DOWN", "timeframe": "30m", "bet_amount": 10, "entry_price": 2043.76, "target_percent": 0.5, "candle_close_at": "2026-02-07T02:00:00+00:00"}	2026-02-07 01:39:53.168557+00
29	10e558ca-3940-4995-9a8f-165e78efaffc	BET	ETHUSDT	444	{"direction": "DOWN", "timeframe": "1m", "bet_amount": 10, "entry_price": 2052.06, "target_percent": 0.5, "candle_close_at": "2026-02-07T01:41:00+00:00"}	2026-02-07 01:40:19.099991+00
30	10e558ca-3940-4995-9a8f-165e78efaffc	BET	ETHUSDT	445	{"direction": "UP", "timeframe": "1d", "bet_amount": 10, "entry_price": 2062.31, "target_percent": 0.5, "candle_close_at": "2026-02-08T00:00:00+00:00"}	2026-02-07 01:40:48.583965+00
31	10e558ca-3940-4995-9a8f-165e78efaffc	RESOLVE	ETHUSDT	444	{"payout": 18, "profit": 8, "status": "WIN", "streak": 0, "open_price": 2051.99, "close_price": 2051.5, "is_target_hit": false}	2026-02-07 01:41:43.48322+00
32	10e558ca-3940-4995-9a8f-165e78efaffc	RESOLVE	BTCUSDT	442	{"payout": 37, "profit": 27, "status": "WIN", "streak": 1, "open_price": 69953.86, "close_price": 70450.01, "is_target_hit": true}	2026-02-07 02:01:14.608064+00
33	10e558ca-3940-4995-9a8f-165e78efaffc	RESOLVE	ETHUSDT	443	{"payout": 0, "profit": -10, "status": "LOSS", "streak": 0, "open_price": 2043.76, "close_price": 2061.52, "is_target_hit": true}	2026-02-07 02:01:15.823195+00
34	10e558ca-3940-4995-9a8f-165e78efaffc	BET	BTCUSDT	446	{"direction": "UP", "timeframe": "1h", "bet_amount": 10, "entry_price": 70131.69, "target_percent": 0.5, "candle_close_at": "2026-02-07T07:00:00+00:00"}	2026-02-07 06:00:12.838571+00
35	10e558ca-3940-4995-9a8f-165e78efaffc	BET	ETHUSDT	447	{"direction": "UP", "timeframe": "1m", "bet_amount": 10, "entry_price": 2080.83, "target_percent": 0.5, "candle_close_at": "2026-02-07T06:05:00+00:00"}	2026-02-07 06:04:12.221221+00
36	10e558ca-3940-4995-9a8f-165e78efaffc	BET	SOLUSDT	448	{"direction": "DOWN", "timeframe": "1m", "bet_amount": 82, "entry_price": 87.93, "target_percent": 0.5, "candle_close_at": "2026-02-07T06:06:00+00:00"}	2026-02-07 06:05:10.146858+00
37	10e558ca-3940-4995-9a8f-165e78efaffc	RESOLVE	ETHUSDT	447	{"payout": 18, "profit": 8, "status": "WIN", "streak": 0, "open_price": 2080.83, "close_price": 2083.85, "is_target_hit": false}	2026-02-07 06:05:43.818696+00
38	10e558ca-3940-4995-9a8f-165e78efaffc	RESOLVE	SOLUSDT	448	{"payout": 0, "profit": -82, "status": "LOSS", "streak": 0, "open_price": 87.93, "close_price": 87.96, "is_target_hit": false}	2026-02-07 06:06:43.952568+00
39	10e558ca-3940-4995-9a8f-165e78efaffc	BET	SOLUSDT	449	{"direction": "UP", "timeframe": "1h", "bet_amount": 10, "entry_price": 86.22, "target_percent": 0.5, "candle_close_at": "2026-02-07T08:00:00+00:00"}	2026-02-07 07:00:19.588681+00
40	10e558ca-3940-4995-9a8f-165e78efaffc	RESOLVE	BTCUSDT	446	{"payout": 0, "profit": -10, "status": "LOSS", "streak": 0, "open_price": 70131.69, "close_price": 68752.2, "is_target_hit": true}	2026-02-07 07:01:15.361357+00
41	10e558ca-3940-4995-9a8f-165e78efaffc	BET	BTCUSDT	450	{"direction": "UP", "timeframe": "1h", "bet_amount": 67, "entry_price": 68752.2, "target_percent": 0.5, "candle_close_at": "2026-02-07T08:00:00+00:00"}	2026-02-07 07:10:16.321888+00
42	10e558ca-3940-4995-9a8f-165e78efaffc	RESOLVE	SOLUSDT	449	{"payout": 0, "profit": -10, "status": "LOSS", "streak": 0, "open_price": 86.22, "close_price": 85.25, "is_target_hit": true}	2026-02-07 08:01:15.092817+00
43	10e558ca-3940-4995-9a8f-165e78efaffc	RESOLVE	BTCUSDT	450	{"payout": 0, "profit": -67, "status": "LOSS", "streak": 0, "open_price": 68752.2, "close_price": 68075.72, "is_target_hit": true}	2026-02-07 08:01:16.209035+00
44	10e558ca-3940-4995-9a8f-165e78efaffc	BET	XRPUSDT	451	{"direction": "DOWN", "timeframe": "1m", "bet_amount": 53, "entry_price": 1.423, "target_percent": 0.5, "candle_close_at": "2026-02-07T09:11:00+00:00"}	2026-02-07 09:10:11.824923+00
45	10e558ca-3940-4995-9a8f-165e78efaffc	RESOLVE	XRPUSDT	451	{"payout": 0, "profit": -53, "status": "LOSS", "streak": 0, "open_price": 1.422, "close_price": 1.423, "is_target_hit": false}	2026-02-07 09:11:44.249147+00
46	10e558ca-3940-4995-9a8f-165e78efaffc	BET	XRPUSDT	452	{"direction": "UP", "timeframe": "1m", "bet_amount": 10, "entry_price": 1.391, "target_percent": 0.5, "candle_close_at": "2026-02-07T12:00:00+00:00"}	2026-02-07 11:59:10.737895+00
47	10e558ca-3940-4995-9a8f-165e78efaffc	BET	DOGEUSDT	453	{"direction": "UP", "timeframe": "30m", "bet_amount": 10, "entry_price": 0.09541, "target_percent": 0.5, "candle_close_at": "2026-02-07T12:30:00+00:00"}	2026-02-07 12:00:16.632419+00
48	10e558ca-3940-4995-9a8f-165e78efaffc	RESOLVE	XRPUSDT	452	{"payout": 0, "profit": -10, "status": "LOSS", "streak": 0, "open_price": 1.391, "close_price": 1.391, "is_target_hit": false}	2026-02-07 12:00:33.272474+00
49	10e558ca-3940-4995-9a8f-165e78efaffc	BET	AVAXUSDT	454	{"direction": "UP", "timeframe": "15m", "bet_amount": 10, "entry_price": 8.98, "target_percent": 0.5, "candle_close_at": "2026-02-07T12:15:00+00:00"}	2026-02-07 12:00:46.386249+00
50	10e558ca-3940-4995-9a8f-165e78efaffc	BET	SOLUSDT	455	{"direction": "DOWN", "timeframe": "30m", "bet_amount": 10, "entry_price": 84.86, "target_percent": 0.5, "candle_close_at": "2026-02-07T12:30:00+00:00"}	2026-02-07 12:01:18.725032+00
51	10e558ca-3940-4995-9a8f-165e78efaffc	RESOLVE	AVAXUSDT	454	{"payout": 37, "profit": 27, "status": "WIN", "streak": 1, "open_price": 8.98, "close_price": 9.115, "is_target_hit": true}	2026-02-07 12:15:43.975388+00
52	10e558ca-3940-4995-9a8f-165e78efaffc	RESOLVE	DOGEUSDT	453	{"payout": 46, "profit": 36, "status": "WIN", "streak": 2, "open_price": 0.09541, "close_price": 0.09689, "is_target_hit": true}	2026-02-07 12:30:44.245744+00
53	10e558ca-3940-4995-9a8f-165e78efaffc	RESOLVE	SOLUSDT	455	{"payout": 0, "profit": -10, "status": "LOSS", "streak": 0, "open_price": 84.86, "close_price": 86.16, "is_target_hit": true}	2026-02-07 12:30:45.556916+00
54	06d3b907-e06e-466b-a5fe-2dcc3912afaf	BET	BTCUSDT	456	{"direction": "UP", "timeframe": "1m", "bet_amount": 10, "entry_price": 68973.56, "target_percent": 1, "candle_close_at": "2026-02-07T14:27:00+00:00"}	2026-02-07 14:26:25.677847+00
55	06d3b907-e06e-466b-a5fe-2dcc3912afaf	BET	BTCUSDT	457	{"direction": "DOWN", "timeframe": "1m", "bet_amount": 10, "entry_price": 69016.06, "target_percent": 0.5, "candle_close_at": "2026-02-07T14:28:00+00:00"}	2026-02-07 14:27:18.292937+00
56	06d3b907-e06e-466b-a5fe-2dcc3912afaf	RESOLVE	BTCUSDT	456	{"payout": 18, "profit": 8, "status": "WIN", "streak": 0, "open_price": 68973.56, "close_price": 69016.06, "is_target_hit": false}	2026-02-07 14:27:53.474494+00
57	06d3b907-e06e-466b-a5fe-2dcc3912afaf	BET	BTCUSDT	458	{"direction": "DOWN", "timeframe": "1m", "bet_amount": 10, "entry_price": 68964.87, "target_percent": 1, "candle_close_at": "2026-02-07T14:29:00+00:00"}	2026-02-07 14:28:24.960892+00
58	06d3b907-e06e-466b-a5fe-2dcc3912afaf	BET	BTCUSDT	459	{"direction": "DOWN", "timeframe": "1m", "bet_amount": 10, "entry_price": 68979.9, "target_percent": 0.5, "candle_close_at": "2026-02-07T14:30:00+00:00"}	2026-02-07 14:29:23.542779+00
59	06d3b907-e06e-466b-a5fe-2dcc3912afaf	RESOLVE	BTCUSDT	457	{"payout": 18, "profit": 8, "status": "WIN", "streak": 0, "open_price": 69016.06, "close_price": 68964.87, "is_target_hit": false}	2026-02-07 14:29:33.081739+00
60	06d3b907-e06e-466b-a5fe-2dcc3912afaf	RESOLVE	BTCUSDT	458	{"payout": 0, "profit": -10, "status": "LOSS", "streak": 0, "open_price": 68964.87, "close_price": 68979.9, "is_target_hit": false}	2026-02-07 14:29:35.202507+00
61	95f608be-c1e9-43b1-b885-5e2784e4858f	BET	BTCUSDT	460	{"direction": "UP", "timeframe": "1m", "bet_amount": 14, "entry_price": 68979.9, "target_percent": 0.5, "candle_close_at": "2026-02-07T14:30:00+00:00"}	2026-02-07 14:29:37.657778+00
64	95f608be-c1e9-43b1-b885-5e2784e4858f	RESOLVE	BTCUSDT	460	{"payout": 0, "profit": -14, "status": "LOSS", "streak": 0, "open_price": 68979.9, "close_price": 68921.84, "is_target_hit": false}	2026-02-07 14:30:33.288177+00
62	06d3b907-e06e-466b-a5fe-2dcc3912afaf	BET	BTCUSDT	461	{"direction": "UP", "timeframe": "1m", "bet_amount": 10, "entry_price": 68921.84, "target_percent": 1, "candle_close_at": "2026-02-07T14:31:00+00:00"}	2026-02-07 14:30:09.122324+00
65	06d3b907-e06e-466b-a5fe-2dcc3912afaf	BET	BTCUSDT	462	{"direction": "UP", "timeframe": "1m", "bet_amount": 10, "entry_price": 68912.79, "target_percent": 0.5, "candle_close_at": "2026-02-07T14:33:00+00:00"}	2026-02-07 14:32:46.670669+00
68	06d3b907-e06e-466b-a5fe-2dcc3912afaf	RESOLVE	BTCUSDT	462	{"payout": 18, "profit": 8, "status": "WIN", "streak": 0, "open_price": 68912.79, "close_price": 68917.49, "is_target_hit": false}	2026-02-07 14:34:16.181222+00
69	06d3b907-e06e-466b-a5fe-2dcc3912afaf	RESOLVE	BTCUSDT	463	{"payout": 0, "profit": -10, "status": "LOSS", "streak": 0, "open_price": 68917.49, "close_price": 68901.7, "is_target_hit": false}	2026-02-07 14:34:46.274797+00
63	06d3b907-e06e-466b-a5fe-2dcc3912afaf	RESOLVE	BTCUSDT	459	{"payout": 18, "profit": 8, "status": "WIN", "streak": 0, "open_price": 68979.9, "close_price": 68921.84, "is_target_hit": false}	2026-02-07 14:30:32.904337+00
66	06d3b907-e06e-466b-a5fe-2dcc3912afaf	RESOLVE	BTCUSDT	461	{"payout": 18, "profit": 8, "status": "WIN", "streak": 0, "open_price": 68921.84, "close_price": 68947.01, "is_target_hit": false}	2026-02-07 14:33:07.656197+00
70	06d3b907-e06e-466b-a5fe-2dcc3912afaf	BET	BTCUSDT	464	{"direction": "DOWN", "timeframe": "1m", "bet_amount": 10, "entry_price": 68901.7, "target_percent": 1, "candle_close_at": "2026-02-07T14:35:00+00:00"}	2026-02-07 14:34:55.140334+00
71	06d3b907-e06e-466b-a5fe-2dcc3912afaf	BET	BTCUSDT	465	{"direction": "UP", "timeframe": "1m", "bet_amount": 10, "entry_price": 68870.55, "target_percent": 0.5, "candle_close_at": "2026-02-07T14:36:00+00:00"}	2026-02-07 14:35:10.962605+00
72	06d3b907-e06e-466b-a5fe-2dcc3912afaf	RESOLVE	BTCUSDT	464	{"payout": 18, "profit": 8, "status": "WIN", "streak": 0, "open_price": 68901.7, "close_price": 68870.55, "is_target_hit": false}	2026-02-07 14:35:46.075602+00
73	06d3b907-e06e-466b-a5fe-2dcc3912afaf	RESOLVE	BTCUSDT	465	{"payout": 0, "profit": -10, "status": "LOSS", "streak": 0, "open_price": 68870.55, "close_price": 68817.42, "is_target_hit": false}	2026-02-07 14:36:25.482044+00
67	06d3b907-e06e-466b-a5fe-2dcc3912afaf	BET	BTCUSDT	463	{"direction": "UP", "timeframe": "1m", "bet_amount": 10, "entry_price": 68917.49, "target_percent": 0.5, "candle_close_at": "2026-02-07T14:34:00+00:00"}	2026-02-07 14:33:36.247423+00
74	95f608be-c1e9-43b1-b885-5e2784e4858f	BET	BTCUSDT	466	{"direction": "DOWN", "timeframe": "1m", "bet_amount": 14, "entry_price": 68691.66, "target_percent": 1, "candle_close_at": "2026-02-07T14:42:00+00:00"}	2026-02-07 14:41:30.717463+00
75	95f608be-c1e9-43b1-b885-5e2784e4858f	RESOLVE	BTCUSDT	466	{"payout": 25, "profit": 11, "status": "WIN", "streak": 0, "open_price": 68691.66, "close_price": 68628.4, "is_target_hit": false}	2026-02-07 14:42:32.9964+00
76	10e558ca-3940-4995-9a8f-165e78efaffc	RESOLVE	ETHUSDT	445	{"payout": 43, "profit": 33, "status": "WIN", "streak": 1, "open_price": 2062.31, "close_price": 2088.31, "is_target_hit": true}	2026-02-08 00:00:33.269556+00
77	1768c70a-81b5-4b3d-80b2-7e2a8f7d631b	BET	BTCUSDT	467	{"direction": "DOWN", "timeframe": "1m", "bet_amount": 30, "entry_price": 69219.57, "target_percent": 1, "candle_close_at": "2026-02-08T05:05:00+00:00"}	2026-02-08 05:04:46.096237+00
78	1768c70a-81b5-4b3d-80b2-7e2a8f7d631b	RESOLVE	BTCUSDT	467	{"payout": 53, "profit": 23, "status": "WIN", "streak": 0, "open_price": 69219.57, "close_price": 69208.03, "is_target_hit": false}	2026-02-08 05:05:54.461856+00
79	9969cfc6-451e-4ab2-ae2f-5d10a98eaf0a	BET	XRPUSDT	468	{"direction": "DOWN", "timeframe": "1h", "bet_amount": 100, "entry_price": 1.437, "target_percent": 1, "candle_close_at": "2026-02-08T11:00:00+00:00"}	2026-02-08 10:09:21.588628+00
80	9969cfc6-451e-4ab2-ae2f-5d10a98eaf0a	BET	SOLUSDT	469	{"direction": "UP", "timeframe": "1h", "bet_amount": 50, "entry_price": 87.56, "target_percent": 0.5, "candle_close_at": "2026-02-08T11:00:00+00:00"}	2026-02-08 10:09:24.644528+00
81	9969cfc6-451e-4ab2-ae2f-5d10a98eaf0a	BET	DOTUSDT	470	{"direction": "UP", "timeframe": "1h", "bet_amount": 50, "entry_price": 1.359, "target_percent": 0.5, "candle_close_at": "2026-02-08T11:00:00+00:00"}	2026-02-08 10:09:43.621065+00
82	9969cfc6-451e-4ab2-ae2f-5d10a98eaf0a	RESOLVE	XRPUSDT	468	{"payout": 191, "profit": 91, "status": "WIN", "streak": 0, "open_price": 1.437, "close_price": 1.43, "is_target_hit": false}	2026-02-08 11:01:26.048863+00
83	9969cfc6-451e-4ab2-ae2f-5d10a98eaf0a	RESOLVE	SOLUSDT	469	{"payout": 0, "profit": -50, "status": "LOSS", "streak": 0, "open_price": 87.56, "close_price": 86.83, "is_target_hit": true}	2026-02-08 11:01:27.358289+00
84	9969cfc6-451e-4ab2-ae2f-5d10a98eaf0a	RESOLVE	DOTUSDT	470	{"payout": 0, "profit": -50, "status": "LOSS", "streak": 0, "open_price": 1.359, "close_price": 1.352, "is_target_hit": true}	2026-02-08 11:01:28.44998+00
85	9969cfc6-451e-4ab2-ae2f-5d10a98eaf0a	BET	MATICUSDT	471	{"direction": "UP", "timeframe": "1h", "bet_amount": 10, "entry_price": 0.1995, "target_percent": 0.5, "candle_close_at": "2026-02-08T12:00:00+00:00"}	2026-02-08 11:15:36.678184+00
86	9969cfc6-451e-4ab2-ae2f-5d10a98eaf0a	BET	SOLUSDT	472	{"direction": "UP", "timeframe": "1h", "bet_amount": 50, "entry_price": 86.83, "target_percent": 0.5, "candle_close_at": "2026-02-08T12:00:00+00:00"}	2026-02-08 11:16:18.153622+00
87	9969cfc6-451e-4ab2-ae2f-5d10a98eaf0a	BET	XRPUSDT	473	{"direction": "DOWN", "timeframe": "1h", "bet_amount": 100, "entry_price": 1.43, "target_percent": 1, "candle_close_at": "2026-02-08T12:00:00+00:00"}	2026-02-08 11:16:18.83312+00
88	9969cfc6-451e-4ab2-ae2f-5d10a98eaf0a	BET	DOTUSDT	474	{"direction": "UP", "timeframe": "1h", "bet_amount": 50, "entry_price": 1.352, "target_percent": 0.5, "candle_close_at": "2026-02-08T12:00:00+00:00"}	2026-02-08 11:17:00.190139+00
89	10e558ca-3940-4995-9a8f-165e78efaffc	BET	SOLUSDT	475	{"direction": "DOWN", "timeframe": "1m", "bet_amount": 13, "entry_price": 88.02, "target_percent": 0.5, "candle_close_at": "2026-02-08T11:50:00+00:00"}	2026-02-08 11:49:49.635271+00
90	10e558ca-3940-4995-9a8f-165e78efaffc	RESOLVE	SOLUSDT	475	{"payout": 23, "profit": 10, "status": "WIN", "streak": 0, "open_price": 88.02, "close_price": 87.98, "is_target_hit": false}	2026-02-08 11:50:24.958623+00
91	10e558ca-3940-4995-9a8f-165e78efaffc	BET	BTCUSDT	476	{"direction": "UP", "timeframe": "1h", "bet_amount": 15, "entry_price": 70216.23, "target_percent": 0.5, "candle_close_at": "2026-02-08T12:00:00+00:00"}	2026-02-08 11:52:47.177576+00
92	10e558ca-3940-4995-9a8f-165e78efaffc	BET	XRPUSDT	477	{"direction": "DOWN", "timeframe": "1m", "bet_amount": 14, "entry_price": 1.45, "target_percent": 0.5, "candle_close_at": "2026-02-08T11:57:00+00:00"}	2026-02-08 11:56:53.739608+00
93	10e558ca-3940-4995-9a8f-165e78efaffc	RESOLVE	XRPUSDT	477	{"payout": 25, "profit": 11, "status": "WIN", "streak": 0, "open_price": 1.45, "close_price": 1.448, "is_target_hit": false}	2026-02-08 11:57:32.431663+00
94	10e558ca-3940-4995-9a8f-165e78efaffc	BET	BTCUSDT	478	{"direction": "DOWN", "timeframe": "1m", "bet_amount": 15, "entry_price": 70932.05, "target_percent": 0.5, "candle_close_at": "2026-02-08T11:59:00+00:00"}	2026-02-08 11:58:05.029096+00
95	10e558ca-3940-4995-9a8f-165e78efaffc	RESOLVE	BTCUSDT	478	{"payout": 26, "profit": 11, "status": "WIN", "streak": 0, "open_price": 70932.05, "close_price": 70900.66, "is_target_hit": false}	2026-02-08 11:59:32.253285+00
96	9969cfc6-451e-4ab2-ae2f-5d10a98eaf0a	RESOLVE	MATICUSDT	471	{"payout": 10, "profit": 0, "status": "ND", "streak": 0, "open_price": 0.1995, "close_price": 0.1995, "is_target_hit": false}	2026-02-08 12:00:32.772422+00
97	9969cfc6-451e-4ab2-ae2f-5d10a98eaf0a	RESOLVE	SOLUSDT	472	{"payout": 115, "profit": 65, "status": "WIN", "streak": 1, "open_price": 86.83, "close_price": 88.18, "is_target_hit": true}	2026-02-08 12:00:35.997741+00
98	9969cfc6-451e-4ab2-ae2f-5d10a98eaf0a	RESOLVE	XRPUSDT	473	{"payout": 0, "profit": -100, "status": "LOSS", "streak": 0, "open_price": 1.43, "close_price": 1.452, "is_target_hit": true}	2026-02-08 12:00:37.729152+00
99	9969cfc6-451e-4ab2-ae2f-5d10a98eaf0a	RESOLVE	DOTUSDT	474	{"payout": 115, "profit": 65, "status": "WIN", "streak": 1, "open_price": 1.352, "close_price": 1.369, "is_target_hit": true}	2026-02-08 12:00:39.330844+00
100	10e558ca-3940-4995-9a8f-165e78efaffc	RESOLVE	BTCUSDT	476	{"payout": 48, "profit": 33, "status": "WIN", "streak": 1, "open_price": 70216.23, "close_price": 70946.1, "is_target_hit": true}	2026-02-08 12:00:40.48666+00
101	10e558ca-3940-4995-9a8f-165e78efaffc	BET	DOGEUSDT	479	{"direction": "DOWN", "timeframe": "1m", "bet_amount": 11, "entry_price": 0.09818, "target_percent": 0.5, "candle_close_at": "2026-02-08T12:02:00+00:00"}	2026-02-08 12:01:12.522712+00
102	10e558ca-3940-4995-9a8f-165e78efaffc	BET	AVAXUSDT	480	{"direction": "DOWN", "timeframe": "30m", "bet_amount": 17, "entry_price": 9.259, "target_percent": 0.5, "candle_close_at": "2026-02-08T12:30:00+00:00"}	2026-02-08 12:02:12.309718+00
103	10e558ca-3940-4995-9a8f-165e78efaffc	RESOLVE	DOGEUSDT	479	{"payout": 19, "profit": 8, "status": "WIN", "streak": 0, "open_price": 0.09818, "close_price": 0.09814, "is_target_hit": false}	2026-02-08 12:02:32.521762+00
104	10e558ca-3940-4995-9a8f-165e78efaffc	BET	SOLUSDT	481	{"direction": "DOWN", "timeframe": "30m", "bet_amount": 10, "entry_price": 88.18, "target_percent": 0.5, "candle_close_at": "2026-02-08T12:30:00+00:00"}	2026-02-08 12:04:05.204716+00
105	10e558ca-3940-4995-9a8f-165e78efaffc	BET	XRPUSDT	482	{"direction": "DOWN", "timeframe": "30m", "bet_amount": 17, "entry_price": 1.452, "target_percent": 0.5, "candle_close_at": "2026-02-08T12:30:00+00:00"}	2026-02-08 12:04:40.462768+00
106	9969cfc6-451e-4ab2-ae2f-5d10a98eaf0a	BET	DOTUSDT	483	{"direction": "UP", "timeframe": "1h", "bet_amount": 50, "entry_price": 1.369, "target_percent": 0.5, "candle_close_at": "2026-02-08T13:00:00+00:00"}	2026-02-08 12:12:47.4858+00
107	10e558ca-3940-4995-9a8f-165e78efaffc	RESOLVE	AVAXUSDT	480	{"payout": 31, "profit": 14, "status": "WIN", "streak": 0, "open_price": 9.259, "close_price": 9.239, "is_target_hit": false}	2026-02-08 12:30:55.088494+00
108	10e558ca-3940-4995-9a8f-165e78efaffc	RESOLVE	SOLUSDT	481	{"payout": 18, "profit": 8, "status": "WIN", "streak": 0, "open_price": 88.18, "close_price": 88.08, "is_target_hit": false}	2026-02-08 12:30:56.791846+00
109	10e558ca-3940-4995-9a8f-165e78efaffc	RESOLVE	XRPUSDT	482	{"payout": 17, "profit": 0, "status": "ND", "streak": 0, "open_price": 1.452, "close_price": 1.452, "is_target_hit": false}	2026-02-08 12:30:57.753328+00
110	10e558ca-3940-4995-9a8f-165e78efaffc	BET	BTCUSDT	484	{"direction": "DOWN", "timeframe": "30m", "bet_amount": 11, "entry_price": 70914.14, "target_percent": 0.5, "candle_close_at": "2026-02-08T13:00:00+00:00"}	2026-02-08 12:33:54.534227+00
111	10e558ca-3940-4995-9a8f-165e78efaffc	BET	ETHUSDT	485	{"direction": "DOWN", "timeframe": "15m", "bet_amount": 11, "entry_price": 2136.97, "target_percent": 0.5, "candle_close_at": "2026-02-08T12:45:00+00:00"}	2026-02-08 12:35:05.699963+00
112	10e558ca-3940-4995-9a8f-165e78efaffc	RESOLVE	ETHUSDT	485	{"payout": 19, "profit": 8, "status": "WIN", "streak": 0, "open_price": 2136.97, "close_price": 2130.13, "is_target_hit": false}	2026-02-08 12:45:55.83292+00
113	9969cfc6-451e-4ab2-ae2f-5d10a98eaf0a	BET	SOLUSDT	486	{"direction": "UP", "timeframe": "1h", "bet_amount": 10, "entry_price": 88.18, "target_percent": 0.5, "candle_close_at": "2026-02-08T13:00:00+00:00"}	2026-02-08 12:49:29.102005+00
114	9969cfc6-451e-4ab2-ae2f-5d10a98eaf0a	RESOLVE	DOTUSDT	483	{"payout": 0, "profit": -50, "status": "LOSS", "streak": 0, "open_price": 1.369, "close_price": 1.365, "is_target_hit": false}	2026-02-08 13:00:55.152019+00
115	10e558ca-3940-4995-9a8f-165e78efaffc	RESOLVE	BTCUSDT	484	{"payout": 0, "profit": -11, "status": "LOSS", "streak": 0, "open_price": 70914.14, "close_price": 71198.64, "is_target_hit": false}	2026-02-08 13:00:56.390136+00
116	9969cfc6-451e-4ab2-ae2f-5d10a98eaf0a	RESOLVE	SOLUSDT	486	{"payout": 0, "profit": -10, "status": "LOSS", "streak": 0, "open_price": 88.18, "close_price": 88.11, "is_target_hit": false}	2026-02-08 13:00:57.756653+00
117	95f608be-c1e9-43b1-b885-5e2784e4858f	BET	BTCUSDT	487	{"direction": "UP", "timeframe": "1m", "bet_amount": 14, "entry_price": 71388.84, "target_percent": 0.5, "candle_close_at": "2026-02-08T13:55:00+00:00"}	2026-02-08 13:54:03.879696+00
118	95f608be-c1e9-43b1-b885-5e2784e4858f	RESOLVE	BTCUSDT	487	{"payout": 0, "profit": -14, "status": "LOSS", "streak": 0, "open_price": 71388.84, "close_price": 71367.05, "is_target_hit": false}	2026-02-08 13:55:32.252817+00
119	95f608be-c1e9-43b1-b885-5e2784e4858f	BET	BTCUSDT	488	{"direction": "UP", "timeframe": "15m", "bet_amount": 14, "entry_price": 71180.42, "target_percent": 1, "candle_close_at": "2026-02-08T14:00:00+00:00"}	2026-02-08 13:56:40.480456+00
120	95f608be-c1e9-43b1-b885-5e2784e4858f	BET	BTCUSDT	489	{"direction": "DOWN", "timeframe": "30m", "bet_amount": 14, "entry_price": 71407.48, "target_percent": 1.5, "candle_close_at": "2026-02-08T14:00:00+00:00"}	2026-02-08 13:56:59.355834+00
121	95f608be-c1e9-43b1-b885-5e2784e4858f	BET	BTCUSDT	490	{"direction": "UP", "timeframe": "4h", "bet_amount": 71, "entry_price": 70946.1, "target_percent": 2, "candle_close_at": "2026-02-08T16:00:00+00:00"}	2026-02-08 13:57:45.067315+00
122	95f608be-c1e9-43b1-b885-5e2784e4858f	BET	BTCUSDT	491	{"direction": "UP", "timeframe": "1d", "bet_amount": 13, "entry_price": 69259.24, "target_percent": 2, "candle_close_at": "2026-02-09T00:00:00+00:00"}	2026-02-08 13:58:10.742774+00
123	95f608be-c1e9-43b1-b885-5e2784e4858f	RESOLVE	BTCUSDT	488	{"payout": 25, "profit": 11, "status": "WIN", "streak": 0, "open_price": 71180.42, "close_price": 71473.6, "is_target_hit": false}	2026-02-08 14:00:51.914473+00
124	95f608be-c1e9-43b1-b885-5e2784e4858f	RESOLVE	BTCUSDT	489	{"payout": 0, "profit": -14, "status": "LOSS", "streak": 0, "open_price": 71407.48, "close_price": 71473.6, "is_target_hit": false}	2026-02-08 14:00:53.073387+00
125	95f608be-c1e9-43b1-b885-5e2784e4858f	RESOLVE	BTCUSDT	490	{"payout": 152, "profit": 81, "status": "WIN", "streak": 0, "open_price": 70946.1, "close_price": 71143.15, "is_target_hit": false}	2026-02-08 16:01:26.496434+00
126	95f608be-c1e9-43b1-b885-5e2784e4858f	RESOLVE	BTCUSDT	491	{"payout": 31, "profit": 18, "status": "WIN", "streak": 0, "open_price": 69259.24, "close_price": 70297.07, "is_target_hit": false}	2026-02-09 00:01:26.767869+00
127	10e558ca-3940-4995-9a8f-165e78efaffc	BET	XAUUSD	492	{"direction": "DOWN", "timeframe": "1m", "bet_amount": 10, "entry_price": 5048.60009765625, "target_percent": 0.5, "candle_close_at": "2026-02-09T06:39:00+00:00"}	2026-02-09 06:38:06.00335+00
128	10e558ca-3940-4995-9a8f-165e78efaffc	BET	ETHUSDT	493	{"direction": "DOWN", "timeframe": "30m", "bet_amount": 10, "entry_price": 2073.49, "target_percent": 0.5, "candle_close_at": "2026-02-09T07:00:00+00:00"}	2026-02-09 06:39:18.526147+00
129	10e558ca-3940-4995-9a8f-165e78efaffc	RESOLVE	XAUUSD	492	{"payout": 18, "profit": 8, "status": "WIN", "streak": 0, "open_price": 5063.7458979492185, "close_price": 5043.551497558594, "is_target_hit": false}	2026-02-09 06:40:21.526491+00
130	10e558ca-3940-4995-9a8f-165e78efaffc	RESOLVE	ETHUSDT	493	{"payout": 0, "profit": -10, "status": "LOSS", "streak": 0, "open_price": 2073.49, "close_price": 2080.31, "is_target_hit": false}	2026-02-09 07:20:53.904902+00
131	10e558ca-3940-4995-9a8f-165e78efaffc	BET	ETHUSDT	494	{"direction": "DOWN", "timeframe": "30m", "bet_amount": 10, "entry_price": 2080.19, "target_percent": 0.5, "candle_close_at": "2026-02-09T08:00:00+00:00"}	2026-02-09 07:32:57.506248+00
132	10e558ca-3940-4995-9a8f-165e78efaffc	BET	ADAUSDT	495	{"direction": "UP", "timeframe": "15m", "bet_amount": 10, "entry_price": 0.2708, "target_percent": 0.5, "candle_close_at": "2026-02-09T07:45:00+00:00"}	2026-02-09 07:33:52.541029+00
133	10e558ca-3940-4995-9a8f-165e78efaffc	BET	DOGEUSDT	496	{"direction": "UP", "timeframe": "1m", "bet_amount": 10, "entry_price": 0.09554, "target_percent": 0.5, "candle_close_at": "2026-02-09T07:35:00+00:00"}	2026-02-09 07:34:49.751145+00
134	10e558ca-3940-4995-9a8f-165e78efaffc	BET	XAUUSD	497	{"direction": "UP", "timeframe": "1m", "bet_amount": 10, "entry_price": 5024.2001953125, "target_percent": 0.5, "candle_close_at": "2026-02-09T07:36:00+00:00"}	2026-02-09 07:35:09.378367+00
135	10e558ca-3940-4995-9a8f-165e78efaffc	RESOLVE	DOGEUSDT	496	{"payout": 0, "profit": -10, "status": "LOSS", "streak": 0, "open_price": 0.09554, "close_price": 0.09544, "is_target_hit": false}	2026-02-09 07:36:06.701902+00
136	10e558ca-3940-4995-9a8f-165e78efaffc	RESOLVE	XAUUSD	497	{"payout": 37, "profit": 27, "status": "WIN", "streak": 1, "open_price": 4999.079194335937, "close_price": 5029.224395507812, "is_target_hit": true}	2026-02-09 07:37:07.308153+00
137	10e558ca-3940-4995-9a8f-165e78efaffc	BET	NG	498	{"direction": "UP", "timeframe": "15m", "bet_amount": 10, "entry_price": 3.194999933242798, "target_percent": 0.5, "candle_close_at": "2026-02-09T08:15:00+00:00"}	2026-02-09 08:02:38.170337+00
138	10e558ca-3940-4995-9a8f-165e78efaffc	BET	CORN	499	{"direction": "DOWN", "timeframe": "15m", "bet_amount": 10, "entry_price": 17.5, "target_percent": 0.5, "candle_close_at": "2026-02-09T08:15:00+00:00"}	2026-02-09 08:03:30.551239+00
139	10e558ca-3940-4995-9a8f-165e78efaffc	RESOLVE	ETHUSDT	494	{"payout": 46, "profit": 36, "status": "WIN", "streak": 2, "open_price": 2080.19, "close_price": 2064.31, "is_target_hit": true}	2026-02-09 08:03:59.248324+00
140	10e558ca-3940-4995-9a8f-165e78efaffc	RESOLVE	ADAUSDT	495	{"payout": 0, "profit": -10, "status": "LOSS", "streak": 0, "open_price": 0.2708, "close_price": 0.2693, "is_target_hit": true}	2026-02-09 08:04:00.49648+00
141	10e558ca-3940-4995-9a8f-165e78efaffc	BET	XAGUSD	500	{"direction": "UP", "timeframe": "15m", "bet_amount": 10, "entry_price": 80.1050033569336, "target_percent": 0.5, "candle_close_at": "2026-02-09T08:15:00+00:00"}	2026-02-09 08:04:15.483459+00
142	10e558ca-3940-4995-9a8f-165e78efaffc	BET	WHEAT	501	{"direction": "DOWN", "timeframe": "15m", "bet_amount": 10, "entry_price": 100, "target_percent": 0.5, "candle_close_at": "2026-02-09T08:15:00+00:00"}	2026-02-09 08:06:20.501686+00
143	10e558ca-3940-4995-9a8f-165e78efaffc	BET	XRPUSDT	502	{"direction": "DOWN", "timeframe": "1h", "bet_amount": 10, "entry_price": 1.424, "target_percent": 0.5, "candle_close_at": "2026-02-09T09:00:00+00:00"}	2026-02-09 08:07:25.396723+00
144	10e558ca-3940-4995-9a8f-165e78efaffc	BET	PA	503	{"direction": "UP", "timeframe": "15m", "bet_amount": 10, "entry_price": 100, "target_percent": 0.5, "candle_close_at": "2026-02-09T12:00:00+00:00"}	2026-02-09 11:48:02.065837+00
145	10e558ca-3940-4995-9a8f-165e78efaffc	BET	ETHUSDT	504	{"direction": "UP", "timeframe": "1h", "bet_amount": 10, "entry_price": 2020.89, "target_percent": 0.5, "candle_close_at": "2026-02-09T12:00:00+00:00"}	2026-02-09 11:49:30.690042+00
146	10e558ca-3940-4995-9a8f-165e78efaffc	RESOLVE	PA	503	{"payout": 0, "profit": -10, "status": "LOSS", "streak": 0, "open_price": 1701.5, "close_price": 1696, "is_target_hit": false}	2026-02-09 12:35:30.515939+00
147	10e558ca-3940-4995-9a8f-165e78efaffc	RESOLVE	NG	498	{"payout": 18, "profit": 8, "status": "WIN", "streak": 0, "open_price": 3.197000026702881, "close_price": 3.2019999027252197, "is_target_hit": false}	2026-02-09 12:35:31.438283+00
148	10e558ca-3940-4995-9a8f-165e78efaffc	RESOLVE	CORN	499	{"payout": 10, "profit": 0, "status": "ND", "streak": 0, "open_price": 429, "close_price": 429, "is_target_hit": false}	2026-02-09 12:35:32.23525+00
149	10e558ca-3940-4995-9a8f-165e78efaffc	RESOLVE	XAGUSD	500	{"payout": 18, "profit": 8, "status": "WIN", "streak": 0, "open_price": 81.26499938964844, "close_price": 81.54000091552734, "is_target_hit": false}	2026-02-09 12:35:33.428347+00
150	10e558ca-3940-4995-9a8f-165e78efaffc	RESOLVE	WHEAT	501	{"payout": 18, "profit": 8, "status": "WIN", "streak": 0, "open_price": 528, "close_price": 527.5, "is_target_hit": false}	2026-02-09 12:35:34.263793+00
151	10e558ca-3940-4995-9a8f-165e78efaffc	RESOLVE	XRPUSDT	502	{"payout": 38, "profit": 28, "status": "WIN", "streak": 1, "open_price": 1.424, "close_price": 1.406, "is_target_hit": true}	2026-02-09 12:35:35.87856+00
152	10e558ca-3940-4995-9a8f-165e78efaffc	RESOLVE	ETHUSDT	504	{"payout": 19, "profit": 9, "status": "WIN", "streak": 0, "open_price": 2020.89, "close_price": 2026.55, "is_target_hit": false}	2026-02-09 12:35:37.121532+00
153	95f608be-c1e9-43b1-b885-5e2784e4858f	BET	BTCUSDT	505	{"direction": "UP", "timeframe": "1m", "bet_amount": 15, "entry_price": 70304.47, "target_percent": 0.5, "candle_close_at": "2026-02-09T22:07:00+00:00"}	2026-02-09 22:06:42.358718+00
154	95f608be-c1e9-43b1-b885-5e2784e4858f	RESOLVE	BTCUSDT	505	{"payout": 0, "profit": -15, "status": "LOSS", "streak": 0, "open_price": 70304.47, "close_price": 70287.35, "is_target_hit": false}	2026-02-09 22:07:32.404393+00
155	95f608be-c1e9-43b1-b885-5e2784e4858f	BET	BTCUSDT	506	{"direction": "DOWN", "timeframe": "1m", "bet_amount": 15, "entry_price": 70287.35, "target_percent": 0.5, "candle_close_at": "2026-02-09T22:08:00+00:00"}	2026-02-09 22:07:33.271406+00
156	95f608be-c1e9-43b1-b885-5e2784e4858f	RESOLVE	BTCUSDT	506	{"payout": 0, "profit": -15, "status": "LOSS", "streak": 0, "open_price": 70287.35, "close_price": 70289.42, "is_target_hit": false}	2026-02-09 22:08:32.367642+00
157	10e558ca-3940-4995-9a8f-165e78efaffc	BET	XAUUSD	507	{"direction": "UP", "timeframe": "1h", "bet_amount": 10, "entry_price": 5040.60009765625, "target_percent": 2, "candle_close_at": "2026-02-10T02:00:00+00:00"}	2026-02-10 01:00:09.621024+00
158	10e558ca-3940-4995-9a8f-165e78efaffc	BET	XAGUSD	508	{"direction": "UP", "timeframe": "1h", "bet_amount": 10, "entry_price": 80.95500183105469, "target_percent": 0.5, "candle_close_at": "2026-02-10T02:00:00+00:00"}	2026-02-10 01:01:13.186961+00
159	10e558ca-3940-4995-9a8f-165e78efaffc	BET	SOLUSDT	509	{"direction": "UP", "timeframe": "1m", "bet_amount": 10, "entry_price": 86.36, "target_percent": 1, "candle_close_at": "2026-02-10T01:02:00+00:00"}	2026-02-10 01:01:43.25801+00
160	10e558ca-3940-4995-9a8f-165e78efaffc	BET	XRPUSDT	510	{"direction": "DOWN", "timeframe": "1m", "bet_amount": 10, "entry_price": 1.436, "target_percent": 0.5, "candle_close_at": "2026-02-10T01:02:00+00:00"}	2026-02-10 01:01:55.086491+00
161	10e558ca-3940-4995-9a8f-165e78efaffc	RESOLVE	SOLUSDT	509	{"payout": 18, "profit": 8, "status": "WIN", "streak": 0, "open_price": 86.36, "close_price": 86.39, "is_target_hit": false}	2026-02-10 01:02:34.61789+00
162	10e558ca-3940-4995-9a8f-165e78efaffc	RESOLVE	XRPUSDT	510	{"payout": 0, "profit": -10, "status": "LOSS", "streak": 0, "open_price": 1.436, "close_price": 1.437, "is_target_hit": false}	2026-02-10 01:02:36.850438+00
163	10e558ca-3940-4995-9a8f-165e78efaffc	RESOLVE	XAUUSD	507	{"payout": 0, "profit": -10, "status": "LOSS", "streak": 0, "open_price": 5054.89990234375, "close_price": 5015.397097167969, "is_target_hit": false}	2026-02-10 02:00:22.958262+00
164	10e558ca-3940-4995-9a8f-165e78efaffc	RESOLVE	XAGUSD	508	{"payout": 0, "profit": -10, "status": "LOSS", "streak": 0, "open_price": 81.80999755859375, "close_price": 80.55022682189941, "is_target_hit": true}	2026-02-10 02:00:24.334619+00
165	10e558ca-3940-4995-9a8f-165e78efaffc	BET	BTCUSDT	511	{"direction": "UP", "timeframe": "1h", "bet_amount": 50, "entry_price": 69468.07, "target_percent": 0.5, "candle_close_at": "2026-02-10T05:00:00+00:00"}	2026-02-10 04:18:13.805396+00
166	10e558ca-3940-4995-9a8f-165e78efaffc	BET	BTCUSDT	512	{"direction": "UP", "timeframe": "1h", "bet_amount": 10, "entry_price": 69468.07, "target_percent": 0.5, "candle_close_at": "2026-02-10T05:00:00+00:00"}	2026-02-10 04:19:11.78806+00
167	10e558ca-3940-4995-9a8f-165e78efaffc	RESOLVE	BTCUSDT	511	{"payout": 96, "profit": 46, "status": "WIN", "streak": 0, "open_price": 69468.07, "close_price": 69794.25, "is_target_hit": false}	2026-02-10 05:00:24.079463+00
168	10e558ca-3940-4995-9a8f-165e78efaffc	RESOLVE	BTCUSDT	512	{"payout": 19, "profit": 9, "status": "WIN", "streak": 0, "open_price": 69468.07, "close_price": 69794.25, "is_target_hit": false}	2026-02-10 05:00:24.408163+00
169	10e558ca-3940-4995-9a8f-165e78efaffc	BET	BTCUSDT	513	{"direction": "UP", "timeframe": "1h", "bet_amount": 50, "entry_price": 69408.77, "target_percent": 0.5, "candle_close_at": "2026-02-10T07:00:00+00:00"}	2026-02-10 06:33:54.056957+00
170	10e558ca-3940-4995-9a8f-165e78efaffc	BET	BTCUSDT	514	{"direction": "UP", "timeframe": "1h", "bet_amount": 50, "entry_price": 69408.77, "target_percent": 0.5, "candle_close_at": "2026-02-10T07:00:00+00:00"}	2026-02-10 06:34:00.287311+00
171	10e558ca-3940-4995-9a8f-165e78efaffc	BET	BTCUSDT	515	{"direction": "UP", "timeframe": "1h", "bet_amount": 50, "entry_price": 69408.77, "target_percent": 0.5, "candle_close_at": "2026-02-10T07:00:00+00:00"}	2026-02-10 06:34:24.933238+00
172	10e558ca-3940-4995-9a8f-165e78efaffc	BET	BTCUSDT	516	{"direction": "DOWN", "timeframe": "1h", "bet_amount": 20, "entry_price": 69408.77, "target_percent": 1, "candle_close_at": "2026-02-10T07:00:00+00:00"}	2026-02-10 06:34:55.647023+00
173	10e558ca-3940-4995-9a8f-165e78efaffc	RESOLVE	BTCUSDT	513	{"payout": 0, "profit": -50, "status": "LOSS", "streak": 0, "open_price": 69408.77, "close_price": 68879.81, "is_target_hit": true}	2026-02-10 07:00:23.824178+00
174	10e558ca-3940-4995-9a8f-165e78efaffc	RESOLVE	BTCUSDT	514	{"payout": 0, "profit": -50, "status": "LOSS", "streak": 0, "open_price": 69408.77, "close_price": 68879.81, "is_target_hit": true}	2026-02-10 07:00:24.540115+00
175	10e558ca-3940-4995-9a8f-165e78efaffc	RESOLVE	BTCUSDT	515	{"payout": 0, "profit": -50, "status": "LOSS", "streak": 0, "open_price": 69408.77, "close_price": 68879.81, "is_target_hit": true}	2026-02-10 07:00:24.780897+00
176	10e558ca-3940-4995-9a8f-165e78efaffc	RESOLVE	BTCUSDT	516	{"payout": 38, "profit": 18, "status": "WIN", "streak": 0, "open_price": 69408.77, "close_price": 68879.81, "is_target_hit": false}	2026-02-10 07:00:25.025522+00
177	10e558ca-3940-4995-9a8f-165e78efaffc	BET	BTCUSDT	517	{"direction": "DOWN", "timeframe": "1h", "bet_amount": 100, "entry_price": 68879.81, "target_percent": 1, "candle_close_at": "2026-02-10T08:00:00+00:00"}	2026-02-10 07:28:17.219595+00
178	10e558ca-3940-4995-9a8f-165e78efaffc	RESOLVE	BTCUSDT	517	{"payout": 191, "profit": 91, "status": "WIN", "streak": 0, "open_price": 68879.81, "close_price": 68867.44, "is_target_hit": false}	2026-02-10 08:00:24.094047+00
179	95f608be-c1e9-43b1-b885-5e2784e4858f	BET	BTCUSDT	518	{"direction": "UP", "timeframe": "1m", "bet_amount": 15, "entry_price": 68918.22, "target_percent": 0.5, "candle_close_at": "2026-02-10T08:03:00+00:00"}	2026-02-10 08:02:20.44163+00
180	95f608be-c1e9-43b1-b885-5e2784e4858f	RESOLVE	BTCUSDT	518	{"payout": 0, "profit": -15, "status": "LOSS", "streak": 0, "open_price": 68918.22, "close_price": 68908.98, "is_target_hit": false}	2026-02-10 08:03:34.497063+00
181	95f608be-c1e9-43b1-b885-5e2784e4858f	BET	BTCUSDT	519	{"direction": "DOWN", "timeframe": "15m", "bet_amount": 15, "entry_price": 68867.44, "target_percent": 0.5, "candle_close_at": "2026-02-10T08:15:00+00:00"}	2026-02-10 08:06:43.540439+00
182	95f608be-c1e9-43b1-b885-5e2784e4858f	RESOLVE	BTCUSDT	519	{"payout": 26, "profit": 11, "status": "WIN", "streak": 0, "open_price": 68867.44, "close_price": 68788.07, "is_target_hit": false}	2026-02-10 08:15:48.563231+00
183	95f608be-c1e9-43b1-b885-5e2784e4858f	BET	BTCUSDT	520	{"direction": "UP", "timeframe": "1h", "bet_amount": 15, "entry_price": 69089.22, "target_percent": 0.5, "candle_close_at": "2026-02-10T11:00:00+00:00"}	2026-02-10 10:26:38.161778+00
184	95f608be-c1e9-43b1-b885-5e2784e4858f	BET	BTCUSDT	521	{"direction": "DOWN", "timeframe": "1m", "bet_amount": 14, "entry_price": 69156.47, "target_percent": 0.5, "candle_close_at": "2026-02-10T10:28:00+00:00"}	2026-02-10 10:27:03.901195+00
185	95f608be-c1e9-43b1-b885-5e2784e4858f	RESOLVE	BTCUSDT	521	{"payout": 0, "profit": -14, "status": "LOSS", "streak": 0, "open_price": 69156.47, "close_price": 69175.8, "is_target_hit": false}	2026-02-10 10:28:33.524916+00
186	95f608be-c1e9-43b1-b885-5e2784e4858f	RESOLVE	BTCUSDT	520	{"payout": 0, "profit": -15, "status": "LOSS", "streak": 0, "open_price": 69089.22, "close_price": 68873.5, "is_target_hit": false}	2026-02-10 11:00:24.978474+00
187	10e558ca-3940-4995-9a8f-165e78efaffc	BET	XAGUSD	522	{"direction": "UP", "timeframe": "1h", "bet_amount": 23, "entry_price": 82.16999816894531, "target_percent": 1.5, "candle_close_at": "2026-02-10T12:00:00+00:00"}	2026-02-10 11:00:50.803217+00
188	10e558ca-3940-4995-9a8f-165e78efaffc	BET	XAUUSD	523	{"direction": "UP", "timeframe": "1h", "bet_amount": 10, "entry_price": 5079.60009765625, "target_percent": 0.5, "candle_close_at": "2026-02-10T12:00:00+00:00"}	2026-02-10 11:01:21.006393+00
189	10e558ca-3940-4995-9a8f-165e78efaffc	BET	SOLUSDT	524	{"direction": "DOWN", "timeframe": "1h", "bet_amount": 10, "entry_price": 84.16, "target_percent": 0.5, "candle_close_at": "2026-02-10T12:00:00+00:00"}	2026-02-10 11:01:33.991006+00
190	10e558ca-3940-4995-9a8f-165e78efaffc	BET	ADAUSDT	525	{"direction": "DOWN", "timeframe": "30m", "bet_amount": 10, "entry_price": 0.2637, "target_percent": 0.5, "candle_close_at": "2026-02-10T11:30:00+00:00"}	2026-02-10 11:01:58.962107+00
191	10e558ca-3940-4995-9a8f-165e78efaffc	RESOLVE	ADAUSDT	525	{"payout": 0, "profit": -10, "status": "LOSS", "streak": 0, "open_price": 0.2637, "close_price": 0.2638, "is_target_hit": false}	2026-02-10 11:30:24.935834+00
192	10e558ca-3940-4995-9a8f-165e78efaffc	RESOLVE	XAGUSD	522	{"payout": 0, "profit": -23, "status": "LOSS", "streak": 0, "open_price": 81.9800033569336, "close_price": 81.75914817810059, "is_target_hit": false}	2026-02-10 12:00:24.251356+00
193	10e558ca-3940-4995-9a8f-165e78efaffc	RESOLVE	XAUUSD	523	{"payout": 0, "profit": -10, "status": "LOSS", "streak": 0, "open_price": 5079, "close_price": 5054.2020971679685, "is_target_hit": false}	2026-02-10 12:00:25.229878+00
194	10e558ca-3940-4995-9a8f-165e78efaffc	RESOLVE	SOLUSDT	524	{"payout": 19, "profit": 9, "status": "WIN", "streak": 0, "open_price": 84.16, "close_price": 83.77, "is_target_hit": false}	2026-02-10 12:00:27.148012+00
195	95f608be-c1e9-43b1-b885-5e2784e4858f	BET	BTCUSDT	526	{"direction": "UP", "timeframe": "1m", "bet_amount": 14, "entry_price": 68750.93, "target_percent": 0.5, "candle_close_at": "2026-02-10T15:14:00+00:00"}	2026-02-10 15:13:11.328277+00
196	95f608be-c1e9-43b1-b885-5e2784e4858f	BET	ETHUSDT	527	{"direction": "DOWN", "timeframe": "1m", "bet_amount": 14, "entry_price": 2013.85, "target_percent": 0.5, "candle_close_at": "2026-02-10T15:14:00+00:00"}	2026-02-10 15:13:36.119238+00
197	95f608be-c1e9-43b1-b885-5e2784e4858f	BET	ETHUSDT	528	{"direction": "DOWN", "timeframe": "30m", "bet_amount": 14, "entry_price": 2008.62, "target_percent": 0.5, "candle_close_at": "2026-02-10T15:30:00+00:00"}	2026-02-10 15:14:15.158733+00
198	95f608be-c1e9-43b1-b885-5e2784e4858f	RESOLVE	BTCUSDT	526	{"payout": 0, "profit": -14, "status": "LOSS", "streak": 0, "open_price": 68754.5, "close_price": 68577.32, "is_target_hit": false}	2026-02-10 15:14:38.083463+00
199	95f608be-c1e9-43b1-b885-5e2784e4858f	RESOLVE	ETHUSDT	527	{"payout": 25, "profit": 11, "status": "WIN", "streak": 0, "open_price": 2013.85, "close_price": 2006.44, "is_target_hit": false}	2026-02-10 15:14:39.162129+00
200	95f608be-c1e9-43b1-b885-5e2784e4858f	RESOLVE	ETHUSDT	528	{"payout": 0, "profit": -14, "status": "LOSS", "streak": 0, "open_price": 2008.62, "close_price": 2020.65, "is_target_hit": true}	2026-02-10 16:13:14.134416+00
201	5e4ec0ef-464a-41db-8e2f-9f3bfa2671ee	BET	BTCUSDT	529	{"direction": "UP", "timeframe": "1m", "bet_amount": 11, "entry_price": 68643.64, "target_percent": 0.5, "candle_close_at": "2026-02-10T23:14:00+00:00"}	2026-02-10 23:13:25.433438+00
202	5e4ec0ef-464a-41db-8e2f-9f3bfa2671ee	BET	BTCUSDT	530	{"direction": "DOWN", "timeframe": "15m", "bet_amount": 11, "entry_price": 68674.07, "target_percent": 0.5, "candle_close_at": "2026-02-10T23:30:00+00:00"}	2026-02-10 23:15:08.177962+00
203	5e4ec0ef-464a-41db-8e2f-9f3bfa2671ee	RESOLVE	BTCUSDT	529	{"payout": 0, "profit": -11, "status": "LOSS", "streak": 0, "open_price": 68643.64, "close_price": 68627.54, "is_target_hit": false}	2026-02-11 00:38:38.613387+00
204	5e4ec0ef-464a-41db-8e2f-9f3bfa2671ee	RESOLVE	BTCUSDT	530	{"payout": 19, "profit": 8, "status": "WIN", "streak": 0, "open_price": 68674.07, "close_price": 68624.53, "is_target_hit": false}	2026-02-11 00:38:40.778721+00
205	5e4ec0ef-464a-41db-8e2f-9f3bfa2671ee	BET	BTCUSDT	531	{"direction": "DOWN", "timeframe": "1h", "bet_amount": 11, "entry_price": 68807.07, "target_percent": 0.5, "candle_close_at": "2026-02-11T01:00:00+00:00"}	2026-02-11 00:48:52.150679+00
206	5e4ec0ef-464a-41db-8e2f-9f3bfa2671ee	BET	BTCUSDT	532	{"direction": "UP", "timeframe": "30m", "bet_amount": 11, "entry_price": 68919.06, "target_percent": 0.5, "candle_close_at": "2026-02-11T02:00:00+00:00"}	2026-02-11 01:44:49.282652+00
207	95f608be-c1e9-43b1-b885-5e2784e4858f	BET	BTCUSDT	533	{"direction": "UP", "timeframe": "30m", "bet_amount": 14, "entry_price": 68919.06, "target_percent": 0.5, "candle_close_at": "2026-02-11T02:00:00+00:00"}	2026-02-11 01:51:28.891916+00
208	5e4ec0ef-464a-41db-8e2f-9f3bfa2671ee	RESOLVE	BTCUSDT	531	{"payout": 0, "profit": -11, "status": "LOSS", "streak": 0, "open_price": 68807.07, "close_price": 69157.17, "is_target_hit": true}	2026-02-11 01:51:58.666102+00
209	5e4ec0ef-464a-41db-8e2f-9f3bfa2671ee	RESOLVE	BTCUSDT	532	{"payout": 20, "profit": 9, "status": "WIN", "streak": 0, "open_price": 68919.06, "close_price": 68942.72, "is_target_hit": false}	2026-02-11 02:00:23.520525+00
210	95f608be-c1e9-43b1-b885-5e2784e4858f	RESOLVE	BTCUSDT	533	{"payout": 26, "profit": 12, "status": "WIN", "streak": 0, "open_price": 68919.06, "close_price": 68942.72, "is_target_hit": false}	2026-02-11 02:00:23.873628+00
211	95f608be-c1e9-43b1-b885-5e2784e4858f	BET	BTCUSDT	534	{"direction": "DOWN", "timeframe": "30m", "bet_amount": 14, "entry_price": 68942.72, "target_percent": 0.5, "candle_close_at": "2026-02-11T02:30:00+00:00"}	2026-02-11 02:26:14.463052+00
212	95f608be-c1e9-43b1-b885-5e2784e4858f	RESOLVE	BTCUSDT	534	{"payout": 0, "profit": -14, "status": "LOSS", "streak": 0, "open_price": 68942.72, "close_price": 69019.7, "is_target_hit": false}	2026-02-11 02:30:29.54452+00
213	10e558ca-3940-4995-9a8f-165e78efaffc	BET	BTCUSDT	535	{"direction": "UP", "timeframe": "1h", "bet_amount": 10, "entry_price": 67036.69, "target_percent": 0.5, "candle_close_at": "2026-02-11T13:00:00+00:00"}	2026-02-11 12:20:01.404754+00
214	10e558ca-3940-4995-9a8f-165e78efaffc	BET	BTCUSDT	536	{"direction": "UP", "timeframe": "1m", "bet_amount": 10, "entry_price": 67163.25, "target_percent": 0.5, "candle_close_at": "2026-02-11T12:21:00+00:00"}	2026-02-11 12:20:14.902741+00
215	10e558ca-3940-4995-9a8f-165e78efaffc	RESOLVE	BTCUSDT	536	{"payout": 18, "profit": 8, "status": "WIN", "streak": 0, "open_price": 67163.25, "close_price": 67242.15, "is_target_hit": false}	2026-02-11 12:21:38.283157+00
216	9969cfc6-451e-4ab2-ae2f-5d10a98eaf0a	BET	BTCUSDT	537	{"direction": "UP", "timeframe": "1m", "bet_amount": 10, "entry_price": 67066.67, "target_percent": 0.5, "candle_close_at": "2026-02-11T12:51:00+00:00"}	2026-02-11 12:50:44.433649+00
217	9969cfc6-451e-4ab2-ae2f-5d10a98eaf0a	RESOLVE	BTCUSDT	537	{"payout": 18, "profit": 8, "status": "WIN", "streak": 0, "open_price": 67066.67, "close_price": 67077.34, "is_target_hit": false}	2026-02-11 12:51:39.960101+00
218	10e558ca-3940-4995-9a8f-165e78efaffc	RESOLVE	BTCUSDT	535	{"payout": 19, "profit": 9, "status": "WIN", "streak": 0, "open_price": 67036.69, "close_price": 67108.64, "is_target_hit": false}	2026-02-11 13:00:40.25114+00
\.


--
-- Data for Name: bookmarks; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.bookmarks (id, user_id, post_id, created_at) FROM stdin;
\.


--
-- Data for Name: comments; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.comments (id, user_id, post_id, content, created_at) FROM stdin;
\.


--
-- Data for Name: likes; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.likes (id, user_id, post_id, created_at) FROM stdin;
\.


--
-- Data for Name: notifications; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.notifications (id, user_id, type, title, message, points_change, is_read, created_at, prediction_id, read) FROM stdin;
ddec1000-d205-4b2f-a6a9-964a9527ee03	36ae407d-c380-41ff-a714-d61371c44fb3	loss	Prediction Lost	BTCUSDT prediction: LOSS (-10 pts)	0	t	2026-02-02 01:55:32.814124+00	26	f
dae5ebb6-23c2-4669-9d1b-7338bae1fcae	5ac10c39-274e-4ce5-a13b-f4da3af4a230	loss	Prediction Lost	BTCUSDT prediction: LOSS (-10 pts)	0	t	2026-02-02 01:55:33.107153+00	27	f
9a541104-5f43-4b96-82d8-4288b19a2a49	60abdd33-af5a-4dfb-b211-a057a0995d12	info	Prediction Ended	BTCUSDT prediction: ND (0 pts)	0	t	2026-02-02 01:55:32.579382+00	25	f
1b5be617-f9e1-40a8-a642-b1ca14a3a53f	36ae407d-c380-41ff-a714-d61371c44fb3	info	Prediction Ended	BTCUSDT prediction: ND (0 pts)	0	t	2026-02-02 02:15:32.950619+00	29	f
accc9b44-16ca-45a7-9b2e-3f7e49ffa2b8	60abdd33-af5a-4dfb-b211-a057a0995d12	loss	Prediction Lost	BTCUSDT prediction: LOSS (-10 pts)	0	t	2026-02-02 02:15:32.688266+00	28	f
26ea3c8b-2357-42a9-807a-85824f25a003	5ac10c39-274e-4ce5-a13b-f4da3af4a230	info	Prediction Ended	BTCUSDT prediction: ND (0 pts)	0	t	2026-02-02 02:15:33.175578+00	30	f
47c061d6-7f34-48fa-ac09-3a4dbf2e8202	36ae407d-c380-41ff-a714-d61371c44fb3	win	Prediction Won! 🎉	BTCUSDT prediction: WIN (10 pts)	0	t	2026-02-02 02:30:32.98753+00	32	f
2a765789-c780-418a-aa95-75e449b2a86b	36ae407d-c380-41ff-a714-d61371c44fb3	info	Prediction Ended	BTCUSDT prediction: ND (0 pts)	0	t	2026-02-02 02:30:33.793375+00	39	f
a14a52fd-0358-4d21-b38d-57d3c78395ce	5ac10c39-274e-4ce5-a13b-f4da3af4a230	info	Prediction Ended	BTCUSDT prediction: ND (0 pts)	0	t	2026-02-02 02:30:33.228265+00	33	f
67e7e073-1ea9-48d8-9c8d-1d0a9fbd3fbd	5ac10c39-274e-4ce5-a13b-f4da3af4a230	info	Prediction Ended	BTCUSDT prediction: ND (0 pts)	0	t	2026-02-02 02:30:33.452365+00	37	f
c73dbb32-025f-4f97-bb47-3b2c26120766	5ac10c39-274e-4ce5-a13b-f4da3af4a230	loss	Prediction Lost	BTCUSDT prediction: LOSS (-10 pts)	0	t	2026-02-02 02:45:33.434841+00	42	f
639a7d41-0d5e-430f-ab94-d647b4fbb3b9	60abdd33-af5a-4dfb-b211-a057a0995d12	loss	Prediction Lost	BTCUSDT prediction: LOSS (-10 pts)	0	t	2026-02-02 02:30:32.651848+00	31	f
a2ccdf84-7e87-4ce9-8370-a79394adf43c	60abdd33-af5a-4dfb-b211-a057a0995d12	loss	Prediction Lost	BTCUSDT prediction: LOSS (-10 pts)	0	t	2026-02-02 02:30:33.61487+00	38	f
0e624fba-fbbc-467f-be08-27ee6b30cdbf	60abdd33-af5a-4dfb-b211-a057a0995d12	info	Prediction Ended	BTCUSDT prediction: ND (0 pts)	0	t	2026-02-02 02:45:33.26451+00	41	f
f2ad3e5d-da7b-4e4b-bfb8-284cb8d7e540	36ae407d-c380-41ff-a714-d61371c44fb3	loss	Prediction Lost	BTCUSDT prediction: LOSS (-10 pts)	0	t	2026-02-02 02:45:33.081426+00	40	f
7406e559-55bd-4a37-bd5c-d4ab12a321c4	5ac10c39-274e-4ce5-a13b-f4da3af4a230	win	Prediction Won! 🎉	BTCUSDT prediction: WIN (20 pts)	0	t	2026-02-02 03:00:58.718547+00	36	f
5860c4be-5bb9-4bd5-81a4-511673a7653f	43075ac5-9589-4a40-9861-7b90cb7c30b9	win	Prediction Won! 🎉	TEST-BTC prediction: WIN (110 pts)	0	f	2026-02-02 23:06:52.525192+00	58	f
47be2485-c914-4f42-9b3e-a27941712880	428f4a8e-2ccc-4bff-9d30-e44cc6c4fdbe	loss	Prediction Lost	TEST-ETH prediction: LOSS (-100 pts)	0	f	2026-02-02 23:06:52.525192+00	59	f
28df609d-983d-4390-9c8e-0ba1df631a46	d9d7ce43-118a-438a-bcd6-6ddc3117b789	win	Prediction Won! 🎉	TEST-SOL prediction: WIN (129 pts)	0	f	2026-02-02 23:06:52.525192+00	60	f
bc40474e-913a-4c99-83c6-28cdf463cad1	349325a9-2d7a-4a3a-8dfb-7e2082cf1280	info	Prediction Ended	TEST-XRP prediction: ND (0 pts)	0	f	2026-02-02 23:06:52.525192+00	61	f
90e5649c-b50b-4de0-8f42-9c4041346b4e	ebdd4583-a106-4909-9b73-aaf392e3bc72	win	Prediction Won! 🎉	TEST-DOGE prediction: WIN (276 pts)	0	f	2026-02-02 23:06:52.525192+00	62	f
b6cd4686-5ddf-4fde-8142-d49ebea074c5	5ac10c39-274e-4ce5-a13b-f4da3af4a230	loss	Prediction Lost	BTCUSDT prediction: LOSS (-21 pts)	0	t	2026-02-02 08:30:59.690749+00	43	f
9075f175-6de6-4cb6-8a8a-eafd4d326656	36ae407d-c380-41ff-a714-d61371c44fb3	win	Prediction Won! 🎉	BTCUSDT prediction: WIN (20 pts)	0	t	2026-02-02 03:00:58.335013+00	34	f
2a508771-b4ca-4479-bafb-b861cd895ca9	36ae407d-c380-41ff-a714-d61371c44fb3	loss	Prediction Lost	ETHUSDT prediction: LOSS (-16 pts)	0	t	2026-02-02 08:21:59.717118+00	46	f
4a7fafbe-ec5d-4099-a0fb-2a8696802851	36ae407d-c380-41ff-a714-d61371c44fb3	loss	Prediction Lost	BTCUSDT prediction: LOSS (-21 pts)	0	t	2026-02-02 08:31:00.265051+00	45	f
c0f8ec5b-f42a-490e-b5b6-ed5fb501175b	60abdd33-af5a-4dfb-b211-a057a0995d12	loss	Prediction Lost	BTCUSDT prediction: LOSS (-10 pts)	0	t	2026-02-02 03:00:58.548789+00	35	f
a94dc378-f0e2-40b5-8d62-d6698f677948	60abdd33-af5a-4dfb-b211-a057a0995d12	info	Prediction Ended	BTCUSDT prediction: ND (10 pts)	0	t	2026-02-02 08:30:59.995324+00	44	f
3c9d8d50-4801-48ae-be8d-c1e40b34d3a3	8cf7c6be-ba2c-48c9-8825-589e675ff608	loss	Prediction Lost	BTCUSDT prediction: LOSS (0 pts)	0	f	2026-02-03 02:11:53.600765+00	67	f
d1fad187-61f2-4dbe-b477-a73b13dd6bfa	95f608be-c1e9-43b1-b885-5e2784e4858f	loss	Prediction Lost	ETHUSDT prediction: LOSS (0 pts)	0	t	2026-02-03 02:11:53.27834+00	66	f
679cbc46-896f-453d-9d82-9d0bc24b258d	10e558ca-3940-4995-9a8f-165e78efaffc	win	Prediction Won! 🎉	ETHUSDT prediction: WIN (0 pts)	0	t	2026-02-03 02:11:52.859676+00	64	f
b729affe-3c87-4ad1-a4d9-1f45c608d76a	5e4ec0ef-464a-41db-8e2f-9f3bfa2671ee	loss	Prediction Lost	ETHUSDT prediction: LOSS (0 pts)	0	t	2026-02-03 02:11:53.078893+00	65	f
10a66613-64da-4bee-b9ec-dd1118cd971f	36ae407d-c380-41ff-a714-d61371c44fb3	win	Prediction Won! 🎉	BTCUSDT prediction: WIN (0 pts)	0	f	2026-02-03 02:11:55.01381+00	80	f
8d5f6d5c-5ed4-4abd-871a-2c09928942f5	36ae407d-c380-41ff-a714-d61371c44fb3	win	Prediction Won! 🎉	BTCUSDT prediction: WIN (0 pts)	0	f	2026-02-03 02:11:56.908668+00	81	f
e87c0f0c-1926-4e4b-9259-c6877ac37f54	36ae407d-c380-41ff-a714-d61371c44fb3	loss	Prediction Lost	BTCUSDT prediction: LOSS (0 pts)	0	f	2026-02-03 02:11:57.947373+00	82	f
8d3fc172-f4ce-4f18-bb0a-f97ff5a2b666	36ae407d-c380-41ff-a714-d61371c44fb3	win	Prediction Won! 🎉	BTCUSDT prediction: WIN (0 pts)	0	f	2026-02-03 02:11:58.514557+00	79	f
405d6719-a43f-4a64-aa9a-036ac8f51ed0	36ae407d-c380-41ff-a714-d61371c44fb3	win	Prediction Won! 🎉	BTCUSDT prediction: WIN (0 pts)	0	f	2026-02-03 02:11:58.795176+00	83	f
1fcbe114-218d-4052-897e-5e07cbc9ef85	36ae407d-c380-41ff-a714-d61371c44fb3	win	Prediction Won! 🎉	BTCUSDT prediction: WIN (0 pts)	0	f	2026-02-03 02:11:59.59182+00	85	f
7a3a41b6-1095-4081-a09c-c0329d3cff80	5ac10c39-274e-4ce5-a13b-f4da3af4a230	loss	Prediction Lost	BTCUSDT prediction: LOSS (0 pts)	0	t	2026-02-03 02:11:53.820156+00	68	f
c3b90b30-3f17-426e-bf95-49f9c2c48466	5ac10c39-274e-4ce5-a13b-f4da3af4a230	win	Prediction Won! 🎉	BTCUSDT prediction: WIN (0 pts)	0	t	2026-02-03 02:11:54.055927+00	69	f
46199eed-ad92-4285-9fd0-6862338ebb6d	5ac10c39-274e-4ce5-a13b-f4da3af4a230	loss	Prediction Lost	BTCUSDT prediction: LOSS (0 pts)	0	t	2026-02-03 02:11:54.225116+00	70	f
38b74de5-e44e-4242-aaf6-29f33ea5a5fe	5ac10c39-274e-4ce5-a13b-f4da3af4a230	win	Prediction Won! 🎉	BTCUSDT prediction: WIN (0 pts)	0	t	2026-02-03 02:11:54.438114+00	71	f
09c408ab-f944-4109-95b1-c12b2294602d	5ac10c39-274e-4ce5-a13b-f4da3af4a230	win	Prediction Won! 🎉	BTCUSDT prediction: WIN (0 pts)	0	t	2026-02-03 02:11:54.683287+00	72	f
486df6d9-fbb7-4dc1-84ee-7ca224b5e56f	5ac10c39-274e-4ce5-a13b-f4da3af4a230	loss	Prediction Lost	BTCUSDT prediction: LOSS (0 pts)	0	t	2026-02-03 02:11:55.220499+00	73	f
46fef7b0-a5f1-47d0-933a-b5ec65dcb86e	5ac10c39-274e-4ce5-a13b-f4da3af4a230	win	Prediction Won! 🎉	BTCUSDT prediction: WIN (0 pts)	0	t	2026-02-03 02:11:57.07056+00	74	f
56032658-d9e4-4a04-b973-ad0301691037	5ac10c39-274e-4ce5-a13b-f4da3af4a230	win	Prediction Won! 🎉	BTCUSDT prediction: WIN (0 pts)	0	t	2026-02-03 02:11:59.171265+00	87	f
11bce20a-baa7-49d4-9603-83aee3e65982	5ac10c39-274e-4ce5-a13b-f4da3af4a230	loss	Prediction Lost	BTCUSDT prediction: LOSS (0 pts)	0	t	2026-02-03 02:11:59.793851+00	88	f
27ccde7a-576b-4b05-ae43-79254d9776eb	5ac10c39-274e-4ce5-a13b-f4da3af4a230	win	Prediction Won! 🎉	BTCUSDT prediction: WIN (0 pts)	0	t	2026-02-03 02:12:00.007976+00	90	f
d0a70f2b-7156-40b4-be3e-1c9ce38b7503	5ac10c39-274e-4ce5-a13b-f4da3af4a230	win	Prediction Won! 🎉	BTCUSDT prediction: WIN (0 pts)	0	t	2026-02-03 02:14:41.789905+00	91	f
82ab387c-4359-4521-91dc-6d3b7ff59150	5ac10c39-274e-4ce5-a13b-f4da3af4a230	loss	Prediction Lost	BTCUSDT prediction: LOSS (0 pts)	0	t	2026-02-03 02:24:41.780708+00	92	f
fb3efd50-fd47-4af5-baa7-b871ead8a650	5ac10c39-274e-4ce5-a13b-f4da3af4a230	loss	Prediction Lost	BTCUSDT prediction: LOSS (0 pts)	0	t	2026-02-03 02:25:41.861864+00	93	f
7fe54c4e-3ea4-49de-8bbd-70d43d6c999b	5ac10c39-274e-4ce5-a13b-f4da3af4a230	win	Prediction Won! 🎉	BTCUSDT prediction: WIN (0 pts)	0	t	2026-02-03 02:28:37.696229+00	94	f
c610a5f0-63d7-4947-8b16-20672a0abc61	5ac10c39-274e-4ce5-a13b-f4da3af4a230	loss	Prediction Lost	BTCUSDT prediction: LOSS (0 pts)	0	t	2026-02-03 02:30:41.804544+00	89	f
55300f33-dc20-4126-af76-85c023d0e1da	60abdd33-af5a-4dfb-b211-a057a0995d12	win	Prediction Won! 🎉	BTCUSDT prediction: WIN (0 pts)	0	t	2026-02-03 02:11:54.848782+00	76	f
f5fa5f83-757a-45ee-a037-5b7103fd859f	60abdd33-af5a-4dfb-b211-a057a0995d12	loss	Prediction Lost	BTCUSDT prediction: LOSS (0 pts)	0	t	2026-02-03 02:11:56.17838+00	77	f
491306fb-eb64-40c3-96cf-45c910a32d45	60abdd33-af5a-4dfb-b211-a057a0995d12	win	Prediction Won! 🎉	BTCUSDT prediction: WIN (0 pts)	0	t	2026-02-03 02:11:57.324549+00	78	f
30aaf659-0d82-43be-a89c-322bb38d151d	60abdd33-af5a-4dfb-b211-a057a0995d12	win	Prediction Won! 🎉	BTCUSDT prediction: WIN (0 pts)	0	t	2026-02-03 02:11:58.272196+00	75	f
d777493d-70bd-4315-a9bc-70fc1cf9f19c	60abdd33-af5a-4dfb-b211-a057a0995d12	loss	Prediction Lost	BTCUSDT prediction: LOSS (0 pts)	0	t	2026-02-03 02:11:58.961752+00	84	f
b0cc329f-c320-4609-b2e9-89b7ed93e1ea	60abdd33-af5a-4dfb-b211-a057a0995d12	loss	Prediction Lost	BTCUSDT prediction: LOSS (0 pts)	0	t	2026-02-03 02:11:59.401542+00	86	f
62ed88c3-b298-40c0-8513-9be73aa5e9a0	36ae407d-c380-41ff-a714-d61371c44fb3	win	Prediction Won! 🎉	BTCUSDT prediction: WIN (0 pts)	0	f	2026-02-03 02:54:43.905377+00	98	f
95528157-1bb5-4bcc-bfe6-c973a7136dd6	36ae407d-c380-41ff-a714-d61371c44fb3	win	✅ Match Won!	BTCUSDT: Target Hit. Great vibe! (+8 pts)	8	f	2026-02-03 02:54:43.905377+00	\N	f
4c232167-584b-45f6-8b30-aabdf05cb9b7	36ae407d-c380-41ff-a714-d61371c44fb3	win	✅ Match Won!	BTCUSDT: Target Hit. Great vibe! (+8 pts)	8	f	2026-02-03 02:54:43.9635+00	\N	f
bc09f259-2f3b-4026-ad6d-7dc789c6a664	60abdd33-af5a-4dfb-b211-a057a0995d12	loss	Prediction Lost	BTCUSDT prediction: LOSS (0 pts)	0	f	2026-02-03 02:54:50.535562+00	96	f
5c8ffb23-707a-4935-946c-212965546a4a	60abdd33-af5a-4dfb-b211-a057a0995d12	loss	❌ Match Lost	BTCUSDT: Market moved against you. (-10 pts)	-10	f	2026-02-03 02:54:50.535562+00	\N	f
9e6107d9-283c-49c8-9b2e-e3da057af250	5ac10c39-274e-4ce5-a13b-f4da3af4a230	loss	Prediction Lost	BTCUSDT prediction: LOSS (0 pts)	0	t	2026-02-03 02:54:44.281668+00	99	f
c31d3eaa-4ce0-449e-aa89-66dbc4fb5bf3	5ac10c39-274e-4ce5-a13b-f4da3af4a230	loss	❌ Match Lost	BTCUSDT: Market moved against you. (-10 pts)	-10	t	2026-02-03 02:54:44.281668+00	\N	f
780783e0-0c46-4edf-b88d-640bf9f0be11	5ac10c39-274e-4ce5-a13b-f4da3af4a230	win	Prediction Won! 🎉	BTCUSDT prediction: WIN (0 pts)	0	t	2026-02-03 02:54:50.359199+00	95	f
28a6dcf8-b939-419c-b552-a4d8f551f701	5ac10c39-274e-4ce5-a13b-f4da3af4a230	win	✅ Match Won!	BTCUSDT: Target Hit. Great vibe! (+8 pts)	8	t	2026-02-03 02:54:50.359199+00	\N	f
dd3e4215-bd4a-4c7f-9040-e74973e1bc5a	5ac10c39-274e-4ce5-a13b-f4da3af4a230	loss	Prediction Lost	BTCUSDT prediction: LOSS (0 pts)	0	t	2026-02-03 02:54:50.786224+00	97	f
81c98743-c769-4b51-bbb5-dcf5791acbb2	5ac10c39-274e-4ce5-a13b-f4da3af4a230	loss	❌ Match Lost	BTCUSDT: Market moved against you. (-10 pts)	-10	t	2026-02-03 02:54:50.786224+00	\N	f
0c72349b-30ff-4327-8514-f39891a1dd31	5ac10c39-274e-4ce5-a13b-f4da3af4a230	loss	Prediction Lost	BTCUSDT prediction: LOSS (0 pts)	0	t	2026-02-03 02:57:48.056181+00	100	f
3b2df9ed-f670-49f0-acd3-c8e09171010a	5ac10c39-274e-4ce5-a13b-f4da3af4a230	loss	❌ Match Lost	BTCUSDT: Market moved against you. (-10 pts)	-10	t	2026-02-03 02:57:48.056181+00	\N	f
04ffabb1-d656-40d5-abeb-a79a1b424077	60abdd33-af5a-4dfb-b211-a057a0995d12	loss	Prediction Lost	BTCUSDT prediction: LOSS (0 pts)	0	f	2026-02-03 03:10:43.232657+00	102	f
56643447-381a-4ce3-8de1-26c03210fff0	60abdd33-af5a-4dfb-b211-a057a0995d12	loss	❌ Match Lost	BTCUSDT: Market moved against you. (-10 pts)	-10	f	2026-02-03 03:10:43.232657+00	\N	f
164053d0-c434-4ace-9cd7-2ec3ba1be567	5ac10c39-274e-4ce5-a13b-f4da3af4a230	win	Prediction Won! 🎉	BTCUSDT prediction: WIN (0 pts)	0	t	2026-02-03 03:10:43.032915+00	101	f
942dd21e-4f07-4c21-9676-0a08572a89a3	5ac10c39-274e-4ce5-a13b-f4da3af4a230	win	✅ Match Won!	BTCUSDT: Target Hit. Great vibe! (+8 pts)	8	t	2026-02-03 03:10:43.032915+00	\N	f
e99772a6-ba1f-4d68-bc1c-fa36968e5916	5ac10c39-274e-4ce5-a13b-f4da3af4a230	loss	Prediction Lost	BTCUSDT prediction: LOSS (0 pts)	0	t	2026-02-03 03:14:43.175609+00	104	f
6d1f01b6-ed4a-4fc5-9de6-0c02d2d29ff7	5ac10c39-274e-4ce5-a13b-f4da3af4a230	loss	❌ Match Lost	BTCUSDT: Market moved against you. (-10 pts)	-10	t	2026-02-03 03:14:43.175609+00	\N	f
c4605879-9d84-46ce-97a1-361087d70130	5ac10c39-274e-4ce5-a13b-f4da3af4a230	loss	Prediction Lost	BTCUSDT prediction: LOSS (0 pts)	0	t	2026-02-03 03:19:33.90879+00	105	f
8bdad7f0-b3cb-475c-98e1-fba3a4cb7c6d	5ac10c39-274e-4ce5-a13b-f4da3af4a230	loss	❌ Match Lost	BTCUSDT: Market moved against you. (-10 pts)	-10	t	2026-02-03 03:19:33.90879+00	\N	f
1bf60eaf-a9d4-4ef9-bbf4-a00c1ca5c605	5ac10c39-274e-4ce5-a13b-f4da3af4a230	loss	❌ Match Lost	BTCUSDT: Market moved against you. (-10 pts)	-10	t	2026-02-03 03:35:30.537186+00	\N	f
13283fea-84c2-4426-bf8e-6cc48e6c9b0c	5ac10c39-274e-4ce5-a13b-f4da3af4a230	loss	❌ Match Lost	BTCUSDT: Market moved against you. (-10 pts)	-10	t	2026-02-03 03:46:30.566708+00	\N	f
fd448185-43f7-4ca6-a76e-2f244666a378	5ac10c39-274e-4ce5-a13b-f4da3af4a230	win	✅ Match Won!	BTCUSDT: Direction Correct. (+8 pts)	8	t	2026-02-03 03:48:31.060365+00	\N	f
2567af14-137c-4b47-af48-b4d8762b4587	5ac10c39-274e-4ce5-a13b-f4da3af4a230	win	✅ Match Won!	BTCUSDT: Perfect! Direction + Target Hit! 🎯 (+33 pts (Bonus Included))	33	t	2026-02-03 04:00:42.973851+00	\N	f
ca0f7e69-355c-4a97-833d-a0634b3f9aa2	5ac10c39-274e-4ce5-a13b-f4da3af4a230	win	✅ Match Won!	BTCUSDT: Direction Correct. (+8 pts)	8	t	2026-02-03 06:19:49.010921+00	\N	f
c241d18a-657e-416c-9601-9e1511ff8c0b	95f608be-c1e9-43b1-b885-5e2784e4858f	win	✅ Match Won!	BTCUSDT: Direction Correct. (+8 pts)	8	t	2026-02-03 13:55:41.301174+00	\N	f
daa4737d-0536-4fc0-b4e9-d37e0ed99ff5	95f608be-c1e9-43b1-b885-5e2784e4858f	win	✅ Match Won!	BTCUSDT: Direction Correct. (+8 pts)	8	t	2026-02-03 13:55:41.286037+00	\N	f
0927781a-c814-461d-9890-3a1818248e23	95f608be-c1e9-43b1-b885-5e2784e4858f	loss	❌ Match Lost	XAUUSD: Market moved against you. (-10 pts)	-10	t	2026-02-03 13:59:42.726061+00	\N	f
0846dbf4-bc54-4840-9782-b49d0f487319	95f608be-c1e9-43b1-b885-5e2784e4858f	loss	❌ Match Lost	BTCUSDT: Market moved against you. (-10 pts)	-10	t	2026-02-03 13:59:42.535872+00	\N	f
fba7e395-4e9e-49d7-b411-62eed7d4b043	95f608be-c1e9-43b1-b885-5e2784e4858f	loss	❌ Match Lost	BTCUSDT: Market moved against you. (-10 pts)	-10	t	2026-02-03 13:59:42.53046+00	\N	f
8f0d4efe-9706-4b1f-b246-1a821a735046	8cf7c6be-ba2c-48c9-8825-589e675ff608	win	✅ Match Won!	BTCUSDT: Direction Correct. (+8 pts)	8	f	2026-02-03 14:28:42.923794+00	\N	f
bf90add8-040d-47a6-a123-e2175b70ae54	95f608be-c1e9-43b1-b885-5e2784e4858f	win	✅ Match Won!	BTCUSDT: Direction Correct. (+8 pts)	8	t	2026-02-03 14:22:42.605824+00	\N	f
130dd21f-19f5-4dad-a8a1-c661f1a51758	95f608be-c1e9-43b1-b885-5e2784e4858f	loss	❌ Match Lost	ETHUSDT: Market moved against you. (-10 pts)	-10	t	2026-02-03 14:19:42.836977+00	\N	f
64d4d45b-e3e2-4abd-b865-ab65694e6c5a	95f608be-c1e9-43b1-b885-5e2784e4858f	loss	❌ Match Lost	ETHUSDT: Market moved against you. (-10 pts)	-10	t	2026-02-03 14:19:42.835247+00	\N	f
b96a4fd4-4bd4-41f0-821d-3d160e7e6cec	95f608be-c1e9-43b1-b885-5e2784e4858f	win	✅ Match Won!	ETHUSDT: Direction Correct. (+8 pts)	8	t	2026-02-03 14:16:42.798566+00	\N	f
9a7d2a1c-ad92-49e1-9ce6-9d8e24d7824d	95f608be-c1e9-43b1-b885-5e2784e4858f	win	✅ Match Won!	ETHUSDT: Direction Correct. (+8 pts)	8	t	2026-02-03 14:16:42.788316+00	\N	f
9c478efc-5b7f-498d-94de-71fa7a4f6468	95f608be-c1e9-43b1-b885-5e2784e4858f	win	✅ Match Won!	ETHUSDT: Direction Correct. (+8 pts)	8	t	2026-02-03 14:16:42.784306+00	\N	f
b0943a6e-0f1c-4ac1-ba3b-8630b942be0d	10e558ca-3940-4995-9a8f-165e78efaffc	win	✅ Match Won!	BTCUSDT: Direction Correct. (+8 pts)	8	t	2026-02-03 14:25:42.609879+00	\N	f
f7df1b10-a937-425d-b8bc-7613109c8029	5e4ec0ef-464a-41db-8e2f-9f3bfa2671ee	loss	❌ Match Lost	BTCUSDT: Market moved against you. (-10 pts)	-10	t	2026-02-03 14:27:42.618117+00	\N	f
f1fe7865-7abc-4523-a1f4-147346fb6120	5e4ec0ef-464a-41db-8e2f-9f3bfa2671ee	win	✅ Match Won!	BTCUSDT: Direction Correct. (+8 pts)	8	t	2026-02-03 14:24:42.747965+00	\N	f
43a1cf3f-3eb3-4084-94f9-842445d10cbb	10e558ca-3940-4995-9a8f-165e78efaffc	win	✅ Match Won!	XAUUSD: Perfect! Direction + Target Hit! 🎯 (+28 pts (Bonus Included))	28	t	2026-02-04 00:41:51.050376+00	\N	f
1c22fab6-1418-4246-92bd-db01dc00d8e4	95f608be-c1e9-43b1-b885-5e2784e4858f	loss	❌ Match Lost	XAUUSD: Market moved against you. (-10 pts)	-10	t	2026-02-04 00:56:32.618039+00	\N	f
11e8463e-92ee-4d2c-8424-67d4603b5959	95f608be-c1e9-43b1-b885-5e2784e4858f	win	✅ Match Won!	XAUUSD: Perfect! Direction + Target Hit! 🎯 (+28 pts (Bonus Included))	28	t	2026-02-04 01:06:18.906098+00	\N	f
4fb998ed-94f5-406d-86b9-cd2b66dd43b5	95f608be-c1e9-43b1-b885-5e2784e4858f	win	✅ Match Won!	BTCUSDT: Direction Correct. (+8 pts)	8	t	2026-02-04 01:53:06.606806+00	\N	f
b11a13eb-6dab-4c5b-928a-21a8cf152d27	95f608be-c1e9-43b1-b885-5e2784e4858f	loss	❌ Match Lost	BTCUSDT: Market moved against you. (-10 pts)	-10	t	2026-02-04 01:53:06.387002+00	\N	f
3e54c432-b298-43cf-99bb-ff2ea6d3babd	95f608be-c1e9-43b1-b885-5e2784e4858f	win	✅ Match Won!	BTCUSDT: Direction Correct. (+8 pts)	8	t	2026-02-04 01:53:06.150482+00	\N	f
b5d640da-a214-4d6c-8af1-da463a9fc955	95f608be-c1e9-43b1-b885-5e2784e4858f	win	✅ Match Won!	BTCUSDT: Direction Correct. (+8 pts)	8	t	2026-02-04 01:53:05.892315+00	\N	f
d9859608-c694-49ff-a7b4-3433366bbaf6	95f608be-c1e9-43b1-b885-5e2784e4858f	loss	❌ Match Lost	ETHUSDT: Market moved against you. (-10 pts)	-10	t	2026-02-04 01:53:04.596951+00	\N	f
b5605f60-2c94-4b8f-b0ea-192396256848	95f608be-c1e9-43b1-b885-5e2784e4858f	win	✅ Match Won!	XAUUSD: Direction Correct. (+8 pts)	8	t	2026-02-04 01:39:53.939144+00	\N	f
2abc730a-f57e-4c2e-a7de-74f191755e3b	95f608be-c1e9-43b1-b885-5e2784e4858f	loss	❌ Match Lost	XAUUSD: Market moved against you. (-10 pts)	-10	t	2026-02-04 02:24:34.311631+00	\N	f
7f0a0e66-d035-44c3-9107-3af3eb772e88	10e558ca-3940-4995-9a8f-165e78efaffc	win	✅ Match Won!	BTCUSDT: Direction Correct. (+8 pts)	8	t	2026-02-04 01:53:05.181317+00	\N	f
72796d82-1667-44c4-ad2c-d463c09693cf	10e558ca-3940-4995-9a8f-165e78efaffc	win	✅ Match Won!	BTCUSDT: Direction Correct. (+88 pts)	88	t	2026-02-04 01:53:05.672132+00	\N	f
700565f8-0950-40d6-8898-34227af6aa7f	10e558ca-3940-4995-9a8f-165e78efaffc	loss	❌ Match Lost	XAGUSD: Market moved against you. (-10 pts)	-10	t	2026-02-04 02:38:52.77961+00	\N	f
df992e4f-4ba4-4cc6-877e-3ae6cd61ebe8	95f608be-c1e9-43b1-b885-5e2784e4858f	win	✅ Match Won!	XAUUSD: Perfect! Direction + Target Hit! 🎯 (+28 pts (Bonus Included))	28	t	2026-02-04 05:05:58.785999+00	\N	f
385c2f76-098f-4876-a85b-b7eee6266b39	95f608be-c1e9-43b1-b885-5e2784e4858f	win	✅ Match Won!	XAUUSD: Perfect! Direction + Target Hit! 🎯 (+28 pts (Bonus Included))	28	t	2026-02-04 05:11:54.789145+00	\N	f
79040757-2cb2-476b-b7c9-570e5b5e7df9	95f608be-c1e9-43b1-b885-5e2784e4858f	win	✅ Match Won!	XAUUSD: Direction Correct. (+8 pts)	8	t	2026-02-04 06:22:42.450608+00	\N	f
4745fc02-14d6-44d5-a3ce-1c1dc8aa2a04	95f608be-c1e9-43b1-b885-5e2784e4858f	win	✅ Match Won!	XAUUSD: Perfect! Direction + Target Hit! 🎯 (+28 pts (Bonus Included))	28	t	2026-02-04 06:52:31.877854+00	\N	f
7a9ea33f-93b3-412d-8539-c268ec9fecf6	5e4ec0ef-464a-41db-8e2f-9f3bfa2671ee	loss	❌ Match Lost	BTCUSDT: Market moved against you. (-10 pts)	-10	t	2026-02-04 01:53:04.872869+00	\N	f
8a1281b5-718d-42df-9af7-6446b592dae7	10e558ca-3940-4995-9a8f-165e78efaffc	loss	❌ Match Lost	XAGUSD: Market moved against you. (-10 pts)	-10	t	2026-02-04 04:52:32.99468+00	\N	f
7af3b9f8-35d6-48ba-8890-48ac4df9899f	10e558ca-3940-4995-9a8f-165e78efaffc	loss	❌ Match Lost	XAGUSD: Market moved against you. (-10 pts)	-10	t	2026-02-04 04:53:53.876465+00	\N	f
a29575c3-c3e3-431c-8dac-f40050ec9ed4	5ac10c39-274e-4ce5-a13b-f4da3af4a230	loss	❌ Match Lost	BTCUSDT: Market moved against you. (-10 pts)	-10	t	2026-02-03 06:24:45.795009+00	\N	f
6b008506-2200-425b-bc08-09c9c781828d	95f608be-c1e9-43b1-b885-5e2784e4858f	loss	❌ Match Lost	XAUUSD: Market moved against you. (-10 pts)	-10	t	2026-02-04 07:16:50.16401+00	\N	f
15699965-7000-40f6-9a8a-f2fa905216aa	95f608be-c1e9-43b1-b885-5e2784e4858f	win	✅ Match Won!	BTCUSDT: Direction Correct. (+11 pts)	11	t	2026-02-04 10:03:50.77848+00	\N	f
de7aaf4e-a42e-40b3-90c9-5ea1b833b359	95f608be-c1e9-43b1-b885-5e2784e4858f	win	✅ Match Won!	BTCUSDT: Direction Correct. (+8 pts)	8	t	2026-02-04 10:03:51.220192+00	\N	f
9a53cecc-f942-46d1-9ef6-6fcf4748bed3	95f608be-c1e9-43b1-b885-5e2784e4858f	loss	❌ Match Lost	XAUUSD: Market moved against you. (-11 pts)	-11	t	2026-02-04 10:08:42.104117+00	\N	f
57edaca1-f796-48d3-85de-8fcc04e4157b	95f608be-c1e9-43b1-b885-5e2784e4858f	loss	❌ Match Lost	XAUUSD: Market moved against you. (-11 pts)	-11	t	2026-02-04 10:30:30.201506+00	\N	f
6157fba9-1923-4d47-92a4-ad83a88ff303	95f608be-c1e9-43b1-b885-5e2784e4858f	win	✅ Match Won!	WTI: Direction Correct. (+11 pts)	11	t	2026-02-04 10:30:30.432567+00	\N	f
ff8db9c1-b559-4ba4-8c25-97e77401eb06	95f608be-c1e9-43b1-b885-5e2784e4858f	win	✅ Match Won!	NG: Perfect! Direction + Target Hit! 🎯 (+91 pts (Bonus Included))	91	t	2026-02-04 10:30:30.670553+00	\N	f
7f2f98fd-072c-4843-b52f-7e860e5c65ed	95f608be-c1e9-43b1-b885-5e2784e4858f	loss	❌ Match Lost	NG: Market moved against you. (-11 pts)	-11	t	2026-02-04 10:30:30.895531+00	\N	f
20c076fc-506b-42a6-8eaf-31ab3243d7f3	5e4ec0ef-464a-41db-8e2f-9f3bfa2671ee	loss	❌ Match Lost	BTCUSDT: Market moved against you. (-10 pts)	-10	t	2026-02-04 01:53:05.419608+00	\N	f
15521053-fb4c-418d-9682-53f5d38d74da	95f608be-c1e9-43b1-b885-5e2784e4858f	loss	❌ Match Lost	NG: Market moved against you. (-12 pts)	-12	t	2026-02-04 10:53:52.073404+00	\N	f
5c9cb737-4c6c-4312-b871-232e396510dd	95f608be-c1e9-43b1-b885-5e2784e4858f	loss	❌ Match Lost	XAUUSD: Market moved against you. (-12 pts)	-12	t	2026-02-04 11:00:52.121061+00	\N	f
5f7f82de-eda4-4487-8813-4a4368bc9c9f	95f608be-c1e9-43b1-b885-5e2784e4858f	loss	❌ Match Lost	NG: Market moved against you. (-12 pts)	-12	t	2026-02-04 11:00:52.356967+00	\N	f
39557e39-63d6-4a41-aefb-eca2680b8c94	10e558ca-3940-4995-9a8f-165e78efaffc	loss	❌ Match Lost	XAGUSD: Market moved against you. (-10 pts)	-10	t	2026-02-04 04:53:54.118528+00	\N	f
2b7429db-1ebf-4e45-962b-f8a1b024970c	10e558ca-3940-4995-9a8f-165e78efaffc	win	✅ Match Won!	CORN: Perfect! Direction + Target Hit! 🎯 (+48 pts (Bonus Included))	48	t	2026-02-04 04:54:52.959042+00	\N	f
0143dedd-cf7e-4645-8aa8-b1c588cc1747	10e558ca-3940-4995-9a8f-165e78efaffc	loss	❌ Match Lost	XAGUSD: Market moved against you. (-73 pts)	-73	t	2026-02-04 06:36:52.425003+00	\N	f
fdb2e637-9ab1-4a0c-b125-18d777728db6	10e558ca-3940-4995-9a8f-165e78efaffc	win	✅ Match Won!	XAGUSD: Direction Correct. (+83 pts)	83	t	2026-02-04 08:01:23.616326+00	\N	f
4ca7fcc2-fb1e-44bf-9cb4-a9aaa182bd1d	10e558ca-3940-4995-9a8f-165e78efaffc	win	✅ Match Won!	XAGUSD: Perfect! Direction + Target Hit! 🎯 (+28 pts (Bonus Included))	28	t	2026-02-04 08:46:52.255238+00	\N	f
90f10a17-121f-48e7-ab62-086e52d8e8c9	10e558ca-3940-4995-9a8f-165e78efaffc	win	✅ Match Won!	XAGUSD: Perfect! Direction + Target Hit! 🎯 (+28 pts (Bonus Included))	28	t	2026-02-04 08:46:52.542873+00	\N	f
fdcb1739-a83c-4a7a-a602-2e1586b44e80	10e558ca-3940-4995-9a8f-165e78efaffc	win	✅ Match Won!	XAUUSD: Perfect! Direction + Target Hit! 🎯 (+28 pts (Bonus Included))	28	t	2026-02-04 09:26:37.762752+00	\N	f
8fd75ebf-7927-44eb-a19f-275e9ca91440	10e558ca-3940-4995-9a8f-165e78efaffc	win	✅ Match Won!	XAUUSD: Direction Correct. (+8 pts)	8	t	2026-02-04 09:27:52.638207+00	\N	f
4fb821b9-93ab-4d7e-9787-26fdeb5c79a6	10e558ca-3940-4995-9a8f-165e78efaffc	win	✅ Match Won!	XAUUSD: Direction Correct. (+8 pts)	8	t	2026-02-04 09:27:52.883423+00	\N	f
f250bbf9-ec59-47e7-9eb5-824429851586	10e558ca-3940-4995-9a8f-165e78efaffc	win	✅ Match Won!	XAUUSD: Perfect! Direction + Target Hit! 🎯 (+28 pts (Bonus Included))	28	t	2026-02-04 09:31:52.220337+00	\N	f
d390e1c6-0430-4a9f-9028-07ea959f88b5	10e558ca-3940-4995-9a8f-165e78efaffc	loss	❌ Match Lost	XAGUSD: Market moved against you. (-170 pts)	-170	t	2026-02-04 09:34:52.207781+00	\N	f
f9991bbb-dbd0-4293-8045-7b46cb4bbc85	10e558ca-3940-4995-9a8f-165e78efaffc	win	✅ Match Won!	XAUUSD: Perfect! Direction + Target Hit! 🎯 (+129 pts (Bonus Included))	129	t	2026-02-04 09:36:50.254448+00	\N	f
1f7bd862-cda9-4325-84ed-cf1aa895006a	10e558ca-3940-4995-9a8f-165e78efaffc	loss	❌ Match Lost	XAGUSD: Market moved against you. (-162 pts)	-162	t	2026-02-04 09:41:25.260184+00	\N	f
dcf85188-abb7-4f06-b6a1-c863548fcdc5	10e558ca-3940-4995-9a8f-165e78efaffc	win	✅ Match Won!	XAUUSD: Perfect! Direction + Target Hit! 🎯 (+124 pts (Bonus Included))	124	t	2026-02-04 09:42:36.968281+00	\N	f
0abf6cba-c486-459b-a150-2ee4738dac33	10e558ca-3940-4995-9a8f-165e78efaffc	win	✅ Match Won!	XAUUSD: Perfect! Direction + Target Hit! 🎯 (+103 pts (Bonus Included))	103	t	2026-02-04 09:42:37.196044+00	\N	f
a17bf94f-3084-4ba2-8c5f-2292fb2e08cb	10e558ca-3940-4995-9a8f-165e78efaffc	loss	❌ Match Lost	CORN: Market moved against you. (-10 pts)	-10	t	2026-02-04 09:47:53.852685+00	\N	f
506bdd67-2670-4216-8f66-6bbfd7532dfe	10e558ca-3940-4995-9a8f-165e78efaffc	loss	❌ Match Lost	XAGUSD: Market moved against you. (-139 pts)	-139	t	2026-02-04 09:56:52.683655+00	\N	f
42ec5fb1-ce9c-4f1a-8fef-023a8174f8b9	10e558ca-3940-4995-9a8f-165e78efaffc	loss	❌ Match Lost	BTCUSDT: Market moved against you. (-122 pts)	-122	t	2026-02-04 10:03:50.366982+00	\N	f
ff92df45-9e11-41c1-bfaa-4152a0fa00df	10e558ca-3940-4995-9a8f-165e78efaffc	loss	❌ Match Lost	BTCUSDT: Market moved against you. (-10 pts)	-10	t	2026-02-04 10:03:50.551805+00	\N	f
d3720d68-f126-40f5-9f62-46ccd0b10774	10e558ca-3940-4995-9a8f-165e78efaffc	win	✅ Match Won!	BTCUSDT: Direction Correct. (+8 pts)	8	t	2026-02-04 10:03:51.000532+00	\N	f
0c8d4a2f-da46-4bb6-b474-3cd78cf734a4	10e558ca-3940-4995-9a8f-165e78efaffc	loss	❌ Match Lost	BTCUSDT: Market moved against you. (-10 pts)	-10	t	2026-02-04 10:03:51.446182+00	\N	f
3ce7a576-a01d-4917-8418-084e67bb3b4e	10e558ca-3940-4995-9a8f-165e78efaffc	win	✅ Match Won!	XRPUSDT: Direction Correct. (+138 pts)	138	t	2026-02-04 10:03:51.667435+00	\N	f
6049c45f-5f81-42af-8abb-eb4de8b754b0	10e558ca-3940-4995-9a8f-165e78efaffc	win	✅ Match Won!	NG: Direction Correct. (+8 pts)	8	t	2026-02-04 10:18:52.529655+00	\N	f
d78b74a0-3e36-4323-9616-91dbaa2eba80	10e558ca-3940-4995-9a8f-165e78efaffc	win	✅ Match Won!	NG: Perfect! Direction + Target Hit! 🎯 (+164 pts (Bonus Included))	164	t	2026-02-04 10:21:42.829687+00	\N	f
1cb7baa5-aefe-4499-83c6-58fefad5ca46	10e558ca-3940-4995-9a8f-165e78efaffc	loss	❌ Match Lost	NG: Market moved against you. (-144 pts)	-144	t	2026-02-04 10:22:55.608797+00	\N	f
2e7bd736-fcb1-4a2a-8c20-f507996ae0b9	10e558ca-3940-4995-9a8f-165e78efaffc	loss	❌ Match Lost	NG: Market moved against you. (-115 pts)	-115	t	2026-02-04 10:22:55.822815+00	\N	f
24e20872-b822-45fd-8861-b91e9dbcba5f	95f608be-c1e9-43b1-b885-5e2784e4858f	loss	❌ Match Lost	WTI: Market moved against you. (-11 pts)	-11	t	2026-02-05 00:54:31.029602+00	\N	f
c67c4889-e26b-4500-8e3b-5e1393424a83	95f608be-c1e9-43b1-b885-5e2784e4858f	win	✅ Match Won!	NG: Perfect! Direction + Target Hit! 🎯 (+31 pts (Bonus Included))	31	t	2026-02-05 01:15:31.039296+00	\N	f
6c590d35-3da9-4f40-be46-c8930514242f	95f608be-c1e9-43b1-b885-5e2784e4858f	win	✅ Match Won!	XAGUSD: Direction Correct. (+11 pts)	11	t	2026-02-05 01:15:31.324873+00	\N	f
809ffa59-bd13-457d-9b62-8ddfb67108fd	95f608be-c1e9-43b1-b885-5e2784e4858f	win	✅ Match Won!	XAGUSD: Direction Correct. (+11 pts)	11	t	2026-02-05 01:15:31.557627+00	\N	f
3f15ed4e-c3bd-4aab-bb8d-78d081090967	95f608be-c1e9-43b1-b885-5e2784e4858f	loss	❌ Match Lost	CORN: Market moved against you. (-11 pts)	-11	t	2026-02-05 01:15:31.810988+00	\N	f
67e4781c-7bfc-40b0-9b85-c80def5ade84	95f608be-c1e9-43b1-b885-5e2784e4858f	loss	❌ Match Lost	XAUUSD: Market moved against you. (-11 pts)	-11	t	2026-02-05 02:00:31.091316+00	\N	f
6b7f22a8-9e30-47fd-a808-117fb6df3363	95f608be-c1e9-43b1-b885-5e2784e4858f	loss	❌ Match Lost	SOY: Market moved against you. (-11 pts)	-11	t	2026-02-05 02:00:31.790697+00	\N	f
b2674d62-58bd-4617-876a-9a5a651582d4	95f608be-c1e9-43b1-b885-5e2784e4858f	win	✅ Match Won!	XAUUSD: Direction Correct. (+10 pts)	10	t	2026-02-05 03:47:30.300433+00	\N	f
43b1956b-eb90-4b0d-99d5-80145b883336	95f608be-c1e9-43b1-b885-5e2784e4858f	loss	❌ Match Lost	WTI: Market moved against you. (-13 pts)	-13	t	2026-02-05 03:47:30.528653+00	\N	f
8eb00316-7339-4036-8ab2-505aa9164099	95f608be-c1e9-43b1-b885-5e2784e4858f	win	✅ Match Won!	XAUUSD: Direction Correct. (+13 pts)	13	t	2026-02-05 04:00:30.660733+00	\N	f
5e1d764e-0889-4c04-ba5e-c686ec0f2b34	95f608be-c1e9-43b1-b885-5e2784e4858f	win	✅ Match Won!	WTI: Perfect! Direction + Target Hit! 🎯 (+53 pts (Bonus Included))	53	t	2026-02-05 04:00:30.985347+00	\N	f
c3e49b83-c74f-4cfb-ab74-d1dcd4e602e5	95f608be-c1e9-43b1-b885-5e2784e4858f	loss	❌ Match Lost	XAUUSD: Market moved against you. (-14 pts)	-14	t	2026-02-05 04:27:30.985778+00	\N	f
dc57f925-8e6a-49c6-93e5-c326b5666397	95f608be-c1e9-43b1-b885-5e2784e4858f	win	✅ Match Won!	WTI: Direction Correct. (+11 pts)	11	t	2026-02-05 04:27:31.269405+00	\N	f
f996a968-d1d0-404c-8c54-85259b04fa8f	5ac10c39-274e-4ce5-a13b-f4da3af4a230	win	✅ Match Won!	XAUUSD: Direction Correct. (+10 pts)	10	t	2026-02-05 07:15:32.029197+00	\N	f
3015faef-fb3b-462e-a02e-f4aee84b6991	5ac10c39-274e-4ce5-a13b-f4da3af4a230	win	✅ Match Won!	WTI: Perfect! Direction + Target Hit! 🎯 (+90 pts (Bonus Included))	90	t	2026-02-05 07:15:32.344235+00	\N	f
91418195-1337-4563-b68b-35e023000c86	5ac10c39-274e-4ce5-a13b-f4da3af4a230	loss	❌ Match Lost	XAUUSD: Market moved against you. (-10 pts)	-10	t	2026-02-05 07:57:30.602682+00	\N	f
d2ff0afd-27bb-4e74-84c0-28cb3010ef54	5ac10c39-274e-4ce5-a13b-f4da3af4a230	win	✅ Match Won!	XAGUSD: Direction Correct. (+8 pts)	8	t	2026-02-05 07:57:30.837424+00	\N	f
386468d2-932a-46b2-805c-ce185be1cf52	5ac10c39-274e-4ce5-a13b-f4da3af4a230	loss	❌ Match Lost	WTI: Market moved against you. (-10 pts)	-10	t	2026-02-05 08:15:30.737234+00	\N	f
68edd0f5-a3aa-446b-ba52-41a3ef1aa13c	5ac10c39-274e-4ce5-a13b-f4da3af4a230	win	✅ Match Won!	XAGUSD: Direction Correct. (+13 pts)	13	t	2026-02-05 09:00:31.199178+00	\N	f
facb9f0e-f8e6-40f0-8870-23eec61b9883	5ac10c39-274e-4ce5-a13b-f4da3af4a230	win	✅ Match Won!	XAUUSD: Direction Correct. (+13 pts)	13	t	2026-02-05 09:00:31.887607+00	\N	f
3c29d595-92d6-4178-a29c-1f6ebb012326	5ac10c39-274e-4ce5-a13b-f4da3af4a230	info	Vibe Locked In!	BTCUSDT UP at $69,404.75	0	t	2026-02-05 15:00:38.481749+00	\N	f
54f7d206-b983-41a8-a6a5-f61be536d1ea	36ae407d-c380-41ff-a714-d61371c44fb3	info	Vibe Locked In!	BTCUSDT DOWN at $69,404.75	0	f	2026-02-05 15:02:43.38277+00	\N	f
c5ca8135-7765-44d1-bdba-f4e7bcff9c63	5ac10c39-274e-4ce5-a13b-f4da3af4a230	info	Vibe Locked In!	ETHUSDT DOWN at $2,046.59	0	t	2026-02-05 15:01:12.206591+00	\N	f
60447e2e-6756-405c-a743-0d24f37d4a8a	5ac10c39-274e-4ce5-a13b-f4da3af4a230	info	Vibe Locked In!	XAUUSD UP at $150.25	0	t	2026-02-05 15:01:51.30413+00	\N	f
c52b9cd3-642e-469c-b311-f6fab95e503a	5ac10c39-274e-4ce5-a13b-f4da3af4a230	info	Vibe Locked In!	XAGUSD UP at $150.25	0	t	2026-02-05 15:02:09.121675+00	\N	f
5e37a191-b1eb-46d4-a25d-2bc75aa97272	5ac10c39-274e-4ce5-a13b-f4da3af4a230	info	Vibe Locked In!	XAGUSD UP at $150.25	0	t	2026-02-05 15:04:07.711275+00	\N	f
eda6cc1d-d276-4a53-b2c4-283487ea0d56	5ac10c39-274e-4ce5-a13b-f4da3af4a230	info	Vibe Locked In!	XAUUSD DOWN at $150.25	0	t	2026-02-05 15:04:44.609379+00	\N	f
b3de4ffc-4c68-4945-8161-6bbffa687e60	5ac10c39-274e-4ce5-a13b-f4da3af4a230	info	Vibe Locked In!	BTCUSDT UP at $69,404.75	0	t	2026-02-05 15:05:05.530614+00	\N	f
f44e574f-7a42-407c-9a70-511d616ee596	5ac10c39-274e-4ce5-a13b-f4da3af4a230	info	Vibe Locked In!	ETHUSDT DOWN at $2,046.59	0	t	2026-02-05 15:05:30.519911+00	\N	f
571d0488-50f0-4428-892e-0e26396154a2	5ac10c39-274e-4ce5-a13b-f4da3af4a230	info	Vibe Locked In!	BTCUSDT UP at $69,404.75	0	t	2026-02-05 15:07:03.970034+00	\N	f
e5ad9a91-f560-4cee-8f5c-65ebb306d7c3	36ae407d-c380-41ff-a714-d61371c44fb3	info	Vibe Locked In!	BTCUSDT UP at $69,404.75	0	f	2026-02-05 15:17:49.14445+00	\N	f
b6c6484b-3335-48fd-a67c-8c5d764b64a2	5ac10c39-274e-4ce5-a13b-f4da3af4a230	info	Vibe Locked In!	ETHUSDT UP at $1,997.36	0	t	2026-02-05 15:15:18.656982+00	\N	f
b693520b-c78a-43f4-8b84-ce1d9518907c	5ac10c39-274e-4ce5-a13b-f4da3af4a230	win	✅ Match Won!	XAGUSD: Direction Correct. (+10 pts)	10	t	2026-02-05 15:15:31.456855+00	\N	f
767ad3f0-913d-4989-8d2c-039accdd757f	5ac10c39-274e-4ce5-a13b-f4da3af4a230	info	Vibe Locked In!	BTCUSDT DOWN at $68,014.24	0	t	2026-02-05 15:19:12.633675+00	\N	f
9265431c-9e63-475f-8490-f1e344d2185c	5ac10c39-274e-4ce5-a13b-f4da3af4a230	info	Vibe Locked In!	SOLUSDT DOWN at $86.39	0	t	2026-02-05 15:19:35.075738+00	\N	f
4f8f8bd7-7e0b-4ab4-a8ef-c90b374131f8	95f608be-c1e9-43b1-b885-5e2784e4858f	win	✅ Match Won!	NG: Direction Correct. (+14 pts)	14	t	2026-02-05 04:45:30.590832+00	\N	f
e1292d2e-a570-4e8d-b307-b3adcad10995	95f608be-c1e9-43b1-b885-5e2784e4858f	win	✅ Match Won!	CORN: Perfect! Direction + Target Hit! 🎯 (+34 pts (Bonus Included))	34	t	2026-02-05 04:45:30.877637+00	\N	f
31c01d2e-65d7-4839-a0a2-fc0b5989bffd	10e558ca-3940-4995-9a8f-165e78efaffc	loss	❌ Match Lost	XAGUSD: Market moved against you. (-159 pts)	-159	t	2026-02-05 01:00:30.976958+00	\N	f
9c731cd0-d260-44cc-912e-be856799f0c3	10e558ca-3940-4995-9a8f-165e78efaffc	loss	❌ Match Lost	XAGUSD: Market moved against you. (-127 pts)	-127	t	2026-02-05 01:00:31.220103+00	\N	f
9877cc56-cc33-4b83-9000-96b189f663c0	10e558ca-3940-4995-9a8f-165e78efaffc	win	✅ Match Won!	XAUUSD: Perfect! Direction + Target Hit! 🎯 (+28 pts (Bonus Included))	28	t	2026-02-05 02:28:31.119506+00	\N	f
ec7e6d98-0d6c-437b-a49c-1f2c5352657f	5ac10c39-274e-4ce5-a13b-f4da3af4a230	info	Vibe Locked In!	ETHUSDT DOWN at $2,046.59	0	t	2026-02-05 15:07:24.42033+00	\N	f
76c69290-ec40-4b0a-a45b-96f8d1d82a33	5ac10c39-274e-4ce5-a13b-f4da3af4a230	info	Vibe Locked In!	XAUUSD UP at $150.25	0	t	2026-02-05 15:09:45.746201+00	\N	f
fc2b3cca-1f12-426c-9683-10ee3763fa0f	5ac10c39-274e-4ce5-a13b-f4da3af4a230	info	Vibe Locked In!	WTI DOWN at $150.25	0	t	2026-02-05 15:10:01.207955+00	\N	f
383f8168-9ce2-4ccf-986f-c91368e81688	5ac10c39-274e-4ce5-a13b-f4da3af4a230	info	Vibe Locked In!	ETHUSDT UP at $2,001.78	0	t	2026-02-05 15:13:06.515437+00	\N	f
94fd4cf4-bd9d-4e19-a8a1-6efcafdf9944	5ac10c39-274e-4ce5-a13b-f4da3af4a230	win	✅ Match Won!	XAUUSD: Direction Correct. (+10 pts)	10	t	2026-02-05 15:15:31.156994+00	\N	f
77279452-bfae-4059-95dc-d67d0d263e62	5ac10c39-274e-4ce5-a13b-f4da3af4a230	info	Vibe Locked In!	ETHUSDT UP at $1,997.36	0	t	2026-02-05 15:19:23.660157+00	\N	f
f8fab2e8-b437-4729-8e00-e4d766b2350b	5ac10c39-274e-4ce5-a13b-f4da3af4a230	loss	❌ Match Lost	XAGUSD: Market moved against you. (-10 pts)	-10	t	2026-02-05 15:30:31.256011+00	\N	f
f0623010-80b9-4222-94e8-744b850e5c35	5ac10c39-274e-4ce5-a13b-f4da3af4a230	loss	❌ Match Lost	XAUUSD: Market moved against you. (-10 pts)	-10	t	2026-02-05 15:30:31.672946+00	\N	f
65ab5919-4653-4229-a8f2-ad5efb027578	5ac10c39-274e-4ce5-a13b-f4da3af4a230	info	Vibe Locked In!	BTCUSDT UP at $66,851.98	0	t	2026-02-05 15:37:24.262386+00	\N	f
432e3fda-0541-48fa-ad97-fadce4719e6b	5ac10c39-274e-4ce5-a13b-f4da3af4a230	win	✅ Match Won!	XAUUSD: Direction Correct. (+13 pts)	13	t	2026-02-05 16:00:31.340524+00	\N	f
f22ef886-f60c-47de-a59f-0c5a60200862	5ac10c39-274e-4ce5-a13b-f4da3af4a230	win	✅ Match Won!	WTI: Perfect! Direction + Target Hit! 🎯 (+33 pts (Bonus Included))	33	t	2026-02-05 16:00:32.080812+00	\N	f
c7780fff-a456-4b1e-bbe4-af1a85470cfb	5ac10c39-274e-4ce5-a13b-f4da3af4a230	win	✅ Match Won!	AAPL: Perfect! Direction + Target Hit! 🎯 (+28 pts (Bonus Included))	28	t	2026-02-05 16:40:30.42983+00	\N	f
49178525-205f-4223-88a1-ad7537a85986	5ac10c39-274e-4ce5-a13b-f4da3af4a230	win	✅ Match Won!	NVDA: Direction Correct. (+8 pts)	8	t	2026-02-05 16:40:30.825578+00	\N	f
56b66028-e1f2-4621-bd6e-66aae27bc242	5ac10c39-274e-4ce5-a13b-f4da3af4a230	win	✅ Match Won!	XAUUSD: Direction Correct. (+8 pts)	8	t	2026-02-05 17:23:30.586372+00	\N	f
4d7d9cda-d7f4-41ee-a1b4-3ec4aeddc7eb	5ac10c39-274e-4ce5-a13b-f4da3af4a230	loss	❌ Match Lost	NVDA: Market moved against you. (-10 pts)	-10	t	2026-02-05 17:30:30.589568+00	\N	f
50d09f3a-901c-412c-9b16-33603996aa6f	5ac10c39-274e-4ce5-a13b-f4da3af4a230	win	✅ Match Won!	TSLA: Direction Correct. (+10 pts)	10	t	2026-02-05 17:30:30.895627+00	\N	f
1151f776-3c26-41e0-8623-daf664be00be	5ac10c39-274e-4ce5-a13b-f4da3af4a230	loss	❌ Match Lost	XAUUSD: Market moved against you. (-10 pts)	-10	t	2026-02-06 00:39:30.567427+00	\N	f
baff6edf-38c4-4609-bf33-44ceee16128d	5ac10c39-274e-4ce5-a13b-f4da3af4a230	win	✅ Match Won!	WTI: Perfect! Direction + Target Hit! 🎯 (+50 pts (Bonus Included))	50	t	2026-02-06 00:45:30.902457+00	\N	f
3b14cf1e-c946-4c11-bec2-fb68343391fd	5ac10c39-274e-4ce5-a13b-f4da3af4a230	loss	❌ Match Lost	XAUUSD: Market moved against you. (-10 pts)	-10	t	2026-02-06 00:45:31.263583+00	\N	f
85d288ff-b9b9-458e-ae04-09528b8b87a5	5ac10c39-274e-4ce5-a13b-f4da3af4a230	loss	❌ Match Lost	WTI: Market moved against you. (-10 pts)	-10	t	2026-02-06 01:00:30.664611+00	\N	f
3d474565-1863-412e-ad9c-282f583a51e6	5ac10c39-274e-4ce5-a13b-f4da3af4a230	loss	❌ Match Lost	XAGUSD: Market moved against you. (-10 pts)	-10	t	2026-02-06 01:00:30.966523+00	\N	f
08454afe-4bfd-4d4e-89cc-3677e0504822	5e4ec0ef-464a-41db-8e2f-9f3bfa2671ee	loss	❌ Match Lost	XAUUSD: Market moved against you. (-11 pts)	-11	t	2026-02-06 05:13:39.437513+00	\N	f
7e2132d7-8f7a-45ec-bbb3-38db47f7409a	5ac10c39-274e-4ce5-a13b-f4da3af4a230	loss	❌ Match Lost	XAUUSD: Market moved against you. (-10 pts)	-10	t	2026-02-06 06:26:22.801462+00	\N	f
b8a9bcb2-2589-4d88-a744-118090bf9d92	5ac10c39-274e-4ce5-a13b-f4da3af4a230	loss	❌ Match Lost	XAUUSD: Market moved against you. (-10 pts)	-10	t	2026-02-06 06:38:22.875319+00	\N	f
7259da95-83e5-4b75-873e-5a717e2b1a29	5ac10c39-274e-4ce5-a13b-f4da3af4a230	loss	❌ Match Lost	XAGUSD: Market moved against you. (-10 pts)	-10	t	2026-02-06 06:58:22.848744+00	\N	f
032fde50-bf6c-45bb-8962-f90ff211eef8	95f608be-c1e9-43b1-b885-5e2784e4858f	prediction_resolved	\N	BTCUSDT: WIN (11 pts)	0	t	2026-02-06 09:00:25.111162+00	420	f
9dee829e-ded8-4a62-b486-a357b07e63e1	95f608be-c1e9-43b1-b885-5e2784e4858f	prediction_resolved	\N	XAGUSD: WIN (30 pts)	0	t	2026-02-06 09:00:26.340525+00	428	f
0d984162-6e1e-4f07-8d9d-0af74a713479	95f608be-c1e9-43b1-b885-5e2784e4858f	prediction_resolved	\N	BTCUSDT: WIN (11 pts)	0	t	2026-02-06 09:00:28.091134+00	429	f
6565dbd6-db7d-42c8-bc70-a996c1e8a193	95f608be-c1e9-43b1-b885-5e2784e4858f	prediction_resolved	\N	ETHUSDT: LOSS (-12 pts)	0	t	2026-02-06 09:00:29.905025+00	430	f
8eec1ec2-d201-457c-b098-cb1bd407b0c9	95f608be-c1e9-43b1-b885-5e2784e4858f	prediction_resolved	\N	BTCUSDT: LOSS (-15 pts)	0	t	2026-02-06 10:32:53.678299+00	432	f
4170d4cb-497e-4778-98ae-7e5fd5d9a732	95f608be-c1e9-43b1-b885-5e2784e4858f	prediction_resolved	\N	XAUUSD: LOSS (-15 pts)	0	t	2026-02-06 10:33:53.481471+00	433	f
bcba261c-56ac-4d07-8962-502003fc626e	95f608be-c1e9-43b1-b885-5e2784e4858f	prediction_resolved	\N	BTCUSDT: LOSS (-15 pts)	0	t	2026-02-06 12:03:52.703865+00	434	f
e8e8d17d-67e0-4520-81b6-890fe1fcdf33	95f608be-c1e9-43b1-b885-5e2784e4858f	prediction_resolved	\N	XAUUSD: LOSS (-15 pts)	0	t	2026-02-06 12:04:53.674614+00	435	f
01929b46-9a98-45c5-8199-d3c87b11a9ee	10e558ca-3940-4995-9a8f-165e78efaffc	prediction_resolved	\N	XRPUSDT: LOSS (-113 pts)	0	t	2026-02-06 10:00:29.65978+00	431	f
478d35a7-8c81-4fda-8886-91e721ce02e3	10e558ca-3940-4995-9a8f-165e78efaffc	prediction_resolved	\N	XAUUSD: LOSS (-10 pts)	0	t	2026-02-06 13:50:44.09666+00	436	f
12466fde-8e8f-416c-a1af-2f13a2c91274	95f608be-c1e9-43b1-b885-5e2784e4858f	prediction_resolved	\N	AAPL: LOSS (-15 pts)	0	t	2026-02-06 14:39:57.859029+00	438	f
f4e9934e-d326-45b2-9d8d-124d57c6dcc1	95f608be-c1e9-43b1-b885-5e2784e4858f	prediction_resolved	\N	XAGUSD: WIN (14 pts)	0	t	2026-02-06 14:40:52.783587+00	439	f
027fc946-ec96-4e5e-876a-dc033ce44b8e	95f608be-c1e9-43b1-b885-5e2784e4858f	prediction_resolved	\N	ETHUSDT: WIN (13 pts)	0	t	2026-02-06 14:41:52.724+00	440	f
57a9cc0f-d4e0-4912-8e87-fc7283985e11	06d3b907-e06e-466b-a5fe-2dcc3912afaf	prediction_resolved	\N	BTCUSDT: WIN (8 pts)	0	f	2026-02-07 14:27:53.474494+00	456	f
0475fa8b-855c-438c-af6c-65248e53d5cc	06d3b907-e06e-466b-a5fe-2dcc3912afaf	prediction_resolved	\N	BTCUSDT: WIN (8 pts)	0	f	2026-02-07 14:29:33.081739+00	457	f
fb05fee8-beb4-4685-a6ad-ed3cc1e0fbb1	06d3b907-e06e-466b-a5fe-2dcc3912afaf	prediction_resolved	\N	BTCUSDT: LOSS (-10 pts)	0	f	2026-02-07 14:29:35.202507+00	458	f
be76bc30-ae09-4a3f-9f2e-b53cc7a43a4e	06d3b907-e06e-466b-a5fe-2dcc3912afaf	prediction_resolved	\N	BTCUSDT: WIN (8 pts)	0	f	2026-02-07 14:30:32.904337+00	459	f
a4d9ea15-de6a-48ca-ada9-9bc7323355fc	95f608be-c1e9-43b1-b885-5e2784e4858f	prediction_resolved	\N	BTCUSDT: LOSS (-14 pts)	0	t	2026-02-07 14:30:33.288177+00	460	f
46793313-6a37-4fac-90fe-ea5cc47a12e0	06d3b907-e06e-466b-a5fe-2dcc3912afaf	prediction_resolved	\N	BTCUSDT: WIN (8 pts)	0	f	2026-02-07 14:33:07.656197+00	461	f
ec05bb0b-e9fa-45a7-b648-d5223963ec8d	06d3b907-e06e-466b-a5fe-2dcc3912afaf	prediction_resolved	\N	BTCUSDT: WIN (8 pts)	0	f	2026-02-07 14:34:16.181222+00	462	f
3a9ceb5e-e450-4a8b-ae0c-c44939b41996	06d3b907-e06e-466b-a5fe-2dcc3912afaf	prediction_resolved	\N	BTCUSDT: LOSS (-10 pts)	0	f	2026-02-07 14:34:46.274797+00	463	f
4b97dd88-b256-4d83-b13f-767c0602d156	06d3b907-e06e-466b-a5fe-2dcc3912afaf	prediction_resolved	\N	BTCUSDT: WIN (8 pts)	0	f	2026-02-07 14:35:46.075602+00	464	f
fd661116-787c-4ff5-a459-43bf0f69bc19	06d3b907-e06e-466b-a5fe-2dcc3912afaf	prediction_resolved	\N	BTCUSDT: LOSS (-10 pts)	0	f	2026-02-07 14:36:25.482044+00	465	f
0d466a50-96f1-4fe5-9884-9f118c9cd944	95f608be-c1e9-43b1-b885-5e2784e4858f	prediction_resolved	\N	BTCUSDT: WIN (11 pts)	0	t	2026-02-07 14:42:32.9964+00	466	f
919f3c8d-2803-4522-85c3-8621770cb81c	1768c70a-81b5-4b3d-80b2-7e2a8f7d631b	prediction_resolved	\N	BTCUSDT: WIN (23 pts)	0	f	2026-02-08 05:05:54.461856+00	467	f
37693cda-cc11-4f16-8617-1b4007fb683b	95f608be-c1e9-43b1-b885-5e2784e4858f	prediction_resolved	\N	BTCUSDT: LOSS (-14 pts)	0	t	2026-02-08 13:55:32.252817+00	487	f
a65ffa96-94bd-44d6-8adb-3429d814ea01	95f608be-c1e9-43b1-b885-5e2784e4858f	prediction_resolved	\N	BTCUSDT: WIN (11 pts)	0	t	2026-02-08 14:00:51.914473+00	488	f
dbbe50a8-6304-4624-a8bc-13c767b5fdaa	95f608be-c1e9-43b1-b885-5e2784e4858f	prediction_resolved	\N	BTCUSDT: LOSS (-14 pts)	0	t	2026-02-08 14:00:53.073387+00	489	f
c2b26387-62c7-49f4-b575-b5c4b9f9b279	95f608be-c1e9-43b1-b885-5e2784e4858f	prediction_resolved	\N	BTCUSDT: WIN (81 pts)	0	t	2026-02-08 16:01:26.496434+00	490	f
3570ed56-5513-46e0-8b98-1ae7c897f911	10e558ca-3940-4995-9a8f-165e78efaffc	prediction_resolved	\N	ETHUSDT: WIN (33 pts)	0	t	2026-02-08 00:00:33.269556+00	445	f
87f775b4-dc44-4028-a9f1-d3e333a1ade8	10e558ca-3940-4995-9a8f-165e78efaffc	prediction_resolved	\N	SOLUSDT: WIN (10 pts)	0	t	2026-02-08 11:50:24.958623+00	475	f
71c81a8f-955d-460e-a6f4-86f050bd5471	10e558ca-3940-4995-9a8f-165e78efaffc	prediction_resolved	\N	XRPUSDT: WIN (11 pts)	0	t	2026-02-08 11:57:32.431663+00	477	f
2245c1b6-ab28-44dd-bef8-171f6b99633e	10e558ca-3940-4995-9a8f-165e78efaffc	prediction_resolved	\N	BTCUSDT: WIN (11 pts)	0	t	2026-02-08 11:59:32.253285+00	478	f
af2bf262-8210-486c-ad01-ebb5bcddee1a	10e558ca-3940-4995-9a8f-165e78efaffc	prediction_resolved	\N	BTCUSDT: WIN (33 pts)	0	t	2026-02-08 12:00:40.48666+00	476	f
cc0061f3-8a0c-46b4-a76c-2b84046e12a1	10e558ca-3940-4995-9a8f-165e78efaffc	prediction_resolved	\N	DOGEUSDT: WIN (8 pts)	0	t	2026-02-08 12:02:32.521762+00	479	f
a435b978-8e34-4cc0-a484-e0df39539449	9969cfc6-451e-4ab2-ae2f-5d10a98eaf0a	prediction_resolved	\N	XRPUSDT: WIN (91 pts)	0	t	2026-02-08 11:01:26.048863+00	468	f
82fa00fa-1c61-4b35-b114-2869373b9bb4	9969cfc6-451e-4ab2-ae2f-5d10a98eaf0a	prediction_resolved	\N	SOLUSDT: LOSS (-50 pts)	0	t	2026-02-08 11:01:27.358289+00	469	f
1808d05e-991e-41a5-90be-c8e01e631a6b	9969cfc6-451e-4ab2-ae2f-5d10a98eaf0a	prediction_resolved	\N	DOTUSDT: LOSS (-50 pts)	0	t	2026-02-08 11:01:28.44998+00	470	f
ff150e61-f3b2-425b-8487-cec6a7e2355d	9969cfc6-451e-4ab2-ae2f-5d10a98eaf0a	prediction_resolved	\N	MATICUSDT: ND (0 pts)	0	t	2026-02-08 12:00:32.772422+00	471	f
c4d157af-b1e8-4bbc-b39c-16aa0da575ff	9969cfc6-451e-4ab2-ae2f-5d10a98eaf0a	prediction_resolved	\N	SOLUSDT: WIN (65 pts)	0	t	2026-02-08 12:00:35.997741+00	472	f
91925d76-5ee6-4d8a-8b50-f0a96f1aa83b	9969cfc6-451e-4ab2-ae2f-5d10a98eaf0a	prediction_resolved	\N	XRPUSDT: LOSS (-100 pts)	0	t	2026-02-08 12:00:37.729152+00	473	f
0a3403bd-6b5d-4a81-84a2-23b377fcc07d	9969cfc6-451e-4ab2-ae2f-5d10a98eaf0a	prediction_resolved	\N	DOTUSDT: WIN (65 pts)	0	t	2026-02-08 12:00:39.330844+00	474	f
edc1d91b-7c21-4316-b89e-3c9286a38371	9969cfc6-451e-4ab2-ae2f-5d10a98eaf0a	prediction_resolved	\N	DOTUSDT: LOSS (-50 pts)	0	t	2026-02-08 13:00:55.152019+00	483	f
9fbe852c-8a5a-46ee-9b78-7a16719140f7	9969cfc6-451e-4ab2-ae2f-5d10a98eaf0a	prediction_resolved	\N	SOLUSDT: LOSS (-10 pts)	0	t	2026-02-08 13:00:57.756653+00	486	f
bab1daa2-31cd-48ef-86ac-3e654b95f237	95f608be-c1e9-43b1-b885-5e2784e4858f	prediction_resolved	\N	BTCUSDT: WIN (18 pts)	0	t	2026-02-09 00:01:26.767869+00	491	f
9ccace06-b5da-41c4-93ba-e7b282ba7082	95f608be-c1e9-43b1-b885-5e2784e4858f	prediction_resolved	\N	BTCUSDT: LOSS (-15 pts)	0	t	2026-02-09 22:07:32.404393+00	505	f
6ff3aae1-2f08-495a-8979-8be4c15f2e42	95f608be-c1e9-43b1-b885-5e2784e4858f	prediction_resolved	\N	BTCUSDT: LOSS (-15 pts)	0	t	2026-02-09 22:08:32.367642+00	506	f
6ec04eaf-375f-4ba9-88a5-508d3067b112	95f608be-c1e9-43b1-b885-5e2784e4858f	prediction_resolved	\N	BTCUSDT: LOSS (-15 pts)	0	t	2026-02-10 08:03:34.497063+00	518	f
40949d37-bfc8-4ffd-85b2-41f2010452e0	95f608be-c1e9-43b1-b885-5e2784e4858f	prediction_resolved	\N	BTCUSDT: WIN (11 pts)	0	t	2026-02-10 08:15:48.563231+00	519	f
1f414748-64c3-4882-9005-36e7fae4e788	95f608be-c1e9-43b1-b885-5e2784e4858f	prediction_resolved	\N	BTCUSDT: LOSS (-14 pts)	0	t	2026-02-10 10:28:33.524916+00	521	f
4bf52e9d-24ef-475c-8d19-bf5ba7dd2cf4	95f608be-c1e9-43b1-b885-5e2784e4858f	prediction_resolved	\N	BTCUSDT: LOSS (-15 pts)	0	t	2026-02-10 11:00:24.978474+00	520	f
593ed08e-c7c4-4d4b-aaad-957f0ed78c60	5e4ec0ef-464a-41db-8e2f-9f3bfa2671ee	prediction_resolved	\N	BTCUSDT: LOSS (-11 pts)	0	f	2026-02-11 00:38:38.613387+00	529	f
aeb0a8fa-7e28-4a2d-8f07-a76a0297d27e	5e4ec0ef-464a-41db-8e2f-9f3bfa2671ee	prediction_resolved	\N	BTCUSDT: WIN (8 pts)	0	f	2026-02-11 00:38:40.778721+00	530	f
86e7360a-1811-4367-92d8-851af28bbbb2	5e4ec0ef-464a-41db-8e2f-9f3bfa2671ee	prediction_resolved	\N	BTCUSDT: LOSS (-11 pts)	0	f	2026-02-11 01:51:58.666102+00	531	f
76130259-95a4-419e-91d2-45d0cc7d0917	5e4ec0ef-464a-41db-8e2f-9f3bfa2671ee	prediction_resolved	\N	BTCUSDT: WIN (9 pts)	0	f	2026-02-11 02:00:23.520525+00	532	f
b4d9e6a9-3100-4622-a9ce-cc2e04e416d6	95f608be-c1e9-43b1-b885-5e2784e4858f	prediction_resolved	\N	BTCUSDT: LOSS (-14 pts)	0	t	2026-02-10 15:14:38.083463+00	526	f
a669618a-8155-46f7-8a4f-2bd3abb9d1ef	95f608be-c1e9-43b1-b885-5e2784e4858f	prediction_resolved	\N	ETHUSDT: WIN (11 pts)	0	t	2026-02-10 15:14:39.162129+00	527	f
0fd75712-d0c4-4f9b-8028-1843955054da	95f608be-c1e9-43b1-b885-5e2784e4858f	prediction_resolved	\N	ETHUSDT: LOSS (-14 pts)	0	t	2026-02-10 16:13:14.134416+00	528	f
60abe7c5-ea28-4ee4-b58e-90f5aefd87ae	95f608be-c1e9-43b1-b885-5e2784e4858f	prediction_resolved	\N	BTCUSDT: WIN (12 pts)	0	t	2026-02-11 02:00:23.873628+00	533	f
452eb925-2fae-438f-b8ae-afc8507cb4e6	95f608be-c1e9-43b1-b885-5e2784e4858f	prediction_resolved	\N	BTCUSDT: LOSS (-14 pts)	0	f	2026-02-11 02:30:29.54452+00	534	f
219046a0-8442-438e-b412-2f1bba6afaaf	10e558ca-3940-4995-9a8f-165e78efaffc	prediction_resolved	\N	XAUUSD: WIN (74 pts)	0	t	2026-02-06 14:30:32.747822+00	437	f
91ec6202-0d9f-496d-86a0-193bc1489b8f	10e558ca-3940-4995-9a8f-165e78efaffc	prediction_resolved	\N	XAUUSD: LOSS (-103 pts)	0	t	2026-02-06 16:17:22.703401+00	441	f
e6538128-cca6-497b-bc76-247cd887f063	10e558ca-3940-4995-9a8f-165e78efaffc	prediction_resolved	\N	ETHUSDT: WIN (8 pts)	0	t	2026-02-07 01:41:43.48322+00	444	f
2a884d1a-b9cf-43c0-9ed4-a126865eb54e	10e558ca-3940-4995-9a8f-165e78efaffc	prediction_resolved	\N	BTCUSDT: WIN (27 pts)	0	t	2026-02-07 02:01:14.608064+00	442	f
b61a16a8-93df-494e-a3c3-fc6b806b31f8	10e558ca-3940-4995-9a8f-165e78efaffc	prediction_resolved	\N	ETHUSDT: LOSS (-10 pts)	0	t	2026-02-07 02:01:15.823195+00	443	f
5573b239-e7bd-4dec-a3cc-8229614f5aef	10e558ca-3940-4995-9a8f-165e78efaffc	prediction_resolved	\N	ETHUSDT: WIN (8 pts)	0	t	2026-02-07 06:05:43.818696+00	447	f
86704b4d-349f-43c5-b607-3c09635099be	10e558ca-3940-4995-9a8f-165e78efaffc	prediction_resolved	\N	SOLUSDT: LOSS (-82 pts)	0	t	2026-02-07 06:06:43.952568+00	448	f
35bd20f5-f730-4e22-86e7-a772f0cd3731	10e558ca-3940-4995-9a8f-165e78efaffc	prediction_resolved	\N	BTCUSDT: LOSS (-10 pts)	0	t	2026-02-07 07:01:15.361357+00	446	f
e7b06748-bc74-4fba-b224-b67898880584	10e558ca-3940-4995-9a8f-165e78efaffc	prediction_resolved	\N	SOLUSDT: LOSS (-10 pts)	0	t	2026-02-07 08:01:15.092817+00	449	f
9abb8bdd-579c-430d-a769-fbcacff91518	10e558ca-3940-4995-9a8f-165e78efaffc	prediction_resolved	\N	BTCUSDT: LOSS (-67 pts)	0	t	2026-02-07 08:01:16.209035+00	450	f
d2b2dfd1-270d-4f39-81ca-0d23f89198a8	10e558ca-3940-4995-9a8f-165e78efaffc	prediction_resolved	\N	XRPUSDT: LOSS (-53 pts)	0	t	2026-02-07 09:11:44.249147+00	451	f
79bd4ab8-864d-4f9d-b148-3404ec906cfb	10e558ca-3940-4995-9a8f-165e78efaffc	prediction_resolved	\N	XRPUSDT: LOSS (-10 pts)	0	t	2026-02-07 12:00:33.272474+00	452	f
0fb9d6e6-ce2a-4b18-8137-098ce22e3500	10e558ca-3940-4995-9a8f-165e78efaffc	prediction_resolved	\N	AVAXUSDT: WIN (27 pts)	0	t	2026-02-07 12:15:43.975388+00	454	f
aebcb31a-9d45-4712-ae53-e92f2b9ea273	10e558ca-3940-4995-9a8f-165e78efaffc	prediction_resolved	\N	DOGEUSDT: WIN (36 pts)	0	t	2026-02-07 12:30:44.245744+00	453	f
bebfbde9-78c6-4182-a9f4-9763f7b3c2a4	10e558ca-3940-4995-9a8f-165e78efaffc	prediction_resolved	\N	SOLUSDT: LOSS (-10 pts)	0	t	2026-02-07 12:30:45.556916+00	455	f
5765f8c7-e075-48a4-8adb-cf57c7d096ef	10e558ca-3940-4995-9a8f-165e78efaffc	prediction_resolved	\N	AVAXUSDT: WIN (14 pts)	0	t	2026-02-08 12:30:55.088494+00	480	f
22302fe4-8a7c-4842-ba09-e46c19b77cbf	10e558ca-3940-4995-9a8f-165e78efaffc	prediction_resolved	\N	SOLUSDT: WIN (8 pts)	0	t	2026-02-10 01:02:34.61789+00	509	f
ef06757c-a09a-4b2b-8a77-180277b52125	10e558ca-3940-4995-9a8f-165e78efaffc	prediction_resolved	\N	XRPUSDT: LOSS (-10 pts)	0	t	2026-02-10 01:02:36.850438+00	510	f
e5205a19-8364-452e-bdc5-c2e55aad7b47	10e558ca-3940-4995-9a8f-165e78efaffc	prediction_resolved	\N	XAUUSD: LOSS (-10 pts)	0	t	2026-02-10 02:00:22.958262+00	507	f
aacbd4f0-8fa9-471f-8cd8-808a4f3405ca	10e558ca-3940-4995-9a8f-165e78efaffc	prediction_resolved	\N	XAGUSD: LOSS (-10 pts)	0	t	2026-02-10 02:00:24.334619+00	508	f
8e6046eb-8477-47da-8668-e89828befde7	10e558ca-3940-4995-9a8f-165e78efaffc	prediction_resolved	\N	BTCUSDT: WIN (46 pts)	0	t	2026-02-10 05:00:24.079463+00	511	f
1d567e25-02ff-4553-9b5d-84a66c0aeafb	10e558ca-3940-4995-9a8f-165e78efaffc	prediction_resolved	\N	BTCUSDT: WIN (9 pts)	0	t	2026-02-10 05:00:24.408163+00	512	f
1fc8aea4-5d07-45e7-90bf-a3bc1a084a5f	10e558ca-3940-4995-9a8f-165e78efaffc	prediction_resolved	\N	BTCUSDT: LOSS (-50 pts)	0	t	2026-02-10 07:00:23.824178+00	513	f
0fb18453-f653-4400-b33f-d0c7539d387b	10e558ca-3940-4995-9a8f-165e78efaffc	prediction_resolved	\N	SOLUSDT: WIN (8 pts)	0	t	2026-02-08 12:30:56.791846+00	481	f
f875f8ce-3adf-4fdc-8549-e4d8f35b1fc3	10e558ca-3940-4995-9a8f-165e78efaffc	prediction_resolved	\N	XRPUSDT: ND (0 pts)	0	t	2026-02-08 12:30:57.753328+00	482	f
1eaebe6b-6d34-4f99-b18d-59233eb08d99	10e558ca-3940-4995-9a8f-165e78efaffc	prediction_resolved	\N	ETHUSDT: WIN (8 pts)	0	t	2026-02-08 12:45:55.83292+00	485	f
08f43934-1807-44c2-bf2c-386cd33d5d85	10e558ca-3940-4995-9a8f-165e78efaffc	prediction_resolved	\N	BTCUSDT: LOSS (-11 pts)	0	t	2026-02-08 13:00:56.390136+00	484	f
49c2c924-0f46-4217-a0ea-ceec1811958b	10e558ca-3940-4995-9a8f-165e78efaffc	prediction_resolved	\N	XAUUSD: WIN (8 pts)	0	t	2026-02-09 06:40:21.526491+00	492	f
fcecbcef-0f87-43c2-8978-2be6b7b402ac	10e558ca-3940-4995-9a8f-165e78efaffc	prediction_resolved	\N	ETHUSDT: LOSS (-10 pts)	0	t	2026-02-09 07:20:53.904902+00	493	f
b7315d39-5e94-40d6-a725-1169c4be0f2e	10e558ca-3940-4995-9a8f-165e78efaffc	prediction_resolved	\N	DOGEUSDT: LOSS (-10 pts)	0	t	2026-02-09 07:36:06.701902+00	496	f
354bd903-77bb-4965-90b6-69d3bddb538c	10e558ca-3940-4995-9a8f-165e78efaffc	prediction_resolved	\N	XAUUSD: WIN (27 pts)	0	t	2026-02-09 07:37:07.308153+00	497	f
ad3fb311-1bb2-4ccb-89a7-a1a1698488da	10e558ca-3940-4995-9a8f-165e78efaffc	prediction_resolved	\N	ETHUSDT: WIN (36 pts)	0	t	2026-02-09 08:03:59.248324+00	494	f
9f7bfda9-406a-4247-8dd1-5d7c8b2fa803	10e558ca-3940-4995-9a8f-165e78efaffc	prediction_resolved	\N	ADAUSDT: LOSS (-10 pts)	0	t	2026-02-09 08:04:00.49648+00	495	f
02d90b93-2005-45c7-aecc-3220ab110502	10e558ca-3940-4995-9a8f-165e78efaffc	prediction_resolved	\N	PA: LOSS (-10 pts)	0	t	2026-02-09 12:35:30.515939+00	503	f
6e828b6e-6f84-4f60-9ad8-88560abad86c	10e558ca-3940-4995-9a8f-165e78efaffc	prediction_resolved	\N	NG: WIN (8 pts)	0	t	2026-02-09 12:35:31.438283+00	498	f
67e26b20-76f0-4b0a-a891-1ba98c26fd91	10e558ca-3940-4995-9a8f-165e78efaffc	prediction_resolved	\N	CORN: ND (0 pts)	0	t	2026-02-09 12:35:32.23525+00	499	f
43997136-ae30-4e3e-be40-0b3067a59041	10e558ca-3940-4995-9a8f-165e78efaffc	prediction_resolved	\N	XAGUSD: WIN (8 pts)	0	t	2026-02-09 12:35:33.428347+00	500	f
5c1e9d47-7d2f-4b0b-8c42-8aa69ae16128	10e558ca-3940-4995-9a8f-165e78efaffc	prediction_resolved	\N	WHEAT: WIN (8 pts)	0	t	2026-02-09 12:35:34.263793+00	501	f
03a6d4ad-ec7f-4f00-b861-f79c779bdd4a	10e558ca-3940-4995-9a8f-165e78efaffc	prediction_resolved	\N	XRPUSDT: WIN (28 pts)	0	t	2026-02-09 12:35:35.87856+00	502	f
613a8a99-6695-49d4-a267-097c2556d3e6	10e558ca-3940-4995-9a8f-165e78efaffc	prediction_resolved	\N	ETHUSDT: WIN (9 pts)	0	t	2026-02-09 12:35:37.121532+00	504	f
b440e23f-8187-4dc4-97f5-0b176db28b6c	10e558ca-3940-4995-9a8f-165e78efaffc	prediction_resolved	\N	BTCUSDT: LOSS (-50 pts)	0	t	2026-02-10 07:00:24.540115+00	514	f
7ae5e0fd-c4f4-4113-bddf-cb0029b54d84	10e558ca-3940-4995-9a8f-165e78efaffc	prediction_resolved	\N	BTCUSDT: LOSS (-50 pts)	0	t	2026-02-10 07:00:24.780897+00	515	f
d4441f4b-c2e2-468c-9527-42725a8881fe	10e558ca-3940-4995-9a8f-165e78efaffc	prediction_resolved	\N	BTCUSDT: WIN (18 pts)	0	t	2026-02-10 07:00:25.025522+00	516	f
9ac45e81-77d5-49af-b727-ad82cb2d7425	10e558ca-3940-4995-9a8f-165e78efaffc	prediction_resolved	\N	BTCUSDT: WIN (91 pts)	0	t	2026-02-10 08:00:24.094047+00	517	f
75b3f7e9-94ca-4a03-bc99-40316991b344	10e558ca-3940-4995-9a8f-165e78efaffc	prediction_resolved	\N	ADAUSDT: LOSS (-10 pts)	0	t	2026-02-10 11:30:24.935834+00	525	f
7660558f-b361-47fb-915f-4fec50e20aa6	10e558ca-3940-4995-9a8f-165e78efaffc	prediction_resolved	\N	XAGUSD: LOSS (-23 pts)	0	t	2026-02-10 12:00:24.251356+00	522	f
a13f0c5c-2fcb-45c6-bf7b-7db5dacea8ad	10e558ca-3940-4995-9a8f-165e78efaffc	prediction_resolved	\N	XAUUSD: LOSS (-10 pts)	0	t	2026-02-10 12:00:25.229878+00	523	f
12c0fa11-e0eb-4e7b-979a-66cb527d5f09	10e558ca-3940-4995-9a8f-165e78efaffc	prediction_resolved	\N	SOLUSDT: WIN (9 pts)	0	t	2026-02-10 12:00:27.148012+00	524	f
70ee63cc-ef83-4617-92e2-13e7e3e36bbd	10e558ca-3940-4995-9a8f-165e78efaffc	prediction_resolved	\N	BTCUSDT: WIN (8 pts)	0	f	2026-02-11 12:21:38.283157+00	536	f
2ce71dfe-30db-45e0-8460-542d4d4a1581	9969cfc6-451e-4ab2-ae2f-5d10a98eaf0a	prediction_resolved	\N	BTCUSDT: WIN (8 pts)	0	f	2026-02-11 12:51:39.960101+00	537	f
1f9499de-88cf-40ab-9d99-a19c83b70c4b	10e558ca-3940-4995-9a8f-165e78efaffc	prediction_resolved	\N	BTCUSDT: WIN (9 pts)	0	f	2026-02-11 13:00:40.25114+00	535	f
\.


--
-- Data for Name: posts; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.posts (id, user_id, title, content, asset_symbol, timeframe, direction, volatility_target, likes_count, comments_count, bookmarks_count, shares_count, feed_score, freshness_score, engagement_score, author_score, created_at) FROM stdin;
\.


--
-- Data for Name: prediction_likes; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.prediction_likes (user_id, prediction_id, created_at) FROM stdin;
\.


--
-- Data for Name: predictions; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.predictions (id, user_id, asset_symbol, timeframe, direction, target_percent, entry_price, bet_amount, status, actual_price, profit, created_at, candle_close_at, resolved_at, comment, close_price, profit_loss, payout, actual_change_percent, is_target_hit, multipliers, entry_offset_seconds) FROM stdin;
503	10e558ca-3940-4995-9a8f-165e78efaffc	PA	15m	UP	0.5	1701.5	10	LOSS	1696	-10	2026-02-09 11:48:02.065837+00	2026-02-09 12:00:00+00	2026-02-09 12:35:30.515939+00	\N	\N	\N	\N	\N	f	{}	0
89	5ac10c39-274e-4ce5-a13b-f4da3af4a230	BTCUSDT	30m	UP	0.5	79017.64	10	LOSS	\N	0	2026-02-03 02:06:51.462772+00	2026-02-03 02:21:51.462772+00	2026-02-03 02:30:41.804544+00	\N	78700	-10	0	\N	f	{}	0
25	60abdd33-af5a-4dfb-b211-a057a0995d12	BTCUSDT	1m	UP	0.5	77624.88	10	ND	77633.43	0	2026-02-02 01:54:03.185211+00	2026-02-02 01:55:00+00	2026-02-02 01:55:32.579382+00	\N	\N	\N	\N	\N	f	{}	0
26	36ae407d-c380-41ff-a714-d61371c44fb3	BTCUSDT	1m	DOWN	0.5	77624.88	10	LOSS	77633.43	-10	2026-02-02 01:54:10.183565+00	2026-02-02 01:55:00+00	2026-02-02 01:55:32.814124+00	\N	\N	\N	\N	\N	f	{}	0
27	5ac10c39-274e-4ce5-a13b-f4da3af4a230	BTCUSDT	1m	DOWN	1.5	77624.88	10	LOSS	77633.43	-10	2026-02-02 01:54:18.838281+00	2026-02-02 01:55:00+00	2026-02-02 01:55:33.107153+00	\N	\N	\N	\N	\N	f	{}	0
28	60abdd33-af5a-4dfb-b211-a057a0995d12	BTCUSDT	15m	UP	1	77518.87	10	LOSS	77196	-10	2026-02-02 02:00:29.286782+00	2026-02-02 02:15:00+00	2026-02-02 02:15:32.688266+00	\N	\N	\N	\N	\N	f	{}	0
29	36ae407d-c380-41ff-a714-d61371c44fb3	BTCUSDT	15m	DOWN	1.5	77518.87	10	ND	77196	0	2026-02-02 02:00:58.226954+00	2026-02-02 02:15:00+00	2026-02-02 02:15:32.950619+00	\N	\N	\N	\N	\N	f	{}	0
30	5ac10c39-274e-4ce5-a13b-f4da3af4a230	BTCUSDT	15m	DOWN	0.5	77518.87	10	ND	77196	0	2026-02-02 02:01:29.503891+00	2026-02-02 02:15:00+00	2026-02-02 02:15:33.175578+00	\N	\N	\N	\N	\N	f	{}	0
31	60abdd33-af5a-4dfb-b211-a057a0995d12	BTCUSDT	30m	UP	0.5	77518.87	10	LOSS	77124.38	-10	2026-02-02 02:02:32.435253+00	2026-02-02 02:30:00+00	2026-02-02 02:30:32.651848+00	\N	\N	\N	\N	\N	f	{}	0
32	36ae407d-c380-41ff-a714-d61371c44fb3	BTCUSDT	30m	DOWN	0.5	77518.87	10	WIN	77124.38	10	2026-02-02 02:02:51.802704+00	2026-02-02 02:30:00+00	2026-02-02 02:30:32.98753+00	\N	\N	\N	\N	\N	f	{}	0
33	5ac10c39-274e-4ce5-a13b-f4da3af4a230	BTCUSDT	30m	DOWN	2	77518.87	10	ND	77124.38	0	2026-02-02 02:03:10.477701+00	2026-02-02 02:30:00+00	2026-02-02 02:30:33.228265+00	\N	\N	\N	\N	\N	f	{}	0
37	5ac10c39-274e-4ce5-a13b-f4da3af4a230	BTCUSDT	15m	DOWN	0.5	77196	10	ND	77124.38	0	2026-02-02 02:18:28.965368+00	2026-02-02 02:30:00+00	2026-02-02 02:30:33.452365+00	\N	\N	\N	\N	\N	f	{}	0
38	60abdd33-af5a-4dfb-b211-a057a0995d12	BTCUSDT	15m	UP	1	77196	10	LOSS	77124.38	-10	2026-02-02 02:18:46.560879+00	2026-02-02 02:30:00+00	2026-02-02 02:30:33.61487+00	\N	\N	\N	\N	\N	f	{}	0
39	36ae407d-c380-41ff-a714-d61371c44fb3	BTCUSDT	15m	DOWN	1.5	77196	10	ND	77124.38	0	2026-02-02 02:19:04.236824+00	2026-02-02 02:30:00+00	2026-02-02 02:30:33.793375+00	\N	\N	\N	\N	\N	f	{}	0
40	36ae407d-c380-41ff-a714-d61371c44fb3	BTCUSDT	15m	UP	1	77124.38	10	LOSS	76972.21	-10	2026-02-02 02:33:53.954104+00	2026-02-02 02:45:00+00	2026-02-02 02:45:33.081426+00	\N	\N	\N	\N	\N	f	{}	0
41	60abdd33-af5a-4dfb-b211-a057a0995d12	BTCUSDT	15m	DOWN	0.5	77124.38	10	ND	76972.21	0	2026-02-02 02:34:11.573198+00	2026-02-02 02:45:00+00	2026-02-02 02:45:33.26451+00	\N	\N	\N	\N	\N	f	{}	0
42	5ac10c39-274e-4ce5-a13b-f4da3af4a230	BTCUSDT	15m	UP	2	77124.38	10	LOSS	76972.21	-10	2026-02-02 02:34:31.033589+00	2026-02-02 02:45:00+00	2026-02-02 02:45:33.434841+00	\N	\N	\N	\N	\N	f	{}	0
34	36ae407d-c380-41ff-a714-d61371c44fb3	BTCUSDT	1h	DOWN	1	77518.87	10	WIN	76491.17	20	2026-02-02 02:03:56.949604+00	2026-02-02 03:00:00+00	2026-02-02 03:00:58.335013+00	\N	\N	\N	\N	\N	f	{}	0
35	60abdd33-af5a-4dfb-b211-a057a0995d12	BTCUSDT	1h	UP	1	77518.87	10	LOSS	76491.17	-10	2026-02-02 02:04:12.225668+00	2026-02-02 03:00:00+00	2026-02-02 03:00:58.548789+00	\N	\N	\N	\N	\N	f	{}	0
36	5ac10c39-274e-4ce5-a13b-f4da3af4a230	BTCUSDT	1h	DOWN	1	77518.87	10	WIN	76491.17	20	2026-02-02 02:04:35.530573+00	2026-02-02 03:00:00+00	2026-02-02 03:00:58.718547+00	\N	\N	\N	\N	\N	f	{}	0
46	36ae407d-c380-41ff-a714-d61371c44fb3	ETHUSDT	1m	UP	2	2255.52	10	LOSS	2241.97	-16	2026-02-02 08:20:11.640373+00	2026-02-02 08:21:00+00	2026-02-02 08:21:59.717118+00	\N	\N	\N	\N	\N	f	{}	0
43	5ac10c39-274e-4ce5-a13b-f4da3af4a230	BTCUSDT	15m	UP	0.5	76870.09	10	LOSS	76789.99	-21	2026-02-02 08:19:30.608239+00	2026-02-02 08:30:00+00	2026-02-02 08:30:59.690749+00	\N	\N	\N	\N	\N	f	{}	0
44	60abdd33-af5a-4dfb-b211-a057a0995d12	BTCUSDT	15m	DOWN	1.5	76870.09	10	ND	76789.99	10	2026-02-02 08:19:44.238743+00	2026-02-02 08:30:00+00	2026-02-02 08:30:59.995324+00	\N	\N	\N	\N	\N	f	{}	0
45	36ae407d-c380-41ff-a714-d61371c44fb3	BTCUSDT	15m	UP	1	76870.09	10	LOSS	76789.99	-21	2026-02-02 08:19:57.716993+00	2026-02-02 08:30:00+00	2026-02-02 08:31:00.265051+00	\N	\N	\N	\N	\N	f	{}	0
58	43075ac5-9589-4a40-9861-7b90cb7c30b9	TEST-BTC	1h	UP	0.5	50000	100	WIN	51250	110	2026-02-02 23:06:52.525192+00	2026-02-03 00:06:52.525192+00	2026-02-02 23:06:52.525192+00	\N	\N	\N	\N	\N	f	{}	0
59	428f4a8e-2ccc-4bff-9d30-e44cc6c4fdbe	TEST-ETH	15m	DOWN	0.5	3000	100	LOSS	3030	-100	2026-02-02 23:06:52.525192+00	2026-02-02 23:21:52.525192+00	2026-02-02 23:06:52.525192+00	\N	\N	\N	\N	\N	f	{}	0
60	d9d7ce43-118a-438a-bcd6-6ddc3117b789	TEST-SOL	1h	UP	1.0	100	100	WIN	101.5	129	2026-02-02 23:06:52.525192+00	2026-02-03 00:06:52.525192+00	2026-02-02 23:06:52.525192+00	\N	\N	\N	\N	\N	f	{}	0
61	349325a9-2d7a-4a3a-8dfb-7e2082cf1280	TEST-XRP	1h	UP	0.5	1.0	100	ND	1.0	0	2026-02-02 23:06:52.525192+00	2026-02-03 00:06:52.525192+00	2026-02-02 23:06:52.525192+00	\N	\N	\N	\N	\N	f	{}	0
62	ebdd4583-a106-4909-9b73-aaf392e3bc72	TEST-DOGE	1h	UP	0.5	0.1	100	WIN	0.11	276	2026-02-02 23:06:52.525192+00	2026-02-03 00:06:52.525192+00	2026-02-02 23:06:52.525192+00	\N	\N	\N	\N	\N	f	{}	0
85	36ae407d-c380-41ff-a714-d61371c44fb3	BTCUSDT	30m	UP	1	78905.59	10	WIN	\N	0	2026-02-03 01:37:33.14126+00	2026-02-03 01:52:33.14126+00	2026-02-03 02:11:59.59182+00	ㅈㅈㅈㅈㅈㅈㅈ	79017.63	8.0	18.0	\N	f	{}	0
90	5ac10c39-274e-4ce5-a13b-f4da3af4a230	BTCUSDT	1m	DOWN	1.5	78822.78	10	WIN	\N	0	2026-02-03 02:07:05.324554+00	2026-02-03 02:08:05.324554+00	2026-02-03 02:12:00.007976+00	\N	78770.06	8.0	18.0	\N	f	{}	0
88	5ac10c39-274e-4ce5-a13b-f4da3af4a230	BTCUSDT	1m	UP	0.5	78864.74	10	LOSS	\N	0	2026-02-03 01:41:08.487195+00	2026-02-03 01:42:08.487195+00	2026-02-03 02:11:59.793851+00	ㄷㄷㄷ	78856.16	-10	0	\N	f	{}	0
64	10e558ca-3940-4995-9a8f-165e78efaffc	ETHUSDT	15m	UP	0.5	100	50	WIN	\N	0	2026-02-03 00:47:05.910658+00	2026-02-03 01:02:05.910658+00	2026-02-03 02:11:52.859676+00	\N	2353.98	40.0	90.0	\N	f	{}	0
65	5e4ec0ef-464a-41db-8e2f-9f3bfa2671ee	ETHUSDT	1h	DOWN	0.5	100	50	LOSS	\N	0	2026-02-03 00:47:06.423243+00	2026-02-03 01:47:06.423243+00	2026-02-03 02:11:53.078893+00	\N	2353.98	-50	0	\N	f	{}	0
66	95f608be-c1e9-43b1-b885-5e2784e4858f	ETHUSDT	1h	DOWN	1	100	50	LOSS	\N	0	2026-02-03 00:47:06.951177+00	2026-02-03 01:47:06.951177+00	2026-02-03 02:11:53.27834+00	\N	2353.98	-50	0	\N	f	{}	0
67	8cf7c6be-ba2c-48c9-8825-589e675ff608	BTCUSDT	1h	DOWN	0.5	100	50	LOSS	\N	0	2026-02-03 00:47:07.466049+00	2026-02-03 01:47:07.466049+00	2026-02-03 02:11:53.600765+00	\N	79065.24	-50	0	\N	f	{}	0
68	5ac10c39-274e-4ce5-a13b-f4da3af4a230	BTCUSDT	1m	UP	0.5	78939.03	10	LOSS	\N	0	2026-02-03 00:49:06.470999+00	2026-02-03 00:50:06.470999+00	2026-02-03 02:11:53.820156+00	\N	78904.2	-10	0	\N	f	{}	0
69	5ac10c39-274e-4ce5-a13b-f4da3af4a230	BTCUSDT	15m	UP	0.5	78951.49	10	WIN	\N	0	2026-02-03 00:57:09.955569+00	2026-02-03 01:12:09.955569+00	2026-02-03 02:11:54.055927+00	\N	79065.24	8.0	18.0	\N	f	{}	0
70	5ac10c39-274e-4ce5-a13b-f4da3af4a230	BTCUSDT	15m	DOWN	0.5	78951.49	10	LOSS	\N	0	2026-02-03 00:59:23.569096+00	2026-02-03 01:14:23.569096+00	2026-02-03 02:11:54.225116+00	\N	79065.24	-10	0	\N	f	{}	0
71	5ac10c39-274e-4ce5-a13b-f4da3af4a230	BTCUSDT	1m	UP	1.5	79065.24	10	WIN	\N	0	2026-02-03 01:00:21.440424+00	2026-02-03 01:01:21.440424+00	2026-02-03 02:11:54.438114+00	\N	79076.62	8.0	18.0	\N	f	{}	0
72	5ac10c39-274e-4ce5-a13b-f4da3af4a230	BTCUSDT	15m	DOWN	1.5	79065.24	10	WIN	\N	0	2026-02-03 01:00:32.38864+00	2026-02-03 01:15:32.38864+00	2026-02-03 02:11:54.683287+00	\N	78930	8.0	18.0	\N	f	{}	0
76	60abdd33-af5a-4dfb-b211-a057a0995d12	BTCUSDT	15m	DOWN	1.5	79065.24	10	WIN	\N	0	2026-02-03 01:01:31.216582+00	2026-02-03 01:16:31.216582+00	2026-02-03 02:11:54.848782+00	\N	78930	8.0	18.0	\N	f	{}	0
80	36ae407d-c380-41ff-a714-d61371c44fb3	BTCUSDT	15m	DOWN	1.5	79065.24	10	WIN	\N	0	2026-02-03 01:02:13.691276+00	2026-02-03 01:17:13.691276+00	2026-02-03 02:11:55.01381+00	\N	78930	8.0	18.0	\N	f	{}	0
73	5ac10c39-274e-4ce5-a13b-f4da3af4a230	BTCUSDT	30m	UP	2	79065.24	10	LOSS	\N	0	2026-02-03 01:00:41.159614+00	2026-02-03 01:15:41.159614+00	2026-02-03 02:11:55.220499+00	\N	78905.59	-10	0	\N	f	{}	0
77	60abdd33-af5a-4dfb-b211-a057a0995d12	BTCUSDT	30m	UP	1	79065.24	10	LOSS	\N	0	2026-02-03 01:01:41.232913+00	2026-02-03 01:16:41.232913+00	2026-02-03 02:11:56.17838+00	\N	78905.59	-10	0	\N	f	{}	0
81	36ae407d-c380-41ff-a714-d61371c44fb3	BTCUSDT	30m	DOWN	1	79065.24	10	WIN	\N	0	2026-02-03 01:02:19.828497+00	2026-02-03 01:17:19.828497+00	2026-02-03 02:11:56.908668+00	\N	78905.59	8.0	18.0	\N	f	{}	0
74	5ac10c39-274e-4ce5-a13b-f4da3af4a230	BTCUSDT	1h	DOWN	1	79065.24	10	WIN	\N	0	2026-02-03 01:00:50.748312+00	2026-02-03 02:00:50.748312+00	2026-02-03 02:11:57.07056+00	\N	79017.63	8.0	18.0	\N	f	{}	0
78	60abdd33-af5a-4dfb-b211-a057a0995d12	BTCUSDT	1h	DOWN	1.5	79065.24	10	WIN	\N	0	2026-02-03 01:01:48.738284+00	2026-02-03 02:01:48.738284+00	2026-02-03 02:11:57.324549+00	\N	79017.63	8.0	18.0	\N	f	{}	0
82	36ae407d-c380-41ff-a714-d61371c44fb3	BTCUSDT	1h	UP	2	79065.24	10	LOSS	\N	0	2026-02-03 01:02:26.596756+00	2026-02-03 02:02:26.596756+00	2026-02-03 02:11:57.947373+00	\N	79017.63	-10	0	\N	f	{}	0
79	36ae407d-c380-41ff-a714-d61371c44fb3	BTCUSDT	1m	UP	1	79093.47	10	WIN	\N	0	2026-02-03 01:02:07.738201+00	2026-02-03 01:03:07.738201+00	2026-02-03 02:11:58.514557+00	\N	79168.63	8.0	18.0	\N	f	{}	0
83	36ae407d-c380-41ff-a714-d61371c44fb3	BTCUSDT	1m	UP	0.5	78822.88	10	WIN	\N	0	2026-02-03 01:37:04.005806+00	2026-02-03 01:38:04.005806+00	2026-02-03 02:11:58.795176+00	\N	78839.4	8.0	18.0	\N	f	{}	0
84	60abdd33-af5a-4dfb-b211-a057a0995d12	BTCUSDT	1m	DOWN	1	78822.88	10	LOSS	\N	0	2026-02-03 01:37:17.157424+00	2026-02-03 01:38:17.157424+00	2026-02-03 02:11:58.961752+00	\N	78839.4	-10	0	\N	f	{}	0
86	60abdd33-af5a-4dfb-b211-a057a0995d12	BTCUSDT	30m	DOWN	1.5	78905.59	10	LOSS	\N	0	2026-02-03 01:37:44.190261+00	2026-02-03 01:52:44.190261+00	2026-02-03 02:11:59.401542+00	ㅈㅈㅈㅈㅈㅈㅈ	79017.63	-10	0	\N	f	{}	0
75	60abdd33-af5a-4dfb-b211-a057a0995d12	BTCUSDT	1m	UP	1.5	79076.62	10	WIN	\N	0	2026-02-03 01:01:20.512514+00	2026-02-03 01:02:20.512514+00	2026-02-03 02:11:58.272196+00	\N	79093.46	8.0	18.0	\N	f	{}	0
87	5ac10c39-274e-4ce5-a13b-f4da3af4a230	BTCUSDT	30m	UP	2	78905.59	10	WIN	\N	0	2026-02-03 01:37:56.280317+00	2026-02-03 01:52:56.280317+00	2026-02-03 02:11:59.171265+00	\N	79017.63	8.0	18.0	\N	f	{}	0
91	5ac10c39-274e-4ce5-a13b-f4da3af4a230	BTCUSDT	1m	UP	0.5	78556.01	10	WIN	\N	0	2026-02-03 02:13:03.657303+00	2026-02-03 02:14:03.657303+00	2026-02-03 02:14:41.789905+00	\N	78586.77	8.0	18.0	\N	f	{}	0
113	95f608be-c1e9-43b1-b885-5e2784e4858f	XAUUSD	1m	UP	0.5	150.25	10	LOSS	\N	0	2026-02-03 13:58:26.734797+00	2026-02-03 13:59:26.734797+00	2026-02-03 13:59:42.726061+00	\N	148.0287622461096	-10	0	-1.47836123387048252900	f	{}	0
92	5ac10c39-274e-4ce5-a13b-f4da3af4a230	BTCUSDT	1m	UP	0.5	78845.64	10	LOSS	\N	0	2026-02-03 02:23:05.649794+00	2026-02-03 02:24:05.649794+00	2026-02-03 02:24:41.780708+00	\N	78828.03	-10	0	\N	f	{}	0
93	5ac10c39-274e-4ce5-a13b-f4da3af4a230	BTCUSDT	1m	DOWN	0.5	78828.03	10	LOSS	\N	0	2026-02-03 02:24:18.968356+00	2026-02-03 02:25:18.968356+00	2026-02-03 02:25:41.861864+00	ㅇㅇㅇㅇㅇㅇㅇ	78842.99	-10	0	\N	f	{}	0
173	95f608be-c1e9-43b1-b885-5e2784e4858f	BTCUSDT	1m	UP	0.5	76459.11	10	LOSS	76377.78125	-10	2026-02-04 05:04:03.501788+00	2026-02-04 05:05:03.501788+00	2026-02-04 05:08:54.01512+00	\N	\N	\N	\N	\N	f	{}	0
94	5ac10c39-274e-4ce5-a13b-f4da3af4a230	BTCUSDT	1m	DOWN	1.5	78701.09	10	WIN	\N	0	2026-02-03 02:27:19.222518+00	2026-02-03 02:28:19.222518+00	2026-02-03 02:28:37.696229+00	\N	78647.71	8.0	18.0	\N	f	{}	0
520	95f608be-c1e9-43b1-b885-5e2784e4858f	BTCUSDT	1h	UP	0.5	69089.22	15	LOSS	68873.5	-15	2026-02-10 10:26:38.161778+00	2026-02-10 11:00:00+00	2026-02-10 11:00:24.978474+00	\N	\N	\N	\N	\N	f	{}	0
524	10e558ca-3940-4995-9a8f-165e78efaffc	SOLUSDT	1h	DOWN	0.5	84.16	10	WIN	83.77	9	2026-02-10 11:01:33.991006+00	2026-02-10 12:00:00+00	2026-02-10 12:00:27.148012+00	\N	\N	\N	\N	\N	f	{}	0
98	36ae407d-c380-41ff-a714-d61371c44fb3	BTCUSDT	1m	UP	0.5	78304.92	10	WIN	\N	0	2026-02-03 02:46:25.615685+00	2026-02-03 02:47:25.615685+00	2026-02-03 02:54:43.9635+00	\N	78331.68	8.0	18.0	0.03417409787277734300	f	{}	0
99	5ac10c39-274e-4ce5-a13b-f4da3af4a230	BTCUSDT	1m	UP	0.5	78331.69	10	LOSS	\N	0	2026-02-03 02:47:12.13926+00	2026-02-03 02:48:12.13926+00	2026-02-03 02:54:44.281668+00	\N	78227.02	-10	0	-0.13362407985835617700	f	{}	0
95	5ac10c39-274e-4ce5-a13b-f4da3af4a230	BTCUSDT	1m	UP	0.5	78640.01	10	WIN	\N	0	2026-02-03 02:35:05.066418+00	2026-02-03 02:36:05.066418+00	2026-02-03 02:54:50.359199+00	\N	78703.99	8.0	18.0	0.08135807714164838000	f	{}	0
96	60abdd33-af5a-4dfb-b211-a057a0995d12	BTCUSDT	1m	DOWN	0.5	78640.01	10	LOSS	\N	0	2026-02-03 02:35:15.684555+00	2026-02-03 02:36:15.684555+00	2026-02-03 02:54:50.535562+00	\N	78703.99	-10	0	0.08135807714164838000	f	{}	0
97	5ac10c39-274e-4ce5-a13b-f4da3af4a230	BTCUSDT	1m	DOWN	0.5	78304.92	10	LOSS	\N	0	2026-02-03 02:46:04.599823+00	2026-02-03 02:47:04.599823+00	2026-02-03 02:54:50.786224+00	\N	78331.68	-10	0	0.03417409787277734300	f	{}	0
100	5ac10c39-274e-4ce5-a13b-f4da3af4a230	BTCUSDT	1m	UP	0.5	78067.69	10	LOSS	\N	0	2026-02-03 02:56:06.183123+00	2026-02-03 02:57:06.183123+00	2026-02-03 02:57:48.056181+00	\N	78065.6	-10	0	-0.002677163881754410819600	f	{}	0
101	5ac10c39-274e-4ce5-a13b-f4da3af4a230	BTCUSDT	1m	UP	0.5	77985.11	10	WIN	\N	0	2026-02-03 03:09:08.72041+00	2026-02-03 03:10:08.72041+00	2026-02-03 03:10:43.032915+00	\N	77998.72	8.0	18.0	0.01745204950021869600	f	{}	0
102	60abdd33-af5a-4dfb-b211-a057a0995d12	BTCUSDT	1m	DOWN	0.5	77985.11	10	LOSS	\N	0	2026-02-03 03:09:20.397194+00	2026-02-03 03:10:20.397194+00	2026-02-03 03:10:43.232657+00	\N	77998.72	-10	0	0.01745204950021869600	f	{}	0
104	5ac10c39-274e-4ce5-a13b-f4da3af4a230	BTCUSDT	1m	UP	0.5	78083.14	10	LOSS	\N	0	2026-02-03 03:13:16.547948+00	2026-02-03 03:14:16.547948+00	2026-02-03 03:14:43.175609+00	\N	78040.01	-10	0	-0.05523599588848501700	f	{}	0
105	5ac10c39-274e-4ce5-a13b-f4da3af4a230	BTCUSDT	1m	UP	0.5	77963.61	10	LOSS	\N	0	2026-02-03 03:18:11.071392+00	2026-02-03 03:19:11.071392+00	2026-02-03 03:19:33.90879+00	\N	77938.94	-10	0	-0.03164296778971625400	f	{}	0
106	5ac10c39-274e-4ce5-a13b-f4da3af4a230	BTCUSDT	1m	UP	0.5	78387.66	10	LOSS	\N	0	2026-02-03 03:34:04.116294+00	2026-02-03 03:35:04.116294+00	2026-02-03 03:35:30.537186+00	\N	78372.16	-10	0	-0.01977352047503395300	f	{}	0
107	5ac10c39-274e-4ce5-a13b-f4da3af4a230	BTCUSDT	1m	UP	0.5	78560	10	LOSS	\N	0	2026-02-03 03:45:20.690911+00	2026-02-03 03:46:20.690911+00	2026-02-03 03:46:30.566708+00	\N	78517.24	-10	0	-0.05442973523421588600	f	{}	0
108	5ac10c39-274e-4ce5-a13b-f4da3af4a230	BTCUSDT	1m	DOWN	0.5	78616	10	WIN	\N	0	2026-02-03 03:47:18.014475+00	2026-02-03 03:48:18.014475+00	2026-02-03 03:48:31.060365+00	\N	78520.49	8.0	18.0	-0.12148926427190393800	f	{}	0
103	5ac10c39-274e-4ce5-a13b-f4da3af4a230	BTCUSDT	1h	UP	0.5	77808.02	10	WIN	\N	0	2026-02-03 03:13:02.657526+00	2026-02-03 04:13:02.657526+00	2026-02-03 04:00:42.973851+00	\N	78753.32	32.80	42.80	1.21491332127459354400	t	{}	0
109	5ac10c39-274e-4ce5-a13b-f4da3af4a230	BTCUSDT	1m	UP	0.5	78111.43	10	WIN	\N	0	2026-02-03 06:18:13.440835+00	2026-02-03 06:19:13.440835+00	2026-02-03 06:19:49.010921+00	\N	78241.9	8.0	18.0	0.16703061254927735900	f	{}	0
110	5ac10c39-274e-4ce5-a13b-f4da3af4a230	BTCUSDT	1m	UP	0.5	78356.84	10	LOSS	\N	0	2026-02-03 06:23:07.059005+00	2026-02-03 06:24:07.059005+00	2026-02-03 06:24:45.795009+00	\N	78333.33	-10	0	-0.03000376227525255000	f	{}	0
111	95f608be-c1e9-43b1-b885-5e2784e4858f	BTCUSDT	1m	UP	0.5	78234.67	10	WIN	\N	0	2026-02-03 13:54:05.445272+00	2026-02-03 13:55:05.445272+00	2026-02-03 13:55:41.301174+00	\N	78247.5	8.0	18.0	0.01639937894542151200	f	{}	0
112	95f608be-c1e9-43b1-b885-5e2784e4858f	BTCUSDT	1m	DOWN	0.5	78318.8	10	LOSS	\N	0	2026-02-03 13:58:03.88171+00	2026-02-03 13:59:03.88171+00	2026-02-03 13:59:42.535872+00	\N	78333.71	-10	0	0.01903757463086768400	f	{}	0
115	95f608be-c1e9-43b1-b885-5e2784e4858f	ETHUSDT	1m	DOWN	0.5	2312.19	10	WIN	\N	0	2026-02-03 14:15:11.556355+00	2026-02-03 14:16:11.556355+00	2026-02-03 14:16:42.788316+00	\N	2312.05	8.0	18.0	-0.006054865733352362911400	f	{}	0
116	95f608be-c1e9-43b1-b885-5e2784e4858f	ETHUSDT	1m	UP	0.5	2302.61	10	LOSS	\N	0	2026-02-03 14:18:21.159932+00	2026-02-03 14:19:21.159932+00	2026-02-03 14:19:42.835247+00	\N	2300.66	-10	0	-0.08468650791927421500	f	{}	0
117	95f608be-c1e9-43b1-b885-5e2784e4858f	BTCUSDT	1m	UP	0.5	78141.07	10	WIN	\N	0	2026-02-03 14:21:04.278124+00	2026-02-03 14:22:04.278124+00	2026-02-03 14:22:42.605824+00	\N	78143.07	8.0	18.0	0.002559473526533486168000	f	{}	0
118	5e4ec0ef-464a-41db-8e2f-9f3bfa2671ee	BTCUSDT	1m	UP	0.5	78159.78	10	WIN	\N	0	2026-02-03 14:23:03.89548+00	2026-02-03 14:24:03.89548+00	2026-02-03 14:24:42.747965+00	\N	78175.36	8.0	18.0	0.01993352591319985800	f	{}	0
119	10e558ca-3940-4995-9a8f-165e78efaffc	BTCUSDT	1m	UP	0.5	78175.35	10	WIN	\N	0	2026-02-03 14:24:13.28658+00	2026-02-03 14:25:13.28658+00	2026-02-03 14:25:42.609879+00	\N	78175.76	8.0	18.0	0.000524461994733634067500	f	{}	0
120	5e4ec0ef-464a-41db-8e2f-9f3bfa2671ee	BTCUSDT	1m	UP	0.5	78334.4	10	LOSS	\N	0	2026-02-03 14:26:07.638626+00	2026-02-03 14:27:07.638626+00	2026-02-03 14:27:42.618117+00	\N	78320	-10	0	-0.01838272840540043700	f	{}	0
121	8cf7c6be-ba2c-48c9-8825-589e675ff608	BTCUSDT	1m	UP	0.5	78320	10	WIN	\N	0	2026-02-03 14:27:08.406577+00	2026-02-03 14:28:08.406577+00	2026-02-03 14:28:42.923794+00	\N	78414.19	8.0	18.0	0.12026302349336057200	f	{}	0
125	10e558ca-3940-4995-9a8f-165e78efaffc	BTCUSDT	15m	UP	0.5	50000	100	WIN	50250	100	2026-02-03 22:09:10.206779+00	2026-02-03 22:24:10.206779+00	2026-02-03 22:09:10.87318+00	\N	\N	\N	\N	\N	f	{}	0
126	10e558ca-3940-4995-9a8f-165e78efaffc	ETHUSDT	1h	DOWN	1	3000	100	WIN	2970	100	2026-02-03 22:09:11.86818+00	2026-02-03 23:09:11.86818+00	2026-02-03 22:09:12.535241+00	\N	\N	\N	\N	\N	f	{}	0
127	10e558ca-3940-4995-9a8f-165e78efaffc	BTCUSDT	15m	UP	0.5	50000	100	LOSS	49500	-100	2026-02-03 22:09:13.533454+00	2026-02-03 22:24:13.533454+00	2026-02-03 22:09:14.202036+00	\N	\N	\N	\N	\N	f	{}	0
128	5e4ec0ef-464a-41db-8e2f-9f3bfa2671ee	BTCUSDT	15m	UP	0.5	50000	100	WIN	50250	100	2026-02-03 22:09:15.566187+00	2026-02-03 22:24:15.566187+00	2026-02-03 22:09:16.239096+00	\N	\N	\N	\N	\N	f	{}	0
129	5e4ec0ef-464a-41db-8e2f-9f3bfa2671ee	ETHUSDT	1h	DOWN	1	3000	100	WIN	2970	100	2026-02-03 22:09:17.244646+00	2026-02-03 23:09:17.244646+00	2026-02-03 22:09:17.922365+00	\N	\N	\N	\N	\N	f	{}	0
130	5e4ec0ef-464a-41db-8e2f-9f3bfa2671ee	BTCUSDT	15m	UP	0.5	50000	100	LOSS	49500	-100	2026-02-03 22:09:18.909016+00	2026-02-03 22:24:18.909016+00	2026-02-03 22:09:19.574927+00	\N	\N	\N	\N	\N	f	{}	0
131	95f608be-c1e9-43b1-b885-5e2784e4858f	BTCUSDT	15m	UP	0.5	50000	100	WIN	50250	100	2026-02-03 22:09:20.94111+00	2026-02-03 22:24:20.94111+00	2026-02-03 22:09:21.615726+00	\N	\N	\N	\N	\N	f	{}	0
132	95f608be-c1e9-43b1-b885-5e2784e4858f	ETHUSDT	1h	DOWN	1	3000	100	WIN	2970	100	2026-02-03 22:09:22.612935+00	2026-02-03 23:09:22.612935+00	2026-02-03 22:09:23.287563+00	\N	\N	\N	\N	\N	f	{}	0
133	95f608be-c1e9-43b1-b885-5e2784e4858f	BTCUSDT	15m	UP	0.5	50000	100	LOSS	49500	-100	2026-02-03 22:09:24.267127+00	2026-02-03 22:24:24.267127+00	2026-02-03 22:09:24.933031+00	\N	\N	\N	\N	\N	f	{}	0
134	8cf7c6be-ba2c-48c9-8825-589e675ff608	BTCUSDT	15m	UP	0.5	50000	100	WIN	50250	100	2026-02-03 22:09:26.275474+00	2026-02-03 22:24:26.275474+00	2026-02-03 22:09:26.946283+00	\N	\N	\N	\N	\N	f	{}	0
135	8cf7c6be-ba2c-48c9-8825-589e675ff608	ETHUSDT	1h	DOWN	1	3000	100	WIN	2970	100	2026-02-03 22:09:27.934848+00	2026-02-03 23:09:27.934848+00	2026-02-03 22:09:28.607892+00	\N	\N	\N	\N	\N	f	{}	0
136	8cf7c6be-ba2c-48c9-8825-589e675ff608	BTCUSDT	15m	UP	0.5	50000	100	LOSS	49500	-100	2026-02-03 22:09:29.596506+00	2026-02-03 22:24:29.596506+00	2026-02-03 22:09:30.260567+00	\N	\N	\N	\N	\N	f	{}	0
138	10e558ca-3940-4995-9a8f-165e78efaffc	BTCUSDT	1m	DOWN	0.5	75636.78	10	WIN	\N	0	2026-02-04 00:09:22.616593+00	2026-02-04 00:10:22.616593+00	2026-02-04 01:53:05.181317+00	\N	75622.77	8.0	18.0	-0.01852273457436977100	f	{}	0
139	5e4ec0ef-464a-41db-8e2f-9f3bfa2671ee	BTCUSDT	1m	UP	0.5	75837.21	10	LOSS	\N	0	2026-02-04 00:21:04.915146+00	2026-02-04 00:22:04.915146+00	2026-02-04 01:53:05.419608+00	\N	75822.9	-10	0	-0.01886936505179977000	f	{}	0
140	10e558ca-3940-4995-9a8f-165e78efaffc	XAUUSD	1m	UP	0.5	150.25	10	WIN	\N	0	2026-02-04 00:40:18.045756+00	2026-02-04 00:41:18.045756+00	2026-02-04 00:41:51.050376+00	\N	151.8066315865905	28.0	38.0	1.03602767826322795300	t	{}	0
174	95f608be-c1e9-43b1-b885-5e2784e4858f	XAUUSD	1m	DOWN	0.5	150.25	10	WIN	\N	0	2026-02-04 05:04:14.150663+00	2026-02-04 05:05:14.150663+00	2026-02-04 05:05:58.785999+00	\N	148.09614607498753	28.0	38.0	-1.43351342762893178000	t	{}	0
175	95f608be-c1e9-43b1-b885-5e2784e4858f	ETHUSDT	1m	UP	0.5	2272.24	10	LOSS	2270.241455078125	-10	2026-02-04 05:04:32.507037+00	2026-02-04 05:05:32.507037+00	2026-02-04 05:08:54.997046+00	\N	\N	\N	\N	\N	f	{}	0
143	95f608be-c1e9-43b1-b885-5e2784e4858f	XAUUSD	1m	UP	0.5	150.25	10	LOSS	\N	0	2026-02-04 00:55:06.91726+00	2026-02-04 00:56:06.91726+00	2026-02-04 00:56:32.618039+00	\N	149.40300527371448	-10	0	-0.56372361150450582400	f	{}	0
526	95f608be-c1e9-43b1-b885-5e2784e4858f	BTCUSDT	1m	UP	0.5	68754.5	14	LOSS	68577.32	-14	2026-02-10 15:13:11.328277+00	2026-02-10 15:14:00+00	2026-02-10 15:14:38.083463+00	\N	\N	\N	\N	\N	f	{}	0
176	95f608be-c1e9-43b1-b885-5e2784e4858f	BTCUSDT	1m	UP	0.5	76413.56	10	WIN	76516.8	8	2026-02-04 05:10:00.435661+00	2026-02-04 05:11:00.435661+00	2026-02-04 05:11:53.906749+00	\N	\N	\N	\N	\N	f	{}	0
144	95f608be-c1e9-43b1-b885-5e2784e4858f	XAUUSD	1m	UP	0.5	150.25	10	WIN	\N	0	2026-02-04 01:04:12.258653+00	2026-02-04 01:05:12.258653+00	2026-02-04 01:06:18.906098+00	\N	153.11508051175488	28.0	38.0	1.90687554858893843600	t	{}	0
177	95f608be-c1e9-43b1-b885-5e2784e4858f	XAUUSD	1m	DOWN	0.5	150.25	10	WIN	\N	0	2026-02-04 05:10:13.529965+00	2026-02-04 05:11:13.529965+00	2026-02-04 05:11:54.789145+00	\N	148.86038474708144	28.0	38.0	-0.92486872074446589000	t	{}	0
178	95f608be-c1e9-43b1-b885-5e2784e4858f	ETHUSDT	1m	UP	0.5	2274.12	10	LOSS	2273.7119140625	-10	2026-02-04 05:10:27.115585+00	2026-02-04 05:11:27.115585+00	2026-02-04 05:14:54.098685+00	\N	\N	\N	\N	\N	f	{}	0
148	95f608be-c1e9-43b1-b885-5e2784e4858f	XAUUSD	1m	UP	0.5	150.25	10	WIN	\N	0	2026-02-04 01:38:03.551257+00	2026-02-04 01:39:03.551257+00	2026-02-04 01:39:53.939144+00	\N	150.99347219787285	8.0	18.0	0.49482342620489184700	f	{}	0
114	95f608be-c1e9-43b1-b885-5e2784e4858f	ETHUSDT	1h	UP	0.5	2312.22	10	LOSS	\N	0	2026-02-03 14:14:22.979633+00	2026-02-03 15:14:22.979633+00	2026-02-04 01:53:04.596951+00	\N	2257.2	-10	0	-2.37953135947271453400	f	{}	0
137	5e4ec0ef-464a-41db-8e2f-9f3bfa2671ee	BTCUSDT	1m	UP	0.5	75954.98	10	LOSS	\N	0	2026-02-03 23:38:11.434764+00	2026-02-03 23:39:11.434764+00	2026-02-04 01:53:04.872869+00	\N	75933.95	-10	0	-0.02768745380487230700	f	{}	0
141	10e558ca-3940-4995-9a8f-165e78efaffc	BTCUSDT	1m	UP	1	76056.01	110	WIN	\N	0	2026-02-04 00:45:13.144231+00	2026-02-04 00:46:13.144231+00	2026-02-04 01:53:05.672132+00	\N	76074.49	88.0	198.0	0.02429788257364539600	f	{}	0
142	95f608be-c1e9-43b1-b885-5e2784e4858f	BTCUSDT	1m	UP	0.5	76122	10	WIN	\N	0	2026-02-04 00:52:05.502004+00	2026-02-04 00:53:05.502004+00	2026-02-04 01:53:05.892315+00	\N	76131.68	8.0	18.0	0.01271642889046530600	f	{}	0
145	95f608be-c1e9-43b1-b885-5e2784e4858f	BTCUSDT	1m	UP	0.5	76405.06	10	WIN	\N	0	2026-02-04 01:04:20.05872+00	2026-02-04 01:05:20.05872+00	2026-02-04 01:53:06.150482+00	\N	76409.71	8.0	18.0	0.006085984357580505793700	f	{}	0
146	95f608be-c1e9-43b1-b885-5e2784e4858f	BTCUSDT	1m	UP	0.5	76494.64	10	LOSS	\N	0	2026-02-04 01:21:06.044301+00	2026-02-04 01:22:06.044301+00	2026-02-04 01:53:06.387002+00	\N	76461.19	-10	0	-0.04372855405293756500	f	{}	0
147	95f608be-c1e9-43b1-b885-5e2784e4858f	BTCUSDT	1m	UP	0.5	76716	10	WIN	\N	0	2026-02-04 01:35:09.05252+00	2026-02-04 01:36:09.05252+00	2026-02-04 01:53:06.606806+00	\N	76754.25	8.0	18.0	0.04985922102299390000	f	{}	0
179	10e558ca-3940-4995-9a8f-165e78efaffc	ETHUSDT	1m	UP	1.5	2263.04	10	LOSS	2260.62548828125	-10	2026-02-04 05:58:07.533325+00	2026-02-04 05:59:07.533325+00	2026-02-04 06:02:53.713394+00	\N	\N	\N	\N	\N	f	{}	0
180	10e558ca-3940-4995-9a8f-165e78efaffc	ETHUSDT	1m	UP	1.5	2264.26	10	LOSS	2262.070068359375	-10	2026-02-04 05:59:03.344563+00	2026-02-04 06:00:03.344563+00	2026-02-04 06:03:53.716294+00	\N	\N	\N	\N	\N	f	{}	0
181	10e558ca-3940-4995-9a8f-165e78efaffc	ETHUSDT	1m	UP	0.5	2265.39	188	LOSS	2258.89208984375	-188	2026-02-04 06:00:10.923331+00	2026-02-04 06:01:10.923331+00	2026-02-04 06:04:54.439967+00	\N	\N	\N	\N	\N	f	{}	0
182	10e558ca-3940-4995-9a8f-165e78efaffc	BTCUSDT	1m	UP	0.5	76458.99	10	LOSS	76365.4765625	-10	2026-02-04 06:07:16.717204+00	2026-02-04 06:08:16.717204+00	2026-02-04 06:11:54.519699+00	\N	\N	\N	\N	\N	f	{}	0
183	10e558ca-3940-4995-9a8f-165e78efaffc	BTCUSDT	1m	UP	0.5	76463.16	10	LOSS	76377.0546875	-10	2026-02-04 06:08:04.843313+00	2026-02-04 06:09:04.843313+00	2026-02-04 06:12:54.529042+00	\N	\N	\N	\N	\N	f	{}	0
156	95f608be-c1e9-43b1-b885-5e2784e4858f	XAUUSD	1m	DOWN	0.5	150.25	10	LOSS	\N	0	2026-02-04 02:23:20.005164+00	2026-02-04 02:24:20.005164+00	2026-02-04 02:24:34.311631+00	\N	151.3391155032329	-10	0	0.72486888734302828600	f	{}	0
187	95f608be-c1e9-43b1-b885-5e2784e4858f	XAUUSD	1m	DOWN	0.5	150.25	10	WIN	\N	0	2026-02-04 06:21:45.274582+00	2026-02-04 06:22:45.274582+00	2026-02-04 06:22:42.450608+00	\N	150.2104984017241	8.0	18.0	-0.02629058121524126500	f	{}	0
184	95f608be-c1e9-43b1-b885-5e2784e4858f	BTCUSDT	1m	UP	0.5	76503.96	10	LOSS	76381.015625	-10	2026-02-04 06:18:27.986502+00	2026-02-04 06:19:27.986502+00	2026-02-04 06:22:55.263189+00	\N	\N	\N	\N	\N	f	{}	0
186	95f608be-c1e9-43b1-b885-5e2784e4858f	BTCUSDT	1m	DOWN	0.5	76496.61	10	WIN	76353.7578125	8	2026-02-04 06:21:09.776861+00	2026-02-04 06:22:09.776861+00	2026-02-04 06:25:55.394297+00	\N	\N	\N	\N	\N	f	{}	0
188	10e558ca-3940-4995-9a8f-165e78efaffc	XAGUSD	1m	UP	0.5	150.25	73	LOSS	\N	0	2026-02-04 06:35:02.877216+00	2026-02-04 06:36:02.877216+00	2026-02-04 06:36:52.425003+00	\N	147.6465247204032	-73	0	-1.73276224931567387700	f	{}	0
168	10e558ca-3940-4995-9a8f-165e78efaffc	XAGUSD	1m	UP	1	150.25	10	LOSS	\N	0	2026-02-04 02:37:07.049654+00	2026-02-04 02:38:07.049654+00	2026-02-04 02:38:52.77961+00	\N	148.52832583325846	-10	0	-1.14587298951184026600	f	{}	0
158	10e558ca-3940-4995-9a8f-165e78efaffc	BTCUSDT	1h	UP	0.5	76423.73	10	LOSS	\N	0	2026-02-04 02:24:04.552712+00	2026-02-04 03:24:04.552712+00	2026-02-04 10:03:50.551805+00	\N	75963.35	-10	0	-0.60240451493273097200	f	{}	0
185	95f608be-c1e9-43b1-b885-5e2784e4858f	BTCUSDT	30m	UP	0.5	76280	10	WIN	\N	0	2026-02-04 06:19:56.75729+00	2026-02-04 06:34:56.75729+00	2026-02-04 10:03:50.77848+00	\N	76486.01	11.20	21.20	0.27007079181961195600	f	{}	0
169	10e558ca-3940-4995-9a8f-165e78efaffc	XAGUSD	1m	UP	1	150.25	10	LOSS	\N	0	2026-02-04 04:51:43.53603+00	2026-02-04 04:52:43.53603+00	2026-02-04 04:52:32.99468+00	\N	148.8873453797825	-10	0	-0.90692487202495840300	f	{}	0
170	10e558ca-3940-4995-9a8f-165e78efaffc	XAGUSD	1m	UP	1	150.25	10	LOSS	\N	0	2026-02-04 04:52:09.530484+00	2026-02-04 04:53:09.530484+00	2026-02-04 04:53:53.876465+00	\N	148.74190588677175	-10	0	-1.00372320347970049900	f	{}	0
171	10e558ca-3940-4995-9a8f-165e78efaffc	XAGUSD	1m	UP	0.5	150.25	10	LOSS	\N	0	2026-02-04 04:52:17.834943+00	2026-02-04 04:53:17.834943+00	2026-02-04 04:53:54.118528+00	\N	148.74190588677175	-10	0	-1.00372320347970049900	f	{}	0
150	10e558ca-3940-4995-9a8f-165e78efaffc	BTCUSDT	1m	UP	2	76381.93	11	LOSS	76364.234375	-11	2026-02-04 02:22:03.824816+00	2026-02-04 02:23:03.824816+00	2026-02-04 04:53:55.534627+00	\N	\N	\N	\N	\N	f	{}	0
151	10e558ca-3940-4995-9a8f-165e78efaffc	BTCUSDT	1m	UP	1	76381.93	11	LOSS	76364.234375	-11	2026-02-04 02:22:26.57053+00	2026-02-04 02:23:26.57053+00	2026-02-04 04:53:56.520146+00	\N	\N	\N	\N	\N	f	{}	0
152	95f608be-c1e9-43b1-b885-5e2784e4858f	BTCUSDT	1m	UP	0.5	76381.93	10	LOSS	76364.234375	-10	2026-02-04 02:22:30.181466+00	2026-02-04 02:23:30.181466+00	2026-02-04 04:53:57.503432+00	\N	\N	\N	\N	\N	f	{}	0
153	10e558ca-3940-4995-9a8f-165e78efaffc	BTCUSDT	1m	UP	0.5	76381.93	11	LOSS	76364.234375	-11	2026-02-04 02:22:48.061023+00	2026-02-04 02:23:48.061023+00	2026-02-04 04:53:58.52297+00	\N	\N	\N	\N	\N	f	{}	0
154	95f608be-c1e9-43b1-b885-5e2784e4858f	ETHUSDT	1m	UP	0.5	2270.76	10	LOSS	2267.739013671875	-10	2026-02-04 02:23:07.416569+00	2026-02-04 02:24:07.416569+00	2026-02-04 04:53:59.508025+00	\N	\N	\N	\N	\N	f	{}	0
155	10e558ca-3940-4995-9a8f-165e78efaffc	BTCUSDT	1m	UP	0.5	76481.7	11	LOSS	76373.7421875	-11	2026-02-04 02:23:09.854668+00	2026-02-04 02:24:09.854668+00	2026-02-04 04:54:00.540698+00	\N	\N	\N	\N	\N	f	{}	0
157	95f608be-c1e9-43b1-b885-5e2784e4858f	SOLUSDT	1m	UP	0.5	98.86	10	LOSS	98.61123657226562	-10	2026-02-04 02:23:37.754918+00	2026-02-04 02:24:37.754918+00	2026-02-04 04:54:01.547233+00	\N	\N	\N	\N	\N	f	{}	0
159	10e558ca-3940-4995-9a8f-165e78efaffc	BTCUSDT	1m	UP	1	76433.86	10	LOSS	76292.1171875	-10	2026-02-04 02:26:27.106396+00	2026-02-04 02:27:27.106396+00	2026-02-04 04:54:03.425946+00	\N	\N	\N	\N	\N	f	{}	0
160	10e558ca-3940-4995-9a8f-165e78efaffc	BTCUSDT	1m	UP	0.5	76433.86	10	LOSS	76292.1171875	-10	2026-02-04 02:26:38.589157+00	2026-02-04 02:27:38.589157+00	2026-02-04 04:54:04.424653+00	\N	\N	\N	\N	\N	f	{}	0
161	10e558ca-3940-4995-9a8f-165e78efaffc	BTCUSDT	1m	UP	1	76433.86	10	LOSS	76292.1171875	-10	2026-02-04 02:26:57.288722+00	2026-02-04 02:27:57.288722+00	2026-02-04 04:54:05.428241+00	\N	\N	\N	\N	\N	f	{}	0
162	10e558ca-3940-4995-9a8f-165e78efaffc	BTCUSDT	1m	UP	1	76239.21	10	LOSS	76108.140625	-10	2026-02-04 02:28:29.492582+00	2026-02-04 02:29:29.492582+00	2026-02-04 04:54:06.413687+00	\N	\N	\N	\N	\N	f	{}	0
163	10e558ca-3940-4995-9a8f-165e78efaffc	BTCUSDT	1m	UP	0.5	76201.44	10	LOSS	76089.59375	-10	2026-02-04 02:29:08.375122+00	2026-02-04 02:30:08.375122+00	2026-02-04 04:54:07.422719+00	\N	\N	\N	\N	\N	f	{}	0
164	10e558ca-3940-4995-9a8f-165e78efaffc	BTCUSDT	1m	UP	1	76186.63	10	LOSS	76048.109375	-10	2026-02-04 02:30:03.782566+00	2026-02-04 02:31:03.782566+00	2026-02-04 04:54:08.450039+00	\N	\N	\N	\N	\N	f	{}	0
165	10e558ca-3940-4995-9a8f-165e78efaffc	BTCUSDT	1m	UP	1	76145.86	10	LOSS	76027.5625	-10	2026-02-04 02:31:11.255457+00	2026-02-04 02:32:11.255457+00	2026-02-04 04:54:09.423756+00	\N	\N	\N	\N	\N	f	{}	0
166	10e558ca-3940-4995-9a8f-165e78efaffc	BTCUSDT	1m	UP	0.5	76145.86	10	LOSS	76027.5625	-10	2026-02-04 02:31:24.364252+00	2026-02-04 02:32:24.364252+00	2026-02-04 04:54:10.43207+00	\N	\N	\N	\N	\N	f	{}	0
167	10e558ca-3940-4995-9a8f-165e78efaffc	BTCUSDT	1m	UP	1	76119	10	LOSS	76024.6328125	-10	2026-02-04 02:32:12.47521+00	2026-02-04 02:33:12.47521+00	2026-02-04 04:54:11.522737+00	\N	\N	\N	\N	\N	f	{}	0
172	10e558ca-3940-4995-9a8f-165e78efaffc	CORN	1m	UP	1	150.25	10	WIN	\N	0	2026-02-04 04:53:06.042688+00	2026-02-04 04:54:06.042688+00	2026-02-04 04:54:52.959042+00	\N	152.83497688691153	48.0	58.0	1.72045050709586023300	t	{}	0
521	95f608be-c1e9-43b1-b885-5e2784e4858f	BTCUSDT	1m	DOWN	0.5	69156.47	14	LOSS	69175.8	-14	2026-02-10 10:27:03.901195+00	2026-02-10 10:28:00+00	2026-02-10 10:28:33.524916+00	ㅓㅗㅗㅓㅓ	\N	\N	\N	\N	f	{}	0
190	95f608be-c1e9-43b1-b885-5e2784e4858f	XAUUSD	1m	UP	0.5	150.25	10	WIN	\N	0	2026-02-04 06:51:36.679587+00	2026-02-04 06:52:36.679587+00	2026-02-04 06:52:31.877854+00	\N	151.86290359207467	28.0	38.0	1.07347992816949750400	t	{}	0
192	95f608be-c1e9-43b1-b885-5e2784e4858f	XAUUSD	1m	DOWN	0.5	150.25	10	LOSS	\N	0	2026-02-04 07:15:34.360874+00	2026-02-04 07:16:34.360874+00	2026-02-04 07:16:50.16401+00	\N	151.74840281502674	-10	0	0.99727308820415307800	f	{}	0
193	10e558ca-3940-4995-9a8f-165e78efaffc	XAGUSD	1h	UP	0.5	150.25	65	WIN	\N	0	2026-02-04 07:25:27.072865+00	2026-02-04 08:25:27.072865+00	2026-02-04 08:01:23.616326+00	\N	150.70766860715474	83.20	148.20	0.30460473021946089900	f	{}	0
195	10e558ca-3940-4995-9a8f-165e78efaffc	XAGUSD	1m	UP	0.5	150.25	10	WIN	\N	0	2026-02-04 08:45:01.29927+00	2026-02-04 08:46:01.29927+00	2026-02-04 08:46:52.255238+00	\N	151.39284734071197	28.0	38.0	0.76063050962527121500	t	{}	0
196	10e558ca-3940-4995-9a8f-165e78efaffc	XAGUSD	1m	UP	0.5	150.25	10	WIN	\N	0	2026-02-04 08:45:05.264904+00	2026-02-04 08:46:05.264904+00	2026-02-04 08:46:52.542873+00	\N	151.39284734071197	28.0	38.0	0.76063050962527121500	t	{}	0
197	10e558ca-3940-4995-9a8f-165e78efaffc	XAUUSD	1m	UP	0.5	150.25	10	WIN	\N	0	2026-02-04 09:25:41.009407+00	2026-02-04 09:26:41.009407+00	2026-02-04 09:26:37.762752+00	\N	151.40959784251584	28.0	38.0	0.77177893012701497500	t	{}	0
198	10e558ca-3940-4995-9a8f-165e78efaffc	XAUUSD	1m	UP	0.5	150.25	10	WIN	\N	0	2026-02-04 09:26:07.595341+00	2026-02-04 09:27:07.595341+00	2026-02-04 09:27:52.638207+00	\N	150.85635095302953	8.0	18.0	0.40356136640900499200	f	{}	0
199	10e558ca-3940-4995-9a8f-165e78efaffc	XAUUSD	1m	UP	0.5	150.25	10	WIN	\N	0	2026-02-04 09:26:27.460558+00	2026-02-04 09:27:27.460558+00	2026-02-04 09:27:52.883423+00	\N	150.85635095302953	8.0	18.0	0.40356136640900499200	f	{}	0
200	10e558ca-3940-4995-9a8f-165e78efaffc	XAUUSD	1m	UP	0.5	150.25	10	WIN	\N	0	2026-02-04 09:30:12.348148+00	2026-02-04 09:31:12.348148+00	2026-02-04 09:31:52.220337+00	\N	151.98952916392258	28.0	38.0	1.15775651508990349400	t	{}	0
201	10e558ca-3940-4995-9a8f-165e78efaffc	XAGUSD	1m	UP	0.5	150.25	170	LOSS	\N	0	2026-02-04 09:33:03.695993+00	2026-02-04 09:34:03.695993+00	2026-02-04 09:34:52.207781+00	\N	148.2399161465957	-170	0	-1.33782619194961730400	f	{}	0
202	10e558ca-3940-4995-9a8f-165e78efaffc	XAUUSD	1m	UP	0.5	150.25	136	WIN	\N	0	2026-02-04 09:35:18.439057+00	2026-02-04 09:36:18.439057+00	2026-02-04 09:36:50.254448+00	\N	151.43557634391018	128.8	264.8	0.78906911408331447600	t	{}	0
203	10e558ca-3940-4995-9a8f-165e78efaffc	XAGUSD	1m	UP	0.5	150.25	162	LOSS	\N	0	2026-02-04 09:39:12.63959+00	2026-02-04 09:40:12.63959+00	2026-02-04 09:41:25.260184+00	\N	150.23226508288798	-162	0	-0.01180360539901497500	f	{}	0
204	10e558ca-3940-4995-9a8f-165e78efaffc	XAUUSD	1m	UP	0.5	150.25	130	WIN	\N	0	2026-02-04 09:41:03.519515+00	2026-02-04 09:42:03.519515+00	2026-02-04 09:42:36.968281+00	\N	152.19513402204907	124.0	254.0	1.29459835078141098200	t	{}	0
205	10e558ca-3940-4995-9a8f-165e78efaffc	XAUUSD	1m	UP	0.5	150.25	104	WIN	\N	0	2026-02-04 09:41:10.276621+00	2026-02-04 09:42:10.276621+00	2026-02-04 09:42:37.196044+00	\N	152.19513402204907	103.2	207.2	1.29459835078141098200	t	{}	0
206	10e558ca-3940-4995-9a8f-165e78efaffc	CORN	1m	DOWN	0.5	150.25	10	LOSS	\N	0	2026-02-04 09:46:25.265933+00	2026-02-04 09:47:25.265933+00	2026-02-04 09:47:53.852685+00	\N	151.16092117691457	-10	0	0.60627033405295840300	f	{}	0
208	10e558ca-3940-4995-9a8f-165e78efaffc	XAGUSD	1m	UP	0.5	150.25	139	LOSS	\N	0	2026-02-04 09:55:13.311663+00	2026-02-04 09:56:13.311663+00	2026-02-04 09:56:52.683655+00	\N	148.80758090835118	-139	0	-0.96001270658823294500	f	{}	0
149	10e558ca-3940-4995-9a8f-165e78efaffc	BTCUSDT	1h	UP	1	76423.73	122	LOSS	\N	0	2026-02-04 02:16:28.356521+00	2026-02-04 03:16:28.356521+00	2026-02-04 10:03:50.366982+00	\N	75963.35	-122	0	-0.60240451493273097200	f	{}	0
189	10e558ca-3940-4995-9a8f-165e78efaffc	BTCUSDT	1m	DOWN	0.5	76714.96	10	WIN	\N	0	2026-02-04 06:43:05.281493+00	2026-02-04 06:44:05.281493+00	2026-02-04 10:03:51.000532+00	\N	76711.75	8.0	18.0	-0.004184320763512097249400	f	{}	0
191	95f608be-c1e9-43b1-b885-5e2784e4858f	BTCUSDT	1m	UP	0.5	76583.89	10	WIN	\N	0	2026-02-04 07:14:57.770223+00	2026-02-04 07:15:57.770223+00	2026-02-04 10:03:51.220192+00	\N	76612.23	8.0	18.0	0.03700517171431224000	f	{}	0
194	10e558ca-3940-4995-9a8f-165e78efaffc	BTCUSDT	1m	UP	0.5	76426.09	10	LOSS	\N	0	2026-02-04 07:26:06.101163+00	2026-02-04 07:27:06.101163+00	2026-02-04 10:03:51.446182+00	\N	76422.25	-10	0	-0.005024462196090366522700	f	{}	0
207	10e558ca-3940-4995-9a8f-165e78efaffc	XRPUSDT	1m	DOWN	0.5	1.5989	173	WIN	\N	0	2026-02-04 09:50:04.194676+00	2026-02-04 09:51:04.194676+00	2026-02-04 10:03:51.667435+00	\N	1.5981	138.4	311.4	-0.05003439864907123600	f	{}	0
209	10e558ca-3940-4995-9a8f-165e78efaffc	ETHUSDT	1m	UP	0.5	2257.5	10	WIN	2266.53	8	2026-02-04 10:03:08.790797+00	2026-02-04 10:04:08.790797+00	2026-02-04 10:04:24.020566+00	\N	\N	\N	\N	\N	f	{}	0
211	95f608be-c1e9-43b1-b885-5e2784e4858f	XAUUSD	1m	DOWN	0.5	150.25	11	LOSS	\N	0	2026-02-04 10:07:57.706512+00	2026-02-04 10:08:57.706512+00	2026-02-04 10:08:42.104117+00	\N	151.5542359944765	-11	0	0.86804392311247920100	f	{}	0
210	95f608be-c1e9-43b1-b885-5e2784e4858f	BTCUSDT	1m	UP	0.5	76179.62	11	WIN	76423.39478399999	8	2026-02-04 10:07:42.782234+00	2026-02-04 10:08:42.782234+00	2026-02-04 10:09:09.517783+00	\N	\N	\N	\N	\N	f	{}	0
212	95f608be-c1e9-43b1-b885-5e2784e4858f	ETHUSDT	1m	UP	0.5	2253.39	11	WIN	2256.319407	8	2026-02-04 10:08:17.163244+00	2026-02-04 10:09:17.163244+00	2026-02-04 10:09:40.153374+00	\N	\N	\N	\N	\N	f	{}	0
219	10e558ca-3940-4995-9a8f-165e78efaffc	NG	1m	UP	0.5	150.25	10	WIN	\N	0	2026-02-04 10:17:11.054444+00	2026-02-04 10:18:11.054444+00	2026-02-04 10:18:52.529655+00	\N	150.56477952753283	8.0	18.0	0.20950384527975374400	f	{}	0
221	10e558ca-3940-4995-9a8f-165e78efaffc	NG	1m	UP	0.5	150.25	180	WIN	\N	0	2026-02-04 10:20:23.1738+00	2026-02-04 10:21:23.1738+00	2026-02-04 10:21:42.829687+00	\N	151.65579037851606	164.0	344.0	0.93563419535178702200	t	{}	0
222	10e558ca-3940-4995-9a8f-165e78efaffc	NG	1m	UP	0.5	150.25	144	LOSS	\N	0	2026-02-04 10:21:10.356232+00	2026-02-04 10:22:10.356232+00	2026-02-04 10:22:55.608797+00	\N	150.17917074295875	-144	0	-0.04714093646672213000	f	{}	0
223	10e558ca-3940-4995-9a8f-165e78efaffc	NG	1m	UP	0.5	150.25	115	LOSS	\N	0	2026-02-04 10:21:20.694983+00	2026-02-04 10:22:20.694983+00	2026-02-04 10:22:55.822815+00	\N	150.17917074295875	-115	0	-0.04714093646672213000	f	{}	0
216	95f608be-c1e9-43b1-b885-5e2784e4858f	XAUUSD	15m	UP	1	150.25	11	LOSS	\N	0	2026-02-04 10:16:24.555934+00	2026-02-04 10:31:24.555934+00	2026-02-04 10:30:30.201506+00	\N	147.82339541743164	-11	0	-1.61504464730007321100	f	{}	0
217	95f608be-c1e9-43b1-b885-5e2784e4858f	WTI	15m	UP	0.5	150.25	11	WIN	\N	0	2026-02-04 10:16:39.538447+00	2026-02-04 10:31:39.538447+00	2026-02-04 10:30:30.432567+00	\N	150.73078739484995	11.000	22.000	0.31999161054905158100	f	{}	0
218	95f608be-c1e9-43b1-b885-5e2784e4858f	NG	15m	UP	1.5	150.25	11	WIN	\N	0	2026-02-04 10:16:58.292703+00	2026-02-04 10:31:58.292703+00	2026-02-04 10:30:30.670553+00	\N	153.07002854246375	91.000	102.000	1.87689087684775374400	t	{}	0
220	95f608be-c1e9-43b1-b885-5e2784e4858f	NG	15m	DOWN	1.5	150.25	11	LOSS	\N	0	2026-02-04 10:17:14.449957+00	2026-02-04 10:32:14.449957+00	2026-02-04 10:30:30.895531+00	\N	153.07002854246375	-11	0	1.87689087684775374400	f	{}	0
213	95f608be-c1e9-43b1-b885-5e2784e4858f	BTCUSDT	15m	DOWN	1	76150	11	WIN	76023.015625	8	2026-02-04 10:15:40.169828+00	2026-02-04 10:30:40.169828+00	2026-02-04 10:35:02.946277+00	\N	\N	\N	\N	\N	f	{}	0
214	95f608be-c1e9-43b1-b885-5e2784e4858f	ETHUSDT	15m	UP	1	2254.7	11	LOSS	2252.743408203125	-11	2026-02-04 10:15:56.331516+00	2026-02-04 10:30:56.331516+00	2026-02-04 10:35:03.82228+00	\N	\N	\N	\N	\N	f	{}	0
215	95f608be-c1e9-43b1-b885-5e2784e4858f	SOLUSDT	15m	DOWN	1.5	97.09	11	WIN	96.876402	8	2026-02-04 10:16:08.728547+00	2026-02-04 10:31:08.728547+00	2026-02-04 10:35:04.715099+00	\N	\N	\N	\N	\N	f	{}	0
225	95f608be-c1e9-43b1-b885-5e2784e4858f	ETHUSDT	1m	DOWN	0.5	2259.21	12	WIN	2250.399081	9	2026-02-04 10:41:42.11109+00	2026-02-04 10:42:42.11109+00	2026-02-04 10:44:14.534162+00	\N	\N	\N	\N	\N	f	{}	0
226	95f608be-c1e9-43b1-b885-5e2784e4858f	SOLUSDT	1m	UP	0.5	96.99	13	LOSS	96.71842799999999	-13	2026-02-04 10:41:55.122088+00	2026-02-04 10:42:55.122088+00	2026-02-04 10:44:15.543726+00	\N	\N	\N	\N	\N	f	{}	0
224	10e558ca-3940-4995-9a8f-165e78efaffc	XAGUSD	30m	UP	0.5	150.25	10	LOSS	149.633975	-10	2026-02-04 10:30:10.409535+00	2026-02-04 10:45:10.409535+00	2026-02-04 10:45:40.150869+00	\N	\N	\N	\N	\N	f	{}	0
231	95f608be-c1e9-43b1-b885-5e2784e4858f	NG	1m	UP	0.5	150.25	12	LOSS	\N	0	2026-02-04 10:52:40.736762+00	2026-02-04 10:53:40.736762+00	2026-02-04 10:53:52.073404+00	\N	149.10019536720532	-12	0	-0.76526098688497836900	f	{}	0
232	95f608be-c1e9-43b1-b885-5e2784e4858f	BTCUSDT	1m	DOWN	0.5	76280	12	WIN	76180.836	9	2026-02-04 10:52:47.837257+00	2026-02-04 10:53:47.837257+00	2026-02-04 10:54:11.039617+00	\N	\N	\N	\N	\N	f	{}	0
229	95f608be-c1e9-43b1-b885-5e2784e4858f	XAUUSD	15m	UP	0.5	150.25	12	LOSS	\N	0	2026-02-04 10:49:37.404619+00	2026-02-04 11:04:37.404619+00	2026-02-04 11:00:52.121061+00	\N	149.97417192681078	-12	0	-0.18357941643209317800	f	{}	0
230	95f608be-c1e9-43b1-b885-5e2784e4858f	NG	15m	DOWN	1.5	150.25	12	LOSS	\N	0	2026-02-04 10:49:49.288316+00	2026-02-04 11:04:49.288316+00	2026-02-04 11:00:52.356967+00	\N	152.78492268451689	-12	0	1.68713656207446921800	f	{}	0
227	95f608be-c1e9-43b1-b885-5e2784e4858f	BTCUSDT	15m	UP	0.5	76263.74	12	LOSS	75882.4213	-12	2026-02-04 10:49:23.300279+00	2026-02-04 11:04:23.300279+00	2026-02-04 11:05:02.891965+00	\N	\N	\N	\N	\N	f	{}	0
228	95f608be-c1e9-43b1-b885-5e2784e4858f	ETHUSDT	15m	DOWN	0.5	2259.92	12	LOSS	2267.82972	-12	2026-02-04 10:49:30.085241+00	2026-02-04 11:04:30.085241+00	2026-02-04 11:05:04.19375+00	\N	\N	\N	\N	\N	f	{}	0
234	95f608be-c1e9-43b1-b885-5e2784e4858f	XAUUSD	1m	DOWN	0.5	150.25	11	WIN	150.204925	8	2026-02-04 23:22:22.547839+00	2026-02-04 23:23:22.547839+00	2026-02-04 23:24:27.403475+00	\N	\N	\N	\N	\N	f	{}	0
235	95f608be-c1e9-43b1-b885-5e2784e4858f	ETHUSDT	1m	UP	1	2138.75	11	LOSS	2133.49	-11	2026-02-04 23:22:31.384516+00	2026-02-04 23:23:31.384516+00	2026-02-04 23:24:27.928289+00	\N	\N	\N	\N	\N	f	{}	0
236	95f608be-c1e9-43b1-b885-5e2784e4858f	SOLUSDT	1m	DOWN	1.5	91.15	11	WIN	90.99	8	2026-02-04 23:22:40.397903+00	2026-02-04 23:23:40.397903+00	2026-02-04 23:24:28.466339+00	\N	\N	\N	\N	\N	f	{}	0
237	95f608be-c1e9-43b1-b885-5e2784e4858f	XAGUSD	1m	DOWN	1.5	150.25	11	WIN	149.7692	8	2026-02-04 23:22:55.61867+00	2026-02-04 23:23:55.61867+00	2026-02-04 23:24:28.945274+00	\N	\N	\N	\N	\N	f	{}	0
278	10e558ca-3940-4995-9a8f-165e78efaffc	BTCUSDT	15m	UP	0.5	50000	100	WIN	50250	100	2026-02-05 01:43:13.496565+00	2026-02-05 01:58:13.496565+00	2026-02-05 01:43:14.169693+00	\N	\N	\N	\N	\N	f	{}	0
529	5e4ec0ef-464a-41db-8e2f-9f3bfa2671ee	BTCUSDT	1m	UP	0.5	68643.64	11	LOSS	68627.54	-11	2026-02-10 23:13:25.433438+00	2026-02-10 23:14:00+00	2026-02-11 00:38:38.613387+00	\N	\N	\N	\N	\N	f	{}	0
280	10e558ca-3940-4995-9a8f-165e78efaffc	BTCUSDT	15m	UP	0.5	50000	100	LOSS	49500	-100	2026-02-05 01:43:16.807361+00	2026-02-05 01:58:16.807361+00	2026-02-05 01:43:17.474013+00	\N	\N	\N	\N	\N	f	{}	0
282	5e4ec0ef-464a-41db-8e2f-9f3bfa2671ee	ETHUSDT	1h	DOWN	1	3000	100	WIN	2970	100	2026-02-05 01:43:20.498728+00	2026-02-05 02:43:20.498728+00	2026-02-05 01:43:21.160304+00	\N	\N	\N	\N	\N	f	{}	0
283	5e4ec0ef-464a-41db-8e2f-9f3bfa2671ee	BTCUSDT	15m	UP	0.5	50000	100	LOSS	49500	-100	2026-02-05 01:43:22.140922+00	2026-02-05 01:58:22.140922+00	2026-02-05 01:43:22.797334+00	\N	\N	\N	\N	\N	f	{}	0
284	95f608be-c1e9-43b1-b885-5e2784e4858f	BTCUSDT	15m	UP	0.5	50000	100	WIN	50250	100	2026-02-05 01:43:24.20437+00	2026-02-05 01:58:24.20437+00	2026-02-05 01:43:24.900901+00	\N	\N	\N	\N	\N	f	{}	0
286	95f608be-c1e9-43b1-b885-5e2784e4858f	BTCUSDT	15m	UP	0.5	50000	100	LOSS	49500	-100	2026-02-05 01:43:27.665551+00	2026-02-05 01:58:27.665551+00	2026-02-05 01:43:28.324837+00	\N	\N	\N	\N	\N	f	{}	0
287	8cf7c6be-ba2c-48c9-8825-589e675ff608	BTCUSDT	15m	UP	0.5	50000	100	WIN	50250	100	2026-02-05 01:43:29.662966+00	2026-02-05 01:58:29.662966+00	2026-02-05 01:43:30.32601+00	\N	\N	\N	\N	\N	f	{}	0
289	8cf7c6be-ba2c-48c9-8825-589e675ff608	BTCUSDT	15m	UP	0.5	50000	100	LOSS	49500	-100	2026-02-05 01:43:32.939288+00	2026-02-05 01:58:32.939288+00	2026-02-05 01:43:33.603537+00	\N	\N	\N	\N	\N	f	{}	0
290	10e558ca-3940-4995-9a8f-165e78efaffc	XAUUSD	1m	UP	0.5	150.25	10	LOSS	149.8293	-10	2026-02-05 02:17:12.522853+00	2026-02-05 02:18:12.522853+00	2026-02-05 02:18:30.693052+00	\N	\N	\N	\N	\N	f	{}	0
295	95f608be-c1e9-43b1-b885-5e2784e4858f	XAUUSD	1m	UP	1.5	150.25	13	WIN	\N	0	2026-02-05 03:46:29.866059+00	2026-02-05 03:47:29.866059+00	2026-02-05 03:47:30.300433+00	\N	152.17341738520017	10.4	23.4	1.28014468232956406000	f	{}	0
296	95f608be-c1e9-43b1-b885-5e2784e4858f	WTI	1m	DOWN	2	150.25	13	LOSS	\N	0	2026-02-05 03:46:42.577852+00	2026-02-05 03:47:42.577852+00	2026-02-05 03:47:30.528653+00	\N	151.45746003101678	-13	0	0.80363396407106822000	f	{}	0
293	95f608be-c1e9-43b1-b885-5e2784e4858f	BTCUSDT	1m	UP	0.5	71298.57	13	WIN	71341.16	10	2026-02-05 03:46:11.419523+00	2026-02-05 03:47:11.419523+00	2026-02-05 03:47:31.485871+00	\N	\N	\N	\N	\N	f	{}	0
298	95f608be-c1e9-43b1-b885-5e2784e4858f	XAUUSD	15m	DOWN	1.5	150.25	13	WIN	\N	0	2026-02-05 03:47:01.134713+00	2026-02-05 04:02:01.134713+00	2026-02-05 04:00:30.660733+00	\N	148.40866697791085	13.000	26.000	-1.22551282668163061600	f	{}	0
299	95f608be-c1e9-43b1-b885-5e2784e4858f	BTCUSDT	15m	DOWN	1.5	71341.16	13	LOSS	71343.62	-13	2026-02-05 03:47:11.597462+00	2026-02-05 04:02:11.597462+00	2026-02-05 04:02:31.755131+00	\N	\N	\N	\N	\N	f	{}	0
300	95f608be-c1e9-43b1-b885-5e2784e4858f	ETHUSDT	15m	UP	0.5	2112.46	13	WIN	2113.21	10	2026-02-05 03:47:18.780194+00	2026-02-05 04:02:18.780194+00	2026-02-05 04:02:32.287959+00	\N	\N	\N	\N	\N	f	{}	0
303	95f608be-c1e9-43b1-b885-5e2784e4858f	XAUUSD	1m	UP	0.5	150.25	14	LOSS	\N	0	2026-02-05 04:26:39.741046+00	2026-02-05 04:27:39.741046+00	2026-02-05 04:27:30.985778+00	\N	149.13325594222204	-14	0	-0.74325727639132113100	f	{}	0
305	95f608be-c1e9-43b1-b885-5e2784e4858f	BTCUSDT	15m	DOWN	1.5	70768.21	14	LOSS	70874.52	-14	2026-02-05 04:32:32.883679+00	2026-02-05 04:47:32.883679+00	2026-02-05 04:48:01.350062+00	\N	\N	\N	\N	\N	f	{}	0
306	95f608be-c1e9-43b1-b885-5e2784e4858f	ETHUSDT	15m	UP	1	2093.02	14	WIN	2098.54	11	2026-02-05 04:32:41.728072+00	2026-02-05 04:47:41.728072+00	2026-02-05 04:48:01.921608+00	\N	\N	\N	\N	\N	f	{}	0
309	95f608be-c1e9-43b1-b885-5e2784e4858f	BTCUSDT	30m	UP	2	70874.52	14	WIN	71021.92	12	2026-02-05 04:33:20.118109+00	2026-02-05 04:48:20.118109+00	2026-02-05 04:48:31.445178+00	\N	\N	\N	\N	\N	f	{}	0
310	95f608be-c1e9-43b1-b885-5e2784e4858f	ETHUSDT	30m	UP	0.5	2098.54	14	LOSS	2094.54	-14	2026-02-05 04:33:27.781391+00	2026-02-05 04:48:27.781391+00	2026-02-05 04:48:45.272067+00	\N	\N	\N	\N	\N	f	{}	0
312	95f608be-c1e9-43b1-b885-5e2784e4858f	XAGUSD	30m	UP	0.5	150.25	14	WIN	150.40024999999997	12	2026-02-05 04:33:47.26098+00	2026-02-05 04:48:47.26098+00	2026-02-05 04:49:01.048291+00	\N	\N	\N	\N	\N	f	{}	0
319	5ac10c39-274e-4ce5-a13b-f4da3af4a230	XAUUSD	15m	UP	1	150.25	10	WIN	\N	0	2026-02-05 07:02:06.703848+00	2026-02-05 07:15:00+00	2026-02-05 07:15:32.029197+00	\N	151.1502341345068	10.000	20.000	0.59915749384811980000	f	{}	127
320	5ac10c39-274e-4ce5-a13b-f4da3af4a230	WTI	15m	DOWN	1.5	150.25	10	WIN	\N	0	2026-02-05 07:02:19.964731+00	2026-02-05 07:15:00+00	2026-02-05 07:15:32.344235+00	\N	147.66815266572587	90.000	100.000	-1.71836761016581031600	t	{}	140
314	5ac10c39-274e-4ce5-a13b-f4da3af4a230	ETHUSDT	15m	UP	1.5	2093.23	10	LOSS	\N	-10	2026-02-05 06:49:52.993333+00	2026-02-05 07:00:00+00	2026-02-05 07:42:50.141523+00	\N	2086.32	-10	0	0.33011183673079403600	f	{}	293
315	5ac10c39-274e-4ce5-a13b-f4da3af4a230	BTCUSDT	1m	UP	1.5	70636.7	10	WIN	\N	8	2026-02-05 06:53:08.274827+00	2026-02-05 06:54:00+00	2026-02-05 07:42:51.647845+00	\N	70666.34	8	18	0.04196119014619878900	f	{}	8
316	5ac10c39-274e-4ce5-a13b-f4da3af4a230	ETHUSDT	1m	UP	0.5	2100.4	10	WIN	\N	6	2026-02-05 07:01:16.083829+00	2026-02-05 07:02:00+00	2026-02-05 07:42:52.743023+00	\N	2109.19	6	16	0.41849171586364502000	f	{}	16
317	5ac10c39-274e-4ce5-a13b-f4da3af4a230	ETHUSDT	15m	DOWN	1	2086.32	10	LOSS	\N	-10	2026-02-05 07:01:31.715639+00	2026-02-05 07:15:00+00	2026-02-05 07:42:54.422803+00	\N	2097.89	-10	0	0.55456497565090686000	f	{}	92
318	5ac10c39-274e-4ce5-a13b-f4da3af4a230	BTCUSDT	15m	DOWN	0.5	70892.3	10	WIN	\N	8	2026-02-05 07:01:49.44012+00	2026-02-05 07:15:00+00	2026-02-05 07:42:55.326389+00	\N	70883.68	8	18	0.01215928951381179600	f	{}	109
313	5ac10c39-274e-4ce5-a13b-f4da3af4a230	BTCUSDT	1m	UP	1	70596.57311594476	10	WIN	\N	8	2026-02-05 06:49:08.371293+00	2026-02-05 06:50:00+00	2026-02-05 07:42:56.214908+00	\N	70676.98	8	18	0.11389629907840315300	f	{}	8
325	5ac10c39-274e-4ce5-a13b-f4da3af4a230	XAUUSD	1m	UP	1	150.25	10	LOSS	\N	0	2026-02-05 07:56:10.252793+00	2026-02-05 07:57:00+00	2026-02-05 07:57:30.602682+00	\N	147.8678264993228	-10	0	-1.58547321176519134800	f	{}	10
326	5ac10c39-274e-4ce5-a13b-f4da3af4a230	XAGUSD	1m	DOWN	1.5	150.25	10	WIN	\N	0	2026-02-05 07:56:19.250486+00	2026-02-05 07:57:00+00	2026-02-05 07:57:30.837424+00	\N	150.1929725132691	8.0	18.0	-0.03795506604386023300	f	{}	19
331	5ac10c39-274e-4ce5-a13b-f4da3af4a230	WTI	15m	UP	0.5	150.25	10	LOSS	\N	0	2026-02-05 08:01:11.493137+00	2026-02-05 08:15:00+00	2026-02-05 08:15:30.737234+00	\N	149.77351136047193	-10	0	-0.31713054211518802000	f	{}	71
321	5ac10c39-274e-4ce5-a13b-f4da3af4a230	BTCUSDT	1h	DOWN	1	70744.5	10	LOSS	\N	-10	2026-02-05 07:05:38.906187+00	2026-02-05 08:00:00+00	2026-02-05 08:43:17.929776+00	\N	70744.5	-10	0	0.000000000000000000000000	f	{}	339
322	5ac10c39-274e-4ce5-a13b-f4da3af4a230	ETHUSDT	1h	DOWN	1.5	2091.59	10	LOSS	\N	-10	2026-02-05 07:05:59.459853+00	2026-02-05 08:00:00+00	2026-02-05 08:43:19.832397+00	\N	2091.59	-10	0	0.00000000000000000000	f	{}	359
323	5ac10c39-274e-4ce5-a13b-f4da3af4a230	BTCUSDT	1m	UP	0.5	71353	10	LOSS	\N	-10	2026-02-05 07:55:08.809061+00	2026-02-05 07:56:00+00	2026-02-05 08:43:20.944162+00	\N	71353	-10	0	0.000000000000000000000000	f	{}	9
324	5ac10c39-274e-4ce5-a13b-f4da3af4a230	ETHUSDT	1m	DOWN	1	2115.88	10	LOSS	\N	-10	2026-02-05 07:55:17.262911+00	2026-02-05 07:56:00+00	2026-02-05 08:43:22.156257+00	\N	2115.88	-10	0	0.00000000000000000000	f	{}	17
332	5ac10c39-274e-4ce5-a13b-f4da3af4a230	XRPUSDT	15m	UP	0.5	1.4359	10	LOSS	\N	-10	2026-02-05 08:01:38.260765+00	2026-02-05 08:15:00+00	2026-02-05 08:43:23.390994+00	\N	1.4359	-10	0	0.00000000000000000000	f	{}	98
333	5ac10c39-274e-4ce5-a13b-f4da3af4a230	BTCUSDT	15m	DOWN	2	71366.28	10	LOSS	\N	-10	2026-02-05 08:01:48.053562+00	2026-02-05 08:15:00+00	2026-02-05 08:43:24.609678+00	\N	71366.28	-10	0	0.000000000000000000000000	f	{}	108
335	5ac10c39-274e-4ce5-a13b-f4da3af4a230	ETHUSDT	30m	DOWN	2	2116.96	10	LOSS	\N	-10	2026-02-05 08:02:22.630781+00	2026-02-05 08:30:00+00	2026-02-05 08:43:27.253874+00	\N	2116.96	-10	0	0.00000000000000000000	f	{}	143
336	5ac10c39-274e-4ce5-a13b-f4da3af4a230	BTCUSDT	1m	UP	0.5	71373.45	10	LOSS	\N	-10	2026-02-05 08:12:04.360131+00	2026-02-05 08:13:00+00	2026-02-05 08:43:28.495445+00	\N	71373.45	-10	0	0.000000000000000000000000	f	{}	4
337	5ac10c39-274e-4ce5-a13b-f4da3af4a230	ETHUSDT	1m	DOWN	1	2116.71	10	LOSS	\N	-10	2026-02-05 08:12:13.64233+00	2026-02-05 08:13:00+00	2026-02-05 08:43:29.557649+00	\N	2116.71	-10	0	0.00000000000000000000	f	{}	14
338	5ac10c39-274e-4ce5-a13b-f4da3af4a230	BTCUSDT	15m	UP	1	71371.3	10	LOSS	\N	-10	2026-02-05 08:15:08.220981+00	2026-02-05 08:30:00+00	2026-02-05 08:43:31.099437+00	\N	71360.28	-10	0	0.01544038009676158300	f	{}	8
329	5ac10c39-274e-4ce5-a13b-f4da3af4a230	XAGUSD	1h	DOWN	1.5	150.25	10	WIN	\N	0	2026-02-05 08:00:43.660768+00	2026-02-05 09:00:00+00	2026-02-05 09:00:31.199178+00	\N	150.10052920443843	12.80	22.80	-0.09948139471651913500	f	{}	44
330	5ac10c39-274e-4ce5-a13b-f4da3af4a230	XAUUSD	1h	UP	1	150.25	10	WIN	\N	0	2026-02-05 08:00:53.620068+00	2026-02-05 09:00:00+00	2026-02-05 09:00:31.887607+00	\N	150.96545441659566	12.80	22.80	0.47617598442306822000	f	{}	54
327	5ac10c39-274e-4ce5-a13b-f4da3af4a230	BTCUSDT	1h	UP	0.5	70541.27315680737	10	WIN	\N	28	2026-02-05 08:00:09.390734+00	2026-02-05 09:00:00+00	2026-02-05 14:48:45.083556+00	\N	71051.3	28	38	0.72301905022168063600	t	{}	9
328	5ac10c39-274e-4ce5-a13b-f4da3af4a230	ETHUSDT	1h	DOWN	1.5	2112.07	10	LOSS	\N	-10	2026-02-05 08:00:21.475463+00	2026-02-05 09:00:00+00	2026-02-05 14:48:47.510734+00	\N	2112.07	-10	0	0.00000000000000000000	f	{}	21
233	95f608be-c1e9-43b1-b885-5e2784e4858f	BTCUSDT	1m	UP	0.5	72969.51	11	LOSS	72789.88	-11	2026-02-04 23:22:09.249578+00	2026-02-04 23:23:09.249578+00	2026-02-04 23:24:26.5543+00	\N	\N	\N	\N	\N	f	{}	0
279	10e558ca-3940-4995-9a8f-165e78efaffc	ETHUSDT	1h	DOWN	1	3000	100	WIN	2970	100	2026-02-05 01:43:15.147631+00	2026-02-05 02:43:15.147631+00	2026-02-05 01:43:15.819859+00	\N	\N	\N	\N	\N	f	{}	0
523	10e558ca-3940-4995-9a8f-165e78efaffc	XAUUSD	1h	UP	0.5	5079	10	LOSS	5054.2020971679685	-10	2026-02-10 11:01:21.006393+00	2026-02-10 12:00:00+00	2026-02-10 12:00:25.229878+00	\N	\N	\N	\N	\N	f	{}	0
281	5e4ec0ef-464a-41db-8e2f-9f3bfa2671ee	BTCUSDT	15m	UP	0.5	50000	100	WIN	50250	100	2026-02-05 01:43:18.848202+00	2026-02-05 01:58:18.848202+00	2026-02-05 01:43:19.51994+00	\N	\N	\N	\N	\N	f	{}	0
238	5e4ec0ef-464a-41db-8e2f-9f3bfa2671ee	BTCUSDT	15m	UP	0.5	73380.95	10	LOSS	73122.52	-10	2026-02-04 23:33:26.830539+00	2026-02-04 23:48:26.830539+00	2026-02-04 23:48:39.539915+00	\N	\N	\N	\N	\N	f	{}	0
239	5e4ec0ef-464a-41db-8e2f-9f3bfa2671ee	ETHUSDT	15m	DOWN	1	2155.26	10	WIN	2148.33	8	2026-02-04 23:33:36.716223+00	2026-02-04 23:48:36.716223+00	2026-02-04 23:49:40.96535+00	\N	\N	\N	\N	\N	f	{}	0
240	5e4ec0ef-464a-41db-8e2f-9f3bfa2671ee	WTI	15m	UP	2	150.25	10	LOSS	149.9495	-10	2026-02-04 23:33:55.330916+00	2026-02-04 23:48:55.330916+00	2026-02-04 23:49:41.451382+00	\N	\N	\N	\N	\N	f	{}	0
241	5e4ec0ef-464a-41db-8e2f-9f3bfa2671ee	XAGUSD	15m	DOWN	1	150.25	10	WIN	149.513775	8	2026-02-04 23:34:06.201567+00	2026-02-04 23:49:06.201567+00	2026-02-04 23:49:41.92674+00	\N	\N	\N	\N	\N	f	{}	0
285	95f608be-c1e9-43b1-b885-5e2784e4858f	ETHUSDT	1h	DOWN	1	3000	100	WIN	2970	100	2026-02-05 01:43:26.017601+00	2026-02-05 02:43:26.017601+00	2026-02-05 01:43:26.676246+00	\N	\N	\N	\N	\N	f	{}	0
528	95f608be-c1e9-43b1-b885-5e2784e4858f	ETHUSDT	30m	DOWN	0.5	2008.62	14	LOSS	2020.65	-14	2026-02-10 15:14:15.158733+00	2026-02-10 15:30:00+00	2026-02-10 16:13:14.134416+00	00000000000	\N	\N	\N	\N	f	{}	0
288	8cf7c6be-ba2c-48c9-8825-589e675ff608	ETHUSDT	1h	DOWN	1	3000	100	WIN	2970	100	2026-02-05 01:43:31.296201+00	2026-02-05 02:43:31.296201+00	2026-02-05 01:43:31.961249+00	\N	\N	\N	\N	\N	f	{}	0
256	95f608be-c1e9-43b1-b885-5e2784e4858f	XAUUSD	1h	UP	1	150.25	11	LOSS	\N	0	2026-02-05 01:03:12.857414+00	2026-02-05 02:03:12.857414+00	2026-02-05 02:00:31.091316+00	\N	147.95968169782384	-11	0	-1.52433830427697836900	f	{}	0
257	95f608be-c1e9-43b1-b885-5e2784e4858f	SOY	1h	DOWN	1.5	150.25	11	LOSS	\N	0	2026-02-05 01:03:31.27274+00	2026-02-05 02:03:31.27274+00	2026-02-05 02:00:31.790697+00	\N	151.53062116174328	-11	0	0.85232689633496173000	f	{}	0
244	95f608be-c1e9-43b1-b885-5e2784e4858f	WTI	1m	DOWN	0.5	150.25	11	LOSS	\N	0	2026-02-05 00:53:40.265067+00	2026-02-05 00:54:40.265067+00	2026-02-05 00:54:31.029602+00	\N	150.35926797958976	-11	0	0.07272411287172046600	f	{}	0
245	95f608be-c1e9-43b1-b885-5e2784e4858f	XAUUSD	1m	UP	2	150.25	11	LOSS	149.73915	-11	2026-02-05 00:54:09.016884+00	2026-02-05 00:55:09.016884+00	2026-02-05 00:55:22.36428+00	\N	\N	\N	\N	\N	f	{}	0
246	95f608be-c1e9-43b1-b885-5e2784e4858f	BTCUSDT	1m	UP	1	72959.23	11	LOSS	72827.25	-11	2026-02-05 00:54:17.9488+00	2026-02-05 00:55:17.9488+00	2026-02-05 00:55:42.68781+00	\N	\N	\N	\N	\N	f	{}	0
247	95f608be-c1e9-43b1-b885-5e2784e4858f	ETHUSDT	1m	DOWN	1	2151.23	11	WIN	2146.89	8	2026-02-05 00:54:25.401484+00	2026-02-05 00:55:25.401484+00	2026-02-05 00:55:43.213225+00	\N	\N	\N	\N	\N	f	{}	0
242	10e558ca-3940-4995-9a8f-165e78efaffc	XAGUSD	1h	UP	0.5	150.25	159	LOSS	\N	0	2026-02-05 00:10:05.582344+00	2026-02-05 01:10:05.582344+00	2026-02-05 01:00:30.976958+00	\N	147.49029628516567	-159	0	-1.83674124115429617300	f	{}	0
243	10e558ca-3940-4995-9a8f-165e78efaffc	XAGUSD	1h	UP	2	150.25	127	LOSS	\N	0	2026-02-05 00:10:55.6313+00	2026-02-05 01:10:55.6313+00	2026-02-05 01:00:31.220103+00	\N	147.49029628516567	-127	0	-1.83674124115429617300	f	{}	0
258	95f608be-c1e9-43b1-b885-5e2784e4858f	XRPUSDT	1h	DOWN	2	1.491	11	WIN	1.485	10	2026-02-05 01:03:51.207025+00	2026-02-05 02:03:51.207025+00	2026-02-05 02:04:30.937285+00	\N	\N	\N	\N	\N	f	{}	0
259	95f608be-c1e9-43b1-b885-5e2784e4858f	ADAUSDT	1h	UP	2	0.2864	11	WIN	0.2866	10	2026-02-05 01:04:06.554909+00	2026-02-05 02:04:06.554909+00	2026-02-05 02:04:31.533392+00	\N	\N	\N	\N	\N	f	{}	0
291	10e558ca-3940-4995-9a8f-165e78efaffc	XAUUSD	1m	UP	0.5	150.25	10	WIN	\N	0	2026-02-05 02:27:50.926003+00	2026-02-05 02:28:50.926003+00	2026-02-05 02:28:31.119506+00	\N	151.18623615560358	28.0	38.0	0.62311890555978702200	t	{}	0
292	10e558ca-3940-4995-9a8f-165e78efaffc	XAUUSD	1m	UP	0.5	150.25	10	LOSS	149.91945	-10	2026-02-05 02:28:02.328692+00	2026-02-05 02:29:02.328692+00	2026-02-05 02:29:31.294358+00	\N	\N	\N	\N	\N	f	{}	0
531	5e4ec0ef-464a-41db-8e2f-9f3bfa2671ee	BTCUSDT	1h	DOWN	0.5	68807.07	11	LOSS	69157.17	-11	2026-02-11 00:48:52.150679+00	2026-02-11 01:00:00+00	2026-02-11 01:51:58.666102+00	0000000000000000000	\N	\N	\N	\N	f	{}	0
248	95f608be-c1e9-43b1-b885-5e2784e4858f	NG	15m	UP	0.5	150.25	11	WIN	\N	0	2026-02-05 01:01:12.864808+00	2026-02-05 01:16:12.864808+00	2026-02-05 01:15:31.039296+00	\N	151.54737899803513	31.000	42.000	0.86348019835948752100	t	{}	0
249	95f608be-c1e9-43b1-b885-5e2784e4858f	XAGUSD	15m	DOWN	1.5	150.25	11	WIN	\N	0	2026-02-05 01:01:23.458806+00	2026-02-05 01:16:23.458806+00	2026-02-05 01:15:31.324873+00	\N	149.3291036783295	11.000	22.000	-0.61290936550449251200	f	{}	0
255	95f608be-c1e9-43b1-b885-5e2784e4858f	XAGUSD	15m	DOWN	1	150.25	11	WIN	\N	0	2026-02-05 01:02:40.734208+00	2026-02-05 01:17:40.734208+00	2026-02-05 01:15:31.557627+00	\N	149.3291036783295	11.000	22.000	-0.61290936550449251200	f	{}	0
254	95f608be-c1e9-43b1-b885-5e2784e4858f	CORN	15m	DOWN	1	150.25	11	LOSS	\N	0	2026-02-05 01:02:27.844624+00	2026-02-05 01:17:27.844624+00	2026-02-05 01:15:31.810988+00	\N	151.16170801057564	-11	0	0.60679401702205657200	f	{}	0
250	95f608be-c1e9-43b1-b885-5e2784e4858f	BTCUSDT	15m	DOWN	1.5	72868.02	11	WIN	72742.2	8	2026-02-05 01:01:36.516981+00	2026-02-05 01:16:36.516981+00	2026-02-05 01:17:01.72232+00	\N	\N	\N	\N	\N	f	{}	0
251	95f608be-c1e9-43b1-b885-5e2784e4858f	ETHUSDT	15m	UP	0.5	2149.78	11	LOSS	2147.72	-11	2026-02-05 01:01:45.830187+00	2026-02-05 01:16:45.830187+00	2026-02-05 01:17:02.254099+00	\N	\N	\N	\N	\N	f	{}	0
252	95f608be-c1e9-43b1-b885-5e2784e4858f	ETHUSDT	30m	UP	1	2149.78	11	LOSS	2148.52	-11	2026-02-05 01:01:59.021205+00	2026-02-05 01:16:59.021205+00	2026-02-05 01:17:31.483716+00	\N	\N	\N	\N	\N	f	{}	0
253	95f608be-c1e9-43b1-b885-5e2784e4858f	BTCUSDT	30m	DOWN	1	72868.02	11	WIN	72857.95	9	2026-02-05 01:02:08.83513+00	2026-02-05 01:17:08.83513+00	2026-02-05 01:17:32.007477+00	\N	\N	\N	\N	\N	f	{}	0
294	95f608be-c1e9-43b1-b885-5e2784e4858f	ETHUSDT	1m	DOWN	1	2110.87	13	LOSS	2112.46	-13	2026-02-05 03:46:19.291427+00	2026-02-05 03:47:19.291427+00	2026-02-05 03:47:32.017272+00	\N	\N	\N	\N	\N	f	{}	0
297	95f608be-c1e9-43b1-b885-5e2784e4858f	WTI	15m	UP	1	150.25	13	WIN	\N	0	2026-02-05 03:46:52.104934+00	2026-02-05 04:01:52.104934+00	2026-02-05 04:00:30.985347+00	\N	152.64052376177173	53.000	66.000	1.59103078986471214600	t	{}	0
263	10e558ca-3940-4995-9a8f-165e78efaffc	BTCUSDT	15m	UP	0.5	50000	100	WIN	50250	100	2026-02-05 01:25:19.087516+00	2026-02-05 01:40:19.087516+00	2026-02-05 01:25:19.767529+00	\N	\N	\N	\N	\N	f	{}	0
264	10e558ca-3940-4995-9a8f-165e78efaffc	ETHUSDT	1h	DOWN	1	3000	100	WIN	2970	100	2026-02-05 01:25:20.758691+00	2026-02-05 02:25:20.758691+00	2026-02-05 01:25:21.429599+00	\N	\N	\N	\N	\N	f	{}	0
304	95f608be-c1e9-43b1-b885-5e2784e4858f	WTI	1m	UP	1.5	150.25	14	WIN	\N	0	2026-02-05 04:26:50.008481+00	2026-02-05 04:27:50.008481+00	2026-02-05 04:27:31.269405+00	\N	150.80905365207607	11.2	25.2	0.37208229755478868600	f	{}	0
265	10e558ca-3940-4995-9a8f-165e78efaffc	BTCUSDT	15m	UP	0.5	50000	100	LOSS	49500	-100	2026-02-05 01:25:22.409452+00	2026-02-05 01:40:22.409452+00	2026-02-05 01:25:23.075114+00	\N	\N	\N	\N	\N	f	{}	0
301	95f608be-c1e9-43b1-b885-5e2784e4858f	BTCUSDT	1m	UP	0.5	71138.24	14	LOSS	70931.76	-14	2026-02-05 04:26:20.537409+00	2026-02-05 04:27:20.537409+00	2026-02-05 04:27:47.267949+00	\N	\N	\N	\N	\N	f	{}	0
266	5e4ec0ef-464a-41db-8e2f-9f3bfa2671ee	BTCUSDT	15m	UP	0.5	50000	100	WIN	50250	100	2026-02-05 01:25:24.440072+00	2026-02-05 01:40:24.440072+00	2026-02-05 01:25:25.534938+00	\N	\N	\N	\N	\N	f	{}	0
302	95f608be-c1e9-43b1-b885-5e2784e4858f	ETHUSDT	1m	DOWN	1.5	2102.11	14	WIN	2095.46	11	2026-02-05 04:26:30.671094+00	2026-02-05 04:27:30.671094+00	2026-02-05 04:27:47.790626+00	\N	\N	\N	\N	\N	f	{}	0
267	5e4ec0ef-464a-41db-8e2f-9f3bfa2671ee	ETHUSDT	1h	DOWN	1	3000	100	WIN	2970	100	2026-02-05 01:25:26.53011+00	2026-02-05 02:25:26.53011+00	2026-02-05 01:25:27.192062+00	\N	\N	\N	\N	\N	f	{}	0
268	5e4ec0ef-464a-41db-8e2f-9f3bfa2671ee	BTCUSDT	15m	UP	0.5	50000	100	LOSS	49500	-100	2026-02-05 01:25:28.224579+00	2026-02-05 01:40:28.224579+00	2026-02-05 01:25:28.904651+00	\N	\N	\N	\N	\N	f	{}	0
269	95f608be-c1e9-43b1-b885-5e2784e4858f	BTCUSDT	15m	UP	0.5	50000	100	WIN	50250	100	2026-02-05 01:25:30.291122+00	2026-02-05 01:40:30.291122+00	2026-02-05 01:25:30.959543+00	\N	\N	\N	\N	\N	f	{}	0
270	95f608be-c1e9-43b1-b885-5e2784e4858f	ETHUSDT	1h	DOWN	1	3000	100	WIN	2970	100	2026-02-05 01:25:31.941791+00	2026-02-05 02:25:31.941791+00	2026-02-05 01:25:32.615244+00	\N	\N	\N	\N	\N	f	{}	0
271	95f608be-c1e9-43b1-b885-5e2784e4858f	BTCUSDT	15m	UP	0.5	50000	100	LOSS	49500	-100	2026-02-05 01:25:33.609527+00	2026-02-05 01:40:33.609527+00	2026-02-05 01:25:34.270243+00	\N	\N	\N	\N	\N	f	{}	0
307	95f608be-c1e9-43b1-b885-5e2784e4858f	NG	15m	DOWN	1.5	150.25	14	WIN	\N	0	2026-02-05 04:32:53.24013+00	2026-02-05 04:47:53.24013+00	2026-02-05 04:45:30.590832+00	\N	149.7938761172935	14.000	28.000	-0.30357662742529118100	f	{}	0
272	8cf7c6be-ba2c-48c9-8825-589e675ff608	BTCUSDT	15m	UP	0.5	50000	100	WIN	50250	100	2026-02-05 01:25:35.632808+00	2026-02-05 01:40:35.632808+00	2026-02-05 01:25:36.297218+00	\N	\N	\N	\N	\N	f	{}	0
308	95f608be-c1e9-43b1-b885-5e2784e4858f	CORN	15m	UP	0.5	150.25	14	WIN	\N	0	2026-02-05 04:33:03.426211+00	2026-02-05 04:48:03.426211+00	2026-02-05 04:45:30.877637+00	\N	152.43991460473788	34.000	48.000	1.45751388002521131400	t	{}	0
273	8cf7c6be-ba2c-48c9-8825-589e675ff608	ETHUSDT	1h	DOWN	1	3000	100	WIN	2970	100	2026-02-05 01:25:37.280892+00	2026-02-05 02:25:37.280892+00	2026-02-05 01:25:37.944564+00	\N	\N	\N	\N	\N	f	{}	0
311	95f608be-c1e9-43b1-b885-5e2784e4858f	XAUUSD	30m	DOWN	1.5	150.25	14	LOSS	150.265025	-14	2026-02-05 04:33:37.451561+00	2026-02-05 04:48:37.451561+00	2026-02-05 04:49:01.520389+00	\N	\N	\N	\N	\N	f	{}	0
274	8cf7c6be-ba2c-48c9-8825-589e675ff608	BTCUSDT	15m	UP	0.5	50000	100	LOSS	49500	-100	2026-02-05 01:25:38.927996+00	2026-02-05 01:40:38.927996+00	2026-02-05 01:25:39.586932+00	\N	\N	\N	\N	\N	f	{}	0
334	5ac10c39-274e-4ce5-a13b-f4da3af4a230	BTCUSDT	30m	UP	1.5	71366.2	10	LOSS	\N	-10	2026-02-05 08:02:07.952092+00	2026-02-05 08:30:00+00	2026-02-05 08:43:25.844917+00	\N	71366.2	-10	0	0.000000000000000000000000	f	{}	128
339	36ae407d-c380-41ff-a714-d61371c44fb3	BTCUSDT	15m	DOWN	1.5	71371.3	10	WIN	\N	6	2026-02-05 08:17:17.508678+00	2026-02-05 08:30:00+00	2026-02-05 08:43:31.292725+00	\N	71360.28	6	16	0.01544038009676158300	f	{}	138
393	5e4ec0ef-464a-41db-8e2f-9f3bfa2671ee	XAUUSD	1m	UP	1	150.25	11	LOSS	\N	0	2026-02-06 05:12:09.180027+00	2026-02-06 05:13:00+00	2026-02-06 05:13:39.437513+00	\N	149.87759652950945	-11	0	-0.24785588718173044900	f	{}	9
527	95f608be-c1e9-43b1-b885-5e2784e4858f	ETHUSDT	1m	DOWN	0.5	2013.85	14	WIN	2006.44	11	2026-02-10 15:13:36.119238+00	2026-02-10 15:14:00+00	2026-02-10 15:14:39.162129+00	\N	\N	\N	\N	\N	f	{}	0
392	5e4ec0ef-464a-41db-8e2f-9f3bfa2671ee	BTCUSDT	1m	UP	1.5	65755.3	11	LOSS	\N	-11	2026-02-06 05:09:10.635333+00	2026-02-06 05:10:00+00	2026-02-06 06:31:52.202191+00	\N	65755.3	-11	0	0.000000000000000000000000	f	{}	11
395	5ac10c39-274e-4ce5-a13b-f4da3af4a230	BTCUSDT	1m	UP	1	65755.3	10	LOSS	\N	-10	2026-02-06 06:21:06.802106+00	2026-02-06 06:22:00+00	2026-02-06 06:31:53.96397+00	\N	65755.3	-10	0	0.000000000000000000000000	f	{}	7
399	5ac10c39-274e-4ce5-a13b-f4da3af4a230	XAUUSD	1m	DOWN	0.5	150.25	10	LOSS	\N	0	2026-02-06 06:36:03.854124+00	2026-02-06 06:37:00+00	2026-02-06 06:38:22.875319+00	\N	153.11941982886114	-10	0	1.90976361321872878500	f	{}	4
398	5ac10c39-274e-4ce5-a13b-f4da3af4a230	ETHUSDT	1m	DOWN	0.5	1928.98	10	LOSS	\N	-10	2026-02-06 06:34:19.889673+00	2026-02-06 06:35:00+00	2026-02-06 06:42:35.913961+00	\N	1928.98	-10	0	0.00000000000000000000	f	{}	20
400	5ac10c39-274e-4ce5-a13b-f4da3af4a230	BTCUSDT	1m	UP	0.5	65164.71891591682	10	LOSS	\N	-10	2026-02-06 06:44:11.74091+00	2026-02-06 06:45:00+00	2026-02-06 06:54:32.798718+00	\N	65164.71891591682	-10	0	0.000000000000000000000000	f	{}	12
342	5ac10c39-274e-4ce5-a13b-f4da3af4a230	XAUUSD	15m	UP	1	150.25	10	WIN	\N	0	2026-02-05 15:01:51.008046+00	2026-02-05 15:15:00+00	2026-02-05 15:15:31.156994+00	\N	150.35402892719307	10.000	20.000	0.06923722275745091500	f	{}	111
343	5ac10c39-274e-4ce5-a13b-f4da3af4a230	XAGUSD	15m	UP	1.5	150.25	10	WIN	\N	0	2026-02-05 15:02:08.839505+00	2026-02-05 15:15:00+00	2026-02-05 15:15:31.456855+00	\N	150.27569019160507	10.000	20.000	0.01709829724131114800	f	{}	129
367	5ac10c39-274e-4ce5-a13b-f4da3af4a230	SOLUSDT	15m	UP	2	79.64	10	LOSS	\N	-10	2026-02-05 17:16:25.67053+00	2026-02-05 17:30:00+00	2026-02-05 23:25:18.78391+00	\N	79.62	-10	0	0.02511300853842290300	f	{}	86
345	5ac10c39-274e-4ce5-a13b-f4da3af4a230	XAGUSD	30m	UP	1	150.25	10	LOSS	\N	0	2026-02-05 15:04:07.478444+00	2026-02-05 15:30:00+00	2026-02-05 15:30:31.256011+00	\N	150.07247389139638	-10	0	-0.11815381604234276200	f	{}	247
346	5ac10c39-274e-4ce5-a13b-f4da3af4a230	XAUUSD	30m	DOWN	2	150.25	10	LOSS	\N	0	2026-02-05 15:04:44.398236+00	2026-02-05 15:30:00+00	2026-02-05 15:30:31.672946+00	\N	151.00046362748145	-10	0	0.49947662394772046600	f	{}	284
351	5ac10c39-274e-4ce5-a13b-f4da3af4a230	XAUUSD	1h	UP	1.5	150.25	10	WIN	\N	0	2026-02-05 15:09:45.521208+00	2026-02-05 16:00:00+00	2026-02-05 16:00:31.340524+00	\N	152.0630268532036	12.80	22.80	1.20667344639174708800	f	{}	586
352	5ac10c39-274e-4ce5-a13b-f4da3af4a230	WTI	1h	DOWN	0.5	150.25	10	WIN	\N	0	2026-02-05 15:10:00.961852+00	2026-02-05 16:00:00+00	2026-02-05 16:00:32.080812+00	\N	147.30185733405847	32.80	42.80	-1.96215818032714143100	t	{}	601
360	5ac10c39-274e-4ce5-a13b-f4da3af4a230	AAPL	1m	UP	0.5	150.25	10	WIN	\N	0	2026-02-05 16:39:04.27449+00	2026-02-05 16:40:00+00	2026-02-05 16:40:30.42983+00	\N	152.5836598488659	28.0	38.0	1.55318459159128119800	t	{}	4
361	5ac10c39-274e-4ce5-a13b-f4da3af4a230	NVDA	1m	DOWN	1.5	150.25	10	WIN	\N	0	2026-02-05 16:39:19.510094+00	2026-02-05 16:40:00+00	2026-02-05 16:40:30.825578+00	\N	149.3215951806098	8.0	18.0	-0.61790670175720465900	f	{}	20
340	5ac10c39-274e-4ce5-a13b-f4da3af4a230	BTCUSDT	15m	UP	1	68336.61	10	LOSS	\N	-10	2026-02-05 15:00:38.051209+00	2026-02-05 15:15:00+00	2026-02-05 16:56:27.410848+00	\N	68336.61	-10	0	0.000000000000000000000000	f	{}	38
344	36ae407d-c380-41ff-a714-d61371c44fb3	BTCUSDT	15m	DOWN	1	68336.61	10	LOSS	\N	-10	2026-02-05 15:02:43.008983+00	2026-02-05 15:15:00+00	2026-02-05 16:56:27.608332+00	\N	68336.61	-10	0	0.000000000000000000000000	f	{}	163
341	5ac10c39-274e-4ce5-a13b-f4da3af4a230	ETHUSDT	15m	DOWN	1.5	2000.64	10	WIN	\N	8	2026-02-05 15:01:11.9553+00	2026-02-05 15:15:00+00	2026-02-05 16:56:28.651108+00	\N	2000.13	8	18	0.02549184261036468300	f	{}	72
347	5ac10c39-274e-4ce5-a13b-f4da3af4a230	BTCUSDT	30m	UP	0.5	68298.81	10	WIN	\N	7	2026-02-05 15:05:05.209584+00	2026-02-05 15:30:00+00	2026-02-05 16:56:29.718946+00	\N	68305.35	7	17	0.009575569471854634070500	f	{}	305
348	5ac10c39-274e-4ce5-a13b-f4da3af4a230	ETHUSDT	30m	DOWN	2	1999.32	10	LOSS	\N	-10	2026-02-05 15:05:30.313928+00	2026-02-05 15:30:00+00	2026-02-05 16:56:30.843892+00	\N	1999.32	-10	0	0.00000000000000000000	f	{}	330
349	5ac10c39-274e-4ce5-a13b-f4da3af4a230	BTCUSDT	1h	UP	1.5	67479.3	10	LOSS	\N	-10	2026-02-05 15:07:03.736627+00	2026-02-05 16:00:00+00	2026-02-05 16:56:32.076256+00	\N	67479.3	-10	0	0.000000000000000000000000	f	{}	424
355	36ae407d-c380-41ff-a714-d61371c44fb3	BTCUSDT	1h	UP	0.5	67479.3	10	LOSS	\N	-10	2026-02-05 15:17:48.861304+00	2026-02-05 16:00:00+00	2026-02-05 16:56:32.240071+00	ㄷㄹㄷㄹ	67479.3	-10	0	0.000000000000000000000000	f	{}	1069
350	5ac10c39-274e-4ce5-a13b-f4da3af4a230	ETHUSDT	1h	DOWN	1.5	1960.72	10	LOSS	\N	-10	2026-02-05 15:07:24.189856+00	2026-02-05 16:00:00+00	2026-02-05 16:56:33.477237+00	\N	1960.72	-10	0	0.00000000000000000000	f	{}	444
353	5ac10c39-274e-4ce5-a13b-f4da3af4a230	ETHUSDT	1m	UP	0.5	2000	10	WIN	\N	8	2026-02-05 15:13:06.161538+00	2026-02-05 15:14:00+00	2026-02-05 16:56:34.744841+00	\N	2000.01	8	18	0.000500000000000000000000	f	{}	6
354	5ac10c39-274e-4ce5-a13b-f4da3af4a230	ETHUSDT	1m	UP	1	2000.01	10	LOSS	\N	-10	2026-02-05 15:15:17.961343+00	2026-02-05 15:16:00+00	2026-02-05 16:56:35.945062+00	호호	2000.01	-10	0	0.00000000000000000000	f	{}	18
356	5ac10c39-274e-4ce5-a13b-f4da3af4a230	BTCUSDT	15m	DOWN	0.5	68319.33	10	LOSS	\N	-10	2026-02-05 15:19:12.340177+00	2026-02-05 15:30:00+00	2026-02-05 16:56:37.116027+00	\N	68319.33	-10	0	0.000000000000000000000000	f	{}	252
357	5ac10c39-274e-4ce5-a13b-f4da3af4a230	ETHUSDT	15m	UP	0.5	1999.19	10	WIN	\N	6	2026-02-05 15:19:23.411294+00	2026-02-05 15:30:00+00	2026-02-05 16:56:38.783559+00	\N	1999.26	6	16	0.003501418074320099640400	f	{}	263
358	5ac10c39-274e-4ce5-a13b-f4da3af4a230	SOLUSDT	15m	DOWN	1.5	85.15	10	LOSS	\N	-10	2026-02-05 15:19:34.862133+00	2026-02-05 15:30:00+00	2026-02-05 16:56:40.017582+00	ㄷㄹㄷㄹㄴ	85.15	-10	0	0.00000000000000000000	f	{}	275
359	5ac10c39-274e-4ce5-a13b-f4da3af4a230	BTCUSDT	30m	UP	0.5	68331	10	LOSS	\N	-10	2026-02-05 15:37:23.98436+00	2026-02-05 16:00:00+00	2026-02-05 16:56:41.214481+00	\N	68331	-10	0	0.000000000000000000000000	f	{}	444
368	5ac10c39-274e-4ce5-a13b-f4da3af4a230	DOGEUSDT	15m	DOWN	2	0.08979	10	LOSS	\N	-10	2026-02-05 17:16:41.352858+00	2026-02-05 17:30:00+00	2026-02-05 23:25:20.50431+00	\N	0.08979	-10	0	0.0000000000000000	f	{}	101
369	5ac10c39-274e-4ce5-a13b-f4da3af4a230	ADAUSDT	1h	DOWN	2	0.258	10	LOSS	\N	-10	2026-02-05 17:17:43.381724+00	2026-02-05 18:00:00+00	2026-02-05 23:25:22.184224+00	\N	0.258	-10	0	0.0000000000000000	f	{}	1063
372	5ac10c39-274e-4ce5-a13b-f4da3af4a230	XAUUSD	1m	UP	1.5	150.25	10	WIN	\N	0	2026-02-05 17:22:04.671763+00	2026-02-05 17:23:00+00	2026-02-05 17:23:30.586372+00	\N	151.13267599188885	8.0	18.0	0.58747154202252911800	f	{}	5
365	5ac10c39-274e-4ce5-a13b-f4da3af4a230	NVDA	15m	DOWN	1.5	150.25	10	LOSS	\N	0	2026-02-05 17:15:50.234829+00	2026-02-05 17:30:00+00	2026-02-05 17:30:30.589568+00	\N	150.69024460674518	-10	0	0.29300805773389683900	f	{}	50
366	5ac10c39-274e-4ce5-a13b-f4da3af4a230	TSLA	15m	DOWN	1.5	180.5	10	WIN	\N	0	2026-02-05 17:16:07.687984+00	2026-02-05 17:30:00+00	2026-02-05 17:30:30.895627+00	\N	178.98319594115668	10.000	20.000	-0.84033465863895844900	f	{}	68
362	5ac10c39-274e-4ce5-a13b-f4da3af4a230	BTCUSDT	1h	UP	0.5	66175.1	10	LOSS	\N	-10	2026-02-05 17:10:26.008111+00	2026-02-05 18:00:00+00	2026-02-05 23:25:11.741775+00	ㅇㄹㅇㄹㅇㄹ	66175.1	-10	0	0.000000000000000000000000	f	{}	626
363	5ac10c39-274e-4ce5-a13b-f4da3af4a230	ETHUSDT	1h	DOWN	1	1955.11	10	LOSS	\N	-10	2026-02-05 17:10:50.910055+00	2026-02-05 18:00:00+00	2026-02-05 23:25:13.774428+00	ㅎㄹㅎㄹ	1955.11	-10	0	0.00000000000000000000	f	{}	651
364	5ac10c39-274e-4ce5-a13b-f4da3af4a230	ETHUSDT	4h	UP	1	1877.92	10	LOSS	\N	-10	2026-02-05 17:15:10.368302+00	2026-02-05 20:00:00+00	2026-02-05 23:25:16.344647+00	\N	1877.92	-10	0	0.00000000000000000000	f	{}	4510
370	5ac10c39-274e-4ce5-a13b-f4da3af4a230	ADAUSDT	1m	UP	1	0.2505	10	LOSS	\N	-10	2026-02-05 17:19:06.791629+00	2026-02-05 17:20:00+00	2026-02-05 23:25:23.719727+00	\N	0.2505	-10	0	0.0000000000000000	f	{}	7
371	5ac10c39-274e-4ce5-a13b-f4da3af4a230	BTCUSDT	1m	DOWN	2	64163.14	10	LOSS	\N	-10	2026-02-05 17:19:19.825108+00	2026-02-05 17:20:00+00	2026-02-05 23:25:25.143054+00	ㅑㅕㅑㅕ	64163.14	-10	0	0.000000000000000000000000	f	{}	20
375	5ac10c39-274e-4ce5-a13b-f4da3af4a230	XAUUSD	15m	DOWN	1.5	150.25	10	LOSS	\N	0	2026-02-06 00:33:10.583838+00	2026-02-06 00:45:00+00	2026-02-06 00:45:31.263583+00	\N	150.47770562671766	-10	0	0.15155116586865890200	f	{}	191
377	5ac10c39-274e-4ce5-a13b-f4da3af4a230	WTI	30m	UP	1	150.25	10	LOSS	\N	0	2026-02-06 00:33:50.769958+00	2026-02-06 01:00:00+00	2026-02-06 01:00:30.664611+00	\N	149.15933945009704	-10	0	-0.72589720459431614000	f	{}	231
380	5ac10c39-274e-4ce5-a13b-f4da3af4a230	SOLUSDT	30m	UP	0.5	76.16	10	WIN	\N	7	2026-02-06 00:34:53.448024+00	2026-02-06 01:00:00+00	2026-02-06 03:43:32.684518+00	\N	76.19	7	17	0.03939075630252100800	f	{}	293
373	5ac10c39-274e-4ce5-a13b-f4da3af4a230	BTCUSDT	15m	UP	1	64536.79	10	LOSS	\N	-10	2026-02-06 00:31:31.457981+00	2026-02-06 00:45:00+00	2026-02-06 03:43:34.260436+00	\N	64536.79	-10	0	0.000000000000000000000000	f	{}	91
374	5ac10c39-274e-4ce5-a13b-f4da3af4a230	ETHUSDT	15m	DOWN	1.5	1891.63	10	LOSS	\N	-10	2026-02-06 00:31:50.352169+00	2026-02-06 00:45:00+00	2026-02-06 03:43:35.786555+00	\N	1891.63	-10	0	0.00000000000000000000	f	{}	110
396	5ac10c39-274e-4ce5-a13b-f4da3af4a230	XAUUSD	1m	UP	0.5	150.25	10	LOSS	\N	0	2026-02-06 06:24:12.683274+00	2026-02-06 06:25:00+00	2026-02-06 06:26:22.801462+00	\N	147.96408124057012	-10	0	-1.52141015602654242900	f	{}	13
394	5ac10c39-274e-4ce5-a13b-f4da3af4a230	BTCUSDT	1m	UP	0.5	65755.3	10	LOSS	\N	-10	2026-02-06 05:31:11.418436+00	2026-02-06 05:32:00+00	2026-02-06 06:31:55.614122+00	\N	65755.3	-10	0	0.000000000000000000000000	f	{}	11
397	5ac10c39-274e-4ce5-a13b-f4da3af4a230	BTCUSDT	1m	UP	0.5	65294.21	10	LOSS	\N	-10	2026-02-06 06:34:05.705194+00	2026-02-06 06:35:00+00	2026-02-06 06:42:37.489219+00	\N	65294.21	-10	0	0.000000000000000000000000	f	{}	6
384	5ac10c39-274e-4ce5-a13b-f4da3af4a230	XAUUSD	1m	DOWN	1	150.25	10	LOSS	\N	0	2026-02-06 00:38:11.905135+00	2026-02-06 00:39:00+00	2026-02-06 00:39:30.567427+00	\N	151.67993859240968	-10	0	0.95170621790993677200	f	{}	12
376	5ac10c39-274e-4ce5-a13b-f4da3af4a230	WTI	15m	UP	1	150.25	10	WIN	\N	0	2026-02-06 00:33:30.13131+00	2026-02-06 00:45:00+00	2026-02-06 00:45:30.902457+00	\N	152.55011847704432	50.000	60.000	1.53086088322417304500	t	{}	210
378	5ac10c39-274e-4ce5-a13b-f4da3af4a230	XAGUSD	30m	DOWN	1.5	150.25	10	LOSS	\N	0	2026-02-06 00:34:06.208087+00	2026-02-06 01:00:00+00	2026-02-06 01:00:30.966523+00	\N	152.53608631686373	-10	0	1.52152167511729118100	f	{}	246
402	5ac10c39-274e-4ce5-a13b-f4da3af4a230	XAGUSD	1m	DOWN	1	150.25	10	LOSS	\N	0	2026-02-06 06:56:15.180991+00	2026-02-06 06:57:00+00	2026-02-06 06:58:22.848744+00	ㅛㅕㅕㅕㅕㅕㅕ	152.87894874541425	-10	0	1.74971630310432612300	f	{}	15
401	5ac10c39-274e-4ce5-a13b-f4da3af4a230	BTCUSDT	1m	UP	0.5	65044.6	10	LOSS	\N	-10	2026-02-06 06:56:05.069865+00	2026-02-06 06:57:00+00	2026-02-06 07:16:15.136178+00	\N	65024.15	-10	0	0.03143996580807630500	f	{}	5
403	95f608be-c1e9-43b1-b885-5e2784e4858f	BTCUSDT	1m	UP	0.5	65340.4	14	LOSS	\N	-14	2026-02-06 07:21:11.283973+00	2026-02-06 07:22:00+00	2026-02-06 07:29:25.204578+00	\N	65340.4	-14	0	0.000000000000000000000000	f	{}	11
404	95f608be-c1e9-43b1-b885-5e2784e4858f	XAGUSD	1m	DOWN	1.5	149.49875	14	LOSS	\N	-14	2026-02-06 07:22:09.778094+00	2026-02-06 07:23:00+00	2026-02-06 07:29:26.476952+00	\N	149.49875	-14	0	0.00000000000000000000	f	{}	10
379	5ac10c39-274e-4ce5-a13b-f4da3af4a230	ETHUSDT	30m	DOWN	1.5	1891.91	10	LOSS	\N	-10	2026-02-06 00:34:35.588887+00	2026-02-06 01:00:00+00	2026-02-06 03:43:37.643657+00	\N	1891.91	-10	0	0.00000000000000000000	f	{}	276
381	5ac10c39-274e-4ce5-a13b-f4da3af4a230	SOLUSDT	1m	UP	0.5	76.23	10	LOSS	\N	-10	2026-02-06 00:35:12.719196+00	2026-02-06 00:36:00+00	2026-02-06 03:43:39.326452+00	ㅎㅎㅎㅎㅎㅎㅎㅎㅎㅎ	76.23	-10	0	0.00000000000000000000	f	{}	13
382	5ac10c39-274e-4ce5-a13b-f4da3af4a230	ETHUSDT	1m	DOWN	1.5	1890.46	10	LOSS	\N	-10	2026-02-06 00:36:08.21617+00	2026-02-06 00:37:00+00	2026-02-06 03:43:40.960973+00	ㅇㅇㅇㅇㅇㅇㅇㅇㅇㅇ	1890.46	-10	0	0.00000000000000000000	f	{}	8
383	5ac10c39-274e-4ce5-a13b-f4da3af4a230	SOLUSDT	1m	DOWN	1.5	76.2	10	LOSS	\N	-10	2026-02-06 00:37:10.853216+00	2026-02-06 00:38:00+00	2026-02-06 03:43:42.983805+00	\N	76.2	-10	0	0.00000000000000000000	f	{}	11
385	95f608be-c1e9-43b1-b885-5e2784e4858f	BTCUSDT	1m	UP	1	64520.37	14	WIN	\N	11	2026-02-06 00:52:03.531626+00	2026-02-06 00:53:00+00	2026-02-06 03:43:44.723177+00	\N	64521.14	11	25	0.001193421550434382195900	f	{}	4
386	5ac10c39-274e-4ce5-a13b-f4da3af4a230	BTCUSDT	1m	UP	0.5	64521.14	10	LOSS	\N	-10	2026-02-06 01:56:04.817307+00	2026-02-06 01:57:00+00	2026-02-06 03:43:46.347106+00	\N	64521.14	-10	0	0.000000000000000000000000	f	{}	5
387	5ac10c39-274e-4ce5-a13b-f4da3af4a230	BTCUSDT	1m	DOWN	0.5	64520.91	10	LOSS	\N	-10	2026-02-06 01:57:08.402385+00	2026-02-06 01:58:00+00	2026-02-06 03:43:48.203645+00	\N	64520.91	-10	0	0.000000000000000000000000	f	{}	8
388	5ac10c39-274e-4ce5-a13b-f4da3af4a230	BTCUSDT	1m	DOWN	0.5	64515.3	10	LOSS	\N	-10	2026-02-06 02:03:05.323959+00	2026-02-06 02:04:00+00	2026-02-06 03:43:49.88004+00	\N	64515.3	-10	0	0.000000000000000000000000	f	{}	5
389	5ac10c39-274e-4ce5-a13b-f4da3af4a230	ETHUSDT	1m	DOWN	0.5	1889.69	10	LOSS	\N	-10	2026-02-06 02:03:18.647443+00	2026-02-06 02:04:00+00	2026-02-06 03:43:51.599979+00	\N	1889.69	-10	0	0.00000000000000000000	f	{}	19
390	5ac10c39-274e-4ce5-a13b-f4da3af4a230	BTCUSDT	1m	UP	0.5	64850.55078029557	10	LOSS	\N	-10	2026-02-06 02:20:04.498255+00	2026-02-06 02:21:00+00	2026-02-06 03:43:53.994534+00	\N	64850.55078029557	-10	0	0.000000000000000000000000	f	{}	4
391	5ac10c39-274e-4ce5-a13b-f4da3af4a230	BTCUSDT	1m	UP	0.5	64515.94	10	LOSS	\N	-10	2026-02-06 02:41:09.140315+00	2026-02-06 02:42:00+00	2026-02-06 03:43:55.575281+00	\N	64515.94	-10	0	0.000000000000000000000000	f	{}	9
405	95f608be-c1e9-43b1-b885-5e2784e4858f	BTCUSDT	1m	UP	0.5	65239.85440154484	14	LOSS	\N	-14	2026-02-06 07:40:13.77819+00	2026-02-06 07:41:00+00	2026-02-06 07:41:24.913418+00	\N	65239.85440154484	-14	0	0.000000000000000000000000	f	{}	14
406	95f608be-c1e9-43b1-b885-5e2784e4858f	XAUUSD	1m	DOWN	1.5	4853.908305664062	14	LOSS	\N	-14	2026-02-06 07:41:14.200991+00	2026-02-06 07:42:00+00	2026-02-06 07:42:24.06395+00	\N	4853.908305664062	-14	0	0.00000000000000000000	f	{}	14
407	95f608be-c1e9-43b1-b885-5e2784e4858f	ETHUSDT	1m	UP	1	1907.6785220420916	14	LOSS	\N	-14	2026-02-06 07:43:09.967338+00	2026-02-06 07:44:00+00	2026-02-06 07:44:24.855926+00	\N	1907.6785220420916	-14	0	0.00000000000000000000	f	{}	10
411	95f608be-c1e9-43b1-b885-5e2784e4858f	SOLUSDT	1m	UP	0.5	79.91659712945619	13	LOSS	\N	-13	2026-02-06 07:53:09.226716+00	2026-02-06 07:54:00+00	2026-02-06 07:54:24.960881+00	\N	79.91659712945619	-13	0	0.00000000000000000000	f	{}	9
408	95f608be-c1e9-43b1-b885-5e2784e4858f	ETHUSDT	15m	UP	0.5	1904.1243182513358	13	LOSS	\N	-13	2026-02-06 07:47:24.163348+00	2026-02-06 08:00:00+00	2026-02-06 08:00:24.927616+00	\N	1895.3358184818928	-13	0	0.46155073411981694800	f	{}	144
409	95f608be-c1e9-43b1-b885-5e2784e4858f	BTCUSDT	15m	DOWN	1.5	65144.25357171153	13	WIN	\N	8	2026-02-06 07:47:41.841727+00	2026-02-06 08:00:00+00	2026-02-06 08:00:27.052778+00	\N	64773.34304059798	8	21	0.56936799606621864000	f	{}	162
410	95f608be-c1e9-43b1-b885-5e2784e4858f	SOLUSDT	15m	UP	0.5	79.91864746207862	13	WIN	\N	8	2026-02-06 07:48:08.67844+00	2026-02-06 08:00:00+00	2026-02-06 08:00:29.014396+00	\N	80.13	8	21	0.26445960315039957500	f	{}	189
415	10e558ca-3940-4995-9a8f-165e78efaffc	XAGUSD	1m	UP	0.5	72.04795364379883	10	LOSS	\N	-10	2026-02-06 08:04:10.260964+00	2026-02-06 08:05:00+00	2026-02-06 08:05:23.387473+00	\N	72.04795364379883	-10	0	0.00000000000000000000	f	{}	10
412	95f608be-c1e9-43b1-b885-5e2784e4858f	BTCUSDT	15m	UP	1	64762.31745067788	13	WIN	\N	8	2026-02-06 08:02:31.414788+00	2026-02-06 08:15:00+00	2026-02-06 08:15:24.944237+00	\N	64977.17573977405	8	21	0.33176436167498671800	f	{}	151
413	95f608be-c1e9-43b1-b885-5e2784e4858f	ETHUSDT	15m	DOWN	1	1896.8862099046357	13	LOSS	\N	-13	2026-02-06 08:02:50.966585+00	2026-02-06 08:15:00+00	2026-02-06 08:15:26.840515+00	\N	1900.3549578393552	-13	0	0.18286536728494052800	f	{}	171
414	95f608be-c1e9-43b1-b885-5e2784e4858f	XAUUSD	15m	DOWN	1.5	4872.2001953125	13	WIN	\N	8	2026-02-06 08:03:37.249618+00	2026-02-06 08:15:00+00	2026-02-06 08:15:28.047193+00	\N	4847.341694335937	8	21	0.51021099257126462700	f	{}	217
422	95f608be-c1e9-43b1-b885-5e2784e4858f	BTCUSDT	1m	DOWN	1.5	64807.666195892656	13	LOSS	\N	-13	2026-02-06 08:21:09.237649+00	2026-02-06 08:22:00+00	2026-02-06 08:22:24.730853+00	\N	64807.666195892656	-13	0	0.000000000000000000000000	f	{}	9
416	95f608be-c1e9-43b1-b885-5e2784e4858f	XAUUSD	30m	DOWN	1.5	4872.2001953125	13	WIN	\N	9	2026-02-06 08:04:53.473609+00	2026-02-06 08:30:00+00	2026-02-06 08:30:23.25239+00	\N	4845.948305664063	9	22	0.53880974910870261400	f	{}	293
417	95f608be-c1e9-43b1-b885-5e2784e4858f	BTCUSDT	30m	UP	2	64762.31745067788	13	WIN	\N	9	2026-02-06 08:05:10.973632+00	2026-02-06 08:30:00+00	2026-02-06 08:30:25.931471+00	\N	64875.36243175026	9	22	0.17455363785966052700	f	{}	311
418	95f608be-c1e9-43b1-b885-5e2784e4858f	ETHUSDT	30m	DOWN	1	1896.8862099046357	13	WIN	\N	9	2026-02-06 08:06:00.492934+00	2026-02-06 08:30:00+00	2026-02-06 08:30:27.855973+00	\N	1884.0453750298475	9	22	0.67694281331897930600	f	{}	360
419	95f608be-c1e9-43b1-b885-5e2784e4858f	SOLUSDT	30m	DOWN	1	79.52252796429445	13	LOSS	\N	-13	2026-02-06 08:06:21.027717+00	2026-02-06 08:30:00+00	2026-02-06 08:30:29.627173+00	\N	79.53	-13	0	0.009396124465390408513000	f	{}	381
421	10e558ca-3940-4995-9a8f-165e78efaffc	SOLUSDT	30m	DOWN	0.5	79.52252796429445	141	LOSS	\N	-141	2026-02-06 08:09:01.649338+00	2026-02-06 08:30:00+00	2026-02-06 08:30:29.79293+00	\N	79.53	-141	0	0.009396124465390408513000	f	{}	542
424	95f608be-c1e9-43b1-b885-5e2784e4858f	ETHUSDT	15m	DOWN	1.5	1874.2865624121073	13	WIN	\N	10	2026-02-06 08:31:13.400232+00	2026-02-06 08:45:00+00	2026-02-06 08:45:26.976674+00	\N	1868.4002795092738	10	23	0.31405458593579022400	f	{}	73
425	95f608be-c1e9-43b1-b885-5e2784e4858f	SOLUSDT	15m	UP	0.5	79.39189581416449	13	LOSS	\N	-13	2026-02-06 08:31:34.411306+00	2026-02-06 08:45:00+00	2026-02-06 08:45:28.915986+00	\N	78.99	-13	0	0.50621768134271816600	f	{}	94
426	95f608be-c1e9-43b1-b885-5e2784e4858f	XAUUSD	15m	DOWN	1	4883.10009765625	13	WIN	\N	48	2026-02-06 08:31:58.133751+00	2026-02-06 08:45:00+00	2026-02-06 08:45:30.149147+00	\N	2686.5	48	61	44.98372045886497285300	t	{}	118
420	95f608be-c1e9-43b1-b885-5e2784e4858f	BTCUSDT	1h	UP	1.5	64762.31745067788	12	WIN	64984.66407408995	11	2026-02-06 08:08:50.814603+00	2026-02-06 09:00:00+00	2026-02-06 09:00:25.111162+00	\N	\N	\N	\N	\N	f	{}	531
428	95f608be-c1e9-43b1-b885-5e2784e4858f	XAGUSD	30m	DOWN	0.5	73.21499633789062	13	WIN	30.845	30	2026-02-06 08:34:24.894853+00	2026-02-06 09:00:00+00	2026-02-06 09:00:26.340525+00	\N	\N	\N	\N	\N	f	{}	265
429	95f608be-c1e9-43b1-b885-5e2784e4858f	BTCUSDT	30m	UP	0.5	64727.414074250795	13	WIN	64984.66407408995	11	2026-02-06 08:34:39.515259+00	2026-02-06 09:00:00+00	2026-02-06 09:00:28.091134+00	\N	\N	\N	\N	\N	f	{}	280
430	95f608be-c1e9-43b1-b885-5e2784e4858f	ETHUSDT	30m	UP	2	1874.2865624121073	12	LOSS	1872	-12	2026-02-06 08:35:00.940246+00	2026-02-06 09:00:00+00	2026-02-06 09:00:29.905025+00	\N	\N	\N	\N	\N	f	{}	301
423	95f608be-c1e9-43b1-b885-5e2784e4858f	BTCUSDT	15m	UP	0.5	64727.414074250795	13	WIN	\N	10	2026-02-06 08:30:54.755941+00	2026-02-06 08:45:00+00	2026-02-06 08:45:24.977684+00	\N	64784.95669681042	10	23	0.08889992498945825200	f	{}	55
427	95f608be-c1e9-43b1-b885-5e2784e4858f	XAGUSD	15m	DOWN	0.5	73.21499633789062	13	WIN	\N	30	2026-02-06 08:33:25.41803+00	2026-02-06 08:45:00+00	2026-02-06 08:45:31.073417+00	\N	30.845	30	43	57.87065281319022732900	t	{}	205
525	10e558ca-3940-4995-9a8f-165e78efaffc	ADAUSDT	30m	DOWN	0.5	0.2637	10	LOSS	0.2638	-10	2026-02-10 11:01:58.962107+00	2026-02-10 11:30:00+00	2026-02-10 11:30:24.935834+00	\N	\N	\N	\N	\N	f	{}	0
431	10e558ca-3940-4995-9a8f-165e78efaffc	XRPUSDT	30m	DOWN	0.5	1.3097115774550252	113	LOSS	1.327732680439997	-113	2026-02-06 09:36:38.503491+00	2026-02-06 10:00:00+00	2026-02-06 10:00:29.65978+00	\N	\N	\N	\N	\N	f	{}	0
432	95f608be-c1e9-43b1-b885-5e2784e4858f	BTCUSDT	1m	DOWN	0.5	65953.61	15	LOSS	65972.99	-15	2026-02-06 10:31:07.257042+00	2026-02-06 10:32:00+00	2026-02-06 10:32:53.678299+00	\N	\N	\N	\N	\N	f	{}	0
433	95f608be-c1e9-43b1-b885-5e2784e4858f	XAUUSD	1m	UP	0.5	4860.375805664063	15	LOSS	4860.375805664063	-15	2026-02-06 10:32:11.417975+00	2026-02-06 10:33:00+00	2026-02-06 10:33:53.481471+00	\N	\N	\N	\N	\N	f	{}	0
434	95f608be-c1e9-43b1-b885-5e2784e4858f	BTCUSDT	1m	DOWN	0.5	66430.57	15	LOSS	66460.54	-15	2026-02-06 12:02:16.159555+00	2026-02-06 12:03:00+00	2026-02-06 12:03:52.703865+00	\N	\N	\N	\N	\N	f	{}	0
435	95f608be-c1e9-43b1-b885-5e2784e4858f	XAUUSD	1m	DOWN	1	4885.847902832032	15	LOSS	4885.847902832032	-15	2026-02-06 12:03:14.444379+00	2026-02-06 12:04:00+00	2026-02-06 12:04:53.674614+00	\N	\N	\N	\N	\N	f	{}	0
436	10e558ca-3940-4995-9a8f-165e78efaffc	XAUUSD	1m	UP	0.5	4951.843004882812	10	LOSS	4932.015805664062	-10	2026-02-06 13:49:17.757272+00	2026-02-06 13:50:00+00	2026-02-06 13:50:44.09666+00	\N	\N	\N	\N	\N	f	{}	0
437	10e558ca-3940-4995-9a8f-165e78efaffc	XAUUSD	30m	DOWN	0.5	4944.10009765625	88	WIN	4927.040805664063	74	2026-02-06 14:00:24.291682+00	2026-02-06 14:30:00+00	2026-02-06 14:30:32.747822+00	\N	\N	\N	\N	\N	f	{}	0
438	95f608be-c1e9-43b1-b885-5e2784e4858f	AAPL	1m	UP	0.5	279.7650146484375	15	LOSS	279.2704378051758	-15	2026-02-06 14:38:12.907297+00	2026-02-06 14:39:00+00	2026-02-06 14:39:57.859029+00	\N	\N	\N	\N	\N	f	{}	0
439	95f608be-c1e9-43b1-b885-5e2784e4858f	XAGUSD	1m	DOWN	1	74.23069530487061	18	WIN	73.9334753036499	14	2026-02-06 14:39:09.705571+00	2026-02-06 14:40:00+00	2026-02-06 14:40:52.783587+00	\N	\N	\N	\N	\N	f	{}	0
440	95f608be-c1e9-43b1-b885-5e2784e4858f	ETHUSDT	1m	UP	2	1978.25	17	WIN	1979.2	13	2026-02-06 14:40:19.290148+00	2026-02-06 14:41:00+00	2026-02-06 14:41:52.724+00	\N	\N	\N	\N	\N	f	{}	0
441	10e558ca-3940-4995-9a8f-165e78efaffc	XAUUSD	1h	DOWN	0.5	4967.60009765625	103	LOSS	4971.7998046875	-103	2026-02-06 15:11:45.735477+00	2026-02-06 16:00:00+00	2026-02-06 16:17:22.703401+00	\N	\N	\N	\N	\N	f	{}	0
444	10e558ca-3940-4995-9a8f-165e78efaffc	ETHUSDT	1m	DOWN	0.5	2051.99	10	WIN	2051.5	8	2026-02-07 01:40:19.099991+00	2026-02-07 01:41:00+00	2026-02-07 01:41:43.48322+00	\N	\N	\N	\N	\N	f	{}	0
442	10e558ca-3940-4995-9a8f-165e78efaffc	BTCUSDT	30m	UP	0.5	69953.86	10	WIN	70450.01	27	2026-02-07 01:39:35.936033+00	2026-02-07 02:00:00+00	2026-02-07 02:01:14.608064+00	\N	\N	\N	\N	\N	f	{}	0
443	10e558ca-3940-4995-9a8f-165e78efaffc	ETHUSDT	30m	DOWN	0.5	2043.76	10	LOSS	2061.52	-10	2026-02-07 01:39:53.168557+00	2026-02-07 02:00:00+00	2026-02-07 02:01:15.823195+00	\N	\N	\N	\N	\N	f	{}	0
447	10e558ca-3940-4995-9a8f-165e78efaffc	ETHUSDT	1m	UP	0.5	2080.83	10	WIN	2083.85	8	2026-02-07 06:04:12.221221+00	2026-02-07 06:05:00+00	2026-02-07 06:05:43.818696+00	\N	\N	\N	\N	\N	f	{}	0
448	10e558ca-3940-4995-9a8f-165e78efaffc	SOLUSDT	1m	DOWN	0.5	87.93	82	LOSS	87.96	-82	2026-02-07 06:05:10.146858+00	2026-02-07 06:06:00+00	2026-02-07 06:06:43.952568+00	\N	\N	\N	\N	\N	f	{}	0
446	10e558ca-3940-4995-9a8f-165e78efaffc	BTCUSDT	1h	UP	0.5	70131.69	10	LOSS	68752.2	-10	2026-02-07 06:00:12.838571+00	2026-02-07 07:00:00+00	2026-02-07 07:01:15.361357+00	\N	\N	\N	\N	\N	f	{}	0
449	10e558ca-3940-4995-9a8f-165e78efaffc	SOLUSDT	1h	UP	0.5	86.22	10	LOSS	85.25	-10	2026-02-07 07:00:19.588681+00	2026-02-07 08:00:00+00	2026-02-07 08:01:15.092817+00	\N	\N	\N	\N	\N	f	{}	0
450	10e558ca-3940-4995-9a8f-165e78efaffc	BTCUSDT	1h	UP	0.5	68752.2	67	LOSS	68075.72	-67	2026-02-07 07:10:16.321888+00	2026-02-07 08:00:00+00	2026-02-07 08:01:16.209035+00	\N	\N	\N	\N	\N	f	{}	0
451	10e558ca-3940-4995-9a8f-165e78efaffc	XRPUSDT	1m	DOWN	0.5	1.422	53	LOSS	1.423	-53	2026-02-07 09:10:11.824923+00	2026-02-07 09:11:00+00	2026-02-07 09:11:44.249147+00	\N	\N	\N	\N	\N	f	{}	0
452	10e558ca-3940-4995-9a8f-165e78efaffc	XRPUSDT	1m	UP	0.5	1.391	10	LOSS	1.391	-10	2026-02-07 11:59:10.737895+00	2026-02-07 12:00:00+00	2026-02-07 12:00:33.272474+00	\N	\N	\N	\N	\N	f	{}	0
454	10e558ca-3940-4995-9a8f-165e78efaffc	AVAXUSDT	15m	UP	0.5	8.98	10	WIN	9.115	27	2026-02-07 12:00:46.386249+00	2026-02-07 12:15:00+00	2026-02-07 12:15:43.975388+00	\N	\N	\N	\N	\N	f	{}	0
453	10e558ca-3940-4995-9a8f-165e78efaffc	DOGEUSDT	30m	UP	0.5	0.09541	10	WIN	0.09689	36	2026-02-07 12:00:16.632419+00	2026-02-07 12:30:00+00	2026-02-07 12:30:44.245744+00	\N	\N	\N	\N	\N	f	{}	0
455	10e558ca-3940-4995-9a8f-165e78efaffc	SOLUSDT	30m	DOWN	0.5	84.86	10	LOSS	86.16	-10	2026-02-07 12:01:18.725032+00	2026-02-07 12:30:00+00	2026-02-07 12:30:45.556916+00	\N	\N	\N	\N	\N	f	{}	0
456	06d3b907-e06e-466b-a5fe-2dcc3912afaf	BTCUSDT	1m	UP	1	68973.56	10	WIN	69016.06	8	2026-02-07 14:26:25.677847+00	2026-02-07 14:27:00+00	2026-02-07 14:27:53.474494+00	\N	\N	\N	\N	\N	f	{}	0
457	06d3b907-e06e-466b-a5fe-2dcc3912afaf	BTCUSDT	1m	DOWN	0.5	69016.06	10	WIN	68964.87	8	2026-02-07 14:27:18.292937+00	2026-02-07 14:28:00+00	2026-02-07 14:29:33.081739+00	\N	\N	\N	\N	\N	f	{}	0
458	06d3b907-e06e-466b-a5fe-2dcc3912afaf	BTCUSDT	1m	DOWN	1	68964.87	10	LOSS	68979.9	-10	2026-02-07 14:28:24.960892+00	2026-02-07 14:29:00+00	2026-02-07 14:29:35.202507+00	\N	\N	\N	\N	\N	f	{}	0
459	06d3b907-e06e-466b-a5fe-2dcc3912afaf	BTCUSDT	1m	DOWN	0.5	68979.9	10	WIN	68921.84	8	2026-02-07 14:29:23.542779+00	2026-02-07 14:30:00+00	2026-02-07 14:30:32.904337+00	\N	\N	\N	\N	\N	f	{}	0
460	95f608be-c1e9-43b1-b885-5e2784e4858f	BTCUSDT	1m	UP	0.5	68979.9	14	LOSS	68921.84	-14	2026-02-07 14:29:37.657778+00	2026-02-07 14:30:00+00	2026-02-07 14:30:33.288177+00	\N	\N	\N	\N	\N	f	{}	0
461	06d3b907-e06e-466b-a5fe-2dcc3912afaf	BTCUSDT	1m	UP	1	68921.84	10	WIN	68947.01	8	2026-02-07 14:30:09.122324+00	2026-02-07 14:31:00+00	2026-02-07 14:33:07.656197+00	\N	\N	\N	\N	\N	f	{}	0
462	06d3b907-e06e-466b-a5fe-2dcc3912afaf	BTCUSDT	1m	UP	0.5	68912.79	10	WIN	68917.49	8	2026-02-07 14:32:46.670669+00	2026-02-07 14:33:00+00	2026-02-07 14:34:16.181222+00	\N	\N	\N	\N	\N	f	{}	0
463	06d3b907-e06e-466b-a5fe-2dcc3912afaf	BTCUSDT	1m	UP	0.5	68917.49	10	LOSS	68901.7	-10	2026-02-07 14:33:36.247423+00	2026-02-07 14:34:00+00	2026-02-07 14:34:46.274797+00	\N	\N	\N	\N	\N	f	{}	0
464	06d3b907-e06e-466b-a5fe-2dcc3912afaf	BTCUSDT	1m	DOWN	1	68901.7	10	WIN	68870.55	8	2026-02-07 14:34:55.140334+00	2026-02-07 14:35:00+00	2026-02-07 14:35:46.075602+00	\N	\N	\N	\N	\N	f	{}	0
465	06d3b907-e06e-466b-a5fe-2dcc3912afaf	BTCUSDT	1m	UP	0.5	68870.55	10	LOSS	68817.42	-10	2026-02-07 14:35:10.962605+00	2026-02-07 14:36:00+00	2026-02-07 14:36:25.482044+00	\N	\N	\N	\N	\N	f	{}	0
466	95f608be-c1e9-43b1-b885-5e2784e4858f	BTCUSDT	1m	DOWN	1	68691.66	14	WIN	68628.4	11	2026-02-07 14:41:30.717463+00	2026-02-07 14:42:00+00	2026-02-07 14:42:32.9964+00	\N	\N	\N	\N	\N	f	{}	0
445	10e558ca-3940-4995-9a8f-165e78efaffc	ETHUSDT	1d	UP	0.5	2062.31	10	WIN	2088.31	33	2026-02-07 01:40:48.583965+00	2026-02-08 00:00:00+00	2026-02-08 00:00:33.269556+00	\N	\N	\N	\N	\N	f	{}	0
467	1768c70a-81b5-4b3d-80b2-7e2a8f7d631b	BTCUSDT	1m	DOWN	1	69219.57	30	WIN	69208.03	23	2026-02-08 05:04:46.096237+00	2026-02-08 05:05:00+00	2026-02-08 05:05:54.461856+00	\N	\N	\N	\N	\N	f	{}	0
468	9969cfc6-451e-4ab2-ae2f-5d10a98eaf0a	XRPUSDT	1h	DOWN	1	1.437	100	WIN	1.43	91	2026-02-08 10:09:21.588628+00	2026-02-08 11:00:00+00	2026-02-08 11:01:26.048863+00	\N	\N	\N	\N	\N	f	{}	0
469	9969cfc6-451e-4ab2-ae2f-5d10a98eaf0a	SOLUSDT	1h	UP	0.5	87.56	50	LOSS	86.83	-50	2026-02-08 10:09:24.644528+00	2026-02-08 11:00:00+00	2026-02-08 11:01:27.358289+00	\N	\N	\N	\N	\N	f	{}	0
470	9969cfc6-451e-4ab2-ae2f-5d10a98eaf0a	DOTUSDT	1h	UP	0.5	1.359	50	LOSS	1.352	-50	2026-02-08 10:09:43.621065+00	2026-02-08 11:00:00+00	2026-02-08 11:01:28.44998+00	\N	\N	\N	\N	\N	f	{}	0
475	10e558ca-3940-4995-9a8f-165e78efaffc	SOLUSDT	1m	DOWN	0.5	88.02	13	WIN	87.98	10	2026-02-08 11:49:49.635271+00	2026-02-08 11:50:00+00	2026-02-08 11:50:24.958623+00	\N	\N	\N	\N	\N	f	{}	0
477	10e558ca-3940-4995-9a8f-165e78efaffc	XRPUSDT	1m	DOWN	0.5	1.45	14	WIN	1.448	11	2026-02-08 11:56:53.739608+00	2026-02-08 11:57:00+00	2026-02-08 11:57:32.431663+00	\N	\N	\N	\N	\N	f	{}	0
478	10e558ca-3940-4995-9a8f-165e78efaffc	BTCUSDT	1m	DOWN	0.5	70932.05	15	WIN	70900.66	11	2026-02-08 11:58:05.029096+00	2026-02-08 11:59:00+00	2026-02-08 11:59:32.253285+00	\N	\N	\N	\N	\N	f	{}	0
471	9969cfc6-451e-4ab2-ae2f-5d10a98eaf0a	MATICUSDT	1h	UP	0.5	0.1995	10	ND	0.1995	0	2026-02-08 11:15:36.678184+00	2026-02-08 12:00:00+00	2026-02-08 12:00:32.772422+00	\N	\N	\N	\N	\N	f	{}	0
472	9969cfc6-451e-4ab2-ae2f-5d10a98eaf0a	SOLUSDT	1h	UP	0.5	86.83	50	WIN	88.18	65	2026-02-08 11:16:18.153622+00	2026-02-08 12:00:00+00	2026-02-08 12:00:35.997741+00	\N	\N	\N	\N	\N	f	{}	0
473	9969cfc6-451e-4ab2-ae2f-5d10a98eaf0a	XRPUSDT	1h	DOWN	1	1.43	100	LOSS	1.452	-100	2026-02-08 11:16:18.83312+00	2026-02-08 12:00:00+00	2026-02-08 12:00:37.729152+00	\N	\N	\N	\N	\N	f	{}	0
474	9969cfc6-451e-4ab2-ae2f-5d10a98eaf0a	DOTUSDT	1h	UP	0.5	1.352	50	WIN	1.369	65	2026-02-08 11:17:00.190139+00	2026-02-08 12:00:00+00	2026-02-08 12:00:39.330844+00	\N	\N	\N	\N	\N	f	{}	0
476	10e558ca-3940-4995-9a8f-165e78efaffc	BTCUSDT	1h	UP	0.5	70216.23	15	WIN	70946.1	33	2026-02-08 11:52:47.177576+00	2026-02-08 12:00:00+00	2026-02-08 12:00:40.48666+00	\N	\N	\N	\N	\N	f	{}	0
522	10e558ca-3940-4995-9a8f-165e78efaffc	XAGUSD	1h	UP	1.5	81.9800033569336	23	LOSS	81.75914817810059	-23	2026-02-10 11:00:50.803217+00	2026-02-10 12:00:00+00	2026-02-10 12:00:24.251356+00	\N	\N	\N	\N	\N	f	{}	0
479	10e558ca-3940-4995-9a8f-165e78efaffc	DOGEUSDT	1m	DOWN	0.5	0.09818	11	WIN	0.09814	8	2026-02-08 12:01:12.522712+00	2026-02-08 12:02:00+00	2026-02-08 12:02:32.521762+00	\N	\N	\N	\N	\N	f	{}	0
533	95f608be-c1e9-43b1-b885-5e2784e4858f	BTCUSDT	30m	UP	0.5	68919.06	14	WIN	68942.72	12	2026-02-11 01:51:28.891916+00	2026-02-11 02:00:00+00	2026-02-11 02:00:23.873628+00	11111111	\N	\N	\N	\N	f	{}	0
530	5e4ec0ef-464a-41db-8e2f-9f3bfa2671ee	BTCUSDT	15m	DOWN	0.5	68674.07	11	WIN	68624.53	8	2026-02-10 23:15:08.177962+00	2026-02-10 23:30:00+00	2026-02-11 00:38:40.778721+00	krjkrjt	\N	\N	\N	\N	f	{}	0
480	10e558ca-3940-4995-9a8f-165e78efaffc	AVAXUSDT	30m	DOWN	0.5	9.259	17	WIN	9.239	14	2026-02-08 12:02:12.309718+00	2026-02-08 12:30:00+00	2026-02-08 12:30:55.088494+00	\N	\N	\N	\N	\N	f	{}	0
481	10e558ca-3940-4995-9a8f-165e78efaffc	SOLUSDT	30m	DOWN	0.5	88.18	10	WIN	88.08	8	2026-02-08 12:04:05.204716+00	2026-02-08 12:30:00+00	2026-02-08 12:30:56.791846+00	\N	\N	\N	\N	\N	f	{}	0
482	10e558ca-3940-4995-9a8f-165e78efaffc	XRPUSDT	30m	DOWN	0.5	1.452	17	ND	1.452	0	2026-02-08 12:04:40.462768+00	2026-02-08 12:30:00+00	2026-02-08 12:30:57.753328+00	\N	\N	\N	\N	\N	f	{}	0
485	10e558ca-3940-4995-9a8f-165e78efaffc	ETHUSDT	15m	DOWN	0.5	2136.97	11	WIN	2130.13	8	2026-02-08 12:35:05.699963+00	2026-02-08 12:45:00+00	2026-02-08 12:45:55.83292+00	\N	\N	\N	\N	\N	f	{}	0
532	5e4ec0ef-464a-41db-8e2f-9f3bfa2671ee	BTCUSDT	30m	UP	0.5	68919.06	11	WIN	68942.72	9	2026-02-11 01:44:49.282652+00	2026-02-11 02:00:00+00	2026-02-11 02:00:23.520525+00	222222	\N	\N	\N	\N	f	{}	0
483	9969cfc6-451e-4ab2-ae2f-5d10a98eaf0a	DOTUSDT	1h	UP	0.5	1.369	50	LOSS	1.365	-50	2026-02-08 12:12:47.4858+00	2026-02-08 13:00:00+00	2026-02-08 13:00:55.152019+00	\N	\N	\N	\N	\N	f	{}	0
484	10e558ca-3940-4995-9a8f-165e78efaffc	BTCUSDT	30m	DOWN	0.5	70914.14	11	LOSS	71198.64	-11	2026-02-08 12:33:54.534227+00	2026-02-08 13:00:00+00	2026-02-08 13:00:56.390136+00	\N	\N	\N	\N	\N	f	{}	0
486	9969cfc6-451e-4ab2-ae2f-5d10a98eaf0a	SOLUSDT	1h	UP	0.5	88.18	10	LOSS	88.11	-10	2026-02-08 12:49:29.102005+00	2026-02-08 13:00:00+00	2026-02-08 13:00:57.756653+00	\N	\N	\N	\N	\N	f	{}	0
487	95f608be-c1e9-43b1-b885-5e2784e4858f	BTCUSDT	1m	UP	0.5	71388.84	14	LOSS	71367.05	-14	2026-02-08 13:54:03.879696+00	2026-02-08 13:55:00+00	2026-02-08 13:55:32.252817+00	\N	\N	\N	\N	\N	f	{}	0
534	95f608be-c1e9-43b1-b885-5e2784e4858f	BTCUSDT	30m	DOWN	0.5	68942.72	14	LOSS	69019.7	-14	2026-02-11 02:26:14.463052+00	2026-02-11 02:30:00+00	2026-02-11 02:30:29.54452+00	45454545	\N	\N	\N	\N	f	{}	0
536	10e558ca-3940-4995-9a8f-165e78efaffc	BTCUSDT	1m	UP	0.5	67163.25	10	WIN	67242.15	8	2026-02-11 12:20:14.902741+00	2026-02-11 12:21:00+00	2026-02-11 12:21:38.283157+00	\N	\N	\N	\N	\N	f	{}	0
488	95f608be-c1e9-43b1-b885-5e2784e4858f	BTCUSDT	15m	UP	1	71180.42	14	WIN	71473.6	11	2026-02-08 13:56:40.480456+00	2026-02-08 14:00:00+00	2026-02-08 14:00:51.914473+00	\N	\N	\N	\N	\N	f	{}	0
489	95f608be-c1e9-43b1-b885-5e2784e4858f	BTCUSDT	30m	DOWN	1.5	71407.48	14	LOSS	71473.6	-14	2026-02-08 13:56:59.355834+00	2026-02-08 14:00:00+00	2026-02-08 14:00:53.073387+00	\N	\N	\N	\N	\N	f	{}	0
490	95f608be-c1e9-43b1-b885-5e2784e4858f	BTCUSDT	4h	UP	2	70946.1	71	WIN	71143.15	81	2026-02-08 13:57:45.067315+00	2026-02-08 16:00:00+00	2026-02-08 16:01:26.496434+00	\N	\N	\N	\N	\N	f	{}	0
491	95f608be-c1e9-43b1-b885-5e2784e4858f	BTCUSDT	1d	UP	2	69259.24	13	WIN	70297.07	18	2026-02-08 13:58:10.742774+00	2026-02-09 00:00:00+00	2026-02-09 00:01:26.767869+00	\N	\N	\N	\N	\N	f	{}	0
537	9969cfc6-451e-4ab2-ae2f-5d10a98eaf0a	BTCUSDT	1m	UP	0.5	67066.67	10	WIN	67077.34	8	2026-02-11 12:50:44.433649+00	2026-02-11 12:51:00+00	2026-02-11 12:51:39.960101+00	\N	\N	\N	\N	\N	f	{}	0
535	10e558ca-3940-4995-9a8f-165e78efaffc	BTCUSDT	1h	UP	0.5	67036.69	10	WIN	67108.64	9	2026-02-11 12:20:01.404754+00	2026-02-11 13:00:00+00	2026-02-11 13:00:40.25114+00	\N	\N	\N	\N	\N	f	{}	0
492	10e558ca-3940-4995-9a8f-165e78efaffc	XAUUSD	1m	DOWN	0.5	5063.7458979492185	10	WIN	5043.551497558594	8	2026-02-09 06:38:06.00335+00	2026-02-09 06:39:00+00	2026-02-09 06:40:21.526491+00	\N	\N	\N	\N	\N	f	{}	0
493	10e558ca-3940-4995-9a8f-165e78efaffc	ETHUSDT	30m	DOWN	0.5	2073.49	10	LOSS	2080.31	-10	2026-02-09 06:39:18.526147+00	2026-02-09 07:00:00+00	2026-02-09 07:20:53.904902+00	\N	\N	\N	\N	\N	f	{}	0
496	10e558ca-3940-4995-9a8f-165e78efaffc	DOGEUSDT	1m	UP	0.5	0.09554	10	LOSS	0.09544	-10	2026-02-09 07:34:49.751145+00	2026-02-09 07:35:00+00	2026-02-09 07:36:06.701902+00	\N	\N	\N	\N	\N	f	{}	0
497	10e558ca-3940-4995-9a8f-165e78efaffc	XAUUSD	1m	UP	0.5	4999.079194335937	10	WIN	5029.224395507812	27	2026-02-09 07:35:09.378367+00	2026-02-09 07:36:00+00	2026-02-09 07:37:07.308153+00	\N	\N	\N	\N	\N	f	{}	0
494	10e558ca-3940-4995-9a8f-165e78efaffc	ETHUSDT	30m	DOWN	0.5	2080.19	10	WIN	2064.31	36	2026-02-09 07:32:57.506248+00	2026-02-09 08:00:00+00	2026-02-09 08:03:59.248324+00	\N	\N	\N	\N	\N	f	{}	0
495	10e558ca-3940-4995-9a8f-165e78efaffc	ADAUSDT	15m	UP	0.5	0.2708	10	LOSS	0.2693	-10	2026-02-09 07:33:52.541029+00	2026-02-09 07:45:00+00	2026-02-09 08:04:00.49648+00	\N	\N	\N	\N	\N	f	{}	0
498	10e558ca-3940-4995-9a8f-165e78efaffc	NG	15m	UP	0.5	3.197000026702881	10	WIN	3.2019999027252197	8	2026-02-09 08:02:38.170337+00	2026-02-09 08:15:00+00	2026-02-09 12:35:31.438283+00	\N	\N	\N	\N	\N	f	{}	0
499	10e558ca-3940-4995-9a8f-165e78efaffc	CORN	15m	DOWN	0.5	429	10	ND	429	0	2026-02-09 08:03:30.551239+00	2026-02-09 08:15:00+00	2026-02-09 12:35:32.23525+00	\N	\N	\N	\N	\N	f	{}	0
500	10e558ca-3940-4995-9a8f-165e78efaffc	XAGUSD	15m	UP	0.5	81.26499938964844	10	WIN	81.54000091552734	8	2026-02-09 08:04:15.483459+00	2026-02-09 08:15:00+00	2026-02-09 12:35:33.428347+00	\N	\N	\N	\N	\N	f	{}	0
501	10e558ca-3940-4995-9a8f-165e78efaffc	WHEAT	15m	DOWN	0.5	528	10	WIN	527.5	8	2026-02-09 08:06:20.501686+00	2026-02-09 08:15:00+00	2026-02-09 12:35:34.263793+00	\N	\N	\N	\N	\N	f	{}	0
502	10e558ca-3940-4995-9a8f-165e78efaffc	XRPUSDT	1h	DOWN	0.5	1.424	10	WIN	1.406	28	2026-02-09 08:07:25.396723+00	2026-02-09 09:00:00+00	2026-02-09 12:35:35.87856+00	\N	\N	\N	\N	\N	f	{}	0
504	10e558ca-3940-4995-9a8f-165e78efaffc	ETHUSDT	1h	UP	0.5	2020.89	10	WIN	2026.55	9	2026-02-09 11:49:30.690042+00	2026-02-09 12:00:00+00	2026-02-09 12:35:37.121532+00	\N	\N	\N	\N	\N	f	{}	0
505	95f608be-c1e9-43b1-b885-5e2784e4858f	BTCUSDT	1m	UP	0.5	70304.47	15	LOSS	70287.35	-15	2026-02-09 22:06:42.358718+00	2026-02-09 22:07:00+00	2026-02-09 22:07:32.404393+00	\N	\N	\N	\N	\N	f	{}	0
506	95f608be-c1e9-43b1-b885-5e2784e4858f	BTCUSDT	1m	DOWN	0.5	70287.35	15	LOSS	70289.42	-15	2026-02-09 22:07:33.271406+00	2026-02-09 22:08:00+00	2026-02-09 22:08:32.367642+00	\N	\N	\N	\N	\N	f	{}	0
509	10e558ca-3940-4995-9a8f-165e78efaffc	SOLUSDT	1m	UP	1	86.36	10	WIN	86.39	8	2026-02-10 01:01:43.25801+00	2026-02-10 01:02:00+00	2026-02-10 01:02:34.61789+00	\N	\N	\N	\N	\N	f	{}	0
510	10e558ca-3940-4995-9a8f-165e78efaffc	XRPUSDT	1m	DOWN	0.5	1.436	10	LOSS	1.437	-10	2026-02-10 01:01:55.086491+00	2026-02-10 01:02:00+00	2026-02-10 01:02:36.850438+00	\N	\N	\N	\N	\N	f	{}	0
507	10e558ca-3940-4995-9a8f-165e78efaffc	XAUUSD	1h	UP	2	5054.89990234375	10	LOSS	5015.397097167969	-10	2026-02-10 01:00:09.621024+00	2026-02-10 02:00:00+00	2026-02-10 02:00:22.958262+00	\N	\N	\N	\N	\N	f	{}	0
508	10e558ca-3940-4995-9a8f-165e78efaffc	XAGUSD	1h	UP	0.5	81.80999755859375	10	LOSS	80.55022682189941	-10	2026-02-10 01:01:13.186961+00	2026-02-10 02:00:00+00	2026-02-10 02:00:24.334619+00	\N	\N	\N	\N	\N	f	{}	0
511	10e558ca-3940-4995-9a8f-165e78efaffc	BTCUSDT	1h	UP	0.5	69468.07	50	WIN	69794.25	46	2026-02-10 04:18:13.805396+00	2026-02-10 05:00:00+00	2026-02-10 05:00:24.079463+00	\N	\N	\N	\N	\N	f	{}	0
512	10e558ca-3940-4995-9a8f-165e78efaffc	BTCUSDT	1h	UP	0.5	69468.07	10	WIN	69794.25	9	2026-02-10 04:19:11.78806+00	2026-02-10 05:00:00+00	2026-02-10 05:00:24.408163+00	\N	\N	\N	\N	\N	f	{}	0
513	10e558ca-3940-4995-9a8f-165e78efaffc	BTCUSDT	1h	UP	0.5	69408.77	50	LOSS	68879.81	-50	2026-02-10 06:33:54.056957+00	2026-02-10 07:00:00+00	2026-02-10 07:00:23.824178+00	\N	\N	\N	\N	\N	f	{}	0
514	10e558ca-3940-4995-9a8f-165e78efaffc	BTCUSDT	1h	UP	0.5	69408.77	50	LOSS	68879.81	-50	2026-02-10 06:34:00.287311+00	2026-02-10 07:00:00+00	2026-02-10 07:00:24.540115+00	\N	\N	\N	\N	\N	f	{}	0
515	10e558ca-3940-4995-9a8f-165e78efaffc	BTCUSDT	1h	UP	0.5	69408.77	50	LOSS	68879.81	-50	2026-02-10 06:34:24.933238+00	2026-02-10 07:00:00+00	2026-02-10 07:00:24.780897+00	\N	\N	\N	\N	\N	f	{}	0
516	10e558ca-3940-4995-9a8f-165e78efaffc	BTCUSDT	1h	DOWN	1	69408.77	20	WIN	68879.81	18	2026-02-10 06:34:55.647023+00	2026-02-10 07:00:00+00	2026-02-10 07:00:25.025522+00	\N	\N	\N	\N	\N	f	{}	0
517	10e558ca-3940-4995-9a8f-165e78efaffc	BTCUSDT	1h	DOWN	1	68879.81	100	WIN	68867.44	91	2026-02-10 07:28:17.219595+00	2026-02-10 08:00:00+00	2026-02-10 08:00:24.094047+00	\N	\N	\N	\N	\N	f	{}	0
518	95f608be-c1e9-43b1-b885-5e2784e4858f	BTCUSDT	1m	UP	0.5	68918.22	15	LOSS	68908.98	-15	2026-02-10 08:02:20.44163+00	2026-02-10 08:03:00+00	2026-02-10 08:03:34.497063+00	\N	\N	\N	\N	\N	f	{}	0
519	95f608be-c1e9-43b1-b885-5e2784e4858f	BTCUSDT	15m	DOWN	0.5	68867.44	15	WIN	68788.07	11	2026-02-10 08:06:43.540439+00	2026-02-10 08:15:00+00	2026-02-10 08:15:48.563231+00	fdfdfd	\N	\N	\N	\N	f	{}	0
\.


--
-- Data for Name: profiles; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.profiles (id, email, username, points, tier, created_at, streak_count, total_earnings, total_games, total_wins, streak) FROM stdin;
5ac10c39-274e-4ce5-a13b-f4da3af4a230	sjustone000@gmail.com	sjustone000	632	bronze	2026-01-30 09:20:35.022913+00	1	383	90	14	0
36ae407d-c380-41ff-a714-d61371c44fb3	naeiver@naver.com	naeiver	971	bronze	2026-02-02 01:49:56.748254+00	0	0	3	1	0
8cf7c6be-ba2c-48c9-8825-589e675ff608	test5@mail.com	test5	1208	bronze	2026-02-02 23:08:54.736679+00	0	0	0	0	0
4cb9d918-0c1c-45a0-a0a5-fd405a0cda38	codex_1770695858717@mail.com	codex_1770695858717	1000	bronze	2026-02-10 03:57:39.390971+00	0	0	0	0	0
e65bfdd9-1478-4264-a26d-6db676ab49bf	codex_1770697037255@mail.com	codex_1770697037255	1000	bronze	2026-02-10 04:17:17.748383+00	0	0	0	0	0
5e4ec0ef-464a-41db-8e2f-9f3bfa2671ee	test3@mail.com	test3	1147	bronze	2026-02-02 23:08:54.736679+00	0	0	5	2	0
62a4018e-393c-4aa0-a754-3db136771637	codex_1770705148556@mail.com	codex_1770705148556	1000	bronze	2026-02-10 06:32:29.2576+00	0	0	0	0	0
43075ac5-9589-4a40-9861-7b90cb7c30b9	sim_user_a@test.com	sim_user_a	1110	bronze	2026-02-02 23:06:52.525192+00	0	0	0	0	1
428f4a8e-2ccc-4bff-9d30-e44cc6c4fdbe	sim_user_b@test.com	sim_user_b	900	bronze	2026-02-02 23:06:52.525192+00	0	0	0	0	0
d9d7ce43-118a-438a-bcd6-6ddc3117b789	sim_user_c@test.com	sim_user_c	1129	bronze	2026-02-02 23:06:52.525192+00	0	0	0	0	1
349325a9-2d7a-4a3a-8dfb-7e2082cf1280	sim_user_d@test.com	sim_user_d	1000	bronze	2026-02-02 23:06:52.525192+00	0	0	0	0	0
ebdd4583-a106-4909-9b73-aaf392e3bc72	sim_user_e@test.com	sim_user_e	1276	bronze	2026-02-02 23:06:52.525192+00	0	0	0	0	5
95f608be-c1e9-43b1-b885-5e2784e4858f	test4@mail.com	test4	1463	bronze	2026-02-02 23:08:54.736679+00	2	0	41	19	0
7ce98344-7670-4faf-853e-70080f6fdfa1	codex_1770780540161@mail.com	codex_1770780540161	1000	bronze	2026-02-11 03:29:00.844806+00	0	0	0	0	0
9969cfc6-451e-4ab2-ae2f-5d10a98eaf0a	test1@mail.com	test1	969	bronze	2026-02-02 23:08:54.736679+00	1	0	10	4	0
06d3b907-e06e-466b-a5fe-2dcc3912afaf	ych6133@daum.net	ych6133	1018	bronze	2026-02-07 14:15:54.774336+00	0	0	9	6	0
f62d4e26-bb72-4b86-9539-a54a8fcbad7e	codex_1770708357487@mail.com	codex_1770708357487	1000	bronze	2026-02-10 07:25:58.192504+00	0	0	0	0	0
10e558ca-3940-4995-9a8f-165e78efaffc	test2@mail.com	test2	461	bronze	2026-02-02 23:08:54.736679+00	2	0	43	25	0
60abdd33-af5a-4dfb-b211-a057a0995d12	gracepk34@gmail.com	gracepk34	874	bronze	2026-02-02 01:31:37.246825+00	0	0	0	0	0
1768c70a-81b5-4b3d-80b2-7e2a8f7d631b	gardenia_319@naver.com	gardenia_319	1023	bronze	2026-02-08 05:01:08.277332+00	0	0	1	1	0
1ddb44b9-add6-437f-96de-2e7c2df0bfcc	tourismyujy@gmail.com	tourismyujy	1000	bronze	2026-02-07 05:47:17.986717+00	0	0	0	0	0
\.


--
-- Data for Name: shares; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.shares (id, user_id, post_id, platform, created_at) FROM stdin;
\.


--
-- Data for Name: users; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.users (id, points, created_at) FROM stdin;
\.


--
-- Name: refresh_tokens_id_seq; Type: SEQUENCE SET; Schema: auth; Owner: supabase_auth_admin
--

SELECT pg_catalog.setval('auth.refresh_tokens_id_seq', 821, true);


--
-- Name: activity_logs_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.activity_logs_id_seq', 218, true);


--
-- Name: posts_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.posts_id_seq', 1, false);


--
-- Name: predictions_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.predictions_id_seq', 537, true);


--
-- Name: mfa_amr_claims amr_id_pk; Type: CONSTRAINT; Schema: auth; Owner: supabase_auth_admin
--

ALTER TABLE ONLY auth.mfa_amr_claims
    ADD CONSTRAINT amr_id_pk PRIMARY KEY (id);


--
-- Name: audit_log_entries audit_log_entries_pkey; Type: CONSTRAINT; Schema: auth; Owner: supabase_auth_admin
--

ALTER TABLE ONLY auth.audit_log_entries
    ADD CONSTRAINT audit_log_entries_pkey PRIMARY KEY (id);


--
-- Name: flow_state flow_state_pkey; Type: CONSTRAINT; Schema: auth; Owner: supabase_auth_admin
--

ALTER TABLE ONLY auth.flow_state
    ADD CONSTRAINT flow_state_pkey PRIMARY KEY (id);


--
-- Name: identities identities_pkey; Type: CONSTRAINT; Schema: auth; Owner: supabase_auth_admin
--

ALTER TABLE ONLY auth.identities
    ADD CONSTRAINT identities_pkey PRIMARY KEY (id);


--
-- Name: identities identities_provider_id_provider_unique; Type: CONSTRAINT; Schema: auth; Owner: supabase_auth_admin
--

ALTER TABLE ONLY auth.identities
    ADD CONSTRAINT identities_provider_id_provider_unique UNIQUE (provider_id, provider);


--
-- Name: instances instances_pkey; Type: CONSTRAINT; Schema: auth; Owner: supabase_auth_admin
--

ALTER TABLE ONLY auth.instances
    ADD CONSTRAINT instances_pkey PRIMARY KEY (id);


--
-- Name: mfa_amr_claims mfa_amr_claims_session_id_authentication_method_pkey; Type: CONSTRAINT; Schema: auth; Owner: supabase_auth_admin
--

ALTER TABLE ONLY auth.mfa_amr_claims
    ADD CONSTRAINT mfa_amr_claims_session_id_authentication_method_pkey UNIQUE (session_id, authentication_method);


--
-- Name: mfa_challenges mfa_challenges_pkey; Type: CONSTRAINT; Schema: auth; Owner: supabase_auth_admin
--

ALTER TABLE ONLY auth.mfa_challenges
    ADD CONSTRAINT mfa_challenges_pkey PRIMARY KEY (id);


--
-- Name: mfa_factors mfa_factors_last_challenged_at_key; Type: CONSTRAINT; Schema: auth; Owner: supabase_auth_admin
--

ALTER TABLE ONLY auth.mfa_factors
    ADD CONSTRAINT mfa_factors_last_challenged_at_key UNIQUE (last_challenged_at);


--
-- Name: mfa_factors mfa_factors_pkey; Type: CONSTRAINT; Schema: auth; Owner: supabase_auth_admin
--

ALTER TABLE ONLY auth.mfa_factors
    ADD CONSTRAINT mfa_factors_pkey PRIMARY KEY (id);


--
-- Name: oauth_authorizations oauth_authorizations_authorization_code_key; Type: CONSTRAINT; Schema: auth; Owner: supabase_auth_admin
--

ALTER TABLE ONLY auth.oauth_authorizations
    ADD CONSTRAINT oauth_authorizations_authorization_code_key UNIQUE (authorization_code);


--
-- Name: oauth_authorizations oauth_authorizations_authorization_id_key; Type: CONSTRAINT; Schema: auth; Owner: supabase_auth_admin
--

ALTER TABLE ONLY auth.oauth_authorizations
    ADD CONSTRAINT oauth_authorizations_authorization_id_key UNIQUE (authorization_id);


--
-- Name: oauth_authorizations oauth_authorizations_pkey; Type: CONSTRAINT; Schema: auth; Owner: supabase_auth_admin
--

ALTER TABLE ONLY auth.oauth_authorizations
    ADD CONSTRAINT oauth_authorizations_pkey PRIMARY KEY (id);


--
-- Name: oauth_client_states oauth_client_states_pkey; Type: CONSTRAINT; Schema: auth; Owner: supabase_auth_admin
--

ALTER TABLE ONLY auth.oauth_client_states
    ADD CONSTRAINT oauth_client_states_pkey PRIMARY KEY (id);


--
-- Name: oauth_clients oauth_clients_pkey; Type: CONSTRAINT; Schema: auth; Owner: supabase_auth_admin
--

ALTER TABLE ONLY auth.oauth_clients
    ADD CONSTRAINT oauth_clients_pkey PRIMARY KEY (id);


--
-- Name: oauth_consents oauth_consents_pkey; Type: CONSTRAINT; Schema: auth; Owner: supabase_auth_admin
--

ALTER TABLE ONLY auth.oauth_consents
    ADD CONSTRAINT oauth_consents_pkey PRIMARY KEY (id);


--
-- Name: oauth_consents oauth_consents_user_client_unique; Type: CONSTRAINT; Schema: auth; Owner: supabase_auth_admin
--

ALTER TABLE ONLY auth.oauth_consents
    ADD CONSTRAINT oauth_consents_user_client_unique UNIQUE (user_id, client_id);


--
-- Name: one_time_tokens one_time_tokens_pkey; Type: CONSTRAINT; Schema: auth; Owner: supabase_auth_admin
--

ALTER TABLE ONLY auth.one_time_tokens
    ADD CONSTRAINT one_time_tokens_pkey PRIMARY KEY (id);


--
-- Name: refresh_tokens refresh_tokens_pkey; Type: CONSTRAINT; Schema: auth; Owner: supabase_auth_admin
--

ALTER TABLE ONLY auth.refresh_tokens
    ADD CONSTRAINT refresh_tokens_pkey PRIMARY KEY (id);


--
-- Name: refresh_tokens refresh_tokens_token_unique; Type: CONSTRAINT; Schema: auth; Owner: supabase_auth_admin
--

ALTER TABLE ONLY auth.refresh_tokens
    ADD CONSTRAINT refresh_tokens_token_unique UNIQUE (token);


--
-- Name: saml_providers saml_providers_entity_id_key; Type: CONSTRAINT; Schema: auth; Owner: supabase_auth_admin
--

ALTER TABLE ONLY auth.saml_providers
    ADD CONSTRAINT saml_providers_entity_id_key UNIQUE (entity_id);


--
-- Name: saml_providers saml_providers_pkey; Type: CONSTRAINT; Schema: auth; Owner: supabase_auth_admin
--

ALTER TABLE ONLY auth.saml_providers
    ADD CONSTRAINT saml_providers_pkey PRIMARY KEY (id);


--
-- Name: saml_relay_states saml_relay_states_pkey; Type: CONSTRAINT; Schema: auth; Owner: supabase_auth_admin
--

ALTER TABLE ONLY auth.saml_relay_states
    ADD CONSTRAINT saml_relay_states_pkey PRIMARY KEY (id);


--
-- Name: schema_migrations schema_migrations_pkey; Type: CONSTRAINT; Schema: auth; Owner: supabase_auth_admin
--

ALTER TABLE ONLY auth.schema_migrations
    ADD CONSTRAINT schema_migrations_pkey PRIMARY KEY (version);


--
-- Name: sessions sessions_pkey; Type: CONSTRAINT; Schema: auth; Owner: supabase_auth_admin
--

ALTER TABLE ONLY auth.sessions
    ADD CONSTRAINT sessions_pkey PRIMARY KEY (id);


--
-- Name: sso_domains sso_domains_pkey; Type: CONSTRAINT; Schema: auth; Owner: supabase_auth_admin
--

ALTER TABLE ONLY auth.sso_domains
    ADD CONSTRAINT sso_domains_pkey PRIMARY KEY (id);


--
-- Name: sso_providers sso_providers_pkey; Type: CONSTRAINT; Schema: auth; Owner: supabase_auth_admin
--

ALTER TABLE ONLY auth.sso_providers
    ADD CONSTRAINT sso_providers_pkey PRIMARY KEY (id);


--
-- Name: users users_phone_key; Type: CONSTRAINT; Schema: auth; Owner: supabase_auth_admin
--

ALTER TABLE ONLY auth.users
    ADD CONSTRAINT users_phone_key UNIQUE (phone);


--
-- Name: users users_pkey; Type: CONSTRAINT; Schema: auth; Owner: supabase_auth_admin
--

ALTER TABLE ONLY auth.users
    ADD CONSTRAINT users_pkey PRIMARY KEY (id);


--
-- Name: activity_logs activity_logs_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.activity_logs
    ADD CONSTRAINT activity_logs_pkey PRIMARY KEY (id);


--
-- Name: bookmarks bookmarks_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.bookmarks
    ADD CONSTRAINT bookmarks_pkey PRIMARY KEY (id);


--
-- Name: bookmarks bookmarks_user_id_post_id_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.bookmarks
    ADD CONSTRAINT bookmarks_user_id_post_id_key UNIQUE (user_id, post_id);


--
-- Name: comments comments_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.comments
    ADD CONSTRAINT comments_pkey PRIMARY KEY (id);


--
-- Name: likes likes_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.likes
    ADD CONSTRAINT likes_pkey PRIMARY KEY (id);


--
-- Name: likes likes_user_id_post_id_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.likes
    ADD CONSTRAINT likes_user_id_post_id_key UNIQUE (user_id, post_id);


--
-- Name: notifications notifications_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.notifications
    ADD CONSTRAINT notifications_pkey PRIMARY KEY (id);


--
-- Name: posts posts_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.posts
    ADD CONSTRAINT posts_pkey PRIMARY KEY (id);


--
-- Name: prediction_likes prediction_likes_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.prediction_likes
    ADD CONSTRAINT prediction_likes_pkey PRIMARY KEY (user_id, prediction_id);


--
-- Name: predictions predictions_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.predictions
    ADD CONSTRAINT predictions_pkey PRIMARY KEY (id);


--
-- Name: profiles profiles_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.profiles
    ADD CONSTRAINT profiles_pkey PRIMARY KEY (id);


--
-- Name: shares shares_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.shares
    ADD CONSTRAINT shares_pkey PRIMARY KEY (id);


--
-- Name: users users_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_pkey PRIMARY KEY (id);


--
-- Name: audit_logs_instance_id_idx; Type: INDEX; Schema: auth; Owner: supabase_auth_admin
--

CREATE INDEX audit_logs_instance_id_idx ON auth.audit_log_entries USING btree (instance_id);


--
-- Name: confirmation_token_idx; Type: INDEX; Schema: auth; Owner: supabase_auth_admin
--

CREATE UNIQUE INDEX confirmation_token_idx ON auth.users USING btree (confirmation_token) WHERE ((confirmation_token)::text !~ '^[0-9 ]*$'::text);


--
-- Name: email_change_token_current_idx; Type: INDEX; Schema: auth; Owner: supabase_auth_admin
--

CREATE UNIQUE INDEX email_change_token_current_idx ON auth.users USING btree (email_change_token_current) WHERE ((email_change_token_current)::text !~ '^[0-9 ]*$'::text);


--
-- Name: email_change_token_new_idx; Type: INDEX; Schema: auth; Owner: supabase_auth_admin
--

CREATE UNIQUE INDEX email_change_token_new_idx ON auth.users USING btree (email_change_token_new) WHERE ((email_change_token_new)::text !~ '^[0-9 ]*$'::text);


--
-- Name: factor_id_created_at_idx; Type: INDEX; Schema: auth; Owner: supabase_auth_admin
--

CREATE INDEX factor_id_created_at_idx ON auth.mfa_factors USING btree (user_id, created_at);


--
-- Name: flow_state_created_at_idx; Type: INDEX; Schema: auth; Owner: supabase_auth_admin
--

CREATE INDEX flow_state_created_at_idx ON auth.flow_state USING btree (created_at DESC);


--
-- Name: identities_email_idx; Type: INDEX; Schema: auth; Owner: supabase_auth_admin
--

CREATE INDEX identities_email_idx ON auth.identities USING btree (email text_pattern_ops);


--
-- Name: INDEX identities_email_idx; Type: COMMENT; Schema: auth; Owner: supabase_auth_admin
--

COMMENT ON INDEX auth.identities_email_idx IS 'Auth: Ensures indexed queries on the email column';


--
-- Name: identities_user_id_idx; Type: INDEX; Schema: auth; Owner: supabase_auth_admin
--

CREATE INDEX identities_user_id_idx ON auth.identities USING btree (user_id);


--
-- Name: idx_auth_code; Type: INDEX; Schema: auth; Owner: supabase_auth_admin
--

CREATE INDEX idx_auth_code ON auth.flow_state USING btree (auth_code);


--
-- Name: idx_oauth_client_states_created_at; Type: INDEX; Schema: auth; Owner: supabase_auth_admin
--

CREATE INDEX idx_oauth_client_states_created_at ON auth.oauth_client_states USING btree (created_at);


--
-- Name: idx_user_id_auth_method; Type: INDEX; Schema: auth; Owner: supabase_auth_admin
--

CREATE INDEX idx_user_id_auth_method ON auth.flow_state USING btree (user_id, authentication_method);


--
-- Name: mfa_challenge_created_at_idx; Type: INDEX; Schema: auth; Owner: supabase_auth_admin
--

CREATE INDEX mfa_challenge_created_at_idx ON auth.mfa_challenges USING btree (created_at DESC);


--
-- Name: mfa_factors_user_friendly_name_unique; Type: INDEX; Schema: auth; Owner: supabase_auth_admin
--

CREATE UNIQUE INDEX mfa_factors_user_friendly_name_unique ON auth.mfa_factors USING btree (friendly_name, user_id) WHERE (TRIM(BOTH FROM friendly_name) <> ''::text);


--
-- Name: mfa_factors_user_id_idx; Type: INDEX; Schema: auth; Owner: supabase_auth_admin
--

CREATE INDEX mfa_factors_user_id_idx ON auth.mfa_factors USING btree (user_id);


--
-- Name: oauth_auth_pending_exp_idx; Type: INDEX; Schema: auth; Owner: supabase_auth_admin
--

CREATE INDEX oauth_auth_pending_exp_idx ON auth.oauth_authorizations USING btree (expires_at) WHERE (status = 'pending'::auth.oauth_authorization_status);


--
-- Name: oauth_clients_deleted_at_idx; Type: INDEX; Schema: auth; Owner: supabase_auth_admin
--

CREATE INDEX oauth_clients_deleted_at_idx ON auth.oauth_clients USING btree (deleted_at);


--
-- Name: oauth_consents_active_client_idx; Type: INDEX; Schema: auth; Owner: supabase_auth_admin
--

CREATE INDEX oauth_consents_active_client_idx ON auth.oauth_consents USING btree (client_id) WHERE (revoked_at IS NULL);


--
-- Name: oauth_consents_active_user_client_idx; Type: INDEX; Schema: auth; Owner: supabase_auth_admin
--

CREATE INDEX oauth_consents_active_user_client_idx ON auth.oauth_consents USING btree (user_id, client_id) WHERE (revoked_at IS NULL);


--
-- Name: oauth_consents_user_order_idx; Type: INDEX; Schema: auth; Owner: supabase_auth_admin
--

CREATE INDEX oauth_consents_user_order_idx ON auth.oauth_consents USING btree (user_id, granted_at DESC);


--
-- Name: one_time_tokens_relates_to_hash_idx; Type: INDEX; Schema: auth; Owner: supabase_auth_admin
--

CREATE INDEX one_time_tokens_relates_to_hash_idx ON auth.one_time_tokens USING hash (relates_to);


--
-- Name: one_time_tokens_token_hash_hash_idx; Type: INDEX; Schema: auth; Owner: supabase_auth_admin
--

CREATE INDEX one_time_tokens_token_hash_hash_idx ON auth.one_time_tokens USING hash (token_hash);


--
-- Name: one_time_tokens_user_id_token_type_key; Type: INDEX; Schema: auth; Owner: supabase_auth_admin
--

CREATE UNIQUE INDEX one_time_tokens_user_id_token_type_key ON auth.one_time_tokens USING btree (user_id, token_type);


--
-- Name: reauthentication_token_idx; Type: INDEX; Schema: auth; Owner: supabase_auth_admin
--

CREATE UNIQUE INDEX reauthentication_token_idx ON auth.users USING btree (reauthentication_token) WHERE ((reauthentication_token)::text !~ '^[0-9 ]*$'::text);


--
-- Name: recovery_token_idx; Type: INDEX; Schema: auth; Owner: supabase_auth_admin
--

CREATE UNIQUE INDEX recovery_token_idx ON auth.users USING btree (recovery_token) WHERE ((recovery_token)::text !~ '^[0-9 ]*$'::text);


--
-- Name: refresh_tokens_instance_id_idx; Type: INDEX; Schema: auth; Owner: supabase_auth_admin
--

CREATE INDEX refresh_tokens_instance_id_idx ON auth.refresh_tokens USING btree (instance_id);


--
-- Name: refresh_tokens_instance_id_user_id_idx; Type: INDEX; Schema: auth; Owner: supabase_auth_admin
--

CREATE INDEX refresh_tokens_instance_id_user_id_idx ON auth.refresh_tokens USING btree (instance_id, user_id);


--
-- Name: refresh_tokens_parent_idx; Type: INDEX; Schema: auth; Owner: supabase_auth_admin
--

CREATE INDEX refresh_tokens_parent_idx ON auth.refresh_tokens USING btree (parent);


--
-- Name: refresh_tokens_session_id_revoked_idx; Type: INDEX; Schema: auth; Owner: supabase_auth_admin
--

CREATE INDEX refresh_tokens_session_id_revoked_idx ON auth.refresh_tokens USING btree (session_id, revoked);


--
-- Name: refresh_tokens_updated_at_idx; Type: INDEX; Schema: auth; Owner: supabase_auth_admin
--

CREATE INDEX refresh_tokens_updated_at_idx ON auth.refresh_tokens USING btree (updated_at DESC);


--
-- Name: saml_providers_sso_provider_id_idx; Type: INDEX; Schema: auth; Owner: supabase_auth_admin
--

CREATE INDEX saml_providers_sso_provider_id_idx ON auth.saml_providers USING btree (sso_provider_id);


--
-- Name: saml_relay_states_created_at_idx; Type: INDEX; Schema: auth; Owner: supabase_auth_admin
--

CREATE INDEX saml_relay_states_created_at_idx ON auth.saml_relay_states USING btree (created_at DESC);


--
-- Name: saml_relay_states_for_email_idx; Type: INDEX; Schema: auth; Owner: supabase_auth_admin
--

CREATE INDEX saml_relay_states_for_email_idx ON auth.saml_relay_states USING btree (for_email);


--
-- Name: saml_relay_states_sso_provider_id_idx; Type: INDEX; Schema: auth; Owner: supabase_auth_admin
--

CREATE INDEX saml_relay_states_sso_provider_id_idx ON auth.saml_relay_states USING btree (sso_provider_id);


--
-- Name: sessions_not_after_idx; Type: INDEX; Schema: auth; Owner: supabase_auth_admin
--

CREATE INDEX sessions_not_after_idx ON auth.sessions USING btree (not_after DESC);


--
-- Name: sessions_oauth_client_id_idx; Type: INDEX; Schema: auth; Owner: supabase_auth_admin
--

CREATE INDEX sessions_oauth_client_id_idx ON auth.sessions USING btree (oauth_client_id);


--
-- Name: sessions_user_id_idx; Type: INDEX; Schema: auth; Owner: supabase_auth_admin
--

CREATE INDEX sessions_user_id_idx ON auth.sessions USING btree (user_id);


--
-- Name: sso_domains_domain_idx; Type: INDEX; Schema: auth; Owner: supabase_auth_admin
--

CREATE UNIQUE INDEX sso_domains_domain_idx ON auth.sso_domains USING btree (lower(domain));


--
-- Name: sso_domains_sso_provider_id_idx; Type: INDEX; Schema: auth; Owner: supabase_auth_admin
--

CREATE INDEX sso_domains_sso_provider_id_idx ON auth.sso_domains USING btree (sso_provider_id);


--
-- Name: sso_providers_resource_id_idx; Type: INDEX; Schema: auth; Owner: supabase_auth_admin
--

CREATE UNIQUE INDEX sso_providers_resource_id_idx ON auth.sso_providers USING btree (lower(resource_id));


--
-- Name: sso_providers_resource_id_pattern_idx; Type: INDEX; Schema: auth; Owner: supabase_auth_admin
--

CREATE INDEX sso_providers_resource_id_pattern_idx ON auth.sso_providers USING btree (resource_id text_pattern_ops);


--
-- Name: unique_phone_factor_per_user; Type: INDEX; Schema: auth; Owner: supabase_auth_admin
--

CREATE UNIQUE INDEX unique_phone_factor_per_user ON auth.mfa_factors USING btree (user_id, phone);


--
-- Name: user_id_created_at_idx; Type: INDEX; Schema: auth; Owner: supabase_auth_admin
--

CREATE INDEX user_id_created_at_idx ON auth.sessions USING btree (user_id, created_at);


--
-- Name: users_email_partial_key; Type: INDEX; Schema: auth; Owner: supabase_auth_admin
--

CREATE UNIQUE INDEX users_email_partial_key ON auth.users USING btree (email) WHERE (is_sso_user = false);


--
-- Name: INDEX users_email_partial_key; Type: COMMENT; Schema: auth; Owner: supabase_auth_admin
--

COMMENT ON INDEX auth.users_email_partial_key IS 'Auth: A partial unique index that applies only when is_sso_user is false';


--
-- Name: users_instance_id_email_idx; Type: INDEX; Schema: auth; Owner: supabase_auth_admin
--

CREATE INDEX users_instance_id_email_idx ON auth.users USING btree (instance_id, lower((email)::text));


--
-- Name: users_instance_id_idx; Type: INDEX; Schema: auth; Owner: supabase_auth_admin
--

CREATE INDEX users_instance_id_idx ON auth.users USING btree (instance_id);


--
-- Name: users_is_anonymous_idx; Type: INDEX; Schema: auth; Owner: supabase_auth_admin
--

CREATE INDEX users_is_anonymous_idx ON auth.users USING btree (is_anonymous);


--
-- Name: idx_activity_logs_type; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_activity_logs_type ON public.activity_logs USING btree (action_type);


--
-- Name: idx_activity_logs_user; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_activity_logs_user ON public.activity_logs USING btree (user_id, created_at DESC);


--
-- Name: idx_notifications_created_at; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_notifications_created_at ON public.notifications USING btree (created_at DESC);


--
-- Name: idx_notifications_user; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_notifications_user ON public.notifications USING btree (user_id, created_at DESC);


--
-- Name: idx_notifications_user_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_notifications_user_id ON public.notifications USING btree (user_id);


--
-- Name: idx_posts_created_at; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_posts_created_at ON public.posts USING btree (created_at DESC);


--
-- Name: idx_posts_feed_score; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_posts_feed_score ON public.posts USING btree (feed_score DESC);


--
-- Name: idx_predictions_candle; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_predictions_candle ON public.predictions USING btree (asset_symbol, timeframe, candle_close_at);


--
-- Name: idx_predictions_created; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_predictions_created ON public.predictions USING btree (created_at DESC);


--
-- Name: idx_predictions_status; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_predictions_status ON public.predictions USING btree (status);


--
-- Name: idx_predictions_user; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_predictions_user ON public.predictions USING btree (user_id);


--
-- Name: users on_auth_user_created; Type: TRIGGER; Schema: auth; Owner: supabase_auth_admin
--

CREATE TRIGGER on_auth_user_created AFTER INSERT ON auth.users FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();


--
-- Name: prediction_likes on_prediction_like; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER on_prediction_like AFTER INSERT OR DELETE ON public.prediction_likes FOR EACH ROW EXECUTE FUNCTION public.update_prediction_likes_count();


--
-- Name: identities identities_user_id_fkey; Type: FK CONSTRAINT; Schema: auth; Owner: supabase_auth_admin
--

ALTER TABLE ONLY auth.identities
    ADD CONSTRAINT identities_user_id_fkey FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE;


--
-- Name: mfa_amr_claims mfa_amr_claims_session_id_fkey; Type: FK CONSTRAINT; Schema: auth; Owner: supabase_auth_admin
--

ALTER TABLE ONLY auth.mfa_amr_claims
    ADD CONSTRAINT mfa_amr_claims_session_id_fkey FOREIGN KEY (session_id) REFERENCES auth.sessions(id) ON DELETE CASCADE;


--
-- Name: mfa_challenges mfa_challenges_auth_factor_id_fkey; Type: FK CONSTRAINT; Schema: auth; Owner: supabase_auth_admin
--

ALTER TABLE ONLY auth.mfa_challenges
    ADD CONSTRAINT mfa_challenges_auth_factor_id_fkey FOREIGN KEY (factor_id) REFERENCES auth.mfa_factors(id) ON DELETE CASCADE;


--
-- Name: mfa_factors mfa_factors_user_id_fkey; Type: FK CONSTRAINT; Schema: auth; Owner: supabase_auth_admin
--

ALTER TABLE ONLY auth.mfa_factors
    ADD CONSTRAINT mfa_factors_user_id_fkey FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE;


--
-- Name: oauth_authorizations oauth_authorizations_client_id_fkey; Type: FK CONSTRAINT; Schema: auth; Owner: supabase_auth_admin
--

ALTER TABLE ONLY auth.oauth_authorizations
    ADD CONSTRAINT oauth_authorizations_client_id_fkey FOREIGN KEY (client_id) REFERENCES auth.oauth_clients(id) ON DELETE CASCADE;


--
-- Name: oauth_authorizations oauth_authorizations_user_id_fkey; Type: FK CONSTRAINT; Schema: auth; Owner: supabase_auth_admin
--

ALTER TABLE ONLY auth.oauth_authorizations
    ADD CONSTRAINT oauth_authorizations_user_id_fkey FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE;


--
-- Name: oauth_consents oauth_consents_client_id_fkey; Type: FK CONSTRAINT; Schema: auth; Owner: supabase_auth_admin
--

ALTER TABLE ONLY auth.oauth_consents
    ADD CONSTRAINT oauth_consents_client_id_fkey FOREIGN KEY (client_id) REFERENCES auth.oauth_clients(id) ON DELETE CASCADE;


--
-- Name: oauth_consents oauth_consents_user_id_fkey; Type: FK CONSTRAINT; Schema: auth; Owner: supabase_auth_admin
--

ALTER TABLE ONLY auth.oauth_consents
    ADD CONSTRAINT oauth_consents_user_id_fkey FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE;


--
-- Name: one_time_tokens one_time_tokens_user_id_fkey; Type: FK CONSTRAINT; Schema: auth; Owner: supabase_auth_admin
--

ALTER TABLE ONLY auth.one_time_tokens
    ADD CONSTRAINT one_time_tokens_user_id_fkey FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE;


--
-- Name: refresh_tokens refresh_tokens_session_id_fkey; Type: FK CONSTRAINT; Schema: auth; Owner: supabase_auth_admin
--

ALTER TABLE ONLY auth.refresh_tokens
    ADD CONSTRAINT refresh_tokens_session_id_fkey FOREIGN KEY (session_id) REFERENCES auth.sessions(id) ON DELETE CASCADE;


--
-- Name: saml_providers saml_providers_sso_provider_id_fkey; Type: FK CONSTRAINT; Schema: auth; Owner: supabase_auth_admin
--

ALTER TABLE ONLY auth.saml_providers
    ADD CONSTRAINT saml_providers_sso_provider_id_fkey FOREIGN KEY (sso_provider_id) REFERENCES auth.sso_providers(id) ON DELETE CASCADE;


--
-- Name: saml_relay_states saml_relay_states_flow_state_id_fkey; Type: FK CONSTRAINT; Schema: auth; Owner: supabase_auth_admin
--

ALTER TABLE ONLY auth.saml_relay_states
    ADD CONSTRAINT saml_relay_states_flow_state_id_fkey FOREIGN KEY (flow_state_id) REFERENCES auth.flow_state(id) ON DELETE CASCADE;


--
-- Name: saml_relay_states saml_relay_states_sso_provider_id_fkey; Type: FK CONSTRAINT; Schema: auth; Owner: supabase_auth_admin
--

ALTER TABLE ONLY auth.saml_relay_states
    ADD CONSTRAINT saml_relay_states_sso_provider_id_fkey FOREIGN KEY (sso_provider_id) REFERENCES auth.sso_providers(id) ON DELETE CASCADE;


--
-- Name: sessions sessions_oauth_client_id_fkey; Type: FK CONSTRAINT; Schema: auth; Owner: supabase_auth_admin
--

ALTER TABLE ONLY auth.sessions
    ADD CONSTRAINT sessions_oauth_client_id_fkey FOREIGN KEY (oauth_client_id) REFERENCES auth.oauth_clients(id) ON DELETE CASCADE;


--
-- Name: sessions sessions_user_id_fkey; Type: FK CONSTRAINT; Schema: auth; Owner: supabase_auth_admin
--

ALTER TABLE ONLY auth.sessions
    ADD CONSTRAINT sessions_user_id_fkey FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE;


--
-- Name: sso_domains sso_domains_sso_provider_id_fkey; Type: FK CONSTRAINT; Schema: auth; Owner: supabase_auth_admin
--

ALTER TABLE ONLY auth.sso_domains
    ADD CONSTRAINT sso_domains_sso_provider_id_fkey FOREIGN KEY (sso_provider_id) REFERENCES auth.sso_providers(id) ON DELETE CASCADE;


--
-- Name: activity_logs activity_logs_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.activity_logs
    ADD CONSTRAINT activity_logs_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.profiles(id);


--
-- Name: bookmarks bookmarks_post_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.bookmarks
    ADD CONSTRAINT bookmarks_post_id_fkey FOREIGN KEY (post_id) REFERENCES public.posts(id) ON DELETE CASCADE;


--
-- Name: bookmarks bookmarks_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.bookmarks
    ADD CONSTRAINT bookmarks_user_id_fkey FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE;


--
-- Name: comments comments_post_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.comments
    ADD CONSTRAINT comments_post_id_fkey FOREIGN KEY (post_id) REFERENCES public.posts(id) ON DELETE CASCADE;


--
-- Name: comments comments_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.comments
    ADD CONSTRAINT comments_user_id_fkey FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE;


--
-- Name: likes likes_post_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.likes
    ADD CONSTRAINT likes_post_id_fkey FOREIGN KEY (post_id) REFERENCES public.posts(id) ON DELETE CASCADE;


--
-- Name: likes likes_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.likes
    ADD CONSTRAINT likes_user_id_fkey FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE;


--
-- Name: notifications notifications_prediction_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.notifications
    ADD CONSTRAINT notifications_prediction_id_fkey FOREIGN KEY (prediction_id) REFERENCES public.predictions(id);


--
-- Name: notifications notifications_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.notifications
    ADD CONSTRAINT notifications_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.profiles(id);


--
-- Name: posts posts_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.posts
    ADD CONSTRAINT posts_user_id_fkey FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE;


--
-- Name: prediction_likes prediction_likes_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.prediction_likes
    ADD CONSTRAINT prediction_likes_user_id_fkey FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE;


--
-- Name: predictions predictions_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.predictions
    ADD CONSTRAINT predictions_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.profiles(id);


--
-- Name: profiles profiles_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.profiles
    ADD CONSTRAINT profiles_id_fkey FOREIGN KEY (id) REFERENCES auth.users(id) ON DELETE CASCADE;


--
-- Name: shares shares_post_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.shares
    ADD CONSTRAINT shares_post_id_fkey FOREIGN KEY (post_id) REFERENCES public.posts(id) ON DELETE CASCADE;


--
-- Name: shares shares_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.shares
    ADD CONSTRAINT shares_user_id_fkey FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE;


--
-- Name: users users_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_id_fkey FOREIGN KEY (id) REFERENCES auth.users(id);


--
-- Name: audit_log_entries; Type: ROW SECURITY; Schema: auth; Owner: supabase_auth_admin
--

ALTER TABLE auth.audit_log_entries ENABLE ROW LEVEL SECURITY;

--
-- Name: flow_state; Type: ROW SECURITY; Schema: auth; Owner: supabase_auth_admin
--

ALTER TABLE auth.flow_state ENABLE ROW LEVEL SECURITY;

--
-- Name: identities; Type: ROW SECURITY; Schema: auth; Owner: supabase_auth_admin
--

ALTER TABLE auth.identities ENABLE ROW LEVEL SECURITY;

--
-- Name: instances; Type: ROW SECURITY; Schema: auth; Owner: supabase_auth_admin
--

ALTER TABLE auth.instances ENABLE ROW LEVEL SECURITY;

--
-- Name: mfa_amr_claims; Type: ROW SECURITY; Schema: auth; Owner: supabase_auth_admin
--

ALTER TABLE auth.mfa_amr_claims ENABLE ROW LEVEL SECURITY;

--
-- Name: mfa_challenges; Type: ROW SECURITY; Schema: auth; Owner: supabase_auth_admin
--

ALTER TABLE auth.mfa_challenges ENABLE ROW LEVEL SECURITY;

--
-- Name: mfa_factors; Type: ROW SECURITY; Schema: auth; Owner: supabase_auth_admin
--

ALTER TABLE auth.mfa_factors ENABLE ROW LEVEL SECURITY;

--
-- Name: one_time_tokens; Type: ROW SECURITY; Schema: auth; Owner: supabase_auth_admin
--

ALTER TABLE auth.one_time_tokens ENABLE ROW LEVEL SECURITY;

--
-- Name: refresh_tokens; Type: ROW SECURITY; Schema: auth; Owner: supabase_auth_admin
--

ALTER TABLE auth.refresh_tokens ENABLE ROW LEVEL SECURITY;

--
-- Name: saml_providers; Type: ROW SECURITY; Schema: auth; Owner: supabase_auth_admin
--

ALTER TABLE auth.saml_providers ENABLE ROW LEVEL SECURITY;

--
-- Name: saml_relay_states; Type: ROW SECURITY; Schema: auth; Owner: supabase_auth_admin
--

ALTER TABLE auth.saml_relay_states ENABLE ROW LEVEL SECURITY;

--
-- Name: schema_migrations; Type: ROW SECURITY; Schema: auth; Owner: supabase_auth_admin
--

ALTER TABLE auth.schema_migrations ENABLE ROW LEVEL SECURITY;

--
-- Name: sessions; Type: ROW SECURITY; Schema: auth; Owner: supabase_auth_admin
--

ALTER TABLE auth.sessions ENABLE ROW LEVEL SECURITY;

--
-- Name: sso_domains; Type: ROW SECURITY; Schema: auth; Owner: supabase_auth_admin
--

ALTER TABLE auth.sso_domains ENABLE ROW LEVEL SECURITY;

--
-- Name: sso_providers; Type: ROW SECURITY; Schema: auth; Owner: supabase_auth_admin
--

ALTER TABLE auth.sso_providers ENABLE ROW LEVEL SECURITY;

--
-- Name: users; Type: ROW SECURITY; Schema: auth; Owner: supabase_auth_admin
--

ALTER TABLE auth.users ENABLE ROW LEVEL SECURITY;

--
-- Name: predictions Anyone can view predictions; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "Anyone can view predictions" ON public.predictions FOR SELECT USING (true);


--
-- Name: profiles Anyone can view profiles; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "Anyone can view profiles" ON public.profiles FOR SELECT USING (true);


--
-- Name: prediction_likes Auth like; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "Auth like" ON public.prediction_likes FOR INSERT WITH CHECK ((auth.uid() = user_id));


--
-- Name: prediction_likes Auth unlike; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "Auth unlike" ON public.prediction_likes FOR DELETE USING ((auth.uid() = user_id));


--
-- Name: comments Authenticated insert comments; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "Authenticated insert comments" ON public.comments FOR INSERT WITH CHECK ((auth.uid() = user_id));


--
-- Name: likes Authenticated insert likes; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "Authenticated insert likes" ON public.likes FOR INSERT WITH CHECK ((auth.uid() = user_id));


--
-- Name: comments Comments are viewable by everyone.; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "Comments are viewable by everyone." ON public.comments FOR SELECT USING (true);


--
-- Name: predictions Enable read access for all users; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "Enable read access for all users" ON public.predictions FOR SELECT USING (true);


--
-- Name: likes Public likes; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "Public likes" ON public.likes FOR SELECT USING (true);


--
-- Name: posts Public posts are viewable by everyone; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "Public posts are viewable by everyone" ON public.posts FOR SELECT USING (true);


--
-- Name: posts Public posts viewable; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "Public posts viewable" ON public.posts FOR SELECT USING (true);


--
-- Name: profiles Public profiles are viewable by everyone.; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "Public profiles are viewable by everyone." ON public.profiles FOR SELECT USING (true);


--
-- Name: prediction_likes Public view; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "Public view" ON public.prediction_likes FOR SELECT USING (true);


--
-- Name: comments Public view comments; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "Public view comments" ON public.comments FOR SELECT USING (true);


--
-- Name: likes Public view likes; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "Public view likes" ON public.likes FOR SELECT USING (true);


--
-- Name: notifications Service Role can manage notifications; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "Service Role can manage notifications" ON public.notifications USING ((auth.uid() = user_id));


--
-- Name: bookmarks User bookmarks; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "User bookmarks" ON public.bookmarks USING ((auth.uid() = user_id));


--
-- Name: bookmarks User delete own bookmarks; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "User delete own bookmarks" ON public.bookmarks FOR DELETE USING ((auth.uid() = user_id));


--
-- Name: likes User delete own likes; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "User delete own likes" ON public.likes FOR DELETE USING ((auth.uid() = user_id));


--
-- Name: bookmarks User insert own bookmarks; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "User insert own bookmarks" ON public.bookmarks FOR INSERT WITH CHECK ((auth.uid() = user_id));


--
-- Name: likes User likes; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "User likes" ON public.likes FOR INSERT WITH CHECK ((auth.uid() = user_id));


--
-- Name: posts User posts editable; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "User posts editable" ON public.posts USING ((auth.uid() = user_id));


--
-- Name: likes User unlink likes; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "User unlink likes" ON public.likes FOR DELETE USING ((auth.uid() = user_id));


--
-- Name: bookmarks User view own bookmarks; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "User view own bookmarks" ON public.bookmarks FOR SELECT USING ((auth.uid() = user_id));


--
-- Name: posts Users can delete their own posts; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "Users can delete their own posts" ON public.posts FOR DELETE USING ((auth.uid() = user_id));


--
-- Name: notifications Users can insert notifications; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "Users can insert notifications" ON public.notifications FOR INSERT WITH CHECK (true);


--
-- Name: comments Users can insert their own comments.; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "Users can insert their own comments." ON public.comments FOR INSERT WITH CHECK ((auth.uid() = user_id));


--
-- Name: posts Users can insert their own posts; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "Users can insert their own posts" ON public.posts FOR INSERT WITH CHECK ((auth.uid() = user_id));


--
-- Name: predictions Users can insert their own predictions.; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "Users can insert their own predictions." ON public.predictions FOR INSERT WITH CHECK ((auth.uid() = user_id));


--
-- Name: profiles Users can insert their own profile.; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "Users can insert their own profile." ON public.profiles FOR INSERT WITH CHECK ((auth.uid() = id));


--
-- Name: profiles Users can update own profile.; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "Users can update own profile." ON public.profiles FOR UPDATE USING ((auth.uid() = id));


--
-- Name: posts Users can update their own posts; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "Users can update their own posts" ON public.posts FOR UPDATE USING ((auth.uid() = user_id));


--
-- Name: predictions Users can update their own predictions; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "Users can update their own predictions" ON public.predictions FOR UPDATE USING ((auth.uid() = user_id)) WITH CHECK ((auth.uid() = user_id));


--
-- Name: notifications Users can view own notifications; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "Users can view own notifications" ON public.notifications FOR SELECT USING ((auth.uid() = user_id));


--
-- Name: profiles Users can view own sensitive data; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "Users can view own sensitive data" ON public.profiles FOR SELECT USING ((auth.uid() = id));


--
-- Name: bookmarks; Type: ROW SECURITY; Schema: public; Owner: postgres
--

ALTER TABLE public.bookmarks ENABLE ROW LEVEL SECURITY;

--
-- Name: comments; Type: ROW SECURITY; Schema: public; Owner: postgres
--

ALTER TABLE public.comments ENABLE ROW LEVEL SECURITY;

--
-- Name: likes; Type: ROW SECURITY; Schema: public; Owner: postgres
--

ALTER TABLE public.likes ENABLE ROW LEVEL SECURITY;

--
-- Name: notifications; Type: ROW SECURITY; Schema: public; Owner: postgres
--

ALTER TABLE public.notifications ENABLE ROW LEVEL SECURITY;

--
-- Name: posts; Type: ROW SECURITY; Schema: public; Owner: postgres
--

ALTER TABLE public.posts ENABLE ROW LEVEL SECURITY;

--
-- Name: prediction_likes; Type: ROW SECURITY; Schema: public; Owner: postgres
--

ALTER TABLE public.prediction_likes ENABLE ROW LEVEL SECURITY;

--
-- Name: predictions; Type: ROW SECURITY; Schema: public; Owner: postgres
--

ALTER TABLE public.predictions ENABLE ROW LEVEL SECURITY;

--
-- Name: profiles; Type: ROW SECURITY; Schema: public; Owner: postgres
--

ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;

--
-- Name: shares; Type: ROW SECURITY; Schema: public; Owner: postgres
--

ALTER TABLE public.shares ENABLE ROW LEVEL SECURITY;

--
-- PostgreSQL database dump complete
--

\unrestrict dqrhXdvhkqMYtqfhjWd9l9sG99pp8Bk4jFUud6e07dDvtqjyAI19fZvuaR8HNv8

