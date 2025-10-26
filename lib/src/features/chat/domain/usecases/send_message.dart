import '../../../../core/usecase/use_case.dart';
import '../entities/chat_message.dart';
import '../repositories/chat_repository.dart';

class SendMessage extends UseCase<ChatMessage, SendMessageParams> {
  SendMessage(this._repository);

  final ChatRepository _repository;

  @override
  Future<ChatMessage> call(SendMessageParams params) async {
    final id = params.id ?? _generateId();
    final sentAt = params.sentAt ?? DateTime.now();
    final message = ChatMessage(
      id: id,
      conversationId: params.conversationId,
      senderId: params.senderId,
      sender: params.sender,
      content: params.content,
      sentAt: sentAt,
    );

    await _repository.sendMessage(params.conversationId, message);
    return message;
  }

  String _generateId() => DateTime.now().microsecondsSinceEpoch.toString();
}

class SendMessageParams {
  const SendMessageParams({
    this.id,
    required this.conversationId,
    required this.senderId,
    required this.sender,
    required this.content,
    this.sentAt,
  });

  final String? id;
  final String conversationId;
  final String senderId;
  final String sender;
  final String content;
  final DateTime? sentAt;
}
