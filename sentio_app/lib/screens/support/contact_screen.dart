import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sentio_app/config/theme.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

/// Pantalla de contacto / ayuda (#5).
/// Canales: WhatsApp y email. Los datos salen de `app_config`
/// (support_whatsapp, support_email) para poder cambiarlos sin recompilar.
class ContactScreen extends StatefulWidget {
  const ContactScreen({super.key});

  @override
  State<ContactScreen> createState() => _ContactScreenState();
}

class _ContactScreenState extends State<ContactScreen> {
  String _whatsapp = '';
  String _email = 'hola@b2better.app';
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadConfig();
  }

  Future<void> _loadConfig() async {
    try {
      final rows = await Supabase.instance.client
          .from('app_config')
          .select('key, value')
          .inFilter('key', ['support_whatsapp', 'support_email']);
      for (final r in rows as List) {
        final v = (r['value'] as String?)?.trim() ?? '';
        if (r['key'] == 'support_whatsapp') _whatsapp = v;
        if (r['key'] == 'support_email' && v.isNotEmpty) _email = v;
      }
    } catch (_) {/* usamos defaults */}
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _openWhatsApp() async {
    final digits = _whatsapp.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isEmpty) return;
    final uri = Uri.parse(
        'https://wa.me/$digits?text=${Uri.encodeComponent('Hola, necesito ayuda con B2Better.')}');
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Future<void> _openEmail() async {
    final uri = Uri(
      scheme: 'mailto',
      path: _email,
      query: 'subject=${Uri.encodeComponent('Ayuda con B2Better')}',
    );
    await launchUrl(uri);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SentioColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: SentioColors.textPrimary),
          onPressed: () => context.pop(),
        ),
        title: Text('Ayuda y contacto',
            style: GoogleFonts.manrope(
                fontSize: 18, fontWeight: FontWeight.w700, color: SentioColors.textPrimary)),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('¿Necesitás una mano?',
                  style: GoogleFonts.manrope(
                      fontSize: 22, fontWeight: FontWeight.w800, color: SentioColors.textPrimary)),
              const SizedBox(height: 8),
              Text(
                  'Escribinos y te respondemos a la brevedad. Estamos para ayudarte con cualquier duda o problema.',
                  style: GoogleFonts.manrope(
                      fontSize: 15, height: 1.5, color: SentioColors.textSecondary)),
              const SizedBox(height: 28),
              if (_loading)
                const Center(child: Padding(
                    padding: EdgeInsets.only(top: 40), child: CircularProgressIndicator()))
              else ...[
                if (_whatsapp.trim().isNotEmpty)
                  _ContactCard(
                    icon: Icons.chat_rounded,
                    color: const Color(0xFF25D366),
                    title: 'WhatsApp',
                    subtitle: 'Chateá con nosotros directo',
                    onTap: _openWhatsApp,
                  ),
                if (_whatsapp.trim().isNotEmpty) const SizedBox(height: 12),
                _ContactCard(
                  icon: Icons.mail_rounded,
                  color: SentioColors.primary,
                  title: 'Email',
                  subtitle: _email,
                  onTap: _openEmail,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _ContactCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  const _ContactCard({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: SentioColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: SentioColors.divider),
        ),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: GoogleFonts.manrope(
                          fontSize: 15, fontWeight: FontWeight.w700, color: SentioColors.textPrimary)),
                  const SizedBox(height: 2),
                  Text(subtitle,
                      style: GoogleFonts.manrope(fontSize: 13, color: SentioColors.textSecondary)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: SentioColors.textTertiary),
          ],
        ),
      ),
    );
  }
}
