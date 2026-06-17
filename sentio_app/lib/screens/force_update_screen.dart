import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:sentio_app/config/theme.dart';
import 'package:sentio_app/providers/app_provider.dart';

/// Pantalla bloqueante de actualización obligatoria.
/// No se puede cerrar ni navegar hacia atrás: el usuario debe actualizar.
class ForceUpdateScreen extends StatelessWidget {
  const ForceUpdateScreen({super.key});

  Future<void> _openStore(BuildContext context, String? url) async {
    if (url == null || url.isEmpty) return;
    final uri = Uri.parse(url);
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo abrir la tienda.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final storeUrl = context.select<AppProvider, String?>((p) => p.forceUpdateStoreUrl);

    // Bloquea el botón "atrás" del sistema: no hay forma de salir sin actualizar.
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: SentioColors.background,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 110,
                    height: 110,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(colors: [
                        SentioColors.primary.withValues(alpha: 0.22),
                        SentioColors.primary.withValues(alpha: 0.06),
                        Colors.transparent,
                      ]),
                    ),
                    child: const Icon(Icons.system_update_rounded,
                        size: 52, color: SentioColors.primary),
                  ),
                ),
                const SizedBox(height: 32),
                Text(
                  'Actualización necesaria',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.manrope(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    color: SentioColors.textPrimary,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  'Lanzamos una versión nueva de B2Better con mejoras importantes. '
                  'Para seguir usando la app necesitás actualizar a la última versión.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.manrope(
                    fontSize: 15,
                    color: SentioColors.textSecondary,
                    height: 1.6,
                  ),
                ),
                const SizedBox(height: 36),
                ElevatedButton(
                  onPressed: () => _openStore(context, storeUrl),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Text(
                      'Actualizar ahora',
                      style: GoogleFonts.manrope(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
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
