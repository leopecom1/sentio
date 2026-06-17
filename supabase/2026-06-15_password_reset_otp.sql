-- ============================================================
-- B2Better — Reseteo de contraseña con código de 6 dígitos (OTP)
-- Backend: b2better.api.kodevant.space
--
-- Flujo:
--   1) App llama request_password_reset(email) → genera un código de
--      6 dígitos, lo guarda HASHEADO (sha256 + email como sal) y lo
--      envía por Resend usando el pipeline existente (send_resend_email
--      + email_template_base, mismo template/logo que el resto).
--   2) App llama verify_password_reset(email, code, new_password) →
--      valida el código (no expirado, no usado, intentos < 5) y cambia
--      la contraseña directamente en auth.users (bcrypt), compatible con
--      GoTrue. Marca el código como usado.
--
-- Seguridad:
--   - Códigos hasheados (nunca en claro en la DB).
--   - Expiran a los 15 minutos.
--   - Máx 5 intentos de verificación por código y máx 5 solicitudes/hora.
--   - request_password_reset SIEMPRE responde ok (no revela si el email
--     existe), pero solo envía el correo si el usuario existe.
--   - Funciones SECURITY DEFINER (owner postgres) para poder tocar
--     auth.users; RLS de la tabla deniega acceso directo.
-- ============================================================

-- ---------- Tabla de códigos ----------
CREATE TABLE IF NOT EXISTS public.password_reset_codes (
  id          uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  email       text NOT NULL,
  code_hash   text NOT NULL,
  expires_at  timestamptz NOT NULL,
  consumed    boolean NOT NULL DEFAULT false,
  attempts    int NOT NULL DEFAULT 0,
  created_at  timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_prc_email_created
  ON public.password_reset_codes (email, created_at DESC);

-- RLS activado SIN políticas → nadie accede directo; solo las funciones
-- SECURITY DEFINER (que corren como owner) pueden leer/escribir.
ALTER TABLE public.password_reset_codes ENABLE ROW LEVEL SECURITY;

-- ---------- Email del código ----------
CREATE OR REPLACE FUNCTION public.send_password_reset_email(p_email text, p_code text)
RETURNS bigint
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public', 'extensions'
AS $fn$
DECLARE
  v_body TEXT;
BEGIN
  v_body :=
    '<p style="margin:0 0 16px;">Recibimos una solicitud para restablecer tu contraseña en B2Better.</p>' ||
    '<p style="margin:0 0 12px;">Ingresá este código en la app para continuar:</p>' ||
    '<div style="margin:8px 0 20px;text-align:center;">' ||
      '<span style="display:inline-block;font-size:34px;font-weight:800;letter-spacing:10px;color:#00FFBD;' ||
      'background:#0A0A0B;border:1px solid rgba(255,255,255,0.12);border-radius:16px;padding:16px 24px;">' ||
      p_code || '</span>' ||
    '</div>' ||
    '<p style="margin:0 0 16px;color:#9999A1;font-size:14px;">El código vence en 15 minutos. Si no fuiste vos, ignorá este correo: tu contraseña no cambia hasta que lo uses.</p>';

  RETURN public.send_resend_email(
    p_email,
    'Tu código para restablecer la contraseña',
    public.email_template_base('Restablecer contraseña', v_body)
  );
END;
$fn$;

-- ---------- 1) Solicitar código ----------
CREATE OR REPLACE FUNCTION public.request_password_reset(p_email text)
RETURNS json
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public', 'extensions'
AS $fn$
DECLARE
  v_email   text := lower(trim(p_email));
  v_user_id uuid;
  v_name    text;
  v_code    text;
  v_recent  int;
