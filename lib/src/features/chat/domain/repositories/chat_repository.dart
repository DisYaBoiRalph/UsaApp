import 'dart:async';

import '../entities/chat_message.dart';

abstract class ChatRepository {
  Stream<List<ChatMessage>> watchMessages();
  Future<void> sendMessage(ChatMessage message);
}
