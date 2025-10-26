import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/entities/conversation.dart';

class ConversationStore {
  ConversationStore({SharedPreferences? sharedPreferences})
    : _sharedPreferences = sharedPreferences;

  static const String _storageKey = 'conversation_store_v1';

  SharedPreferences? _sharedPreferences;
  bool _initialized = false;

  final StreamController<List<Conversation>> _controller =
      StreamController<List<Conversation>>.broadcast();
  final List<Conversation> _conversations = <Conversation>[];

  Future<void> init() async {
    if (_initialized) {
      return;
    }

    _sharedPreferences ??= await SharedPreferences.getInstance();
    final raw = _sharedPreferences!.getString(_storageKey);
    if (raw != null) {
      final decoded = jsonDecode(raw) as List<dynamic>;
      _conversations
        ..clear()
        ..addAll(
          decoded.whereType<Map<String, dynamic>>().map(Conversation.fromJson),
        );
    }

    _initialized = true;
    _emit();
  }

  Stream<List<Conversation>> watchAll() {
    scheduleMicrotask(_emit);
    return _controller.stream;
  }

  List<Conversation> get current =>
      List<Conversation>.unmodifiable(_conversations);

  Future<Conversation> createConversation(String title) async {
    await init();
    final now = DateTime.now();
    final conversation = Conversation(
      id: _generateId(),
      title: title.trim().isEmpty ? 'Conversation' : title.trim(),
      createdAt: now,
      updatedAt: now,
    );
    _conversations.add(conversation);
    await _persist();
    _emit();
    return conversation;
  }

  Future<Conversation> ensureConversationExists({
    required String id,
    required String title,
  }) async {
    await init();
    final index = _conversations.indexWhere(
      (conversation) => conversation.id == id,
    );
    final trimmedTitle = title.trim();
    final now = DateTime.now();

    if (index >= 0) {
      final existing = _conversations[index];
      if (trimmedTitle.isNotEmpty && existing.title != trimmedTitle) {
        _conversations[index] = existing.copyWith(
          title: trimmedTitle,
          updatedAt: now,
        );
        await _persist();
        _emit();
      }
      return _conversations[index];
    }

    final conversation = Conversation(
      id: id,
      title: trimmedTitle.isEmpty ? 'Conversation' : trimmedTitle,
      createdAt: now,
      updatedAt: now,
    );
    _conversations.add(conversation);
    await _persist();
    _emit();
    return conversation;
  }

  Future<void> renameConversation({
    required String id,
    required String newTitle,
  }) async {
    await init();
    final index = _conversations.indexWhere(
      (conversation) => conversation.id == id,
    );
    if (index == -1) {
      return;
    }

    _conversations[index] = _conversations[index].copyWith(
      title: newTitle.trim().isEmpty
          ? _conversations[index].title
          : newTitle.trim(),
      updatedAt: DateTime.now(),
    );
    await _persist();
    _emit();
  }

  Future<void> touchConversation(String id) async {
    await init();
    final index = _conversations.indexWhere(
      (conversation) => conversation.id == id,
    );
    if (index == -1) {
      return;
    }

    _conversations[index] = _conversations[index].copyWith(
      updatedAt: DateTime.now(),
    );
    await _persist();
    _emit();
  }

  Future<void> deleteConversation(String id) async {
    await init();
    _conversations.removeWhere((conversation) => conversation.id == id);
    await _persist();
    _emit();
  }

  Future<void> dispose() async {
    await _controller.close();
  }

  Future<void> _persist() async {
    _conversations.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    await _sharedPreferences!.setString(
      _storageKey,
      jsonEncode(
        _conversations.map((conversation) => conversation.toJson()).toList(),
      ),
    );
  }

  void _emit() {
    if (_controller.isClosed) {
      return;
    }
    _controller.add(List<Conversation>.unmodifiable(_conversations));
  }

  String _generateId() {
    final random = Random.secure();
    final buffer = StringBuffer();
    for (var i = 0; i < 12; i++) {
      buffer.write(_alphabet[random.nextInt(_alphabet.length)]);
    }
    return buffer.toString();
  }
}

const String _alphabet = 'abcdefghijklmnopqrstuvwxyz0123456789';
