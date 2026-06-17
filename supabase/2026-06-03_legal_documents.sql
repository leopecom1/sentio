-- B2Better — tabla opcional para servir Términos y Política de Privacidad
-- desde el servidor (override del contenido local en legal_content.dart).
-- La app YA funciona sin esto (usa fallback local); ejecutar solo si se quiere
-- editar lo legal sin recompilar la app.
-- Correr en: Supabase Studio (mateo) → SQL Editor.

create table if not exists public.legal_documents (
  id           uuid primary key default gen_random_uuid(),
  doc_type     text not null unique check (doc_type in ('terms', 'privacy')),
  sections     jsonb not null default '[]'::jsonb,   -- [{ "title": "...", "body": "..." }]
  version      text,
  last_updated text,
  updated_at   timestamptz not null default now()
);

alter table public.legal_documents enable row level security;

-- Lectura pública (cualquier usuario autenticado o anónimo puede leer los textos legales)
drop policy if exists "legal_documents_read" on public.legal_documents;
create policy "legal_documents_read"
  on public.legal_documents for select
  using (true);

-- Escritura solo para admins (ajustar a tu lógica de is_admin en profiles)
drop policy if exists "legal_documents_admin_write" on public.legal_documents;
create policy "legal_documents_admin_write"
  on public.legal_documents for all
  using (exists (select 1 from public.profiles p where p.id = auth.uid() and p.is_admin = true))
  with check (exists (select 1 from public.profiles p where p.id = auth.uid() and p.is_admin = true));
