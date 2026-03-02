-- Update predictions table to include resolution details
alter table public.predictions 
add column if not exists close_price numeric,
add column if not exists actual_change_percent numeric,
add column if not exists is_direction_correct boolean default false,
add column if not exists is_target_hit boolean default false;

-- Migrate existing status values to uppercase standard
UPDATE public.predictions SET status = 'WIN' WHERE status = 'won';
UPDATE public.predictions SET status = 'LOSE' WHERE status = 'lost';

-- Update status check constraint
alter table public.predictions 
drop constraint if exists predictions_status_check;

alter table public.predictions 
add constraint predictions_status_check 
check (status in ('pending', 'WIN', 'LOSE'));
