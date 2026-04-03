-- ChartClash USDT-only canonical Supabase schema
-- Date: 2026-03-29
--
-- What this file does
-- - removes legacy points/streak gameplay columns and RPC dependencies
-- - aligns Supabase with the current on-chain USDT-only runtime
-- - keeps Supabase as auth/app-data/mirror storage, not the money ledger
-- - adds compatibility RPCs and triggers used by the current app
--
-- Safe mode
-- - This file is written to be idempotent for in-place migration.
-- - If you want a clean rebuild, drop the public schema first and then run this file.

begin;

create extension if not exists pgcrypto;

create or replace function public.set_current_timestamp()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

create or replace function public.asset_category_for_symbol(p_symbol text)
returns text
language sql
immutable
as $$
  select case upper(coalesce(p_symbol, ''))
    when 'AAPL' then 'STOCKS'
    when 'NVDA' then 'STOCKS'
    when 'TSLA' then 'STOCKS'
    when 'MSFT' then 'STOCKS'
    when 'AMZN' then 'STOCKS'
    when 'GOOGL' then 'STOCKS'
    when 'META' then 'STOCKS'
    when 'NFLX' then 'STOCKS'
    when 'AMD' then 'STOCKS'
    when 'INTC' then 'STOCKS'
    when 'XAUUSD' then 'COMMODITIES'
    when 'XAGUSD' then 'COMMODITIES'
    when 'WTI' then 'COMMODITIES'
    when 'NG' then 'COMMODITIES'
    when 'CORN' then 'COMMODITIES'
    when 'SOY' then 'COMMODITIES'
    when 'WHEAT' then 'COMMODITIES'
    when 'HG' then 'COMMODITIES'
    when 'PL' then 'COMMODITIES'
    when 'PA' then 'COMMODITIES'
    else 'CRYPTO'
  end;
$$;

create or replace function public.asset_name_for_symbol(p_symbol text)
returns text
language sql
immutable
as $$
  select case upper(coalesce(p_symbol, ''))
    when 'BTCUSDT' then 'Bitcoin'
    when 'ETHUSDT' then 'Ethereum'
    when 'SOLUSDT' then 'Solana'
    when 'XRPUSDT' then 'Ripple'
    when 'DOGEUSDT' then 'Dogecoin'
    when 'ADAUSDT' then 'Cardano'
    when 'AVAXUSDT' then 'Avalanche'
    when 'DOTUSDT' then 'Polkadot'
    when 'LINKUSDT' then 'Chainlink'
    when 'MATICUSDT' then 'Polygon'
    when 'AAPL' then 'Apple'
    when 'NVDA' then 'Nvidia'
    when 'TSLA' then 'Tesla'
    when 'MSFT' then 'Microsoft'
    when 'AMZN' then 'Amazon'
    when 'GOOGL' then 'Google'
    when 'META' then 'Meta'
    when 'NFLX' then 'Netflix'
    when 'AMD' then 'AMD'
    when 'INTC' then 'Intel'
    when 'XAUUSD' then 'Gold'
    when 'XAGUSD' then 'Silver'
    when 'WTI' then 'Crude Oil'
    when 'NG' then 'Natural Gas'
    when 'CORN' then 'Corn'
    when 'SOY' then 'Soybeans'
    when 'WHEAT' then 'Wheat'
    when 'HG' then 'Copper'
    when 'PL' then 'Platinum'
    when 'PA' then 'Palladium'
    else upper(coalesce(p_symbol, 'UNKNOWN'))
  end;
$$;

create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  email text,
  username text,
  avatar_url text,
  tier text not null default 'verified',
  is_bot boolean not null default false,
  total_games integer not null default 0,
  total_wins integer not null default 0,
  total_earnings integer not null default 0,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table public.profiles add column if not exists email text;
alter table public.profiles add column if not exists username text;
alter table public.profiles add column if not exists avatar_url text;
alter table public.profiles add column if not exists tier text not null default 'verified';
alter table public.profiles add column if not exists is_bot boolean not null default false;
alter table public.profiles add column if not exists total_games integer not null default 0;
alter table public.profiles add column if not exists total_wins integer not null default 0;
alter table public.profiles add column if not exists total_earnings integer not null default 0;
alter table public.profiles add column if not exists created_at timestamptz not null default now();
alter table public.profiles add column if not exists updated_at timestamptz not null default now();

