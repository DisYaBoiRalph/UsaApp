import '../../domain/entities/chat_message.dart';

class ChatMessageModel extends ChatMessage {
  const ChatMessageModel({
    required super.id,
    required super.sender,
    required super.content,
    required super.sentAt,
  });

  factory ChatMessageModel.fromEntity(ChatMessage entity) {
    return ChatMessageModel(
      id: entity.id,
      sender: entity.sender,
      content: entity.content,
      sentAt: entity.sentAt,
    );
  }

  ChatMessage toEntity() {
    return ChatMessage(
      id: id,
      sender: sender,
      content: content,
      sentAt: sentAt,
    );
  }
}
