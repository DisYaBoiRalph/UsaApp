import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../core/usecase/use_case.dart';
import '../../domain/entities/chat_message.dart';
import '../../domain/usecases/send_message.dart';
import '../../domain/usecases/watch_messages.dart';

class ChatController extends ChangeNotifier {
  ChatController({
    required SendMessage sendMessage,
    required WatchMessages watchMessages,
    String defaultSender = 'You',
  }) : _sendMessage = sendMessage,
       _watchMessages = watchMessages,
       _defaultSender = defaultSender;

  final SendMessage _sendMessage;
  final WatchMessages _watchMessages;
  final String _defaultSender;

  final TextEditingController messageFieldController = TextEditingController();

  StreamSubscription<List<ChatMessage>>? _subscription;
  final List<ChatMessageViewModel> _messages = <ChatMessageViewModel>[];

  List<ChatMessageViewModel> get messages =>
      List<ChatMessageViewModel>.unmodifiable(_messages);

  Future<void> start() async {
    _subscription ??= _watchMessages(const NoParams()).listen((messages) {
      _messages
        ..clear()
        ..addAll(messages.map(ChatMessageViewModel.fromEntity));
      notifyListeners();
    });
  }

  Future<void> sendMessage(String rawContent) async {
    final content = rawContent.trim();
    if (content.isEmpty) {
      return;
    }

    messageFieldController.clear();
    await _sendMessage(
      SendMessageParams(
        sender: _defaultSender,
        content: content,
        sentAt: DateTime.now(),
      ),
    );
  }

  @override
  void dispose() {
    messageFieldController.dispose();
    _subscription?.cancel();
    super.dispose();
  }
}

class ChatMessageViewModel {
  ChatMessageViewModel({
    required this.id,
    required this.sender,
    required this.content,
    required this.sentAt,
  });

  factory ChatMessageViewModel.fromEntity(ChatMessage entity) {
    return ChatMessageViewModel(
      id: entity.id,
      sender: entity.sender,
      content: entity.content,
      sentAt: entity.sentAt,
    );
  }

  final String id;
  final String sender;
  final String content;
  final DateTime sentAt;

  String get sentAtFormatted {
    final parsed = sentAt.toLocal();
    final hours = parsed.hour.toString().padLeft(2, '0');
    final minutes = parsed.minute.toString().padLeft(2, '0');
    return '$hours:$minutes';
  }
}
