class UserGoal {
  final String id;
  final String title;
  final bool isDaily;
  final bool isCompleted;
  final DateTime? completedAt;
  final String source;
  final DateTime createdAt;

  UserGoal({
    required this.id,
    required this.title,
    required this.isDaily,
    required this.isCompleted,
    this.completedAt,
    this.source = 'manual',
    required this.createdAt,
  });

  factory UserGoal.fromJson(Map<String, dynamic> j) => UserGoal(
        id: j['id'] as String,
        title: (j['title'] ?? '') as String,
        isDaily: (j['is_daily'] ?? false) as bool,
        isCompleted: (j['is_completed'] ?? false) as bool,
        completedAt: j['completed_at'] != null
            ? DateTime.tryParse(j['completed_at'] as String)
            : null,
        source: (j['source'] ?? 'manual') as String,
        createdAt:
            DateTime.tryParse((j['created_at'] ?? '') as String) ?? DateTime.now(),
      );
}
