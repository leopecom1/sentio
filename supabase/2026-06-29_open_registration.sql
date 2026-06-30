-- ============================================================
-- B2Better — Registro abierto (sin aprobación manual por defecto)
-- Backend: b2better.api.kodevant.space
--
-- `require_account_approval` en app_config controla si las cuentas nuevas
-- necesitan que un admin las habilite:
--   'false' (default) -> registro abierto: el usuario entra directo.
--   'true'            -> el admin debe aprobar cada cuenta (pantalla "Aprobar cuentas").
--
-- Esto es INDEPENDIENTE de `validation_status` (la validación de la comunidad).
-- ============================================================

-- Flag de config (lectura pública, escritura admin — ya cubierto por las
-- policies existentes de app_config).
INSERT INTO public.app_config (key, value)
VALUES ('require_account_approval', 'false')
ON CONFLICT (key) DO NOTHING;

-- Trigger de alta: setea is_approved según el flag.
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $fn$
DECLARE v_require boolean;
BEGIN
  v_require := COALESCE(
    (SELECT value FROM public.app_config WHERE key = 'require_account_approval'),
    'false'
  ) = 'true';

  INSERT INTO public.profiles (id, full_name, is_approved, approved_at)
  VALUES (
    NEW.id,
    COALESCE(NEW.raw_user_meta_data->>'full_name', split_part(NEW.email, '@', 1)),
    NOT v_require,
    CASE WHEN NOT v_require THEN now() ELSE NULL END
  )
  ON CONFLICT (id) DO UPDATE SET
    full_name = COALESCE(public.profiles.full_name, EXCLUDED.full_name);

  BEGIN
    PERFORM public.send_welcome_email(
      NEW.email,
      COALESCE(NEW.raw_user_meta_data->>'full_name', split_part(NEW.email, '@', 1))
    );
  EXCEPTION WHEN OTHERS THEN
    RAISE WARNING 'send_welcome_email failed for %: %', NEW.id, SQLERRM;
  END;

  RETURN NEW;
EXCEPTION
  WHEN OTHERS THEN
    RAISE WARNING 'handle_new_user failed for %: %', NEW.id, SQLERRM;
    RETURN NEW;
END;
$fn$;

NOTIFY pgrst, 'reload schema';
SELECT 'registro abierto instalado' AS status;
