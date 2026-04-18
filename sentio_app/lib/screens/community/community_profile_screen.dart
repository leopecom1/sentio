import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import 'package:sentio_app/config/theme.dart';
import 'package:sentio_app/config/constants.dart';
import 'package:sentio_app/providers/app_provider.dart';
import 'package:sentio_app/models/community_post.dart';
import 'package:sentio_app/models/community_user.dart';

class CommunityProfileScreen extends StatefulWidget {
  final String userId;
  const CommunityProfileScreen({super.key, required this.userId});

  @override
  State<CommunityProfileScreen> createState() => _CommunityProfileScreenState();
}

class _CommunityProfileScreenState extends State<CommunityProfileScreen> {
  CommunityUser? _user;
  List<CommunityPost> _posts = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final provider = context.read<AppProvider>();
    final results = await Future.wait([
      provider.getCommunityUser(widget.userId),
      provider.getPostsByUser(widget.userId),
    ]);
    if (mounted) {
      setState(() {
        _user = results[0] as CommunityUser?;
        _posts = results[1] as List<CommunityPost>;
        _loading = false;
      });
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

    if (_loading) {
      return Scaffold(
        backgroundColor: SentioColors.background,
        appBar: AppBar(backgroundColor: SentioColors.background),
        body: const Center(child: CircularProgressIndicator(strokeWidth: 2, color: SentioColors.primary)),
      );
    }

    final user = _user;
    if (user == null) {
      return Scaffold(
        backgroundColor: SentioColors.background,
        appBar: AppBar(backgroundColor: SentioColors.background),
        body: const Center(child: Text('Usuario no encontrado', style: TextStyle(color: SentioColors.textSecondary))),
      );
    }

    final posts = _posts;

    return Scaffold(
      backgroundColor: SentioColors.background,
      appBar: AppBar(
        backgroundColor: SentioColors.background,
        leading: IconButton(icon: const Icon(Icons.arrow_back_rounded), onPressed: () => context.pop()),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          children: [
            // Avatar
            ClipOval(
              child: Container(
                width: 80,
                height: 80,
                color: SentioColors.primary.withValues(alpha: 0.2),
                child: user.avatarUrl != null
                    ? CachedNetworkImage(
                        imageUrl: user.avatarUrl!,
                        fit: BoxFit.cover,
                        errorWidget: (_, __, ___) => Center(child: Text(user.fullName[0], style: GoogleFonts.manrope(fontSize: 32, color: SentioColors.primary))),
                      )
                    : Center(child: Text(user.fullName[0], style: GoogleFonts.manrope(fontSize: 32, color: SentioColors.primary))),
              ),
            ),
            const SizedBox(height: 16),
            Text(user.fullName, style: GoogleFonts.manrope(fontSize: 24, color: SentioColors.textPrimary)),
            if (user.bio != null) ...[
              const SizedBox(height: 8),
              Text(user.bio!, style: TextStyle(fontSize: 14, color: SentioColors.textSecondary, height: 1.4), textAlign: TextAlign.center),
            ],
            const SizedBox(height: 20),
            // Stats
            Container(
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                color: SentioColors.surface,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  _StatItem(value: '${user.postsCount}', label: 'Posts'),
                  Container(width: 1, height: 32, color: SentioColors.divider),
                  _StatItem(value: '${user.followersCount}', label: 'Seguidores'),
                  Container(width: 1, height: 32, color: SentioColors.divider),
                  _StatItem(value: '${user.followingCount}', label: 'Siguiendo'),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Follow button
            SizedBox(
              width: double.infinity,
              child: user.isFollowedByMe
                  ? OutlinedButton(
                      onPressed: () => provider.toggleFollowUser(widget.userId),
                      child: const Text('Siguiendo'),
                    )
                  : ElevatedButton(
                      onPressed: () => provider.toggleFollowUser(widget.userId),
                      child: const Text('Seguir'),
                    ),
            ),
            const SizedBox(height: 24),
            // Posts
            if (posts.isNotEmpty) ...[
              Align(
                alignment: Alignment.centerLeft,
                child: Text('Publicaciones', style: GoogleFonts.manrope(fontSize: 16, fontWeight: FontWeight.w600, color: SentioColors.textPrimary)),
              ),
              const SizedBox(height: 12),
              ...posts.map((post) => _buildPostCard(context, post, provider)),
            ],
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  Widget _buildPostCard(BuildContext context, CommunityPost post, AppProvider provider) {
    final emotion = post.emotion != null
        ? SentioConstants.emotions.firstWhere((e) => e['id'] == post.emotion, orElse: () => <String, dynamic>{})
        : null;

    return GestureDetector(
      onTap: () => context.push('/community/post/${post.id}'),
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: SentioColors.surface,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(_timeAgo(post.createdAt), style: TextStyle(fontSize: 12, color: SentioColors.textTertiary)),
                if (emotion != null && emotion.isNotEmpty && post.emotion != null) ...[
                  const SizedBox(width: 6),
                  Icon(
                    SentioConstants.getEmotionIcon(post.emotion!),
                    size: 14,
                    color: Color(emotion['color'] as int),
                  ),
                ],
              ],
            ),
            if (post.content != null) ...[
              const SizedBox(height: 8),
              Text(post.content!, maxLines: 3, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 14, height: 1.5, color: SentioColors.textPrimary)),
            ],
            if (post.imageUrls.isNotEmpty) ...[
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: CachedNetworkImage(
                  imageUrl: post.imageUrls.first,
                  width: double.infinity,
                  height: 150,
                  fit: BoxFit.cover,
                  errorWidget: (_, __, ___) => Container(height: 150, color: SentioColors.card),
                ),
              ),
            ],
            const SizedBox(height: 10),
            Row(
              children: [
                Icon(post.isLikedByMe ? Icons.favorite_rounded : Icons.favorite_border_rounded, size: 16, color: post.isLikedByMe ? SentioColors.error : SentioColors.textTertiary),
                const SizedBox(width: 4),
                Text('${post.likesCount}', style: TextStyle(fontSize: 12, color: SentioColors.textTertiary)),
                const SizedBox(width: 16),
                const Icon(Icons.chat_bubble_outline_rounded, size: 14, color: SentioColors.textTertiary),
                const SizedBox(width: 4),
                Text('${post.commentsCount}', style: TextStyle(fontSize: 12, color: SentioColors.textTertiary)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String value;
  final String label;
  const _StatItem({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: SentioColors.textPrimary)),
          const SizedBox(height: 2),
          Text(label, style: TextStyle(fontSize: 12, color: SentioColors.textSecondary)),
        ],
      ),
    );
  }
}
