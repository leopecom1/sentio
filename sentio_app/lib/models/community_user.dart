class CommunityUser {
  final String id;
  final String fullName;
  final String? avatarUrl;
  final String? bio;
  final int followersCount;
  final int followingCount;
  final int postsCount;
  final bool isFollowedByMe;

  CommunityUser({
    required this.id,
    required this.fullName,
    this.avatarUrl,
    this.bio,
    this.followersCount = 0,
    this.followingCount = 0,
    this.postsCount = 0,
    this.isFollowedByMe = false,
  });

  CommunityUser copyWith({
    bool? isFollowedByMe,
    int? followersCount,
  }) {
    return CommunityUser(
      id: id,
      fullName: fullName,
      avatarUrl: avatarUrl,
      bio: bio,
      followersCount: followersCount ?? this.followersCount,
      followingCount: followingCount,
      postsCount: postsCount,
      isFollowedByMe: isFollowedByMe ?? this.isFollowedByMe,
    );
  }

  String get firstName => fullName.split(' ').first;
}
