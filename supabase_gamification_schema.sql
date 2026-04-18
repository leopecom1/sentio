-- ============================================================
-- Sentio Gamification Schema (Admin-Managed)
-- Run this in Supabase SQL Editor
-- ============================================================

-- 1. Point Rules: admin-configurable XP rewards per action
CREATE TABLE IF NOT EXISTS point_rules (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  action_key TEXT NOT NULL UNIQUE,
  label TEXT NOT NULL,
  description TEXT,
  xp_amount INT NOT NULL DEFAULT 0,
  icon TEXT DEFAULT 'star',
  category TEXT DEFAULT 'general',
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

-- 2. Levels: admin-configurable level thresholds
CREATE TABLE IF NOT EXISTS gamification_levels (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  level INT NOT NULL UNIQUE,
  title TEXT NOT NULL,
  xp_required INT NOT NULL DEFAULT 0,
  icon TEXT DEFAULT 'shield',
  created_at TIMESTAMPTZ DEFAULT now()
);

-- 3. Achievements: admin-configurable badges/achievements
CREATE TABLE IF NOT EXISTS gamification_achievements (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  achievement_key TEXT NOT NULL UNIQUE,
  name TEXT NOT NULL,
  description TEXT,
  icon TEXT DEFAULT 'emoji_events',
  category TEXT DEFAULT 'general',
  condition_type TEXT NOT NULL DEFAULT 'count',
  condition_field TEXT,
  condition_value INT DEFAULT 1,
  xp_reward INT DEFAULT 0,
  is_active BOOLEAN DEFAULT true,
  sort_order INT DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

-- 4. User Points Log: immutable event log of all XP transactions
CREATE TABLE IF NOT EXISTS user_points_log (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  action_key TEXT NOT NULL,
  xp_amount INT NOT NULL,
  description TEXT,
  created_at TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX idx_user_points_log_user_id ON user_points_log(user_id);
CREATE INDEX idx_user_points_log_created_at ON user_points_log(created_at DESC);

-- 5. User Achievements: tracks which achievements each user has unlocked
CREATE TABLE IF NOT EXISTS user_achievements (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  achievement_key TEXT NOT NULL,
  unlocked_at TIMESTAMPTZ DEFAULT now(),
  UNIQUE(user_id, achievement_key)
);

CREATE INDEX idx_user_achievements_user_id ON user_achievements(user_id);

-- 6. Add total_xp column to profiles if not exists
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'profiles' AND column_name = 'total_xp') THEN
    ALTER TABLE profiles ADD COLUMN total_xp INT DEFAULT 0;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'profiles' AND column_name = 'current_level') THEN
    ALTER TABLE profiles ADD COLUMN current_level INT DEFAULT 1;
  END IF;
END $$;

-- ============================================================
-- RLS Policies
-- ============================================================

ALTER TABLE point_rules ENABLE ROW LEVEL SECURITY;
ALTER TABLE gamification_levels ENABLE ROW LEVEL SECURITY;
ALTER TABLE gamification_achievements ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_points_log ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_achievements ENABLE ROW LEVEL SECURITY;

-- Point rules: anyone can read (app needs them), only service role can modify
CREATE POLICY "point_rules_select" ON point_rules FOR SELECT USING (true);
CREATE POLICY "point_rules_insert" ON point_rules FOR INSERT WITH CHECK (true);
CREATE POLICY "point_rules_update" ON point_rules FOR UPDATE USING (true);
CREATE POLICY "point_rules_delete" ON point_rules FOR DELETE USING (true);

-- Levels: anyone can read
CREATE POLICY "gamification_levels_select" ON gamification_levels FOR SELECT USING (true);
CREATE POLICY "gamification_levels_insert" ON gamification_levels FOR INSERT WITH CHECK (true);
CREATE POLICY "gamification_levels_update" ON gamification_levels FOR UPDATE USING (true);
CREATE POLICY "gamification_levels_delete" ON gamification_levels FOR DELETE USING (true);

-- Achievements: anyone can read
CREATE POLICY "gamification_achievements_select" ON gamification_achievements FOR SELECT USING (true);
CREATE POLICY "gamification_achievements_insert" ON gamification_achievements FOR INSERT WITH CHECK (true);
CREATE POLICY "gamification_achievements_update" ON gamification_achievements FOR UPDATE USING (true);
CREATE POLICY "gamification_achievements_delete" ON gamification_achievements FOR DELETE USING (true);

-- User points log: user can read own, insert own
CREATE POLICY "user_points_log_select" ON user_points_log FOR SELECT USING (true);
CREATE POLICY "user_points_log_insert" ON user_points_log FOR INSERT WITH CHECK (auth.uid() = user_id);

-- User achievements: user can read own, insert own
CREATE POLICY "user_achievements_select" ON user_achievements FOR SELECT USING (true);
CREATE POLICY "user_achievements_insert" ON user_achievements FOR INSERT WITH CHECK (auth.uid() = user_id);

-- ============================================================
-- Seed: Default Point Rules
-- ============================================================

INSERT INTO point_rules (action_key, label, description, xp_amount, icon, category) VALUES
  ('checkin', 'Check-in diario', 'Realizar un check-in emocional', 20, 'favorite', 'bienestar'),
  ('deep_checkin', 'Check-in profundo', 'Check-in con reflexión profunda', 35, 'psychology', 'bienestar'),
  ('journal_entry', 'Entrada de diario', 'Escribir en el diario personal', 25, 'edit_note', 'bienestar'),
  ('chat_session', 'Conversación con Coach', 'Sesión de chat con el coach IA', 15, 'chat', 'bienestar'),
  ('tool_completed', 'Herramienta completada', 'Completar una herramienta de bienestar', 30, 'air', 'herramientas'),
  ('routine_completed', 'Rutina completada', 'Completar una rutina diaria', 40, 'repeat', 'herramientas'),
  ('community_post', 'Post en comunidad', 'Publicar en la comunidad', 10, 'group', 'comunidad'),
  ('community_story', 'Historia publicada', 'Publicar una historia', 10, 'auto_stories', 'comunidad'),
  ('streak_bonus_7', 'Racha de 7 días', 'Bonus por 7 días consecutivos', 100, 'local_fire_department', 'rachas'),
  ('streak_bonus_30', 'Racha de 30 días', 'Bonus por 30 días consecutivos', 300, 'whatshot', 'rachas'),
  ('transaction', 'Transacción registrada', 'Registrar una transacción financiera', 10, 'account_balance_wallet', 'finanzas'),
  ('account_created', 'Cuenta creada', 'Crear una cuenta financiera', 15, 'add_card', 'finanzas'),
  ('receipt_scan', 'Ticket escaneado', 'Escanear un ticket/recibo', 20, 'document_scanner', 'finanzas')
ON CONFLICT (action_key) DO NOTHING;

-- ============================================================
-- Function: Increment user XP
-- ============================================================

CREATE OR REPLACE FUNCTION increment_user_xp(p_user_id UUID, p_amount INT)
RETURNS VOID AS $$
BEGIN
  UPDATE profiles
  SET total_xp = COALESCE(total_xp, 0) + p_amount
  WHERE id = p_user_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================================
-- Seed: Default Levels
-- ============================================================

INSERT INTO gamification_levels (level, title, xp_required, icon) VALUES
  (1, 'Iniciado', 0, 'egg'),
  (2, 'Explorador Interior', 250, 'explore'),
  (3, 'Observador Consciente', 600, 'visibility'),
  (4, 'Guerrero Resiliente', 1000, 'shield'),
  (5, 'Maestro del Equilibrio', 1500, 'balance'),
  (6, 'Guardián de la Calma', 2200, 'spa'),
  (7, 'Voluntad de Hierro', 3000, 'fitness_center'),
  (8, 'Líder Interior', 4000, 'stars')
ON CONFLICT (level) DO NOTHING;

-- ============================================================
-- Seed: Default Achievements
-- ============================================================

INSERT INTO gamification_achievements (achievement_key, name, description, icon, category, condition_type, condition_field, condition_value, xp_reward, sort_order) VALUES
  ('first_checkin', 'Primer Paso', 'Realiza tu primer check-in', 'emoji_events', 'checkin', 'count', 'total_checkins', 1, 50, 1),
  ('writer_5', 'Escritor Nocturno', 'Escribe 5 entradas de diario', 'edit_note', 'journal', 'count', 'total_journal_entries', 5, 75, 2),
  ('streak_7', 'Racha de 7', 'Mantén 7 días consecutivos', 'local_fire_department', 'checkin', 'count', 'longest_streak', 7, 100, 3),
  ('breather_10', 'Respirador', 'Usa 10 herramientas de bienestar', 'air', 'tools', 'count', 'total_tools_used', 10, 75, 4),
  ('talker_10', 'Voz Interior', 'Envía 50 mensajes al coach', 'chat', 'chat', 'count', 'total_chat_messages', 50, 75, 5),
  ('connected', 'Conectado', 'Publica tu primer post', 'group', 'community', 'count', 'posts_count', 1, 50, 6),
  ('streak_30', 'Constante', 'Mantén 30 días de racha', 'whatshot', 'checkin', 'count', 'longest_streak', 30, 200, 7),
  ('routine_10', 'Rutinario', 'Completa 20 rutinas', 'repeat', 'routines', 'count', 'total_tools_used', 20, 100, 8),
  ('resilient', 'Resiliente', 'Alcanza el nivel 5', 'shield', 'milestone', 'level', 'current_level', 5, 150, 9),
  ('finance_first', 'Primer Registro', 'Registra tu primera transacción', 'account_balance_wallet', 'finance', 'count', 'total_transactions', 1, 50, 10),
  ('finance_10', 'Control Financiero', '10 transacciones registradas', 'trending_up', 'finance', 'count', 'total_transactions', 10, 100, 11),
  ('receipt_scanner', 'Scanner Pro', 'Escanea 5 tickets', 'document_scanner', 'finance', 'count', 'total_receipts', 5, 75, 12)
ON CONFLICT (achievement_key) DO NOTHING;
