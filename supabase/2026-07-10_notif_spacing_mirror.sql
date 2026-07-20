-- ============================================================
-- B2Better — Notificaciones: espaciado global + mail espejo
-- Backend: b2better.api.kodevant.space  ·  2026-07-10
--
-- Arregla dos problemas de retención del motor (2026-06-18_notifications_engine):
--
-- #1 ESPACIADO: hoy el cooldown es por-plantilla, así que en la corrida diaria
--    un usuario puede recibir varios avisos juntos (no_checkin + streak_danger +
--    no_journal + inactivity) y termina apagándolos todos. Se agrega un COOLDOWN
--    GLOBAL por usuario: como mucho 1 aviso de recordatorio por ventana
--    (app_config.notif_global_cooldown_minutes, default 1080 = 18h).
--    Exentas: 'comunidad' y 'crisis' (deben llegar siempre).
--
-- #2 MAIL ESPEJO: si un aviso sale por push, sale también por email (salvo que
--    el usuario haya desactivado el mail de esa categoría a propósito). Así quien
--    no tiene push activo, o no mira el celular, igual recibe el aviso.
--
-- Solo redefine notify_user (no envía nada por sí solo).
-- ============================================================

INSERT INTO public.app_config(key, value)
VALUES ('notif_global_cooldown_minutes', '1080')
ON CONFLICT (key) DO NOTHING;

CREATE OR REPLACE FUNCTION public.notify_user(p_user_id uuid, p_template_key text, p_vars jsonb DEFAULT '{}'::jsonb)
RETURNS void LANGUAGE plpgsql SECURITY DEFINER SET search_path=public, extensions AS $fn$
DECLARE
  v_tpl   public.notification_templates%ROWTYPE;
  v_inapp boolean; v_push boolean; v_email boolean;
  v_pin boolean; v_ppush boolean; v_pemail boolean;
  v_email_optout boolean := false;
  v_title text; v_body text; k text; val text;
  v_email_addr text; v_chans text[] := '{}';
  v_global_cd int;
  v_throttled boolean;
BEGIN
  SELECT * INTO v_tpl FROM notification_templates WHERE key=p_template_key AND is_active=true;
  IF NOT FOUND THEN RETURN; END IF;

  -- Categorías exentas del espaciado global (siempre deben poder llegar).
  v_throttled := v_tpl.category NOT IN ('comunidad','crisis');

  -- cooldown anti-spam POR PLANTILLA (no repetir el mismo aviso)
  PERFORM 1 FROM notification_log
   WHERE user_id=p_user_id AND template_key=p_template_key
     AND created_at > now() - make_interval(mins => v_tpl.cooldown_minutes);
  IF FOUND THEN RETURN; END IF;

  -- #1 cooldown GLOBAL por usuario (espaciado): si en la ventana ya recibió
  -- cualquier aviso de una categoría no-exenta, no mandamos otro recordatorio.
  IF v_throttled THEN
    v_global_cd := COALESCE((SELECT value FROM app_config WHERE key='notif_global_cooldown_minutes')::int, 1080);
    PERFORM 1
      FROM notification_log nl
      JOIN notification_templates t ON t.key = nl.template_key
     WHERE nl.user_id = p_user_id
       AND t.category NOT IN ('comunidad','crisis')
       AND nl.created_at > now() - make_interval(mins => v_global_cd);
    IF FOUND THEN RETURN; END IF;
  END IF;

  -- canales: default del template, override por preferencias
  v_inapp := true; v_push := v_tpl.push_default; v_email := v_tpl.email_default;
  SELECT in_app, push, email INTO v_pin, v_ppush, v_pemail
    FROM notification_preferences WHERE user_id=p_user_id AND category=v_tpl.category;
  IF FOUND THEN
    v_inapp:=v_pin; v_push:=v_ppush; v_email:=v_pemail;
    IF v_pemail = false THEN v_email_optout := true; END IF;  -- el usuario apagó el mail a propósito
  END IF;
  -- master switch (category='all'): si existe y todo apagado, mutea
  SELECT in_app, push, email INTO v_pin, v_ppush, v_pemail
    FROM notification_preferences WHERE user_id=p_user_id AND category='all';
  IF FOUND AND v_pin=false AND v_ppush=false AND v_pemail=false THEN RETURN; END IF;

  -- #2 MAIL ESPEJO: si va por push y el usuario no desactivó el mail a propósito,
  -- lo mandamos también por email.
  IF v_push AND NOT v_email_optout THEN v_email := true; END IF;

  -- render variables {nombre} etc
  v_title := v_tpl.title; v_body := v_tpl.body;
  FOR k, val IN SELECT key, value FROM jsonb_each_text(p_vars) LOOP
    v_title := replace(v_title, '{'||k||'}', val);
    v_body  := replace(v_body,  '{'||k||'}', val);
  END LOOP;

  IF v_inapp THEN
    INSERT INTO notifications (user_id, type, title, body, icon, color)
    VALUES (p_user_id, v_tpl.category, v_title, v_body, v_tpl.icon, v_tpl.color);
    v_chans := array_append(v_chans, 'in_app');
  END IF;

  IF v_email THEN
    BEGIN
      v_email_addr := (SELECT email FROM auth.users WHERE id=p_user_id);
      IF v_email_addr IS NOT NULL THEN
        PERFORM send_resend_email(v_email_addr, v_title,
          email_template_base(v_title, '<p style="margin:0 0 16px;">'||v_body||'</p>'));
        v_chans := array_append(v_chans, 'email');
      END IF;
    EXCEPTION WHEN OTHERS THEN RAISE WARNING 'notify email: %', SQLERRM; END;
  END IF;

  IF v_push THEN
    PERFORM send_push(p_user_id, v_title, v_body);
    v_chans := array_append(v_chans, 'push');
  END IF;

  INSERT INTO notification_log (user_id, template_key, channels) VALUES (p_user_id, p_template_key, v_chans);
