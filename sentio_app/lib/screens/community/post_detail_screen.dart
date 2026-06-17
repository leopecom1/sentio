import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import 'package:sentio_app/config/theme.dart';
import 'package:sentio_app/config/constants.dart';
import 'package:sentio_app/providers/app_provider.dart';
import 'package:sentio_app/models/community_comment.dart';

class PostDetailScreen extends StatefulWidget {
  final String postId;
  const PostDetailScreen({super.key, required this.postId});

  @override
  State<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends State<PostDetailScreen> {
  final _commentController = TextEditingController();
  List<CommunityComment> _comments = [];
  bool _commentsLoading = true;

  @override
  void initState() {
    super.initState();
    _loadComments();
  }

  Future<void> _loadComments() async {
    final provider = context.read<AppProvider>();
    final comments = await provider.getCommentsForPost(widget.postId);
    if (mounted) {
      setState(() {
        _comments = comments;
        _commentsLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  /// Opens a reason picker and submits a content report.
  Future<void> _reportContent(String contentType, String contentId) async {
    final reasons = [
      'Contenido inapropiado u ofensivo',
      'Spam o engañoso',
      'Acoso o discurso de odio',
      'Contenido sexual o violento',
      'Otro',
    ];
    final reason = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: SentioColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
              child: Text(
                'Reportar contenido',
                style: GoogleFonts.manrope(fontSize: 18, fontWeight: FontWeight.w700, color: SentioColors.textPrimary),
              ),
            ),
            ...reasons.map((r) => ListTile(
                  title: Text(r, style: GoogleFonts.manrope(color: SentioColors.textPrimary)),
                  onTap: () => Navigator.of(ctx).pop(r),
                )),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    if (reason == null || !mounted) return;
    final ok = await context.read<AppProvider>().reportContent(
          contentType: contentType,
          contentId: contentId,
          reason: reason,
        );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(ok
            ? 'Gracias. Revisaremos el contenido reportado.'
            : 'No se pudo enviar el reporte. Intentá de nuevo.'),
      ),
    );
  }

  /// Confirms and blocks a user, then leaves the post.
  Future<void> _confirmBlockUser(String userId, String userName) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: SentioColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Bloquear a $userName',
            style: GoogleFonts.manrope(fontWeight: FontWeight.w700, color: SentioColors.textPrimary)),
        content: Text(
          'No volverás a ver sus publicaciones, historias ni comentarios. '
          'Podés desbloquearlo más tarde desde tu perfil.',
          style: GoogleFonts.manrope(color: SentioColors.textSecondary, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text('Cancelar', style: GoogleFonts.manrope(color: SentioColors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: SentioColors.error, foregroundColor: Colors.white),
            child: Text('Bloquear', style: GoogleFonts.manrope(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
    if (confirm != true || !mounted) return;
    final ok = await context.read<AppProvider>().blockUser(userId);
    if (!mounted) return;
    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$userName fue bloqueado.')),
      );
      context.pop();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo bloquear al usuario.')),
      );
    }
  }

  String _timeAgo(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    if (diff.inHours < 24) return '${diff.inHours}h';
    if (diff.inDays < 7) return '${diff.inDays}d';
    return '${(diff.inDays / 7).floor()}sem';
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final post = provider.communityPosts.where((p) => p.id == widget.postId).firstOrNull;

    if (post == null) {
      return Scaffold(
        backgroundColor: SentioColors.background,
        appBar: AppBar(backgroundColor: SentioColors.background),
        body: const Center(child: Text('Post no encontrado', style: TextStyle(color: SentioColors.textSecondary))),
      );
    }

    final comments = _comments;
    final emotion = post.emotion != null
        ? SentioConstants.emotions.firstWhere((e) => e['id'] == post.emotion, orElse: () => <String, dynamic>{})
        : null;

    return Scaffold(
      backgroundColor: SentioColors.background,
      appBar: AppBar(
        backgroundColor: SentioColors.background,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
        title: const Text('Publicación'),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert_rounded, color: SentioColors.textSecondary),
            color: SentioColors.surface,
            onSelected: (value) {
              if (value == 'report') {
                _reportContent('post', post.id);
              } else if (value == 'block') {
                _confirmBlockUser(post.userId, post.userName);
              }
            },
            itemBuilder: (_) => [
              PopupMenuItem(
                value: 'report',
                child: Row(
                  children: [
                    const Icon(Icons.flag_outlined, size: 18, color: SentioColors.textSecondary),
                    const SizedBox(width: 10),
                    Text('Reportar publicación', style: GoogleFonts.manrope(color: SentioColors.textPrimary)),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'block',
                child: Row(
                  children: [
                    const Icon(Icons.block_rounded, size: 18, color: SentioColors.error),
                    const SizedBox(width: 10),
                    Text('Bloquear a ${post.userName}', style: GoogleFonts.manrope(color: SentioColors.error)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Post header
                  GestureDetector(
                    onTap: () => context.push('/community/user/${post.userId}'),
                    child: Row(
                      children: [
                        _buildAvatar(post.userAvatar, post.userName, 48),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(post.userName, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: SentioColors.textPrimary)),
                                  if (emotion != null && emotion.isNotEmpty && post.emotion != null) ...[
                                    const SizedBox(width: 6),
                                    Icon(
                                      SentioConstants.getEmotionIcon(post.emotion!),
                                      size: 16,
                                      color: Color(emotion['color'] as int),
                                    ),
                                  ],
                                ],
                              ),
                              Text(_timeAgo(post.createdAt), style: TextStyle(fontSize: 13, color: SentioColors.textTertiary)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Content
                  if (post.content != null && post.content!.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Text(post.content!, style: const TextStyle(fontSize: 16, height: 1.6, color: SentioColors.textPrimary)),
                  ],
                  // Image
                  if (post.imageUrls.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: CachedNetworkImage(
                        imageUrl: post.imageUrls.first,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        placeholder: (_, __) => Container(height: 250, color: SentioColors.card, child: const Center(child: CircularProgressIndicator(strokeWidth: 2, color: SentioColors.primary))),
                        errorWidget: (_, __, ___) => Container(height: 250, color: SentioColors.card, child: const Icon(Icons.image_not_supported_rounded, color: SentioColors.textTertiary)),
                      ),
                    ),
                  ],
                  // Like row
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () => provider.togglePostLike(post.id),
                        child: Row(
                          children: [
                            Icon(
                              post.isLikedByMe ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                              size: 24,
                              color: post.isLikedByMe ? SentioColors.error : SentioColors.textTertiary,
                            ),
                            const SizedBox(width: 6),
                            Text('${post.likesCount}', style: TextStyle(fontSize: 15, color: post.isLikedByMe ? SentioColors.error : SentioColors.textTertiary)),
                          ],
                        ),
                      ),
                      const SizedBox(width: 24),
                      Row(
                        children: [
                          const Icon(Icons.chat_bubble_outline_rounded, size: 22, color: SentioColors.textTertiary),
                          const SizedBox(width: 6),
                          Text('${post.commentsCount}', style: TextStyle(fontSize: 15, color: SentioColors.textTertiary)),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  const Divider(color: SentioColors.divider),
                  const SizedBox(height: 16),
                  // Comments
                  if (_commentsLoading)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(24),
                        child: CircularProgressIndicator(strokeWidth: 2, color: SentioColors.primary),
                      ),
                    )
                  else if (comments.isNotEmpty) ...[
                    Text(
                      'Comentarios',
                      style: GoogleFonts.manrope(fontSize: 16, fontWeight: FontWeight.w600, color: SentioColors.textPrimary),
                    ),
                    const SizedBox(height: 12),
                    ...comments.map((comment) => _buildCommentTile(comment)),
                  ] else
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(
                          'Sé el primero en comentar',
                          style: TextStyle(fontSize: 14, color: SentioColors.textTertiary),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          // Comment input
          Container(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 12),
            decoration: BoxDecoration(
              color: SentioColors.surface,
              border: Border(top: BorderSide(color: SentioColors.divider)),
            ),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: SentioColors.card,
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: TextField(
                        controller: _commentController,
                        decoration: InputDecoration(
                          hintText: 'Escribí un comentario...',
                          border: InputBorder.none,
                          filled: false,
                          contentPadding: const EdgeInsets.symmetric(vertical: 12),
                          hintStyle: TextStyle(color: SentioColors.textTertiary),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () async {
                      if (_commentController.text.trim().isNotEmpty) {
                        final text = _commentController.text.trim();
                        _commentController.clear();
                        FocusScope.of(context).unfocus();
                        await provider.addCommentToPost(widget.postId, text);
                        _loadComments();
                      }
                    },
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: SentioColors.primary,
                        borderRadius: BorderRadius.circular(22),
                      ),
                      child: const Icon(Icons.arrow_upward_rounded, color: Colors.white, size: 22),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommentTile(CommunityComment comment) {
    return GestureDetector(
      onLongPress: () => _showCommentActions(comment),
      child: Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildAvatar(comment.userAvatar, comment.userName, 32),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(comment.userName, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: SentioColors.textPrimary)),
                    const SizedBox(width: 8),
                    Text(_timeAgo(comment.createdAt), style: TextStyle(fontSize: 11, color: SentioColors.textTertiary)),
                  ],
                ),
                const SizedBox(height: 4),
                Text(comment.content, style: const TextStyle(fontSize: 14, height: 1.4, color: SentioColors.textPrimary)),
              ],
            ),
          ),
        ],
      ),
      ),
    );
  }

  /// Bottom sheet shown on long-press of a comment (report / block author).
  void _showCommentActions(CommunityComment comment) {
    showModalBottomSheet(
      context: context,
      backgroundColor: SentioColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.flag_outlined, color: SentioColors.textSecondary),
              title: Text('Reportar comentario', style: GoogleFonts.manrope(color: SentioColors.textPrimary)),
              onTap: () {
                Navigator.of(ctx).pop();
                _reportContent('comment', comment.id);
              },
            ),
            ListTile(
              leading: const Icon(Icons.block_rounded, color: SentioColors.error),
              title: Text('Bloquear a ${comment.userName}', style: GoogleFonts.manrope(color: SentioColors.error)),
              onTap: () {
                Navigator.of(ctx).pop();
                _confirmBlockUser(comment.userId, comment.userName);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatar(String? url, String name, double size) {
    return ClipOval(
      child: Container(
        width: size,
        height: size,
        color: SentioColors.primary.withValues(alpha: 0.2),
        child: url != null
            ? CachedNetworkImage(
                imageUrl: url,
                fit: BoxFit.cover,
                errorWidget: (_, __, ___) => Center(child: Text(name.isNotEmpty ? name[0] : '?', style: TextStyle(fontSize: size * 0.4, fontWeight: FontWeight.bold, color: SentioColors.primary))),
              )
            : Center(child: Text(name.isNotEmpty ? name[0] : '?', style: TextStyle(fontSize: size * 0.4, fontWeight: FontWeight.bold, color: SentioColors.primary))),
      ),
    );
  }
}
