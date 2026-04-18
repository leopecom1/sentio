import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  late AnimationController _bgController;
  late AnimationController _entryController;
  late AnimationController _breathController;
  late AnimationController _shimmerController;

  late ScrollController _scrollController;
  double _scrollOffset = 0;

  // Staggered entry animations
  late Animation<double> _greetingFade;
  late Animation<Offset> _greetingSlide;
  late Animation<double> _checkinFade;
  late Animation<Offset> _checkinSlide;
  late Animation<double> _suggestionFade;
  late Animation<Offset> _suggestionSlide;
  late Animation<double> _actionsFade;
  late Animation<double> _restFade;

  // Particle dots
  late List<_Particle> _particles;

  @override
  void initState() {
    super.initState();

    _scrollController = ScrollController()
      ..addListener(() {
        setState(() => _scrollOffset = _scrollController.offset);
      });

    // Background gradient animation
    _bgController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat(reverse: true);

    // Breathing glow effect
    _breathController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);

    // Shimmer effect
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();

    // Staggered entry controller
    _entryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );

    _greetingFade = Tween(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _entryController, curve: const Interval(0.0, 0.35, curve: Curves.easeOut)),
    );
    _greetingSlide = Tween(begin: const Offset(0, 0.15), end: Offset.zero).animate(
      CurvedAnimation(parent: _entryController, curve: const Interval(0.0, 0.35, curve: Curves.easeOutCubic)),
    );
    _checkinFade = Tween(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _entryController, curve: const Interval(0.1, 0.45, curve: Curves.easeOut)),
    );
    _checkinSlide = Tween(begin: const Offset(0, 0.12), end: Offset.zero).animate(
      CurvedAnimation(parent: _entryController, curve: const Interval(0.1, 0.45, curve: Curves.easeOutCubic)),
    );
    _suggestionFade = Tween(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _entryController, curve: const Interval(0.2, 0.55, curve: Curves.easeOut)),
    );
    _suggestionSlide = Tween(begin: const Offset(0, 0.1), end: Offset.zero).animate(
      CurvedAnimation(parent: _entryController, curve: const Interval(0.2, 0.55, curve: Curves.easeOutCubic)),
    );
    _actionsFade = Tween(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _entryController, curve: const Interval(0.3, 0.65, curve: Curves.easeOut)),
    );
    _restFade = Tween(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _entryController, curve: const Interval(0.4, 0.8, curve: Curves.easeOut)),
    );

    // Initialize particles
    final rng = Random();
    _particles = List.generate(18, (_) => _Particle(rng));

    _entryController.forward();
  }

  @override
  void dispose() {
    _bgController.dispose();
    _entryController.dispose();
    _breathController.dispose();
    _shimmerController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();

    final topPadding = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: SentioColors.background,
      // Let content extend to the very top so it scrolls under the blur
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          // Parallax animated background
          _buildParallaxBackground(),
          // Particle overlay
          _buildParticles(),
          // Content
          SingleChildScrollView(
            controller: _scrollController,
            physics: const BouncingScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: topPadding + 16),
                  SlideTransition(
                    position: _greetingSlide,
                    child: FadeTransition(
                      opacity: _greetingFade,
                      child: _buildGreeting(provider),
                    ),
                  ),
                  const SizedBox(height: 20),
                  SlideTransition(
                    position: _checkinSlide,
                    child: FadeTransition(
                      opacity: _checkinFade,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: _buildCheckinCard(context, provider),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  SlideTransition(
                    position: _suggestionSlide,
                    child: FadeTransition(
                      opacity: _suggestionFade,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: _buildSuggestion(context, provider),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  FadeTransition(
                    opacity: _actionsFade,
                    child: Padding(
                      padding: const EdgeInsets.only(left: 20),
                      child: _buildQuickActions(context),
                    ),
                  ),
                  const SizedBox(height: 24),
                  FadeTransition(
                    opacity: _restFade,
                    child: Column(
                      children: [
                        if (provider.checkins.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: _buildInsightCard(context, provider),
                          ),
                        if (provider.checkins.isNotEmpty) const SizedBox(height: 20),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: _buildDailyPhrase(context, provider),
                        ),
                        const SizedBox(height: 20),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: _buildMaterialsBanner(context),
                        ),
                        const SizedBox(height: 20),
                        if (provider.thisWeekCheckins.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: _buildWeeklyMood(context, provider),
                          ),
                        const SizedBox(height: 100),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          // Blurred header (iOS-style liquid glass)
          _buildBlurHeader(topPadding),
        ],
      ),
    );
  }

  // ══════════════════════════════════════
  // BLUR HEADER (iOS Liquid Glass style)
  // ══════════════════════════════════════

  Widget _buildBlurHeader(double topPadding) {
    return AnimatedBuilder(
      animation: _scrollController,
      builder: (context, _) {
        // Progressive blur strength based on scroll
        final scrollOffset = _scrollController.hasClients
            ? _scrollController.offset.clamp(0.0, 80.0)
            : 0.0;
        final progress = scrollOffset / 80.0;
        final blurAmount = 20.0 * progress;
        final bgOpacity = 0.55 * progress;

        return Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: IgnorePointer(
            child: ClipRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: blurAmount, sigmaY: blurAmount),
                child: Container(
                  height: topPadding + 8,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        SentioColors.background.withValues(alpha: bgOpacity + 0.1),
                        SentioColors.background.withValues(alpha: bgOpacity),
                        SentioColors.background.withValues(alpha: 0.0),
                      ],
                      stops: const [0.0, 0.7, 1.0],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // ══════════════════════════════════════
  // PARALLAX BACKGROUND
  // ══════════════════════════════════════

  Widget _buildParallaxBackground() {
    return AnimatedBuilder(
      animation: _bgController,
      builder: (context, _) {
        final t = _bgController.value;
        // Parallax: background moves at 30% of scroll speed
        final parallax = _scrollOffset * 0.3;
        return Transform.translate(
          offset: Offset(0, -parallax),
          child: Stack(
            children: [
              // Primary orb
              Positioned(
                right: -60 + t * 80,
                top: -40 + t * 50,
                child: Container(
                  width: 300,
                  height: 300,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        SentioColors.primary.withValues(alpha: 0.1 + t * 0.05),
                        SentioColors.primary.withValues(alpha: 0.0),
                      ],
                    ),
                  ),
                ),
              ),
              // Accent orb
              Positioned(
                left: -80 + t * 40,
                top: 200 + t * 60,
                child: Container(
                  width: 220,
                  height: 220,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        SentioColors.accent.withValues(alpha: 0.06 + t * 0.03),
                        SentioColors.accent.withValues(alpha: 0.0),
                      ],
                    ),
                  ),
                ),
              ),
              // Third pink orb
              Positioned(
                right: 40 + t * 30,
                top: 400 - t * 40,
                child: Container(
                  width: 150,
                  height: 150,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        const Color(0xFFFF6B9D).withValues(alpha: 0.04 + t * 0.02),
                        const Color(0xFFFF6B9D).withValues(alpha: 0.0),
                      ],
                    ),
                  ),
                ),
              ),
              // Top gradient overlay
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment(-1.0 + t, -1.0),
                      end: Alignment(1.0, 1.0 - t * 0.3),
                      colors: [
                        SentioColors.primary.withValues(alpha: 0.06 + t * 0.03),
                        SentioColors.background,
                        SentioColors.background,
                      ],
                      stops: const [0.0, 0.4, 1.0],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ══════════════════════════════════════
  // PARTICLE DOTS
  // ══════════════════════════════════════

  Widget _buildParticles() {
    return AnimatedBuilder(
      animation: _bgController,
      builder: (context, _) {
        final size = MediaQuery.of(context).size;
        final t = _bgController.value;
        return IgnorePointer(
          child: CustomPaint(
            size: size,
            painter: _ParticlePainter(_particles, t, _scrollOffset),
          ),
        );
      },
    );
  }

  // ══════════════════════════════════════
  // GREETING
  // ══════════════════════════════════════

  Widget _buildGreeting(AppProvider provider) {
    final streak = provider.profile?.checkinStreak ?? 0;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  SentioConstants.getGreeting(provider.userName),
                  style: GoogleFonts.manrope(
                    fontSize: 26, fontWeight: FontWeight.w800,
                    color: SentioColors.textPrimary, letterSpacing: -0.8, height: 1.2,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  SentioConstants.getGreetingSubtitle(),
                  style: GoogleFonts.manrope(fontSize: 14, color: SentioColors.textSecondary),
                ),
              ],
            ),
          ),
          if (streak > 0)
            AnimatedBuilder(
              animation: _breathController,
              builder: (context, _) {
                final glow = _breathController.value;
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.orange.withValues(alpha: 0.15 + glow * 0.1)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.orange.withValues(alpha: 0.08 + glow * 0.08),
                        blurRadius: 12 + glow * 8, spreadRadius: -2,
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.local_fire_department_rounded, size: 16, color: Colors.orange),
                      const SizedBox(width: 4),
                      Text('$streak', style: GoogleFonts.manrope(fontSize: 15, fontWeight: FontWeight.w800, color: Colors.orange)),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════
  // CHECK-IN CARD (Glassmorphism)
  // ══════════════════════════════════════

  Widget _buildCheckinCard(BuildContext context, AppProvider provider) {
    final hasCheckedIn = provider.hasCheckedInToday;
    final todayCheckin = provider.todayCheckin;

    if (hasCheckedIn && todayCheckin != null) {
      final emotion = SentioConstants.emotions.firstWhere(
        (e) => e['id'] == todayCheckin.primaryEmotion,
        orElse: () => SentioConstants.emotions.first,
      );
      final emotionColor = Color(emotion['color'] as int);

      return ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: SentioColors.surface.withValues(alpha: 0.85),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: emotionColor.withValues(alpha: 0.12)),
              boxShadow: [
                BoxShadow(color: emotionColor.withValues(alpha: 0.08), blurRadius: 24, spreadRadius: -4, offset: const Offset(0, 8)),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 50, height: 50,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [emotionColor.withValues(alpha: 0.2), emotionColor.withValues(alpha: 0.08)],
                          begin: Alignment.topLeft, end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Center(child: Text(emotion['emoji'], style: const TextStyle(fontSize: 26))),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Hoy te sentís ${(emotion['label'] as String).toLowerCase()}',
                            style: GoogleFonts.manrope(fontSize: 15, fontWeight: FontWeight.w700, color: SentioColors.textPrimary),
                          ),
                          const SizedBox(height: 2),
                          Text('Check-in completado', style: GoogleFonts.manrope(fontSize: 12, color: SentioColors.textTertiary)),
                        ],
                      ),
                    ),
                    _buildScaleButton('Editar', emotionColor, () => context.push('/checkin')),
                  ],
                ),
                const SizedBox(height: 18),
                _buildAnimatedMetricBar('Energía', todayCheckin.energyLevel, 5, SentioColors.accent, Icons.bolt_rounded),
                const SizedBox(height: 10),
                _buildAnimatedMetricBar('Estrés', todayCheckin.stressLevel, 5, SentioColors.warning, Icons.whatshot_rounded),
                if (todayCheckin.motivationLevel != null) ...[
                  const SizedBox(height: 10),
                  _buildAnimatedMetricBar('Motivación', todayCheckin.motivationLevel!, 5, SentioColors.primary, Icons.rocket_launch_rounded),
                ],
                if (todayCheckin.note != null && todayCheckin.note!.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  Container(
                    width: double.infinity, padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.03),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.04)),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.format_quote_rounded, size: 14, color: SentioColors.textTertiary),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            todayCheckin.note!,
                            style: GoogleFonts.manrope(fontSize: 13, color: SentioColors.textSecondary, fontStyle: FontStyle.italic, height: 1.4),
                            maxLines: 2, overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      );
    }

    // Not checked in — breathing glow CTA with glassmorphism
    return AnimatedBuilder(
      animation: _breathController,
      builder: (context, _) {
        final glow = _breathController.value;
        return GestureDetector(
          onTap: () { HapticFeedback.lightImpact(); context.push('/checkin'); },
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      SentioColors.surface.withValues(alpha: 0.8),
                      SentioColors.primary.withValues(alpha: 0.06 + glow * 0.04),
                    ],
                    begin: Alignment.topLeft, end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: SentioColors.primary.withValues(alpha: 0.12 + glow * 0.08)),
                  boxShadow: [
                    BoxShadow(
                      color: SentioColors.primary.withValues(alpha: 0.06 + glow * 0.06),
                      blurRadius: 20 + glow * 12, spreadRadius: -4, offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '¿Cómo estás hoy,\nde verdad?',
                            style: GoogleFonts.manrope(fontSize: 20, fontWeight: FontWeight.w800, color: SentioColors.textPrimary, letterSpacing: -0.3, height: 1.25),
                          ),
                          const SizedBox(height: 8),
                          Text('Registrar cómo te sentís ya es un paso.', style: GoogleFonts.manrope(fontSize: 13, color: SentioColors.textSecondary, height: 1.4)),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Container(
                      width: 52, height: 52,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(colors: [SentioColors.primary, SentioColors.primary.withValues(alpha: 0.7)], begin: Alignment.topLeft, end: Alignment.bottomRight),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [BoxShadow(color: SentioColors.primary.withValues(alpha: 0.25 + glow * 0.15), blurRadius: 16 + glow * 8, spreadRadius: -2)],
                      ),
                      child: const Icon(Icons.add_rounded, color: Colors.white, size: 28),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // ══════════════════════════════════════
  // SCALE BUTTON (spring press)
  // ══════════════════════════════════════

  Widget _buildScaleButton(String label, Color color, VoidCallback onTap) {
    return _SpringButton(
      onTap: () { HapticFeedback.lightImpact(); onTap(); },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withValues(alpha: 0.15)),
        ),
        child: Text(label, style: GoogleFonts.manrope(fontSize: 12, fontWeight: FontWeight.w600, color: color)),
      ),
    );
  }

  // ══════════════════════════════════════
  // ANIMATED METRIC BAR
  // ══════════════════════════════════════

  Widget _buildAnimatedMetricBar(String label, int value, int maxValue, Color color, IconData icon) {
    final fraction = value / maxValue;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: fraction),
      duration: const Duration(milliseconds: 800),
      curve: Curves.easeOutCubic,
      builder: (context, animatedFraction, _) {
        return Row(
          children: [
            Icon(icon, size: 15, color: color.withValues(alpha: 0.8)),
            const SizedBox(width: 8),
            SizedBox(width: 68, child: Text(label, style: GoogleFonts.manrope(fontSize: 12, fontWeight: FontWeight.w500, color: SentioColors.textSecondary))),
            const SizedBox(width: 8),
            Expanded(
              child: Container(
                height: 6,
                decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(3)),
                child: FractionallySizedBox(
                  alignment: Alignment.centerLeft, widthFactor: animatedFraction,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: [color, color.withValues(alpha: 0.5)]),
                      borderRadius: BorderRadius.circular(3),
                      boxShadow: [BoxShadow(color: color.withValues(alpha: 0.3), blurRadius: 8, spreadRadius: -2)],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text('$value/$maxValue', style: GoogleFonts.manrope(fontSize: 11, fontWeight: FontWeight.w700, color: color)),
          ],
        );
      },
    );
  }

  // ══════════════════════════════════════
  // SUGGESTION CARD
  // ══════════════════════════════════════

  Widget _buildSuggestion(BuildContext context, AppProvider provider) {
    String title; String subtitle; IconData icon; VoidCallback onTap; Color color;

    if (provider.averageStress > 3.5) {
      title = 'Tus últimos días fueron intensos'; subtitle = '¿Qué tal una pausa de 2 minutos?';
      icon = Icons.self_improvement_rounded; onTap = () => context.push('/tool/pause_2min'); color = SentioColors.warning;
    } else if (provider.journalEntries.isEmpty) {
      title = 'Tu diario te espera'; subtitle = 'Escribir puede ayudarte a ver más claro.';
      icon = Icons.edit_note_rounded; onTap = () => context.push('/journal/new'); color = SentioColors.accent;
    } else {
      title = 'Hablá con tu asistente'; subtitle = 'A veces poner en palabras lo que sentís ayuda.';
      icon = Icons.chat_bubble_outline_rounded; onTap = () => context.push('/chat'); color = SentioColors.primary;
    }

    return _SpringButton(
      onTap: () { HapticFeedback.selectionClick(); onTap(); },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: SentioColors.surface, borderRadius: BorderRadius.circular(20),
          border: Border.all(color: SentioColors.border),
        ),
        child: Row(
          children: [
            Container(
              width: 44, height: 44,
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [color.withValues(alpha: 0.15), color.withValues(alpha: 0.05)], begin: Alignment.topLeft, end: Alignment.bottomRight),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: GoogleFonts.manrope(fontSize: 14, fontWeight: FontWeight.w700, color: SentioColors.textPrimary)),
                  const SizedBox(height: 2),
                  Text(subtitle, style: GoogleFonts.manrope(fontSize: 12, color: SentioColors.textSecondary)),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios_rounded, size: 14, color: SentioColors.textTertiary),
          ],
        ),
      ),
    );
  }

  // ══════════════════════════════════════
  // QUICK ACTIONS (with scale + stagger)
  // ══════════════════════════════════════

  Widget _buildQuickActions(BuildContext context) {
    final actions = [
      _QA(Icons.edit_note_rounded, 'Escribir', SentioColors.accent, () => context.push('/journal/new')),
      _QA(Icons.chat_bubble_outline_rounded, 'Hablar', SentioColors.primary, () => context.push('/chat')),
      _QA(Icons.spa_outlined, 'Respirar', const Color(0xFF7B9E87), () => context.push('/tool/breathing_calm')),
      _QA(Icons.account_balance_wallet_outlined, 'Finanzas', const Color(0xFF4CAF50), () => context.push('/finance')),
      _QA(Icons.grid_view_rounded, 'Herramientas', SentioColors.warning, () => context.push('/tools')),
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: actions.asMap().entries.map((entry) {
          final i = entry.key;
          final a = entry.value;
          return TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: 1.0),
            duration: Duration(milliseconds: 500 + i * 80),
            curve: Curves.easeOutCubic,
            builder: (context, val, child) {
              return Opacity(
                opacity: val,
                child: Transform.translate(offset: Offset(0, 12 * (1 - val)), child: child),
              );
            },
            child: Padding(
              padding: EdgeInsets.only(right: i == actions.length - 1 ? 20 : 16),
              child: _SpringButton(
                onTap: () { HapticFeedback.selectionClick(); a.onTap(); },
                child: Column(
                  children: [
                    Container(
                      width: 54, height: 54,
                      decoration: BoxDecoration(
                        color: a.color.withValues(alpha: 0.1), shape: BoxShape.circle,
                        border: Border.all(color: a.color.withValues(alpha: 0.15)),
                      ),
                      child: Icon(a.icon, color: a.color, size: 24),
                    ),
                    const SizedBox(height: 8),
                    Text(a.label, style: GoogleFonts.manrope(fontSize: 11, fontWeight: FontWeight.w600, color: SentioColors.textSecondary)),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ══════════════════════════════════════
  // INSIGHT CARD
  // ══════════════════════════════════════

  Widget _buildInsightCard(BuildContext context, AppProvider provider) {
    final avgStress = provider.averageStress;
    String insight; IconData insightIcon; Color insightColor;

    if (avgStress > 3.5) {
      insight = 'Tu estrés promedio esta semana es alto. Considerá hacer más pausas.';
      insightIcon = Icons.warning_amber_rounded; insightColor = SentioColors.warning;
    } else if (avgStress < 2.5) {
      insight = 'Tu nivel de estrés está más bajo que antes. Algo estás haciendo bien.';
      insightIcon = Icons.trending_down_rounded; insightColor = SentioColors.accent;
    } else {
      insight = 'Tu semana tiene altibajos normales. Lo importante es que estás prestando atención.';
      insightIcon = Icons.insights_rounded; insightColor = SentioColors.primary;
    }

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [SentioColors.surface, insightColor.withValues(alpha: 0.04)], begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: insightColor.withValues(alpha: 0.1)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38, height: 38,
            decoration: BoxDecoration(color: insightColor.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(12)),
            child: Icon(insightIcon, color: insightColor, size: 18),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Insight del día', style: GoogleFonts.manrope(fontSize: 12, fontWeight: FontWeight.w700, color: insightColor, letterSpacing: 0.3)),
                const SizedBox(height: 5),
                Text(insight, style: GoogleFonts.manrope(fontSize: 13, color: SentioColors.textPrimary, height: 1.5)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════
  // DAILY PHRASE (with shimmer)
  // ══════════════════════════════════════

  // ══════════════════════════════════════
  // MATERIALS & INTERVIEWS BANNER
  // ══════════════════════════════════════

  Widget _buildMaterialsBanner(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        context.push('/materials');
      },
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [
              Color(0xFF1A0033),
              Color(0xFF2D1B69),
              Color(0xFF0404FB),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: SentioColors.primary.withValues(alpha: 0.25),
              blurRadius: 24,
              spreadRadius: -4,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
              ),
              child: const Icon(
                Icons.play_circle_filled_rounded,
                color: Colors.white,
                size: 30,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFF0033),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'YOUTUBE',
                          style: GoogleFonts.manrope(
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'NUEVO',
                        style: GoogleFonts.manrope(
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          color: SentioColors.accent,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Materiales y Entrevistas',
                    style: GoogleFonts.manrope(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Entrevistas con emprendedores y referentes',
                    style: GoogleFonts.manrope(
                      fontSize: 12,
                      color: Colors.white.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.arrow_forward_rounded,
                color: Colors.white,
                size: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDailyPhrase(BuildContext context, AppProvider provider) {
    final phrase = provider.dailyPhrase.isEmpty
        ? 'No necesitás tener todas las respuestas. Solo la siguiente.'
        : provider.dailyPhrase;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
      decoration: BoxDecoration(
        color: SentioColors.surface, borderRadius: BorderRadius.circular(20),
        border: Border.all(color: SentioColors.border),
      ),
      child: Column(
        children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(color: SentioColors.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
            child: Icon(Icons.format_quote_rounded, color: SentioColors.primary.withValues(alpha: 0.6), size: 20),
          ),
          const SizedBox(height: 16),
          // Shimmer text
          AnimatedBuilder(
            animation: _shimmerController,
            builder: (context, _) {
              return ShaderMask(
                shaderCallback: (bounds) {
                  final shimmerPosition = _shimmerController.value * 3 - 1;
                  return LinearGradient(
                    begin: Alignment(shimmerPosition - 0.3, 0),
                    end: Alignment(shimmerPosition + 0.3, 0),
                    colors: [
                      SentioColors.textPrimary,
                      SentioColors.accent.withValues(alpha: 0.9),
                      SentioColors.textPrimary,
                    ],
                    stops: const [0.0, 0.5, 1.0],
                  ).createShader(bounds);
                },
                child: Text(
                  phrase,
                  style: GoogleFonts.manrope(
                    fontSize: 16, fontWeight: FontWeight.w600, height: 1.5,
                    color: Colors.white, letterSpacing: -0.2,
                  ),
                  textAlign: TextAlign.center,
                ),
              );
            },
          ),
          const SizedBox(height: 14),
          Container(
            width: 28, height: 2,
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [SentioColors.primary.withValues(alpha: 0.4), SentioColors.accent.withValues(alpha: 0.4)]),
              borderRadius: BorderRadius.circular(1),
            ),
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════
  // WEEKLY MOOD
  // ══════════════════════════════════════

  Widget _buildWeeklyMood(BuildContext context, AppProvider provider) {
    final weekCheckins = provider.thisWeekCheckins;
    final weeklyData = provider.weeklyEvolutionEmotional;
    final dayNames = ['L', 'M', 'X', 'J', 'V', 'S', 'D'];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: SentioColors.surface, borderRadius: BorderRadius.circular(20),
        border: Border.all(color: SentioColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Tu semana', style: GoogleFonts.manrope(fontSize: 16, fontWeight: FontWeight.w700, color: SentioColors.textPrimary)),
              _buildScaleButton('Ver más', SentioColors.primary, () => context.push('/progress')),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 130,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(7, (index) {
                final value = weeklyData[index];
                final hasData = value > 0;
                final barHeight = hasData ? (value * 90).clamp(10.0, 90.0) : 6.0;
                final now = DateTime.now();
                final dayDate = now.subtract(Duration(days: 6 - index));
                final dayCheckin = weekCheckins.where((c) =>
                  c.createdAt.year == dayDate.year && c.createdAt.month == dayDate.month && c.createdAt.day == dayDate.day
                ).firstOrNull;

                Color barColor;
                if (dayCheckin != null) {
                  final emotion = SentioConstants.emotions.firstWhere((e) => e['id'] == dayCheckin.primaryEmotion, orElse: () => SentioConstants.emotions.first);
                  barColor = Color(emotion['color'] as int);
                } else { barColor = SentioColors.textTertiary; }

                final isToday = dayDate.year == now.year && dayDate.month == now.month && dayDate.day == now.day;

                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 3),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TweenAnimationBuilder<double>(
                          tween: Tween(begin: 0.0, end: barHeight),
                          duration: Duration(milliseconds: 600 + index * 100),
                          curve: Curves.easeOutCubic,
                          builder: (context, h, _) {
                            return Container(
                              height: h,
                              decoration: BoxDecoration(
                                gradient: hasData ? LinearGradient(colors: [barColor, barColor.withValues(alpha: 0.4)], begin: Alignment.topCenter, end: Alignment.bottomCenter) : null,
                                color: hasData ? null : Colors.white.withValues(alpha: 0.04),
                                borderRadius: BorderRadius.circular(6),
                                boxShadow: hasData ? [BoxShadow(color: barColor.withValues(alpha: 0.2), blurRadius: 8, spreadRadius: -2, offset: const Offset(0, 2))] : null,
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 8),
                        Container(
                          width: 26, height: 26,
                          decoration: BoxDecoration(
                            color: isToday ? SentioColors.primary.withValues(alpha: 0.12) : Colors.transparent,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Center(
                            child: Text(dayNames[index], style: GoogleFonts.manrope(fontSize: 11, fontWeight: isToday ? FontWeight.w700 : FontWeight.w500, color: isToday ? SentioColors.primary : SentioColors.textTertiary)),
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

// ══════════════════════════════════════
// SPRING BUTTON (scale on press)
// ══════════════════════════════════════

class _SpringButton extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;
  const _SpringButton({required this.child, required this.onTap});

  @override
  State<_SpringButton> createState() => _SpringButtonState();
}

class _SpringButtonState extends State<_SpringButton> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 150));
    _scale = Tween(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() { _controller.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) { _controller.reverse(); widget.onTap(); },
      onTapCancel: () => _controller.reverse(),
      child: ScaleTransition(scale: _scale, child: widget.child),
    );
  }
}

// ══════════════════════════════════════
// PARTICLE SYSTEM
// ══════════════════════════════════════

class _Particle {
  double x, y, size, speed, opacity;
  bool isAccent;

  _Particle(Random rng)
      : x = rng.nextDouble(),
        y = rng.nextDouble(),
        size = rng.nextDouble() * 2 + 0.5,
        speed = rng.nextDouble() * 0.3 + 0.1,
        opacity = rng.nextDouble() * 0.25 + 0.05,
        isAccent = rng.nextBool();
}

class _ParticlePainter extends CustomPainter {
  final List<_Particle> particles;
  final double time;
  final double scrollOffset;

  _ParticlePainter(this.particles, this.time, this.scrollOffset);

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in particles) {
      final px = p.x * size.width + sin(time * pi * 2 + p.speed * 10) * 15;
      final py = (p.y * size.height * 0.6) + cos(time * pi * 2 + p.x * 10) * 10 - scrollOffset * 0.15;

      if (py < -20 || py > size.height) continue;

      final paint = Paint()
        ..color = (p.isAccent ? const Color(0xFF00FFBD) : const Color(0xFF0404FB))
            .withValues(alpha: p.opacity * (0.6 + sin(time * pi * 2 + p.y * 5) * 0.4))
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, p.size * 0.5);

      canvas.drawCircle(Offset(px, py), p.size, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _ParticlePainter oldDelegate) => true;
}

class _QA {
  final IconData icon; final String label; final Color color; final VoidCallback onTap;
  const _QA(this.icon, this.label, this.color, this.onTap);
}