alter table public.profiles drop column if exists points;
alter table public.profiles drop column if exists streak;
alter table public.profiles drop column if exists streak_count;

drop trigger if exists profiles_set_current_timestamp on public.profiles;
create trigger profiles_set_current_timestamp
before update on public.profiles
for each row
execute function public.set_current_timestamp();

create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
as $$
begin
  insert into public.profiles (id, email, username)
  values (new.id, new.email, split_part(coalesce(new.email, 'trader'), '@', 1))
  on conflict (id) do update
    set email = excluded.email,
        username = coalesce(public.profiles.username, excluded.username),
        updated_at = now();
  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
after insert on auth.users
for each row
execute procedure public.handle_new_user();

create table if not exists public.predictions (
  id bigint generated by default as identity primary key,
  user_id uuid not null references public.profiles(id) on delete cascade,
  asset_symbol text not null,
  timeframe text not null,
  direction text not null,
  target_percent numeric not null default 0,
  entry_price numeric not null,
  bet_amount integer not null,
  status text not null default 'pending',
  actual_price numeric,
  profit integer not null default 0,
  created_at timestamptz not null default now(),
  candle_close_at timestamptz not null default now(),
  resolved_at timestamptz,
  comment text,
  likes_count integer not null default 0,
  is_opinion boolean not null default false,
  channel text not null default 'market',
  round_time timestamptz
);

alter table public.predictions add column if not exists timeframe text;
alter table public.predictions add column if not exists target_percent numeric not null default 0;
alter table public.predictions add column if not exists bet_amount integer not null default 0;
alter table public.predictions add column if not exists actual_price numeric;
alter table public.predictions add column if not exists profit integer not null default 0;
alter table public.predictions add column if not exists candle_close_at timestamptz not null default now();
alter table public.predictions add column if not exists resolved_at timestamptz;
alter table public.predictions add column if not exists comment text;
alter table public.predictions add column if not exists likes_count integer not null default 0;
alter table public.predictions add column if not exists is_opinion boolean not null default false;
alter table public.predictions add column if not exists channel text not null default 'market';
alter table public.predictions add column if not exists round_time timestamptz;

alter table public.predictions drop column if exists candle_close_time;

alter table public.predictions alter column timeframe set default '1h';
alter table public.predictions alter column target_percent set default 0;
alter table public.predictions alter column bet_amount set default 0;
alter table public.predictions alter column likes_count set default 0;
alter table public.predictions alter column is_opinion set default false;
alter table public.predictions alter column channel set default 'market';
alter table public.predictions alter column status set default 'pending';
alter table public.predictions alter column profit set default 0;

do $$
begin
  if exists (
    select 1 from pg_constraint
    where conname = 'predictions_direction_check'
      and conrelid = 'public.predictions'::regclass
  ) then
    alter table public.predictions drop constraint predictions_direction_check;
  end if;
end;
$$;

alter table public.predictions
  add constraint predictions_direction_check
  check (direction in ('UP', 'DOWN'));

do $$
begin
  if exists (
    select 1 from pg_constraint
    where conname = 'predictions_status_check'
      and conrelid = 'public.predictions'::regclass
  ) then
    alter table public.predictions drop constraint predictions_status_check;
  end if;
end;
$$;

alter table public.predictions
  add constraint predictions_status_check
  check (status in ('pending', 'WIN', 'LOSS', 'ND', 'REFUND'));

create table if not exists public.rounds (
  id bigserial primary key,
  asset text not null,
  timeframe text not null,
  open_time bigint not null,
  close_time bigint not null,
  open_price numeric,
  close_price numeric,
  on_chain_id text,
  status text not null default 'open',
  settle_tx text,
  created_at timestamptz not null default now()
);

alter table public.rounds add column if not exists asset text;
alter table public.rounds add column if not exists timeframe text;
alter table public.rounds add column if not exists open_time bigint;
alter table public.rounds add column if not exists close_time bigint;
alter table public.rounds add column if not exists open_price numeric;
alter table public.rounds add column if not exists close_price numeric;
alter table public.rounds add column if not exists on_chain_id text;
alter table public.rounds add column if not exists status text not null default 'open';
alter table public.rounds add column if not exists settle_tx text;
alter table public.rounds add column if not exists created_at timestamptz not null default now();

