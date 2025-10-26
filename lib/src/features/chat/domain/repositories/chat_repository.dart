import 'dart:async';

import '../entities/chat_message.dart';

abstract class ChatRepository {
  Stream<List<ChatMessage>> watchMessages(String conversationId);
  Future<void> sendMessage(String conversationId, ChatMessage message);
  Future<void> clearConversation(String conversationId);
}
