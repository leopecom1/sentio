import 'dart:async';
import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:sentio_app/config/theme.dart';
import 'package:sentio_app/config/constants.dart';
import 'package:sentio_app/models/gamification.dart';
import 'package:sentio_app/providers/app_provider.dart';

// ── Breathing phase state machine ──────────────────────────────────

enum BreathPhase { inhale, holdIn, exhale, holdOut }

class _BreathingConfig {
  final int inhale;
  final int holdIn;
  final int exhale;
  final int holdOut;
  final int totalCycles;

  const _BreathingConfig({
    required this.inhale,
    required this.holdIn,
    required this.exhale,
    required this.holdOut,
    required this.totalCycles,
  });

  int durationOf(BreathPhase phase) {
    switch (phase) {
      case BreathPhase.inhale: return inhale;
      case BreathPhase.holdIn: return holdIn;
      case BreathPhase.exhale: return exhale;
      case BreathPhase.holdOut: return holdOut;
    }
  }

  BreathPhase? nextPhase(BreathPhase current) {
    switch (current) {
      case BreathPhase.inhale:
        return holdIn > 0 ? BreathPhase.holdIn : BreathPhase.exhale;
      case BreathPhase.holdIn:
        return BreathPhase.exhale;
      case BreathPhase.exhale:
        return holdOut > 0 ? BreathPhase.holdOut : null;
      case BreathPhase.holdOut:
        return null;
    }
  }
}

// ── Tool Detail Screen ─────────────────────────────────────────────

class ToolDetailScreen extends StatefulWidget {
  final String toolId;

  const ToolDetailScreen({super.key, required this.toolId});

  @override
  State<ToolDetailScreen> createState() => _ToolDetailScreenState();
}

