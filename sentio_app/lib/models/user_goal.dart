class UserGoal {
  final String id;
  final String title;
  final bool isDaily;
  final bool isCompleted;
  final DateTime? completedAt;
  final String source;
  final String recurrence; // 'none' | 'daily' | 'weekly' | 'monthly' | 'custom'
  final int? intervalDays; // para recurrence == 'custom' (cada N días)
  final DateTime createdAt;

  UserGoal({
    required this.id,
    required this.title,
    required this.isDaily,
    required this.isCompleted,
    this.completedAt,
    this.source = 'manual',
    this.recurrence = 'none',
    this.intervalDays,
    required this.createdAt,
  });

  bool get isRecurring => recurrence != 'none';

  /// Etiqueta legible de la frecuencia.
  String get recurrenceLabel {
    switch (recurrence) {
      case 'daily':
        return 'Diaria';
      case 'weekly':
        return 'Semanal';
      case 'monthly':
        return 'Mensual';
      case 'custom':
        return intervalDays != null ? 'Cada $intervalDays días' : 'Personalizada';
      default:
        return 'Una vez';
    }
  }

  factory UserGoal.fromJson(Map<String, dynamic> j) => UserGoal(
        id: j['id'] as String,
        title: (j['title'] ?? '') as String,
        isDaily: (j['is_daily'] ?? false) as bool,
        isCompleted: (j['is_completed'] ?? false) as bool,
        completedAt: j['completed_at'] != null
            ? DateTime.tryParse(j['completed_at'] as String)
            : null,
        source: (j['source'] ?? 'manual') as String,
        recurrence: (j['recurrence'] ?? 'none') as String,
        intervalDays: j['interval_days'] as int?,
        createdAt: DateTime.tryParse((j['created_at'] ?? '') as String) ??
            DateTime.now(),
      );
}
