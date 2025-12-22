import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/chat_room_model.dart';
import '../../domain/entities/chat_room.dart';

/// Stores and manages chat rooms with support for sync across devices.
///
/// Chat rooms are persisted to SharedPreferences and can be synchronized
/// using their unique IDs. The store emits updates via a stream whenever
/// the room list changes.
class ChatRoomStore {
  ChatRoomStore({SharedPreferences? sharedPreferences})
    : _sharedPreferences = sharedPreferences;

  static const String _storageKey = 'chat_room_store_v1';
  static const String _syncMetadataKey = 'chat_room_sync_metadata_v1';

  SharedPreferences? _sharedPreferences;
  bool _initialized = false;

  final StreamController<List<ChatRoom>> _controller =
      StreamController<List<ChatRoom>>.broadcast();
  final List<ChatRoomModel> _rooms = <ChatRoomModel>[];

  /// Sync metadata tracking last sync time and version per room.
  final Map<String, RoomSyncMetadata> _syncMetadata =
      <String, RoomSyncMetadata>{};

  /// Initializes the store by loading persisted rooms.
  Future<void> init() async {
    if (_initialized) {
      return;
    }

    _sharedPreferences ??= await SharedPreferences.getInstance();
    await _loadRooms();
    await _loadSyncMetadata();

    _initialized = true;
    _emit();
  }

  /// Returns a stream of all chat rooms, sorted by last updated.
  Stream<List<ChatRoom>> watchAll() {
    scheduleMicrotask(_emit);
    return _controller.stream;
  }

  /// Returns the current list of chat rooms.
  List<ChatRoom> get current => List<ChatRoom>.unmodifiable(_rooms);

  /// Returns a room by ID, or null if not found.
  ChatRoom? getRoomById(String id) {
    final index = _rooms.indexWhere((room) => room.id == id);
    return index >= 0 ? _rooms[index] : null;
  }

  /// Creates a new public chat room.
  Future<ChatRoom> createPublicRoom({
    required String name,
    required String description,
    required String ownerId,
    int? maxMembers,
  }) async {
    await init();
    final room = ChatRoomModel.createPublicRoom(
      id: _generateId(),
      name: name,
      description: description,
      ownerId: ownerId,
      maxMembers: maxMembers,
    );
    _rooms.add(room);
    _updateSyncMetadata(room.id);
    await _persist();
    _emit();
    return room;
  }

  /// Creates a new private chat room with password protection.
  Future<ChatRoom> createPrivateRoom({
    required String name,
    required String description,
    required String ownerId,
    required String password,
    int? maxMembers,
  }) async {
    await init();
    final room = ChatRoomModel.createPrivateRoom(
      id: _generateId(),
      name: name,
      description: description,
      ownerId: ownerId,
      password: password,
      maxMembers: maxMembers,
    );
    _rooms.add(room);
    _updateSyncMetadata(room.id);
    await _persist();
    _emit();
    return room;
  }

  /// Attempts to join a private room with the given password.
  /// Returns true if successful, false if password is incorrect.
  Future<bool> joinPrivateRoom({
    required String roomId,
    required String userId,
    required String password,
  }) async {
    await init();
    final index = _rooms.indexWhere((room) => room.id == roomId);
    if (index < 0) {
      return false;
    }

    final room = _rooms[index];
    if (!room.verifyPassword(password)) {
      return false;
    }

    if (room.isFull) {
      return false;
    }

    if (!room.memberIds.contains(userId)) {
      final updatedMembers = [...room.memberIds, userId];
      _rooms[index] = room.copyWith(
        memberIds: updatedMembers,
        updatedAt: DateTime.now().toUtc(),
      );
      _updateSyncMetadata(roomId);
      await _persist();
      _emit();
    }

    return true;
  }

  /// Joins a public room (no password required).
  Future<bool> joinPublicRoom({
    required String roomId,
    required String userId,
  }) async {
    await init();
    final index = _rooms.indexWhere((room) => room.id == roomId);
    if (index < 0) {
      return false;
    }

    final room = _rooms[index];
    if (room.isPrivate) {
      return false; // Use joinPrivateRoom for private rooms
    }

    if (room.isFull) {
      return false;
    }

    if (!room.memberIds.contains(userId)) {
      final updatedMembers = [...room.memberIds, userId];
      _rooms[index] = room.copyWith(
        memberIds: updatedMembers,
        updatedAt: DateTime.now().toUtc(),
      );
      _updateSyncMetadata(roomId);
      await _persist();
      _emit();
    }

    return true;
  }

