import 'dart:async';

import '../../../../core/usecase/use_case.dart';
import '../entities/chat_message.dart';
import '../repositories/chat_repository.dart';

class WatchMessages extends StreamUseCase<List<ChatMessage>, NoParams> {
  WatchMessages(this._repository);

  final ChatRepository _repository;

  @override
  Stream<List<ChatMessage>> call(NoParams params) {
    return _repository.watchMessages();
  }
}
