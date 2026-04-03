import 'dart:async';
import 'dart:math' as math;

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
      case BreathPhase.inhale:
        return inhale;
      case BreathPhase.holdIn:
        return holdIn;
      case BreathPhase.exhale:
        return exhale;
      case BreathPhase.holdOut:
        return holdOut;
    }
  }

  BreathPhase? nextPhase(BreathPhase current) {
    switch (current) {
      case BreathPhase.inhale:
        return holdIn > 0 ? BreathPhase.holdIn : BreathPhase.exhale;
      case BreathPhase.holdIn:
        return BreathPhase.exhale;
      case BreathPhase.exhale:
        return holdOut > 0 ? BreathPhase.holdOut : null; // null = cycle end
      case BreathPhase.holdOut:
        return null; // cycle end
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

  // Breathing circle animation
  late AnimationController _circleController;
  late Animation<double> _circleSize;

  // Glow pulse animation
  late AnimationController _glowController;
  late Animation<double> _glowOpacity;

  @override
  void initState() {
    super.initState();
    _tool = SentioConstants.tools.firstWhere(
      (t) => t['id'] == widget.toolId,
      orElse: () => SentioConstants.tools.first,
    );
    _remainingSeconds = _tool['durationSeconds'] as int;

    // Parse breathing config
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
    _circleSize = Tween(begin: 100.0, end: 220.0).animate(
      CurvedAnimation(parent: _circleController, curve: Curves.easeInOut),
    );

    _glowController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);
    _glowOpacity = Tween(begin: 0.3, end: 0.7).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _phaseTimer?.cancel();
    _circleController.dispose();
    _glowController.dispose();
    super.dispose();
  }

  // ── Start ──

  void _start() {
    setState(() => _started = true);
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

  // ── Breathing phase machine ──

  void _startBreathingPhase(BreathPhase phase) {
    final config = _breathConfig!;
    final duration = config.durationOf(phase);

    setState(() {
      _currentPhase = phase;
      _phaseSecondsLeft = duration;
    });

    HapticFeedback.lightImpact();

    // Animate circle based on phase
    _circleController.stop();
    _circleController.duration = Duration(seconds: duration);

    switch (phase) {
      case BreathPhase.inhale:
        _circleController.forward(from: 0.0);
        break;
      case BreathPhase.holdIn:
        _circleController.value = 1.0; // keep expanded
        break;
      case BreathPhase.exhale:
        _circleController.reverse(from: 1.0);
        break;
      case BreathPhase.holdOut:
        _circleController.value = 0.0; // keep contracted
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
      // Cycle complete
      if (_currentCycle >= config.totalCycles) {
        _complete();
      } else {
        setState(() => _currentCycle++);
        _startBreathingPhase(BreathPhase.inhale);
      }
    }
  }

  // ── Complete ──

  void _complete() {
    _timer?.cancel();
    _phaseTimer?.cancel();
    _circleController.stop();
    HapticFeedback.mediumImpact();
    setState(() => _completed = true);

    // Save tool usage + award XP
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
      case BreathPhase.inhale:
        return 'Inhala';
      case BreathPhase.holdIn:
        return 'Mantené';
      case BreathPhase.exhale:
        return 'Exhala';
      case BreathPhase.holdOut:
        return 'Pausa';
    }
  }

  String _formatTime(int seconds) {
    final min = seconds ~/ 60;
    final sec = seconds % 60;
    return '${min.toString().padLeft(2, '0')}:${sec.toString().padLeft(2, '0')}';
  }

  // ── Build ──

  @override
  Widget build(BuildContext context) {
    if (_completed) return _buildCompletedView();
    if (_started) return _buildActiveView();
    return _buildStartView();
  }

  // ── Start view ──

  Widget _buildStartView() {
    final color = _isBreathing ? SentioColors.accent : SentioColors.primary;

    return Scaffold(
      backgroundColor: SentioColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Row(
                children: [
                  GestureDetector(
                    onTap: () => context.pop(),
                    child: const Icon(Icons.arrow_back_rounded),
                  ),
                ],
              ),
              const Spacer(flex: 2),
              // Icon
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: color.withValues(alpha: 0.12),
                ),
                child: Icon(
                  _isBreathing ? Icons.air_rounded : Icons.self_improvement_rounded,
                  color: color,
                  size: 48,
                ),
              ),
              const SizedBox(height: 32),
              Text(
                _tool['title'],
                style: GoogleFonts.manrope(
                  fontSize: 28,
                  color: SentioColors.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                _tool['description'],
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: SentioColors.textSecondary,
                    ),
                textAlign: TextAlign.center,
              ),
              if (_isBreathing && _breathConfig != null) ...[
                const SizedBox(height: 16),
                _buildPatternChips(),
              ],
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _tool['duration'],
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: color),
                ),
              ),
              const Spacer(flex: 3),
              ElevatedButton(
                onPressed: _start,
                style: ElevatedButton.styleFrom(backgroundColor: color),
                child: const Text('Empezar'),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPatternChips() {
    final config = _breathConfig!;
    final phases = <MapEntry<String, int>>[
      MapEntry('Inhala', config.inhale),
      if (config.holdIn > 0) MapEntry('Mantené', config.holdIn),
      MapEntry('Exhala', config.exhale),
      if (config.holdOut > 0) MapEntry('Pausa', config.holdOut),
    ];

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: phases.map((e) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: SentioColors.accent.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '${e.key} ${e.value}s',
              style: GoogleFonts.manrope(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: SentioColors.accent,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  // ── Active view ──

  Widget _buildActiveView() {
    final color = _isBreathing ? SentioColors.accent : SentioColors.primary;
    final totalSeconds = _tool['durationSeconds'] as int;
    final progress = 1 - (_remainingSeconds / totalSeconds);

    return Scaffold(
      backgroundColor: SentioColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap: () {
                      _timer?.cancel();
                      _phaseTimer?.cancel();
                      _circleController.stop();
                      context.pop();
                    },
                    child: const Icon(Icons.close_rounded, color: SentioColors.textTertiary),
                  ),
                  Text(
                    _formatTime(_remainingSeconds),
                    style: GoogleFonts.manrope(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: SentioColors.textSecondary,
                    ),
                  ),
                ],
              ),
              const Spacer(flex: 2),
              // Breathing circle or non-breathing content
              if (_isBreathing && _breathConfig != null)
                _buildBreathingCircle(color)
              else ...[
                Container(
                  width: 160,
                  height: 160,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: color.withValues(alpha: 0.08),
                  ),
                  child: Icon(Icons.self_improvement_rounded, color: color, size: 64),
                ),
                const SizedBox(height: 32),
                Text(
                  _tool['description'],
                  style: GoogleFonts.manrope(
                    fontSize: 22,
                    color: SentioColors.textPrimary,
                    height: 1.4,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
              const Spacer(flex: 3),
              // Progress bar
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: progress,
                  backgroundColor: color.withValues(alpha: 0.1),
                  valueColor: AlwaysStoppedAnimation(color),
                  minHeight: 4,
                ),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: _complete,
                child: Text(
                  'Terminar antes',
                  style: TextStyle(color: SentioColors.textTertiary),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBreathingCircle(Color color) {
    final config = _breathConfig!;

    return AnimatedBuilder(
      animation: Listenable.merge([_circleSize, _glowOpacity]),
      builder: (_, __) {
        final size = _circleSize.value;
        final glow = _glowOpacity.value;

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Cycle counter
            Text(
              'Ciclo ${_currentCycle}/${config.totalCycles}',
              style: GoogleFonts.manrope(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: SentioColors.textTertiary,
              ),
            ),
            const SizedBox(height: 24),
            // Animated circle with glow
            Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    color.withValues(alpha: 0.15),
                    color.withValues(alpha: 0.05),
                    Colors.transparent,
                  ],
                  stops: const [0.0, 0.7, 1.0],
                ),
                boxShadow: [
                  BoxShadow(
                    color: color.withValues(alpha: glow),
                    blurRadius: 40,
                    spreadRadius: 10,
                  ),
                ],
              ),
              child: Center(
                child: Container(
                  width: size * 0.35,
                  height: size * 0.35,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: color.withValues(alpha: 0.25),
                    border: Border.all(
                      color: color.withValues(alpha: 0.5),
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: color.withValues(alpha: glow * 0.5),
                        blurRadius: 20,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 32),
            // Phase label with animated switch
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: Text(
                _phaseLabel(_currentPhase),
                key: ValueKey(_currentPhase),
                style: GoogleFonts.manrope(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
            ),
            const SizedBox(height: 8),
            // Phase countdown
            Text(
              '$_phaseSecondsLeft',
              style: GoogleFonts.manrope(
                fontSize: 48,
                fontWeight: FontWeight.w800,
                color: SentioColors.textPrimary,
                letterSpacing: -1,
              ),
            ),
          ],
        );
      },
    );
  }

  // ── Completed view ──

  Widget _buildCompletedView() {
    return Scaffold(
      backgroundColor: SentioColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(flex: 2),
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: SentioColors.accent.withValues(alpha: 0.15),
                  boxShadow: SentioEffects.glow(SentioColors.accent, blur: 20, opacity: 0.4),
                ),
                child: const Icon(
                  Icons.check_rounded,
                  color: SentioColors.accent,
                  size: 48,
                ),
              ),
              const SizedBox(height: 32),
              Text(
                'Bien hecho',
                style: GoogleFonts.manrope(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: SentioColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Cada pausa cuenta.\nTu cuerpo y tu mente te lo agradecen.',
                style: GoogleFonts.manrope(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: SentioColors.textSecondary,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              // XP earned badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: SentioColors.accent.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: SentioColors.accent.withValues(alpha: 0.3)),
                ),
                child: Text(
                  '+${XpRewards.toolCompleted} XP',
                  style: GoogleFonts.manrope(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: SentioColors.accent,
                  ),
                ),
              ),
              const Spacer(flex: 3),
              ElevatedButton(
                onPressed: () => context.pop(),
                child: const Text('Volver'),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
