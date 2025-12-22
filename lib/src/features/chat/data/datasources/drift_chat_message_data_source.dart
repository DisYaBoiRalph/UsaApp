import 'dart:async';

import '../../../../core/database/app_database.dart';
import '../models/chat_message_model.dart';

/// Data source for chat messages using drift (SQLite).
///
/// Replaces [PersistentChatMessageDataSource] with SQLite-backed storage
/// that supports efficient pagination and search.
class DriftChatMessageDataSource {
  DriftChatMessageDataSource(this._db);

  final AppDatabase _db;

  /// Watch all messages for a conversation.
  Stream<List<ChatMessageModel>> watchMessages(String conversationId) {
    return _db
        .watchMessages(conversationId)
        .map((entries) => entries.map(_entryToModel).toList(growable: false));
  }

  /// Watch messages with pagination (most recent first).
  Stream<List<ChatMessageModel>> watchMessagesPaginated(
    String conversationId, {
    int limit = 50,
    int offset = 0,
  }) {
    return _db
        .watchMessagesPaginated(conversationId, limit: limit, offset: offset)
        .map((entries) => entries.map(_entryToModel).toList(growable: false));
  }

  /// Get messages before a certain time (for infinite scroll).
  Future<List<ChatMessageModel>> getMessagesBefore(
    String conversationId,
    DateTime before, {
    int limit = 50,
  }) async {
    final entries = await _db.getMessagesBefore(
      conversationId,
      before,
      limit: limit,
    );
    return entries.map(_entryToModel).toList(growable: false);
  }

  /// Save a message.
  Future<void> saveMessage(String conversationId, ChatMessageModel message) {
    return _db.upsertMessage(_modelToEntry(message));
  }

  /// Save multiple messages in batch (for migration/sync).
  Future<void> saveMessagesBatch(List<ChatMessageModel> messages) {
    final entries = messages.map(_modelToEntry).toList(growable: false);
    return _db.insertMessagesBatch(entries);
  }

  /// Clear all messages in a conversation.
  Future<void> clearConversation(String conversationId) {
    return _db.clearConversationMessages(conversationId);
  }

  /// Search messages by content.
  Future<List<ChatMessageModel>> searchMessages(
    String query, {
    String? conversationId,
    int limit = 50,
  }) async {
    final entries = await _db.searchMessages(
      query,
      conversationId: conversationId,
      limit: limit,
    );
    return entries.map(_entryToModel).toList(growable: false);
  }

  /// Get total message count for a conversation.
  Future<int> getMessageCount(String conversationId) {
    return _db.getMessageCount(conversationId);
  }

  // ─────────────────────────────────────────────────────────────────────────
  // CONVERTERS
  // ─────────────────────────────────────────────────────────────────────────

  ChatMessageModel _entryToModel(ChatMessageEntry entry) {
    return ChatMessageModel(
      id: entry.id,
      conversationId: entry.conversationId,
      senderId: entry.senderId,
      sender: entry.sender,
      content: entry.content,
      sentAt: entry.sentAt,
    );
  }

  ChatMessageEntry _modelToEntry(ChatMessageModel model) {
    return ChatMessageEntry(
      id: model.id,
      conversationId: model.conversationId,
      senderId: model.senderId,
      sender: model.sender,
      content: model.content,
      sentAt: model.sentAt,
    );
  }
}
