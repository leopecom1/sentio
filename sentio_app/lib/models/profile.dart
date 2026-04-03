class Profile {
  final String id;
  final String? fullName;
  final String? avatarUrl;
  final String timezone;
  final bool onboardingCompleted;
  final List<String> pressureTypes;
  final String? currentMood;
  final int? initialEnergy;
  final List<String> goals;
  final String preferredCompanionStyle;
  final String plan;
  final DateTime? planExpiresAt;
  final int checkinStreak;
  final int longestStreak;
  final int totalCheckins;
  final int totalJournalEntries;
  final int totalChatMessages;
  final int totalToolsUsed;
  final DateTime? lastActiveAt;
  final bool morningReminder;
  final bool eveningReminder;
  final String theme;
  final String language;
  final String? bio;
  final int postsCount;
  final int followersCount;
  final int followingCount;
  final int totalTransactions;
  final String preferredCurrency;
  final DateTime createdAt;

  Profile({
    required this.id,
    this.fullName,
    this.avatarUrl,
    this.timezone = 'America/Argentina/Buenos_Aires',
    this.onboardingCompleted = false,
    this.pressureTypes = const [],
    this.currentMood,
    this.initialEnergy,
    this.goals = const [],
    this.preferredCompanionStyle = 'balanced',
    this.plan = 'free',
    this.planExpiresAt,
    this.checkinStreak = 0,
    this.longestStreak = 0,
    this.totalCheckins = 0,
    this.totalJournalEntries = 0,
    this.totalChatMessages = 0,
    this.totalToolsUsed = 0,
    this.lastActiveAt,
    this.morningReminder = true,
    this.eveningReminder = true,
    this.theme = 'light',
    this.language = 'es',
    this.bio,
    this.postsCount = 0,
    this.followersCount = 0,
    this.followingCount = 0,
    this.totalTransactions = 0,
    this.preferredCurrency = 'ARS',
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  factory Profile.fromJson(Map<String, dynamic> json) {
    return Profile(
      id: json['id'],
      fullName: json['full_name'],
      avatarUrl: json['avatar_url'],
      timezone: json['timezone'] ?? 'America/Argentina/Buenos_Aires',
      onboardingCompleted: json['onboarding_completed'] ?? false,
      pressureTypes: List<String>.from(json['pressure_types'] ?? []),
      currentMood: json['current_mood'],
      initialEnergy: json['initial_energy'],
      goals: List<String>.from(json['goals'] ?? []),
      preferredCompanionStyle: json['preferred_companion_style'] ?? 'balanced',
      plan: json['plan'] ?? 'free',
      planExpiresAt: json['plan_expires_at'] != null
          ? DateTime.parse(json['plan_expires_at'])
          : null,
      checkinStreak: json['checkin_streak'] ?? 0,
      longestStreak: json['longest_streak'] ?? 0,
      totalCheckins: json['total_checkins'] ?? 0,
      totalJournalEntries: json['total_journal_entries'] ?? 0,
      totalChatMessages: json['total_chat_messages'] ?? 0,
      totalToolsUsed: json['total_tools_used'] ?? 0,
      lastActiveAt: json['last_active_at'] != null
          ? DateTime.parse(json['last_active_at'])
          : null,
      morningReminder: json['morning_reminder'] ?? true,
      eveningReminder: json['evening_reminder'] ?? true,
      theme: json['theme'] ?? 'light',
      language: json['language'] ?? 'es',
      bio: json['bio'],
      postsCount: json['posts_count'] ?? 0,
      followersCount: json['followers_count'] ?? 0,
      followingCount: json['following_count'] ?? 0,
      totalTransactions: json['total_transactions'] ?? 0,
      preferredCurrency: json['preferred_currency'] ?? 'ARS',
      createdAt: DateTime.parse(json['created_at'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'full_name': fullName,
    'avatar_url': avatarUrl,
    'timezone': timezone,
    'onboarding_completed': onboardingCompleted,
    'pressure_types': pressureTypes,
    'current_mood': currentMood,
    'initial_energy': initialEnergy,
    'goals': goals,
    'preferred_companion_style': preferredCompanionStyle,
    'plan': plan,
    'morning_reminder': morningReminder,
    'evening_reminder': eveningReminder,
    'theme': theme,
    'language': language,
  };

  String get firstName => fullName?.split(' ').first ?? 'amigo';
  bool get isPremium => plan == 'premium';
}
