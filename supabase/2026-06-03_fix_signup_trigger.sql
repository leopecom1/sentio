-- ============================================================
-- B2Better — FIX CRÍTICO: "Database error saving new user"
-- ESTADO: YA APLICADO en la DB (mateo) el 2026-06-03 vía pg-meta.
--
-- Causa raíz real: el trigger handle_new_user() insertaba en
-- profiles las columnas `email` e `is_approved`, que NO EXISTEN
-- en la tabla (la DB usa `validation_status`, y el email vive en
-- auth.users, no en profiles). Cualquier alta de usuario reventaba.
--
-- Este fix:
--   1) Inserta SOLO columnas que existen (id, full_name).
--   2) Fija search_path = public y qualifica public.profiles.
--   3) Envuelve el envío de welcome email y el cuerpo entero en
--      EXCEPTION, para que un fallo nunca bloquee el alta en auth.
-- Verificado end-to-end: alta de usuario crea profile OK.
-- ============================================================

CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $fn$
BEGIN
  INSERT INTO public.profiles (id, full_name)
  VALUES (
    NEW.id,
    COALESCE(NEW.raw_user_meta_data->>'full_name', split_part(NEW.email, '@', 1))
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
    -- No bloquear el alta del usuario si el profile falla.
    RAISE WARNING 'handle_new_user failed for %: %', NEW.id, SQLERRM;
    RETURN NEW;
END;
$fn$;

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- Backfill defensivo: crear profiles faltantes para usuarios ya existentes.
INSERT INTO public.profiles (id, full_name)
SELECT u.id,
       COALESCE(u.raw_user_meta_data->>'full_name', split_part(u.email, '@', 1))
FROM auth.users u
LEFT JOIN public.profiles p ON p.id = u.id
WHERE p.id IS NULL
ON CONFLICT (id) DO NOTHING;

SELECT 'Trigger de signup reparado + profiles backfilleados' AS status;
