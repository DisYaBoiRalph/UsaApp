import '../../core/utils/logger.dart';
import '../../features/chat/data/datasources/chat_message_data_source.dart';
import '../../features/chat/data/repositories/chat_repository_impl.dart';
import '../../features/chat/domain/repositories/chat_repository.dart';
import '../../features/chat/domain/usecases/send_message.dart';
import '../../features/chat/domain/usecases/watch_messages.dart';
import '../../features/chat/presentation/controllers/chat_controller.dart';
import '../../features/p2p/data/services/p2p_service.dart';

class AppDependencies {
  AppDependencies._();

  static final AppDependencies instance = AppDependencies._();

  final Logger _logger = const Logger('AppDependencies');

  late final ChatRepository _chatRepository;
  late final SendMessage _sendMessage;
  late final WatchMessages _watchMessages;
  late final P2pService _p2pService;

  Future<void> init() async {
    _logger.info('Initializing dependencies');

    final dataSource = InMemoryChatMessageDataSource();
    _chatRepository = ChatRepositoryImpl(dataSource);
    _sendMessage = SendMessage(_chatRepository);
    _watchMessages = WatchMessages(_chatRepository);

    // Initialize P2P service
    _p2pService = P2pService();
    await _p2pService.initialize();
  }

  ChatController createChatController() {
    return ChatController(
      sendMessage: _sendMessage,
      watchMessages: _watchMessages,
    );
  }

  P2pService get p2pService => _p2pService;
}
