import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sentio_app/config/theme.dart';
import 'package:url_launcher/url_launcher.dart';

class CrisisScreen extends StatelessWidget {
  const CrisisScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SentioColors.surface,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              // Close button
              Align(
                alignment: Alignment.topRight,
                child: GestureDetector(
                  onTap: () => context.pop(),
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.1),
                    ),
                    child: Icon(
                      Icons.close_rounded,
                      color: Colors.white.withValues(alpha: 0.7),
                      size: 20,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 32),
              // Heart icon
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: SentioColors.error.withValues(alpha: 0.2),
                ),
                child: const Icon(
                  Icons.favorite_rounded,
                  color: SentioColors.error,
                  size: 36,
                ),
              ),
              const SizedBox(height: 28),
              // Main message
              Text(
                'Estás acá y eso importa.',
                style: GoogleFonts.manrope(
                  fontSize: 28,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                'No tenés que resolver nada ahora.\nSolo respirá.',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white.withValues(alpha: 0.7),
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),
              // Options
              _CrisisOption(
                icon: Icons.air_rounded,
                title: 'Respirar ahora',
                subtitle: 'Una pausa guiada de 2 minutos',
                onTap: () {
                  context.pop();
                  context.push('/tool/breathing_calm');
                },
              ),
              const SizedBox(height: 12),
              _CrisisOption(
                icon: Icons.edit_rounded,
                title: 'Escribir lo que siento',
                subtitle: 'Vaciar la mente puede ayudar',
                onTap: () {
                  context.pop();
                  context.push('/journal/new');
                },
              ),
              const SizedBox(height: 12),
              _CrisisOption(
                icon: Icons.chat_bubble_outline_rounded,
                title: 'Hablar con alguien',
                subtitle: 'Tu asistente está acá para escucharte',
                onTap: () {
                  context.pop();
                  context.push('/chat');
                },
              ),
              const SizedBox(height: 24),
              // Professional help
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.1),
                  ),
                ),
                child: Column(
                  children: [
                    Text(
                      'Si sentís que necesitás ayuda profesional, eso también es un acto de fuerza.',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white.withValues(alpha: 0.8),
                        height: 1.4,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    GestureDetector(
                      onTap: () => _showHelplineSheet(context),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.public_rounded,
                              color: Colors.white.withValues(alpha: 0.9),
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Buscar línea de ayuda',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: Colors.white.withValues(alpha: 0.9),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              // Closing message
              Text(
                'A veces la fuerza está en hacer una pausa.',
                style: GoogleFonts.manrope(
                  fontSize: 16,
                  color: Colors.white.withValues(alpha: 0.5),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  void _showHelplineSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: SentioColors.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.85,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (_, scrollCtrl) => _HelplineList(scrollController: scrollCtrl),
      ),
    );
  }
}

// ══════════════════════════════════════
// HELPLINE DATA & SHEET
// ══════════════════════════════════════

class _Helpline {
  final String country;
  final String flag;
  final String number;
  final String organization;
  final String hours;
  final bool is24_7;
  final String? note;
  final List<String> alternates;

  const _Helpline({
    required this.country,
    required this.flag,
    required this.number,
    required this.organization,
    required this.hours,
    required this.is24_7,
    this.note,
    this.alternates = const [],
  });
}

const List<_Helpline> _helplines = [
  _Helpline(
    country: 'Argentina',
    flag: '🇦🇷',
    number: '135',
    organization: 'Centro de Asistencia al Suicida (CAS)',
    hours: '08:00 - 00:00',
    is24_7: false,
    note: 'Gratuito desde CABA y GBA. Resto del país: (011) 5275-1135',
    alternates: ['(011) 5275-1135', '0800-345-1435'],
  ),
  _Helpline(
    country: 'España',
    flag: '🇪🇸',
    number: '024',
    organization: 'Línea 024 — Ministerio de Sanidad',
    hours: '24/7, 365 días',
    is24_7: true,
  ),
  _Helpline(
    country: 'México',
    flag: '🇲🇽',
    number: '800 290 0024',
    organization: 'Línea de la Vida — CONASAMA',
    hours: '24/7',
    is24_7: true,
    note: 'Alternativa: SAPTEL (NGO) 24/7',
    alternates: ['55 5259-8121'],
  ),
  _Helpline(
    country: 'Chile',
    flag: '🇨🇱',
    number: '*4141',
    organization: 'Salud Responde — MINSAL',
    hours: '24/7',
    is24_7: true,
    note: 'Gratuito desde celular y fijo',
  ),
  _Helpline(
    country: 'Colombia',
    flag: '🇨🇴',
    number: '106',
    organization: 'Línea 106 — Bogotá',
    hours: '24/7, 365 días',
    is24_7: true,
    note: '106 cubre Bogotá. Para emergencia nacional: 123',
    alternates: ['123 (emergencia nacional)', 'WhatsApp: 300 754 8933'],
  ),
  _Helpline(
    country: 'Perú',
    flag: '🇵🇪',
    number: '113',
    organization: 'MINSA — Línea 113, opción 5',
    hours: '24/7, 365 días',
    is24_7: true,
    note: 'Marcar 113 y elegir opción 5 (Salud Mental)',
  ),
  _Helpline(
    country: 'Uruguay',
    flag: '🇺🇾',
    number: '0800 0767',
    organization: 'Línea Vida — ASSE / MSP',
    hours: '24/7, 365 días',
    is24_7: true,
    note: 'Desde celular: *0767',
    alternates: ['*0767'],
  ),
  _Helpline(
    country: 'Paraguay',
    flag: '🇵🇾',
    number: '155',
    organization: 'Línea 155 — MSPBS',
    hours: '24/7, 365 días',
    is24_7: true,
    note: 'Gratuita y confidencial',
  ),
  _Helpline(
    country: 'Ecuador',
    flag: '🇪🇨',
    number: '171',
    organization: 'MSP — Línea 171, opción 6',
    hours: '24/7',
    is24_7: true,
    note: 'Marcar 171 y elegir opción 6 (Salud Mental)',
  ),
  _Helpline(
    country: 'Bolivia',
    flag: '🇧🇴',
    number: '800 11 30 40',
    organization: 'Familia Segura — UNICEF / La Paz',
    hours: '06:00 - 24:00',
    is24_7: false,
    note: 'WhatsApp: 77797667',
    alternates: ['77797667 (WhatsApp)'],
  ),
  _Helpline(
    country: 'Venezuela',
    flag: '🇻🇪',
    number: '0212-416-3116',
    organization: 'LAPSI — Federación de Psicólogos',
    hours: 'Vie 08:00 a Mié 08:00',
    is24_7: false,
    alternates: ['0212-416-3118'],
  ),
  _Helpline(
    country: 'República Dominicana',
    flag: '🇩🇴',
    number: '911',
    organization: 'Sistema 9-1-1 con psicólogos certificados',
    hours: '24/7',
    is24_7: true,
    note: 'MSP Salud Mental: 809-544-4223 (lun-vie)',
    alternates: ['809-544-4223', '809-636-3507'],
  ),
  _Helpline(
    country: 'Costa Rica',
    flag: '🇨🇷',
    number: '800 273 7869',
    organization: 'Aquí Estoy — Colegio de Psicología',
    hours: 'Lun-Vie 14:00-22:00, Sáb 09:00-16:00',
    is24_7: false,
    note: 'Fuera de horario: 911',
    alternates: ['911 (emergencia 24/7)'],
  ),
  _Helpline(
    country: 'Panamá',
    flag: '🇵🇦',
    number: '169',
    organization: 'MINSA — Línea 169',
    hours: '24/7',
    is24_7: true,
    note: 'Seguir las opciones de voz para Salud Mental',
    alternates: ['512-6800 (INSAM)'],
  ),
  _Helpline(
    country: 'Estados Unidos',
    flag: '🇺🇸',
    number: '988',
    organization: '988 Suicide & Crisis Lifeline',
    hours: '24/7, 365 días',
    is24_7: true,
    note: 'Presionar 2 para español',
  ),
  _Helpline(
    country: 'Brasil',
    flag: '🇧🇷',
    number: '188',
    organization: 'CVV — Centro de Valorização da Vida',
    hours: '24/7',
    is24_7: true,
    note: 'Servicio en portugués',
  ),
];

class _HelplineList extends StatefulWidget {
  final ScrollController scrollController;
  const _HelplineList({required this.scrollController});

  @override
  State<_HelplineList> createState() => _HelplineListState();
}

class _HelplineListState extends State<_HelplineList> {
  String _search = '';

  @override
  Widget build(BuildContext context) {
    final filtered = _search.isEmpty
        ? _helplines
        : _helplines
            .where((h) => h.country.toLowerCase().contains(_search.toLowerCase()))
            .toList();

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
      child: Column(
        children: [
          // Handle
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 18),
          Text(
            'Líneas de ayuda',
            style: GoogleFonts.manrope(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Elegí tu país para ver el número',
            style: GoogleFonts.manrope(
              fontSize: 13,
              color: Colors.white.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 16),
          // Search
          Container(
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
            ),
            child: TextField(
              onChanged: (v) => setState(() => _search = v),
              style: GoogleFonts.manrope(color: Colors.white, fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Buscar país...',
                hintStyle: GoogleFonts.manrope(
                  color: Colors.white.withValues(alpha: 0.4),
                  fontSize: 14,
                ),
                prefixIcon: Icon(
                  Icons.search_rounded,
                  color: Colors.white.withValues(alpha: 0.4),
                  size: 18,
                ),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
          const SizedBox(height: 12),
          // List
          Expanded(
            child: filtered.isEmpty
                ? Center(
                    child: Text(
                      'Sin resultados',
                      style: GoogleFonts.manrope(
                        color: Colors.white.withValues(alpha: 0.4),
                      ),
                    ),
                  )
                : ListView.separated(
                    controller: widget.scrollController,
                    physics: const BouncingScrollPhysics(),
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (_, i) => _HelplineCard(helpline: filtered[i]),
                  ),
          ),
        ],
      ),
    );
  }
}

class _HelplineCard extends StatelessWidget {
  final _Helpline helpline;
  const _HelplineCard({required this.helpline});

  Future<void> _call() async {
    // Strip non-digit chars except leading * and +
    final clean = helpline.number.replaceAll(RegExp(r'[^\d*+]'), '');
    final uri = Uri.parse('tel:$clean');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _call,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(helpline.flag, style: const TextStyle(fontSize: 22)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          helpline.country,
                          style: GoogleFonts.manrope(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      if (helpline.is24_7)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: SentioColors.accent.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '24/7',
                            style: GoogleFonts.manrope(
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                              color: SentioColors.accent,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    helpline.organization,
                    style: GoogleFonts.manrope(
                      fontSize: 11,
                      color: Colors.white.withValues(alpha: 0.5),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(
                        Icons.phone_rounded,
                        size: 13,
                        color: SentioColors.accent,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        helpline.number,
                        style: GoogleFonts.manrope(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: SentioColors.accent,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        Icons.access_time_rounded,
                        size: 11,
                        color: Colors.white.withValues(alpha: 0.4),
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          helpline.hours,
                          style: GoogleFonts.manrope(
                            fontSize: 11,
                            color: Colors.white.withValues(alpha: 0.5),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  if (helpline.note != null) ...[
                    const SizedBox(height: 6),
                    Text(
                      helpline.note!,
                      style: GoogleFonts.manrope(
                        fontSize: 11,
                        color: Colors.white.withValues(alpha: 0.45),
                        fontStyle: FontStyle.italic,
                        height: 1.3,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CrisisOption extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _CrisisOption({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.1),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: Colors.white, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.white.withValues(alpha: 0.5),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              size: 14,
              color: Colors.white.withValues(alpha: 0.4),
            ),
          ],
        ),
      ),
    );
  }
}
