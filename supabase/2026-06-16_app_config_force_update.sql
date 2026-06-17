-- ============================================================
-- B2Better — Config pública de la app + Forced Update
-- Backend: b2better.api.kodevant.space
--
-- Tabla `app_config`: pares clave/valor de configuración NO sensible,
-- legible por la app (anon) para controlar comportamiento sin re-publicar.
-- (Separada de `app_secrets`, que contiene la API key de Resend y NO debe
-- exponerse al cliente.)
--
-- Forced update: la app compara su versión instalada contra `min_*_version`.
-- Si es menor, muestra una pantalla bloqueante con botón a la tienda.
-- Para forzar una actualización: subir `min_android_version`/`min_ios_version`
-- al número de la versión que querés exigir.
-- ============================================================

CREATE TABLE IF NOT EXISTS public.app_config (
  key        text PRIMARY KEY,
  value      text,
  updated_at timestamptz NOT NULL DEFAULT now()
);

ALTER TABLE public.app_config ENABLE ROW LEVEL SECURITY;

-- Lectura pública (solo config no sensible). Escritura solo service_role/admin.
DROP POLICY IF EXISTS "app_config public read" ON public.app_config;
CREATE POLICY "app_config public read"
  ON public.app_config FOR SELECT
  TO anon, authenticated
  USING (true);

-- Valores iniciales. min_* = 1.0.0 para NO bloquear a los usuarios actuales
-- (1.0.0 >= 1.0.0). Cuando publiques una versión nueva y quieras forzarla,
-- subí estos números (p. ej. a 1.1.0).
INSERT INTO public.app_config (key, value) VALUES
  ('min_android_version', '1.0.0'),
  ('min_ios_version',     '1.0.0'),
  ('android_store_url',   'https://play.google.com/store/apps/details?id=com.sentio.sentio_app'),
  ('ios_store_url',       'https://apps.apple.com/app/id6776117344')
ON CONFLICT (key) DO NOTHING;

-- Escritura: solo admins (profiles.is_admin) pueden editar la config
-- (desde el panel admin). El resto es solo lectura.
DROP POLICY IF EXISTS "Admins can manage app_config" ON public.app_config;
CREATE POLICY "Admins can manage app_config"
  ON public.app_config FOR ALL
  TO authenticated
  USING (EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND is_admin = true))
  WITH CHECK (EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND is_admin = true));

SELECT 'app_config + forced update instalado' AS status;
