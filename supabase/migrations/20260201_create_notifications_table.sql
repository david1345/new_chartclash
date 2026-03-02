-- 🔔 Create Notifications Table (Missing from base schema)
create table if not exists public.notifications (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
    type TEXT NOT NULL, -- 'win', 'loss', 'info', 'system'
    title TEXT NOT NULL,
    message TEXT NOT NULL,
    points_change INT DEFAULT 0,
    is_read BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Index for performance
create index if not exists idx_notifications_user_id ON public.notifications(user_id);
create index if not exists idx_notifications_created_at ON public.notifications(created_at DESC);

-- RLS
alter table public.notifications enable row level security;

drop policy if exists "Users can view own notifications" on public.notifications;
create policy "Users can view own notifications" 
on public.notifications for select 
using (auth.uid() = user_id);

-- Enable Realtime (Idempotent)
DO $$
BEGIN
  BEGIN
    alter publication supabase_realtime add table notifications;
  EXCEPTION WHEN duplicate_object THEN
    NULL; -- Already exists, ignore
  END;
END;
$$;
