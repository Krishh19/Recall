-- Make user_id nullable if it was previously NOT NULL
alter table public.saved_items alter column user_id drop not null;

-- Drop any previous restrictive policies
drop policy if exists "Users can view their own saved items" on public.saved_items;
drop policy if exists "Users can insert their own saved items" on public.saved_items;
drop policy if exists "Users can update their own saved items" on public.saved_items;
drop policy if exists "Users can delete their own saved items" on public.saved_items;
drop policy if exists "Allow public access to saved items" on public.saved_items;
drop policy if exists "Allow all access to saved_items" on public.saved_items;

-- Enable RLS
alter table public.saved_items enable row level security;

-- Create permissive policy for anon, authenticated, and service_role
create policy "Allow all access to saved_items"
  on public.saved_items
  for all
  to anon, authenticated, service_role
  using (true)
  with check (true);