END;$fn$;

SELECT 'notify_user: espaciado global + mail espejo instalado' AS status;

-- ------------------------------------------------------------
-- Prioridad de reglas: al espaciar, gana el aviso más importante.
-- (menor número = más importante; se procesa primero)
-- ------------------------------------------------------------
ALTER TABLE public.automation_rules ADD COLUMN IF NOT EXISTS priority int NOT NULL DEFAULT 100;
UPDATE public.automation_rules SET priority = 10 WHERE trigger_type='streak_danger';
UPDATE public.automation_rules SET priority = 20 WHERE trigger_type='no_checkin';
UPDATE public.automation_rules SET priority = 30 WHERE trigger_type='no_journal';
UPDATE public.automation_rules SET priority = 40 WHERE trigger_type='daily_goals_pending';
UPDATE public.automation_rules SET priority = 50 WHERE trigger_type='inactivity';

CREATE OR REPLACE FUNCTION public.run_daily_automations()
RETURNS void LANGUAGE plpgsql SECURITY DEFINER SET search_path=public, extensions AS $fn$
DECLARE r public.automation_rules%ROWTYPE; v_days int;
BEGIN
  FOR r IN SELECT * FROM automation_rules WHERE is_active=true ORDER BY priority ASC, key ASC LOOP
    IF r.trigger_type = 'no_checkin' THEN
      PERFORM notify_user(p.id, r.template_key,
        jsonb_build_object('nombre', coalesce(split_part(p.full_name,' ',1),'')))
      FROM profiles p
      WHERE p.onboarding_completed=true
        AND NOT EXISTS (SELECT 1 FROM checkins c WHERE c.user_id=p.id AND c.created_at::date = current_date);
    ELSIF r.trigger_type = 'streak_danger' THEN
      PERFORM notify_user(p.id, r.template_key,
        jsonb_build_object('nombre', coalesce(split_part(p.full_name,' ',1),''), 'racha', p.checkin_streak::text))
      FROM profiles p
      WHERE coalesce(p.checkin_streak,0) > 0
        AND NOT EXISTS (SELECT 1 FROM checkins c WHERE c.user_id=p.id AND c.created_at::date = current_date);
    ELSIF r.trigger_type = 'daily_goals_pending' THEN
      PERFORM notify_user(g.user_id, r.template_key, '{}'::jsonb)
      FROM (SELECT DISTINCT user_id FROM user_goals WHERE is_daily=true AND is_completed=false) g;
    ELSIF r.trigger_type = 'no_journal' THEN
      v_days := coalesce((r.params->>'days')::int, 3);
      PERFORM notify_user(p.id, r.template_key,
        jsonb_build_object('nombre', coalesce(split_part(p.full_name,' ',1),'')))
      FROM profiles p
      WHERE p.onboarding_completed=true
        AND NOT EXISTS (SELECT 1 FROM journal_entries j WHERE j.user_id=p.id AND j.created_at > now() - make_interval(days => v_days));
    ELSIF r.trigger_type = 'inactivity' THEN
      v_days := coalesce((r.params->>'days')::int, 5);
      PERFORM notify_user(p.id, r.template_key,
        jsonb_build_object('nombre', coalesce(split_part(p.full_name,' ',1),'')))
      FROM profiles p
      WHERE p.onboarding_completed=true
        AND coalesce(p.last_active_at, p.created_at) < now() - make_interval(days => v_days);
    END IF;
  END LOOP;
END;$fn$;

SELECT 'run_daily_automations: ordenado por prioridad' AS status;
