import '../../domain/entities/chat_message.dart';

class ChatMessageModel extends ChatMessage {
  const ChatMessageModel({
    required super.id,
    required super.conversationId,
    required super.senderId,
    required super.sender,
    required super.content,
    required super.sentAt,
  });

  factory ChatMessageModel.fromEntity(ChatMessage entity) {
    return ChatMessageModel(
      id: entity.id,
      conversationId: entity.conversationId,
      senderId: entity.senderId,
      sender: entity.sender,
      content: entity.content,
      sentAt: entity.sentAt,
    );
  }

  factory ChatMessageModel.fromJson(Map<String, dynamic> json) {
    final sentAtRaw = json['sentAt'];
    return ChatMessageModel(
      id: json['id'] as String,
      conversationId: json['conversationId'] as String,
      senderId: json['senderId'] as String,
      sender: json['sender'] as String,
      content: json['content'] as String,
      sentAt: sentAtRaw is String
          ? DateTime.tryParse(sentAtRaw)?.toUtc() ?? DateTime.now().toUtc()
          : DateTime.now().toUtc(),
    );
  }

  ChatMessage toEntity() {
    return ChatMessage(
      id: id,
      conversationId: conversationId,
      senderId: senderId,
      sender: sender,
      content: content,
      sentAt: sentAt,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'conversationId': conversationId,
      'senderId': senderId,
      'sender': sender,
      'content': content,
      'sentAt': sentAt.toUtc().toIso8601String(),
    };
  }
}
