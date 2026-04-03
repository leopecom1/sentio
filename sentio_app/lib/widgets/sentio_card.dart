import 'package:flutter/material.dart';
import 'package:sentio_app/config/theme.dart';

class SentioCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final Color? color;
  final Color? glowColor;

  const SentioCard({
    super.key,
    required this.child,
    this.padding,
    this.color,
    this.glowColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding ?? const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color ?? SentioColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: SentioColors.border),
        boxShadow: glowColor != null
            ? SentioEffects.glow(glowColor!)
            : null,
      ),
      child: child,
    );
  }
}

class SentioGradientCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final Color? glowColor;

  const SentioGradientCard({
    super.key,
    required this.child,
    this.padding,
    this.glowColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding ?? const EdgeInsets.all(20),
      clipBehavior: Clip.antiAlias,
      decoration: SentioEffects.gradientCard(glowColor: glowColor),
      child: child,
    );
  }
}

class SentioGlowCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final Color glowColor;

  const SentioGlowCard({
    super.key,
    required this.child,
    this.padding,
    required this.glowColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding ?? const EdgeInsets.all(20),
      decoration: SentioEffects.glowCard(glowColor: glowColor),
      child: child,
    );
  }
}
