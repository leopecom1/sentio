-- ============================================================
-- B2Better — Metas del usuario (normales + diarias)
-- Backend: b2better.api.kodevant.space
--
-- El usuario puede crear metas (persistentes) y metas diarias, marcarlas
-- como completadas. El asistente del chat puede sugerir metas (la app las
-- inserta acá cuando el usuario toca "Agregar meta").
-- ============================================================

CREATE TABLE IF NOT EXISTS public.user_goals (
  id           uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id      uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  title        text NOT NULL,
  is_daily     boolean NOT NULL DEFAULT false,
  is_completed boolean NOT NULL DEFAULT false,
  completed_at timestamptz,
  source       text NOT NULL DEFAULT 'manual',  -- 'manual' | 'chat'
  created_at   timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_user_goals_user
  ON public.user_goals (user_id, is_daily, is_completed, created_at DESC);

ALTER TABLE public.user_goals ENABLE ROW LEVEL SECURITY;

-- Cada usuario ve y maneja solo sus metas.
DROP POLICY IF EXISTS "own goals" ON public.user_goals;
CREATE POLICY "own goals"
  ON public.user_goals FOR ALL
  TO authenticated
  USING (user_id = auth.uid())
  WITH CHECK (user_id = auth.uid());

NOTIFY pgrst, 'reload schema';
SELECT 'user_goals instalado' AS status;
