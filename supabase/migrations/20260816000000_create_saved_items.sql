-- Create saved_items table
create table if not exists public.saved_items (
  id uuid primary key default gen_random_uuid(),
  user_id uuid,                      -- optional user_id (not requiring auth.users)
  url text not null,
  platform text not null,            -- twitter | instagram | youtube | article
  title text,
  thumbnail_url text,
  raw_content text,
  summary text,
  key_points jsonb,
  category text,
  tags text[],
  status text default 'processing',  -- processing | done | failed
  is_read boolean default false,
  is_favorite boolean default false,
  created_at timestamptz default now()
);

-- Performance index for chronological feeds
create index if not exists saved_items_created_idx
  on public.saved_items (created_at desc);

-- GIN index for tag containment and search queries
create index if not exists saved_items_tags_gin_idx
  on public.saved_items using gin (tags);

-- Enable Row Level Security
alter table public.saved_items enable row level security;

-- Permissive RLS Policies for standalone/development app
create policy "Allow public access to saved items"
  on public.saved_items for all
  using (true)
  with check (true);
