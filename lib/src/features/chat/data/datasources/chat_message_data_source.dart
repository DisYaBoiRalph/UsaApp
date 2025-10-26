import 'dart:async';
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/chat_message_model.dart';

abstract class ChatMessageDataSource {
  Stream<List<ChatMessageModel>> watchMessages(String conversationId);
  Future<void> saveMessage(String conversationId, ChatMessageModel message);
  Future<void> clearConversation(String conversationId);
  Future<void> dispose();
}

class InMemoryChatMessageDataSource implements ChatMessageDataSource {
  final Map<String, StreamController<List<ChatMessageModel>>> _controllers =
      <String, StreamController<List<ChatMessageModel>>>{};
  final Map<String, List<ChatMessageModel>> _cache =
      <String, List<ChatMessageModel>>{};

  @override
  Future<void> saveMessage(
    String conversationId,
    ChatMessageModel message,
  ) async {
    final list = _cache.putIfAbsent(conversationId, () => <ChatMessageModel>[]);
    final existingIndex = list.indexWhere((cached) => cached.id == message.id);
    if (existingIndex >= 0) {
      list[existingIndex] = message;
    } else {
      list.add(message);
      list.sort((a, b) => a.sentAt.compareTo(b.sentAt));
    }

    _ensureController(
      conversationId,
    ).add(List<ChatMessageModel>.unmodifiable(list));
  }

  @override
  Stream<List<ChatMessageModel>> watchMessages(String conversationId) {
    return _ensureController(conversationId).stream;
  }

  @override
  Future<void> clearConversation(String conversationId) async {
    _cache.remove(conversationId);
    final controller = _controllers[conversationId];
    controller?.add(const <ChatMessageModel>[]);
  }

  @override
  Future<void> dispose() async {
    for (final controller in _controllers.values) {
      await controller.close();
    }
    _controllers.clear();
    _cache.clear();
  }

  StreamController<List<ChatMessageModel>> _ensureController(
    String conversationId,
  ) {
    return _controllers.putIfAbsent(conversationId, () {
      final controller = StreamController<List<ChatMessageModel>>.broadcast();
      controller.onListen = () {
        controller.add(
          List<ChatMessageModel>.unmodifiable(
            _cache[conversationId] ?? const <ChatMessageModel>[],
          ),
        );
      };
      return controller;
    });
  }
}

class PersistentChatMessageDataSource implements ChatMessageDataSource {
  PersistentChatMessageDataSource({SharedPreferences? sharedPreferences})
    : _sharedPreferences = sharedPreferences;

  static const String _storagePrefix = 'chat_messages_v1_';

  final SharedPreferences? _sharedPreferences;
  SharedPreferences? _prefs;

  final Map<String, StreamController<List<ChatMessageModel>>> _controllers =
      <String, StreamController<List<ChatMessageModel>>>{};
  final Map<String, List<ChatMessageModel>> _cache =
      <String, List<ChatMessageModel>>{};

  @override
  Future<void> saveMessage(
    String conversationId,
    ChatMessageModel message,
  ) async {
    await _ensurePrefs();
    final list = await _ensureConversationLoaded(conversationId);
    final existingIndex = list.indexWhere((item) => item.id == message.id);
    if (existingIndex >= 0) {
      list[existingIndex] = message;
    } else {
      list.add(message);
      list.sort((a, b) => a.sentAt.compareTo(b.sentAt));
    }

    await _persist(conversationId, list);
    _emit(conversationId, list);
  }

  @override
  Stream<List<ChatMessageModel>> watchMessages(String conversationId) async* {
    await _ensurePrefs();
    await _ensureConversationLoaded(conversationId);
    final controller = _ensureController(conversationId);
    yield* controller.stream;
  }

  @override
  Future<void> clearConversation(String conversationId) async {
    await _ensurePrefs();
    _cache.remove(conversationId);
    await _prefs!.remove(_storageKeyFor(conversationId));
    final controller = _controllers[conversationId];
    controller?.add(const <ChatMessageModel>[]);
  }

  @override
  Future<void> dispose() async {
    for (final controller in _controllers.values) {
      await controller.close();
    }
    _controllers.clear();
    _cache.clear();
  }

  Future<void> _ensurePrefs() async {
    _prefs ??= _sharedPreferences ?? await SharedPreferences.getInstance();
  }

  Future<List<ChatMessageModel>> _ensureConversationLoaded(
    String conversationId,
  ) async {
    final existing = _cache[conversationId];
    if (existing != null) {
      return existing;
    }

    final raw = _prefs!.getString(_storageKeyFor(conversationId));
    final list = <ChatMessageModel>[];
    if (raw != null && raw.isNotEmpty) {
      try {
        final decoded = jsonDecode(raw);
        if (decoded is List) {
          for (final item in decoded) {
            if (item is Map<String, dynamic>) {
              list.add(ChatMessageModel.fromJson(item));
            } else if (item is Map) {
              list.add(
                ChatMessageModel.fromJson(
                  item.map((key, value) => MapEntry('$key', value)),
                ),
              );
            }
          }
        }
      } catch (_) {
        // Corrupted payloads are ignored and replaced with a fresh list.
      }
    }

    list.sort((a, b) => a.sentAt.compareTo(b.sentAt));
    _cache[conversationId] = list;
    _emit(conversationId, list);
    return list;
  }

  Future<void> _persist(
    String conversationId,
    List<ChatMessageModel> list,
  ) async {
    final encoded = jsonEncode(list.map((item) => item.toJson()).toList());
    await _prefs!.setString(_storageKeyFor(conversationId), encoded);
  }

  StreamController<List<ChatMessageModel>> _ensureController(
    String conversationId,
  ) {
    return _controllers.putIfAbsent(conversationId, () {
      final controller = StreamController<List<ChatMessageModel>>.broadcast();
      controller.onListen = () {
        final current = _cache[conversationId] ?? const <ChatMessageModel>[];
        controller.add(List<ChatMessageModel>.unmodifiable(current));
      };
      return controller;
    });
  }

  void _emit(String conversationId, List<ChatMessageModel> list) {
    final controller = _ensureController(conversationId);
    if (!controller.isClosed) {
      controller.add(List<ChatMessageModel>.unmodifiable(list));
    }
  }

  String _storageKeyFor(String conversationId) =>
      '$_storagePrefix$conversationId';
}
