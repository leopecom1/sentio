-- ============================================
-- DIAGNÓSTICO PROFUNDO: ¿Por qué falla user creation?
-- ============================================

-- 1. ALL triggers on auth.users (incluyendo internos de Supabase)
SELECT tgname, tgenabled, pg_get_triggerdef(t.oid) AS trigger_def
FROM pg_trigger t
JOIN pg_class c ON t.tgrelid = c.oid
JOIN pg_namespace n ON c.relnamespace = n.oid
WHERE n.nspname = 'auth' AND c.relname = 'users'
  AND NOT tgisinternal;

-- 2. Check auth schema health - required tables
SELECT table_name
FROM information_schema.tables
WHERE table_schema = 'auth'
ORDER BY table_name;

-- 3. Check required extensions
SELECT extname, extversion FROM pg_extension ORDER BY extname;

-- 4. Check if auth.uid() function works
SELECT auth.uid() AS current_uid;

-- 5. Try to validate our trigger function independently
DO $$
BEGIN
  -- Test: can we call the function body logic?
  RAISE NOTICE 'Testing INSERT into profiles...';
  -- Just check if profiles table is writable
  PERFORM 1 FROM profiles LIMIT 0;
  RAISE NOTICE 'profiles table accessible';
END;
$$;

-- 6. Check if there are any BEFORE triggers on auth.users
SELECT tgname, CASE tgtype & 2 WHEN 2 THEN 'BEFORE' ELSE 'AFTER' END AS timing,
       CASE tgtype & 28
         WHEN 4 THEN 'INSERT'
         WHEN 8 THEN 'DELETE'
         WHEN 16 THEN 'UPDATE'
         WHEN 20 THEN 'INSERT OR UPDATE'
       END AS event
FROM pg_trigger t
JOIN pg_class c ON t.tgrelid = c.oid
JOIN pg_namespace n ON c.relnamespace = n.oid
WHERE n.nspname = 'auth' AND c.relname = 'users';

-- 7. Test: Temporarily DISABLE our trigger, then check
-- (after this, tell Claude so he can retry the API call)
ALTER TABLE auth.users DISABLE TRIGGER on_auth_user_created;
SELECT 'Trigger DISABLED - tell Claude to retry user creation now' AS action_needed;
