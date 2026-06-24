-- ============================================================
-- B2Better — Motor de notificaciones + automatizaciones
-- Backend: b2better.api.kodevant.space
--
-- Canales: in-app (tabla notifications) + email (Resend) + push (OneSignal).
-- - notification_templates: catálogo editable (texto + categoría + canales default + cooldown)
-- - automation_rules: reglas programadas (cron) activables desde el admin
-- - notification_preferences: preferencias por usuario y categoría
-- - notification_log: anti-spam + métricas
-- - notify_user(): dispatch central (respeta prefs, cooldown, manda por los canales)
-- - send_push(): OneSignal (no-op hasta configurar app_secrets)
-- - run_daily_automations(): motor diario (pg_cron) para hábitos + inactividad
-- - triggers de comunidad: comentarios / likes -> notifican al dueño
-- ============================================================

CREATE EXTENSION IF NOT EXISTS pg_cron;

-- ---------- Tablas ----------
CREATE TABLE IF NOT EXISTS public.notification_templates (
  key              text PRIMARY KEY,
  title            text NOT NULL,
  body             text NOT NULL,
  category         text NOT NULL,            -- habitos | comunidad | reactivacion | progreso
  icon             text,
  color            text,
  push_default     boolean NOT NULL DEFAULT true,
  email_default    boolean NOT NULL DEFAULT false,
  cooldown_minutes int NOT NULL DEFAULT 720, -- no repetir al mismo user dentro de esta ventana
  is_active        boolean NOT NULL DEFAULT true,
  updated_at       timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public.automation_rules (
  key          text PRIMARY KEY,
  template_key text NOT NULL,
  description  text,
  trigger_type text NOT NULL,                -- no_checkin | streak_danger | daily_goals_pending | no_journal | inactivity
  params       jsonb NOT NULL DEFAULT '{}'::jsonb,
  is_active    boolean NOT NULL DEFAULT true,
  updated_at   timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public.notification_preferences (
  user_id  uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  category text NOT NULL,                    -- 'all' (master) | habitos | comunidad | reactivacion | progreso
  in_app   boolean NOT NULL DEFAULT true,
  push     boolean NOT NULL DEFAULT true,
  email    boolean NOT NULL DEFAULT true,
  PRIMARY KEY (user_id, category)
);

CREATE TABLE IF NOT EXISTS public.notification_log (
  id           uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id      uuid NOT NULL,
  template_key text NOT NULL,
  channels     text[] NOT NULL DEFAULT '{}',
  created_at   timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS idx_notiflog_user_tpl
  ON public.notification_log (user_id, template_key, created_at DESC);

-- ---------- RLS ----------
ALTER TABLE public.notification_templates ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.automation_rules ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.notification_preferences ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.notification_log ENABLE ROW LEVEL SECURITY;

-- templates/rules: lectura autenticada, escritura admin
DROP POLICY IF EXISTS "tpl read" ON public.notification_templates;
CREATE POLICY "tpl read" ON public.notification_templates FOR SELECT TO anon, authenticated USING (true);
DROP POLICY IF EXISTS "tpl admin" ON public.notification_templates;
CREATE POLICY "tpl admin" ON public.notification_templates FOR ALL TO authenticated
  USING (EXISTS (SELECT 1 FROM public.profiles WHERE id=auth.uid() AND is_admin=true))
  WITH CHECK (EXISTS (SELECT 1 FROM public.profiles WHERE id=auth.uid() AND is_admin=true));

DROP POLICY IF EXISTS "rule read" ON public.automation_rules;
CREATE POLICY "rule read" ON public.automation_rules FOR SELECT TO anon, authenticated USING (true);
DROP POLICY IF EXISTS "rule admin" ON public.automation_rules;
CREATE POLICY "rule admin" ON public.automation_rules FOR ALL TO authenticated
  USING (EXISTS (SELECT 1 FROM public.profiles WHERE id=auth.uid() AND is_admin=true))
  WITH CHECK (EXISTS (SELECT 1 FROM public.profiles WHERE id=auth.uid() AND is_admin=true));

-- preferences: cada usuario las suyas
DROP POLICY IF EXISTS "pref own" ON public.notification_preferences;
CREATE POLICY "pref own" ON public.notification_preferences FOR ALL TO authenticated
  USING (user_id = auth.uid()) WITH CHECK (user_id = auth.uid());

-- log: solo admin lee (métricas); las funciones SECURITY DEFINER escriben
DROP POLICY IF EXISTS "log admin" ON public.notification_log;
CREATE POLICY "log admin" ON public.notification_log FOR SELECT TO authenticated
  USING (EXISTS (SELECT 1 FROM public.profiles WHERE id=auth.uid() AND is_admin=true));

-- ---------- send_push (OneSignal; no-op hasta configurar) ----------
CREATE OR REPLACE FUNCTION public.send_push(p_user_id uuid, p_title text, p_body text)
RETURNS void LANGUAGE plpgsql SECURITY DEFINER SET search_path=public, extensions AS $fn$
DECLARE v_app text; v_key text;
BEGIN
  v_app := (SELECT setting_value FROM app_secrets WHERE setting_key='onesignal_app_id');
  v_key := (SELECT setting_value FROM app_secrets WHERE setting_key='onesignal_api_key');
  IF v_app IS NULL OR v_app='' OR v_key IS NULL OR v_key='' THEN RETURN; END IF;
  PERFORM extensions.http_set_curlopt('CURLOPT_TIMEOUT','15');
  PERFORM extensions.http((
    'POST','https://onesignal.com/api/v1/notifications',
    ARRAY[extensions.http_header('Authorization','Basic '||v_key)],
    'application/json',
    jsonb_build_object(
      'app_id', v_app,
      'include_aliases', jsonb_build_object('external_id', jsonb_build_array(p_user_id::text)),
      'target_channel','push',
      'headings', jsonb_build_object('en',p_title,'es',p_title),
      'contents', jsonb_build_object('en',p_body,'es',p_body)
    )::text
  )::extensions.http_request);
EXCEPTION WHEN OTHERS THEN RAISE WARNING 'send_push: %', SQLERRM;
END;$fn$;

-- ---------- notify_user: dispatch central ----------
CREATE OR REPLACE FUNCTION public.notify_user(p_user_id uuid, p_template_key text, p_vars jsonb DEFAULT '{}'::jsonb)
RETURNS void LANGUAGE plpgsql SECURITY DEFINER SET search_path=public, extensions AS $fn$
DECLARE
  v_tpl   public.notification_templates%ROWTYPE;
  v_inapp boolean; v_push boolean; v_email boolean;
  v_pin boolean; v_ppush boolean; v_pemail boolean; v_has_pref boolean := false;
  v_title text; v_body text; k text; val text;
  v_email_addr text; v_chans text[] := '{}';
BEGIN
  SELECT * INTO v_tpl FROM notification_templates WHERE key=p_template_key AND is_active=true;
  IF NOT FOUND THEN RETURN; END IF;

  -- cooldown anti-spam
  PERFORM 1 FROM notification_log
   WHERE user_id=p_user_id AND template_key=p_template_key
     AND created_at > now() - make_interval(mins => v_tpl.cooldown_minutes);
  IF FOUND THEN RETURN; END IF;

  -- canales: default del template, override por preferencias
  v_inapp := true; v_push := v_tpl.push_default; v_email := v_tpl.email_default;
  SELECT in_app, push, email INTO v_pin, v_ppush, v_pemail
    FROM notification_preferences WHERE user_id=p_user_id AND category=v_tpl.category;
  IF FOUND THEN v_inapp:=v_pin; v_push:=v_ppush; v_email:=v_pemail; END IF;
  -- master switch (category='all'): si existe y todo apagado, mutea
  SELECT in_app, push, email INTO v_pin, v_ppush, v_pemail
    FROM notification_preferences WHERE user_id=p_user_id AND category='all';
  IF FOUND AND v_pin=false AND v_ppush=false AND v_pemail=false THEN RETURN; END IF;

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

-- ---------- Motor diario (pg_cron) ----------
CREATE OR REPLACE FUNCTION public.run_daily_automations()
RETURNS void LANGUAGE plpgsql SECURITY DEFINER SET search_path=public, extensions AS $fn$
DECLARE r public.automation_rules%ROWTYPE; v_days int;
BEGIN
  FOR r IN SELECT * FROM automation_rules WHERE is_active=true LOOP
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

-- ---------- Triggers de comunidad (eventos) ----------
CREATE OR REPLACE FUNCTION public.tg_notify_comment()
RETURNS trigger LANGUAGE plpgsql SECURITY DEFINER SET search_path=public, extensions AS $fn$
DECLARE v_owner uuid; v_name text;
BEGIN
  SELECT user_id INTO v_owner FROM community_posts WHERE id=NEW.post_id;
  IF v_owner IS NOT NULL AND v_owner <> NEW.user_id THEN
    SELECT coalesce(split_part(full_name,' ',1),'Alguien') INTO v_name FROM profiles WHERE id=NEW.user_id;
    PERFORM notify_user(v_owner, 'community_comment', jsonb_build_object('quien', v_name));
  END IF;
  RETURN NEW;
END;$fn$;
DROP TRIGGER IF EXISTS trg_notify_comment ON public.community_comments;
CREATE TRIGGER trg_notify_comment AFTER INSERT ON public.community_comments
  FOR EACH ROW EXECUTE FUNCTION public.tg_notify_comment();

CREATE OR REPLACE FUNCTION public.tg_notify_like()
RETURNS trigger LANGUAGE plpgsql SECURITY DEFINER SET search_path=public, extensions AS $fn$
DECLARE v_owner uuid; v_name text;
BEGIN
  SELECT user_id INTO v_owner FROM community_posts WHERE id=NEW.post_id;
  IF v_owner IS NOT NULL AND v_owner <> NEW.user_id THEN
    SELECT coalesce(split_part(full_name,' ',1),'Alguien') INTO v_name FROM profiles WHERE id=NEW.user_id;
    PERFORM notify_user(v_owner, 'community_like', jsonb_build_object('quien', v_name));
  END IF;
  RETURN NEW;
END;$fn$;
DROP TRIGGER IF EXISTS trg_notify_like ON public.community_likes;
CREATE TRIGGER trg_notify_like AFTER INSERT ON public.community_likes
  FOR EACH ROW EXECUTE FUNCTION public.tg_notify_like();

-- ---------- Seeds: templates ----------
INSERT INTO public.notification_templates (key, title, body, category, icon, color, push_default, email_default, cooldown_minutes) VALUES
  ('habit_no_checkin', '¿Cómo viene tu día, {nombre}?', 'Tomate 30 segundos para registrar cómo te sentís hoy.', 'habitos', 'mood', '#3030FF', true, false, 1200),
  ('habit_streak_danger', 'Tu racha está en juego 🔥', 'Llevás {racha} días seguidos. Hacé tu check-in para no perder la racha.', 'habitos', 'whatshot', '#FF9800', true, false, 1200),
  ('habit_daily_goals', 'Te quedan metas por hoy', 'Todavía tenés metas diarias sin completar. ¿Vamos por una?', 'habitos', 'flag', '#00FFBD', true, false, 1200),
  ('habit_no_journal', 'Tu diario te espera', 'Hace unos días que no escribís. Aunque sean dos líneas, ayuda a ordenar la cabeza.', 'habitos', 'edit', '#00FFBD', true, false, 4320),
  ('community_comment', '{quien} comentó tu publicación', 'Entrá a la comunidad para ver qué te dijeron.', 'comunidad', 'chat', '#3030FF', true, false, 0),
  ('community_like', 'A {quien} le gustó tu publicación', 'Tu historia está resonando con otros founders.', 'comunidad', 'favorite', '#FF6B9D', true, false, 60),
  ('reactivation_inactive', 'Te extrañamos, {nombre}', 'Hace unos días que no pasás por acá. Tu espacio sigue intacto cuando quieras volver.', 'reactivacion', 'waving_hand', '#C9A96E', true, true, 10080)
ON CONFLICT (key) DO NOTHING;

-- ---------- Seeds: automation_rules ----------
-- Arrancan PAUSADAS (is_active=false): el admin las activa desde el panel
-- cuando esté listo, para no notificar masivamente sin revisión.
INSERT INTO public.automation_rules (key, template_key, description, trigger_type, params, is_active) VALUES
  ('rule_no_checkin', 'habit_no_checkin', 'Recordar check-in si no registró hoy', 'no_checkin', '{}', false),
  ('rule_streak_danger', 'habit_streak_danger', 'Avisar racha en peligro', 'streak_danger', '{}', false),
  ('rule_daily_goals', 'habit_daily_goals', 'Metas diarias pendientes', 'daily_goals_pending', '{}', false),
  ('rule_no_journal', 'habit_no_journal', 'Sin journal en N días', 'no_journal', '{"days":3}', false),
  ('rule_inactivity', 'reactivation_inactive', 'Reactivación por inactividad', 'inactivity', '{"days":5}', false)
ON CONFLICT (key) DO NOTHING;

-- ---------- Envío manual (broadcast) desde el admin ----------
-- Manda una plantilla a todos los usuarios con onboarding completo.
-- Respeta preferencias y cooldown (vía notify_user). Solo admin.
CREATE OR REPLACE FUNCTION public.admin_broadcast(p_template_key text)
RETURNS int LANGUAGE plpgsql SECURITY DEFINER SET search_path=public, extensions AS $fn$
DECLARE v_count int := 0; r record;
BEGIN
  IF NOT EXISTS (SELECT 1 FROM profiles WHERE id=auth.uid() AND is_admin=true) THEN
    RAISE EXCEPTION 'solo admin';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM notification_templates WHERE key=p_template_key AND is_active=true) THEN
    RAISE EXCEPTION 'plantilla inexistente o inactiva';
  END IF;
  FOR r IN SELECT id, full_name FROM profiles WHERE onboarding_completed=true LOOP
    PERFORM notify_user(r.id, p_template_key,
      jsonb_build_object('nombre', coalesce(split_part(r.full_name,' ',1),'')));
    v_count := v_count + 1;
  END LOOP;
  RETURN v_count;
END;$fn$;

-- ---------- pg_cron: motor diario 22:00 UTC (~19:00 ARG) ----------
SELECT cron.unschedule('daily-automations') WHERE EXISTS (SELECT 1 FROM cron.job WHERE jobname='daily-automations');
SELECT cron.schedule('daily-automations', '0 22 * * *', $$ SELECT public.run_daily_automations(); $$);

NOTIFY pgrst, 'reload schema';
SELECT 'motor de notificaciones instalado' AS status;
