enum MessageRole {
  user,
  assistant,
  system,
}

class ChatMessage {
  final String id;
  final String text;
  final MessageRole role;
  final DateTime timestamp;
  final double? tokensPerSecond;
  final bool isThinking;

  ChatMessage({
    required this.id,
    required this.text,
    required this.role,
    required this.timestamp,
    this.tokensPerSecond,
    this.isThinking = false,
  });

  ChatMessage copyWith({
    String? id,
    String? text,
    MessageRole? role,
    DateTime? timestamp,
    double? tokensPerSecond,
    bool? isThinking,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      text: text ?? this.text,
      role: role ?? this.role,
      timestamp: timestamp ?? this.timestamp,
      tokensPerSecond: tokensPerSecond ?? this.tokensPerSecond,
      isThinking: isThinking ?? this.isThinking,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'text': text,
    'role': role.name,
    'timestamp': timestamp.toIso8601String(),
    'tokensPerSecond': tokensPerSecond,
  };

  factory ChatMessage.fromJson(Map<String, dynamic> json) => ChatMessage(
    id: json['id'] as String,
    text: json['text'] as String,
    role: MessageRole.values.firstWhere((r) => r.name == json['role']),
    timestamp: DateTime.parse(json['timestamp'] as String),
    tokensPerSecond: (json['tokensPerSecond'] as num?)?.toDouble(),
  );
}
