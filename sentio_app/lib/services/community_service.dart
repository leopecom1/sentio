import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:sentio_app/models/community_post.dart';
import 'package:sentio_app/models/community_comment.dart';
import 'package:sentio_app/models/community_story.dart';
import 'package:sentio_app/models/community_user.dart';

class CommunityService {
  CommunityService._();
  static final CommunityService instance = CommunityService._();

  final _supabase = Supabase.instance.client;
  String? get _userId => _supabase.auth.currentUser?.id;

  // ── Posts ──

  Future<List<CommunityPost>> loadPosts({
    String? category,
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      var query = _supabase
          .from('community_posts')
          .select('*, profiles!community_posts_user_id_fkey(full_name, avatar_url)')
          .eq('is_visible', true);

      if (category != null && category != 'Todo') {
        query = query.eq('category', category.toLowerCase());
      }

      final data = await query
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);

      // Get user's liked posts
      final likedIds = await _getUserLikedPostIds();

      return (data as List).map((p) {
        final profile = p['profiles'] as Map<String, dynamic>?;
        return CommunityPost(
          id: p['id'],
          userId: p['user_id'],
          userName: profile?['full_name'] ?? 'Usuario',
          userAvatar: profile?['avatar_url'],
          content: p['content'],
          imageUrls: List<String>.from(p['image_urls'] ?? []),
          likesCount: p['likes_count'] ?? 0,
          commentsCount: p['comments_count'] ?? 0,
          isLikedByMe: likedIds.contains(p['id']),
          emotion: p['emotion'],
          category: p['category'],
          createdAt: DateTime.parse(p['created_at']),
        );
      }).toList();
    } catch (e) {
      debugPrint('Error loading community posts: $e');
      return [];
    }
  }

  Future<Set<String>> _getUserLikedPostIds() async {
    if (_userId == null) return {};
    try {
      final data = await _supabase
          .from('community_likes')
          .select('post_id')
          .eq('user_id', _userId!);
      return (data as List).map((d) => d['post_id'] as String).toSet();
    } catch (_) {
      return {};
    }
  }

  Future<CommunityPost?> createPost({
    required String content,
    List<String>? imageUrls,
    String? emotion,
    String? category,
  }) async {
    if (_userId == null) return null;
    try {
      final data = await _supabase.from('community_posts').insert({
        'user_id': _userId,
        'content': content,
        'image_urls': imageUrls ?? [],
        'emotion': emotion,
        'category': category ?? 'general',
      }).select('*, profiles!community_posts_user_id_fkey(full_name, avatar_url)').single();

      final profile = data['profiles'] as Map<String, dynamic>?;
      return CommunityPost(
        id: data['id'],
        userId: data['user_id'],
        userName: profile?['full_name'] ?? 'Usuario',
        userAvatar: profile?['avatar_url'],
        content: data['content'],
        imageUrls: List<String>.from(data['image_urls'] ?? []),
        likesCount: 0,
        commentsCount: 0,
        emotion: data['emotion'],
        category: data['category'],
        createdAt: DateTime.parse(data['created_at']),
      );
    } catch (e) {
      debugPrint('Error creating post: $e');
      return null;
    }
  }

  // ── Likes ──

  Future<bool> toggleLike(String postId) async {
    if (_userId == null) return false;
    try {
      final existing = await _supabase
          .from('community_likes')
          .select('id')
          .eq('post_id', postId)
          .eq('user_id', _userId!);

      if ((existing as List).isNotEmpty) {
        await _supabase
            .from('community_likes')
            .delete()
            .eq('post_id', postId)
            .eq('user_id', _userId!);
        return false; // unliked
      } else {
        await _supabase.from('community_likes').insert({
          'post_id': postId,
          'user_id': _userId,
        });
        return true; // liked
      }
    } catch (e) {
      debugPrint('Error toggling like: $e');
      return false;
    }
  }

  // ── Comments ──

  Future<List<CommunityComment>> loadComments(String postId) async {
    try {
      final data = await _supabase
          .from('community_comments')
          .select('*, profiles!community_comments_user_id_fkey(full_name, avatar_url)')
          .eq('post_id', postId)
          .order('created_at');

      return (data as List).map((c) {
        final profile = c['profiles'] as Map<String, dynamic>?;
        return CommunityComment(
          id: c['id'],
          postId: c['post_id'],
          userId: c['user_id'],
          userName: profile?['full_name'] ?? 'Usuario',
          userAvatar: profile?['avatar_url'],
          content: c['content'],
          createdAt: DateTime.parse(c['created_at']),
        );
      }).toList();
    } catch (e) {
      debugPrint('Error loading comments: $e');
      return [];
    }
  }

  Future<CommunityComment?> addComment(String postId, String content) async {
    if (_userId == null) return null;
    try {
      final data = await _supabase.from('community_comments').insert({
        'post_id': postId,
        'user_id': _userId,
        'content': content,
      }).select('*, profiles!community_comments_user_id_fkey(full_name, avatar_url)').single();

      final profile = data['profiles'] as Map<String, dynamic>?;
      return CommunityComment(
        id: data['id'],
        postId: data['post_id'],
        userId: data['user_id'],
        userName: profile?['full_name'] ?? 'Usuario',
        userAvatar: profile?['avatar_url'],
        content: data['content'],
        createdAt: DateTime.parse(data['created_at']),
      );
    } catch (e) {
      debugPrint('Error adding comment: $e');
      return null;
    }
  }

  // ── Follows ──

  Future<bool> toggleFollow(String targetUserId) async {
    if (_userId == null) return false;
    try {
      final existing = await _supabase
          .from('community_follows')
          .select('id')
          .eq('follower_id', _userId!)
          .eq('following_id', targetUserId);

      if ((existing as List).isNotEmpty) {
        await _supabase
            .from('community_follows')
            .delete()
            .eq('follower_id', _userId!)
            .eq('following_id', targetUserId);
        return false; // unfollowed
      } else {
        await _supabase.from('community_follows').insert({
          'follower_id': _userId,
          'following_id': targetUserId,
        });
        return true; // followed
      }
    } catch (e) {
      debugPrint('Error toggling follow: $e');
      return false;
    }
  }

  Future<Set<String>> getFollowedUserIds() async {
    if (_userId == null) return {};
    try {
      final data = await _supabase
          .from('community_follows')
          .select('following_id')
          .eq('follower_id', _userId!);
      return (data as List).map((d) => d['following_id'] as String).toSet();
    } catch (_) {
      return {};
    }
  }

  // ── User profile ──

  Future<CommunityUser?> loadUserProfile(String userId) async {
    try {
      final data = await _supabase
          .from('profiles')
          .select('id, full_name, avatar_url, bio, followers_count, following_count, posts_count')
          .eq('id', userId)
          .single();

      final followedIds = await getFollowedUserIds();

      return CommunityUser(
        id: data['id'],
        fullName: data['full_name'] ?? 'Usuario',
        avatarUrl: data['avatar_url'],
        bio: data['bio'],
        followersCount: data['followers_count'] ?? 0,
        followingCount: data['following_count'] ?? 0,
        postsCount: data['posts_count'] ?? 0,
        isFollowedByMe: followedIds.contains(data['id']),
      );
    } catch (e) {
      debugPrint('Error loading user profile: $e');
      return null;
    }
  }

  // ── Stories ──

  Future<List<CommunityStory>> loadStories() async {
    try {
      final data = await _supabase
          .from('community_stories')
          .select('*, profiles!community_stories_user_id_fkey(full_name, avatar_url)')
          .gt('expires_at', DateTime.now().toIso8601String())
          .order('created_at', ascending: false);

      return (data as List).map((s) {
        final profile = s['profiles'] as Map<String, dynamic>?;
        return CommunityStory(
          id: s['id'],
          userId: s['user_id'],
          userName: profile?['full_name'] ?? 'Usuario',
          userAvatar: profile?['avatar_url'],
          imageUrl: s['image_url'],
          textOverlay: s['text_overlay'],
          createdAt: DateTime.parse(s['created_at']),
          expiresAt: DateTime.parse(s['expires_at']),
        );
      }).toList();
    } catch (e) {
      debugPrint('Error loading stories: $e');
      return [];
    }
  }

  // ── Stories: create ──

  Future<CommunityStory?> createStory({
    required String textOverlay,
    String? imageUrl,
  }) async {
    if (_userId == null) return null;
    try {
      final data = await _supabase.from('community_stories').insert({
        'user_id': _userId,
        'text_overlay': textOverlay,
        'image_url': imageUrl ?? '',
        'expires_at': DateTime.now().add(const Duration(hours: 24)).toIso8601String(),
      }).select('*, profiles!community_stories_user_id_fkey(full_name, avatar_url)').single();

      final profile = data['profiles'] as Map<String, dynamic>?;
      return CommunityStory(
        id: data['id'],
        userId: data['user_id'],
        userName: profile?['full_name'] ?? 'Usuario',
        userAvatar: profile?['avatar_url'],
        imageUrl: data['image_url'] ?? '',
        textOverlay: data['text_overlay'],
        createdAt: DateTime.parse(data['created_at']),
        expiresAt: DateTime.parse(data['expires_at']),
      );
    } catch (e) {
      debugPrint('Error creating story: $e');
      return null;
    }
  }

  // ── Image upload ──

  Future<String?> uploadImage(String fileName, Uint8List bytes) async {
    try {
      final path = '${_userId}/$fileName';
      await _supabase.storage
          .from('community-images')
          .uploadBinary(path, bytes);
      return _supabase.storage
          .from('community-images')
          .getPublicUrl(path);
    } catch (e) {
      debugPrint('Error uploading image: $e');
      return null;
    }
  }

  // ── Posts by user ──

  Future<List<CommunityPost>> loadPostsByUser(String userId) async {
    try {
      final data = await _supabase
          .from('community_posts')
          .select('*, profiles!community_posts_user_id_fkey(full_name, avatar_url)')
          .eq('user_id', userId)
          .eq('is_visible', true)
          .order('created_at', ascending: false);

      final likedIds = await _getUserLikedPostIds();

      return (data as List).map((p) {
        final profile = p['profiles'] as Map<String, dynamic>?;
        return CommunityPost(
          id: p['id'],
          userId: p['user_id'],
          userName: profile?['full_name'] ?? 'Usuario',
          userAvatar: profile?['avatar_url'],
          content: p['content'],
          imageUrls: List<String>.from(p['image_urls'] ?? []),
          likesCount: p['likes_count'] ?? 0,
          commentsCount: p['comments_count'] ?? 0,
          isLikedByMe: likedIds.contains(p['id']),
          emotion: p['emotion'],
          category: p['category'],
          createdAt: DateTime.parse(p['created_at']),
        );
      }).toList();
    } catch (e) {
      debugPrint('Error loading user posts: $e');
      return [];
    }
  }
}
