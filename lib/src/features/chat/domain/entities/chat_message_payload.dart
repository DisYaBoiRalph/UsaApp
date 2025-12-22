import 'dart:convert';

import '../../../../core/models/peer_identity.dart';
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
    this.senderFullName,
    this.senderRole,
    this.senderGroupName,
    this.senderProfileImageBase64,
  });

  final String id;
  final String conversationId;
  final String conversationTitle;
  final String senderId;
  final String senderName;
  final String content;
  final DateTime sentAt;

  // Profile information
  final String? senderFullName;
  final String? senderRole; // Stored as string for serialization
  final String? senderGroupName;
  final String? senderProfileImageBase64;

  static const int _protocolVersion = 2; // Incremented for profile support

  factory ChatMessagePayload.fromChatMessage(
    ChatMessage message, {
    required String conversationTitle,
    PeerIdentity? senderIdentity,
  }) {
    return ChatMessagePayload(
      id: message.id,
      conversationId: message.conversationId,
      conversationTitle: conversationTitle,
      senderId: message.senderId,
      senderName: message.sender,
      content: message.content,
      sentAt: message.sentAt,
      senderFullName: senderIdentity?.name,
      senderRole: senderIdentity?.role.name,
      senderGroupName: senderIdentity?.groupName,
      senderProfileImageBase64: senderIdentity?.profileImage,
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

  /// Extracts PeerIdentity from the payload's sender information
  PeerIdentity getSenderIdentity() {
    return PeerIdentity(
      id: senderId,
      displayName: senderName,
      name: senderFullName,
      role: senderRole != null
          ? UserRole.values.firstWhere(
              (e) => e.name == senderRole,
              orElse: () => UserRole.other,
            )
          : UserRole.other,
      groupName: senderGroupName,
      profileImage: senderProfileImageBase64,
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
      if (senderFullName != null) 'senderFullName': senderFullName,
      if (senderRole != null) 'senderRole': senderRole,
      if (senderGroupName != null) 'senderGroupName': senderGroupName,
      if (senderProfileImageBase64 != null)
        'senderProfileImageBase64': senderProfileImageBase64,
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
      if (version is! num || (version.toInt() != 1 && version.toInt() != 2)) {
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

      // Extract profile fields (only in v2)
      final senderFullName = decoded['senderFullName'] as String?;
      final senderRole = decoded['senderRole'] as String?;
      final senderGroupName = decoded['senderGroupName'] as String?;
      final senderProfileImageBase64 =
          decoded['senderProfileImageBase64'] as String?;

      return ChatMessagePayload(
        id: id,
        conversationId: conversationId,
        conversationTitle: conversationTitle,
        senderId: senderId,
        senderName: senderName,
        content: content,
        sentAt: DateTime.tryParse(sentAt)?.toUtc() ?? DateTime.now().toUtc(),
        senderFullName: senderFullName,
        senderRole: senderRole,
        senderGroupName: senderGroupName,
        senderProfileImageBase64: senderProfileImageBase64,
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
