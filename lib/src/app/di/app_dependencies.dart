import 'package:drift/drift.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/database/app_database.dart';
import '../../core/models/peer_identity.dart';
import '../../core/services/chat_data_migration_service.dart';
import '../../core/services/peer_identity_service.dart';
import '../../core/utils/logger.dart';
import '../../features/chat/data/datasources/chat_message_data_source.dart';
import '../../features/chat/data/datasources/conversation_store.dart';
import '../../features/chat/data/datasources/drift_chat_message_data_source.dart';
import '../../features/chat/data/datasources/drift_chat_room_data_source.dart';
import '../../features/chat/data/datasources/drift_conversation_data_source.dart';
import '../../features/chat/data/repositories/chat_repository_impl.dart';
import '../../features/chat/domain/entities/conversation.dart';
import '../../features/chat/domain/repositories/chat_repository.dart';
import '../../features/chat/domain/usecases/send_message.dart';
import '../../features/chat/domain/usecases/watch_messages.dart';
import '../../features/chat/presentation/controllers/chat_controller.dart';
import '../../features/p2p/data/services/latency_probe_service.dart';
import '../../features/p2p/data/services/p2p_service.dart';
import '../../features/p2p/presentation/controllers/p2p_session_controller.dart';

class AppDependencies {
  AppDependencies._();

  static final AppDependencies instance = AppDependencies._();

  final Logger _logger = const Logger('AppDependencies');

  // Database
  AppDatabase? _database;
  ChatDataMigrationService? _migrationService;

  // Drift data sources (SQLite-backed)
  DriftChatMessageDataSource? _driftChatMessageDataSource;
  DriftConversationDataSource? _driftConversationDataSource;
  DriftChatRoomDataSource? _driftChatRoomDataSource;

  // Legacy data sources (for migration compatibility)
  late final ChatMessageDataSource _chatMessageDataSource;
  late final ChatRepository _chatRepository;
  late final SendMessage _sendMessage;
  late final WatchMessages _watchMessages;
  late final P2pService _p2pService;
  late final PeerIdentityService _peerIdentityService;
  late PeerIdentity _peerIdentity;
  late final ConversationStore _conversationStore;
  late final LatencyProbeService _latencyProbeService;
  Map<String, PeerIdentity> _knownPeers = <String, PeerIdentity>{};

  /// Initialize dependencies.
  ///
  /// Pass [executor] for testing with an in-memory database.
  /// If null, uses the default file-based SQLite database.
  Future<void> init({QueryExecutor? executor}) async {
    _logger.info('Initializing dependencies');

    final sharedPreferences = await SharedPreferences.getInstance();

    // Initialize database (use provided executor for tests, or default)
    if (executor != null) {
      _database = AppDatabase(executor);
    } else {
      _database = AppDatabase();
    }

    // Run migration from SharedPreferences to SQLite
    _migrationService = ChatDataMigrationService(
      database: _database!,
      sharedPreferences: sharedPreferences,
    );
    final migrationResult = await _migrationService!.migrate();
    if (migrationResult.totalMigrated > 0) {
      _logger.info('Migration completed: $migrationResult');
    }

    // Initialize drift data sources
    _driftChatMessageDataSource = DriftChatMessageDataSource(_database!);
    _driftConversationDataSource = DriftConversationDataSource(_database!);
    _driftChatRoomDataSource = DriftChatRoomDataSource(_database!);

    // Keep legacy data source for backward compatibility during transition
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

    _latencyProbeService = LatencyProbeService(identity: _peerIdentity);
  }

  ChatController createChatController({required Conversation conversation}) {
    return ChatController(
      sendMessage: _sendMessage,
      watchMessages: _watchMessages,
      identity: _peerIdentity,
      conversation: conversation,
      conversationStore: _conversationStore,
      rememberPeer: (PeerIdentity identity) async {
        await rememberPeer(identity);
      },
      knownPeers: _knownPeers,
    );
  }

  P2pService get p2pService => _p2pService;
  PeerIdentityService get peerIdentityService => _peerIdentityService;
  LatencyProbeService get latencyProbeService => _latencyProbeService;

  // Database and drift data sources
  AppDatabase? get database => _database;
  DriftChatMessageDataSource? get driftChatMessageDataSource =>
      _driftChatMessageDataSource;
  DriftConversationDataSource? get driftConversationDataSource =>
      _driftConversationDataSource;
  DriftChatRoomDataSource? get driftChatRoomDataSource =>
      _driftChatRoomDataSource;

  PeerIdentity get peerIdentity => _peerIdentity;
  Map<String, PeerIdentity> get knownPeers =>
      Map<String, PeerIdentity>.unmodifiable(_knownPeers);

  ConversationStore get conversationStore => _conversationStore;

  P2pSessionController createP2pSessionController() {
    return P2pSessionController(
      p2pService: _p2pService,
      conversationStore: _conversationStore,
      latencyProbeService: _latencyProbeService,
    );
  }

  Future<void> updatePeerDisplayName(String displayName) async {
    final trimmed = displayName.trim();
    final effectiveName = trimmed.isEmpty
        ? _peerIdentityService.defaultDisplayName(_peerIdentity.id)
        : trimmed;
    await _peerIdentityService.setDisplayName(effectiveName);
    _peerIdentity = _peerIdentity.copyWith(displayName: effectiveName);
    _knownPeers[_peerIdentity.id] = _peerIdentity;
    _latencyProbeService.updateIdentity(_peerIdentity);
  }

  Future<void> rememberPeer(PeerIdentity identity) async {
    await _peerIdentityService.rememberPeer(identity);
    _knownPeers[identity.id] = identity;
  }
}
