import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: SentioColors.background,
      body: Stack(
        children: [
          // Main content (extends to bottom, floating nav covers it)
          Positioned.fill(child: child),

          // Floating bottom navigation (Liquid Glass)
          Positioned(
            left: 16,
            right: 16,
            bottom: bottomPadding > 0 ? bottomPadding : 16,
            child: _FloatingNavBar(currentIndex: index),
          ),

          // Crisis FAB (floats above the nav bar)
          Positioned(
            right: 20,
            bottom: bottomPadding + 90,
            child: _CrisisButton(onTap: () => context.push('/crisis')),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════
// FLOATING NAV BAR (Liquid Glass)
// ══════════════════════════════════════

class _FloatingNavBar extends StatelessWidget {
  final int currentIndex;
  const _FloatingNavBar({required this.currentIndex});

  static const _items = [
    _NavItemData(icon: Icons.dashboard_outlined, activeIcon: Icons.dashboard_rounded, label: 'Panel', path: '/'),
    _NavItemData(icon: Icons.edit_note_outlined, activeIcon: Icons.edit_note_rounded, label: 'Escribir', path: '/journal'),
    _NavItemData(icon: Icons.people_outline_rounded, activeIcon: Icons.people_rounded, label: 'Comunidad', path: '/community'),
    _NavItemData(icon: Icons.account_balance_wallet_outlined, activeIcon: Icons.account_balance_wallet_rounded, label: 'Finanzas', path: '/finance'),
    _NavItemData(icon: Icons.person_outline_rounded, activeIcon: Icons.person_rounded, label: 'Perfil', path: '/profile'),
  ];

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                SentioColors.surface.withValues(alpha: 0.55),
                SentioColors.surface.withValues(alpha: 0.75),
              ],
            ),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.1),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.35),
                blurRadius: 30,
                spreadRadius: -6,
                offset: const Offset(0, 10),
              ),
              BoxShadow(
                color: SentioColors.primary.withValues(alpha: 0.08),
                blurRadius: 24,
                spreadRadius: -2,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(_items.length, (i) {
                final item = _items[i];
                return _NavButton(
                  data: item,
                  isActive: currentIndex == i,
                  onTap: () => context.go(item.path),
                );
              }),
            ),
          ),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════
// NAV BUTTON (pill-shaped, animated)
// ══════════════════════════════════════

class _NavButton extends StatelessWidget {
  final _NavItemData data;
  final bool isActive;
  final VoidCallback onTap;

  const _NavButton({
    required this.data,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final activeColor = SentioColors.accent;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          HapticFeedback.lightImpact();
          onTap();
        },
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 260),
          curve: Curves.easeOutCubic,
          margin: const EdgeInsets.symmetric(horizontal: 2),
          padding: const EdgeInsets.symmetric(vertical: 6),
          decoration: BoxDecoration(
            gradient: isActive
                ? LinearGradient(
                    colors: [
                      activeColor.withValues(alpha: 0.22),
                      activeColor.withValues(alpha: 0.08),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  )
                : null,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isActive ? activeColor.withValues(alpha: 0.35) : Colors.transparent,
              width: 1,
            ),
            boxShadow: isActive
                ? [
                    BoxShadow(
                      color: activeColor.withValues(alpha: 0.25),
                      blurRadius: 14,
                      spreadRadius: -2,
                    ),
                  ]
                : null,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Small top dot indicator when active
              AnimatedContainer(
                duration: const Duration(milliseconds: 260),
                curve: Curves.easeOutCubic,
                width: isActive ? 16 : 0,
                height: 2,
                margin: EdgeInsets.only(bottom: isActive ? 4 : 0),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      activeColor,
                      activeColor.withValues(alpha: 0.5),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(1),
                  boxShadow: isActive
                      ? [
                          BoxShadow(
                            color: activeColor.withValues(alpha: 0.6),
                            blurRadius: 6,
                          ),
                        ]
                      : null,
                ),
              ),
              AnimatedScale(
                duration: const Duration(milliseconds: 260),
                curve: Curves.easeOutBack,
                scale: isActive ? 1.1 : 1.0,
                child: Icon(
                  isActive ? data.activeIcon : data.icon,
                  color: isActive ? activeColor : SentioColors.textSecondary,
                  size: 22,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                data.label,
                style: GoogleFonts.manrope(
                  fontSize: 9.5,
                  fontWeight: isActive ? FontWeight.w800 : FontWeight.w500,
                  color: isActive ? activeColor : SentioColors.textSecondary,
                  letterSpacing: 0.1,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItemData {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final String path;
  const _NavItemData({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.path,
  });
}

// ══════════════════════════════════════
// CRISIS BUTTON (floating above nav)
// ══════════════════════════════════════

class _CrisisButton extends StatefulWidget {
  final VoidCallback onTap;
  const _CrisisButton({required this.onTap});

  @override
  State<_CrisisButton> createState() => _CrisisButtonState();
}

class _CrisisButtonState extends State<_CrisisButton> with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, _) {
        final glow = _pulseController.value;
        return GestureDetector(
          onTap: () {
            HapticFeedback.mediumImpact();
            widget.onTap();
          },
          child: Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [
                  SentioColors.error,
                  SentioColors.error.withValues(alpha: 0.8),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: SentioColors.error.withValues(alpha: 0.4 + glow * 0.2),
                  blurRadius: 16 + glow * 8,
                  spreadRadius: 0,
                ),
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
              border: Border.all(color: Colors.white.withValues(alpha: 0.2), width: 1),
            ),
            child: const Icon(
              Icons.favorite_rounded,
              color: Colors.white,
              size: 20,
            ),
          ),
        );
      },
    );
  }
}
