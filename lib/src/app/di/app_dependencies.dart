import 'package:shared_preferences/shared_preferences.dart';

import '../../core/models/peer_identity.dart';
import '../../core/services/peer_identity_service.dart';
import '../../core/utils/logger.dart';
import '../../features/chat/data/datasources/chat_message_data_source.dart';
import '../../features/chat/data/datasources/conversation_store.dart';
import '../../features/chat/data/repositories/chat_repository_impl.dart';
import '../../features/chat/domain/entities/conversation.dart';
import '../../features/chat/domain/repositories/chat_repository.dart';
import '../../features/chat/domain/usecases/send_message.dart';
import '../../features/chat/domain/usecases/watch_messages.dart';
import '../../features/chat/presentation/controllers/chat_controller.dart';
import '../../features/p2p/data/services/p2p_service.dart';
import '../../features/p2p/presentation/controllers/p2p_session_controller.dart';

class AppDependencies {
  AppDependencies._();

  static final AppDependencies instance = AppDependencies._();

  final Logger _logger = const Logger('AppDependencies');

  late final ChatMessageDataSource _chatMessageDataSource;
  late final ChatRepository _chatRepository;
  late final SendMessage _sendMessage;
  late final WatchMessages _watchMessages;
  late final P2pService _p2pService;
  late final PeerIdentityService _peerIdentityService;
  late PeerIdentity _peerIdentity;
  late final ConversationStore _conversationStore;
  Map<String, String> _knownPeers = <String, String>{};

  Future<void> init() async {
    _logger.info('Initializing dependencies');

    final sharedPreferences = await SharedPreferences.getInstance();

    _chatMessageDataSource = PersistentChatMessageDataSource(
      sharedPreferences: sharedPreferences,
    );
    _chatRepository = ChatRepositoryImpl(_chatMessageDataSource);
    _sendMessage = SendMessage(_chatRepository);
    _watchMessages = WatchMessages(_chatRepository);

    // Prepare P2P service (lazy initialization happens on demand)
    _p2pService = P2pService();

    _peerIdentityService = PeerIdentityService();
    _peerIdentity = await _peerIdentityService.getIdentity();
    _knownPeers = await _peerIdentityService.getKnownPeers();

    _conversationStore = ConversationStore(
      sharedPreferences: sharedPreferences,
    );
    await _conversationStore.init();
  }

  ChatController createChatController({required Conversation conversation}) {
    return ChatController(
      sendMessage: _sendMessage,
      watchMessages: _watchMessages,
      identity: _peerIdentity,
      conversation: conversation,
      conversationStore: _conversationStore,
      rememberPeerName:
          ({required String peerId, required String displayName}) async {
            await rememberPeerName(peerId: peerId, displayName: displayName);
          },
      knownPeers: _knownPeers,
    );
  }

  P2pService get p2pService => _p2pService;

  PeerIdentity get peerIdentity => _peerIdentity;
  Map<String, String> get knownPeers =>
      Map<String, String>.unmodifiable(_knownPeers);

  ConversationStore get conversationStore => _conversationStore;

  P2pSessionController createP2pSessionController() {
    return P2pSessionController(
      p2pService: _p2pService,
      conversationStore: _conversationStore,
    );
  }

  Future<void> updatePeerDisplayName(String displayName) async {
    final trimmed = displayName.trim();
    final effectiveName = trimmed.isEmpty
        ? _peerIdentityService.defaultDisplayName(_peerIdentity.id)
        : trimmed;
    await _peerIdentityService.setDisplayName(effectiveName);
    _peerIdentity = _peerIdentity.copyWith(displayName: effectiveName);
    _knownPeers[_peerIdentity.id] = effectiveName;
  }

  Future<void> rememberPeerName({
    required String peerId,
    required String displayName,
  }) async {
    final trimmed = displayName.trim();
    await _peerIdentityService.rememberPeer(id: peerId, displayName: trimmed);
    if (trimmed.isEmpty) {
      _knownPeers.remove(peerId);
    } else {
      _knownPeers[peerId] = trimmed;
    }
  }
}
