class CommunityStory {
  final String id;
  final String userId;
  final String userName;
  final String? userAvatar;
  final String imageUrl;
  final String? textOverlay;
  final DateTime createdAt;
  final DateTime expiresAt;
  final bool isViewed;

  CommunityStory({
    required this.id,
    required this.userId,
    required this.userName,
    this.userAvatar,
    required this.imageUrl,
    this.textOverlay,
    DateTime? createdAt,
    DateTime? expiresAt,
    this.isViewed = false,
  })  : createdAt = createdAt ?? DateTime.now(),
        expiresAt = expiresAt ?? DateTime.now().add(const Duration(hours: 24));

  CommunityStory copyWith({bool? isViewed}) {
    return CommunityStory(
      id: id,
      userId: userId,
      userName: userName,
      userAvatar: userAvatar,
      imageUrl: imageUrl,
      textOverlay: textOverlay,
      createdAt: createdAt,
      expiresAt: expiresAt,
      isViewed: isViewed ?? this.isViewed,
    );
  }
}
