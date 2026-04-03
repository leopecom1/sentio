import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:sentio_app/config/theme.dart';
import 'package:sentio_app/config/constants.dart';
import 'package:sentio_app/providers/app_provider.dart';


class ProgressScreen extends StatelessWidget {
  const ProgressScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final profile = provider.profile;

    return Scaffold(
      backgroundColor: SentioColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => context.pop(),
                      child: const Icon(Icons.arrow_back_rounded),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
                child: Text(
                  'Tu progreso',
                  style: GoogleFonts.manrope(
                    fontSize: 28,
                    color: SentioColors.textPrimary,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  'No se trata de estar bien siempre.\nSe trata de conocerte mejor.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: SentioColors.textSecondary,
                        height: 1.5,
                      ),
                ),
              ),
              const SizedBox(height: 24),
              // Streak card
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        SentioColors.primary,
                        SentioColors.primary.withValues(alpha: 0.85),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      const Icon(
                        Icons.local_fire_department_rounded,
                        color: Colors.white,
                        size: 36,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${profile?.checkinStreak ?? 0}',
                        style: GoogleFonts.manrope(
                          fontSize: 48,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        'días de racha',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.white.withValues(alpha: 0.8),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Cada día que registrás cómo te sentís\nes un acto de cuidado.',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white.withValues(alpha: 0.6),
                          height: 1.4,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              // Stats grid
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  children: [
                    Expanded(
                      child: _ProgressStat(
                        icon: Icons.check_circle_outline_rounded,
                        value: '${profile?.totalCheckins ?? 0}',
                        label: 'Check-ins totales',
                        color: SentioColors.primary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _ProgressStat(
                        icon: Icons.edit_note_rounded,
                        value: '${profile?.totalJournalEntries ?? 0}',
                        label: 'Entradas de diario',
                        color: SentioColors.secondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  children: [
                    Expanded(
                      child: _ProgressStat(
                        icon: Icons.emoji_events_outlined,
                        value: '${profile?.longestStreak ?? 0}',
                        label: 'Mejor racha',
                        color: SentioColors.accent,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _ProgressStat(
                        icon: Icons.spa_outlined,
                        value: '${profile?.totalToolsUsed ?? 0}',
                        label: 'Herramientas usadas',
                        color: SentioColors.warning,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              // Week mood timeline
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  'Tu semana emocional',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 80,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  itemCount: 7,
                  separatorBuilder: (_, __) => const SizedBox(width: 10),
                  itemBuilder: (context, index) {
                    final weekCheckins = provider.thisWeekCheckins;
                    final checkin = weekCheckins
                        .where((c) => c.createdAt.weekday == index + 1)
                        .firstOrNull;
                    final dayNames = ['Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb', 'Dom'];
                    final emotion = checkin != null
                        ? SentioConstants.emotions.firstWhere(
                            (e) => e['id'] == checkin.primaryEmotion,
                            orElse: () => SentioConstants.emotions.first,
                          )
                        : null;
                    final isToday = DateTime.now().weekday == index + 1;

                    return Container(
                      width: 56,
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: isToday
                            ? SentioColors.primary.withValues(alpha: 0.08)
                            : SentioColors.surface,
                        borderRadius: BorderRadius.circular(14),
                        border: isToday
                            ? Border.all(color: SentioColors.primary.withValues(alpha: 0.3))
                            : null,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            dayNames[index],
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: isToday ? FontWeight.w600 : FontWeight.w400,
                              color: isToday
                                  ? SentioColors.primary
                                  : SentioColors.textTertiary,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            emotion != null ? emotion['emoji'] : '·',
                            style: TextStyle(
                              fontSize: emotion != null ? 24 : 18,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 24),
              // Message
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: SentioColors.card,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      const Icon(
                        Icons.format_quote_rounded,
                        color: SentioColors.secondary,
                        size: 24,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Tu progreso no se mide en estar perfecto.\nSe mide en estar presente.',
                        style: GoogleFonts.manrope(
                          fontSize: 16,
                          height: 1.4,
                          color: SentioColors.textPrimary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProgressStat extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;

  const _ProgressStat({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: SentioColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 10),
          Text(
            value,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: SentioColors.textPrimary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: SentioColors.textTertiary,
            ),
          ),
        ],
      ),
    );
  }
}
