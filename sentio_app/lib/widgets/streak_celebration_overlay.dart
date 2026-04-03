import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sentio_app/config/theme.dart';

class StreakCelebrationOverlay extends StatefulWidget {
  final int streakCount;
  final VoidCallback onDismiss;

  const StreakCelebrationOverlay({
    super.key,
    required this.streakCount,
    required this.onDismiss,
  });

  @override
  State<StreakCelebrationOverlay> createState() => _StreakCelebrationOverlayState();
}

class _StreakCelebrationOverlayState extends State<StreakCelebrationOverlay>
    with SingleTickerProviderStateMixin {
  late ConfettiController _confettiController;
  late AnimationController _scaleController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(duration: const Duration(seconds: 3));
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.elasticOut),
    );
    _confettiController.play();
    _scaleController.forward();
    HapticFeedback.heavyImpact();
  }

  @override
  void dispose() {
    _confettiController.dispose();
    _scaleController.dispose();
    super.dispose();
  }

  String _getMilestoneMessage(int streak) {
    if (streak >= 100) return 'Cien días. Leyenda.';
    if (streak >= 60) return 'Dos meses. Sos imparable.';
    if (streak >= 30) return 'Un mes completo.\nEsto es resiliencia real.';
    if (streak >= 14) return 'Dos semanas sin parar.\nEstás construyendo un hábito.';
    if (streak >= 7) return 'Una semana de constancia.\nTu mente te lo agradece.';
    return '¡Increíble racha!';
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withValues(alpha: 0.7),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Confetti
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirectionality: BlastDirectionality.explosive,
              colors: const [
                SentioColors.accent,
                SentioColors.primary,
                SentioColors.emotionMotivated,
                SentioColors.emotionGrateful,
              ],
              numberOfParticles: 30,
              gravity: 0.2,
              emissionFrequency: 0.05,
            ),
          ),
          // Content
          ScaleTransition(
            scale: _scaleAnimation,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: SentioColors.accent.withValues(alpha: 0.2),
                    boxShadow: SentioEffects.glow(SentioColors.accent, blur: 30, opacity: 0.6),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.local_fire_department_rounded,
                      color: SentioColors.accent,
                      size: 52,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  '${widget.streakCount} días!',
                  style: GoogleFonts.manrope(
                    fontSize: 40,
                    fontWeight: FontWeight.w800,
                    color: SentioColors.accent,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  child: Text(
                    _getMilestoneMessage(widget.streakCount),
                    style: GoogleFonts.manrope(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: SentioColors.textSecondary,
                      height: 1.4,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 32),
                GestureDetector(
                  onTap: widget.onDismiss,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                    decoration: BoxDecoration(
                      color: SentioColors.accent,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: SentioEffects.glow(SentioColors.accent, blur: 12, opacity: 0.4),
                    ),
                    child: Text(
                      'Seguir',
                      style: GoogleFonts.manrope(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: SentioColors.background,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
