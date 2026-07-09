-- ============================================================
-- B2Better — Sistema de Email Marketing (Resend)
-- Backend: b2better.api.kodevant.space  ·  aplicado 2026-07-09
--
-- Construye sobre la infra de email existente (send_resend_email, pg_net,
-- app_secrets.resend_api_key / resend_from). Agrega:
--   · Etiquetas de contactos (segmentación)
--   · Campañas con editor por bloques (JSON) + HTML renderizado
--   · Envío por Resend con tracking (aperturas/clics vía webhook)
--   · Baja (unsubscribe) por contacto — obligatorio legalmente
--
-- SEGURIDAD:
--   · Todo el acceso es vía RPC SECURITY DEFINER con guard public.is_admin().
--   · Las tablas tienen RLS (nadie las lee directo salvo admin).
--   · Las campañas NO se envían solas: admin_campaign_send() es explícito.
--
-- SECRETOS (NO en el repo, van en app_secrets):
--   resend_api_key, resend_from  (ya existen)
--   resend_webhook_secret        (nuevo — token del webhook de Resend)
-- CONFIG pública (app_config):
--   marketing_public_base = URL pública del admin (para el link de baja)
-- ============================================================

-- ---------- 1. Etiquetas ----------
CREATE TABLE IF NOT EXISTS public.email_tags (
  id          uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name        text NOT NULL,
  color       text NOT NULL DEFAULT '#3D5A80',
  description text,
  created_at  timestamptz NOT NULL DEFAULT now(),
  created_by  uuid REFERENCES auth.users(id) ON DELETE SET NULL,
  UNIQUE (name)
);

CREATE TABLE IF NOT EXISTS public.contact_tags (
  tag_id     uuid NOT NULL REFERENCES public.email_tags(id) ON DELETE CASCADE,
  user_id    uuid NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  created_at timestamptz NOT NULL DEFAULT now(),
  PRIMARY KEY (tag_id, user_id)
);
CREATE INDEX IF NOT EXISTS idx_contact_tags_user ON public.contact_tags(user_id);

-- ---------- 2. Campañas ----------
CREATE TABLE IF NOT EXISTS public.email_campaigns (
  id            uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name          text NOT NULL,
  subject       text NOT NULL DEFAULT '',
  preheader     text NOT NULL DEFAULT '',
  from_name     text,
  from_email    text,
  blocks        jsonb NOT NULL DEFAULT '[]'::jsonb,   -- editor por bloques
  html          text  NOT NULL DEFAULT '',            -- render final
  style         jsonb NOT NULL DEFAULT '{}'::jsonb,   -- estética/tema elegido
  audience      jsonb NOT NULL DEFAULT '{"mode":"all"}'::jsonb,
  status        text  NOT NULL DEFAULT 'draft'
                CHECK (status IN ('draft','scheduled','sending','sent','failed')),
  scheduled_at  timestamptz,
  sent_at       timestamptz,
  total_recipients int NOT NULL DEFAULT 0,
  sent_count    int NOT NULL DEFAULT 0,
  failed_count  int NOT NULL DEFAULT 0,
  opened_count  int NOT NULL DEFAULT 0,
  clicked_count int NOT NULL DEFAULT 0,
  created_at    timestamptz NOT NULL DEFAULT now(),
  updated_at    timestamptz NOT NULL DEFAULT now(),
  created_by    uuid REFERENCES auth.users(id) ON DELETE SET NULL
);
CREATE INDEX IF NOT EXISTS idx_campaigns_status ON public.email_campaigns(status);

