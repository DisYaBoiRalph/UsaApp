import 'dart:async';

import '../../domain/entities/chat_message.dart';
import '../../domain/repositories/chat_repository.dart';
import '../datasources/chat_message_data_source.dart';
import '../models/chat_message_model.dart';

class ChatRepositoryImpl implements ChatRepository {
  ChatRepositoryImpl(this._messageDataSource);

  final ChatMessageDataSource _messageDataSource;

  @override
  Future<void> sendMessage(ChatMessage message) {
    final model = ChatMessageModel.fromEntity(message);
    return _messageDataSource.saveMessage(model);
  }

  @override
  Stream<List<ChatMessage>> watchMessages() {
    return _messageDataSource.watchMessages().map(
      (models) =>
          models.map((model) => model.toEntity()).toList(growable: false),
    );
  }
}
