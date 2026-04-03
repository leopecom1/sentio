import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:sentio_app/config/theme.dart';
import 'package:sentio_app/config/constants.dart';
import 'package:sentio_app/providers/app_provider.dart';
import 'package:sentio_app/models/community_post.dart';
import 'package:sentio_app/models/community_story.dart';
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
    final allPosts = provider.communityPosts;
    final stories = provider.communityStories;
    final selectedCategory = provider.selectedCommunityCategory;

    // Filter posts by category
    final posts = selectedCategory == 'Todo'
        ? allPosts
        : allPosts.where((p) => _postCategory(p) == selectedCategory).toList();

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
                      itemCount: stories.length + 1,
                      itemBuilder: (context, index) {
                        if (index == 0) {
                          return _buildAddStoryCircle();
                        }
                        final story = stories[index - 1];
                        return _buildStoryCircle(story, index - 1);
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

  Widget _buildStoryCircle(CommunityStory story, int storyIndex) {
    return GestureDetector(
      onTap: () => context.push('/community/story/$storyIndex'),
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
                gradient: story.isViewed
                    ? null
                    : const LinearGradient(
                        colors: [SentioColors.primary, SentioColors.accent],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                border: story.isViewed
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
                  color: story.isViewed ? SentioColors.textTertiary : SentioColors.textPrimary,
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
            GestureDetector(
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
                            // Emotion emoji
                            if (emotion != null && emotion.isNotEmpty) ...[
                              const SizedBox(width: 6),
                              Text(emotion['emoji'] ?? '', style: const TextStyle(fontSize: 13)),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
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
