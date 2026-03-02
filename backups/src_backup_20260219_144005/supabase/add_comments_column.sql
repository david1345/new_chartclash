-- Add comment column to predictions
alter table public.predictions 
add column if not exists comment text;

-- Optional: Create an index for feed if we query by latest
create index if not exists predictions_created_at_idx on public.predictions(created_at desc);
