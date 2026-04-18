import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:sentio_app/config/theme.dart';
import 'package:sentio_app/providers/app_provider.dart';

class ValidationScreen extends StatefulWidget {
  const ValidationScreen({super.key});

  @override
  State<ValidationScreen> createState() => _ValidationScreenState();
}

class _ValidationScreenState extends State<ValidationScreen> {
  int _step = 0; // 0=intro, 1=choose path, 2=url, 3=answer
  final _urlController = TextEditingController();
  final _answerController = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    _urlController.dispose();
    _answerController.dispose();
    super.dispose();
  }

  Future<void> _submit({String? url, String? answer}) async {
    setState(() => _submitting = true);
    final ok = await context.read<AppProvider>().submitCommunityValidation(
          url: url,
          answer: answer,
        );
    if (!mounted) return;
    setState(() => _submitting = false);
    if (ok) {
      HapticFeedback.mediumImpact();
      // Go back to community — it will now show status screen
      context.pop();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No se pudo enviar. Reintentá.', style: GoogleFonts.manrope()),
          backgroundColor: SentioColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SentioColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: Row(
                children: [
                  if (_step > 0)
                    GestureDetector(
                      onTap: () => setState(() => _step = _step == 1 ? 0 : 1),
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: SentioColors.border),
                        ),
                        child: const Icon(Icons.arrow_back_rounded, color: SentioColors.textPrimary, size: 20),
                      ),
                    )
                  else
                    GestureDetector(
                      onTap: () => context.pop(),
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: SentioColors.border),
                        ),
                        child: const Icon(Icons.close_rounded, color: SentioColors.textPrimary, size: 20),
                      ),
                    ),
                ],
              ),
            ),
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 280),
                child: KeyedSubtree(
                  key: ValueKey(_step),
                  child: _buildStep(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStep() {
    switch (_step) {
      case 0: return _buildIntro();
      case 1: return _buildChoosePath();
      case 2: return _buildUrlForm();
      case 3: return _buildAnswerForm();
      default: return _buildIntro();
    }
  }

  // ── Step 0: Intro ──
  Widget _buildIntro() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 20),
          Center(
            child: Container(
              width: 100, height: 100,
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  colors: [
                    SentioColors.primary.withValues(alpha: 0.3),
                    SentioColors.primary.withValues(alpha: 0.05),
                    Colors.transparent,
                  ],
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: SentioColors.primary.withValues(alpha: 0.3),
                    blurRadius: 40,
                    spreadRadius: 4,
                  ),
                ],
              ),
              child: const Icon(Icons.workspace_premium_rounded, color: SentioColors.primary, size: 48),
            ),
          ),
          const SizedBox(height: 28),
          Text(
            'Comunidad cerrada',
            textAlign: TextAlign.center,
            style: GoogleFonts.manrope(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: SentioColors.textPrimary,
              letterSpacing: -0.8,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'B2Better es un espacio para emprendedores, freelancers y profesionales independientes que están construyendo algo real.',
            textAlign: TextAlign.center,
            style: GoogleFonts.manrope(
              fontSize: 14,
              color: SentioColors.textSecondary,
              height: 1.6,
            ),
          ),
          const SizedBox(height: 32),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  SentioColors.surface,
                  SentioColors.accent.withValues(alpha: 0.04),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: SentioColors.accent.withValues(alpha: 0.15)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.verified_rounded, color: SentioColors.accent, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      'Qué esperamos',
                      style: GoogleFonts.manrope(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: SentioColors.accent,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                _Bullet('Que puedas describir qué estás construyendo'),
                _Bullet('Que tengas un problema concreto que resolver'),
                _Bullet('Que ya hayas tomado alguna acción (hablado con clientes, lanzado un MVP, etc.)'),
              ],
            ),
          ),
          const SizedBox(height: 28),
          ElevatedButton(
            onPressed: () => setState(() => _step = 1),
            child: Text('Empezar validación', style: GoogleFonts.manrope(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  // ── Step 1: Choose path ──
  Widget _buildChoosePath() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '¿Cómo querés validar tu perfil?',
            style: GoogleFonts.manrope(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: SentioColors.textPrimary,
              letterSpacing: -0.5,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Elegí una opción. La primera es aprobación instantánea.',
            style: GoogleFonts.manrope(fontSize: 14, color: SentioColors.textSecondary),
          ),
          const SizedBox(height: 28),
          _PathCard(
            icon: Icons.link_rounded,
            color: SentioColors.accent,
            badge: 'INSTANTÁNEO',
            title: 'Tengo una web o red social',
            description: 'Compartí el link a tu web o perfil de IG/LinkedIn dedicado a tu negocio y accedés automáticamente.',
            onTap: () => setState(() => _step = 2),
          ),
          const SizedBox(height: 12),
          _PathCard(
            icon: Icons.chat_bubble_outline_rounded,
            color: SentioColors.primary,
            badge: 'MENOS DE 24H',
            title: 'Contame en qué estoy trabajando',
            description: 'Respondé unas preguntas cortas y nuestro equipo valida tu perfil en menos de 24 horas.',
            onTap: () => setState(() => _step = 3),
          ),
        ],
      ),
    );
  }

  // ── Step 2: URL form ──
  Widget _buildUrlForm() {
    final isValid = _urlController.text.trim().isNotEmpty && _urlController.text.contains('.');
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Tu web o red social',
            style: GoogleFonts.manrope(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: SentioColors.textPrimary,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Pegá el link a tu sitio web o perfil profesional. Debe estar dedicado principalmente a tu negocio.',
            style: GoogleFonts.manrope(fontSize: 14, color: SentioColors.textSecondary, height: 1.5),
          ),
          const SizedBox(height: 24),
          TextField(
            controller: _urlController,
            keyboardType: TextInputType.url,
            autofocus: true,
            onChanged: (_) => setState(() {}),
            style: GoogleFonts.manrope(fontSize: 14, color: SentioColors.textPrimary),
            decoration: InputDecoration(
              hintText: 'https://tuweb.com  o  instagram.com/tunegocio',
              hintStyle: GoogleFonts.manrope(color: SentioColors.textTertiary, fontSize: 13),
              prefixIcon: Icon(Icons.link_rounded, color: SentioColors.accent, size: 20),
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: SentioColors.accent.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: SentioColors.accent.withValues(alpha: 0.15)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.flash_on_rounded, color: SentioColors.accent, size: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Acceso instantáneo. Al enviar el link, accedés a la comunidad inmediatamente.',
                    style: GoogleFonts.manrope(
                      fontSize: 12,
                      color: SentioColors.accent,
                      fontWeight: FontWeight.w600,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),
          ElevatedButton(
            onPressed: (isValid && !_submitting) ? () => _submit(url: _urlController.text.trim()) : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: SentioColors.accent,
              foregroundColor: Colors.black,
            ),
            child: _submitting
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                : Text('Enviar y acceder', style: GoogleFonts.manrope(fontWeight: FontWeight.w800, color: Colors.black)),
          ),
        ],
      ),
    );
  }

  // ── Step 3: Answer form ──
  Widget _buildAnswerForm() {
    final charCount = _answerController.text.trim().length;
    final isValid = charCount >= 60;
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Contanos qué estás haciendo',
            style: GoogleFonts.manrope(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: SentioColors.textPrimary,
              letterSpacing: -0.5,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: SentioColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: SentioColors.border),
            ),
            child: Text(
              '¿Qué estás construyendo o qué servicio ofrecés, para quién, y cuál es el mayor desafío que estás enfrentando hoy en tu negocio?',
              style: GoogleFonts.manrope(
                fontSize: 14,
                fontStyle: FontStyle.italic,
                color: SentioColors.textPrimary,
                height: 1.5,
              ),
            ),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _answerController,
            autofocus: true,
            maxLines: 6,
            textCapitalization: TextCapitalization.sentences,
            onChanged: (_) => setState(() {}),
            style: GoogleFonts.manrope(fontSize: 14, color: SentioColors.textPrimary, height: 1.5),
            decoration: InputDecoration(
              hintText: 'Ej: Tengo una agencia de diseño con 3 clientes fijos. Mi problema hoy es cómo pasar de vender tiempo a vender proyectos...',
              hintStyle: GoogleFonts.manrope(color: SentioColors.textTertiary, fontSize: 13, height: 1.5),
            ),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text(
                '$charCount / 60 caracteres mínimo',
                style: GoogleFonts.manrope(
                  fontSize: 11,
                  color: isValid ? SentioColors.accent : SentioColors.textTertiary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: SentioColors.primary.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: SentioColors.primary.withValues(alpha: 0.15)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline_rounded, color: SentioColors.primary, size: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Nuestro equipo revisa tu respuesta en menos de 24 horas. Te avisaremos cuando esté aprobada.',
                    style: GoogleFonts.manrope(
                      fontSize: 12,
                      color: SentioColors.primary,
                      fontWeight: FontWeight.w600,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),
          ElevatedButton(
            onPressed: (isValid && !_submitting) ? () => _submit(answer: _answerController.text.trim()) : null,
            child: _submitting
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : Text('Enviar para revisión', style: GoogleFonts.manrope(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}

// ── Helper widgets ──

class _PathCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String badge;
  final String title;
  final String description;
  final VoidCallback onTap;

  const _PathCard({
    required this.icon,
    required this.color,
    required this.badge,
    required this.title,
    required this.description,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [SentioColors.surface, color.withValues(alpha: 0.04)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(icon, color: color, size: 22),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    badge,
                    style: GoogleFonts.manrope(
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      color: color == SentioColors.accent ? Colors.black : Colors.white,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: GoogleFonts.manrope(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: SentioColors.textPrimary,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              description,
              style: GoogleFonts.manrope(
                fontSize: 13,
                color: SentioColors.textSecondary,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Bullet extends StatelessWidget {
  final String text;
  const _Bullet(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Container(
              width: 5,
              height: 5,
              decoration: const BoxDecoration(
                color: SentioColors.accent,
                shape: BoxShape.circle,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.manrope(
                fontSize: 13,
                color: SentioColors.textPrimary,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
