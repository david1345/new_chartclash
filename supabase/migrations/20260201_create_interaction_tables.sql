-- Create Likes Table
create table if not exists likes (
  id uuid default gen_random_uuid() primary key,
  user_id uuid references auth.users(id) on delete cascade not null,
  post_id bigint references posts(id) on delete cascade not null, -- Assuming posts.id is bigint based on previous context
  created_at timestamp with time zone default timezone('utc'::text, now()) not null,
  unique(user_id, post_id)
);

-- Create Comments Table
create table if not exists comments (
  id uuid default gen_random_uuid() primary key,
  user_id uuid references auth.users(id) on delete cascade not null,
  post_id bigint references posts(id) on delete cascade not null,
  content text not null,
  created_at timestamp with time zone default timezone('utc'::text, now()) not null
);

-- Create Bookmarks Table
create table if not exists bookmarks (
  id uuid default gen_random_uuid() primary key,
  user_id uuid references auth.users(id) on delete cascade not null,
  post_id bigint references posts(id) on delete cascade not null,
  created_at timestamp with time zone default timezone('utc'::text, now()) not null,
  unique(user_id, post_id)
);

-- Create Shares Table (Referenced in triggers)
create table if not exists shares (
  id uuid default gen_random_uuid() primary key,
  user_id uuid references auth.users(id) on delete cascade not null,
  post_id bigint references posts(id) on delete cascade not null,
  platform text,
  created_at timestamp with time zone default timezone('utc'::text, now()) not null
);

-- Enable RLS (Security Best Practice)
alter table likes enable row level security;
alter table comments enable row level security;
alter table bookmarks enable row level security;
alter table shares enable row level security;

-- Basic Policies (Adjust as needed)
DROP POLICY IF EXISTS "Public view likes" ON likes;
create policy "Public view likes" on likes for select using (true);

DROP POLICY IF EXISTS "Authenticated insert likes" ON likes;
create policy "Authenticated insert likes" on likes for insert with check (auth.uid() = user_id);

DROP POLICY IF EXISTS "User delete own likes" ON likes;
create policy "User delete own likes" on likes for delete using (auth.uid() = user_id);

DROP POLICY IF EXISTS "Public view comments" ON comments;
create policy "Public view comments" on comments for select using (true);

DROP POLICY IF EXISTS "Authenticated insert comments" ON comments;
create policy "Authenticated insert comments" on comments for insert with check (auth.uid() = user_id);

DROP POLICY IF EXISTS "User view own bookmarks" ON bookmarks;
create policy "User view own bookmarks" on bookmarks for select using (auth.uid() = user_id);

DROP POLICY IF EXISTS "User insert own bookmarks" ON bookmarks;
create policy "User insert own bookmarks" on bookmarks for insert with check (auth.uid() = user_id);

DROP POLICY IF EXISTS "User delete own bookmarks" ON bookmarks;
create policy "User delete own bookmarks" on bookmarks for delete using (auth.uid() = user_id);
