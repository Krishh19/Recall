-- Enable pg_net extension for async HTTP requests from Postgres
create extension if not exists pg_net with schema extensions;

-- Function to invoke process-item edge function when a saved item is inserted
create or replace function public.handle_saved_item_inserted()
returns trigger as $$
declare
  request_id bigint;
begin
  -- Trigger the process-item Edge Function asynchronously
  select net.http_post(
    url := 'https://evtzrvqfaearmpjgqwqd.supabase.co/functions/v1/process-item',
    headers := jsonb_build_object(
      'Content-Type', 'application/json'
    ),
    body := jsonb_build_object(
      'id', new.id,
      'url', new.url
    )
  ) into request_id;

  return new;
end;
$$ language plpgsql security definer;

-- Trigger on INSERT
drop trigger if exists on_saved_item_inserted on public.saved_items;
create trigger on_saved_item_inserted
  after insert on public.saved_items
  for each row
  execute function public.handle_saved_item_inserted();