-- ---------- 3. Destinatarios (log por contacto) ----------
CREATE TABLE IF NOT EXISTS public.email_campaign_recipients (
  id          uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  campaign_id uuid NOT NULL REFERENCES public.email_campaigns(id) ON DELETE CASCADE,
  user_id     uuid REFERENCES public.profiles(id) ON DELETE SET NULL,
  email       text NOT NULL,
  status      text NOT NULL DEFAULT 'pending'
              CHECK (status IN ('pending','sent','delivered','opened','clicked','bounced','complained','failed')),
  resend_id   text,
  unsub_token uuid NOT NULL DEFAULT gen_random_uuid(),
  error       text,
  sent_at     timestamptz,
  opened_at   timestamptz,
  clicked_at  timestamptz,
  created_at  timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS idx_recip_campaign ON public.email_campaign_recipients(campaign_id);
CREATE INDEX IF NOT EXISTS idx_recip_email     ON public.email_campaign_recipients(email);
CREATE INDEX IF NOT EXISTS idx_recip_resend    ON public.email_campaign_recipients(resend_id);
CREATE UNIQUE INDEX IF NOT EXISTS idx_recip_unsub ON public.email_campaign_recipients(unsub_token);

-- ---------- 4. Bajas (unsubscribe) ----------
CREATE TABLE IF NOT EXISTS public.email_unsubscribes (
  email       text PRIMARY KEY,
  user_id     uuid REFERENCES public.profiles(id) ON DELETE SET NULL,
  campaign_id uuid REFERENCES public.email_campaigns(id) ON DELETE SET NULL,
  created_at  timestamptz NOT NULL DEFAULT now()
);

-- ---------- 5. RLS: solo admin (todo el resto pasa por RPC definer) ----------
ALTER TABLE public.email_tags                 ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.contact_tags               ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.email_campaigns            ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.email_campaign_recipients  ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.email_unsubscribes         ENABLE ROW LEVEL SECURITY;

DO $$
DECLARE t text;
BEGIN
  FOREACH t IN ARRAY ARRAY['email_tags','contact_tags','email_campaigns','email_campaign_recipients','email_unsubscribes']
  LOOP
    EXECUTE format('DROP POLICY IF EXISTS %I ON public.%I', t||'_admin_all', t);
    EXECUTE format($p$CREATE POLICY %I ON public.%I FOR ALL TO authenticated USING (public.is_admin()) WITH CHECK (public.is_admin())$p$, t||'_admin_all', t);
  END LOOP;
END $$;

-- ============================================================
-- FUNCIONES
-- ============================================================

-- Guard: lanza excepción si el que llama no es admin.
CREATE OR REPLACE FUNCTION public._em_guard() RETURNS void
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
BEGIN
  IF NOT public.is_admin() THEN
    RAISE EXCEPTION 'Solo administradores';
  END IF;
END $$;

-- ---------- Etiquetas ----------
CREATE OR REPLACE FUNCTION public.admin_tags_list()
RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
DECLARE v jsonb;
BEGIN
  PERFORM public._em_guard();
  SELECT COALESCE(jsonb_agg(x ORDER BY x.name), '[]'::jsonb) INTO v
  FROM (
    SELECT t.id, t.name, t.color, t.description,
           (SELECT count(*) FROM contact_tags ct WHERE ct.tag_id = t.id) AS contacts
    FROM email_tags t
  ) x;
  RETURN v;
END $$;

CREATE OR REPLACE FUNCTION public.admin_tag_upsert(p_id uuid, p_name text, p_color text, p_description text)
RETURNS uuid LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
DECLARE v_id uuid;
BEGIN
  PERFORM public._em_guard();
  IF p_id IS NULL THEN
    INSERT INTO email_tags(name, color, description, created_by)
    VALUES (trim(p_name), COALESCE(NULLIF(trim(p_color),''),'#3D5A80'), NULLIF(trim(p_description),''), auth.uid())
    RETURNING id INTO v_id;
  ELSE
    UPDATE email_tags SET name=trim(p_name),
           color=COALESCE(NULLIF(trim(p_color),''),'#3D5A80'),
           description=NULLIF(trim(p_description),'')
    WHERE id=p_id RETURNING id INTO v_id;
  END IF;
  RETURN v_id;
END $$;

CREATE OR REPLACE FUNCTION public.admin_tag_delete(p_id uuid)
RETURNS void LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
BEGIN
  PERFORM public._em_guard();
  DELETE FROM email_tags WHERE id = p_id;
END $$;

-- Asigna/quita una etiqueta a varios contactos de una.
CREATE OR REPLACE FUNCTION public.admin_tag_assign(p_tag_id uuid, p_user_ids uuid[], p_attach boolean)
RETURNS int LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
DECLARE n int;
BEGIN
  PERFORM public._em_guard();
  IF p_attach THEN
    INSERT INTO contact_tags(tag_id, user_id)
    SELECT p_tag_id, u FROM unnest(p_user_ids) u
    ON CONFLICT DO NOTHING;
    GET DIAGNOSTICS n = ROW_COUNT;
  ELSE
    DELETE FROM contact_tags WHERE tag_id = p_tag_id AND user_id = ANY(p_user_ids);
    GET DIAGNOSTICS n = ROW_COUNT;
  END IF;
  RETURN n;
END $$;

-- Reemplaza el set completo de etiquetas de un contacto.
CREATE OR REPLACE FUNCTION public.admin_contact_tags_set(p_user_id uuid, p_tag_ids uuid[])
RETURNS void LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
BEGIN
  PERFORM public._em_guard();
  DELETE FROM contact_tags WHERE user_id = p_user_id;
  INSERT INTO contact_tags(tag_id, user_id)
  SELECT t, p_user_id FROM unnest(COALESCE(p_tag_ids,'{}')) t
  ON CONFLICT DO NOTHING;
END $$;

-- ---------- Contactos ----------
-- Lista contactos (perfiles con email) + etiquetas + estado de baja.
CREATE OR REPLACE FUNCTION public.admin_contacts(
  p_search text DEFAULT NULL, p_tag_ids uuid[] DEFAULT NULL,
  p_only_unsub boolean DEFAULT false, p_limit int DEFAULT 50, p_offset int DEFAULT 0)
RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
DECLARE v_rows jsonb; v_total int;
BEGIN
  PERFORM public._em_guard();

  WITH base AS (
    SELECT p.id, COALESCE(au.email, p.email) AS email, p.full_name, p.created_at,
           (eu.email IS NOT NULL) AS unsubscribed,
           COALESCE((SELECT array_agg(ct.tag_id) FROM contact_tags ct WHERE ct.user_id = p.id), '{}') AS tag_ids
    FROM profiles p
    LEFT JOIN auth.users au ON au.id = p.id
    LEFT JOIN email_unsubscribes eu ON eu.email = COALESCE(au.email, p.email)
    WHERE COALESCE(au.email, p.email) IS NOT NULL
  ), filtered AS (
    SELECT * FROM base b
    WHERE (p_search IS NULL OR p_search = '' OR b.email ILIKE '%'||p_search||'%' OR b.full_name ILIKE '%'||p_search||'%')
      AND (p_tag_ids IS NULL OR array_length(p_tag_ids,1) IS NULL OR b.tag_ids && p_tag_ids)
      AND (NOT p_only_unsub OR b.unsubscribed)
  )
  SELECT count(*) INTO v_total FROM filtered;

  WITH base AS (
    SELECT p.id, COALESCE(au.email, p.email) AS email, p.full_name, p.created_at,
           (eu.email IS NOT NULL) AS unsubscribed,
           COALESCE((SELECT array_agg(ct.tag_id) FROM contact_tags ct WHERE ct.user_id = p.id), '{}') AS tag_ids
    FROM profiles p
    LEFT JOIN auth.users au ON au.id = p.id
    LEFT JOIN email_unsubscribes eu ON eu.email = COALESCE(au.email, p.email)
    WHERE COALESCE(au.email, p.email) IS NOT NULL
  ), filtered AS (
    SELECT * FROM base b
    WHERE (p_search IS NULL OR p_search = '' OR b.email ILIKE '%'||p_search||'%' OR b.full_name ILIKE '%'||p_search||'%')
      AND (p_tag_ids IS NULL OR array_length(p_tag_ids,1) IS NULL OR b.tag_ids && p_tag_ids)
      AND (NOT p_only_unsub OR b.unsubscribed)
  )
  SELECT COALESCE(jsonb_agg(to_jsonb(f) ORDER BY f.created_at DESC), '[]'::jsonb) INTO v_rows
  FROM (SELECT * FROM filtered ORDER BY created_at DESC LIMIT p_limit OFFSET p_offset) f;

  RETURN jsonb_build_object('total', v_total, 'rows', v_rows);
END $$;

-- ---------- Audiencia (resolución interna) ----------
-- Devuelve los contactos alcanzables por una definición de audiencia,
-- excluyendo bajas y emails nulos. audience = {"mode":"all"} |
-- {"mode":"tags","tag_ids":[...],"match":"any|all"}
CREATE OR REPLACE FUNCTION public._em_audience(p_audience jsonb)
RETURNS TABLE(user_id uuid, email text, full_name text)
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
DECLARE v_mode text; v_match text; v_tags uuid[]; v_n int;
BEGIN
  v_mode  := COALESCE(p_audience->>'mode', 'all');
  v_match := COALESCE(p_audience->>'match', 'any');
  IF p_audience ? 'tag_ids' THEN
    SELECT array_agg((e)::uuid) INTO v_tags FROM jsonb_array_elements_text(p_audience->'tag_ids') e;
  END IF;
  v_n := COALESCE(array_length(v_tags,1), 0);

  RETURN QUERY
  SELECT p.id, COALESCE(au.email, p.email)::text AS email, p.full_name::text
  FROM profiles p
  LEFT JOIN auth.users au ON au.id = p.id
  WHERE COALESCE(au.email, p.email) IS NOT NULL
    AND NOT EXISTS (SELECT 1 FROM email_unsubscribes eu WHERE eu.email = COALESCE(au.email, p.email))
    AND (
      v_mode = 'all'
      OR (v_mode = 'tags' AND v_n > 0 AND (
            (v_match = 'any' AND EXISTS (
               SELECT 1 FROM contact_tags ct WHERE ct.user_id = p.id AND ct.tag_id = ANY(v_tags)))
         OR (v_match = 'all' AND (
               SELECT count(DISTINCT ct.tag_id) FROM contact_tags ct
               WHERE ct.user_id = p.id AND ct.tag_id = ANY(v_tags)) = v_n)
      ))
    );
END $$;

CREATE OR REPLACE FUNCTION public.admin_campaign_audience_preview(p_audience jsonb)
RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
DECLARE v_count int; v_sample jsonb;
BEGIN
  PERFORM public._em_guard();
  SELECT count(*) INTO v_count FROM public._em_audience(p_audience);
  SELECT COALESCE(jsonb_agg(x), '[]'::jsonb) INTO v_sample
  FROM (SELECT email, full_name FROM public._em_audience(p_audience) LIMIT 5) x;
  RETURN jsonb_build_object('count', v_count, 'sample', v_sample);
END $$;

-- ---------- Campañas: CRUD ----------
CREATE OR REPLACE FUNCTION public.admin_campaigns_list()
RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
DECLARE v jsonb;
BEGIN
  PERFORM public._em_guard();
  SELECT COALESCE(jsonb_agg(to_jsonb(c) ORDER BY c.updated_at DESC), '[]'::jsonb) INTO v
  FROM (
    SELECT id, name, subject, status, audience, total_recipients, sent_count,
           failed_count, opened_count, clicked_count, scheduled_at, sent_at, created_at, updated_at
    FROM email_campaigns
  ) c;
  RETURN v;
END $$;

CREATE OR REPLACE FUNCTION public.admin_campaign_get(p_id uuid)
RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
DECLARE v jsonb;
BEGIN
  PERFORM public._em_guard();
  SELECT to_jsonb(c) INTO v FROM email_campaigns c WHERE c.id = p_id;
  RETURN v;
END $$;

CREATE OR REPLACE FUNCTION public.admin_campaign_upsert(
  p_id uuid, p_name text, p_subject text, p_preheader text,
  p_from_name text, p_from_email text, p_blocks jsonb, p_html text, p_audience jsonb, p_style jsonb DEFAULT '{}'::jsonb)
RETURNS uuid LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
DECLARE v_id uuid;
BEGIN
  PERFORM public._em_guard();
  IF p_id IS NULL THEN
    INSERT INTO email_campaigns(name, subject, preheader, from_name, from_email, blocks, html, audience, style, created_by)
    VALUES (COALESCE(NULLIF(trim(p_name),''),'Campaña sin título'), COALESCE(p_subject,''), COALESCE(p_preheader,''),
            NULLIF(trim(p_from_name),''), NULLIF(trim(p_from_email),''),
            COALESCE(p_blocks,'[]'::jsonb), COALESCE(p_html,''), COALESCE(p_audience,'{"mode":"all"}'::jsonb),
            COALESCE(p_style,'{}'::jsonb), auth.uid())
    RETURNING id INTO v_id;
  ELSE
    UPDATE email_campaigns SET
      name=COALESCE(NULLIF(trim(p_name),''), name), subject=COALESCE(p_subject, subject),
      preheader=COALESCE(p_preheader, preheader), from_name=NULLIF(trim(p_from_name),''),
      from_email=NULLIF(trim(p_from_email),''), blocks=COALESCE(p_blocks, blocks),
      html=COALESCE(p_html, html), audience=COALESCE(p_audience, audience),
      style=COALESCE(p_style, style), updated_at=now()
    WHERE id=p_id AND status IN ('draft','scheduled','failed')  -- no editar enviadas
    RETURNING id INTO v_id;
    IF v_id IS NULL THEN RAISE EXCEPTION 'No se puede editar una campaña ya enviada'; END IF;
  END IF;
  RETURN v_id;
END $$;

CREATE OR REPLACE FUNCTION public.admin_campaign_delete(p_id uuid)
RETURNS void LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
BEGIN
  PERFORM public._em_guard();
  DELETE FROM email_campaigns WHERE id = p_id;
END $$;

-- ---------- Render + envío ----------
-- Templating simple sobre el HTML: reemplaza merge tags por recipiente.
CREATE OR REPLACE FUNCTION public._em_render(p_html text, p_name text, p_email text, p_unsub_url text)
RETURNS text LANGUAGE sql IMMUTABLE AS $$
  SELECT replace(replace(replace(replace(
           COALESCE(p_html,''),
           '{{name}}',            COALESCE(NULLIF(p_name,''),'emprendedor/a')),
           '{{first_name}}',      COALESCE(NULLIF(split_part(p_name,' ',1),''),'emprendedor/a')),
           '{{email}}',           COALESCE(p_email,'')),
           '{{unsubscribe_url}}', COALESCE(p_unsub_url,'#'));
$$;

-- Envía UN email por Resend con tags de tracking (correlación por recipiente).
CREATE OR REPLACE FUNCTION public._em_send_one(
  p_to text, p_subject text, p_html text, p_from text, p_rcpt_id uuid, p_unsub_url text)
RETURNS bigint LANGUAGE plpgsql SECURITY DEFINER SET search_path = public, extensions AS $$
DECLARE v_key text; v_req bigint; v_headers jsonb;
BEGIN
  v_key := (SELECT setting_value FROM app_secrets WHERE setting_key = 'resend_api_key');
  IF v_key IS NULL OR v_key = '' THEN RAISE EXCEPTION 'resend_api_key no configurada'; END IF;

  v_headers := jsonb_build_object('Content-Type','application/json','Authorization','Bearer '||v_key);

  v_req := net.http_post(
    url := 'https://api.resend.com/emails',
    headers := v_headers,
    body := jsonb_build_object(
      'from', p_from,
      'to', jsonb_build_array(p_to),
      'subject', p_subject,
      'html', p_html,
      'headers', jsonb_build_object('List-Unsubscribe', '<'||COALESCE(p_unsub_url,'')||'>'),
      'tags', jsonb_build_array(jsonb_build_object('name','rcpt_id','value', replace(p_rcpt_id::text,'-','_')))
    )
  );
  RETURN v_req;
END $$;

-- Base pública para el link de baja (config editable).
CREATE OR REPLACE FUNCTION public._em_unsub_base()
RETURNS text LANGUAGE sql STABLE AS $$
  SELECT COALESCE(NULLIF((SELECT value FROM app_config WHERE key='marketing_public_base'),''), '')
$$;

-- Envío de PRUEBA: un solo destinatario, no toca stats ni recipients.
CREATE OR REPLACE FUNCTION public.admin_campaign_send_test(p_id uuid, p_to text)
RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER SET search_path = public, extensions AS $$
DECLARE c email_campaigns%ROWTYPE; v_from text; v_html text; v_req bigint;
BEGIN
  PERFORM public._em_guard();
  SELECT * INTO c FROM email_campaigns WHERE id = p_id;
  IF NOT FOUND THEN RAISE EXCEPTION 'Campaña no encontrada'; END IF;
  IF p_to IS NULL OR p_to = '' THEN RAISE EXCEPTION 'Falta el email de prueba'; END IF;

  v_from := COALESCE(
    CASE WHEN c.from_email IS NOT NULL THEN COALESCE(c.from_name,'B2Better')||' <'||c.from_email||'>' END,
    (SELECT setting_value FROM app_secrets WHERE setting_key='resend_from'),
    'B2Better <b2better@sistemas-kodevant.online>');

  v_html := public._em_render(c.html, 'Prueba', p_to, public._em_unsub_base()||'/u/demo');
  v_req := public._em_send_one(p_to, '[PRUEBA] '||c.subject, v_html, v_from, gen_random_uuid(), public._em_unsub_base()||'/u/demo');
  RETURN jsonb_build_object('ok', true, 'request_id', v_req);
END $$;

-- Envío REAL de la campaña a toda la audiencia. Explícito, no automático.
CREATE OR REPLACE FUNCTION public.admin_campaign_send(p_id uuid)
RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER SET search_path = public, extensions AS $$
DECLARE c email_campaigns%ROWTYPE; v_from text; v_base text;
        r record; v_rcpt uuid; v_token uuid; v_html text; v_unsub text; v_n int := 0;
BEGIN
  PERFORM public._em_guard();
  SELECT * INTO c FROM email_campaigns WHERE id = p_id FOR UPDATE;
  IF NOT FOUND THEN RAISE EXCEPTION 'Campaña no encontrada'; END IF;
  IF c.status NOT IN ('draft','scheduled','failed') THEN
    RAISE EXCEPTION 'La campaña ya fue enviada (status=%)', c.status;
  END IF;
  IF COALESCE(c.subject,'') = '' THEN RAISE EXCEPTION 'La campaña no tiene asunto'; END IF;

  v_from := COALESCE(
    CASE WHEN c.from_email IS NOT NULL THEN COALESCE(c.from_name,'B2Better')||' <'||c.from_email||'>' END,
    (SELECT setting_value FROM app_secrets WHERE setting_key='resend_from'),
    'B2Better <b2better@sistemas-kodevant.online>');
  v_base := public._em_unsub_base();

  UPDATE email_campaigns SET status='sending', sent_at=now() WHERE id=p_id;

  FOR r IN SELECT * FROM public._em_audience(c.audience) LOOP
    INSERT INTO email_campaign_recipients(campaign_id, user_id, email, status)
    VALUES (p_id, r.user_id, r.email, 'pending')
    RETURNING id, unsub_token INTO v_rcpt, v_token;
    v_unsub := v_base || '/u/' || v_token::text;
    v_html  := public._em_render(c.html, r.full_name, r.email, v_unsub);
    BEGIN
      PERFORM public._em_send_one(r.email, c.subject, v_html, v_from, v_rcpt, v_unsub);
      UPDATE email_campaign_recipients SET status='sent', sent_at=now() WHERE id=v_rcpt;
      v_n := v_n + 1;
    EXCEPTION WHEN OTHERS THEN
      UPDATE email_campaign_recipients SET status='failed', error=SQLERRM WHERE id=v_rcpt;
    END;
  END LOOP;

  UPDATE email_campaigns
     SET status='sent',
         total_recipients = (SELECT count(*) FROM email_campaign_recipients WHERE campaign_id=p_id),
         sent_count       = (SELECT count(*) FROM email_campaign_recipients WHERE campaign_id=p_id AND status <> 'failed'),
         failed_count     = (SELECT count(*) FROM email_campaign_recipients WHERE campaign_id=p_id AND status = 'failed')
   WHERE id=p_id;

  RETURN jsonb_build_object('ok', true, 'sent', v_n);
END $$;

-- ---------- Baja (unsubscribe) — público ----------
CREATE OR REPLACE FUNCTION public.email_unsubscribe(p_token uuid)
RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
DECLARE r email_campaign_recipients%ROWTYPE;
BEGIN
  SELECT * INTO r FROM email_campaign_recipients WHERE unsub_token = p_token;
  IF NOT FOUND THEN RETURN jsonb_build_object('ok', false, 'error', 'link inválido'); END IF;
  INSERT INTO email_unsubscribes(email, user_id, campaign_id)
  VALUES (r.email, r.user_id, r.campaign_id)
  ON CONFLICT (email) DO NOTHING;
  RETURN jsonb_build_object('ok', true, 'email', r.email);
END $$;

-- ---------- Webhook de Resend — público (protegido por token) ----------
-- URL a configurar en Resend:
--   https://b2better.api.kodevant.space/rest/v1/rpc/resend_webhook?apikey=<ANON>
--   con el token en el body (o usar el header configurable). Ver notas.
CREATE OR REPLACE FUNCTION public.resend_webhook(p_payload jsonb, p_token text DEFAULT NULL)
RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
DECLARE v_secret text; v_type text; v_email text; v_rcpt uuid; v_tag text; v_id uuid;
BEGIN
  v_secret := (SELECT setting_value FROM app_secrets WHERE setting_key='resend_webhook_secret');
  IF v_secret IS NOT NULL AND v_secret <> '' AND COALESCE(p_token,'') <> v_secret THEN
    RAISE EXCEPTION 'token inválido';
  END IF;

  v_type  := p_payload->>'type';                         -- email.sent / email.delivered / email.opened / ...
  v_email := lower(COALESCE(p_payload#>>'{data,to,0}', p_payload#>>'{data,to}'));

  -- correlación por tag rcpt_id (uuid con '_' en vez de '-'); fallback por email.
  BEGIN
    SELECT value INTO v_tag FROM jsonb_array_elements(p_payload#>'{data,tags}') e,
      LATERAL (SELECT e->>'value' AS value, e->>'name' AS name) x WHERE x.name='rcpt_id' LIMIT 1;
  EXCEPTION WHEN OTHERS THEN v_tag := NULL; END;

  IF v_tag IS NOT NULL THEN
    v_rcpt := replace(v_tag,'_','-')::uuid;
  ELSE
    SELECT id INTO v_rcpt FROM email_campaign_recipients
    WHERE lower(email) = v_email ORDER BY created_at DESC LIMIT 1;
  END IF;

  IF v_rcpt IS NULL THEN RETURN jsonb_build_object('ok', true, 'matched', false); END IF;

  IF v_type = 'email.delivered' THEN
    UPDATE email_campaign_recipients SET status = CASE WHEN status IN ('opened','clicked') THEN status ELSE 'delivered' END WHERE id=v_rcpt;
  ELSIF v_type = 'email.opened' THEN
    UPDATE email_campaign_recipients SET status=CASE WHEN status='clicked' THEN status ELSE 'opened' END,
           opened_at=COALESCE(opened_at, now()) WHERE id=v_rcpt AND opened_at IS NULL
    RETURNING campaign_id INTO v_id;
    IF v_id IS NOT NULL THEN UPDATE email_campaigns SET opened_count=opened_count+1 WHERE id=v_id; END IF;
  ELSIF v_type = 'email.clicked' THEN
    UPDATE email_campaign_recipients SET status='clicked', clicked_at=COALESCE(clicked_at, now()) WHERE id=v_rcpt AND clicked_at IS NULL
    RETURNING campaign_id INTO v_id;
    IF v_id IS NOT NULL THEN UPDATE email_campaigns SET clicked_count=clicked_count+1 WHERE id=v_id; END IF;
  ELSIF v_type IN ('email.bounced','email.complained') THEN
    UPDATE email_campaign_recipients SET status=split_part(v_type,'.',2) WHERE id=v_rcpt;
    -- una queja/rebote duro = baja automática (protege reputación de envío)
    INSERT INTO email_unsubscribes(email, user_id, campaign_id)
    SELECT email, user_id, campaign_id FROM email_campaign_recipients WHERE id=v_rcpt
    ON CONFLICT (email) DO NOTHING;
  END IF;

  RETURN jsonb_build_object('ok', true, 'matched', true, 'type', v_type);
END $$;

-- ---------- Permisos ----------
-- Admin RPCs: solo authenticated (el guard interno valida is_admin()).
DO $$
DECLARE fn text;
BEGIN
  FOREACH fn IN ARRAY ARRAY[
    'admin_tags_list()', 'admin_tag_upsert(uuid,text,text,text)', 'admin_tag_delete(uuid)',
    'admin_tag_assign(uuid,uuid[],boolean)', 'admin_contact_tags_set(uuid,uuid[])',
    'admin_contacts(text,uuid[],boolean,integer,integer)',
    'admin_campaign_audience_preview(jsonb)', 'admin_campaigns_list()', 'admin_campaign_get(uuid)',
    'admin_campaign_upsert(uuid,text,text,text,text,text,jsonb,text,jsonb,jsonb)', 'admin_campaign_delete(uuid)',
    'admin_campaign_send_test(uuid,text)', 'admin_campaign_send(uuid)'
  ] LOOP
    EXECUTE format('REVOKE ALL ON FUNCTION public.%s FROM public, anon', fn);
    EXECUTE format('GRANT EXECUTE ON FUNCTION public.%s TO authenticated', fn);
  END LOOP;
END $$;

-- Público: baja + webhook (accesibles con anon; validan token/link internamente).
GRANT EXECUTE ON FUNCTION public.email_unsubscribe(uuid) TO anon, authenticated;
GRANT EXECUTE ON FUNCTION public.resend_webhook(jsonb, text) TO anon, authenticated;

-- Config por defecto del módulo.
INSERT INTO public.app_config(key, value)
VALUES ('marketing_public_base', '')
ON CONFLICT (key) DO NOTHING;

SELECT 'email marketing instalado' AS status;
