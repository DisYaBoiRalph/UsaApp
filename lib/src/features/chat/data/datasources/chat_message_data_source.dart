import 'dart:async';

import '../models/chat_message_model.dart';

abstract class ChatMessageDataSource {
  Stream<List<ChatMessageModel>> watchMessages();
  Future<void> saveMessage(ChatMessageModel message);
}

class InMemoryChatMessageDataSource implements ChatMessageDataSource {
  InMemoryChatMessageDataSource()
    : _controller = StreamController<List<ChatMessageModel>>.broadcast() {
    _controller.add(const <ChatMessageModel>[]);
  }

  final StreamController<List<ChatMessageModel>> _controller;
  final List<ChatMessageModel> _cache = <ChatMessageModel>[];

  @override
  Future<void> saveMessage(ChatMessageModel message) async {
    _cache.add(message);
    _controller.add(List<ChatMessageModel>.unmodifiable(_cache));
  }

  @override
  Stream<List<ChatMessageModel>> watchMessages() {
    return _controller.stream;
  }

  Future<void> dispose() async {
    await _controller.close();
  }
}
