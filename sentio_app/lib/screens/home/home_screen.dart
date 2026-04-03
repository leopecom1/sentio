import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:sentio_app/config/theme.dart';
import 'package:sentio_app/config/constants.dart';
import 'package:sentio_app/providers/app_provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  late AnimationController _gradientController;

  @override
  void initState() {
    super.initState();
    _gradientController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _gradientController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();

    return Scaffold(
      backgroundColor: SentioColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Hero section: gradient extends behind greeting + check-in
              _buildHeroSection(context, provider),
              const SizedBox(height: 20),
              // Contextual suggestion
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: _buildSuggestion(context, provider),
              ),
              const SizedBox(height: 24),
              // Quick actions
              Padding(
                padding: const EdgeInsets.only(left: 20),
                child: _buildQuickActions(context),
              ),
              const SizedBox(height: 24),
              // Insight of the day
              if (provider.checkins.isNotEmpty) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: _buildInsightCard(context, provider),
                ),
                const SizedBox(height: 20),
              ],
              // Daily phrase
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: _buildDailyPhrase(context, provider),
              ),
              const SizedBox(height: 20),
              // Weekly mood overview
              if (provider.thisWeekCheckins.isNotEmpty) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: _buildWeeklyMood(context, provider),
                ),
                const SizedBox(height: 20),
              ],
              const SizedBox(height: 80),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeroSection(BuildContext context, AppProvider provider) {
    return AnimatedBuilder(
      animation: _gradientController,
      builder: (context, child) {
        final t = _gradientController.value;
        return Stack(
          children: [
            // Animated gradient background - extends behind greeting + check-in
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment(-1.0 + t * 2, -1.0),
                    end: Alignment(1.0 - t * 0.5, 1.0),
                    colors: [
                      SentioColors.primary.withValues(alpha: 0.14 + t * 0.08),
                      SentioColors.accent.withValues(alpha: 0.10 + t * 0.06),
                      SentioColors.primary.withValues(alpha: 0.04),
                      SentioColors.background,
                    ],
                    stops: [0.0, 0.3 + t * 0.1, 0.7, 1.0],
                  ),
                ),
              ),
            ),
            // Floating glow orbs
            Positioned(
              right: -20 + t * 50,
              top: 10 + t * 30,
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      SentioColors.accent.withValues(alpha: 0.12),
                      SentioColors.accent.withValues(alpha: 0.0),
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              left: -30 + t * 20,
              bottom: 20 + t * 15,
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      SentioColors.primary.withValues(alpha: 0.08),
                      SentioColors.primary.withValues(alpha: 0.0),
                    ],
                  ),
                ),
              ),
            ),
            // Content
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    SentioConstants.getGreeting(provider.userName),
                    style: GoogleFonts.manrope(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: SentioColors.textPrimary,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    SentioConstants.getGreetingSubtitle(),
                    style: GoogleFonts.manrope(
                      fontSize: 15,
                      fontWeight: FontWeight.w400,
                      color: SentioColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Check-in card overlapping the gradient
                  _buildCheckinCard(context, provider),
                  const SizedBox(height: 4),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildCheckinCard(BuildContext context, AppProvider provider) {
    final hasCheckedIn = provider.hasCheckedInToday;
    final todayCheckin = provider.todayCheckin;

    if (hasCheckedIn && todayCheckin != null) {
      final emotion = SentioConstants.emotions.firstWhere(
        (e) => e['id'] == todayCheckin.primaryEmotion,
        orElse: () => SentioConstants.emotions.first,
      );
      final emotionColor = Color(emotion['color'] as int);

      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: SentioColors.surface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: SentioColors.border),
          boxShadow: SentioEffects.glow(emotionColor, blur: 12, opacity: 0.15),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: emoji + label + edit button
            Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: emotionColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: emotionColor.withValues(alpha: 0.25),
                    ),
                  ),
                  child: Center(
                    child: Text(
                      emotion['emoji'],
                      style: const TextStyle(fontSize: 28),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Hoy te sentís ${(emotion['label'] as String).toLowerCase()}',
                        style: GoogleFonts.manrope(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: SentioColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Check-in de hoy',
                        style: GoogleFonts.manrope(
                          fontSize: 12,
                          color: SentioColors.textTertiary,
                        ),
                      ),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: () => context.push('/checkin'),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: emotionColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: emotionColor.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Text(
                      'Editar',
                      style: GoogleFonts.manrope(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: emotionColor,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            // Visual bars for energy and stress
            _buildMetricBar(
              label: 'Energía',
              value: todayCheckin.energyLevel,
              maxValue: 5,
              color: SentioColors.accent,
              icon: Icons.bolt_rounded,
            ),
            const SizedBox(height: 10),
            _buildMetricBar(
              label: 'Estrés',
              value: todayCheckin.stressLevel,
              maxValue: 5,
              color: SentioColors.warning,
              icon: Icons.whatshot_rounded,
            ),
            if (todayCheckin.motivationLevel != null) ...[
              const SizedBox(height: 10),
              _buildMetricBar(
                label: 'Motivación',
                value: todayCheckin.motivationLevel!,
                maxValue: 5,
                color: SentioColors.primary,
                icon: Icons.rocket_launch_rounded,
              ),
            ],
            // Note preview
            if (todayCheckin.note != null && todayCheckin.note!.isNotEmpty) ...[
              const SizedBox(height: 14),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.04),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(Icons.format_quote_rounded, size: 16, color: SentioColors.textTertiary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        todayCheckin.note!,
                        style: GoogleFonts.manrope(
                          fontSize: 13,
                          fontWeight: FontWeight.w400,
                          color: SentioColors.textSecondary,
                          fontStyle: FontStyle.italic,
                          height: 1.5,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      );
    }

    // Not checked in yet
    return GestureDetector(
      onTap: () => context.push('/checkin'),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: SentioEffects.gradientCard(glowColor: SentioColors.primary),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '¿Cómo estás hoy, de verdad?',
                    style: GoogleFonts.manrope(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: SentioColors.textPrimary,
                      letterSpacing: -0.3,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Registrar cómo te sentís ya es un paso importante.',
                    style: GoogleFonts.manrope(
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      color: SentioColors.textSecondary,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    SentioColors.primary,
                    SentioColors.primary.withValues(alpha: 0.7),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: SentioEffects.glow(SentioColors.primary, blur: 12, opacity: 0.4),
              ),
              child: const Icon(
                Icons.add_rounded,
                color: Colors.white,
                size: 28,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricBar({
    required String label,
    required int value,
    required int maxValue,
    required Color color,
    required IconData icon,
  }) {
    final fraction = value / maxValue;
    return Row(
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 8),
        SizedBox(
          width: 70,
          child: Text(
            label,
            style: GoogleFonts.manrope(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: SentioColors.textSecondary,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Container(
            height: 8,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(4),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: fraction,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      color,
                      color.withValues(alpha: 0.6),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(4),
                  boxShadow: [
                    BoxShadow(
                      color: color.withValues(alpha: 0.3),
                      blurRadius: 6,
                      spreadRadius: -2,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          '$value/$maxValue',
          style: GoogleFonts.manrope(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildSuggestion(BuildContext context, AppProvider provider) {
    String title;
    String subtitle;
    IconData icon;
    VoidCallback onTap;

    if (provider.averageStress > 3.5) {
      title = 'Tus ultimos dias fueron intensos';
      subtitle = '¿Que tal una pausa de 2 minutos?';
      icon = Icons.self_improvement_rounded;
      onTap = () => context.push('/tool/pause_2min');
    } else if (provider.journalEntries.isEmpty) {
      title = 'Tu diario te espera';
      subtitle = 'Escribir puede ayudarte a ver mas claro.';
      icon = Icons.edit_note_rounded;
      onTap = () => context.push('/journal/new');
    } else {
      title = 'Habla con tu asistente';
      subtitle = 'A veces poner en palabras lo que sentis ayuda.';
      icon = Icons.chat_bubble_outline_rounded;
      onTap = () => context.go('/chat');
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: SentioEffects.standardCard(),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: SentioColors.accent.withOpacity(0.1),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: SentioColors.accent.withOpacity(0.2),
                ),
              ),
              child: Icon(icon, color: SentioColors.accent, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.manrope(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: SentioColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: GoogleFonts.manrope(
                      fontSize: 13,
                      fontWeight: FontWeight.w400,
                      color: SentioColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.arrow_forward_ios_rounded,
                size: 14,
                color: SentioColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    final actions = [
      _QuickActionData(
        icon: Icons.edit_note_rounded,
        label: 'Escribir',
        color: SentioColors.accent,
        onTap: () => context.push('/journal/new'),
      ),
      _QuickActionData(
        icon: Icons.chat_bubble_outline_rounded,
        label: 'Hablar',
        color: SentioColors.primary,
        onTap: () => context.go('/chat'),
      ),
      _QuickActionData(
        icon: Icons.spa_outlined,
        label: 'Respirar',
        color: const Color(0xFF7B9E87),
        onTap: () => context.push('/tool/breathing_calm'),
      ),
      _QuickActionData(
        icon: Icons.account_balance_wallet_outlined,
        label: 'Finanzas',
        color: const Color(0xFF4CAF50),
        onTap: () => context.push('/finance'),
      ),
      _QuickActionData(
        icon: Icons.grid_view_rounded,
        label: 'Herramientas',
        color: SentioColors.warning,
        onTap: () => context.push('/tools'),
      ),
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: actions.map((action) {
          final isLast = action == actions.last;
          return Padding(
            padding: EdgeInsets.only(right: isLast ? 0 : 16),
            child: GestureDetector(
              onTap: action.onTap,
              child: Column(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: action.color.withOpacity(0.1),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: action.color.withOpacity(0.2),
                      ),
                    ),
                    child: Icon(
                      action.icon,
                      color: action.color,
                      size: 26,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    action.label,
                    style: GoogleFonts.manrope(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: SentioColors.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildInsightCard(BuildContext context, AppProvider provider) {
    final avgStress = provider.averageStress;
    String insight;
    IconData insightIcon;
    Color insightColor;

    if (avgStress > 3.5) {
      insight = 'Tu estres promedio esta semana es alto. Considera hacer mas pausas.';
      insightIcon = Icons.warning_amber_rounded;
      insightColor = SentioColors.warning;
    } else if (avgStress < 2.5) {
      insight = 'Tu nivel de estres esta mas bajo que antes. Algo estas haciendo bien.';
      insightIcon = Icons.trending_down_rounded;
      insightColor = SentioColors.accent;
    } else {
      insight = 'Tu semana tiene altibajos normales. Lo importante es que estas prestando atencion.';
      insightIcon = Icons.insights_rounded;
      insightColor = SentioColors.primary;
    }

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: SentioEffects.gradientCard(),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: insightColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              insightIcon,
              color: insightColor,
              size: 20,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Insight del dia',
                  style: GoogleFonts.manrope(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: insightColor,
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  insight,
                  style: GoogleFonts.manrope(
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    color: SentioColors.textPrimary,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDailyPhrase(BuildContext context, AppProvider provider) {
    final phrase = provider.dailyPhrase.isEmpty
        ? 'No necesitas tener todas las respuestas. Solo la siguiente.'
        : provider.dailyPhrase;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
      decoration: SentioEffects.standardCard(),
      child: Column(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: SentioColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.format_quote_rounded,
              color: SentioColors.primary.withOpacity(0.7),
              size: 22,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            phrase,
            style: GoogleFonts.manrope(
              fontSize: 17,
              fontWeight: FontWeight.w600,
              height: 1.5,
              color: SentioColors.textPrimary,
              letterSpacing: -0.2,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Container(
            width: 32,
            height: 3,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  SentioColors.primary.withOpacity(0.5),
                  SentioColors.accent.withOpacity(0.5),
                ],
              ),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeeklyMood(BuildContext context, AppProvider provider) {
    final weekCheckins = provider.thisWeekCheckins;
    final weeklyData = provider.weeklyEvolutionEmotional;
    final dayNames = ['L', 'M', 'X', 'J', 'V', 'S', 'D'];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: SentioEffects.standardCard(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Tu semana',
                style: GoogleFonts.manrope(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: SentioColors.textPrimary,
                ),
              ),
              GestureDetector(
                onTap: () => context.push('/progress'),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: SentioColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Ver mas',
                    style: GoogleFonts.manrope(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: SentioColors.primary,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 140,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(7, (index) {
                final value = weeklyData[index];
                final hasData = value > 0;
                final barHeight = hasData ? (value * 100).clamp(12.0, 100.0) : 8.0;

                // Get emotion for this day for color
                final now = DateTime.now();
                final dayDate = now.subtract(Duration(days: 6 - index));
                final dayCheckin = weekCheckins.where((c) =>
                  c.createdAt.year == dayDate.year &&
                  c.createdAt.month == dayDate.month &&
                  c.createdAt.day == dayDate.day
                ).firstOrNull;

                Color barColor;
                if (dayCheckin != null) {
                  final emotion = SentioConstants.emotions.firstWhere(
                    (e) => e['id'] == dayCheckin.primaryEmotion,
                    orElse: () => SentioConstants.emotions.first,
                  );
                  barColor = Color(emotion['color'] as int);
                } else {
                  barColor = SentioColors.textTertiary;
                }

                final isToday = dayDate.year == now.year &&
                    dayDate.month == now.month &&
                    dayDate.day == now.day;

                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        // Bar
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 400),
                          curve: Curves.easeOutCubic,
                          height: barHeight,
                          decoration: BoxDecoration(
                            gradient: hasData
                                ? LinearGradient(
                                    colors: [
                                      barColor.withOpacity(0.9),
                                      barColor.withOpacity(0.5),
                                    ],
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                  )
                                : null,
                            color: hasData ? null : Colors.white.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: hasData
                                ? [
                                    BoxShadow(
                                      color: barColor.withOpacity(0.25),
                                      blurRadius: 8,
                                      spreadRadius: -2,
                                      offset: const Offset(0, 2),
                                    ),
                                  ]
                                : null,
                          ),
                        ),
                        const SizedBox(height: 10),
                        // Day label
                        Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            color: isToday
                                ? SentioColors.primary.withOpacity(0.15)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Center(
                            child: Text(
                              dayNames[index],
                              style: GoogleFonts.manrope(
                                fontSize: 12,
                                fontWeight: isToday ? FontWeight.w700 : FontWeight.w500,
                                color: isToday
                                    ? SentioColors.primary
                                    : SentioColors.textTertiary,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickActionData {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionData({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });
}
