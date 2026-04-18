import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:sentio_app/config/theme.dart';
import 'package:sentio_app/config/constants.dart';
import 'package:sentio_app/providers/app_provider.dart';

class JournalScreen extends StatelessWidget {
  const JournalScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final entries = provider.journalEntries;

    return Scaffold(
      backgroundColor: SentioColors.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Tu diario',
                        style: GoogleFonts.manrope(
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          color: SentioColors.textPrimary,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        entries.isEmpty
                            ? 'Un espacio para vos'
                            : '${entries.length} ${entries.length == 1 ? 'entrada' : 'entradas'}',
                        style: GoogleFonts.manrope(
                          fontSize: 14,
                          color: SentioColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  GestureDetector(
                    onTap: () => context.push('/journal/new'),
                    child: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            SentioColors.primary,
                            SentioColors.primary.withValues(alpha: 0.8),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: SentioEffects.glow(
                          SentioColors.primary,
                          blur: 12,
                          opacity: 0.3,
                        ),
                      ),
                      child: const Icon(
                        Icons.add_rounded,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Entries
            Expanded(
              child: entries.isEmpty
                  ? _buildEmptyState(context)
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(24, 0, 24, 100),
                      itemCount: entries.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final entry = entries[index];
                        final emotion = entry.dominantEmotion != null
                            ? SentioConstants.emotions.firstWhere(
                                (e) => e['id'] == entry.dominantEmotion,
                                orElse: () => SentioConstants.emotions.first,
                              )
                            : null;
                        final emotionColor = emotion != null
                            ? Color(emotion['color'] as int)
                            : null;

                        return GestureDetector(
                          onTap: () => context.push('/journal/${entry.id}'),
                          child: Container(
                            padding: const EdgeInsets.all(18),
                            decoration: BoxDecoration(
                              color: SentioColors.surface,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: SentioColors.border),
                              boxShadow: emotionColor != null
                                  ? [
                                      BoxShadow(
                                        color: emotionColor
                                            .withValues(alpha: 0.08),
                                        blurRadius: 12,
                                        offset: const Offset(0, 4),
                                      ),
                                    ]
                                  : null,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    if (emotion != null) ...[
                                      Container(
                                        width: 36,
                                        height: 36,
                                        decoration: BoxDecoration(
                                          color: emotionColor!
                                              .withValues(alpha: 0.12),
                                          borderRadius:
                                              BorderRadius.circular(10),
                                        ),
                                        child: Center(
                                          child: Icon(
                                            SentioConstants.getEmotionIcon(emotion['id']),
                                            color: emotionColor,
                                            size: 18,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                    ],
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            DateFormat('EEEE d \'de\' MMMM',
                                                    'es')
                                                .format(entry.createdAt),
                                            style: GoogleFonts.manrope(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w600,
                                              color: SentioColors.textPrimary,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            '${DateFormat('HH:mm').format(entry.createdAt)} · ${entry.wordCount} palabras',
                                            style: GoogleFonts.manrope(
                                              fontSize: 12,
                                              color: SentioColors.textTertiary,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Icon(
                                      Icons.chevron_right_rounded,
                                      color: SentioColors.textTertiary,
                                      size: 20,
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 14),
                                // Content preview
                                Text(
                                  entry.content,
                                  maxLines: 3,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.manrope(
                                    fontSize: 14,
                                    height: 1.6,
                                    color: SentioColors.textSecondary,
                                    fontWeight: FontWeight.w400,
                                  ),
                                ),
                                // Tags
                                if (entry.tags.isNotEmpty) ...[
                                  const SizedBox(height: 12),
                                  Wrap(
                                    spacing: 6,
                                    runSpacing: 6,
                                    children: entry.tags.map((tag) {
                                      return Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 10, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: SentioColors.primary
                                              .withValues(alpha: 0.08),
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                        child: Text(
                                          tag,
                                          style: GoogleFonts.manrope(
                                            fontSize: 12,
                                            color: SentioColors.primary,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      );
                                    }).toList(),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(48),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [
                    SentioColors.primary.withValues(alpha: 0.12),
                    SentioColors.accent.withValues(alpha: 0.08),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: const Icon(
                Icons.edit_note_rounded,
                size: 40,
                color: SentioColors.accent,
              ),
            ),
            const SizedBox(height: 28),
            Text(
              'Tu diario está en blanco,\ncomo una página nueva.',
              style: GoogleFonts.manrope(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                height: 1.4,
                color: SentioColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Text(
              'Escribí lo que necesites.\nNo tiene que ser perfecto.',
              style: GoogleFonts.manrope(
                fontSize: 14,
                color: SentioColors.textSecondary,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 28),
            GestureDetector(
              onTap: () => context.push('/journal/new'),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      SentioColors.primary,
                      SentioColors.primary.withValues(alpha: 0.8),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: SentioEffects.glow(
                    SentioColors.primary,
                    blur: 16,
                    opacity: 0.3,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.edit_rounded, size: 18, color: Colors.white),
                    const SizedBox(width: 8),
                    Text(
                      'Empezar a escribir',
                      style: GoogleFonts.manrope(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
