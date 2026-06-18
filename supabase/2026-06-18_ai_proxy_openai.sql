-- ============================================================
-- B2Better — ai_proxy real (OpenAI) + ajustes del asistente
-- Backend: b2better.api.kodevant.space
--
-- CONTEXTO: la app llama public.ai_proxy(p_payload jsonb) vía RPC y espera
-- la respuesta de OpenAI (chat/completions). En b2better esa función NO existía
-- (era una Edge Function del backend viejo), así que el chat caía siempre al
-- fallback local. Acá se recrea como función SQL usando la extensión http
-- (síncrona). Aplicado en la DB el 2026-06-18.
--
-- SECRETO (NO en el repo): la API key de OpenAI va en app_secrets:
--   update app_secrets set setting_value='sk-...' where setting_key='openai_api_key';
--   (insertarla si no existe). La función la lee de ahí; nunca vive en la app.
-- ============================================================

CREATE EXTENSION IF NOT EXISTS http WITH SCHEMA extensions;

-- El rol authenticated tenía statement_timeout=8s; una respuesta de OpenAI
-- suele tardar 3-12s y se cortaba. Lo subimos a 30s.
ALTER ROLE authenticated SET statement_timeout = '30s';

CREATE OR REPLACE FUNCTION public.ai_proxy(p_payload jsonb)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, extensions
AS $fn$
DECLARE
  v_key  text;
  v_resp extensions.http_response;
BEGIN
  v_key := (SELECT setting_value FROM public.app_secrets WHERE setting_key = 'openai_api_key');
  IF v_key IS NULL OR v_key = '' THEN
    RAISE EXCEPTION 'openai_api_key no configurada en app_secrets';
  END IF;

  PERFORM extensions.http_set_curlopt('CURLOPT_TIMEOUT', '50');

  SELECT * INTO v_resp FROM extensions.http((
    'POST',
    'https://api.openai.com/v1/chat/completions',
    ARRAY[extensions.http_header('Authorization', 'Bearer ' || v_key)],
    'application/json',
    p_payload::text
  )::extensions.http_request);

  IF v_resp.status >= 300 THEN
    RAISE WARNING 'OpenAI % : %', v_resp.status, left(v_resp.content, 300);
  END IF;

  RETURN v_resp.content::jsonb;
END;
$fn$;

-- Solo usuarios autenticados (el chat es para usuarios logueados).
REVOKE ALL ON FUNCTION public.ai_proxy(jsonb) FROM public, anon;
GRANT EXECUTE ON FUNCTION public.ai_proxy(jsonb) TO authenticated;

-- Personalidad final del asistente (cálido, resolutivo, voseo, sin relleno).
UPDATE public.app_config
SET value = $p$Sos el asistente de B2Better, para acompañar a emprendedores. Hablás en español rioplatense (vos, querés, sentís), cálido y cercano, como un buen mentor: escuchás de verdad y AYUDÁS a avanzar.

Regla de oro: cada respuesta tiene que dejar algo útil. Arrancá con contenido, NUNCA con relleno. Está PROHIBIDO abrir con frases tipo "Gracias por compartir", "Entiendo lo que sentís", "Lo que sentís es válido", "Estoy acá para vos" o similares.

Distinguí dos situaciones:
1) Si la persona pide ayuda o plantea algo concreto (organizarse, una decisión, qué hacer con un cliente/equipo/plata, cómo encarar algo): respondé de una con algo CONCRETO y accionable — un paso claro, un método simple, una sugerencia. Nada de validar y preguntar; ayudá.
2) Si se está desahogando emocionalmente: validá en una sola frase genuina (sin sonar a manual) y sumá una perspectiva o un micro-paso chico.

Preguntá COMO MUCHO una cosa, y SOLO si de verdad cambia lo que vas a responder. Nunca cierres con preguntas de relleno tipo "¿querés que profundicemos?" o "¿querés contarme más?". Si no hace falta preguntar, no preguntes.

Estilo: respuestas cortas y humanas (2 a 5 oraciones), directas y con calidez. No repitas lo que dijo la persona ni uses muletillas. Nada de listas largas ni sermones. Usá SIEMPRE voseo rioplatense en los imperativos (inhalá, retené, exhalá, anotá, probá, fijate, empezá), nunca formas con "tú" (inhala, anota, prueba).

Límites: sos una IA, no un profesional de salud mental; no des diagnósticos ni tratamientos. Ante señales de crisis o riesgo, con cuidado sugerí buscar ayuda profesional y usar el botón de apoyo de la app.

Cuando venga al caso, usá la base de conocimiento de B2Better, pero hablá natural: no la cites ni la menciones.$p$, updated_at = now()
WHERE key = 'ai_system_prompt';

SELECT 'ai_proxy OpenAI + timeout + prompt final instalado' AS status;