class _ToolDetailScreenState extends State<ToolDetailScreen>
    with TickerProviderStateMixin {
  late Map<String, dynamic> _tool;
  bool _started = false;
  bool _completed = false;

  // General timer
  int _remainingSeconds = 0;
  Timer? _timer;

  // Breathing state
  bool get _isBreathing => (_tool['category'] as String) == 'breathing';
  _BreathingConfig? _breathConfig;
  BreathPhase _currentPhase = BreathPhase.inhale;
  int _phaseSecondsLeft = 0;
  int _currentCycle = 1;
  Timer? _phaseTimer;

  // Animations
  late AnimationController _circleController;
  late Animation<double> _circleSize;
  late AnimationController _glowController;
  late AnimationController _bgController;
  late AnimationController _entryController;
  late Animation<double> _entryFade;
  late Animation<Offset> _entrySlide;

  @override
  void initState() {
    super.initState();
    _tool = SentioConstants.tools.firstWhere(
      (t) => t['id'] == widget.toolId,
      orElse: () => SentioConstants.tools.first,
    );
    _remainingSeconds = _tool['durationSeconds'] as int;

    if (_isBreathing && _tool['breathingPattern'] != null) {
      final p = _tool['breathingPattern'] as Map<String, dynamic>;
      _breathConfig = _BreathingConfig(
        inhale: p['inhale'] as int,
        holdIn: p['holdIn'] as int,
        exhale: p['exhale'] as int,
        holdOut: p['holdOut'] as int,
        totalCycles: _tool['totalCycles'] as int? ?? 8,
      );
    }

    _circleController = AnimationController(
      duration: const Duration(seconds: 4),
      vsync: this,
    );
    _circleSize = Tween(begin: 120.0, end: 280.0).animate(
      CurvedAnimation(parent: _circleController, curve: Curves.easeInOutCubic),
    );

    _glowController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat(reverse: true);

    _bgController = AnimationController(
      duration: const Duration(seconds: 8),
      vsync: this,
    )..repeat(reverse: true);

    _entryController = AnimationController(
      duration: const Duration(milliseconds: 700),
      vsync: this,
    );
    _entryFade = Tween(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _entryController, curve: Curves.easeOut),
    );
    _entrySlide = Tween(begin: const Offset(0, 0.1), end: Offset.zero).animate(
      CurvedAnimation(parent: _entryController, curve: Curves.easeOutCubic),
    );
    _entryController.forward();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _phaseTimer?.cancel();
    _circleController.dispose();
    _glowController.dispose();
    _bgController.dispose();
    _entryController.dispose();
    super.dispose();
  }

  Color get _toolColor {
    switch (_tool['category'] as String) {
      case 'breathing': return SentioColors.accent;
      case 'pause': return SentioColors.primary;
      case 'anxiety': return const Color(0xFF9B8EC4);
      case 'entrepreneur': return SentioColors.warning;
      default: return SentioColors.primary;
    }
  }

  IconData get _toolIcon {
    final custom = _tool['icon'] as IconData?;
    if (custom != null) return custom;
    switch (_tool['category'] as String) {
      case 'breathing': return Icons.air_rounded;
      case 'pause': return Icons.pause_circle_outline_rounded;
      case 'anxiety': return Icons.self_improvement_rounded;
      case 'entrepreneur': return Icons.rocket_launch_outlined;
      default: return Icons.spa_outlined;
    }
  }

  List<Map<String, dynamic>> get _toolSteps {
    final raw = _tool['steps'] as List?;
    if (raw == null) return const [];
    return raw.cast<Map<String, dynamic>>();
  }

  int get _currentStepIndex {
    final steps = _toolSteps;
    if (steps.isEmpty) return 0;
    final totalTimed = steps.fold<int>(0, (a, s) => a + ((s['seconds'] as int?) ?? 0));
    if (totalTimed <= 0) return 0;
    final elapsed = (_tool['durationSeconds'] as int) - _remainingSeconds;
    int acc = 0;
    for (int i = 0; i < steps.length; i++) {
      acc += (steps[i]['seconds'] as int?) ?? 0;
      if (elapsed < acc) return i;
    }
    return steps.length - 1;
  }

  void _start() {
    HapticFeedback.lightImpact();
    setState(() => _started = true);
    _entryController.reset();
    _entryController.forward();
    _startGlobalTimer();
    if (_isBreathing && _breathConfig != null) {
      _startBreathingPhase(BreathPhase.inhale);
    }
  }

  void _startGlobalTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {
        _remainingSeconds--;
        if (_remainingSeconds <= 0) _complete();
      });
    });
  }

  void _startBreathingPhase(BreathPhase phase) {
    final config = _breathConfig!;
    final duration = config.durationOf(phase);

    setState(() {
      _currentPhase = phase;
      _phaseSecondsLeft = duration;
    });

    HapticFeedback.lightImpact();

    _circleController.stop();
    _circleController.duration = Duration(seconds: duration);

    switch (phase) {
      case BreathPhase.inhale:
        _circleController.forward(from: 0.0);
        break;
      case BreathPhase.holdIn:
        _circleController.value = 1.0;
        break;
      case BreathPhase.exhale:
        _circleController.reverse(from: 1.0);
        break;
      case BreathPhase.holdOut:
        _circleController.value = 0.0;
        break;
    }

    _phaseTimer?.cancel();
    _phaseTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {
        _phaseSecondsLeft--;
        if (_phaseSecondsLeft <= 0) {
          _phaseTimer?.cancel();
          _advancePhase();
        }
      });
    });
  }

  void _advancePhase() {
    final config = _breathConfig!;
    final next = config.nextPhase(_currentPhase);

    if (next != null) {
      _startBreathingPhase(next);
    } else {
      if (_currentCycle >= config.totalCycles) {
        _complete();
      } else {
        setState(() => _currentCycle++);
        _startBreathingPhase(BreathPhase.inhale);
      }
    }
  }

  void _complete() {
    _timer?.cancel();
    _phaseTimer?.cancel();
    _circleController.stop();
    HapticFeedback.heavyImpact();
    setState(() => _completed = true);
    _entryController.reset();
    _entryController.forward();

    final provider = context.read<AppProvider>();
    provider.saveToolUsage(
      toolId: _tool['id'],
      toolCategory: _tool['category'],
      durationSeconds: (_tool['durationSeconds'] as int) - _remainingSeconds,
      completed: _remainingSeconds <= 0,
    );
  }

  String _phaseLabel(BreathPhase phase) {
    switch (phase) {
      case BreathPhase.inhale: return 'Inhalá';
      case BreathPhase.holdIn: return 'Mantené';
      case BreathPhase.exhale: return 'Exhalá';
      case BreathPhase.holdOut: return 'Pausa';
    }
  }

  String _formatTime(int seconds) {
    final min = seconds ~/ 60;
    final sec = seconds % 60;
    return '${min.toString().padLeft(2, '0')}:${sec.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    if (_completed) return _buildCompletedView();
    if (_started) return _buildActiveView();
    return _buildStartView();
  }

  // ══════════════════════════════════════
  // ANIMATED BACKGROUND (shared)
  // ══════════════════════════════════════

  Widget _animatedBackground(Color color) {
    return AnimatedBuilder(
      animation: _bgController,
      builder: (context, _) {
        final t = _bgController.value;
        return Stack(
          children: [
            Positioned(
              right: -100 + t * 60,
              top: -50 + t * 40,
              child: Container(
                width: 320,
                height: 320,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      color.withValues(alpha: 0.12 + t * 0.06),
                      color.withValues(alpha: 0.0),
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              left: -80 + t * 30,
              bottom: 100 + t * 50,
              child: Container(
                width: 250,
                height: 250,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      color.withValues(alpha: 0.08 + t * 0.04),
                      color.withValues(alpha: 0.0),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  // ══════════════════════════════════════
  // START VIEW (premium intro)
  // ══════════════════════════════════════

  Widget _buildStartView() {
    final color = _toolColor;

    return Scaffold(
      backgroundColor: SentioColors.background,
      body: Stack(
        children: [
          _animatedBackground(color),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  // Header with back button
                  Row(
                    children: [
                      _SpringTap(
                        onTap: () => context.pop(),
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: SentioColors.border),
                          ),
                          child: const Icon(
                            Icons.arrow_back_rounded,
                            color: SentioColors.textPrimary,
                            size: 20,
                          ),
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: color.withValues(alpha: 0.2)),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.timer_outlined, size: 13, color: color),
                            const SizedBox(width: 5),
                            Text(
                              _tool['duration'],
                              style: GoogleFonts.manrope(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: color,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  // Content
                  Expanded(
                    child: SlideTransition(
                      position: _entrySlide,
                      child: FadeTransition(
                        opacity: _entryFade,
                        child: SingleChildScrollView(
                          physics: const BouncingScrollPhysics(),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const SizedBox(height: 8),
                            // Animated icon with glow
                            AnimatedBuilder(
                              animation: _glowController,
                              builder: (context, _) {
                                final glow = _glowController.value;
                                return Container(
                                  width: 140,
                                  height: 140,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: RadialGradient(
                                      colors: [
                                        color.withValues(alpha: 0.25),
                                        color.withValues(alpha: 0.08),
                                        Colors.transparent,
                                      ],
                                      stops: const [0.0, 0.6, 1.0],
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: color.withValues(alpha: 0.2 + glow * 0.2),
                                        blurRadius: 40 + glow * 20,
                                        spreadRadius: 6,
                                      ),
                                    ],
                                  ),
                                  child: Center(
                                    child: Container(
                                      width: 80,
                                      height: 80,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        gradient: LinearGradient(
                                          colors: [
                                            color.withValues(alpha: 0.3),
                                            color.withValues(alpha: 0.1),
                                          ],
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                        ),
                                        border: Border.all(
                                          color: color.withValues(alpha: 0.4),
                                          width: 1.5,
                                        ),
                                      ),
                                      child: Icon(_toolIcon, color: color, size: 38),
                                    ),
                                  ),
                                );
                              },
                            ),
                            const SizedBox(height: 36),
                            Text(
                              _tool['title'],
                              style: GoogleFonts.manrope(
                                fontSize: 30,
                                fontWeight: FontWeight.w800,
                                color: SentioColors.textPrimary,
                                letterSpacing: -1,
                                height: 1.1,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 14),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 20),
                              child: Text(
                                (_tool['intro'] as String?) ?? _tool['description'],
                                style: GoogleFonts.manrope(
                                  fontSize: 14,
                                  color: SentioColors.textSecondary,
                                  height: 1.5,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                            if (_toolSteps.isNotEmpty) ...[
                              const SizedBox(height: 24),
                              _buildStepsPreview(color),
                            ],
                            if (_isBreathing && _breathConfig != null) ...[
                              const SizedBox(height: 20),
                              _buildPatternChips(color),
                            ],
                              const SizedBox(height: 8),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Big start button with glow
                  AnimatedBuilder(
                    animation: _glowController,
                    builder: (context, _) {
                      final glow = _glowController.value;
                      return _SpringTap(
                        onTap: _start,
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [color, color.withValues(alpha: 0.7)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: color.withValues(alpha: 0.3 + glow * 0.2),
                                blurRadius: 24 + glow * 8,
                                spreadRadius: -2,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 24),
                              const SizedBox(width: 6),
                              Text(
                                'Empezar',
                                style: GoogleFonts.manrope(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                  letterSpacing: 0.3,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepsPreview(Color color) {
    final steps = _toolSteps;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: SentioColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.list_alt_rounded, color: color, size: 16),
              const SizedBox(width: 8),
              Text(
                'QUÉ VAS A HACER',
                style: GoogleFonts.manrope(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: color,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ...List.generate(steps.length, (i) {
            final step = steps[i];
            final isLast = i == steps.length - 1;
            return Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 22,
                    height: 22,
                    margin: const EdgeInsets.only(top: 1),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: color.withValues(alpha: 0.3)),
                    ),
                    child: Center(
                      child: Text(
                        '${i + 1}',
                        style: GoogleFonts.manrope(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: color,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      step['text'] as String,
                      style: GoogleFonts.manrope(
                        fontSize: 13,
                        color: SentioColors.textPrimary,
                        height: 1.4,
                      ),
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

  Widget _buildPatternChips(Color color) {
    final config = _breathConfig!;
    final phases = <MapEntry<String, int>>[
      MapEntry('Inhalá', config.inhale),
      if (config.holdIn > 0) MapEntry('Mantené', config.holdIn),
      MapEntry('Exhalá', config.exhale),
      if (config.holdOut > 0) MapEntry('Pausa', config.holdOut),
    ];

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      alignment: WrapAlignment.center,
      children: phases.map((e) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: color.withValues(alpha: 0.15)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                e.key,
                style: GoogleFonts.manrope(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: SentioColors.textSecondary,
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${e.value}s',
                  style: GoogleFonts.manrope(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: color,
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  // ══════════════════════════════════════
  // ACTIVE VIEW (premium during practice)
  // ══════════════════════════════════════

  Widget _buildActiveView() {
    final color = _toolColor;
    final totalSeconds = _tool['durationSeconds'] as int;
    final progress = 1 - (_remainingSeconds / totalSeconds);

    return Scaffold(
      backgroundColor: SentioColors.background,
      body: Stack(
        children: [
          _animatedBackground(color),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Column(
                children: [
                  // Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _SpringTap(
                        onTap: () {
                          _timer?.cancel();
                          _phaseTimer?.cancel();
                          _circleController.stop();
                          context.pop();
                        },
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: SentioColors.border),
                          ),
                          child: const Icon(Icons.close_rounded, color: SentioColors.textPrimary, size: 18),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: SentioColors.border),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.timer_outlined, size: 14, color: color),
                            const SizedBox(width: 6),
                            Text(
                              _formatTime(_remainingSeconds),
                              style: GoogleFonts.manrope(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: SentioColors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  // Main content
                  Expanded(
                    child: Center(
                      child: _isBreathing && _breathConfig != null
                          ? _buildBreathingCircle(color)
                          : _buildNonBreathingActive(color),
                    ),
                  ),

                  // Premium progress bar
                  Container(
                    height: 6,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(3),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(3),
                      child: TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0.0, end: progress),
                        duration: const Duration(milliseconds: 400),
                        curve: Curves.easeOut,
                        builder: (context, value, _) {
                          return LinearProgressIndicator(
                            value: value,
                            backgroundColor: Colors.transparent,
                            valueColor: AlwaysStoppedAnimation(color),
                            minHeight: 6,
                          );
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextButton.icon(
                    onPressed: _complete,
                    icon: Icon(Icons.check_rounded, size: 16, color: SentioColors.textTertiary),
                    label: Text(
                      'Terminar antes',
                      style: GoogleFonts.manrope(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: SentioColors.textTertiary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNonBreathingActive(Color color) {
    final steps = _toolSteps;
    final hasTimedSteps = steps.any((s) => ((s['seconds'] as int?) ?? 0) > 0);
    final stepIdx = hasTimedSteps ? _currentStepIndex : 0;
    final currentStep = steps.isNotEmpty ? steps[stepIdx] : null;

    return AnimatedBuilder(
      animation: _glowController,
      builder: (context, _) {
        final glow = _glowController.value;
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Step indicator pill
            if (currentStep != null && hasTimedSteps)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: SentioColors.border),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Paso ',
                      style: GoogleFonts.manrope(
                        fontSize: 12,
                        color: SentioColors.textTertiary,
                      ),
                    ),
                    Text(
                      '${stepIdx + 1}',
                      style: GoogleFonts.manrope(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: color,
                      ),
                    ),
                    Text(
                      ' / ${steps.length}',
                      style: GoogleFonts.manrope(
                        fontSize: 12,
                        color: SentioColors.textTertiary,
                      ),
                    ),
                  ],
                ),
              ),
            if (currentStep != null && hasTimedSteps) const SizedBox(height: 24),
            Container(
              width: 180,
              height: 180,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    color.withValues(alpha: 0.2),
                    color.withValues(alpha: 0.05),
                    Colors.transparent,
                  ],
                  stops: const [0.0, 0.6, 1.0],
                ),
                boxShadow: [
                  BoxShadow(
                    color: color.withValues(alpha: 0.15 + glow * 0.15),
                    blurRadius: 50 + glow * 20,
                    spreadRadius: 10,
                  ),
                ],
              ),
              child: Center(
                child: Container(
                  width: 96,
                  height: 96,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [
                        color.withValues(alpha: 0.3),
                        color.withValues(alpha: 0.12),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    border: Border.all(color: color.withValues(alpha: 0.4), width: 1.5),
                  ),
                  child: Icon(_toolIcon, color: color, size: 48),
                ),
              ),
            ),
            const SizedBox(height: 36),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 400),
                transitionBuilder: (child, anim) => FadeTransition(
                  opacity: anim,
                  child: SlideTransition(
                    position: Tween(
                      begin: const Offset(0, 0.15),
                      end: Offset.zero,
                    ).animate(anim),
                    child: child,
                  ),
                ),
                child: Text(
                  (currentStep?['text'] as String?) ?? _tool['description'],
                  key: ValueKey(stepIdx),
                  style: GoogleFonts.manrope(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: SentioColors.textPrimary,
                    height: 1.4,
                    letterSpacing: -0.3,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildBreathingCircle(Color color) {
    final config = _breathConfig!;

    return AnimatedBuilder(
      animation: Listenable.merge([_circleSize, _glowController]),
      builder: (_, __) {
        final size = _circleSize.value;
        final glow = _glowController.value;

        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Cycle indicator (premium)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: SentioColors.border),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Ciclo ',
                    style: GoogleFonts.manrope(
                      fontSize: 12,
                      color: SentioColors.textTertiary,
                    ),
                  ),
                  Text(
                    '$_currentCycle',
                    style: GoogleFonts.manrope(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: color,
                    ),
                  ),
                  Text(
                    ' / ${config.totalCycles}',
                    style: GoogleFonts.manrope(
                      fontSize: 12,
                      color: SentioColors.textTertiary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 36),
            // Layered breathing circle with concentric rings
            SizedBox(
              width: 320,
              height: 320,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Outer ring (decorative)
                  Container(
                    width: 320,
                    height: 320,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: color.withValues(alpha: 0.06),
                        width: 1,
                      ),
                    ),
                  ),
                  Container(
                    width: 260,
                    height: 260,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: color.withValues(alpha: 0.08),
                        width: 1,
                      ),
                    ),
                  ),
                  // Animated breathing circle with glow
                  Container(
                    width: size,
                    height: size,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          color.withValues(alpha: 0.3),
                          color.withValues(alpha: 0.1),
                          Colors.transparent,
                        ],
                        stops: const [0.0, 0.7, 1.0],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: color.withValues(alpha: 0.25 + glow * 0.2),
                          blurRadius: 50,
                          spreadRadius: 10,
                        ),
                      ],
                    ),
                  ),
                  // Inner solid circle
                  Container(
                    width: size * 0.45,
                    height: size * 0.45,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          color.withValues(alpha: 0.5),
                          color.withValues(alpha: 0.2),
                        ],
                      ),
                      border: Border.all(
                        color: color.withValues(alpha: 0.6),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: color.withValues(alpha: 0.3 + glow * 0.2),
                          blurRadius: 30,
                          spreadRadius: 4,
                        ),
                      ],
                    ),
                  ),
                  // Phase label + countdown overlay
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 400),
                        transitionBuilder: (child, animation) {
                          return FadeTransition(
                            opacity: animation,
                            child: ScaleTransition(scale: animation, child: child),
                          );
                        },
                        child: Text(
                          _phaseLabel(_currentPhase),
                          key: ValueKey(_currentPhase),
                          style: GoogleFonts.manrope(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            letterSpacing: -0.3,
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 200),
                        transitionBuilder: (child, animation) {
                          return ScaleTransition(scale: animation, child: child);
                        },
                        child: Text(
                          '$_phaseSecondsLeft',
                          key: ValueKey(_phaseSecondsLeft),
                          style: GoogleFonts.manrope(
                            fontSize: 56,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            letterSpacing: -2,
                            height: 1,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  // ══════════════════════════════════════
  // COMPLETED VIEW (premium celebration)
  // ══════════════════════════════════════

  Widget _buildCompletedView() {
    final color = _toolColor;
    return Scaffold(
      backgroundColor: SentioColors.background,
      body: Stack(
        children: [
          _animatedBackground(SentioColors.accent),
          // Confetti effect (custom paint)
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _entryController,
              builder: (context, _) {
                return CustomPaint(
                  painter: _ConfettiPainter(_entryController.value),
                );
              },
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  const Spacer(flex: 2),
                  SlideTransition(
                    position: _entrySlide,
                    child: FadeTransition(
                      opacity: _entryFade,
                      child: Column(
                        children: [
                          // Success icon with strong glow
                          AnimatedBuilder(
                            animation: _glowController,
                            builder: (context, _) {
                              final glow = _glowController.value;
                              return Container(
                                width: 130,
                                height: 130,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: RadialGradient(
                                    colors: [
                                      SentioColors.accent.withValues(alpha: 0.4),
                                      SentioColors.accent.withValues(alpha: 0.1),
                                      Colors.transparent,
                                    ],
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: SentioColors.accent.withValues(alpha: 0.4 + glow * 0.2),
                                      blurRadius: 50 + glow * 20,
                                      spreadRadius: 8,
                                    ),
                                  ],
                                ),
                                child: Center(
                                  child: Container(
                                    width: 76,
                                    height: 76,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      gradient: const LinearGradient(
                                        colors: [SentioColors.accent, Color(0xFF00D4AA)],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                    ),
                                    child: const Icon(
                                      Icons.check_rounded,
                                      color: Colors.black,
                                      size: 44,
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                          const SizedBox(height: 36),
                          Text(
                            'Bien hecho',
                            style: GoogleFonts.manrope(
                              fontSize: 32,
                              fontWeight: FontWeight.w800,
                              color: SentioColors.textPrimary,
                              letterSpacing: -1,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 32),
                            child: Text(
                              'Cada pausa cuenta.\nTu cuerpo y tu mente te lo agradecen.',
                              style: GoogleFonts.manrope(
                                fontSize: 15,
                                fontWeight: FontWeight.w400,
                                color: SentioColors.textSecondary,
                                height: 1.6,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                          const SizedBox(height: 28),
                          // XP earned badge with glow
                          AnimatedBuilder(
                            animation: _glowController,
                            builder: (context, _) {
                              final glow = _glowController.value;
                              return Container(
                                padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      SentioColors.accent.withValues(alpha: 0.2),
                                      SentioColors.accent.withValues(alpha: 0.08),
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius: BorderRadius.circular(28),
                                  border: Border.all(
                                    color: SentioColors.accent.withValues(alpha: 0.4 + glow * 0.2),
                                    width: 1.5,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: SentioColors.accent.withValues(alpha: 0.15 + glow * 0.15),
                                      blurRadius: 16 + glow * 8,
                                      spreadRadius: -2,
                                    ),
                                  ],
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.bolt_rounded, color: SentioColors.accent, size: 20),
                                    const SizedBox(width: 6),
                                    Text(
                                      '+${XpRewards.toolCompleted} XP',
                                      style: GoogleFonts.manrope(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w800,
                                        color: SentioColors.accent,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                  const Spacer(flex: 3),
                  _SpringTap(
                    onTap: () => context.pop(),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [color, color.withValues(alpha: 0.7)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: color.withValues(alpha: 0.3),
                            blurRadius: 20,
                            spreadRadius: -2,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          'Volver',
                          style: GoogleFonts.manrope(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════
// SPRING TAP BUTTON
// ══════════════════════════════════════

class _SpringTap extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;
  const _SpringTap({required this.child, required this.onTap});

  @override
  State<_SpringTap> createState() => _SpringTapState();
}

class _SpringTapState extends State<_SpringTap> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 150));
    _scale = Tween(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _ctrl.forward(),
      onTapUp: (_) { _ctrl.reverse(); widget.onTap(); },
      onTapCancel: () => _ctrl.reverse(),
      child: ScaleTransition(scale: _scale, child: widget.child),
    );
  }
}

// ══════════════════════════════════════
// CONFETTI PAINTER (one-shot on complete)
// ══════════════════════════════════════

class _ConfettiPainter extends CustomPainter {
  final double progress;
  final List<_ConfettiParticle> particles;

  _ConfettiPainter(this.progress)
      : particles = List.generate(40, (i) => _ConfettiParticle(i));

  @override
  void paint(Canvas canvas, Size size) {
    if (progress == 0) return;
    final colors = [
      SentioColors.accent,
      SentioColors.primary,
      const Color(0xFFFFD93D),
      const Color(0xFFFF6B9D),
    ];

    for (final p in particles) {
      final t = (progress + p.delay).clamp(0.0, 1.0);
      if (t <= 0) continue;
      final fall = t * (size.height + 100);
      final x = p.startX * size.width + math.sin(t * math.pi * 2 + p.startX * 10) * 30;
      final y = -20 + fall;

      final paint = Paint()
        ..color = colors[p.colorIdx % colors.length].withValues(alpha: (1 - t).clamp(0.0, 1.0));

      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(t * p.rotSpeed * math.pi * 2);
      canvas.drawRect(
        Rect.fromCenter(center: Offset.zero, width: 6, height: 8),
        paint,
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_ConfettiPainter oldDelegate) => oldDelegate.progress != progress;
}

class _ConfettiParticle {
  final double startX;
  final double delay;
  final double rotSpeed;
  final int colorIdx;

  _ConfettiParticle(int seed)
      : startX = (seed * 37 % 100) / 100,
        delay = -((seed * 13 % 30) / 100),
        rotSpeed = 1.0 + (seed % 5) * 0.3,
        colorIdx = seed;
}
