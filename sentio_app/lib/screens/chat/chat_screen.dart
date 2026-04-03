import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:sentio_app/config/theme.dart';
import 'package:sentio_app/config/constants.dart';
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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<AppProvider>();
      if (provider.currentMessages.isEmpty) {
        provider.startNewConversation();
      }
    });
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

  /// Returns an emoji for today's checkin emotion, or a default.
  String _getMoodEmoji(String? emotionId) {
    if (emotionId == null) return '---';
    final match = SentioConstants.emotions.where((e) => e['id'] == emotionId);
    if (match.isNotEmpty) return match.first['emoji'] as String;
    return '---';
  }

  /// Returns the label for today's checkin emotion.
  String _getMoodLabel(String? emotionId) {
    if (emotionId == null) return 'Sin registro';
    final match = SentioConstants.emotions.where((e) => e['id'] == emotionId);
    if (match.isNotEmpty) return match.first['label'] as String;
    return emotionId;
  }

  /// Returns the first goal label from the user's profile goals list.
  String _getGoalText(List<String> goals) {
    if (goals.isEmpty) return 'Sin meta';
    final goalId = goals.first;
    final match = SentioConstants.goals.where((g) => g['id'] == goalId);
    if (match.isNotEmpty) return match.first['label'] ?? goalId;
    return goalId;
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final messages = provider.currentMessages;
    final todayCheckin = provider.todayCheckin;
    final profile = provider.profile;

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
                // ─── Focus Area Cards ───
                _buildFocusCards(todayCheckin?.primaryEmotion, profile?.goals ?? []),
                // ─── Divider ───
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Divider(height: 1, color: SentioColors.border),
                ),
                // ─── Messages ───
                Expanded(
                  child: messages.isEmpty
                      ? _buildEmptyState()
                      : ListView.builder(
                          controller: _scrollController,
                          padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                          itemCount: messages.length + (_isSending ? 1 : 0),
                          itemBuilder: (context, index) {
                            if (index == messages.length && _isSending) {
                              return _buildTypingIndicator();
                            }
                            final message = messages[index];
                            return _buildMessage(message.content, message.isUser);
                          },
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
          // Coach avatar
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
              Icons.psychology_rounded,
              color: SentioColors.primary,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          // Title + online indicator
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Coach Alex',
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
                    // Animated ping dot
                    _OnlineDot(),
                    const SizedBox(width: 6),
                    Text(
                      'En línea ahora',
                      style: GoogleFonts.manrope(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: SentioColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // More button
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.more_vert_rounded, size: 22),
            color: SentioColors.textSecondary,
            splashRadius: 20,
          ),
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
  //  FOCUS AREA CARDS
  // ═══════════════════════════════════════════
  Widget _buildFocusCards(String? emotionId, List<String> goals) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
      child: Row(
        children: [
          // Estado card
          Expanded(
            child: _FocusCard(
              icon: Text(
                _getMoodEmoji(emotionId),
                style: const TextStyle(fontSize: 18),
              ),
              label: 'Estado',
              value: _getMoodLabel(emotionId),
            ),
          ),
          const SizedBox(width: 8),
          // Meta card
          Expanded(
            child: _FocusCard(
              icon: const Icon(
                Icons.flag_rounded,
                color: SentioColors.primary,
                size: 18,
              ),
              label: 'Meta',
              value: _getGoalText(goals),
            ),
          ),
          const SizedBox(width: 8),
          // Ingresos card
          Expanded(
            child: _FocusCard(
              icon: Icon(
                Icons.trending_up_rounded,
                color: SentioColors.accent,
                size: 18,
              ),
              label: 'Ingresos',
              value: '+15%',
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
              // Attach button
              IconButton(
                onPressed: () {},
                icon: const Icon(Icons.attach_file_rounded, size: 20),
                color: SentioColors.textSecondary,
                splashRadius: 18,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
              ),
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
              // Mic button
              IconButton(
                onPressed: () {},
                icon: const Icon(Icons.mic_none_rounded, size: 20),
                color: SentioColors.textSecondary,
                splashRadius: 18,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
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
//  FOCUS CARD WIDGET
// ═══════════════════════════════════════════════
class _FocusCard extends StatelessWidget {
  final Widget icon;
  final String label;
  final String value;

  const _FocusCard({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: SentioColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: SentioColors.primary.withOpacity(0.20),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          icon,
          const SizedBox(height: 6),
          Text(
            label,
            style: GoogleFonts.manrope(
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: SentioColors.textSecondary,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: GoogleFonts.manrope(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: SentioColors.textPrimary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════
//  ONLINE INDICATOR DOT (animated ping)
// ═══════════════════════════════════════════════
class _OnlineDot extends StatefulWidget {
  @override
  State<_OnlineDot> createState() => _OnlineDotState();
}

class _OnlineDotState extends State<_OnlineDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();
    _scaleAnimation = Tween(begin: 1.0, end: 2.5).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
    _opacityAnimation = Tween(begin: 0.6, end: 0.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 12,
      height: 12,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Ping ring
          AnimatedBuilder(
            animation: _controller,
            builder: (_, __) => Transform.scale(
              scale: _scaleAnimation.value,
              child: Opacity(
                opacity: _opacityAnimation.value,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: SentioColors.accent,
                  ),
                ),
              ),
            ),
          ),
          // Solid dot
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: SentioColors.accent,
            ),
          ),
        ],
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
