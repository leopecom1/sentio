class JournalEntry {
  final String id;
  final String userId;
  final String content;
  final String? promptUsed;
  final String? dominantEmotion;
  final List<String> tags;
  final int wordCount;
  final DateTime createdAt;
  final DateTime updatedAt;

  JournalEntry({
    required this.id,
    required this.userId,
    required this.content,
    this.promptUsed,
    this.dominantEmotion,
    this.tags = const [],
    this.wordCount = 0,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  factory JournalEntry.fromJson(Map<String, dynamic> json) {
    return JournalEntry(
      id: json['id'],
      userId: json['user_id'],
      content: json['content'],
      promptUsed: json['prompt_used'],
      dominantEmotion: json['dominant_emotion'],
      tags: List<String>.from(json['tags'] ?? []),
      wordCount: json['word_count'] ?? 0,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() => {
    'user_id': userId,
    'content': content,
    'prompt_used': promptUsed,
    'dominant_emotion': dominantEmotion,
    'tags': tags,
    'word_count': wordCount,
  };
}
