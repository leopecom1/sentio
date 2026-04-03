# CLAUDE.md — Sentio

## Project Overview

**Sentio** — App de bienestar emocional premium para emprendedores.
Espacio privado, inteligente y emocionalmente seguro para registrar emociones, entender patrones, recibir acompañamiento IA y acceder a herramientas de regulación.

## Monorepo Structure

```
sentio/
├── sentio_app/      # Flutter mobile app (iOS + Android)
├── sentio_admin/    # React web admin dashboard
├── supabase/        # Database schema and migrations
└── PRD.md           # Product requirements document
```

## Flutter App (sentio_app/)

```bash
cd sentio_app
flutter pub get
flutter run              # Run on connected device/emulator
flutter analyze          # Check for errors
```

**Stack:** Flutter 3.41 / Dart 3.11 / Provider / GoRouter / Supabase / Google Fonts
**Package ID:** `com.sentio.sentio_app`

### Architecture
- `lib/config/` — Theme, router, constants
- `lib/models/` — Data models (Profile, Checkin, JournalEntry, ChatMessage)
- `lib/providers/` — State management (AppProvider)
- `lib/screens/` — All screens organized by feature
- `lib/widgets/` — Shared widgets (MainShell)

### Key Screens
- Onboarding (5 steps)
- Home (dashboard with check-in, suggestions, insights)
- Check-in (quick + deep emotional registration)
- Journal (writing with prompts)
- Chat (AI assistant conversation)
- Tools (breathing, pauses, entrepreneur-specific)
- Insights (patterns and trends)
- Profile (stats, settings)
- Crisis (immediate support)
- Routines (guided micro-routines)
- Progress (emotional progress tracking)

### Color Palette
- Primary: #3D5A80 (calm blue)
- Secondary: #C9A96E (warm gold)
- Accent: #7B9E87 (sage green)
- Background: #FAFAF8 (warm white)
- Text: #1A1A2E (deep navy)

### Typography
- Display: DM Serif Display
- Body: DM Sans

## Admin Dashboard (sentio_admin/)

```bash
cd sentio_admin
npm install
npm run dev              # http://localhost:5174
npm run build
npx tsc --noEmit         # Type check
```

**Stack:** React 18 / Vite / TypeScript / Tailwind CSS v4 / Recharts / React Router

### Pages
- Dashboard — Overview stats, charts, alerts
- Users — User list with search/filter
- Analytics — DAU, retention, feature usage, stress distribution
- Content — Articles and daily phrases management
- Conversations — AI chat monitoring with crisis alerts
- Settings — Platform configuration

## Database (supabase/)

Schema file: `supabase/schema.sql`

### Tables
- profiles, checkins, journal_entries
- chat_conversations, chat_messages
- tool_usage, routine_completions, favorite_tools
- articles, daily_phrases, routines

All tables have RLS enabled. Triggers auto-create profiles and update streaks.

## Supabase Setup
1. Create a new Supabase project
2. Run `supabase/schema.sql` in the SQL editor
3. Update credentials in:
   - `sentio_app/lib/config/constants.dart`
   - `sentio_admin/.env` (VITE_SUPABASE_URL, VITE_SUPABASE_ANON_KEY)
