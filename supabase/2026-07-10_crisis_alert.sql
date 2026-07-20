-- ============================================================
-- B2Better — #3b Alerta de contención a admins
-- Backend: b2better.api.kodevant.space  ·  2026-07-10
--
-- Cuando un check-in entra con is_crisis=true, avisa a los administradores
-- por push + email + notificación in-app, para que alguien pueda actuar.
-- (La respuesta directa al usuario con recursos es del lado de la app, #3a.)
-- ============================================================

CREATE OR REPLACE FUNCTION public.tg_checkin_crisis_alert()
RETURNS trigger LANGUAGE plpgsql SECURITY DEFINER SET search_path=public, extensions AS $fn$
DECLARE a record; v_name text; v_email text; v_title text; v_body text;
BEGIN
  IF NEW.is_crisis IS NOT TRUE THEN RETURN NEW; END IF;

  SELECT full_name INTO v_name FROM profiles WHERE id = NEW.user_id;
  v_name := COALESCE(NULLIF(v_name,''), 'Un usuario');
  v_title := 'Alerta de contención';
  v_body  := v_name || ' registró un check-in de alerta (estrés '
             || COALESCE(NEW.stress_level::text,'?') || '/5, energía '
             || COALESCE(NEW.energy_level::text,'?') || '/5). Puede necesitar acompañamiento.';

  FOR a IN SELECT id FROM profiles WHERE is_admin = true LOOP
    BEGIN
      INSERT INTO notifications(user_id, type, title, body, icon, color)
        VALUES (a.id, 'crisis', v_title, v_body, '🚨', '#E5484D');
      PERFORM send_push(a.id, v_title, v_body);
      v_email := (SELECT email FROM auth.users WHERE id = a.id);
      IF v_email IS NOT NULL THEN
        PERFORM send_resend_email(v_email, v_title,
          email_template_base(v_title, '<p style="margin:0 0 16px;">'||v_body||'</p>'));
      END IF;
    EXCEPTION WHEN OTHERS THEN RAISE WARNING 'crisis alert admin %: %', a.id, SQLERRM; END;
  END LOOP;

  RETURN NEW;
EXCEPTION WHEN OTHERS THEN RAISE WARNING 'crisis alert: %', SQLERRM; RETURN NEW;
END $fn$;

DROP TRIGGER IF EXISTS trg_checkin_crisis_alert ON public.checkins;
CREATE TRIGGER trg_checkin_crisis_alert
  AFTER INSERT ON public.checkins
  FOR EACH ROW WHEN (NEW.is_crisis IS TRUE)
  EXECUTE FUNCTION public.tg_checkin_crisis_alert();

SELECT 'trigger de alerta de contención instalado' AS status;
