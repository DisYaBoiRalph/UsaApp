import '../../../../core/usecase/use_case.dart';
import '../entities/chat_message.dart';
import '../repositories/chat_repository.dart';

class SendMessage extends UseCase<void, SendMessageParams> {
  SendMessage(this._repository);

  final ChatRepository _repository;

  @override
  Future<void> call(SendMessageParams params) {
    final message = ChatMessage(
      id: _generateId(),
      sender: params.sender,
      content: params.content,
      sentAt: params.sentAt,
    );

    return _repository.sendMessage(message);
  }

  String _generateId() => DateTime.now().microsecondsSinceEpoch.toString();
}

class SendMessageParams {
  const SendMessageParams({
    required this.sender,
    required this.content,
    required this.sentAt,
  });

  final String sender;
  final String content;
  final DateTime sentAt;
}
