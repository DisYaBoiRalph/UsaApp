import 'dart:convert';

import 'chat_message.dart';

class ChatMessagePayload {
  const ChatMessagePayload({
    required this.id,
    required this.conversationId,
    required this.conversationTitle,
    required this.senderId,
    required this.senderName,
    required this.content,
    required this.sentAt,
  });

  final String id;
  final String conversationId;
  final String conversationTitle;
  final String senderId;
  final String senderName;
  final String content;
  final DateTime sentAt;

  static const int _protocolVersion = 1;

  factory ChatMessagePayload.fromChatMessage(
    ChatMessage message, {
    required String conversationTitle,
  }) {
    return ChatMessagePayload(
      id: message.id,
      conversationId: message.conversationId,
      conversationTitle: conversationTitle,
      senderId: message.senderId,
      senderName: message.sender,
      content: message.content,
      sentAt: message.sentAt,
    );
  }

  ChatMessage toChatMessage() {
    return ChatMessage(
      id: id,
      conversationId: conversationId,
      senderId: senderId,
      sender: senderName,
      content: content,
      sentAt: sentAt,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'v': _protocolVersion,
      'id': id,
      'conversationId': conversationId,
      'conversationTitle': conversationTitle,
      'senderId': senderId,
      'senderName': senderName,
      'content': content,
      'sentAt': sentAt.toUtc().toIso8601String(),
    };
  }

  String encode() => jsonEncode(toJson());

  static ChatMessagePayload? tryParse(String raw) {
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) {
        return null;
      }

      final version = decoded['v'];
      if (version is! num || version.toInt() != _protocolVersion) {
        return null;
      }

      final id = decoded['id'];
      final conversationIdRaw = decoded['conversationId'];
      final conversationTitleRaw = decoded['conversationTitle'];
      final senderId = decoded['senderId'];
      final senderName = decoded['senderName'];
      final content = decoded['content'];
      final sentAt = decoded['sentAt'];

      if (id is! String ||
          senderId is! String ||
          senderName is! String ||
          content is! String ||
          sentAt is! String) {
        return null;
      }

      final conversationId =
          conversationIdRaw is String && conversationIdRaw.isNotEmpty
          ? conversationIdRaw
          : 'default';
      final conversationTitle =
          conversationTitleRaw is String && conversationTitleRaw.isNotEmpty
          ? conversationTitleRaw
          : 'Conversation';

      return ChatMessagePayload(
        id: id,
        conversationId: conversationId,
        conversationTitle: conversationTitle,
        senderId: senderId,
        senderName: senderName,
        content: content,
        sentAt: DateTime.tryParse(sentAt)?.toUtc() ?? DateTime.now().toUtc(),
      );
    } catch (_) {
      return null;
    }
  }

  static ChatMessagePayload fallback(String content) {
    final id = DateTime.now().microsecondsSinceEpoch.toString();
    return ChatMessagePayload(
      id: id,
      conversationId: 'default',
      conversationTitle: 'Conversation',
      senderId: 'unknown',
      senderName: 'Peer',
      content: content,
      sentAt: DateTime.now().toUtc(),
    );
  }
}
