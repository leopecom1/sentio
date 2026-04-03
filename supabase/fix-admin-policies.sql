-- ============================================
-- FIX: Admin policies recursion issue
-- The problem: "Admins can read all profiles" policy
-- does SELECT on profiles → triggers same policy → infinite loop
-- Solution: SECURITY DEFINER function bypasses RLS
-- ============================================

-- 1. Create helper function that bypasses RLS to check admin status
CREATE OR REPLACE FUNCTION public.is_admin()
RETURNS BOOLEAN AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.profiles
    WHERE id = auth.uid() AND is_admin = true
  );
$$ LANGUAGE sql SECURITY DEFINER STABLE;

-- 2. Drop ALL the broken admin policies
DROP POLICY IF EXISTS "Admins can read all profiles" ON profiles;
DROP POLICY IF EXISTS "Admins can read all checkins" ON checkins;
DROP POLICY IF EXISTS "Admins can read all journal_entries" ON journal_entries;
DROP POLICY IF EXISTS "Admins can read all chat_conversations" ON chat_conversations;
DROP POLICY IF EXISTS "Admins can read all chat_messages" ON chat_messages;
DROP POLICY IF EXISTS "Admins can read all tool_usage" ON tool_usage;
DROP POLICY IF EXISTS "Admins can read all articles" ON articles;
DROP POLICY IF EXISTS "Admins can read all daily_phrases" ON daily_phrases;
DROP POLICY IF EXISTS "Admins can read all routines" ON routines;
DROP POLICY IF EXISTS "Admins can insert articles" ON articles;
DROP POLICY IF EXISTS "Admins can update articles" ON articles;
DROP POLICY IF EXISTS "Admins can delete articles" ON articles;
DROP POLICY IF EXISTS "Admins can insert daily_phrases" ON daily_phrases;
DROP POLICY IF EXISTS "Admins can update daily_phrases" ON daily_phrases;
DROP POLICY IF EXISTS "Admins can delete daily_phrases" ON daily_phrases;
DROP POLICY IF EXISTS "Admins can insert routines" ON routines;
DROP POLICY IF EXISTS "Admins can update routines" ON routines;
DROP POLICY IF EXISTS "Admins can delete routines" ON routines;
DROP POLICY IF EXISTS "Admins can update all profiles" ON profiles;

-- 3. Re-create all admin policies using is_admin() function (no recursion)

-- SELECT policies
CREATE POLICY "Admins can read all profiles"
  ON profiles FOR SELECT USING (public.is_admin());

CREATE POLICY "Admins can read all checkins"
  ON checkins FOR SELECT USING (public.is_admin());

CREATE POLICY "Admins can read all journal_entries"
  ON journal_entries FOR SELECT USING (public.is_admin());

CREATE POLICY "Admins can read all chat_conversations"
  ON chat_conversations FOR SELECT USING (public.is_admin());

CREATE POLICY "Admins can read all chat_messages"
  ON chat_messages FOR SELECT USING (public.is_admin());

CREATE POLICY "Admins can read all tool_usage"
  ON tool_usage FOR SELECT USING (public.is_admin());

CREATE POLICY "Admins can read all articles"
  ON articles FOR SELECT USING (public.is_admin());

CREATE POLICY "Admins can read all daily_phrases"
  ON daily_phrases FOR SELECT USING (public.is_admin());

CREATE POLICY "Admins can read all routines"
  ON routines FOR SELECT USING (public.is_admin());

-- Admin UPDATE on profiles
CREATE POLICY "Admins can update all profiles"
  ON profiles FOR UPDATE USING (public.is_admin());

-- Articles: admin full CRUD
CREATE POLICY "Admins can insert articles"
  ON articles FOR INSERT WITH CHECK (public.is_admin());

CREATE POLICY "Admins can update articles"
  ON articles FOR UPDATE USING (public.is_admin());

CREATE POLICY "Admins can delete articles"
  ON articles FOR DELETE USING (public.is_admin());

-- Daily phrases: admin full CRUD
CREATE POLICY "Admins can insert daily_phrases"
  ON daily_phrases FOR INSERT WITH CHECK (public.is_admin());

CREATE POLICY "Admins can update daily_phrases"
  ON daily_phrases FOR UPDATE USING (public.is_admin());

CREATE POLICY "Admins can delete daily_phrases"
  ON daily_phrases FOR DELETE USING (public.is_admin());

-- Routines: admin full CRUD
CREATE POLICY "Admins can insert routines"
  ON routines FOR INSERT WITH CHECK (public.is_admin());

CREATE POLICY "Admins can update routines"
  ON routines FOR UPDATE USING (public.is_admin());

CREATE POLICY "Admins can delete routines"
  ON routines FOR DELETE USING (public.is_admin());