  /// Removes a user from a room.
  Future<void> leaveRoom({
    required String roomId,
    required String userId,
  }) async {
    await init();
    final index = _rooms.indexWhere((room) => room.id == roomId);
    if (index < 0) {
      return;
    }

    final room = _rooms[index];
    final updatedMembers = room.memberIds.where((id) => id != userId).toList();

    _rooms[index] = room.copyWith(
      memberIds: updatedMembers,
      updatedAt: DateTime.now().toUtc(),
    );
    _updateSyncMetadata(roomId);
    await _persist();
    _emit();
  }

  /// Updates a room's details (only owner can update).
  Future<bool> updateRoom({
    required String roomId,
    required String requesterId,
    String? name,
    String? description,
    int? maxMembers,
  }) async {
    await init();
    final index = _rooms.indexWhere((room) => room.id == roomId);
    if (index < 0) {
      return false;
    }

    final room = _rooms[index];
    if (!room.isOwner(requesterId)) {
      return false;
    }

    _rooms[index] = room.copyWith(
      name: name,
      description: description,
      maxMembers: maxMembers,
      updatedAt: DateTime.now().toUtc(),
    );
    _updateSyncMetadata(roomId);
    await _persist();
    _emit();
    return true;
  }

  /// Changes the password for a private room (only owner can change).
  Future<bool> changeRoomPassword({
    required String roomId,
    required String requesterId,
    required String newPassword,
  }) async {
    await init();
    final index = _rooms.indexWhere((room) => room.id == roomId);
    if (index < 0) {
      return false;
    }

    final room = _rooms[index];
    if (!room.isOwner(requesterId)) {
      return false;
    }

    final newHash = ChatRoomModel.hashPassword(newPassword);
    _rooms[index] = room.copyWith(
      isPrivate: true,
      passwordHash: newHash,
      updatedAt: DateTime.now().toUtc(),
    );
    _updateSyncMetadata(roomId);
    await _persist();
    _emit();
    return true;
  }

  /// Deletes a room (only owner can delete).
  Future<bool> deleteRoom({
    required String roomId,
    required String requesterId,
  }) async {
    await init();
    final index = _rooms.indexWhere((room) => room.id == roomId);
    if (index < 0) {
      return false;
    }

    final room = _rooms[index];
    if (!room.isOwner(requesterId)) {
      return false;
    }

    _rooms.removeAt(index);
    _syncMetadata.remove(roomId);
    await _persist();
    await _persistSyncMetadata();
    _emit();
    return true;
  }

  // ─────────────────────────────────────────────────────────────────────────
  // SYNC SUPPORT
  // ─────────────────────────────────────────────────────────────────────────

  /// Returns sync metadata for all rooms (used for sync negotiation).
  Map<String, RoomSyncMetadata> getSyncMetadata() {
    return Map<String, RoomSyncMetadata>.unmodifiable(_syncMetadata);
  }

  /// Returns rooms that have been modified since the given timestamp.
  List<ChatRoomModel> getRoomsModifiedSince(DateTime since) {
    return _rooms
        .where((room) => room.updatedAt.isAfter(since))
        .toList(growable: false);
  }

  /// Exports all rooms as JSON for sync purposes.
  String exportForSync() {
    final data = {
      'rooms': _rooms.map((room) => room.toJson()).toList(),
      'metadata': _syncMetadata.map(
        (key, value) => MapEntry(key, value.toJson()),
      ),
      'exportedAt': DateTime.now().toUtc().toIso8601String(),
    };
    return jsonEncode(data);
  }

  /// Imports rooms from a sync payload, merging with existing data.
  /// Uses last-write-wins strategy based on updatedAt timestamps.
  Future<SyncResult> importFromSync(String jsonPayload) async {
    await init();

    try {
      final decoded = jsonDecode(jsonPayload);
      if (decoded is! Map<String, dynamic>) {
        return const SyncResult(
          success: false,
          error: 'Invalid sync payload format',
        );
      }

      final roomsJson = decoded['rooms'];
      if (roomsJson is! List) {
        return const SyncResult(success: false, error: 'Missing rooms array');
      }

      var added = 0;
      var updated = 0;
      var skipped = 0;

      for (final roomData in roomsJson) {
        if (roomData is! Map<String, dynamic>) {
          skipped++;
          continue;
        }

        try {
          final incomingRoom = ChatRoomModel.fromJson(roomData);
          final existingIndex = _rooms.indexWhere(
            (room) => room.id == incomingRoom.id,
          );

          if (existingIndex < 0) {
            // New room - add it
            _rooms.add(incomingRoom);
            _updateSyncMetadata(incomingRoom.id);
            added++;
          } else {
            // Existing room - merge using last-write-wins
            final existing = _rooms[existingIndex];
            if (incomingRoom.updatedAt.isAfter(existing.updatedAt)) {
              _rooms[existingIndex] = incomingRoom;
              _updateSyncMetadata(incomingRoom.id);
              updated++;
            } else {
              skipped++;
            }
          }
        } catch (_) {
          skipped++;
        }
      }

      await _persist();
      _emit();

      return SyncResult(
        success: true,
        added: added,
        updated: updated,
        skipped: skipped,
      );
    } catch (e) {
      return SyncResult(success: false, error: 'Sync import failed: $e');
    }
  }

