import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../core/models/peer_identity.dart';
import '../../data/datasources/conversation_store.dart';
import '../../domain/entities/chat_message.dart';
import '../../domain/entities/chat_message_payload.dart';
import '../../domain/entities/conversation.dart';
import '../../domain/usecases/send_message.dart';
import '../../domain/usecases/watch_messages.dart';

typedef RememberPeer = Future<void> Function(PeerIdentity identity);

class ChatController extends ChangeNotifier {
  ChatController({
    required SendMessage sendMessage,
    required WatchMessages watchMessages,
    required PeerIdentity identity,
    required Conversation conversation,
    required ConversationStore conversationStore,
    required RememberPeer rememberPeer,
    Map<String, PeerIdentity>? knownPeers,
  }) : _sendMessage = sendMessage,
       _watchMessages = watchMessages,
       _identity = identity,
       _conversation = conversation,
       _conversationStore = conversationStore,
       _rememberPeer = rememberPeer,
       _knownPeers = Map<String, PeerIdentity>.from(
         knownPeers ?? <String, PeerIdentity>{},
       );

  final SendMessage _sendMessage;
  final WatchMessages _watchMessages;
  final PeerIdentity _identity;
  final ConversationStore _conversationStore;
  final RememberPeer _rememberPeer;
  Conversation _conversation;
  final Map<String, PeerIdentity> _knownPeers;

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
                  localIdentity: _identity,
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
    if (senderName.isNotEmpty) {
      final existingIdentity = _knownPeers[message.senderId];
      if (existingIdentity == null ||
          existingIdentity.displayName != senderName) {
        final newIdentity = PeerIdentity(
          id: message.senderId,
          displayName: senderName,
        );
        _knownPeers[message.senderId] = newIdentity;
        unawaited(_rememberPeer(newIdentity));
      }
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

    // Extract and remember sender identity
    final senderIdentity = payload.getSenderIdentity();
    final existingIdentity = _knownPeers[senderIdentity.id];
    if (existingIdentity == null ||
        existingIdentity.displayName != senderIdentity.displayName ||
        existingIdentity.profileImage != senderIdentity.profileImage) {
      _knownPeers[senderIdentity.id] = senderIdentity;
      unawaited(_rememberPeer(senderIdentity));
    }

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
    required this.senderIdentity,
  });

  factory ChatMessageViewModel.fromEntity(
    ChatMessage entity, {
    required String localPeerId,
    required PeerIdentity localIdentity,
    required Map<String, PeerIdentity> knownPeers,
  }) {
    final isLocal = entity.senderId == localPeerId;
    final PeerIdentity senderIdentity;

    if (isLocal) {
      senderIdentity = localIdentity;
    } else {
      final knownIdentity = knownPeers[entity.senderId];
      senderIdentity =
          knownIdentity ??
          PeerIdentity(id: entity.senderId, displayName: entity.sender);
    }

    return ChatMessageViewModel(
      id: entity.id,
      conversationId: entity.conversationId,
      senderId: entity.senderId,
      sender: senderIdentity.displayName,
      content: entity.content,
      sentAt: entity.sentAt,
      isLocal: isLocal,
      senderIdentity: senderIdentity,
    );
  }

  final String id;
  final String conversationId;
  final String senderId;
  final String sender;
  final String content;
  final DateTime sentAt;
  final bool isLocal;
  final PeerIdentity senderIdentity;

  String get sentAtFormatted {
    final parsed = sentAt.toLocal();
    final hours = parsed.hour.toString().padLeft(2, '0');
    final minutes = parsed.minute.toString().padLeft(2, '0');
    return '$hours:$minutes';
  }

  String get displaySender => isLocal ? 'You' : sender;
}
