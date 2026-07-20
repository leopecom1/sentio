-- ============================================================
-- B2Better — #7 Panel de uso: métricas de todas las secciones
-- Backend: b2better.api.kodevant.space  ·  2026-07-10
--
-- RPC admin-only que devuelve la serie diaria de uso por sección
-- (check-ins, diario, finanzas, comunidad, herramientas, chats IA),
-- usuarios activos por día (DAU) y logins (proxy de aperturas), en un
-- solo payload. El dashboard del admin lo consume y grafica.
-- ============================================================

CREATE OR REPLACE FUNCTION public.admin_usage_metrics(p_days int DEFAULT 14)
RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER SET search_path = public, auth AS $fn$
DECLARE v_days jsonb; v_from date;
BEGIN
  IF NOT public.is_admin() THEN RAISE EXCEPTION 'Solo administradores'; END IF;
  p_days := greatest(1, least(p_days, 90));
  v_from := current_date - (p_days - 1);

  WITH spine AS (SELECT generate_series(v_from, current_date, interval '1 day')::date d),
  ck AS (SELECT created_at::date d, count(*) n FROM checkins WHERE created_at >= v_from GROUP BY 1),
  jr AS (SELECT created_at::date d, count(*) n FROM journal_entries WHERE created_at >= v_from GROUP BY 1),
  fi AS (SELECT created_at::date d, count(*) n FROM financial_transactions WHERE created_at >= v_from GROUP BY 1),
  co AS (SELECT created_at::date d, count(*) n FROM community_posts WHERE created_at >= v_from GROUP BY 1),
  tl AS (SELECT created_at::date d, count(*) n FROM tool_usage WHERE created_at >= v_from GROUP BY 1),
  ch AS (SELECT created_at::date d, count(*) n FROM chat_messages WHERE role='user' AND created_at >= v_from GROUP BY 1),
  lg AS (SELECT created_at::date d, count(*) n FROM auth.sessions WHERE created_at >= v_from GROUP BY 1),
  act AS (
    SELECT d, count(DISTINCT user_id) u FROM (
      SELECT created_at::date d, user_id FROM checkins WHERE created_at >= v_from
      UNION ALL SELECT created_at::date, user_id FROM journal_entries WHERE created_at >= v_from
      UNION ALL SELECT created_at::date, user_id FROM financial_transactions WHERE created_at >= v_from
      UNION ALL SELECT created_at::date, user_id FROM community_posts WHERE created_at >= v_from
      UNION ALL SELECT created_at::date, user_id FROM tool_usage WHERE created_at >= v_from
      UNION ALL SELECT created_at::date, user_id FROM chat_messages WHERE created_at >= v_from
    ) a GROUP BY d
  )
  SELECT jsonb_agg(jsonb_build_object(
      'date', s.d,
      'active_users', COALESCE(act.u,0),
      'logins',   COALESCE(lg.n,0),
      'checkins', COALESCE(ck.n,0),
      'journal',  COALESCE(jr.n,0),
      'finance',  COALESCE(fi.n,0),
      'community',COALESCE(co.n,0),
      'tools',    COALESCE(tl.n,0),
      'chats',    COALESCE(ch.n,0)
    ) ORDER BY s.d)
  INTO v_days
  FROM spine s
  LEFT JOIN ck ON ck.d=s.d LEFT JOIN jr ON jr.d=s.d LEFT JOIN fi ON fi.d=s.d
  LEFT JOIN co ON co.d=s.d LEFT JOIN tl ON tl.d=s.d LEFT JOIN ch ON ch.d=s.d
  LEFT JOIN lg ON lg.d=s.d LEFT JOIN act ON act.d=s.d;

  RETURN jsonb_build_object(
    'days', COALESCE(v_days, '[]'::jsonb),
    'summary', jsonb_build_object(
      'total_users', (SELECT count(*) FROM profiles),
      'dau', (SELECT count(DISTINCT user_id) FROM (
                SELECT user_id FROM checkins WHERE created_at::date=current_date
                UNION SELECT user_id FROM journal_entries WHERE created_at::date=current_date
                UNION SELECT user_id FROM financial_transactions WHERE created_at::date=current_date
                UNION SELECT user_id FROM community_posts WHERE created_at::date=current_date
                UNION SELECT user_id FROM tool_usage WHERE created_at::date=current_date
                UNION SELECT user_id FROM chat_messages WHERE created_at::date=current_date) x),
      'wau', (SELECT count(DISTINCT user_id) FROM (
                SELECT user_id FROM checkins WHERE created_at >= current_date-6
                UNION SELECT user_id FROM journal_entries WHERE created_at >= current_date-6
                UNION SELECT user_id FROM financial_transactions WHERE created_at >= current_date-6
                UNION SELECT user_id FROM community_posts WHERE created_at >= current_date-6
                UNION SELECT user_id FROM tool_usage WHERE created_at >= current_date-6
                UNION SELECT user_id FROM chat_messages WHERE created_at >= current_date-6) x),
      'mau', (SELECT count(DISTINCT user_id) FROM (
                SELECT user_id FROM checkins WHERE created_at >= current_date-29
                UNION SELECT user_id FROM journal_entries WHERE created_at >= current_date-29
                UNION SELECT user_id FROM financial_transactions WHERE created_at >= current_date-29
                UNION SELECT user_id FROM community_posts WHERE created_at >= current_date-29
                UNION SELECT user_id FROM tool_usage WHERE created_at >= current_date-29
                UNION SELECT user_id FROM chat_messages WHERE created_at >= current_date-29) x)
    )
  );
END $fn$;

REVOKE ALL ON FUNCTION public.admin_usage_metrics(int) FROM public, anon;
GRANT EXECUTE ON FUNCTION public.admin_usage_metrics(int) TO authenticated;

SELECT 'admin_usage_metrics instalado' AS status;