BEGIN
  IF v_email IS NULL OR v_email = '' OR position('@' in v_email) = 0 THEN
    RAISE EXCEPTION 'invalid_email';
  END IF;

  -- Rate limit: máx 5 solicitudes por hora por email.
  SELECT count(*) INTO v_recent
  FROM public.password_reset_codes
  WHERE email = v_email AND created_at > now() - interval '1 hour';
  IF v_recent >= 5 THEN
    RAISE EXCEPTION 'too_many_requests';
  END IF;

  SELECT id, COALESCE(raw_user_meta_data->>'full_name', split_part(email,'@',1))
    INTO v_user_id, v_name
  FROM auth.users
  WHERE email = v_email;

  -- Invalida códigos previos sin usar.
  UPDATE public.password_reset_codes
  SET consumed = true
  WHERE email = v_email AND consumed = false;

  -- Genera código de 6 dígitos y lo guarda hasheado (sal = email).
  v_code := lpad((floor(random() * 1000000))::int::text, 6, '0');

  INSERT INTO public.password_reset_codes (email, code_hash, expires_at)
  VALUES (
    v_email,
    encode(digest(v_code || v_email, 'sha256'), 'hex'),
    now() + interval '15 minutes'
  );

  -- Solo enviamos el email si el usuario existe (sin revelarlo al cliente).
  IF v_user_id IS NOT NULL THEN
    BEGIN
      PERFORM public.send_password_reset_email(v_email, v_code);
    EXCEPTION WHEN OTHERS THEN
      RAISE WARNING 'send_password_reset_email failed for %: %', v_email, SQLERRM;
    END;
  END IF;

  RETURN json_build_object('ok', true);
END;
$fn$;

-- ---------- 2) Verificar código + cambiar contraseña ----------
CREATE OR REPLACE FUNCTION public.verify_password_reset(
  p_email text,
  p_code text,
  p_new_password text
)
RETURNS json
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public', 'extensions'
AS $fn$
DECLARE
  v_email   text := lower(trim(p_email));
  v_rec     public.password_reset_codes%ROWTYPE;
  v_user_id uuid;
BEGIN
  IF p_new_password IS NULL OR length(p_new_password) < 6 THEN
    RAISE EXCEPTION 'weak_password';
  END IF;

  -- Código vigente más reciente.
  SELECT * INTO v_rec
  FROM public.password_reset_codes
  WHERE email = v_email AND consumed = false AND expires_at > now()
  ORDER BY created_at DESC
  LIMIT 1;

  IF v_rec.id IS NULL THEN
    RAISE EXCEPTION 'invalid_code';
  END IF;

  IF v_rec.attempts >= 5 THEN
    UPDATE public.password_reset_codes SET consumed = true WHERE id = v_rec.id;
    RAISE EXCEPTION 'too_many_attempts';
  END IF;

  -- ¿Coincide el código?
  IF v_rec.code_hash <> encode(digest(trim(p_code) || v_email, 'sha256'), 'hex') THEN
    UPDATE public.password_reset_codes SET attempts = attempts + 1 WHERE id = v_rec.id;
    RAISE EXCEPTION 'invalid_code';
  END IF;

  SELECT id INTO v_user_id FROM auth.users WHERE email = v_email;
  IF v_user_id IS NULL THEN
    UPDATE public.password_reset_codes SET consumed = true WHERE id = v_rec.id;
    RAISE EXCEPTION 'invalid_code';
  END IF;

  -- Cambia la contraseña (bcrypt, compatible con GoTrue).
  UPDATE auth.users
  SET encrypted_password = crypt(p_new_password, gen_salt('bf')),
      updated_at = now()
  WHERE id = v_user_id;

  UPDATE public.password_reset_codes SET consumed = true WHERE id = v_rec.id;

  RETURN json_build_object('ok', true);
END;
$fn$;

-- ---------- Permisos ----------
-- Llamadas desde la app SIN sesión (usuario olvidó la clave) → anon.
REVOKE ALL ON FUNCTION public.request_password_reset(text) FROM public;
REVOKE ALL ON FUNCTION public.verify_password_reset(text, text, text) FROM public;
GRANT EXECUTE ON FUNCTION public.request_password_reset(text) TO anon, authenticated;
GRANT EXECUTE ON FUNCTION public.verify_password_reset(text, text, text) TO anon, authenticated;
-- El email helper NO se expone al cliente.
REVOKE ALL ON FUNCTION public.send_password_reset_email(text, text) FROM public;

SELECT 'password reset OTP instalado' AS status;
