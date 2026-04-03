class Checkin {
  final String id;
  final String userId;
  final String primaryEmotion;
  final int energyLevel;
  final int stressLevel;
  final int? mentalClarity;
  final int? motivationLevel;
  final int? financialPressure;
  final int? controlFeeling;
  final int? dayQuality;
  final String? note;
  final String? notePrompt;
  final bool isDeep;
  final bool isCrisis;
  final DateTime createdAt;

  Checkin({
    required this.id,
    required this.userId,
    required this.primaryEmotion,
    required this.energyLevel,
    required this.stressLevel,
    this.mentalClarity,
    this.motivationLevel,
    this.financialPressure,
    this.controlFeeling,
    this.dayQuality,
    this.note,
    this.notePrompt,
    this.isDeep = false,
    this.isCrisis = false,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  factory Checkin.fromJson(Map<String, dynamic> json) {
    return Checkin(
      id: json['id'],
      userId: json['user_id'],
      primaryEmotion: json['primary_emotion'],
      energyLevel: json['energy_level'],
      stressLevel: json['stress_level'],
      mentalClarity: json['mental_clarity'],
      motivationLevel: json['motivation_level'],
      financialPressure: json['financial_pressure'],
      controlFeeling: json['control_feeling'],
      dayQuality: json['day_quality'],
      note: json['note'],
      notePrompt: json['note_prompt'],
      isDeep: json['is_deep'] ?? false,
      isCrisis: json['is_crisis'] ?? false,
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() => {
    'user_id': userId,
    'primary_emotion': primaryEmotion,
    'energy_level': energyLevel,
    'stress_level': stressLevel,
    'mental_clarity': mentalClarity,
    'motivation_level': motivationLevel,
    'financial_pressure': financialPressure,
    'control_feeling': controlFeeling,
    'day_quality': dayQuality,
    'note': note,
    'note_prompt': notePrompt,
    'is_deep': isDeep,
    'is_crisis': isCrisis,
  };
}
