-- ============================================
-- SENTIO — Database Schema
-- Bienestar emocional para emprendedores
-- ============================================

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ============================================
-- PROFILES (extends Supabase auth.users)
-- ============================================
CREATE TABLE profiles (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  full_name TEXT,
  avatar_url TEXT,
  timezone TEXT DEFAULT 'America/Argentina/Buenos_Aires',
  onboarding_completed BOOLEAN DEFAULT FALSE,
  -- Onboarding data
  pressure_types TEXT[] DEFAULT '{}', -- financial, burnout, loneliness, fear, decisions, disconnect, frustration, team
  current_mood TEXT, -- from onboarding
  initial_energy INTEGER, -- 1-5
  goals TEXT[] DEFAULT '{}', -- discharge, tools, patterns, companion, organize, all
  preferred_companion_style TEXT DEFAULT 'balanced', -- gentle, direct, balanced
  -- Subscription
  plan TEXT DEFAULT 'free' CHECK (plan IN ('free', 'premium')),
  plan_expires_at TIMESTAMPTZ,
  -- Engagement
  checkin_streak INTEGER DEFAULT 0,
  longest_streak INTEGER DEFAULT 0,
  total_checkins INTEGER DEFAULT 0,
  total_journal_entries INTEGER DEFAULT 0,
  total_chat_messages INTEGER DEFAULT 0,
  total_tools_used INTEGER DEFAULT 0,
  last_active_at TIMESTAMPTZ DEFAULT NOW(),
  -- Preferences
  morning_reminder BOOLEAN DEFAULT TRUE,
  evening_reminder BOOLEAN DEFAULT TRUE,
  reminder_morning_time TIME DEFAULT '08:00',
  reminder_evening_time TIME DEFAULT '21:00',
  theme TEXT DEFAULT 'light' CHECK (theme IN ('light', 'dark', 'system')),
  language TEXT DEFAULT 'es',
  -- Metadata
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================
-- CHECK-INS
-- ============================================
CREATE TABLE checkins (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  -- Core emotions
  primary_emotion TEXT NOT NULL, -- calm, focused, motivated, grateful, hopeful, tired, overwhelmed, anxious, frustrated, sad, insecure, lonely, pressured, angry, blocked
  energy_level INTEGER NOT NULL CHECK (energy_level BETWEEN 1 AND 5),
  stress_level INTEGER NOT NULL CHECK (stress_level BETWEEN 1 AND 5),
  -- Deep check-in (optional)
  mental_clarity INTEGER CHECK (mental_clarity BETWEEN 1 AND 5),
  motivation_level INTEGER CHECK (motivation_level BETWEEN 1 AND 5),
  financial_pressure INTEGER CHECK (financial_pressure BETWEEN 1 AND 5),
  control_feeling INTEGER CHECK (control_feeling BETWEEN 1 AND 5),
  day_quality INTEGER CHECK (day_quality BETWEEN 1 AND 5),
  -- Text
  note TEXT,
  note_prompt TEXT, -- which prompt was shown
  -- Metadata
  is_deep BOOLEAN DEFAULT FALSE,
  is_crisis BOOLEAN DEFAULT FALSE, -- stress=5 + energy=1
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_checkins_user_date ON checkins(user_id, created_at DESC);
CREATE INDEX idx_checkins_emotion ON checkins(primary_emotion);

-- ============================================
-- JOURNAL ENTRIES
-- ============================================
CREATE TABLE journal_entries (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  content TEXT NOT NULL,
  prompt_used TEXT, -- which prompt was shown (if any)
  -- Emotional context
  dominant_emotion TEXT,
  tags TEXT[] DEFAULT '{}',
  -- Metadata
  word_count INTEGER DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_journal_user_date ON journal_entries(user_id, created_at DESC);

-- ============================================
-- CHAT CONVERSATIONS
-- ============================================
CREATE TABLE chat_conversations (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  title TEXT, -- auto-generated summary
  -- Context
  initial_emotion TEXT,
  summary TEXT, -- AI-generated summary for context
  -- Metadata
  message_count INTEGER DEFAULT 0,
  is_crisis BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_conversations_user ON chat_conversations(user_id, created_at DESC);

-- ============================================
-- CHAT MESSAGES
-- ============================================
CREATE TABLE chat_messages (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  conversation_id UUID NOT NULL REFERENCES chat_conversations(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  role TEXT NOT NULL CHECK (role IN ('user', 'assistant')),
  content TEXT NOT NULL,
  -- Metadata
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_messages_conversation ON chat_messages(conversation_id, created_at);

-- ============================================
-- TOOL USAGE
-- ============================================
CREATE TABLE tool_usage (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  tool_id TEXT NOT NULL, -- breathing_calm, breathing_focus, pause_2min, etc.
  tool_category TEXT NOT NULL, -- breathing, pause, anxiety, entrepreneur
  -- Usage data
  duration_seconds INTEGER,
  completed BOOLEAN DEFAULT FALSE,
  -- Context
  emotion_before TEXT,
  stress_before INTEGER,
  -- Metadata
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_tool_usage_user ON tool_usage(user_id, created_at DESC);

-- ============================================
-- CONTENT / ARTICLES
-- ============================================
CREATE TABLE articles (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  title TEXT NOT NULL,
  subtitle TEXT,
  content TEXT NOT NULL,
  -- Categorization
  category TEXT NOT NULL, -- financial_pressure, fear_failure, burnout, loneliness, guilt_rest, responsibility, comparison, slow_results, stress_decisions, team_management, imposter, identity
  tags TEXT[] DEFAULT '{}',
  -- Media
  cover_image_url TEXT,
  reading_time_minutes INTEGER DEFAULT 3,
  -- Reflection
  reflection_question TEXT,
  -- Publishing
  is_published BOOLEAN DEFAULT FALSE,
  is_premium BOOLEAN DEFAULT FALSE,
  sort_order INTEGER DEFAULT 0,
  -- Metadata
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================
-- DAILY PHRASES
-- ============================================
CREATE TABLE daily_phrases (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  phrase TEXT NOT NULL,
  author TEXT,
  category TEXT DEFAULT 'general', -- general, resilience, calm, motivation, self_care
  is_active BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================
-- ROUTINES
-- ============================================
CREATE TABLE routines (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  title TEXT NOT NULL,
  description TEXT,
  type TEXT NOT NULL, -- morning, evening, pre_meeting, post_conflict, night_discharge
  duration_minutes INTEGER DEFAULT 3,
  -- Steps
  steps JSONB NOT NULL DEFAULT '[]', -- [{type: "breathing|reflection|gratitude|writing|body_scan", title, description, duration_seconds}]
  -- Publishing
  is_published BOOLEAN DEFAULT TRUE,
  is_premium BOOLEAN DEFAULT FALSE,
  sort_order INTEGER DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================
-- ROUTINE COMPLETIONS
-- ============================================
CREATE TABLE routine_completions (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  routine_id UUID NOT NULL REFERENCES routines(id) ON DELETE CASCADE,
  completed_steps INTEGER DEFAULT 0,
  total_steps INTEGER DEFAULT 0,
  completed BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_routine_completions_user ON routine_completions(user_id, created_at DESC);

-- ============================================
-- FAVORITE TOOLS
-- ============================================
CREATE TABLE favorite_tools (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  tool_id TEXT NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(user_id, tool_id)
);

-- ============================================
-- RLS POLICIES
-- ============================================

ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE checkins ENABLE ROW LEVEL SECURITY;
ALTER TABLE journal_entries ENABLE ROW LEVEL SECURITY;
ALTER TABLE chat_conversations ENABLE ROW LEVEL SECURITY;
ALTER TABLE chat_messages ENABLE ROW LEVEL SECURITY;
ALTER TABLE tool_usage ENABLE ROW LEVEL SECURITY;
ALTER TABLE routine_completions ENABLE ROW LEVEL SECURITY;
ALTER TABLE favorite_tools ENABLE ROW LEVEL SECURITY;
ALTER TABLE articles ENABLE ROW LEVEL SECURITY;
ALTER TABLE daily_phrases ENABLE ROW LEVEL SECURITY;
ALTER TABLE routines ENABLE ROW LEVEL SECURITY;

-- Profiles: users can read/update their own
CREATE POLICY "Users can view own profile" ON profiles FOR SELECT USING (auth.uid() = id);
CREATE POLICY "Users can update own profile" ON profiles FOR UPDATE USING (auth.uid() = id);
CREATE POLICY "Users can insert own profile" ON profiles FOR INSERT WITH CHECK (auth.uid() = id);

-- Checkins: users can CRUD their own
CREATE POLICY "Users can manage own checkins" ON checkins FOR ALL USING (auth.uid() = user_id);

-- Journal: users can CRUD their own
CREATE POLICY "Users can manage own journal" ON journal_entries FOR ALL USING (auth.uid() = user_id);

-- Conversations: users can CRUD their own
CREATE POLICY "Users can manage own conversations" ON chat_conversations FOR ALL USING (auth.uid() = user_id);

-- Messages: users can CRUD their own
CREATE POLICY "Users can manage own messages" ON chat_messages FOR ALL USING (auth.uid() = user_id);

-- Tool usage: users can CRUD their own
CREATE POLICY "Users can manage own tool usage" ON tool_usage FOR ALL USING (auth.uid() = user_id);

-- Routine completions: users can CRUD their own
CREATE POLICY "Users can manage own routine completions" ON routine_completions FOR ALL USING (auth.uid() = user_id);

-- Favorites: users can CRUD their own
CREATE POLICY "Users can manage own favorites" ON favorite_tools FOR ALL USING (auth.uid() = user_id);

-- Articles: everyone can read published
CREATE POLICY "Anyone can read published articles" ON articles FOR SELECT USING (is_published = TRUE);

-- Daily phrases: everyone can read active
CREATE POLICY "Anyone can read active phrases" ON daily_phrases FOR SELECT USING (is_active = TRUE);

-- Routines: everyone can read published
CREATE POLICY "Anyone can read published routines" ON routines FOR SELECT USING (is_published = TRUE);

-- ============================================
-- FUNCTIONS
-- ============================================

-- Auto-create profile on signup
CREATE OR REPLACE FUNCTION handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO profiles (id, full_name)
  VALUES (NEW.id, NEW.raw_user_meta_data->>'full_name');
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION handle_new_user();

-- Update checkin streak
CREATE OR REPLACE FUNCTION update_checkin_streak()
RETURNS TRIGGER AS $$
DECLARE
  last_checkin_date DATE;
  current_streak INTEGER;
BEGIN
  SELECT DATE(created_at) INTO last_checkin_date
  FROM checkins
  WHERE user_id = NEW.user_id AND id != NEW.id
  ORDER BY created_at DESC
  LIMIT 1;

  SELECT checkin_streak INTO current_streak FROM profiles WHERE id = NEW.user_id;

  IF last_checkin_date = CURRENT_DATE - INTERVAL '1 day' THEN
    current_streak := current_streak + 1;
  ELSIF last_checkin_date < CURRENT_DATE - INTERVAL '1 day' OR last_checkin_date IS NULL THEN
    current_streak := 1;
  END IF;

  UPDATE profiles SET
    checkin_streak = current_streak,
    longest_streak = GREATEST(longest_streak, current_streak),
    total_checkins = total_checkins + 1,
    last_active_at = NOW(),
    updated_at = NOW()
  WHERE id = NEW.user_id;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER on_checkin_created
  AFTER INSERT ON checkins
  FOR EACH ROW EXECUTE FUNCTION update_checkin_streak();

-- Update journal count
CREATE OR REPLACE FUNCTION update_journal_count()
RETURNS TRIGGER AS $$
BEGIN
  UPDATE profiles SET
    total_journal_entries = total_journal_entries + 1,
    last_active_at = NOW(),
    updated_at = NOW()
  WHERE id = NEW.user_id;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER on_journal_created
  AFTER INSERT ON journal_entries
  FOR EACH ROW EXECUTE FUNCTION update_journal_count();

-- ============================================
-- SEED DATA: Daily Phrases
-- ============================================
INSERT INTO daily_phrases (phrase, author, category) VALUES
  ('No necesitas tener todas las respuestas. Solo la siguiente.', NULL, 'resilience'),
  ('Emprender es un acto de valentia. Descansar tambien.', NULL, 'self_care'),
  ('No se trata de no sentir presion. Se trata de no cargarla solo.', NULL, 'general'),
  ('Cada dia que seguis adelante, estas construyendo algo.', NULL, 'motivation'),
  ('Tu negocio necesita que estes bien. Cuidarte es estrategia.', NULL, 'self_care'),
  ('No todo tiene que resolverse hoy.', NULL, 'calm'),
  ('La claridad no viene de pensar mas. Viene de hacer una pausa.', NULL, 'calm'),
  ('Sos mas que tu facturacion.', NULL, 'general'),
  ('Un paso a la vez. Un dia a la vez.', NULL, 'resilience'),
  ('Lo que sentis es valido. Lo que haces con eso, es tu poder.', NULL, 'resilience'),
  ('No tenes que demostrarle nada a nadie. Solo a vos mismo.', NULL, 'general'),
  ('Descansar no es rendirse. Es recargarse.', NULL, 'self_care'),
  ('La presion es real. Pero vos sos mas grande que ella.', NULL, 'motivation'),
  ('Hoy no necesitas ser perfecto. Solo necesitas ser honesto.', NULL, 'general'),
  ('Cada emprendedor que admiras tambien tuvo dias dificiles.', NULL, 'resilience');

-- ============================================
-- SEED DATA: Sample Articles
-- ============================================
INSERT INTO articles (title, subtitle, content, category, reading_time_minutes, reflection_question, is_published) VALUES
  (
    'La presion financiera no te define',
    'Como separar tu valor personal de tus numeros',
    'Cuando emprendes, es facil confundir tu cuenta bancaria con tu valor como persona. Un mal mes no significa que seas un mal emprendedor. La presion financiera es real, pero no es permanente ni es tu identidad.

Lo que podes hacer:
- Separa el problema financiero del problema emocional. Son dos cosas distintas.
- Escribe los numeros. Verlos en papel los hace mas manejables que tenerlos dando vueltas en la cabeza.
- Recorda que la mayoria de los negocios exitosos pasaron por momentos de escasez.
- Pedi ayuda. Un contador, un mentor, un colega. No tenes que resolverlo solo.',
    'financial_pressure',
    3,
    'Cuando fue la ultima vez que separaste tu valor personal de los numeros de tu negocio?',
    TRUE
  ),
  (
    'El agotamiento no es un premio',
    'Por que trabajar hasta caer no es productividad',
    'En la cultura emprendedora hay un mito peligroso: que el agotamiento es senal de compromiso. No lo es. El burnout destruye creatividad, relaciones y salud.

Senales de que necesitas parar:
- Te cuesta concentrarte en tareas simples
- Todo te irrita mas de lo normal
- Sentis que trabajas mucho pero avanzas poco
- Te desconectas de las cosas que antes disfrutabas
- Tu cuerpo te manda senales: dolor de cabeza, tension, insomnio

Que hacer:
- Reconoce que estas agotado. Sin culpa.
- Toma un descanso real, aunque sea breve.
- Delega algo esta semana.
- Dormi una hora mas hoy.',
    'burnout',
    3,
    'Que te esta costando delegar o soltar esta semana?',
    TRUE
  ),
  (
    'La soledad de emprender',
    'Por que te sentis solo aunque estes rodeado de gente',
    'Emprender puede ser una de las experiencias mas solitarias. No porque estes solo fisicamente, sino porque pocas personas entienden realmente lo que vivis: la incertidumbre, la presion, las decisiones que solo vos podes tomar.

Esto no significa que algo este mal con vos. Significa que necesitas encontrar tu tribu: otros emprendedores que entienden.

Mientras tanto:
- Hablar de lo que sentis no es debilidad. Es inteligencia emocional.
- Un mentor o coach puede ser ese espacio de escucha que necesitas.
- Esta app puede ser un refugio diario. Usala.
- Escribir lo que sentis es una forma de acompanarte a vos mismo.',
    'loneliness',
    3,
    'Con quien compartiste por ultima vez como te sentis de verdad?',
    TRUE
  );

-- ============================================
-- SEED DATA: Routines
-- ============================================
INSERT INTO routines (title, description, type, duration_minutes, steps) VALUES
  (
    'Inicio con intencion',
    'Empieza tu dia con claridad y calma',
    'morning',
    3,
    '[
      {"type": "breathing", "title": "Respira profundo", "description": "3 respiraciones lentas para despertar tu cuerpo", "duration_seconds": 30},
      {"type": "reflection", "title": "Intencion del dia", "description": "Cual es la unica cosa importante de hoy?", "duration_seconds": 60},
      {"type": "gratitude", "title": "Un motivo", "description": "Nombra una cosa por la que estas agradecido hoy", "duration_seconds": 30},
      {"type": "breathing", "title": "Respira y arranca", "description": "Una respiracion profunda final. Estas listo.", "duration_seconds": 20}
    ]'
  ),
  (
    'Cierre del dia',
    'Suelta el dia y prepara tu descanso',
    'evening',
    3,
    '[
      {"type": "reflection", "title": "Como fue tu dia?", "description": "Sin juzgar, solo observa. Como te sentis ahora?", "duration_seconds": 45},
      {"type": "gratitude", "title": "Algo bueno", "description": "Que fue lo mejor del dia, por mas chico que sea?", "duration_seconds": 30},
      {"type": "writing", "title": "Soltar", "description": "Escribe una cosa que queres dejar ir antes de dormir", "duration_seconds": 60},
      {"type": "breathing", "title": "Respira y descansa", "description": "5 respiraciones lentas. El dia termino. Mereces descansar.", "duration_seconds": 45}
    ]'
  ),
  (
    'Antes de la reunion',
    'Centrate antes de una conversacion importante',
    'pre_meeting',
    2,
    '[
      {"type": "breathing", "title": "Box breathing", "description": "Inhala 4s, manten 4s, exhala 4s, manten 4s. Repite 3 veces.", "duration_seconds": 50},
      {"type": "reflection", "title": "Tu intencion", "description": "Que queres lograr en esta reunion? Una sola cosa.", "duration_seconds": 30},
      {"type": "body_scan", "title": "Soltar tension", "description": "Relaja hombros, mandibula, manos. Suelta.", "duration_seconds": 20},
      {"type": "breathing", "title": "Una ultima", "description": "Una respiracion profunda. Estas preparado.", "duration_seconds": 15}
    ]'
  ),
  (
    'Descarga nocturna',
    'Vacia tu mente antes de dormir',
    'night_discharge',
    5,
    '[
      {"type": "breathing", "title": "Baja el ritmo", "description": "Respira lento. Inhala 4s, exhala 6s. Repite 5 veces.", "duration_seconds": 60},
      {"type": "writing", "title": "Vacia tu cabeza", "description": "Escribe todo lo que te esta dando vueltas. Sin filtro.", "duration_seconds": 120},
      {"type": "reflection", "title": "Que puede esperar?", "description": "De todo lo que escribiste, que puede esperar hasta manana?", "duration_seconds": 30},
      {"type": "body_scan", "title": "Escaneo corporal", "description": "Desde la cabeza hasta los pies, relaja cada parte de tu cuerpo.", "duration_seconds": 60},
      {"type": "breathing", "title": "Respiracion de sueno", "description": "Inhala 4s, manten 7s, exhala 8s. 3 veces. Buenas noches.", "duration_seconds": 60}
    ]'
  );
