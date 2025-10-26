import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../core/models/peer_identity.dart';
import '../../data/datasources/conversation_store.dart';
import '../../domain/entities/chat_message.dart';
import '../../domain/entities/chat_message_payload.dart';
import '../../domain/entities/conversation.dart';
import '../../domain/usecases/send_message.dart';
import '../../domain/usecases/watch_messages.dart';

typedef RememberPeerName =
    Future<void> Function({
      required String peerId,
      required String displayName,
    });

class ChatController extends ChangeNotifier {
  ChatController({
    required SendMessage sendMessage,
    required WatchMessages watchMessages,
    required PeerIdentity identity,
    required Conversation conversation,
    required ConversationStore conversationStore,
    required RememberPeerName rememberPeerName,
    Map<String, String>? knownPeers,
  }) : _sendMessage = sendMessage,
       _watchMessages = watchMessages,
       _identity = identity,
       _conversation = conversation,
       _conversationStore = conversationStore,
       _rememberPeerName = rememberPeerName,
       _knownPeers = Map<String, String>.from(knownPeers ?? <String, String>{});

  final SendMessage _sendMessage;
  final WatchMessages _watchMessages;
  final PeerIdentity _identity;
  final ConversationStore _conversationStore;
  final RememberPeerName _rememberPeerName;
  Conversation _conversation;
  final Map<String, String> _knownPeers;

  final TextEditingController messageFieldController = TextEditingController();

  StreamSubscription<List<ChatMessage>>? _subscription;
  final List<ChatMessageViewModel> _messages = <ChatMessageViewModel>[];

  List<ChatMessageViewModel> get messages =>
      List<ChatMessageViewModel>.unmodifiable(_messages);

  String get localPeerId => _identity.id;
  String get localDisplayName => _identity.displayName;
  Conversation get conversation => _conversation;

  set conversation(Conversation value) {
    if (_conversation.id == value.id && _conversation.title == value.title) {
      return;
    }
    _conversation = value;
    if (_subscription != null) {
      _subscribeToMessages();
    }
    notifyListeners();
  }

  Future<void> start() async {
    if (_subscription != null) {
      return;
    }
    _subscribeToMessages();
  }

  void _subscribeToMessages() {
    _subscription?.cancel();
    _subscription =
        _watchMessages(
          WatchMessagesParams(conversationId: _conversation.id),
        ).listen((messages) {
          _messages
            ..clear()
            ..addAll(
              messages.map(
                (message) => ChatMessageViewModel.fromEntity(
                  message,
                  localPeerId: _identity.id,
                  knownPeers: _knownPeers,
                ),
              ),
            );
          notifyListeners();
        });
  }

  Future<ChatMessage?> sendLocalMessage(String rawContent) async {
    final content = rawContent.trim();
    if (content.isEmpty) {
      return null;
    }

    messageFieldController.clear();
    final storedMessage = await _sendMessage(
      SendMessageParams(
        conversationId: _conversation.id,
        senderId: _identity.id,
        sender: _identity.displayName,
        content: content,
      ),
    );
    unawaited(_conversationStore.touchConversation(_conversation.id));
    return storedMessage;
  }

  Future<void> receiveMessage(ChatMessage message) async {
    if (message.senderId == _identity.id) {
      return;
    }

    final senderName = message.sender.trim();
    if (senderName.isNotEmpty && _knownPeers[message.senderId] != senderName) {
      _knownPeers[message.senderId] = senderName;
      unawaited(
        _rememberPeerName(peerId: message.senderId, displayName: senderName),
      );
    }

    await _sendMessage(
      SendMessageParams(
        id: message.id,
        conversationId: message.conversationId,
        senderId: message.senderId,
        sender: message.sender,
        content: message.content,
        sentAt: message.sentAt,
      ),
    );
  }

  Future<void> receivePayload(ChatMessagePayload payload) async {
    final conversationRecord = await _conversationStore
        .ensureConversationExists(
          id: payload.conversationId,
          title: payload.conversationTitle,
        );
    conversation = conversationRecord;
    unawaited(_conversationStore.touchConversation(conversationRecord.id));
    return receiveMessage(payload.toChatMessage());
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
    required this.conversationId,
    required this.senderId,
    required this.sender,
    required this.content,
    required this.sentAt,
    required this.isLocal,
  });

  factory ChatMessageViewModel.fromEntity(
    ChatMessage entity, {
    required String localPeerId,
    required Map<String, String> knownPeers,
  }) {
    final isLocal = entity.senderId == localPeerId;
    final senderOverride = knownPeers[entity.senderId];
    return ChatMessageViewModel(
      id: entity.id,
      conversationId: entity.conversationId,
      senderId: entity.senderId,
      sender: senderOverride?.isNotEmpty == true
          ? senderOverride!
          : entity.sender,
      content: entity.content,
      sentAt: entity.sentAt,
      isLocal: isLocal,
    );
  }

  final String id;
  final String conversationId;
  final String senderId;
  final String sender;
  final String content;
  final DateTime sentAt;
  final bool isLocal;

  String get sentAtFormatted {
    final parsed = sentAt.toLocal();
    final hours = parsed.hour.toString().padLeft(2, '0');
    final minutes = parsed.minute.toString().padLeft(2, '0');
    return '$hours:$minutes';
  }

  String get displaySender => isLocal ? 'You' : sender;
}
