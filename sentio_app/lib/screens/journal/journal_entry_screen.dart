import 'dart:math';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:sentio_app/config/theme.dart';
import 'package:sentio_app/config/constants.dart';
import 'package:sentio_app/providers/app_provider.dart';

class JournalEntryScreen extends StatefulWidget {
  final String? entryId;

  const JournalEntryScreen({super.key, this.entryId});

  @override
  State<JournalEntryScreen> createState() => _JournalEntryScreenState();
}

class _JournalEntryScreenState extends State<JournalEntryScreen>
    with SingleTickerProviderStateMixin {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  String? _selectedEmotion;
  late String _prompt;
  bool _showPrompt = true;
  bool _saving = false;
  late AnimationController _promptFade;

  @override
  void initState() {
    super.initState();
    _prompt = SentioConstants
        .journalPrompts[Random().nextInt(SentioConstants.journalPrompts.length)];
    _promptFade = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
      value: 1.0,
    );

    if (widget.entryId != null) {
      _showPrompt = false;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final provider = context.read<AppProvider>();
        final entry = provider.journalEntries
            .where((e) => e.id == widget.entryId)
            .firstOrNull;
        if (entry != null) {
          _controller.text = entry.content;
          _selectedEmotion = entry.dominantEmotion;
          setState(() {});
        }
      });
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _focusNode.requestFocus();
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    _promptFade.dispose();
    super.dispose();
  }

  void _dismissPrompt() {
    _promptFade.reverse().then((_) {
      if (mounted) setState(() => _showPrompt = false);
    });
  }

  Future<void> _save() async {
    if (_controller.text.trim().isEmpty || _saving) return;

    setState(() => _saving = true);
    try {
      final provider = context.read<AppProvider>();
      final success = await provider.saveJournalEntry(
        content: _controller.text.trim(),
        prompt: _showPrompt ? _prompt : null,
        emotion: _selectedEmotion,
      );

      if (!mounted) return;
      if (success) {
        context.pop();
      } else {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('No se pudo guardar. Verificá tu conexión.'),
            backgroundColor: Colors.red.shade700,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al guardar: $e'),
          backgroundColor: Colors.red.shade700,
        ),
      );
    }
  }

  int get _wordCount =>
      _controller.text.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).length;

  @override
  Widget build(BuildContext context) {
    final isNew = widget.entryId == null;
    final now = DateTime.now();

    return Scaffold(
      backgroundColor: SentioColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            _buildHeader(isNew, now),

            // Prompt
            if (_showPrompt && isNew) _buildPromptCard(),

            // Editor
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: TextField(
                  controller: _controller,
                  focusNode: _focusNode,
                  maxLines: null,
                  expands: true,
                  textAlignVertical: TextAlignVertical.top,
                  style: GoogleFonts.manrope(
                    fontSize: 17,
                    height: 1.8,
                    color: SentioColors.textPrimary,
                    fontWeight: FontWeight.w400,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Empezá a escribir lo que sentís...',
                    hintStyle: GoogleFonts.manrope(
                      fontSize: 17,
                      color: SentioColors.textTertiary,
                      fontWeight: FontWeight.w400,
                    ),
                    border: InputBorder.none,
                    filled: false,
                    contentPadding: const EdgeInsets.only(top: 8),
                  ),
                  onChanged: (_) => setState(() {}),
                ),
              ),
            ),

            // Bottom toolbar
            if (isNew) _buildBottomBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(bool isNew, DateTime now) {
    final hasContent = _controller.text.trim().isNotEmpty;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
              ),
              child: const Icon(
                Icons.arrow_back_rounded,
                color: SentioColors.textPrimary,
                size: 20,
              ),
            ),
          ),
          const SizedBox(width: 14),
          // Date + time
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isNew ? 'Nueva entrada' : 'Editando',
                  style: GoogleFonts.manrope(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: SentioColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  DateFormat('EEEE d \'de\' MMMM, HH:mm', 'es').format(now),
                  style: GoogleFonts.manrope(
                    fontSize: 12,
                    color: SentioColors.textTertiary,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
          // Save button
          if (isNew)
            GestureDetector(
              onTap: hasContent ? _save : null,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding:
                    const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                decoration: BoxDecoration(
                  color: hasContent
                      ? SentioColors.primary
                      : SentioColors.primary.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: hasContent
                      ? SentioEffects.glow(SentioColors.primary,
                          blur: 10, opacity: 0.3)
                      : null,
                ),
                child: _saving
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : Text(
                        'Guardar',
                        style: GoogleFonts.manrope(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: hasContent
                              ? Colors.white
                              : Colors.white.withValues(alpha: 0.5),
                        ),
                      ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPromptCard() {
    return FadeTransition(
      opacity: _promptFade,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 12),
        child: GestureDetector(
          onTap: _dismissPrompt,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  SentioColors.primary.withValues(alpha: 0.08),
                  SentioColors.accent.withValues(alpha: 0.05),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: SentioColors.primary.withValues(alpha: 0.12),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: SentioColors.accent.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.lightbulb_outline_rounded,
                    color: SentioColors.accent,
                    size: 16,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _prompt,
                    style: GoogleFonts.manrope(
                      fontSize: 14,
                      color: SentioColors.textSecondary,
                      fontStyle: FontStyle.italic,
                      height: 1.4,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  Icons.close_rounded,
                  size: 16,
                  color: SentioColors.textTertiary,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
      decoration: BoxDecoration(
        color: SentioColors.surface,
        border: Border(
          top: BorderSide(color: SentioColors.border),
        ),
      ),
      child: SafeArea(
        child: Row(
          children: [
            // Emotion selector
            GestureDetector(
              onTap: _showEmotionPicker,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: _selectedEmotion != null
                      ? _emotionColor.withValues(alpha: 0.1)
                      : Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: _selectedEmotion != null
                        ? _emotionColor.withValues(alpha: 0.25)
                        : SentioColors.border,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _selectedEmotion != null
                          ? SentioConstants.getEmotionIcon(_selectedEmotion!)
                          : Icons.mood_rounded,
                      size: 18,
                      color: _selectedEmotion != null
                          ? _emotionColor
                          : SentioColors.textSecondary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _selectedEmotion != null ? _emotionLabel : 'Emoción',
                      style: GoogleFonts.manrope(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: _selectedEmotion != null
                            ? _emotionColor
                            : SentioColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const Spacer(),
            // Word count
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.04),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '$_wordCount palabras',
                style: GoogleFonts.manrope(
                  fontSize: 12,
                  color: SentioColors.textTertiary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Map<String, dynamic> get _emotionData => SentioConstants.emotions.firstWhere(
        (e) => e['id'] == _selectedEmotion,
        orElse: () => SentioConstants.emotions.first,
      );

  Color get _emotionColor => Color(_emotionData['color'] as int);
  String get _emotionEmoji => _emotionData['emoji'] as String;
  String get _emotionLabel => _emotionData['label'] as String;

  void _showEmotionPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: SentioColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      isScrollControlled: true,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: SentioColors.divider,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                '¿Cómo te sentís ahora?',
                style: GoogleFonts.manrope(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: SentioColors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Asociá una emoción a esta entrada',
                style: GoogleFonts.manrope(
                  fontSize: 14,
                  color: SentioColors.textSecondary,
                ),
              ),
              const SizedBox(height: 20),
              Wrap(
              spacing: 8,
              runSpacing: 8,
              children: SentioConstants.emotions.map((emotion) {
                final isSelected = _selectedEmotion == emotion['id'];
                final color = Color(emotion['color'] as int);
                return GestureDetector(
                  onTap: () {
                    setState(() => _selectedEmotion = emotion['id']);
                    Navigator.of(ctx).pop();
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? color.withValues(alpha: 0.15)
                          : Colors.white.withValues(alpha: 0.04),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSelected
                            ? color.withValues(alpha: 0.5)
                            : SentioColors.border,
                        width: isSelected ? 1.5 : 1,
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: color.withValues(alpha: 0.15),
                                blurRadius: 8,
                                spreadRadius: -2,
                              )
                            ]
                          : null,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          SentioConstants.getEmotionIcon(emotion['id']),
                          size: 18,
                          color: isSelected ? color : SentioColors.textSecondary,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          emotion['label'],
                          style: GoogleFonts.manrope(
                            fontSize: 13,
                            fontWeight:
                                isSelected ? FontWeight.w600 : FontWeight.w400,
                            color: isSelected
                                ? color
                                : SentioColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 12),
          ],
          ),
        ),
      ),
    );
  }
}
