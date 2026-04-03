import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sentio_app/config/theme.dart';
import 'package:sentio_app/models/gamification.dart';

class LevelUpModal extends StatefulWidget {
  final ResilienceLevel newLevel;
  final VoidCallback onDismiss;

  const LevelUpModal({
    super.key,
    required this.newLevel,
    required this.onDismiss,
  });

  @override
  State<LevelUpModal> createState() => _LevelUpModalState();
}

class _LevelUpModalState extends State<LevelUpModal>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.elasticOut),
    );
    _controller.forward();
    HapticFeedback.heavyImpact();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withValues(alpha: 0.75),
      child: Center(
        child: ScaleTransition(
          scale: _scaleAnimation,
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 40),
            padding: const EdgeInsets.all(32),
            decoration: SentioEffects.gradientCard(glowColor: SentioColors.primary),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Shield with level number
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      colors: [SentioColors.primary, SentioColors.accent],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: SentioEffects.glow(SentioColors.primary, blur: 20, opacity: 0.6),
                  ),
                  child: Center(
                    child: Text(
                      '${widget.newLevel.level}',
                      style: GoogleFonts.manrope(
                        fontSize: 36,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  '¡Nuevo Nivel!',
                  style: GoogleFonts.manrope(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: SentioColors.accent,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  widget.newLevel.title,
                  style: GoogleFonts.manrope(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: SentioColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 24),
                GestureDetector(
                  onTap: widget.onDismiss,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      color: SentioColors.primary,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: SentioEffects.glow(SentioColors.primary, blur: 10, opacity: 0.4),
                    ),
                    child: Center(
                      child: Text(
                        'Continuar',
                        style: GoogleFonts.manrope(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
