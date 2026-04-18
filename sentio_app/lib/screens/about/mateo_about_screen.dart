import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sentio_app/config/theme.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

// ══════════════════════════════════════
// CONTENT MODEL (with fallback defaults)
// ══════════════════════════════════════

class _AboutContent {
  final String name;
  final String subtitle;
  final String creatorLabel;
  final String quote;
  final String whoIsTitle;
  final List<String> whoIsParagraphs;
  final String missionTitle;
  final String missionIntro;
  final List<_Item> missionItems;
  final String methodTitle;
  final String methodIntro;
  final List<_Item> methodSteps;
  final String whyTitle;
  final List<String> whyParagraphs;
  final String ctaLabel;
  final String ctaUrl;
  final String footer;

  const _AboutContent({
    required this.name,
    required this.subtitle,
    required this.creatorLabel,
    required this.quote,
    required this.whoIsTitle,
    required this.whoIsParagraphs,
    required this.missionTitle,
    required this.missionIntro,
    required this.missionItems,
    required this.methodTitle,
    required this.methodIntro,
    required this.methodSteps,
    required this.whyTitle,
    required this.whyParagraphs,
    required this.ctaLabel,
    required this.ctaUrl,
    required this.footer,
  });

  static _AboutContent fromJson(Map<String, dynamic> j) {
    List<String> strList(dynamic raw) =>
        (raw as List?)?.map((e) => e.toString()).toList() ?? const [];
    List<_Item> itemList(dynamic raw) =>
        (raw as List?)?.map((e) => _Item(
              title: (e['title'] ?? '').toString(),
              description: (e['description'] ?? '').toString(),
            )).toList() ?? const [];

    return _AboutContent(
      name: (j['name'] ?? _defaults.name).toString(),
      subtitle: (j['subtitle'] ?? _defaults.subtitle).toString(),
      creatorLabel: (j['creator_label'] ?? _defaults.creatorLabel).toString(),
      quote: (j['quote'] ?? _defaults.quote).toString(),
      whoIsTitle: (j['who_is_title'] ?? _defaults.whoIsTitle).toString(),
      whoIsParagraphs: strList(j['who_is_paragraphs']).isEmpty
          ? _defaults.whoIsParagraphs
          : strList(j['who_is_paragraphs']),
      missionTitle: (j['mission_title'] ?? _defaults.missionTitle).toString(),
      missionIntro: (j['mission_intro'] ?? _defaults.missionIntro).toString(),
      missionItems: itemList(j['mission_items']).isEmpty
          ? _defaults.missionItems
          : itemList(j['mission_items']),
      methodTitle: (j['method_title'] ?? _defaults.methodTitle).toString(),
      methodIntro: (j['method_intro'] ?? _defaults.methodIntro).toString(),
      methodSteps: itemList(j['method_steps']).isEmpty
          ? _defaults.methodSteps
          : itemList(j['method_steps']),
      whyTitle: (j['why_title'] ?? _defaults.whyTitle).toString(),
      whyParagraphs: strList(j['why_paragraphs']).isEmpty
          ? _defaults.whyParagraphs
          : strList(j['why_paragraphs']),
      ctaLabel: (j['cta_label'] ?? _defaults.ctaLabel).toString(),
      ctaUrl: (j['cta_url'] ?? _defaults.ctaUrl).toString(),
      footer: (j['footer'] ?? _defaults.footer).toString(),
    );
  }

  static const _defaults = _AboutContent(
    name: 'Mateo Silvera',
    subtitle: 'Psicólogo clínico · Emprendedor',
    creatorLabel: 'Creador de',
    quote:
        'Transformar el aislamiento y el agotamiento de la vida fundadora en claridad, confianza y crecimiento sostenible.',
    whoIsTitle: 'Quién es',
    whoIsParagraphs: [
      'Mateo Silvera es psicólogo clínico y emprendedor. Fundó B2Better, una plataforma de mentoría especializada en líderes empresariales, combinando profundidad clínica con experiencia práctica en negocios.',
      'Habiendo construido negocios él mismo, entiende los desafíos que enfrentan los fundadores desde adentro — no desde un libro. Su enfoque une herramientas psicológicas con estrategia empresarial real.',
    ],
    missionTitle: 'La misión de B2Better',
    missionIntro:
        'B2Better ayuda a los fundadores a resolver los tres problemas más silenciosos del emprendimiento:',
    missionItems: [
      _Item(title: 'Confusión sobre prioridades', description: 'Saber qué mover primero cuando todo parece urgente.'),
      _Item(title: 'Aislamiento emocional', description: 'Tener un espacio real donde bajar la guardia y pensar en voz alta.'),
      _Item(title: 'Riesgo de burnout', description: 'Sostener el crecimiento sin romperte en el camino.'),
    ],
    methodTitle: 'El método: Sistema KOYNOS',
    methodIntro:
        'Un marco de 4 etapas diseñado para transformar el burnout en claridad, balance y rendimiento sostenible.',
    methodSteps: [
      _Item(title: 'Diagnóstico psicológico', description: 'Entender cómo tu mente está respondiendo a la presión actual.'),
      _Item(title: 'Desarrollo de desempeño', description: 'Construir las capacidades que tu rol te exige hoy.'),
      _Item(title: 'Sistemas sostenibles', description: 'Estructuras que te permitan crecer sin agotarte.'),
      _Item(title: 'Reconexión con propósito', description: 'Volver a recordar por qué estás haciendo lo que hacés.'),
    ],
    whyTitle: 'Por qué existe esta app',
    whyParagraphs: [
      'B2Better nació como programa de mentoría. Esta app es la extensión natural: llevar las herramientas que usan los fundadores en consultoría a un espacio que podés llevar en el bolsillo, todos los días, cuando no estás en una sesión.',
      'No es un reemplazo de la consultoría profesional — es el compañero diario que te ayuda a mantener lo que trabajás en sesión.',
    ],
    ctaLabel: 'Visitar mateosilvera.com',
    ctaUrl: 'https://mateosilvera.com',
    footer: '© 2026 B2Better · Mateo Silvera',
  );
}

