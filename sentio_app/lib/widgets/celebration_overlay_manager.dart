import 'package:flutter/material.dart';
import 'package:sentio_app/providers/app_provider.dart';
import 'package:sentio_app/widgets/floating_xp_widget.dart';
import 'package:sentio_app/widgets/streak_celebration_overlay.dart';
import 'package:sentio_app/widgets/level_up_modal.dart';
import 'package:sentio_app/widgets/badge_unlock_overlay.dart';

class CelebrationOverlayManager extends StatelessWidget {
  final AppProvider provider;

  const CelebrationOverlayManager({super.key, required this.provider});

  @override
  Widget build(BuildContext context) {
    if (provider.pendingCelebrations.isEmpty) return const SizedBox.shrink();

    final celebration = provider.pendingCelebrations.first;

    switch (celebration.event) {
      case CelebrationEvent.xpGained:
        return FloatingXpWidget(
          xpAmount: celebration.xpAmount ?? 0,
          onComplete: () => provider.consumeCelebration(),
        );
      case CelebrationEvent.streakMilestone:
        return StreakCelebrationOverlay(
          streakCount: celebration.streakCount ?? 0,
          onDismiss: () => provider.consumeCelebration(),
        );
      case CelebrationEvent.levelUp:
        return LevelUpModal(
          newLevel: celebration.newLevel!,
          onDismiss: () => provider.consumeCelebration(),
        );
      case CelebrationEvent.achievementUnlocked:
        return BadgeUnlockOverlay(
          achievement: celebration.achievement!,
          onDismiss: () => provider.consumeCelebration(),
        );
    }
  }
}
