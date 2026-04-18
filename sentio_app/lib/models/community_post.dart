class CommunityPost {
  final String id;
  final String userId;
  final String userName;
  final String? userAvatar;
  final String? content;
  final List<String> imageUrls;
  final int likesCount;
  final int commentsCount;
  final bool isLikedByMe;
  final String? emotion;
  final String? category;
  final DateTime createdAt;

  CommunityPost({
    required this.id,
    required this.userId,
    required this.userName,
    this.userAvatar,
    this.content,
    this.imageUrls = const [],
    this.likesCount = 0,
    this.commentsCount = 0,
    this.isLikedByMe = false,
    this.emotion,
    this.category,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  factory CommunityPost.fromJson(Map<String, dynamic> json) {
    return CommunityPost(
      id: json['id'],
      userId: json['user_id'],
      userName: json['user_name'] ?? '',
      userAvatar: json['user_avatar'],
      content: json['content'],
      imageUrls: List<String>.from(json['image_urls'] ?? []),
      likesCount: json['likes_count'] ?? 0,
      commentsCount: json['comments_count'] ?? 0,
      isLikedByMe: json['is_liked_by_me'] ?? false,
      emotion: json['emotion'],
      category: json['category'],
      createdAt: DateTime.parse(json['created_at'] ?? DateTime.now().toIso8601String()),
    );
  }

  CommunityPost copyWith({
    int? likesCount,
    int? commentsCount,
    bool? isLikedByMe,
  }) {
    return CommunityPost(
      id: id,
      userId: userId,
      userName: userName,
      userAvatar: userAvatar,
      content: content,
      imageUrls: imageUrls,
      likesCount: likesCount ?? this.likesCount,
      commentsCount: commentsCount ?? this.commentsCount,
      isLikedByMe: isLikedByMe ?? this.isLikedByMe,
      emotion: emotion,
      category: category,
      createdAt: createdAt,
    );
  }
}
