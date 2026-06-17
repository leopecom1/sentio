-- ============================================================
-- App Store / Play Store compliance migration  (2026-06-03)
-- Aplicada vía pg-meta (supabase_admin).
-- ============================================================

-- 1) BORRADO DE CUENTA (Apple 5.1.1(v) / Google Play)
--    Borra el usuario de auth.users; todo cascadea (profiles + datos).
create or replace function public.delete_current_user()
returns void
language plpgsql
security definer
set search_path = public, auth
as $fn$
declare
  v_uid uuid := auth.uid();
begin
  if v_uid is null then
    raise exception 'Not authenticated';
  end if;
  delete from auth.users where id = v_uid;
end;
$fn$;

revoke all on function public.delete_current_user() from public, anon;
grant execute on function public.delete_current_user() to authenticated;

-- 2) AUTO-APROBACIÓN (que el revisor de Apple no quede bloqueado)
alter table public.profiles alter column validation_status set default 'approved';
update public.profiles set validation_status = 'approved'
  where validation_status is distinct from 'approved';

-- 3) PROXY OPENAI (sacar la API key del cliente)
--    Secreto en Vault + función SECURITY DEFINER que reenvía a OpenAI.
do $secret$
begin
  if not exists (select 1 from vault.secrets where name = 'openai_api_key') then
    perform vault.create_secret('REEMPLAZAR_POR_KEY', 'openai_api_key');
  end if;
end;
$secret$;

create or replace function public.ai_proxy(p_payload jsonb)
returns jsonb
language plpgsql
security definer
set search_path = public, extensions, vault
as $fn$
declare
  v_key  text;
  v_body jsonb;
  v_resp text;
  v_model text;
  v_max  int;
begin
  if auth.uid() is null then
    raise exception 'Not authenticated';
  end if;

  select decrypted_secret into v_key
  from vault.decrypted_secrets where name = 'openai_api_key' limit 1;
  if v_key is null then
    raise exception 'OpenAI key not configured';
  end if;

  -- Whitelist de modelo y tope de tokens para evitar abuso.
  v_model := coalesce(p_payload->>'model', 'gpt-4o-mini');
  if v_model not in ('gpt-4o-mini', 'gpt-4o') then
    v_model := 'gpt-4o-mini';
  end if;
  v_max := least(coalesce((p_payload->>'max_tokens')::int, 300), 1000);

  v_body := jsonb_set(
              jsonb_set(p_payload, '{model}', to_jsonb(v_model)),
              '{max_tokens}', to_jsonb(v_max));

  perform extensions.http_set_curlopt('CURLOPT_TIMEOUT_MS', '60000');

  select content into v_resp
  from extensions.http((
    'POST',
    'https://api.openai.com/v1/chat/completions',
    array[extensions.http_header('Authorization', 'Bearer ' || v_key)],
    'application/json',
    v_body::text
  )::extensions.http_request);

  return v_resp::jsonb;
end;
$fn$;

revoke all on function public.ai_proxy(jsonb) from public, anon;
grant execute on function public.ai_proxy(jsonb) to authenticated;

-- 4) MODERACIÓN DE CONTENIDO (Apple 1.2 - UGC: reportar + bloquear)
create table if not exists public.content_reports (
  id uuid primary key default gen_random_uuid(),
  reporter_id uuid not null references public.profiles(id) on delete cascade,
  content_type text not null check (content_type in ('post','comment','story','user')),
  content_id uuid not null,
  reason text,
  status text not null default 'pending',
  created_at timestamptz not null default now()
);
alter table public.content_reports enable row level security;
drop policy if exists "reports_insert_own" on public.content_reports;
create policy "reports_insert_own" on public.content_reports
  for insert to authenticated with check (auth.uid() = reporter_id);
drop policy if exists "reports_select_own" on public.content_reports;
create policy "reports_select_own" on public.content_reports
  for select to authenticated using (auth.uid() = reporter_id);

create table if not exists public.blocked_users (
  blocker_id uuid not null references public.profiles(id) on delete cascade,
  blocked_id uuid not null references public.profiles(id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (blocker_id, blocked_id)
);
alter table public.blocked_users enable row level security;
drop policy if exists "blocks_all_own" on public.blocked_users;
create policy "blocks_all_own" on public.blocked_users
  for all to authenticated
  using (auth.uid() = blocker_id)
  with check (auth.uid() = blocker_id);

-- Auto-ocultar un post cuando acumula >= 3 reportes únicos.
create or replace function public.handle_content_report()
returns trigger
language plpgsql
security definer
set search_path = public
as $fn$
begin
  if new.content_type = 'post' then
    if (select count(distinct reporter_id) from public.content_reports
        where content_type = 'post' and content_id = new.content_id) >= 3 then
      update public.community_posts set is_visible = false where id = new.content_id;
    end if;
  end if;
  return new;
end;
$fn$;
drop trigger if exists trg_content_report on public.content_reports;
create trigger trg_content_report
  after insert on public.content_reports
  for each row execute function public.handle_content_report();
