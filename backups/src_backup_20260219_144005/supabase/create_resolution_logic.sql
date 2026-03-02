-- 1. Updates to predictions table (ensure columns exist)
alter table public.predictions 
add column if not exists close_price numeric,
add column if not exists actual_change_percent numeric,
add column if not exists is_direction_correct boolean default false,
add column if not exists is_target_hit boolean default false;

-- 2. Update status constraint to include 'ND'
alter table public.predictions 
drop constraint if exists predictions_status_check;

alter table public.predictions 
add constraint predictions_status_check 
check (status in ('pending', 'WIN', 'LOSE', 'ND'));

-- 3. Create/Replace the resolution logic function
create or replace function public.resolve_prediction(
  p_id bigint, 
  p_close_price numeric
)
returns jsonb
language plpgsql
security definer
as $$
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
