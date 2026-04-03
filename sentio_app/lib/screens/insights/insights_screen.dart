import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:sentio_app/config/theme.dart';
import 'package:sentio_app/config/constants.dart';
import 'package:sentio_app/providers/app_provider.dart';

class InsightsScreen extends StatelessWidget {
  const InsightsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();

    return Scaffold(
      backgroundColor: SentioColors.background,
      appBar: AppBar(
        title: Text(
          'Tus patrones',
          style: GoogleFonts.manrope(fontSize: 24),
        ),
      ),
      body: provider.checkins.isEmpty
          ? _buildEmptyState(context)
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildWeekSummary(context, provider),
                  const SizedBox(height: 24),
                  _buildEmotionDistribution(context, provider),
                  const SizedBox(height: 24),
                  _buildStressTrend(context, provider),
                  const SizedBox(height: 24),
                  _buildInsightCards(context, provider),
                  const SizedBox(height: 40),
                ],
              ),
            ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(48),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: SentioColors.primary.withValues(alpha: 0.1),
              ),
              child: const Icon(
                Icons.insights_rounded,
                size: 36,
                color: SentioColors.primary,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Todavía estamos\nconociéndonos.',
              style: GoogleFonts.manrope(
                fontSize: 22,
                height: 1.4,
                color: SentioColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Después de algunos check-ins, vamos a empezar a mostrarte patrones que te van a servir.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: SentioColors.textSecondary,
                    height: 1.5,
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeekSummary(BuildContext context, AppProvider provider) {
    final weekCheckins = provider.thisWeekCheckins;
    final avgStress = weekCheckins.isEmpty
        ? 0.0
        : weekCheckins.map((c) => c.stressLevel).reduce((a, b) => a + b) /
            weekCheckins.length;
    final avgEnergy = weekCheckins.isEmpty
        ? 0.0
        : weekCheckins.map((c) => c.energyLevel).reduce((a, b) => a + b) /
            weekCheckins.length;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: SentioColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Resumen semanal',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _MetricCard(
                  label: 'Estrés promedio',
                  value: avgStress.toStringAsFixed(1),
                  maxValue: '/5',
                  color: avgStress > 3.5 ? SentioColors.error : SentioColors.accent,
                  icon: Icons.trending_down_rounded,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _MetricCard(
                  label: 'Energía promedio',
                  value: avgEnergy.toStringAsFixed(1),
                  maxValue: '/5',
                  color: avgEnergy < 2.5 ? SentioColors.warning : SentioColors.primary,
                  icon: Icons.bolt_rounded,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _MetricCard(
                  label: 'Check-ins',
                  value: weekCheckins.length.toString(),
                  maxValue: '/7',
                  color: SentioColors.secondary,
                  icon: Icons.check_circle_outline_rounded,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _MetricCard(
                  label: 'Racha',
                  value: '${provider.profile?.checkinStreak ?? 0}',
                  maxValue: ' días',
                  color: SentioColors.accent,
                  icon: Icons.local_fire_department_rounded,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmotionDistribution(BuildContext context, AppProvider provider) {
    final counts = provider.emotionCounts;
    if (counts.isEmpty) return const SizedBox.shrink();

    final sorted = counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final total = sorted.fold<int>(0, (sum, e) => sum + e.value);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: SentioColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Emociones más frecuentes',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 16),
          ...sorted.take(5).map((entry) {
            final emotion = SentioConstants.emotions.firstWhere(
              (e) => e['id'] == entry.key,
              orElse: () => SentioConstants.emotions.first,
            );
            final percentage = (entry.value / total * 100).round();

            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  Text(emotion['emoji'], style: const TextStyle(fontSize: 20)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              emotion['label'],
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Text(
                              '$percentage%',
                              style: TextStyle(
                                fontSize: 13,
                                color: SentioColors.textTertiary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: entry.value / total,
                            backgroundColor: SentioColors.card,
                            valueColor: AlwaysStoppedAnimation(
                              Color(emotion['color'] as int),
                            ),
                            minHeight: 6,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildStressTrend(BuildContext context, AppProvider provider) {
    final recentCheckins = provider.checkins.take(7).toList().reversed.toList();
    if (recentCheckins.length < 3) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: SentioColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Tendencia de estrés',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 120,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: recentCheckins.map((checkin) {
                final height = (checkin.stressLevel / 5) * 100;
                final color = checkin.stressLevel >= 4
                    ? SentioColors.error
                    : checkin.stressLevel >= 3
                        ? SentioColors.warning
                        : SentioColors.accent;
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 3),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          '${checkin.stressLevel}',
                          style: TextStyle(
                            fontSize: 11,
                            color: SentioColors.textTertiary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 500),
                          height: height,
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.7),
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInsightCards(BuildContext context, AppProvider provider) {
    final insights = <Map<String, String>>[];

    if (provider.averageStress > 3.5) {
      insights.add({
        'text': 'Tu estrés promedio está alto. Considerá incorporar pausas más frecuentes en tu rutina.',
        'icon': '⚡',
      });
    }
    if (provider.averageEnergy < 2.5) {
      insights.add({
        'text': 'Tu energía viene baja. ¿Estás durmiendo lo suficiente? Tu cuerpo te pide descanso.',
        'icon': '🔋',
      });
    }
    if (provider.journalEntries.isNotEmpty) {
      insights.add({
        'text': 'Cuando escribís en el diario, tu claridad mental del día siguiente suele mejorar.',
        'icon': '✏️',
      });
    }
    if (insights.isEmpty) {
      insights.add({
        'text': 'Seguí registrando cómo te sentís. Con más datos, voy a poder darte insights más precisos.',
        'icon': '📊',
      });
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Descubrimientos',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: 12),
        ...insights.map((insight) => Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: SentioColors.primary.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(insight['icon']!, style: const TextStyle(fontSize: 20)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      insight['text']!,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            height: 1.5,
                          ),
                    ),
                  ),
                ],
              ),
            )),
      ],
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String label;
  final String value;
  final String maxValue;
  final Color color;
  final IconData icon;

  const _MetricCard({
    required this.label,
    required this.value,
    required this.maxValue,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 8),
          RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: value,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
                TextSpan(
                  text: maxValue,
                  style: TextStyle(
                    fontSize: 14,
                    color: SentioColors.textTertiary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: SentioColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
