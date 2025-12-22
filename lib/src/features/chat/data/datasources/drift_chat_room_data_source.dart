import '../../../../core/database/app_database.dart';
import '../../domain/entities/chat_room.dart';
import '../models/chat_room_model.dart';

/// Data source for chat rooms using drift (SQLite).
class DriftChatRoomDataSource {
  DriftChatRoomDataSource(this._db);

  final AppDatabase _db;

  /// Watch all chat rooms.
  Stream<List<ChatRoom>> watchAll() {
    return _db.watchAllRooms().map(
      (entries) => entries.map(_entryToRoom).toList(growable: false),
    );
  }

  /// Get a room by ID.
  Future<ChatRoom?> getRoomById(String id) async {
    final entry = await _db.getRoomById(id);
    return entry != null ? _entryToRoom(entry) : null;
  }

  /// Get a room model by ID (includes password hash for verification).
  Future<ChatRoomModel?> getRoomModelById(String id) async {
    final entry = await _db.getRoomById(id);
    return entry != null ? _entryToModel(entry) : null;
  }

  /// Save a chat room.
  Future<void> saveRoom(ChatRoomModel room) async {
    await _db.upsertRoom(_modelToEntry(room));
    await _db.updateSyncMetadata(room.id, 'room');
  }

  /// Delete a chat room.
  Future<void> deleteRoom(String id) async {
    await _db.deleteRoom(id);
  }

  /// Get rooms modified since a timestamp.
  Future<List<ChatRoomModel>> getRoomsModifiedSince(DateTime since) async {
    final entries = await _db.getRoomsModifiedSince(since);
    return entries.map(_entryToModel).toList(growable: false);
  }

  /// Insert multiple rooms in batch (for migration/sync).
  Future<void> insertRoomsBatch(List<ChatRoomModel> rooms) async {
    for (final room in rooms) {
      await _db.upsertRoom(_modelToEntry(room));
      await _db.updateSyncMetadata(room.id, 'room');
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // CONVERTERS
  // ─────────────────────────────────────────────────────────────────────────

  ChatRoom _entryToRoom(ChatRoomEntry entry) {
    return ChatRoom(
      id: entry.id,
      name: entry.name,
      description: entry.description,
      ownerId: entry.ownerId,
      isPrivate: entry.isPrivate,
      passwordHash: entry.passwordHash,
      memberIds: entry.memberIdsList,
      maxMembers: entry.maxMembers,
      createdAt: entry.createdAt,
      updatedAt: entry.updatedAt,
    );
  }

  ChatRoomModel _entryToModel(ChatRoomEntry entry) {
    return ChatRoomModel(
      id: entry.id,
      name: entry.name,
      description: entry.description,
      ownerId: entry.ownerId,
      isPrivate: entry.isPrivate,
      passwordHash: entry.passwordHash,
      memberIds: entry.memberIdsList,
      maxMembers: entry.maxMembers,
      createdAt: entry.createdAt,
      updatedAt: entry.updatedAt,
    );
  }

  ChatRoomEntry _modelToEntry(ChatRoomModel room) {
    return ChatRoomEntry(
      id: room.id,
      name: room.name,
      description: room.description,
      ownerId: room.ownerId,
      isPrivate: room.isPrivate,
      passwordHash: room.passwordHash,
      memberIds: encodeMemberIds(room.memberIds),
      maxMembers: room.maxMembers,
      createdAt: room.createdAt,
      updatedAt: room.updatedAt,
    );
  }
}
