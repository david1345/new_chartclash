-- 1. Schema Updates
alter table public.profiles 
add column if not exists streak_count int default 0,
add column if not exists total_earnings numeric default 0; -- Track "Skill Score" base

alter table public.predictions 
add column if not exists bet_amount int default 0,
add column if not exists payout_amount int default 0,
add column if not exists multipliers jsonb default '{}'::jsonb;

-- 2. Advanced Resolution Function
create or replace function public.resolve_prediction_advanced(
  p_id bigint, 
  p_close_price numeric
)
returns jsonb
language plpgsql
security definer
as $$
declare
  v_pred record;
  v_user_profile record;
  v_status text;
  v_is_target_hit boolean := false;
  v_actual_change numeric;
  
  -- Multipliers
  v_tf_mult numeric := 1.0;
  v_vol_mult numeric := 1.0;
  v_crowd_mult numeric := 1.0;
  v_streak_mult numeric := 1.0;
  v_house_edge numeric := 0.92;
  
  -- Crowd calc
  v_total_votes int;
  v_same_side_votes int;
  v_crowd_ratio numeric;
  v_rarity numeric;
  
  v_raw_reward numeric;
  v_final_reward int;
  v_net_change int;
  
begin
  -- Get prediction
  select * into v_pred from public.predictions where id = p_id;
  if not found then return jsonb_build_object('error', 'Prediction not found'); end if;

  -- Get User Profile (for streak)
  select * into v_user_profile from public.profiles where id = v_pred.user_id;

  -- 1. Determine Status (WIN/LOSE/ND)
  v_actual_change := round(((p_close_price - v_pred.entry_price) / v_pred.entry_price) * 100, 4);

  if round(p_close_price, 2) = round(v_pred.entry_price, 2) then
    v_status := 'ND';
  elsif v_pred.direction = 'UP' then
    if p_close_price > v_pred.entry_price then v_status := 'WIN'; else v_status := 'LOSE'; end if;
  elsif v_pred.direction = 'DOWN' then
    if p_close_price < v_pred.entry_price then v_status := 'WIN'; else v_status := 'LOSE'; end if;
  end if;

  -- 2. Target Hit Check (Must be WIN to qualify for reward in this model? 
  --    User said "Target Multiplier" applies. Usually implies if you HIT the target.
  --    Let's assume: If Status is WIN, we check if Target Hit. 
  --    If Target NOT Hit, maybe just standard reward? Or LOSE?
  --    User Logic: "Target % Multiplier (Difficulty)". 
  --    Implies you MUST hit the target to get that multiplier? 
  --    OR is it just "Because you chose high risk, you get high reward IF you win direction?"
  --    Re-reading: "큰 수익 = 더 어려움". "Target % Multiplier".
  --    Case A: "15m / 0.5%". Result: WIN direction. 
  --    If deviation < 0.5%, do they win?
  --    Actually, usually "Target" in these games means a Strike Price.
  --    Let's assume strictly: MUST HIT TARGET to WIN.
  --    User: "상승은 마감가>시작가이면 WIN... 반대로..." (Earlier prompt).
  --    BUT New Prompt: "Target % Multiplier...".
  --    Let's Hybrid: 
  --      - If Direction Wrong -> LOSE
  --      - If Direction Right BUT Target Not Hit -> WIN (Base Reward? OR LOSE?)
  --      - User examples show "Reward = Bet * ... * TargetMult".
  --      - This implies you selected the Target difficulty beforehand.
  --      - If you select 2% and it only moves 1%, you likely FAIL the specific bet condition?
  --      - Let's implement Strict: MUST hit target percent to WIN.
  --      - Wait, user said "Diff > starts... WIN. Percent... ONLY calculate if WIN".
  --      - This implies Direction is the primary Win Condition.
  --      - But then "Target Multiplier" is applied.
  --      - Usage: IF (Direction Correct AND Change >= Target) THEN Pay Reward (with Target Mult).
  --      - IF (Direction Correct BUT Change < Target) THEN LOSE? Or Small Reward?
  --      - "High Risk High Return". If I bet 2% and only get 1%, I should probably Lose or get reduced.
  --      - Let's go with STRICT: You chose the difficulty. You must clear the bar.
  
  if v_status = 'WIN' then
    if abs(v_actual_change) >= v_pred.target_percent then
      v_is_target_hit := true;
    else
      -- Did not hit target. Downgrade to LOSE? Or just 0 multiplier?
      -- For "Game" mechanics, usually it's "Close, but no cigar" -> LOSE.
      v_status := 'LOSE'; -- Strict Mode
    end if;
  end if;

  -- 3. Calculate Reward (Only if WIN)
  if v_status = 'WIN' then
  
    -- A. Timeframe Mult
    if v_pred.timeframe = '15m' then v_tf_mult := 1.0;
    elsif v_pred.timeframe = '30m' then v_tf_mult := 1.2;
    elsif v_pred.timeframe = '1h' then v_tf_mult := 1.5;
    elsif v_pred.timeframe = '4h' then v_tf_mult := 2.2;
    elsif v_pred.timeframe = '1d' then v_tf_mult := 3.5;
    end if;

    -- B. Volatility Mult
    if v_pred.target_percent <= 0.5 then v_vol_mult := 1.0;
    elsif v_pred.target_percent <= 1.0 then v_vol_mult := 1.6;
    elsif v_pred.target_percent <= 1.5 then v_vol_mult := 2.4;
    else v_vol_mult := 3.5; -- 2.0%+
    end if;

    -- C. Crowd Mult (Contrarian Bonus)
    -- Count total preds for this candle
    select count(*), count(*) filter (where direction = v_pred.direction)
    into v_total_votes, v_same_side_votes
    from public.predictions
    where asset_symbol = v_pred.asset_symbol 
      and timeframe = v_pred.timeframe
      -- Approximate time bucket match (created within same candle window)
      -- For simplicity, we use the record's candle time if we stored it, or just generic logic
      -- Here we assume 'resolve' happens batch-wise or id-wise. 
      -- Let's stick to simple logic: predictions created within +/- 5 mins of this one?
      -- OR better: created between open_time and lock_time.
      -- Since we don't strictly store 'candle_id', we'll approximate:
      and created_at between v_pred.created_at - interval '1 day' and v_pred.created_at + interval '1 day'; 
      -- (Actually, for accurate crowd, we need exact window. 
      --  But for now, let's use a simplified constant or logic.
      --  Assuming single active round per asset/tf).
      
    if v_total_votes > 0 then
      v_crowd_ratio := v_same_side_votes::numeric / v_total_votes::numeric;
    else
      v_crowd_ratio := 0.5; -- Default
    end if;

    -- Formula: 1 + min((1 - ratio) * 0.8, 0.8)
    -- If 90% agree (ratio 0.9) -> rarity 0.1 -> mult 1.08
    -- If 10% agree (ratio 0.1) -> rarity 0.9 -> mult 1.72
    v_rarity := 1.0 - v_crowd_ratio;
    v_crowd_mult := 1.0 + least(v_rarity * 0.8, 0.8);
    v_crowd_mult := round(v_crowd_mult, 2);

    -- D. Streak Mult
    if v_user_profile.streak_count < 2 then v_streak_mult := 1.0;
    elsif v_user_profile.streak_count < 4 then v_streak_mult := 1.1; -- 2-3
    elsif v_user_profile.streak_count < 6 then v_streak_mult := 1.25; -- 4-5
    else v_streak_mult := 1.4; -- 6+
    end if;

    -- CALC FINAL
    v_raw_reward := v_pred.bet_amount * v_tf_mult * v_vol_mult * v_crowd_mult * v_streak_mult;
    v_final_reward := floor(v_raw_reward * v_house_edge);
    v_net_change := v_final_reward; -- Net profit to add (Bet was already deducted)

  elsif v_status = 'ND' then
    -- Refund Bet
    v_final_reward := v_pred.bet_amount;
    v_net_change := 0; -- No profit, just refund
  else
    -- LOSE
    v_final_reward := 0;
    v_net_change := -v_pred.bet_amount; -- Was already deducted, effectively lost
  end if;

  -- 4. Execute Transaction updates
  -- Update Prediction
  update public.predictions
  set 
    close_price = p_close_price,
    actual_change_percent = v_actual_change,
    status = v_status,
    is_target_hit = v_is_target_hit,
    payout_amount = v_final_reward,
    resolved_at = now(),
    multipliers = jsonb_build_object(
      'timeframe', v_tf_mult,
      'volatility', v_vol_mult,
      'crowd', v_crowd_mult,
      'streak', v_streak_mult,
      'raw_payout', v_final_reward
    )
  where id = p_id;

  -- Update Profile Points & Streak
  if v_status = 'WIN' then
    update public.profiles 
    set 
      points = points + v_pred.bet_amount + v_final_reward, -- Return Bet + Profit
      streak_count = streak_count + 1,
      total_earnings = total_earnings + v_final_reward
    where id = v_pred.user_id;
  elsif v_status = 'LOSE' then
    update public.profiles 
    set 
      streak_count = 0 -- Reset streak
      -- Points already deducted at entry
    where id = v_pred.user_id;
  elsif v_status = 'ND' then
    update public.profiles 
    set points = points + v_pred.bet_amount -- Refund
    where id = v_pred.user_id;
  end if;

  return jsonb_build_object(
    'id', p_id, 
    'status', v_status, 
    'payout', v_final_reward,
    'multiplier', v_crowd_mult
  );
end;
$$;
