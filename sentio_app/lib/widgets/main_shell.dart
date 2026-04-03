import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sentio_app/config/theme.dart';

class MainShell extends StatelessWidget {
  final Widget child;

  const MainShell({super.key, required this.child});

  int _currentIndex(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;
    if (location == '/') return 0;
    if (location.startsWith('/journal')) return 1;
    if (location.startsWith('/community')) return 2;
    if (location.startsWith('/finance')) return 3;
    if (location.startsWith('/profile')) return 4;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final index = _currentIndex(context);

    return Scaffold(
      body: child,
      extendBody: true,
      bottomNavigationBar: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Container(
            decoration: BoxDecoration(
              color: SentioColors.background.withOpacity(0.8),
              border: Border(
                top: BorderSide(color: SentioColors.border),
              ),
            ),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _NavItem(
                      icon: Icons.dashboard_outlined,
                      activeIcon: Icons.dashboard_rounded,
                      label: 'Panel',
                      isActive: index == 0,
                      onTap: () => context.go('/'),
                    ),
                    _NavItem(
                      icon: Icons.edit_note_rounded,
                      activeIcon: Icons.edit_note_rounded,
                      label: 'Escribir',
                      isActive: index == 1,
                      onTap: () => context.go('/journal'),
                    ),
                    _NavItem(
                      icon: Icons.people_outline_rounded,
                      activeIcon: Icons.people_rounded,
                      label: 'Comunidad',
                      isActive: index == 2,
                      onTap: () => context.go('/community'),
                    ),
                    _NavItem(
                      icon: Icons.account_balance_wallet_outlined,
                      activeIcon: Icons.account_balance_wallet_rounded,
                      label: 'Finanzas',
                      isActive: index == 3,
                      onTap: () => context.go('/finance'),
                    ),
                    _NavItem(
                      icon: Icons.person_outline_rounded,
                      activeIcon: Icons.person_rounded,
                      label: 'Perfil',
                      isActive: index == 4,
                      onTap: () => context.go('/profile'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
      // Crisis FAB
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 48),
        child: Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: SentioEffects.glow(SentioColors.error, blur: 12, opacity: 0.4),
          ),
          child: FloatingActionButton.small(
            onPressed: () => context.push('/crisis'),
            backgroundColor: SentioColors.error.withOpacity(0.9),
            elevation: 0,
            tooltip: 'Necesito apoyo',
            child: const Icon(Icons.favorite_rounded, color: Colors.white, size: 20),
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 64,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.all(6),
              decoration: isActive
                  ? BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    )
                  : null,
              child: Icon(
                isActive ? activeIcon : icon,
                color: isActive ? SentioColors.primary : SentioColors.textSecondary,
                size: 24,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: GoogleFonts.manrope(
                fontSize: 10,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                color: isActive ? SentioColors.primary : SentioColors.textSecondary,
                letterSpacing: 0.15,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
