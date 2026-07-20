-- ============================================================
-- B2Better — Notas de voz en el Diario
-- Backend: b2better.api.kodevant.space  ·  2026-07-10
--
-- Cada entrada del diario puede ser texto o nota de voz. El audio se guarda
-- (Opus, liviano) en un bucket PRIVADO por usuario y se reproduce con URLs
-- firmadas. Sin transcripción ni IA. Duración máxima configurable por el admin.
-- ============================================================

-- 1) Columnas nuevas en el diario
ALTER TABLE public.journal_entries
  ADD COLUMN IF NOT EXISTS note_type text NOT NULL DEFAULT 'text'
    CHECK (note_type IN ('text','voice')),
  ADD COLUMN IF NOT EXISTS audio_path text,
  ADD COLUMN IF NOT EXISTS duration_seconds int;

-- 2) Bucket PRIVADO para las notas de voz (a diferencia de avatars/email-assets)
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES ('voice-notes','voice-notes', false, 15728640,
        ARRAY['audio/ogg','audio/opus','audio/aac','audio/mp4','audio/m4a','audio/mpeg','audio/webm'])
ON CONFLICT (id) DO UPDATE SET public=false;

-- 3) RLS: cada usuario sube/lee/borra SOLO sus audios (carpeta = su user_id)
DROP POLICY IF EXISTS voice_notes_select ON storage.objects;
DROP POLICY IF EXISTS voice_notes_insert ON storage.objects;
DROP POLICY IF EXISTS voice_notes_delete ON storage.objects;
CREATE POLICY voice_notes_select ON storage.objects FOR SELECT TO authenticated
  USING (bucket_id='voice-notes' AND (auth.uid())::text = (storage.foldername(name))[1]);
CREATE POLICY voice_notes_insert ON storage.objects FOR INSERT TO authenticated
  WITH CHECK (bucket_id='voice-notes' AND (auth.uid())::text = (storage.foldername(name))[1]);
CREATE POLICY voice_notes_delete ON storage.objects FOR DELETE TO authenticated
  USING (bucket_id='voice-notes' AND (auth.uid())::text = (storage.foldername(name))[1]);

-- 4) Duración máxima de la nota de voz (segundos) — la edita el admin, rige para todos
INSERT INTO public.app_config(key, value)
VALUES ('voice_note_max_seconds', '180')
ON CONFLICT (key) DO NOTHING;

SELECT 'notas de voz: columnas + bucket privado + config listo' AS status;
