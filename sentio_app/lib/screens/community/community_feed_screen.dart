import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:sentio_app/config/theme.dart';
import 'package:sentio_app/config/constants.dart';
import 'package:sentio_app/providers/app_provider.dart';
import 'package:sentio_app/models/community_post.dart';
import 'package:sentio_app/models/community_story.dart';
import 'package:sentio_app/models/profile.dart';
import 'package:sentio_app/widgets/category_pills.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';

class CommunityFeedScreen extends StatefulWidget {
  const CommunityFeedScreen({super.key});

  @override
  State<CommunityFeedScreen> createState() => _CommunityFeedScreenState();
}

class _CommunityFeedScreenState extends State<CommunityFeedScreen> {
  bool _storiesExpanded = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<AppProvider>();
      if (provider.communityPosts.isEmpty) {
        provider.loadCommunityData();
      }
    });
  }

  String _timeAgo(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    if (diff.inHours < 24) return '${diff.inHours}h';
    if (diff.inDays < 7) return '${diff.inDays}d';
    return '${(diff.inDays / 7).floor()}sem';
  }

  /// Opens a reason picker and submits a report for a post.
  Future<void> _reportPost(String postId) async {
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
                'Reportar publicación',
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
          contentType: 'post',
          contentId: postId,
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

  /// Confirms and blocks a user.
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
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(ok ? '$userName fue bloqueado.' : 'No se pudo bloquear al usuario.')),
    );
  }

  // Map category names to colors for tags
  Color _categoryColor(String? category) {
    switch (category) {
      case 'Mentalidad':
        return const Color(0xFF9B8EC4);
      case 'Ventas':
        return const Color(0xFFC9A96E);
      case 'Finanzas':
        return const Color(0xFF6DB3C4);
      case 'Hábitos':
        return const Color(0xFF7B9E87);
      case 'Tech':
        return SentioColors.primary;
      default:
        return SentioColors.textSecondary;
    }
  }

  // Assign a pseudo-category based on post emotion or content for demo
  String? _postCategory(CommunityPost post) {
    final emotion = post.emotion;
    if (emotion == null) return null;
    switch (emotion) {
      case 'motivated':
      case 'hopeful':
        return 'Mentalidad';
      case 'focused':
        return 'Tech';
      case 'calm':
        return 'Hábitos';
      case 'overwhelmed':
      case 'anxious':
      case 'pressured':
        return 'Mentalidad';
      case 'grateful':
        return 'Mentalidad';
      case 'sad':
      case 'frustrated':
      case 'angry':
        return 'Mentalidad';
      case 'insecure':
        return 'Ventas';
      case 'lonely':
        return 'Mentalidad';
      case 'blocked':
        return 'Tech';
      default:
        return null;
    }
  }

  // Assign a role label based on user demo data
  String _userRole(String userId) {
    switch (userId) {
      case 'demo-ana':
        return 'CEO';
      case 'demo-diego':
        return 'Founder';
      case 'demo-vale':
        return 'Diseñadora UX';
      case 'demo-nico':
        return 'CTO';
      case 'demo-cami':
        return 'Marketing';
      case 'demo-mateo':
        return 'Mentor';
      case 'demo-isa':
        return 'Fundadora';
      case 'demo-santi':
        return 'Dev';
      default:
        return 'Emprendedor';
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();

    // ── Validation gate ──
    final validationStatus = provider.profile?.validationStatus ?? 'not_submitted';
    if (validationStatus != 'approved') {
      return _ValidationGate(status: validationStatus, profile: provider.profile);
    }

    final allPosts = provider.communityPosts;
    final stories = provider.communityStories;

    // Group stories by user - one circle per user
    final Map<String, List<CommunityStory>> storiesByUser = {};
    for (final story in stories) {
      storiesByUser.putIfAbsent(story.userId, () => []).add(story);
    }
    final groupedUserIds = storiesByUser.keys.toList();
    final selectedCategory = provider.selectedCommunityCategory;

    // Filter posts by category (compare lowercase for consistency)
    final posts = selectedCategory == 'Todo'
        ? allPosts
        : allPosts.where((p) {
            final postCat = p.category ?? _postCategory(p);
            return (postCat ?? '').toLowerCase() == selectedCategory.toLowerCase();
          }).toList();

    return Scaffold(
      backgroundColor: SentioColors.background,
      body: SafeArea(
        child: RefreshIndicator(
          color: SentioColors.accent,
          backgroundColor: SentioColors.surface,
          onRefresh: () async {
            provider.loadCommunityData();
          },
          child: CustomScrollView(
            slivers: [
              // -- Header: avatar + title + search icon --
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                  child: Row(
                    children: [
                      // User avatar
                      GestureDetector(
                        onTap: () => context.push('/profile'),
                        child: _buildAvatar(
                          provider.profile?.avatarUrl,
                          provider.userName,
                          38,
                        ),
                      ),
                      const Spacer(),
                      // Title centered
                      Text(
                        'Comunidad',
                        style: GoogleFonts.manrope(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: SentioColors.textPrimary,
                          letterSpacing: -0.3,
                        ),
                      ),
                      const Spacer(),
                      // Search icon
                      GestureDetector(
                        onTap: () {
                          // TODO: implement search
                        },
                        child: Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: SentioColors.surface,
                            shape: BoxShape.circle,
                            border: Border.all(color: SentioColors.border),
                          ),
                          child: const Icon(
                            Icons.search_rounded,
                            color: SentioColors.textSecondary,
                            size: 20,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 16)),

              // -- Category pills --
              SliverToBoxAdapter(
                child: CategoryPills(
                  categories: SentioConstants.communityCategories,
                  selected: selectedCategory,
                  onSelected: (cat) => provider.setCommunityCategory(cat),
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 16)),

              // -- Compose bar --
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: GestureDetector(
                    onTap: () => context.push('/community/create'),
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: SentioEffects.standardCard(),
                      child: Row(
                        children: [
                          _buildAvatar(
                            provider.profile?.avatarUrl,
                            provider.userName,
                            34,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              '¿Qué querés compartir?',
                              style: GoogleFonts.manrope(
                                fontSize: 14,
                                fontWeight: FontWeight.w400,
                                color: SentioColors.textSecondary,
                              ),
                            ),
                          ),
                          Container(
                            width: 34,
                            height: 34,
                            decoration: BoxDecoration(
                              color: SentioColors.primary,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: SentioEffects.glow(
                                SentioColors.primary,
                                blur: 8,
                                opacity: 0.25,
                              ),
                            ),
                            child: const Icon(
                              Icons.send_rounded,
                              color: Colors.white,
                              size: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 16)),

              // -- Stories section (always visible) --
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: GestureDetector(
                    onTap: () => setState(() => _storiesExpanded = !_storiesExpanded),
                    child: Row(
                      children: [
                        Text(
                          'Historias',
                          style: GoogleFonts.manrope(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: SentioColors.textSecondary,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          _storiesExpanded
                              ? Icons.keyboard_arrow_up_rounded
                              : Icons.keyboard_arrow_down_rounded,
                          size: 18,
                          color: SentioColors.textSecondary,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              if (_storiesExpanded) ...[
                const SliverToBoxAdapter(child: SizedBox(height: 10)),
                SliverToBoxAdapter(
                  child: SizedBox(
                    height: 88,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: groupedUserIds.length + 1,
                      itemBuilder: (context, index) {
                        if (index == 0) {
                          return _buildAddStoryCircle();
                        }
                        final userId = groupedUserIds[index - 1];
                        final userStories = storiesByUser[userId]!;
                        final latestStory = userStories.first;
                        final allViewed = userStories.every((s) => s.isViewed);
                        return _buildStoryCircle(latestStory, userId, allViewed);
                      },
                    ),
                  ),
                ),
              ],
              const SliverToBoxAdapter(child: SizedBox(height: 8)),

              // -- Divider --
              SliverToBoxAdapter(
                child: Container(
                  height: 1,
                  color: SentioColors.divider,
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 12)),

              // -- Posts feed --
              if (posts.isEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
                    child: Center(
                      child: Column(
                        children: [
                          Icon(
                            Icons.forum_outlined,
                            size: 48,
                            color: SentioColors.textTertiary.withOpacity(0.5),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'No hay posts en esta categoría',
                            style: GoogleFonts.manrope(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: SentioColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              else
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final post = posts[index];
                      return _buildPostCard(context, post, provider);
                    },
                    childCount: posts.length,
                  ),
                ),

              const SliverToBoxAdapter(child: SizedBox(height: 100)),
            ],
          ),
        ),
      ),
      // -- FAB: new post --
      floatingActionButton: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          boxShadow: SentioEffects.glow(
            SentioColors.primary,
            blur: 16,
            opacity: 0.4,
          ),
        ),
        child: FloatingActionButton(
          onPressed: () => context.push('/community/create'),
          backgroundColor: SentioColors.primary,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          child: const Icon(
            Icons.add_rounded,
            color: Colors.white,
            size: 28,
          ),
        ),
      ),
    );
  }

  // ============ STORIES ============

  Widget _buildAddStoryCircle() {
    return GestureDetector(
      onTap: () => context.push('/community/story/create'),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [
                    SentioColors.primary.withValues(alpha: 0.15),
                    SentioColors.accent.withValues(alpha: 0.1),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                border: Border.all(
                  color: SentioColors.accent.withValues(alpha: 0.4),
                  width: 1.5,
                ),
              ),
              child: const Icon(
                Icons.add_rounded,
                color: SentioColors.accent,
                size: 26,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Tu historia',
              style: GoogleFonts.manrope(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: SentioColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStoryCircle(CommunityStory story, String userId, bool allViewed) {
    return GestureDetector(
      onTap: () => context.push('/community/story/$userId'),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 58,
              height: 58,
              padding: const EdgeInsets.all(2.5),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: allViewed
                    ? null
                    : const LinearGradient(
                        colors: [SentioColors.primary, SentioColors.accent],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                border: allViewed
                    ? Border.all(color: SentioColors.divider, width: 2)
                    : null,
              ),
              child: Container(
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: SentioColors.background,
                ),
                padding: const EdgeInsets.all(2),
                child: ClipOval(
                  child: story.userAvatar != null
                      ? CachedNetworkImage(
                          imageUrl: story.userAvatar!,
                          fit: BoxFit.cover,
                          placeholder: (_, __) => Container(
                            color: SentioColors.surface,
                            child: const Icon(Icons.person, size: 18, color: SentioColors.textTertiary),
                          ),
                          errorWidget: (_, __, ___) => Container(
                            color: SentioColors.surface,
                            child: Center(
                              child: Text(
                                story.userName.isNotEmpty ? story.userName[0] : '?',
                                style: GoogleFonts.manrope(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: SentioColors.textPrimary,
                                ),
                              ),
                            ),
                          ),
                        )
                      : Container(
                          color: SentioColors.primary.withValues(alpha: 0.2),
                          child: Center(
                            child: Text(
                              story.userName.isNotEmpty ? story.userName[0] : '?',
                              style: GoogleFonts.manrope(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: SentioColors.primary,
                              ),
                            ),
                          ),
                        ),
                ),
              ),
            ),
            const SizedBox(height: 6),
            SizedBox(
              width: 58,
              child: Text(
                story.userName.split(' ').first,
                style: GoogleFonts.manrope(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: allViewed ? SentioColors.textTertiary : SentioColors.textPrimary,
                ),
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============ POST CARD ============

  Widget _buildPostCard(BuildContext context, CommunityPost post, AppProvider provider) {
    final emotion = post.emotion != null
        ? SentioConstants.emotions.firstWhere(
            (e) => e['id'] == post.emotion,
            orElse: () => <String, dynamic>{},
          )
        : null;

    final category = _postCategory(post);
    final role = _userRole(post.userId);

    return GestureDetector(
      onTap: () => context.push('/community/post/${post.id}'),
      child: Container(
        margin: const EdgeInsets.fromLTRB(20, 0, 20, 14),
        padding: const EdgeInsets.all(18),
        decoration: SentioEffects.standardCard(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // -- Post header: avatar + name + role tag + timestamp --
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => context.push('/community/user/${post.userId}'),
                    child: Row(
                      children: [
                        _buildAvatar(post.userAvatar, post.userName, 40),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                post.userName,
                                style: GoogleFonts.manrope(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: SentioColors.textPrimary,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 8),
                            // Role tag
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: SentioColors.primary.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                role,
                                style: GoogleFonts.manrope(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: SentioColors.primary,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Text(
                              _timeAgo(post.createdAt),
                              style: GoogleFonts.manrope(
                                fontSize: 12,
                                fontWeight: FontWeight.w400,
                                color: SentioColors.textTertiary,
                              ),
                            ),
                            // Category tag
                            if (category != null) ...[
                              const SizedBox(width: 8),
                              Container(
                                width: 4,
                                height: 4,
                                decoration: BoxDecoration(
                                  color: SentioColors.textTertiary,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: _categoryColor(category).withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  category,
                                  style: GoogleFonts.manrope(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: _categoryColor(category),
                                  ),
                                ),
                              ),
                            ],
                            // Emotion icon
                            if (emotion != null && emotion.isNotEmpty && post.emotion != null) ...[
                              const SizedBox(width: 6),
                              Icon(
                                SentioConstants.getEmotionIcon(post.emotion!),
                                size: 13,
                                color: Color(emotion['color'] as int),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                        ],
                      ),
                    ),
                  ),
                // -- Overflow menu: report / block --
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_horiz_rounded, color: SentioColors.textTertiary, size: 20),
                  color: SentioColors.surface,
                  onSelected: (value) {
                    if (value == 'report') {
                      _reportPost(post.id);
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
                          Text('Reportar', style: GoogleFonts.manrope(color: SentioColors.textPrimary)),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'block',
                      child: Row(
                        children: [
                          const Icon(Icons.block_rounded, size: 18, color: SentioColors.error),
                          const SizedBox(width: 10),
                          Text('Bloquear', style: GoogleFonts.manrope(color: SentioColors.error)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),

            // -- Content --
            if (post.content != null && post.content!.isNotEmpty) ...[
              const SizedBox(height: 14),
              Text(
                post.content!,
                style: GoogleFonts.manrope(
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  height: 1.55,
                  color: SentioColors.textPrimary,
                ),
              ),
            ],

            // -- Image --
            if (post.imageUrls.isNotEmpty) ...[
              const SizedBox(height: 14),
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: CachedNetworkImage(
                  imageUrl: post.imageUrls.first,
                  width: double.infinity,
                  height: 200,
                  fit: BoxFit.cover,
                  placeholder: (_, __) => Container(
                    height: 200,
                    decoration: BoxDecoration(
                      color: SentioColors.card,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Center(
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: SentioColors.primary,
                      ),
                    ),
                  ),
                  errorWidget: (_, __, ___) => Container(
                    height: 200,
                    decoration: BoxDecoration(
                      color: SentioColors.card,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(
                      Icons.image_not_supported_rounded,
                      color: SentioColors.textTertiary,
                    ),
                  ),
                ),
              ),
            ],

            // -- Action row: like, comment, share --
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Row(
                children: [
                  // Like
                  _buildActionButton(
                    icon: post.isLikedByMe
                        ? Icons.favorite_rounded
                        : Icons.favorite_border_rounded,
                    label: '${post.likesCount}',
                    isActive: post.isLikedByMe,
                    activeColor: SentioColors.error,
                    onTap: () => provider.togglePostLike(post.id),
                  ),
                  const SizedBox(width: 20),
                  // Comment
                  _buildActionButton(
                    icon: Icons.chat_bubble_outline_rounded,
                    label: '${post.commentsCount}',
                    onTap: () => context.push('/community/post/${post.id}'),
                  ),
                  const SizedBox(width: 20),
                  // Share
                  _buildActionButton(
                    icon: Icons.share_outlined,
                    label: '',
                    onTap: () {
                      SharePlus.instance.share(
                        ShareParams(
                          text: '${post.userName} en Sentio:\n\n"${post.content}"\n\nDescargá Sentio para conectar con emprendedores.',
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============ ACTION BUTTON ============

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    bool isActive = false,
    Color? activeColor,
    required VoidCallback onTap,
  }) {
    final color = isActive
        ? (activeColor ?? SentioColors.accent)
        : SentioColors.textTertiary;

    return GestureDetector(
      onTap: onTap,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 19, color: color),
          if (label.isNotEmpty) ...[
            const SizedBox(width: 5),
            Text(
              label,
              style: GoogleFonts.manrope(
                fontSize: 13,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                color: color,
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ============ AVATAR ============

  Widget _buildAvatar(String? url, String name, double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: SentioColors.primary.withValues(alpha: 0.15),
        border: Border.all(
          color: Colors.white.withOpacity(0.08),
          width: 1,
        ),
      ),
      child: ClipOval(
        child: url != null
            ? CachedNetworkImage(
                imageUrl: url,
                fit: BoxFit.cover,
                placeholder: (_, __) => Center(
                  child: Text(
                    name.isNotEmpty ? name[0].toUpperCase() : '?',
                    style: GoogleFonts.manrope(
                      fontSize: size * 0.38,
                      fontWeight: FontWeight.w700,
                      color: SentioColors.primary,
                    ),
                  ),
                ),
                errorWidget: (_, __, ___) => Center(
                  child: Text(
                    name.isNotEmpty ? name[0].toUpperCase() : '?',
                    style: GoogleFonts.manrope(
                      fontSize: size * 0.38,
                      fontWeight: FontWeight.w700,
                      color: SentioColors.primary,
                    ),
                  ),
                ),
              )
            : Center(
                child: Text(
                  name.isNotEmpty ? name[0].toUpperCase() : '?',
                  style: GoogleFonts.manrope(
                    fontSize: size * 0.38,
                    fontWeight: FontWeight.w700,
                    color: SentioColors.primary,
                  ),
                ),
              ),
      ),
    );
  }
}

// ══════════════════════════════════════
// VALIDATION GATE (shown when profile not approved)
// ══════════════════════════════════════

class _ValidationGate extends StatelessWidget {
  final String status;
  final Profile? profile;

  const _ValidationGate({required this.status, required this.profile});

  @override
  Widget build(BuildContext context) {
    final isPending = status == 'pending';
    final isRejected = status == 'rejected';

    final Color accentColor;
    final IconData icon;
    final String title;
    final String message;
    final String? ctaLabel;

    if (isPending) {
      accentColor = SentioColors.primary;
      icon = Icons.hourglass_top_rounded;
      title = 'Tu perfil está en revisión';
      message = 'Nuestro equipo está revisando tu solicitud. Te avisaremos cuando esté aprobada — normalmente menos de 24 horas.';
      ctaLabel = null;
    } else if (isRejected) {
      accentColor = SentioColors.warning;
      icon = Icons.info_outline_rounded;
      title = 'Necesitamos más información';
      message = profile?.validationRejectionReason ??
          'Revisamos tu perfil y no encontramos suficiente información para confirmar que estás construyendo un negocio. Si estás empezando y todavía no tenés mucho para mostrar, mandános una descripción breve de qué estás construyendo, para quién, y cuál es tu mayor desafío hoy.';
      ctaLabel = 'Volver a intentarlo';
    } else {
      // not_submitted
      accentColor = SentioColors.accent;
      icon = Icons.workspace_premium_rounded;
      title = 'Comunidad cerrada';
      message = 'B2Better es un espacio para emprendedores, freelancers y profesionales que están construyendo algo real. Validá tu perfil para acceder.';
      ctaLabel = 'Validar mi perfil';
    }

    return Scaffold(
      backgroundColor: SentioColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      accentColor.withValues(alpha: 0.3),
                      accentColor.withValues(alpha: 0.05),
                      Colors.transparent,
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: accentColor.withValues(alpha: 0.3),
                      blurRadius: 40,
                      spreadRadius: 4,
                    ),
                  ],
                ),
                child: Icon(icon, color: accentColor, size: 54),
              ),
              const SizedBox(height: 32),
              Text(
                title,
                textAlign: TextAlign.center,
                style: GoogleFonts.manrope(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: SentioColors.textPrimary,
                  letterSpacing: -0.7,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                message,
                textAlign: TextAlign.center,
                style: GoogleFonts.manrope(
                  fontSize: 14,
                  color: SentioColors.textSecondary,
                  height: 1.6,
                ),
              ),
              if (isPending && profile?.validationAnswer != null) ...[
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: SentioColors.surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: SentioColors.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.history_rounded, size: 14, color: SentioColors.textTertiary),
                          const SizedBox(width: 6),
                          Text(
                            'Tu respuesta',
                            style: GoogleFonts.manrope(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: SentioColors.textTertiary,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        profile!.validationAnswer!,
                        style: GoogleFonts.manrope(
                          fontSize: 13,
                          color: SentioColors.textPrimary,
                          fontStyle: FontStyle.italic,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              if (ctaLabel != null) ...[
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => context.push('/community/validate'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: accentColor,
                      foregroundColor: accentColor == SentioColors.accent ? Colors.black : Colors.white,
                    ),
                    child: Text(
                      ctaLabel,
                      style: GoogleFonts.manrope(
                        fontWeight: FontWeight.w800,
                        color: accentColor == SentioColors.accent ? Colors.black : Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
