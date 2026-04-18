import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sentio_app/config/theme.dart';
import 'package:sentio_app/providers/app_provider.dart';

class PendingApprovalScreen extends StatelessWidget {
  const PendingApprovalScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appProvider = context.watch<AppProvider>();
    final profile = appProvider.profile;

    return Scaffold(
      backgroundColor: SentioColors.background,
      body: Stack(
        children: [
          // Background gradient orbs
          Positioned(
            top: -100,
            right: -80,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    SentioColors.accent.withOpacity(0.3),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: -120,
            left: -80,
            child: Container(
              width: 280,
              height: 280,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    SentioColors.primary.withOpacity(0.3),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 60, sigmaY: 60),
            child: Container(color: Colors.black.withOpacity(0.2)),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  const Spacer(),
                  Container(
                    width: 110,
                    height: 110,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [
                          SentioColors.accent.withOpacity(0.2),
                          SentioColors.primary.withOpacity(0.2),
                        ],
                      ),
                      border: Border.all(
                        color: SentioColors.accent.withOpacity(0.4),
                        width: 2,
                      ),
                    ),
                    child: const Icon(
                      Icons.hourglass_top_rounded,
                      color: SentioColors.accent,
                      size: 50,
                    ),
                  ),
                  const SizedBox(height: 32),
                  const Text(
                    'Cuenta en revisión',
                    style: TextStyle(
                      color: SentioColors.textPrimary,
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Hola ${profile?.firstName ?? ''}, recibimos tu registro. Nuestro equipo está revisando tu cuenta manualmente para mantener la calidad de la comunidad B2Better.',
                    style: const TextStyle(
                      color: SentioColors.textSecondary,
                      fontSize: 15,
                      height: 1.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: SentioColors.border),
                    ),
                    child: Column(
                      children: [
                        _InfoRow(
                          icon: Icons.mark_email_read_rounded,
                          text: profile?.email ?? 'Tu email registrado',
                        ),
                        const SizedBox(height: 14),
                        const _InfoRow(
                          icon: Icons.schedule_rounded,
                          text: 'Tiempo estimado: 24-48 hs',
                        ),
                        const SizedBox(height: 14),
                        const _InfoRow(
                          icon: Icons.notifications_active_rounded,
                          text: 'Te avisaremos por email al aprobarte',
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () async {
                            await appProvider.refreshProfile();
                            if (!context.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  appProvider.isApproved
                                      ? '¡Cuenta aprobada!'
                                      : 'Aún en revisión, te avisaremos pronto',
                                ),
                                backgroundColor: appProvider.isApproved
                                    ? SentioColors.success
                                    : SentioColors.surface,
                              ),
                            );
                          },
                          style: OutlinedButton.styleFrom(
                            foregroundColor: SentioColors.textPrimary,
                            side: BorderSide(color: SentioColors.border),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          icon: const Icon(Icons.refresh_rounded, size: 18),
                          label: const Text('Revisar estado'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => appProvider.signOut(),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: SentioColors.surface,
                            foregroundColor: SentioColors.textPrimary,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          icon: const Icon(Icons.logout_rounded, size: 18),
                          label: const Text('Cerrar sesión'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;
  const _InfoRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: SentioColors.accent, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              color: SentioColors.textPrimary,
              fontSize: 14,
            ),
          ),
        ),
      ],
    );
  }
}
