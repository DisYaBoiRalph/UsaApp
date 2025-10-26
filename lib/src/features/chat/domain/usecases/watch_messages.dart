import 'dart:async';

import '../../../../core/usecase/use_case.dart';
import '../entities/chat_message.dart';
import '../repositories/chat_repository.dart';

class WatchMessagesParams {
  const WatchMessagesParams({required this.conversationId});

  final String conversationId;
}

class WatchMessages
    extends StreamUseCase<List<ChatMessage>, WatchMessagesParams> {
  WatchMessages(this._repository);

  final ChatRepository _repository;

  @override
  Stream<List<ChatMessage>> call(WatchMessagesParams params) {
    return _repository.watchMessages(params.conversationId);
  }
}
