import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sentio_app/config/theme.dart';
import 'package:sentio_app/providers/app_provider.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  bool _isSending = false;

  static const String _consentKey = 'chat_ai_consent_v1';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<AppProvider>();
      if (provider.currentMessages.isEmpty) {
        // Retomamos la última conversación si existe; si no, arrancamos una nueva.
        if (provider.conversations.isNotEmpty) {
          provider.loadConversationMessages(provider.conversations.first.id);
        } else {
          provider.startNewConversation();
        }
      }
      _ensureConsent();
    });
  }

  /// Panel con el historial de conversaciones para retomar o empezar otra.
  void _showHistory(BuildContext context, AppProvider provider) {
    provider.reloadConversations();
    showModalBottomSheet(
      context: context,
      backgroundColor: SentioColors.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Consumer<AppProvider>(
        builder: (ctx, p, _) {
          final convs = p.conversations;
          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.history_rounded,
                          color: SentioColors.textSecondary, size: 20),
                      const SizedBox(width: 8),
                      Text('Tus conversaciones',
                          style: GoogleFonts.manrope(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: SentioColors.textPrimary)),
                      const Spacer(),
                      TextButton(
                        onPressed: () {
                          Navigator.pop(ctx);
                          provider.startNewConversation();
                        },
                        child: const Text('Nueva',
                            style: TextStyle(color: SentioColors.primary)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  if (convs.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 28),
                      child: Text('Todavía no tenés conversaciones.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: SentioColors.textTertiary)),
                    )
                  else
                    Flexible(
                      child: ListView.separated(
                        shrinkWrap: true,
                        itemCount: convs.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (_, i) {
                          final c = convs[i];
                          final isCurrent = c.id == p.currentConversationId;
                          return GestureDetector(
                            onTap: () {
                              Navigator.pop(ctx);
                              provider.loadConversationMessages(c.id);
                            },
                            child: Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: isCurrent
                                    ? SentioColors.primary.withValues(alpha: 0.10)
                                    : SentioColors.card,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                    color: isCurrent
                                        ? SentioColors.primary
                                        : SentioColors.border),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                      c.isCrisis
                                          ? Icons.favorite_rounded
                                          : Icons.chat_bubble_outline_rounded,
                                      size: 18,
                                      color: c.isCrisis
                                          ? SentioColors.error
                                          : SentioColors.primary),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                            (c.title?.isNotEmpty ?? false)
                                                ? c.title!
                                                : 'Conversación',
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: GoogleFonts.manrope(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w600,
                                                color:
                                                    SentioColors.textPrimary)),
                                        const SizedBox(height: 2),
                                        Text(_formatDate(c.updatedAt),
                                            style: TextStyle(
                                                fontSize: 11,
                                                color:
                                                    SentioColors.textTertiary)),
                                      ],
                                    ),
                                  ),
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
        },
      ),
    );
  }

  String _formatDate(DateTime d) {
    final diff = DateTime.now().difference(d);
    if (diff.inDays == 0) return 'Hoy';
    if (diff.inDays == 1) return 'Ayer';
    if (diff.inDays < 7) return 'Hace ${diff.inDays} días';
    return '${d.day}/${d.month}/${d.year}';
  }

  /// Shows a one-time consent dialog before the user can use the AI chat.
  /// If the user declines, we leave the screen. Acceptance is persisted.
  Future<void> _ensureConsent() async {
    final prefs = await SharedPreferences.getInstance();
    final accepted = prefs.getBool(_consentKey) ?? false;
    if (accepted) return;
    if (!mounted) return;

    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: SentioColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: SentioColors.primary.withOpacity(0.15),
              ),
              child: const Icon(
                Icons.smart_toy_rounded,
                color: SentioColors.primary,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Asistente de IA',
                style: GoogleFonts.manrope(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: SentioColors.textPrimary,
                ),
              ),
            ),
          ],
        ),
        content: Text(
          'Este chat usa inteligencia artificial para generar respuestas '
          'automáticas. No es un profesional de la salud ni reemplaza '
          'atención médica, psicológica o financiera.\n\n'
          'Tus mensajes se envían a un proveedor de IA para generar las '
          'respuestas. No compartas información sensible que no quieras '
          'procesar.\n\n'
          'Si estás en crisis o emergencia, contactá a un profesional o a '
          'los servicios de emergencia de tu país.',
          style: GoogleFonts.manrope(
            fontSize: 14,
            height: 1.5,
            color: SentioColors.textSecondary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(
              'No, gracias',
              style: GoogleFonts.manrope(
                fontWeight: FontWeight.w600,
                color: SentioColors.textSecondary,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: SentioColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              'Acepto y continúo',
              style: GoogleFonts.manrope(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );

    if (result == true) {
      await prefs.setBool(_consentKey, true);
    } else {
      if (mounted) context.pop();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _isSending) return;

    _controller.clear();
    setState(() => _isSending = true);

    final provider = context.read<AppProvider>();
    await provider.sendMessage(text);

    if (!mounted) return;
    setState(() => _isSending = false);
    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final messages = provider.currentMessages;

    return Scaffold(
      backgroundColor: SentioColors.background,
      body: Stack(
        children: [
          // Background decorative glow circles
          Positioned(
            top: -80,
            right: -80,
            child: IgnorePointer(
              child: Container(
                width: 260,
                height: 260,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      SentioColors.primary.withOpacity(0.10),
                      SentioColors.primary.withOpacity(0.0),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            bottom: -60,
            left: -60,
            child: IgnorePointer(
              child: Container(
                width: 180,
                height: 180,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      SentioColors.accent.withOpacity(0.10),
                      SentioColors.accent.withOpacity(0.0),
                    ],
                  ),
                ),
              ),
            ),
          ),
          // Main content
          SafeArea(
            child: Column(
              children: [
                // ─── Header ───
                _buildHeader(provider),
                // ─── AI disclaimer banner ───
                _buildDisclaimerBanner(),
                const SizedBox(height: 4),
                // ─── Messages (tap para ocultar el teclado) ───
                Expanded(
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => FocusScope.of(context).unfocus(),
                    child: messages.isEmpty
                        ? _buildEmptyState()
                        : ListView.builder(
                            controller: _scrollController,
                            keyboardDismissBehavior:
                                ScrollViewKeyboardDismissBehavior.onDrag,
                            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                            itemCount: messages.length + (_isSending ? 1 : 0),
                            itemBuilder: (context, index) {
                              if (index == messages.length && _isSending) {
                                return _buildTypingIndicator();
                              }
                              final message = messages[index];
                              return _buildMessage(
                                  message.content, message.isUser);
                            },
                          ),
                  ),
                ),
                // ─── Quick Suggestions ───
                if (messages.length <= 1) _buildQuickActions(),
                // ─── Input Area ───
                _buildInputArea(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════
  //  HEADER
  // ═══════════════════════════════════════════
  Widget _buildHeader(AppProvider provider) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
      decoration: BoxDecoration(
        color: SentioColors.background.withOpacity(0.85),
      ),
      child: Row(
        children: [
          // Back button
          GestureDetector(
            onTap: () => context.pop(),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.arrow_back_rounded,
                color: SentioColors.textPrimary,
                size: 20,
              ),
            ),
          ),
          const SizedBox(width: 10),
          // AI assistant avatar
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: SentioColors.primary.withOpacity(0.15),
              border: Border.all(
                color: SentioColors.primary.withOpacity(0.3),
                width: 1.5,
              ),
            ),
            child: const Icon(
              Icons.smart_toy_rounded,
              color: SentioColors.primary,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          // Title + AI label
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Asistente IA',
                  style: GoogleFonts.manrope(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: SentioColors.textPrimary,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Icon(
                      Icons.auto_awesome_rounded,
                      size: 12,
                      color: SentioColors.textSecondary,
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        'Respuestas generadas por IA',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.manrope(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: SentioColors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // History button
          GestureDetector(
            onTap: () => _showHistory(context, provider),
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: SentioColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: SentioColors.border),
              ),
              child: const Icon(
                Icons.history_rounded,
                color: SentioColors.textSecondary,
                size: 20,
              ),
            ),
          ),
          const SizedBox(width: 8),
          // New conversation button
          GestureDetector(
            onTap: () => provider.startNewConversation(),
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: SentioColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: SentioColors.border),
              ),
              child: const Icon(
                Icons.add_rounded,
                color: SentioColors.textSecondary,
                size: 20,
              ),
            ),
          ),
          const SizedBox(width: 4),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════
  //  AI DISCLAIMER BANNER
  // ═══════════════════════════════════════════
  Widget _buildDisclaimerBanner() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 4),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: SentioColors.primary.withOpacity(0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: SentioColors.primary.withOpacity(0.15)),
      ),
      child: Row(
        children: [
          Icon(
            Icons.info_outline_rounded,
            size: 14,
            color: SentioColors.textSecondary,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Respuestas generadas por IA. No reemplaza atención profesional.',
              style: GoogleFonts.manrope(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                height: 1.3,
                color: SentioColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }


  // ═══════════════════════════════════════════
  //  EMPTY STATE
  // ═══════════════════════════════════════════
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: SentioColors.primary.withOpacity(0.1),
            ),
            child: const Icon(
              Icons.chat_bubble_outline_rounded,
              color: SentioColors.primary,
              size: 28,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Cuando quieras hablar,\nacá voy a estar.',
            style: GoogleFonts.manrope(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              height: 1.4,
              color: SentioColors.textPrimary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════
  //  MESSAGE BUBBLE
  // ═══════════════════════════════════════════
  Widget _buildMessage(String content, bool isUser) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) ...[
            // AI avatar
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: SentioColors.primary.withOpacity(0.15),
              ),
              child: const Icon(
                Icons.psychology_rounded,
                color: SentioColors.primary,
                size: 16,
              ),
            ),
            const SizedBox(width: 10),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isUser ? SentioColors.primary : SentioColors.surface,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(20),
                  topRight: const Radius.circular(20),
                  bottomLeft: Radius.circular(isUser ? 20 : 0),
                  bottomRight: Radius.circular(isUser ? 0 : 20),
                ),
                border: isUser
                    ? null
                    : Border.all(color: SentioColors.border),
                boxShadow: isUser
                    ? [
                        BoxShadow(
                          color: SentioColors.primary.withOpacity(0.20),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ]
                    : null,
              ),
              child: Text(
                content,
                style: GoogleFonts.manrope(
                  fontSize: 15,
                  height: 1.5,
                  fontWeight: FontWeight.w400,
                  color: isUser ? Colors.white : SentioColors.textPrimary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════
  //  TYPING INDICATOR
  // ═══════════════════════════════════════════
  Widget _buildTypingIndicator() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: SentioColors.primary.withOpacity(0.15),
            ),
            child: const Icon(
              Icons.psychology_rounded,
              color: SentioColors.primary,
              size: 16,
            ),
          ),
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: SentioColors.surface,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
                bottomLeft: Radius.circular(0),
                bottomRight: Radius.circular(20),
              ),
              border: Border.all(color: SentioColors.border),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _Dot(delay: 0),
                const SizedBox(width: 4),
                _Dot(delay: 200),
                const SizedBox(width: 4),
                _Dot(delay: 400),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════
  //  QUICK ACTION PILLS
  // ═══════════════════════════════════════════
  Widget _buildQuickActions() {
    final suggestions = [
      {'emoji': '\u{1F630}', 'text': 'Tengo ansiedad'},
      {'emoji': '\u{1F9F1}', 'text': 'Estoy bloqueado'},
      {'emoji': '\u{1F4C9}', 'text': 'No estoy vendiendo'},
      {'emoji': '\u{1F4A1}', 'text': 'Necesito claridad'},
    ];

    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: suggestions.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final s = suggestions[index];
          return GestureDetector(
            onTap: () {
              _controller.text = '${s['emoji']} ${s['text']}';
              _send();
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: SentioColors.surface,
                borderRadius: BorderRadius.circular(100),
                border: Border.all(
                  color: SentioColors.primary.withOpacity(0.20),
                ),
              ),
              child: Text(
                '${s['emoji']} ${s['text']}',
                style: GoogleFonts.manrope(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: SentioColors.textPrimary,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // ═══════════════════════════════════════════
  //  INPUT AREA
  // ═══════════════════════════════════════════
  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
      decoration: BoxDecoration(
        color: SentioColors.background,
        border: Border(
          top: BorderSide(color: SentioColors.border),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Container(
          padding: const EdgeInsets.only(left: 4, right: 4),
          decoration: BoxDecoration(
            color: SentioColors.surface,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: SentioColors.border),
          ),
          child: Row(
            children: [
              const SizedBox(width: 12),
              // TextField
              Expanded(
                child: TextField(
                  controller: _controller,
                  maxLines: 4,
                  minLines: 1,
                  textCapitalization: TextCapitalization.sentences,
                  style: GoogleFonts.manrope(
                    fontSize: 14,
                    color: SentioColors.textPrimary,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Escribí tu mensaje...',
                    border: InputBorder.none,
                    filled: false,
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                    hintStyle: GoogleFonts.manrope(
                      fontSize: 14,
                      color: SentioColors.textSecondary,
                    ),
                  ),
                  onSubmitted: (_) => _send(),
                ),
              ),
              // Send button
              GestureDetector(
                onTap: _send,
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: SentioColors.primary,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.send_rounded,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
              ),
              const SizedBox(width: 2),
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════
//  TYPING INDICATOR DOT (bouncing)
// ═══════════════════════════════════════════════
class _Dot extends StatefulWidget {
  final int delay;
  const _Dot({required this.delay});

  @override
  State<_Dot> createState() => _DotState();
}

class _DotState extends State<_Dot> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _animation = Tween(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    Future.delayed(Duration(milliseconds: widget.delay), () {
      if (mounted) _controller.repeat(reverse: true);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (_, __) => Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: SentioColors.textSecondary.withOpacity(_animation.value),
        ),
      ),
    );
  }
}
