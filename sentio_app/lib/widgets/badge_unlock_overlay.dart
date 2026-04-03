import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sentio_app/config/theme.dart';
import 'package:sentio_app/models/gamification.dart';

class BadgeUnlockOverlay extends StatefulWidget {
  final Achievement achievement;
  final VoidCallback onDismiss;

  const BadgeUnlockOverlay({
    super.key,
    required this.achievement,
    required this.onDismiss,
  });

  @override
  State<BadgeUnlockOverlay> createState() => _BadgeUnlockOverlayState();
}

class _BadgeUnlockOverlayState extends State<BadgeUnlockOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  static const _iconMap = <String, IconData>{
    'check_circle': Icons.check_circle_rounded,
    'edit_note': Icons.edit_note_rounded,
    'local_fire_department': Icons.local_fire_department_rounded,
    'self_improvement': Icons.self_improvement_rounded,
    'chat': Icons.chat_rounded,
    'people': Icons.people_rounded,
    'psychology': Icons.psychology_rounded,
    'military_tech': Icons.military_tech_rounded,
    'spa': Icons.spa_rounded,
    'shield': Icons.shield_rounded,
    'star': Icons.star_rounded,
  };

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
    HapticFeedback.mediumImpact();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final icon = _iconMap[widget.achievement.iconName] ?? Icons.emoji_events_rounded;

    return Material(
      color: Colors.black.withValues(alpha: 0.75),
      child: Center(
        child: ScaleTransition(
          scale: _scaleAnimation,
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 40),
            padding: const EdgeInsets.all(32),
            decoration: SentioEffects.gradientCard(glowColor: SentioColors.accent),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Badge icon
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [
                        SentioColors.primary.withValues(alpha: 0.3),
                        SentioColors.accent.withValues(alpha: 0.3),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: SentioEffects.glow(SentioColors.accent, blur: 16, opacity: 0.5),
                  ),
                  child: Icon(icon, color: SentioColors.accent, size: 36),
                ),
                const SizedBox(height: 20),
                Text(
                  '¡Logro Desbloqueado!',
                  style: GoogleFonts.manrope(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: SentioColors.accent,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  widget.achievement.name,
                  style: GoogleFonts.manrope(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: SentioColors.textPrimary,
                    letterSpacing: -0.3,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                Text(
                  widget.achievement.description,
                  style: GoogleFonts.manrope(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: SentioColors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                GestureDetector(
                  onTap: widget.onDismiss,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      color: SentioColors.accent,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Center(
                      child: Text(
                        'Genial',
                        style: GoogleFonts.manrope(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: SentioColors.background,
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
