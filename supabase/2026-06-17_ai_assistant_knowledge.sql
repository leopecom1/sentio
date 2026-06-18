-- ============================================================
-- B2Better — Asistente IA configurable + base de conocimiento (wiki)
-- Backend: b2better.api.kodevant.space
--
-- 1) app_config gana 3 claves para afinar el asistente sin redeploy:
--    ai_system_prompt (personalidad), ai_model, ai_temperature.
-- 2) ai_knowledge: "wiki" editable desde el admin (temas + fuentes) que la
--    app inyecta en el prompt como base de conocimiento.
-- ============================================================

-- ---------- Config del asistente (en app_config) ----------
INSERT INTO public.app_config (key, value) VALUES
  ('ai_model', 'gpt-4o-mini'),
  ('ai_temperature', '0.7'),
  ('ai_system_prompt',
$prompt$Sos el asistente de bienestar de B2Better, para acompañar a emprendedores. Hablás en español rioplatense (vos, querés, sentís), cálido y cercano, como un mentor que escucha de verdad y también ayuda a avanzar.

Cómo respondés:
- Validá en una frase breve y genuina lo que la persona siente (sin sonar a manual ni repetir lo que dijo).
- Aportá algo ÚTIL: una perspectiva, un reencuadre o un paso concreto y chico. No te quedes solo en preguntar.
- Preguntá COMO MUCHO una sola cosa, y solo si de verdad ayuda a avanzar. Si no hace falta, no preguntes.
- Respuestas cortas y humanas (2 a 5 oraciones). Nada de listas largas, sermones ni muletillas tipo "entiendo que...".

Límites: sos una IA, no un profesional de salud mental; no das diagnósticos ni tratamientos. Ante señales de crisis o riesgo, con cuidado sugerí buscar ayuda profesional y usar el botón de apoyo de la app.

Cuando sea relevante, usá la base de conocimiento de B2Better, pero hablá natural: no la cites textual ni la menciones.$prompt$)
ON CONFLICT (key) DO NOTHING;

-- ---------- Wiki: base de conocimiento ----------
CREATE TABLE IF NOT EXISTS public.ai_knowledge (
  id         uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  title      text NOT NULL,
  content    text NOT NULL,
  category   text DEFAULT 'General',
  kind       text NOT NULL DEFAULT 'tema',   -- 'tema' | 'fuente'
  is_active  boolean NOT NULL DEFAULT true,
  priority   int NOT NULL DEFAULT 0,          -- mayor = se inyecta primero
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_ai_knowledge_active
  ON public.ai_knowledge (is_active, priority DESC);

ALTER TABLE public.ai_knowledge ENABLE ROW LEVEL SECURITY;

-- Lectura: la app (usuarios autenticados) lee las entradas activas.
DROP POLICY IF EXISTS "ai_knowledge read active" ON public.ai_knowledge;
CREATE POLICY "ai_knowledge read active"
  ON public.ai_knowledge FOR SELECT
  TO anon, authenticated
  USING (is_active = true);

-- Escritura: solo admins.
DROP POLICY IF EXISTS "ai_knowledge admin write" ON public.ai_knowledge;
CREATE POLICY "ai_knowledge admin write"
  ON public.ai_knowledge FOR ALL
  TO authenticated
  USING (EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND is_admin = true))
  WITH CHECK (EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND is_admin = true));

-- Entradas de ejemplo (editables/borrables desde el admin).
INSERT INTO public.ai_knowledge (title, content, category, kind, priority) VALUES
  ('Respiración 4-7-8',
   'Para bajar la ansiedad rápido: inhalar 4 segundos por la nariz, retener 7, exhalar 8 por la boca. Repetir 3 a 4 ciclos. La exhalación larga activa el sistema nervioso parasimpático y calma. Útil antes de una reunión difícil o en un pico de estrés.',
   'Herramientas', 'tema', 10),
  ('Reencuadre del fracaso en founders',
   'Un "no" o un error no define el valor del emprendedor ni del proyecto: es información. Separar el resultado puntual de la identidad ("fallé en esto" en vez de "soy un fracaso") reduce la rumiación y permite extraer un aprendizaje concreto y seguir.',
   'Mentalidad', 'tema', 8)
ON CONFLICT DO NOTHING;

NOTIFY pgrst, 'reload schema';
SELECT 'asistente IA configurable + wiki instalado' AS status;