class _Item {
  final String title;
  final String description;
  const _Item({required this.title, required this.description});
}

// ══════════════════════════════════════
// SCREEN
// ══════════════════════════════════════

class MateoAboutScreen extends StatefulWidget {
  const MateoAboutScreen({super.key});

  @override
  State<MateoAboutScreen> createState() => _MateoAboutScreenState();
}

class _MateoAboutScreenState extends State<MateoAboutScreen> {
  _AboutContent _content = _AboutContent._defaults;
  bool _loading = true;

  static const _missionIcons = [
    Icons.my_location_rounded,
    Icons.group_outlined,
    Icons.local_fire_department_rounded,
  ];
  static const _missionColors = [
    SentioColors.primary,
    SentioColors.accent,
    Color(0xFFFF6B9D),
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final data = await Supabase.instance.client
          .from('about_content')
          .select('content')
          .maybeSingle();
      if (data != null && data['content'] != null) {
        setState(() {
          _content = _AboutContent.fromJson(data['content'] as Map<String, dynamic>);
          _loading = false;
        });
        return;
      }
    } catch (_) {}
    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        backgroundColor: SentioColors.background,
        body: Center(child: CircularProgressIndicator(color: SentioColors.accent)),
      );
    }

    final c = _content;

    return Scaffold(
      backgroundColor: SentioColors.background,
      body: Stack(
        children: [
          // Mesh gradient background
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: MediaQuery.of(context).size.height * 0.65,
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.asset(
                  'assets/images/mesh_gradient.png',
                  fit: BoxFit.cover,
                  alignment: Alignment.topCenter,
                ),
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          SentioColors.background.withValues(alpha: 0.6),
                          SentioColors.background,
                        ],
                        stops: const [0.0, 0.75, 1.0],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                  child: Row(
                    children: [_GlassBackButton(onTap: () => context.pop())],
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(0, 24, 0, 40),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildHero(c),
                        const SizedBox(height: 40),
                        _buildLogoSection(c.creatorLabel),
                        const SizedBox(height: 36),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _QuoteCard(c.quote),
                              const SizedBox(height: 32),
                              _SectionTitle(c.whoIsTitle),
                              const SizedBox(height: 10),
                              for (int i = 0; i < c.whoIsParagraphs.length; i++) ...[
                                _Paragraph(c.whoIsParagraphs[i]),
                                if (i < c.whoIsParagraphs.length - 1) const SizedBox(height: 12),
                              ],
                              const SizedBox(height: 32),
                              _SectionTitle(c.missionTitle),
                              const SizedBox(height: 10),
                              _Paragraph(c.missionIntro),
                              const SizedBox(height: 16),
                              for (int i = 0; i < c.missionItems.length; i++)
                                _Bullet(
                                  icon: _missionIcons[i % _missionIcons.length],
                                  color: _missionColors[i % _missionColors.length],
                                  title: c.missionItems[i].title,
                                  description: c.missionItems[i].description,
                                ),
                              const SizedBox(height: 32),
                              _SectionTitle(c.methodTitle),
                              const SizedBox(height: 10),
                              _Paragraph(c.methodIntro),
                              const SizedBox(height: 16),
                              for (int i = 0; i < c.methodSteps.length; i++)
                                _Step(i + 1, c.methodSteps[i].title, c.methodSteps[i].description),
                              const SizedBox(height: 32),
                              _SectionTitle(c.whyTitle),
                              const SizedBox(height: 10),
                              for (int i = 0; i < c.whyParagraphs.length; i++) ...[
                                _Paragraph(c.whyParagraphs[i]),
                                if (i < c.whyParagraphs.length - 1) const SizedBox(height: 12),
                              ],
                              const SizedBox(height: 36),
                              _SpringTap(
                                onTap: () => launchUrl(
                                  Uri.parse(c.ctaUrl),
                                  mode: LaunchMode.externalApplication,
                                ),
                                child: Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [SentioColors.primary, SentioColors.primaryLight],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    borderRadius: BorderRadius.circular(16),
                                    boxShadow: [
                                      BoxShadow(
                                        color: SentioColors.primary.withValues(alpha: 0.35),
                                        blurRadius: 20,
                                        spreadRadius: -2,
                                        offset: const Offset(0, 6),
                                      ),
                                    ],
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(Icons.public_rounded, color: Colors.white, size: 18),
                                      const SizedBox(width: 8),
                                      Text(
                                        c.ctaLabel,
                                        style: GoogleFonts.manrope(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w800,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),
                              Center(
                                child: Text(
                                  c.footer,
                                  style: GoogleFonts.manrope(
                                    fontSize: 11,
                                    color: SentioColors.textTertiary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHero(_AboutContent c) {
    return SizedBox(
      width: double.infinity,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 180,
              height: 180,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: SentioColors.primary.withValues(alpha: 0.3),
                    blurRadius: 40,
                    spreadRadius: 6,
                  ),
                ],
              ),
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [SentioColors.primary, SentioColors.accent],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                padding: const EdgeInsets.all(3),
                child: ClipOval(
                  child: Container(
                    color: SentioColors.background,
                    padding: const EdgeInsets.all(2),
                    child: ClipOval(
                      child: Image.asset(
                        'assets/images/mateo_photo.jpg',
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          color: SentioColors.surface,
                          child: const Center(
                            child: Icon(Icons.person, size: 80, color: SentioColors.textTertiary),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              c.name,
              style: GoogleFonts.manrope(
                fontSize: 30,
                fontWeight: FontWeight.w800,
                color: Colors.white,
                letterSpacing: -1,
                shadows: const [
                  Shadow(color: Colors.black54, blurRadius: 16, offset: Offset(0, 2)),
                ],
              ),
            ),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
              ),
              child: Text(
                c.subtitle,
                style: GoogleFonts.manrope(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.white.withValues(alpha: 0.9),
                  letterSpacing: 0.3,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLogoSection(String creatorLabel) {
    return Center(
      child: Column(
        children: [
          Text(
            creatorLabel,
            style: GoogleFonts.manrope(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: SentioColors.textTertiary,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  SentioColors.surface.withValues(alpha: 0.6),
                  SentioColors.surface.withValues(alpha: 0.3),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
            ),
            child: SvgPicture.asset(
              'assets/images/b2better_logo_white.svg',
              height: 36,
              colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
            ),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════
// HELPER WIDGETS
// ══════════════════════════════════════

class _GlassBackButton extends StatelessWidget {
  final VoidCallback onTap;
  const _GlassBackButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
            ),
            child: const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 20),
          ),
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);
  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: GoogleFonts.manrope(
        fontSize: 18,
        fontWeight: FontWeight.w800,
        color: SentioColors.textPrimary,
        letterSpacing: -0.3,
      ),
    );
  }
}

class _Paragraph extends StatelessWidget {
  final String text;
  const _Paragraph(this.text);
  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: GoogleFonts.manrope(
        fontSize: 14,
        color: SentioColors.textSecondary,
        height: 1.6,
      ),
    );
  }
}

class _QuoteCard extends StatelessWidget {
  final String text;
  const _QuoteCard(this.text);
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            SentioColors.primary.withValues(alpha: 0.1),
            SentioColors.accent.withValues(alpha: 0.06),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: SentioColors.primary.withValues(alpha: 0.15)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.format_quote_rounded, color: SentioColors.primary.withValues(alpha: 0.6), size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.manrope(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: SentioColors.textPrimary,
                height: 1.5,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Bullet extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String description;
  const _Bullet({
    required this.icon,
    required this.color,
    required this.title,
    required this.description,
  });
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: SentioColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: SentioColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: GoogleFonts.manrope(
                  fontSize: 14, fontWeight: FontWeight.w700, color: SentioColors.textPrimary,
                )),
                const SizedBox(height: 2),
                Text(description, style: GoogleFonts.manrope(
                  fontSize: 12, color: SentioColors.textSecondary, height: 1.4,
                )),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Step extends StatelessWidget {
  final int number;
  final String title;
  final String description;
  const _Step(this.number, this.title, this.description);
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: SentioColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: SentioColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [SentioColors.primary, SentioColors.primaryLight],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text('$number', style: GoogleFonts.manrope(
                fontSize: 16, fontWeight: FontWeight.w800, color: Colors.white,
              )),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: GoogleFonts.manrope(
                  fontSize: 14, fontWeight: FontWeight.w700, color: SentioColors.textPrimary,
                )),
                const SizedBox(height: 2),
                Text(description, style: GoogleFonts.manrope(
                  fontSize: 12, color: SentioColors.textSecondary, height: 1.4,
                )),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SpringTap extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;
  const _SpringTap({required this.child, required this.onTap});
  @override
  State<_SpringTap> createState() => _SpringTapState();
}

class _SpringTapState extends State<_SpringTap> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;
  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 150));
    _scale = Tween(begin: 1.0, end: 0.96).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }
  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _ctrl.forward(),
      onTapUp: (_) { _ctrl.reverse(); widget.onTap(); },
      onTapCancel: () => _ctrl.reverse(),
      child: ScaleTransition(scale: _scale, child: widget.child),
    );
  }
}
