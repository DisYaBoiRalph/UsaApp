class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.sender,
    required this.content,
    required this.sentAt,
  });

  final String id;
  final String sender;
  final String content;
  final DateTime sentAt;

  ChatMessage copyWith({
    String? id,
    String? sender,
    String? content,
    DateTime? sentAt,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      sender: sender ?? this.sender,
      content: content ?? this.content,
      sentAt: sentAt ?? this.sentAt,
    );
  }
}
