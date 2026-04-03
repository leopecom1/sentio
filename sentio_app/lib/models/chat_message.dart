class ChatConversation {
  final String id;
  final String userId;
  final String? title;
  final String? initialEmotion;
  final String? summary;
  final int messageCount;
  final bool isCrisis;
  final DateTime createdAt;
  final DateTime updatedAt;

  ChatConversation({
    required this.id,
    required this.userId,
    this.title,
    this.initialEmotion,
    this.summary,
    this.messageCount = 0,
    this.isCrisis = false,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  factory ChatConversation.fromJson(Map<String, dynamic> json) {
    return ChatConversation(
      id: json['id'],
      userId: json['user_id'],
      title: json['title'],
      initialEmotion: json['initial_emotion'],
      summary: json['summary'],
      messageCount: json['message_count'] ?? 0,
      isCrisis: json['is_crisis'] ?? false,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }
}

class ChatMessage {
  final String id;
  final String conversationId;
  final String userId;
  final String role; // 'user' or 'assistant'
  final String content;
  final DateTime createdAt;

  ChatMessage({
    required this.id,
    required this.conversationId,
    required this.userId,
    required this.role,
    required this.content,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'],
      conversationId: json['conversation_id'],
      userId: json['user_id'],
      role: json['role'],
      content: json['content'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() => {
    'conversation_id': conversationId,
    'user_id': userId,
    'role': role,
    'content': content,
  };

  bool get isUser => role == 'user';
  bool get isAssistant => role == 'assistant';
}
