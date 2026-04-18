import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sentio_app/config/legal_content.dart';
import 'package:sentio_app/config/theme.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

enum LegalDocType { terms, privacy }

class LegalScreen extends StatefulWidget {
  final LegalDocType type;

  const LegalScreen({super.key, required this.type});

  @override
  State<LegalScreen> createState() => _LegalScreenState();
}

class _LegalScreenState extends State<LegalScreen> {
  List<LegalSection>? _sections;
  String? _version;
  String? _lastUpdated;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadFromServer();
  }

  Future<void> _loadFromServer() async {
    final docType = widget.type == LegalDocType.terms ? 'terms' : 'privacy';
    try {
      final data = await Supabase.instance.client
          .from('legal_documents')
          .select()
          .eq('doc_type', docType)
          .maybeSingle();

      if (data != null && data['sections'] != null) {
        final rawSections = data['sections'] as List;
        setState(() {
          _sections = rawSections.map((s) =>
            LegalSection(title: s['title'] ?? '', body: s['body'] ?? '')
          ).toList();
          _version = data['version'];
          _lastUpdated = data['last_updated'];
          _loading = false;
        });
        return;
      }
    } catch (_) {
      // Fallback to local content
    }
    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final isTerms = widget.type == LegalDocType.terms;
    final sections = _sections ?? (isTerms ? LegalContent.terms : LegalContent.privacy);
    final version = _version ?? LegalContent.version;
    final lastUpdated = _lastUpdated ?? LegalContent.lastUpdated;
    final title = isTerms ? 'Términos y Condiciones' : 'Política de Privacidad';
    final subtitle = isTerms
        ? 'Reglas para usar B2Better'
        : 'Cómo cuidamos tu información';
    final icon = isTerms ? Icons.gavel_rounded : Icons.shield_rounded;

    if (_loading) {
      return Scaffold(
        backgroundColor: SentioColors.background,
        body: const Center(child: CircularProgressIndicator(color: SentioColors.accent)),
      );
    }

    return Scaffold(
      backgroundColor: SentioColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Row(
                children: [
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
                      child: const Icon(
                        Icons.arrow_back_rounded,
                        color: SentioColors.textPrimary,
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            SentioColors.primary.withValues(alpha: 0.2),
                            SentioColors.accent.withValues(alpha: 0.1),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(icon, color: SentioColors.accent, size: 28),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      title,
                      style: GoogleFonts.manrope(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: SentioColors.textPrimary,
                        letterSpacing: -0.8,
                        height: 1.1,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      subtitle,
                      style: GoogleFonts.manrope(
                        fontSize: 14,
                        color: SentioColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: SentioColors.surface,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: SentioColors.border),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.update_rounded,
                            size: 14,
                            color: SentioColors.textTertiary,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Actualizado: $lastUpdated',
                            style: GoogleFonts.manrope(
                              fontSize: 12,
                              color: SentioColors.textTertiary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            width: 1,
                            height: 12,
                            color: SentioColors.divider,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'v$version',
                            style: GoogleFonts.manrope(
                              fontSize: 12,
                              color: SentioColors.textTertiary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 28),
                    // Sections
                    ...sections.map((s) => _buildSection(s)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(LegalSection section) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            section.title,
            style: GoogleFonts.manrope(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: SentioColors.textPrimary,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            section.body,
            style: GoogleFonts.manrope(
              fontSize: 14,
              color: SentioColors.textSecondary,
              height: 1.6,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }
}