  /// Ensures a room exists (used when receiving room data from peers).
  Future<ChatRoom> ensureRoomExists(ChatRoomModel room) async {
    await init();
    final index = _rooms.indexWhere((r) => r.id == room.id);

    if (index >= 0) {
      final existing = _rooms[index];
      // Update if incoming is newer
      if (room.updatedAt.isAfter(existing.updatedAt)) {
        _rooms[index] = room;
        _updateSyncMetadata(room.id);
        await _persist();
        _emit();
      }
      return _rooms[index];
    }

    _rooms.add(room);
    _updateSyncMetadata(room.id);
    await _persist();
    _emit();
    return room;
  }

  // ─────────────────────────────────────────────────────────────────────────
  // PRIVATE HELPERS
  // ─────────────────────────────────────────────────────────────────────────

  Future<void> _loadRooms() async {
    final raw = _sharedPreferences!.getString(_storageKey);
    if (raw != null && raw.isNotEmpty) {
      try {
        final decoded = jsonDecode(raw);
        if (decoded is List) {
          _rooms
            ..clear()
            ..addAll(
              decoded.whereType<Map<String, dynamic>>().map(
                ChatRoomModel.fromJson,
              ),
            );
        }
      } catch (_) {
        // Corrupted data - start fresh
        _rooms.clear();
      }
    }
  }

  Future<void> _loadSyncMetadata() async {
    final raw = _sharedPreferences!.getString(_syncMetadataKey);
    if (raw != null && raw.isNotEmpty) {
      try {
        final decoded = jsonDecode(raw);
        if (decoded is Map) {
          _syncMetadata.clear();
          decoded.forEach((key, value) {
            if (key is String && value is Map) {
              try {
                _syncMetadata[key] = RoomSyncMetadata.fromJson(
                  value.cast<String, dynamic>(),
                );
              } catch (_) {
                // Skip invalid entries
              }
            }
          });
        }
      } catch (_) {
        _syncMetadata.clear();
      }
    }
  }

  Future<void> _persist() async {
    _rooms.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    await _sharedPreferences!.setString(
      _storageKey,
      jsonEncode(_rooms.map((room) => room.toJson()).toList()),
    );
    await _persistSyncMetadata();
  }

  Future<void> _persistSyncMetadata() async {
    await _sharedPreferences!.setString(
      _syncMetadataKey,
      jsonEncode(
        _syncMetadata.map((key, value) => MapEntry(key, value.toJson())),
      ),
    );
  }

  void _updateSyncMetadata(String roomId) {
    final existing = _syncMetadata[roomId];
    _syncMetadata[roomId] = RoomSyncMetadata(
      lastModified: DateTime.now().toUtc(),
      version: (existing?.version ?? 0) + 1,
    );
  }

  void _emit() {
    if (_controller.isClosed) {
      return;
    }
    _controller.add(List<ChatRoom>.unmodifiable(_rooms));
  }

  String _generateId() {
    final random = Random.secure();
    final buffer = StringBuffer();
    // Use 'room_' prefix for easy identification
    buffer.write('room_');
    for (var i = 0; i < 12; i++) {
      buffer.write(_alphabet[random.nextInt(_alphabet.length)]);
    }
    return buffer.toString();
  }

  Future<void> dispose() async {
    await _controller.close();
  }
}

const String _alphabet = 'abcdefghijklmnopqrstuvwxyz0123456789';

/// Metadata for tracking sync state of a room.
class RoomSyncMetadata {
  const RoomSyncMetadata({required this.lastModified, required this.version});

  final DateTime lastModified;
  final int version;

  Map<String, dynamic> toJson() {
    return {
      'lastModified': lastModified.toUtc().toIso8601String(),
      'version': version,
    };
  }

  factory RoomSyncMetadata.fromJson(Map<String, dynamic> json) {
    return RoomSyncMetadata(
      lastModified: DateTime.parse(json['lastModified'] as String).toUtc(),
      version: json['version'] as int,
    );
  }
}

/// Result of a sync operation.
class SyncResult {
  const SyncResult({
    required this.success,
    this.added = 0,
    this.updated = 0,
    this.skipped = 0,
    this.error,
  });

  final bool success;
  final int added;
  final int updated;
  final int skipped;
  final String? error;

  @override
  String toString() {
    if (!success) {
      return 'SyncResult(failed: $error)';
    }
    return 'SyncResult(added: $added, updated: $updated, skipped: $skipped)';
  }
}