create unique index if not exists rounds_asset_tf_open_uniq
  on public.rounds (asset, timeframe, open_time);

create table if not exists public.notifications (
  id bigint generated by default as identity primary key,
  user_id uuid not null references public.profiles(id) on delete cascade,
  prediction_id bigint references public.predictions(id) on delete set null,
  type text not null default 'info',
  title text not null default '',
  message text not null default '',
  pnl_change integer not null default 0,
  is_read boolean not null default false,
  created_at timestamptz not null default now()
);

alter table public.notifications add column if not exists prediction_id bigint references public.predictions(id) on delete set null;
alter table public.notifications add column if not exists title text not null default '';
alter table public.notifications add column if not exists message text not null default '';
alter table public.notifications add column if not exists pnl_change integer not null default 0;
alter table public.notifications add column if not exists is_read boolean not null default false;
alter table public.notifications add column if not exists created_at timestamptz not null default now();

alter table public.notifications drop column if exists points_change;
alter table public.notifications drop column if exists read;

create table if not exists public.feedbacks (
  id bigint generated by default as identity primary key,
  user_id uuid references public.profiles(id) on delete set null,
  email text not null,
  category text not null default 'suggestion',
  message text not null,
  status text not null default 'new',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table public.feedbacks add column if not exists user_id uuid references public.profiles(id) on delete set null;
alter table public.feedbacks add column if not exists email text not null default '';
alter table public.feedbacks add column if not exists category text not null default 'suggestion';
alter table public.feedbacks add column if not exists message text not null default '';
alter table public.feedbacks add column if not exists status text not null default 'new';
alter table public.feedbacks add column if not exists created_at timestamptz not null default now();
alter table public.feedbacks add column if not exists updated_at timestamptz not null default now();

drop trigger if exists feedbacks_set_current_timestamp on public.feedbacks;
create trigger feedbacks_set_current_timestamp
before update on public.feedbacks
for each row
execute function public.set_current_timestamp();

create table if not exists public.activity_logs (
  id bigint generated by default as identity primary key,
  user_id uuid references public.profiles(id) on delete cascade,
  action_type text not null,
  asset_symbol text,
  prediction_id bigint references public.predictions(id) on delete set null,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now()
);

create table if not exists public.scheduler_settings (
  service_name text primary key,
  enabled boolean not null default false,
  timeframes text[] not null default array['15m', '30m', '1h', '4h', '1d']::text[],
  updated_at timestamptz not null default now()
);

alter table public.scheduler_settings add column if not exists enabled boolean not null default false;
alter table public.scheduler_settings add column if not exists timeframes text[] not null default array['15m', '30m', '1h', '4h', '1d']::text[];
alter table public.scheduler_settings add column if not exists updated_at timestamptz not null default now();

drop trigger if exists scheduler_settings_set_current_timestamp on public.scheduler_settings;
create trigger scheduler_settings_set_current_timestamp
before update on public.scheduler_settings
for each row
execute function public.set_current_timestamp();

create table if not exists public.api_usage (
  service_name text not null,
  usage_date date not null,
  count integer not null default 0,
  updated_at timestamptz not null default now(),
  primary key (service_name, usage_date)
);

alter table public.api_usage add column if not exists count integer not null default 0;
alter table public.api_usage add column if not exists updated_at timestamptz not null default now();

create table if not exists public.scheduler_locks (
  lock_key text primary key,
  locked_by text not null,
  expires_at timestamptz not null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table public.scheduler_locks add column if not exists locked_by text not null default 'unknown';
alter table public.scheduler_locks add column if not exists expires_at timestamptz not null default now();
alter table public.scheduler_locks add column if not exists created_at timestamptz not null default now();
alter table public.scheduler_locks add column if not exists updated_at timestamptz not null default now();

drop trigger if exists scheduler_locks_set_current_timestamp on public.scheduler_locks;
create trigger scheduler_locks_set_current_timestamp
before update on public.scheduler_locks
for each row
execute function public.set_current_timestamp();

create index if not exists idx_profiles_username on public.profiles (username);
create index if not exists idx_profiles_is_bot on public.profiles (is_bot);
create index if not exists idx_predictions_user_status on public.predictions (user_id, status, created_at desc);
create index if not exists idx_predictions_asset_tf_status on public.predictions (asset_symbol, timeframe, status, candle_close_at);
create index if not exists idx_predictions_channel_round on public.predictions (channel, round_time desc);
create index if not exists idx_predictions_created_at on public.predictions (created_at desc);
create index if not exists idx_rounds_status_close_time on public.rounds (status, close_time);
create index if not exists idx_notifications_user_created_at on public.notifications (user_id, created_at desc);
create index if not exists idx_feedbacks_created_at on public.feedbacks (created_at desc);
create index if not exists idx_activity_logs_user_created_at on public.activity_logs (user_id, created_at desc);
create index if not exists idx_scheduler_locks_expires_at on public.scheduler_locks (expires_at);

alter table public.profiles enable row level security;
alter table public.predictions enable row level security;
alter table public.rounds enable row level security;
alter table public.notifications enable row level security;
alter table public.feedbacks enable row level security;
alter table public.activity_logs enable row level security;
alter table public.scheduler_settings enable row level security;
alter table public.api_usage enable row level security;
alter table public.scheduler_locks enable row level security;

drop policy if exists "Public profiles are viewable by everyone." on public.profiles;
drop policy if exists "Users can insert their own profile." on public.profiles;
drop policy if exists "Users can update own profile." on public.profiles;
create policy "Public profiles are viewable by everyone." on public.profiles
  for select using (true);
create policy "Users can insert their own profile." on public.profiles
  for insert with check (auth.uid() = id);
create policy "Users can update own profile." on public.profiles
  for update using (auth.uid() = id);

drop policy if exists "Predictions are viewable by everyone." on public.predictions;
drop policy if exists "Users can insert their own predictions." on public.predictions;
drop policy if exists "Users can update their own predictions" on public.predictions;
create policy "Predictions are viewable by everyone." on public.predictions
  for select using (true);
create policy "Users can insert their own predictions." on public.predictions
  for insert with check (auth.uid() = user_id);
create policy "Users can update their own predictions" on public.predictions
  for update using (auth.uid() = user_id);

drop policy if exists "Rounds are viewable by everyone." on public.rounds;
create policy "Rounds are viewable by everyone." on public.rounds
  for select using (true);

drop policy if exists "Users can view own notifications" on public.notifications;
drop policy if exists "Users can update own notifications" on public.notifications;
create policy "Users can view own notifications" on public.notifications
  for select using (auth.uid() = user_id);
create policy "Users can update own notifications" on public.notifications
  for update using (auth.uid() = user_id);

drop policy if exists "Anyone can submit feedback" on public.feedbacks;
drop policy if exists "Authenticated users can view feedbacks" on public.feedbacks;
create policy "Anyone can submit feedback" on public.feedbacks
  for insert with check (true);
create policy "Authenticated users can view feedbacks" on public.feedbacks
  for select using (auth.role() = 'authenticated');

drop policy if exists "Authenticated users can manage activity logs" on public.activity_logs;
create policy "Authenticated users can manage activity logs" on public.activity_logs
  for all using (auth.role() = 'authenticated')
  with check (auth.role() = 'authenticated');

insert into public.scheduler_settings (service_name, enabled, timeframes)
values ('ai_analyst', false, array['15m', '30m', '1h', '4h', '1d']::text[])
on conflict (service_name) do nothing;

create or replace function public.refresh_profile_performance(p_user_id uuid)
returns void
language plpgsql
security definer
as $$
begin
  update public.profiles
  set total_games = coalesce((
        select count(*)
        from public.predictions
        where user_id = p_user_id
          and status in ('WIN', 'LOSS', 'ND', 'REFUND')
      ), 0),
      total_wins = coalesce((
        select count(*)
        from public.predictions
        where user_id = p_user_id
          and status = 'WIN'
      ), 0),
      total_earnings = coalesce((
        select sum(coalesce(profit, 0))
        from public.predictions
        where user_id = p_user_id
          and status in ('WIN', 'LOSS', 'ND', 'REFUND')
      ), 0),
      updated_at = now()
  where id = p_user_id;
end;
$$;

create or replace function public.refresh_all_profile_performance()
returns void
language plpgsql
security definer
as $$
declare
  r record;
begin
  for r in select id from public.profiles loop
    perform public.refresh_profile_performance(r.id);
  end loop;
end;
$$;

create or replace function public.handle_prediction_profile_sync()
returns trigger
language plpgsql
security definer
as $$
begin
  if tg_op = 'DELETE' then
    perform public.refresh_profile_performance(old.user_id);
    return old;
  end if;

  perform public.refresh_profile_performance(new.user_id);

  if tg_op = 'UPDATE' and old.user_id is distinct from new.user_id then
    perform public.refresh_profile_performance(old.user_id);
  end if;

  return new;
end;
$$;

drop trigger if exists predictions_profile_sync on public.predictions;
create trigger predictions_profile_sync
after insert or update or delete on public.predictions
for each row
execute function public.handle_prediction_profile_sync();

create or replace function public.handle_prediction_notifications()
returns trigger
language plpgsql
security definer
as $$
declare
  v_title text;
  v_message text;
begin
  if tg_op <> 'UPDATE' then
    return new;
  end if;

  if old.status = 'pending'
     and new.status is distinct from old.status
     and new.status in ('WIN', 'LOSS', 'ND', 'REFUND') then

    v_title := case
      when new.status = 'WIN' then 'Battle won'
      when new.status = 'LOSS' then 'Battle lost'
      else 'Battle refunded'
    end;

    v_message := case
      when new.status = 'WIN' then format('%s %s settled in your favor. +%s USDT mirrored PnL.', new.asset_symbol, new.timeframe, coalesce(new.profit, 0))
      when new.status = 'LOSS' then format('%s %s settled against you. %s USDT mirrored PnL.', new.asset_symbol, new.timeframe, coalesce(new.profit, 0))
      else format('%s %s closed flat or void. Stake refunded.', new.asset_symbol, new.timeframe)
    end;

    insert into public.notifications (user_id, prediction_id, type, title, message, pnl_change, is_read)
    values (
      new.user_id,
      new.id,
      case
        when new.status = 'WIN' then 'win'
        when new.status = 'LOSS' then 'loss'
        else 'info'
      end,
      v_title,
      v_message,
      coalesce(new.profit, 0),
      false
    );
  end if;

  return new;
end;
$$;

drop trigger if exists predictions_notify_on_resolution on public.predictions;
create trigger predictions_notify_on_resolution
after update on public.predictions
for each row
execute function public.handle_prediction_notifications();

create or replace function public.handle_prediction_activity_logs()
returns trigger
language plpgsql
security definer
as $$
begin
  if tg_op = 'INSERT' then
    insert into public.activity_logs (user_id, action_type, asset_symbol, prediction_id, metadata)
    values (
      new.user_id,
      case when new.is_opinion then 'analyst_post_created' else 'bet_mirrored' end,
      new.asset_symbol,
      new.id,
      jsonb_build_object(
        'timeframe', new.timeframe,
        'direction', new.direction,
        'bet_amount', new.bet_amount,
        'channel', new.channel
      )
    );
    return new;
  end if;

  if tg_op = 'UPDATE'
     and old.status = 'pending'
     and new.status is distinct from old.status
     and new.status in ('WIN', 'LOSS', 'ND', 'REFUND') then
    insert into public.activity_logs (user_id, action_type, asset_symbol, prediction_id, metadata)
    values (
      new.user_id,
      'bet_resolved',
      new.asset_symbol,
      new.id,
      jsonb_build_object(
        'timeframe', new.timeframe,
        'direction', new.direction,
        'status', new.status,
        'profit', new.profit
      )
    );
  end if;

  return new;
end;
$$;

drop trigger if exists predictions_activity_log on public.predictions;
create trigger predictions_activity_log
after insert or update on public.predictions
for each row
execute function public.handle_prediction_activity_logs();

drop function if exists public.get_top_leaders(integer);
drop function if exists public.get_trending_assets(integer);
drop function if exists public.get_market_sentiment(integer);
drop function if exists public.get_analyst_rounds(text, text, text);
drop function if exists public.get_live_rounds_with_stats(text, integer);
drop function if exists public.get_trending_by_single_category(text);
drop function if exists public.get_scheduler_settings(text);
drop function if exists public.update_scheduler_settings(text, boolean, text[]);
drop function if exists public.acquire_scheduler_lock(text, text, integer);
drop function if exists public.release_scheduler_lock(text, text);
drop function if exists public.get_api_usage(text, date);
drop function if exists public.can_make_api_call(text, integer);
drop function if exists public.track_api_call(text, integer);
drop function if exists public.resolve_prediction_pari_mutuel(bigint, numeric);
drop function if exists public.get_user_rank(uuid);

create or replace function public.get_top_leaders(limit_count integer default 3)
returns table (
  id uuid,
  username text,
  avatar_url text,
  total_wins integer,
  total_games integer,
  total_earnings integer
)
language sql
stable
as $$
  select
    p.id,
    coalesce(nullif(p.username, ''), 'Trader') as username,
    p.avatar_url,
    coalesce(p.total_wins, 0) as total_wins,
    coalesce(p.total_games, 0) as total_games,
    coalesce(p.total_earnings, 0) as total_earnings
  from public.profiles p
  order by coalesce(p.total_earnings, 0) desc, coalesce(p.total_wins, 0) desc, coalesce(p.total_games, 0) desc
  limit greatest(limit_count, 1);
$$;

create or replace function public.get_trending_assets(limit_count integer default 100)
returns table (
  symbol text,
  timeframe text,
  prediction_count bigint,
  total_volume numeric
)
language sql
stable
as $$
  with recent as (
    select *
    from public.predictions
    where created_at >= now() - interval '24 hours'
  )
  select
    asset_symbol as symbol,
    timeframe,
    count(*)::bigint as prediction_count,
    coalesce(sum(bet_amount), 0)::numeric as total_volume
  from recent
  group by asset_symbol, timeframe
  order by total_volume desc, prediction_count desc, asset_symbol asc
  limit greatest(limit_count, 1);
$$;

create or replace function public.get_market_sentiment(p_hours integer default 24)
returns table (
  asset_symbol text,
  total_votes bigint,
  bull_percent integer,
  bear_percent integer,
  avg_target numeric
)
language sql
stable
as $$
  with scoped as (
    select *
    from public.predictions
    where created_at >= now() - make_interval(hours => greatest(p_hours, 1))
  ),
  grouped as (
    select
      asset_symbol,
      count(*)::bigint as total_votes,
      sum(case when direction = 'UP' then 1 else 0 end) as bull_votes,
      sum(case when direction = 'DOWN' then 1 else 0 end) as bear_votes,
      avg(coalesce(target_percent, 0)) as avg_target
    from scoped
    group by asset_symbol
  )
  select
    asset_symbol,
    total_votes,
    case when total_votes = 0 then 0 else round((bull_votes::numeric / total_votes::numeric) * 100)::integer end as bull_percent,
    case when total_votes = 0 then 0 else round((bear_votes::numeric / total_votes::numeric) * 100)::integer end as bear_percent,
    round(coalesce(avg_target, 0)::numeric, 2) as avg_target
  from grouped
  order by total_votes desc, asset_symbol asc;
$$;

create or replace function public.get_analyst_rounds(
  p_asset_symbol text default null,
  p_timeframe text default null,
  p_channel text default 'analyst_hub'
)
returns table (
  asset_symbol text,
  timeframe text,
  round_time timestamptz,
  post_count bigint
)
language sql
stable
as $$
  select
    asset_symbol,
    timeframe,
    round_time,
    count(*)::bigint as post_count
  from public.predictions
  where is_opinion = true
    and channel = coalesce(p_channel, 'analyst_hub')
    and round_time is not null
    and (p_asset_symbol is null or asset_symbol = p_asset_symbol)
    and (p_timeframe is null or timeframe = p_timeframe)
  group by asset_symbol, timeframe, round_time
  order by round_time desc, asset_symbol asc, timeframe asc;
$$;

create or replace function public.get_live_rounds_with_stats(
  p_category text default 'ALL',
  p_limit integer default 50
)
returns table (
  asset_symbol text,
  timeframe text,
  asset_name text,
  asset_type text,
  participant_count bigint,
  total_volume numeric,
  ai_direction text,
  ai_confidence numeric
)
language sql
stable
as $$
  with live_rounds as (
    select
      r.asset,
      r.timeframe,
      r.open_time,
      r.close_time
    from public.rounds r
    where r.status = 'open'
      and r.close_time >= ((extract(epoch from now()) * 1000)::bigint - 60000)
      and (
        upper(coalesce(p_category, 'ALL')) = 'ALL'
        or public.asset_category_for_symbol(r.asset) = upper(p_category)
      )
    order by r.close_time asc
    limit greatest(p_limit, 1)
  )
  select
    lr.asset as asset_symbol,
    lr.timeframe,
    public.asset_name_for_symbol(lr.asset) as asset_name,
    public.asset_category_for_symbol(lr.asset) as asset_type,
    count(distinct p.user_id)::bigint as participant_count,
    coalesce(sum(case when p.status = 'pending' then p.bet_amount else 0 end), 0)::numeric as total_volume,
    ai.direction as ai_direction,
    ai.confidence as ai_confidence
  from live_rounds lr
  left join public.predictions p
    on p.asset_symbol = lr.asset
   and p.timeframe = lr.timeframe
   and p.status = 'pending'
   and p.candle_close_at = to_timestamp(lr.close_time / 1000.0)
  left join lateral (
    select
      ap.direction,
      ap.target_percent::numeric as confidence
    from public.predictions ap
    where ap.asset_symbol = lr.asset
      and ap.timeframe = lr.timeframe
      and ap.channel = 'analyst_hub'
      and ap.is_opinion = true
    order by ap.round_time desc nulls last, ap.created_at desc
    limit 1
  ) ai on true
  group by lr.asset, lr.timeframe, ai.direction, ai.confidence, lr.close_time
  order by total_volume desc, participant_count desc, lr.close_time asc
  limit greatest(p_limit, 1);
$$;

create or replace function public.get_trending_by_single_category(p_category text default 'CRYPTO')
returns table (
  asset_symbol text,
  timeframe text,
  asset_name text,
  asset_type text,
  participant_count bigint,
  total_volume numeric,
  ai_direction text,
  ai_confidence numeric
)
language sql
stable
as $$
  select *
  from public.get_live_rounds_with_stats(coalesce(p_category, 'CRYPTO'), 3);
$$;

create or replace function public.get_scheduler_settings(p_service_name text)
returns table (
  service_name text,
  enabled boolean,
  timeframes text[],
  updated_at timestamptz
)
language sql
stable
as $$
  select
    service_name,
    enabled,
    timeframes,
    updated_at
  from public.scheduler_settings
  where service_name = p_service_name;
$$;

create or replace function public.update_scheduler_settings(
  p_service_name text,
  p_enabled boolean default null,
  p_timeframes text[] default null
)
returns table (
  service_name text,
  enabled boolean,
  timeframes text[],
  updated_at timestamptz
)
language plpgsql
security definer
as $$
begin
  insert into public.scheduler_settings (service_name, enabled, timeframes)
  values (
    p_service_name,
    coalesce(p_enabled, false),
    coalesce(p_timeframes, array['15m', '30m', '1h', '4h', '1d']::text[])
  )
  on conflict (service_name) do update
    set enabled = coalesce(p_enabled, public.scheduler_settings.enabled),
        timeframes = coalesce(p_timeframes, public.scheduler_settings.timeframes),
        updated_at = now();

  return query
  select
    s.service_name,
    s.enabled,
    s.timeframes,
    s.updated_at
  from public.scheduler_settings s
  where s.service_name = p_service_name;
end;
$$;

create or replace function public.acquire_scheduler_lock(
  p_lock_key text,
  p_locked_by text,
  p_ttl_seconds integer default 300
)
returns jsonb
language plpgsql
security definer
as $$
begin
  delete from public.scheduler_locks
  where lock_key = p_lock_key
    and expires_at <= now();

  insert into public.scheduler_locks (lock_key, locked_by, expires_at)
  values (p_lock_key, p_locked_by, now() + make_interval(secs => greatest(p_ttl_seconds, 1)))
  on conflict do nothing;

  if found then
    return jsonb_build_object('success', true);
  end if;

  return jsonb_build_object('success', false, 'error', 'Lock already held');
end;
$$;

create or replace function public.release_scheduler_lock(
  p_lock_key text,
  p_locked_by text
)
returns boolean
language plpgsql
security definer
as $$
begin
  delete from public.scheduler_locks
  where lock_key = p_lock_key
    and locked_by = p_locked_by;

  return found;
end;
$$;

create or replace function public.get_api_usage(
  p_service text,
  p_date date default current_date
)
returns jsonb
language sql
stable
as $$
  select jsonb_build_object(
    'count',
    coalesce((
      select count
      from public.api_usage
      where service_name = p_service
        and usage_date = p_date
    ), 0)
  );
$$;

create or replace function public.can_make_api_call(
  p_service text,
  p_max_daily integer
)
returns boolean
language sql
stable
as $$
  select coalesce((
    select count < greatest(p_max_daily, 0)
    from public.api_usage
    where service_name = p_service
      and usage_date = current_date
  ), true);
$$;

create or replace function public.track_api_call(
  p_service text,
  p_increment integer default 1
)
returns boolean
language plpgsql
security definer
as $$
begin
  insert into public.api_usage (service_name, usage_date, count, updated_at)
  values (p_service, current_date, greatest(p_increment, 1), now())
  on conflict (service_name, usage_date) do update
    set count = public.api_usage.count + greatest(p_increment, 1),
        updated_at = now();

  return true;
end;
$$;

create or replace function public.resolve_prediction_pari_mutuel(
  target_prediction_id bigint,
  resolved_close_price numeric
)
returns jsonb
language plpgsql
security definer
as $$
declare
  v_prediction public.predictions%rowtype;
  v_profit integer;
  v_status text;
begin
  select *
  into v_prediction
  from public.predictions
  where id = target_prediction_id
    and status = 'pending'
  for update;

  if not found then
    return jsonb_build_object('success', false, 'error', 'Already resolved');
  end if;

  if resolved_close_price = v_prediction.entry_price then
    v_status := 'ND';
    v_profit := 0;
  elsif (
    v_prediction.direction = 'UP' and resolved_close_price > v_prediction.entry_price
  ) or (
    v_prediction.direction = 'DOWN' and resolved_close_price < v_prediction.entry_price
  ) then
    v_status := 'WIN';
    v_profit := v_prediction.bet_amount;
  else
    v_status := 'LOSS';
    v_profit := -v_prediction.bet_amount;
  end if;

  update public.predictions
  set status = v_status,
      actual_price = resolved_close_price,
      profit = v_profit,
      resolved_at = now()
  where id = target_prediction_id;

  return jsonb_build_object(
    'success', true,
    'status', v_status,
    'profit', v_profit
  );
end;
$$;

create or replace function public.get_user_rank(p_user_id uuid)
returns bigint
language sql
stable
security definer
as $$
  select rank
  from (
    select
      id,
      rank() over (order by total_earnings desc, total_wins desc, total_games desc, created_at asc) as rank
    from public.profiles
  ) ranked
  where id = p_user_id;
$$;

drop function if exists public.submit_prediction(uuid, text, text, text, numeric, numeric, integer);
drop function if exists public.submit_prediction(uuid, text, text, text, numeric, numeric, integer, boolean, text);
drop function if exists public.submit_prediction(uuid, text, text, text, numeric, numeric, numeric);
drop function if exists public.resolve_prediction_advanced(bigint, numeric, numeric);
drop function if exists public.resolve_prediction_advanced(bigint, numeric);

do $$
begin
  begin
    alter publication supabase_realtime add table public.predictions;
  exception when duplicate_object then null;
  end;

  begin
    alter publication supabase_realtime add table public.notifications;
  exception when duplicate_object then null;
  end;

  begin
    alter publication supabase_realtime add table public.rounds;
  exception when duplicate_object then null;
  end;
end;
$$;

select public.refresh_all_profile_performance();

commit;
