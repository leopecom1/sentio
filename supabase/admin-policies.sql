-- ============================================
-- SENTIO — Admin RLS Policies
-- Run this AFTER schema.sql has been applied
-- ============================================

-- ============================================
-- 1. Add is_admin column to profiles
-- ============================================
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS is_admin BOOLEAN DEFAULT FALSE;

-- ============================================
-- 2. Admin SELECT policies for all tables
-- Allows admins to read ALL rows in each table
-- ============================================

-- Profiles: admin can see all users
CREATE POLICY "Admins can read all profiles"
  ON profiles FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM profiles
      WHERE id = auth.uid() AND is_admin = true
    )
  );

-- Checkins: admin can see all check-ins
CREATE POLICY "Admins can read all checkins"
  ON checkins FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM profiles
      WHERE id = auth.uid() AND is_admin = true
    )
  );

-- Journal entries: admin can see all entries
CREATE POLICY "Admins can read all journal_entries"
  ON journal_entries FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM profiles
      WHERE id = auth.uid() AND is_admin = true
    )
  );

-- Chat conversations: admin can see all conversations
CREATE POLICY "Admins can read all chat_conversations"
  ON chat_conversations FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM profiles
      WHERE id = auth.uid() AND is_admin = true
    )
  );

-- Chat messages: admin can see all messages
CREATE POLICY "Admins can read all chat_messages"
  ON chat_messages FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM profiles
      WHERE id = auth.uid() AND is_admin = true
    )
  );

-- Tool usage: admin can see all usage
CREATE POLICY "Admins can read all tool_usage"
  ON tool_usage FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM profiles
      WHERE id = auth.uid() AND is_admin = true
    )
  );

-- Articles: admin can see ALL articles (including unpublished)
CREATE POLICY "Admins can read all articles"
  ON articles FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM profiles
      WHERE id = auth.uid() AND is_admin = true
    )
  );

-- Daily phrases: admin can see ALL phrases (including inactive)
CREATE POLICY "Admins can read all daily_phrases"
  ON daily_phrases FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM profiles
      WHERE id = auth.uid() AND is_admin = true
    )
  );

-- Routines: admin can see ALL routines (including unpublished)
CREATE POLICY "Admins can read all routines"
  ON routines FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM profiles
      WHERE id = auth.uid() AND is_admin = true
    )
  );

-- ============================================
-- 3. Admin INSERT/UPDATE/DELETE on content tables
-- (articles, daily_phrases, routines)
-- ============================================

-- Articles: admin full CRUD
CREATE POLICY "Admins can insert articles"
  ON articles FOR INSERT
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM profiles
      WHERE id = auth.uid() AND is_admin = true
    )
  );

CREATE POLICY "Admins can update articles"
  ON articles FOR UPDATE
  USING (
    EXISTS (
      SELECT 1 FROM profiles
      WHERE id = auth.uid() AND is_admin = true
    )
  );

CREATE POLICY "Admins can delete articles"
  ON articles FOR DELETE
  USING (
    EXISTS (
      SELECT 1 FROM profiles
      WHERE id = auth.uid() AND is_admin = true
    )
  );

-- Daily phrases: admin full CRUD
CREATE POLICY "Admins can insert daily_phrases"
  ON daily_phrases FOR INSERT
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM profiles
      WHERE id = auth.uid() AND is_admin = true
    )
  );

CREATE POLICY "Admins can update daily_phrases"
  ON daily_phrases FOR UPDATE
  USING (
    EXISTS (
      SELECT 1 FROM profiles
      WHERE id = auth.uid() AND is_admin = true
    )
  );

CREATE POLICY "Admins can delete daily_phrases"
  ON daily_phrases FOR DELETE
  USING (
    EXISTS (
      SELECT 1 FROM profiles
      WHERE id = auth.uid() AND is_admin = true
    )
  );

-- Routines: admin full CRUD
CREATE POLICY "Admins can insert routines"
  ON routines FOR INSERT
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM profiles
      WHERE id = auth.uid() AND is_admin = true
    )
  );

CREATE POLICY "Admins can update routines"
  ON routines FOR UPDATE
  USING (
    EXISTS (
      SELECT 1 FROM profiles
      WHERE id = auth.uid() AND is_admin = true
    )
  );

CREATE POLICY "Admins can delete routines"
  ON routines FOR DELETE
  USING (
    EXISTS (
      SELECT 1 FROM profiles
      WHERE id = auth.uid() AND is_admin = true
    )
  );

-- ============================================
-- 4. Admin can update profiles (e.g. toggle is_admin)
-- ============================================
CREATE POLICY "Admins can update all profiles"
  ON profiles FOR UPDATE
  USING (
    EXISTS (
      SELECT 1 FROM profiles
      WHERE id = auth.uid() AND is_admin = true
    )
  );

-- ============================================
-- 5. Helper: Promote a user to admin
-- Run manually in SQL editor replacing the UUID:
--
--   UPDATE profiles SET is_admin = true WHERE id = 'YOUR-USER-UUID-HERE';
--
-- Or by email (requires auth.users join):
--
--   UPDATE profiles SET is_admin = true
--   WHERE id = (SELECT id FROM auth.users WHERE email = 'admin@sentio.app');
--
-- ============================================
