import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sentio_app/config/theme.dart';

class BlurHeader extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final VoidCallback? onBack;
  final Widget? trailing;
  final Widget? leading;
  final bool showBorder;

  const BlurHeader({
    super.key,
    required this.title,
    this.onBack,
    this.trailing,
    this.leading,
    this.showBorder = true,
  });

  @override
  Size get preferredSize => const Size.fromHeight(56);

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          decoration: BoxDecoration(
            color: SentioColors.background.withOpacity(0.85),
            border: showBorder
                ? Border(bottom: BorderSide(color: SentioColors.border))
                : null,
          ),
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  if (onBack != null)
                    _CircleButton(
                      icon: Icons.arrow_back,
                      onTap: onBack!,
                    )
                  else if (leading != null)
                    leading!
                  else
                    const SizedBox(width: 40),
                  Expanded(
                    child: Text(
                      title,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.manrope(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: SentioColors.textPrimary,
                        letterSpacing: -0.3,
                      ),
                    ),
                  ),
                  if (trailing != null)
                    trailing!
                  else
                    const SizedBox(width: 40),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class CircleIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const CircleIconButton({
    super.key,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return _CircleButton(icon: icon, onTap: onTap);
  }
}

class _CircleButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _CircleButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: SentioColors.surface,
          shape: BoxShape.circle,
          border: Border.all(color: SentioColors.border),
        ),
        child: Icon(icon, color: SentioColors.textPrimary, size: 20),
      ),
    );
  }
}
