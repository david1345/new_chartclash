-- ChartClash: on-chain rounds registry
-- Run this in Supabase SQL Editor

create table if not exists public.rounds (
    id           bigserial primary key,
    asset        text        not null,
    timeframe    text        not null,
    open_time    bigint      not null,   -- unix ms
    close_time   bigint      not null,   -- unix ms
    open_price   numeric,
    close_price  numeric,
    on_chain_id  text,                   -- uint256 from contract.createRound()
    status       text        not null default 'open',  -- 'open' | 'settled' | 'cancelled'
    settle_tx    text,                   -- blockchain tx hash
    created_at   timestamptz not null default now(),
    constraint rounds_asset_tf_open_uniq unique (asset, timeframe, open_time)
);

-- Index for cron lookups
create index if not exists rounds_status_close_time_idx on public.rounds (status, close_time);
