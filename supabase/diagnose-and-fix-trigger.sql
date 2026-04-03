-- ============================================
-- DIAGNÓSTICO + FIX: User creation error
-- Correr en Supabase SQL Editor
-- ============================================

-- 1. Check if trigger function exists
SELECT
  proname AS function_name,
  prosecdef AS is_security_definer,
  prorettype::regtype AS return_type
FROM pg_proc
WHERE proname = 'handle_new_user';

-- 2. Check if trigger exists on auth.users
SELECT
  tgname AS trigger_name,
  tgtype,
  tgenabled
FROM pg_trigger
WHERE tgname = 'on_auth_user_created';

-- 3. Check profiles table columns (verify is_admin exists)
SELECT column_name, data_type, column_default, is_nullable
FROM information_schema.columns
WHERE table_schema = 'public' AND table_name = 'profiles'
ORDER BY ordinal_position;

-- 4. Check all triggers on auth.users
SELECT tgname, tgenabled, tgtype
FROM pg_trigger t
JOIN pg_class c ON t.tgrelid = c.oid
JOIN pg_namespace n ON c.relnamespace = n.oid
WHERE n.nspname = 'auth' AND c.relname = 'users';

-- 5. Check all policies on profiles
SELECT policyname, cmd, permissive, roles, qual, with_check
FROM pg_policies
WHERE tablename = 'profiles';

-- ============================================
-- FIX: Drop and recreate trigger + function
-- ============================================

-- Drop existing trigger (safe)
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;

-- Drop existing function (safe)
DROP FUNCTION IF EXISTS handle_new_user();

-- Recreate function
CREATE OR REPLACE FUNCTION handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO profiles (id, full_name)
  VALUES (NEW.id, COALESCE(NEW.raw_user_meta_data->>'full_name', ''));
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Recreate trigger
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION handle_new_user();

-- Verify fix
SELECT 'Trigger recreated successfully' AS status;
