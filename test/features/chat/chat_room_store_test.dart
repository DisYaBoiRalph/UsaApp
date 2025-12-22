import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:usaapp/src/features/chat/data/datasources/chat_room_store.dart';
import 'package:usaapp/src/features/chat/data/models/chat_room_model.dart';

void main() {
  late ChatRoomStore store;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    store = ChatRoomStore(sharedPreferences: prefs);
  });

  tearDown(() async {
    await store.dispose();
  });

  group('ChatRoomStore', () {
    test('should create a public room', () async {
      final room = await store.createPublicRoom(
        name: 'General',
        description: 'A public chat room',
        ownerId: 'user-1',
      );

      expect(room.id, startsWith('room_'));
      expect(room.name, 'General');
      expect(room.description, 'A public chat room');
      expect(room.ownerId, 'user-1');
      expect(room.isPrivate, false);
      expect(room.memberIds, contains('user-1'));
    });

    test('should create a private room with password', () async {
      final room = await store.createPrivateRoom(
        name: 'Secret Club',
        description: 'A private chat room',
        ownerId: 'user-1',
        password: 'secret123',
      );

      expect(room.isPrivate, true);
      expect(room.passwordHash, isNotNull);
      expect(room.memberIds, contains('user-1'));
    });

    test('should get room by ID', () async {
      final created = await store.createPublicRoom(
        name: 'Test Room',
        description: 'Test',
        ownerId: 'user-1',
      );

      final found = store.getRoomById(created.id);
      expect(found, isNotNull);
      expect(found!.name, 'Test Room');

      final notFound = store.getRoomById('nonexistent');
      expect(notFound, isNull);
    });

    test('should join public room', () async {
      final room = await store.createPublicRoom(
        name: 'Public Room',
        description: 'Open to all',
        ownerId: 'user-1',
      );

      final joined = await store.joinPublicRoom(
        roomId: room.id,
        userId: 'user-2',
      );

      expect(joined, true);
      final updated = store.getRoomById(room.id);
      expect(updated!.memberIds, contains('user-2'));
    });

    test('should not join private room without password', () async {
      final room = await store.createPrivateRoom(
        name: 'Private Room',
        description: 'Password required',
        ownerId: 'user-1',
        password: 'secret123',
      );

      // Try to join as public room
      final joined = await store.joinPublicRoom(
        roomId: room.id,
        userId: 'user-2',
      );

      expect(joined, false);
    });

    test('should join private room with correct password', () async {
      final room = await store.createPrivateRoom(
        name: 'Private Room',
        description: 'Password required',
        ownerId: 'user-1',
        password: 'secret123',
      );

      final joined = await store.joinPrivateRoom(
        roomId: room.id,
        userId: 'user-2',
        password: 'secret123',
      );

      expect(joined, true);
      final updated = store.getRoomById(room.id);
      expect(updated!.memberIds, contains('user-2'));
    });

    test('should not join private room with wrong password', () async {
      final room = await store.createPrivateRoom(
        name: 'Private Room',
        description: 'Password required',
        ownerId: 'user-1',
        password: 'secret123',
      );

      final joined = await store.joinPrivateRoom(
        roomId: room.id,
        userId: 'user-2',
        password: 'wrongpassword',
      );

      expect(joined, false);
    });

    test('should leave room', () async {
      final room = await store.createPublicRoom(
        name: 'Test Room',
        description: 'Test',
        ownerId: 'user-1',
      );

      await store.joinPublicRoom(roomId: room.id, userId: 'user-2');

      await store.leaveRoom(roomId: room.id, userId: 'user-2');

      final updated = store.getRoomById(room.id);
      expect(updated!.memberIds, isNot(contains('user-2')));
    });

    test('should update room as owner', () async {
      final room = await store.createPublicRoom(
        name: 'Original Name',
        description: 'Original Description',
        ownerId: 'user-1',
      );

      final success = await store.updateRoom(
        roomId: room.id,
        requesterId: 'user-1',
        name: 'New Name',
        description: 'New Description',
      );

      expect(success, true);
      final updated = store.getRoomById(room.id);
      expect(updated!.name, 'New Name');
      expect(updated.description, 'New Description');
    });

    test('should not update room as non-owner', () async {
      final room = await store.createPublicRoom(
        name: 'Original Name',
        description: 'Original Description',
        ownerId: 'user-1',
      );

      final success = await store.updateRoom(
        roomId: room.id,
        requesterId: 'user-2',
        name: 'Hacked Name',
      );

      expect(success, false);
      final unchanged = store.getRoomById(room.id);
      expect(unchanged!.name, 'Original Name');
    });

    test('should delete room as owner', () async {
      final room = await store.createPublicRoom(
        name: 'To Delete',
        description: 'Will be deleted',
        ownerId: 'user-1',
      );

      final success = await store.deleteRoom(
        roomId: room.id,
        requesterId: 'user-1',
      );

      expect(success, true);
      expect(store.getRoomById(room.id), isNull);
    });

    test('should not delete room as non-owner', () async {
      final room = await store.createPublicRoom(
        name: 'Protected',
        description: 'Cannot be deleted by others',
        ownerId: 'user-1',
      );

      final success = await store.deleteRoom(
        roomId: room.id,
        requesterId: 'user-2',
      );

      expect(success, false);
      expect(store.getRoomById(room.id), isNotNull);
    });

    test('should change room password', () async {
      final room = await store.createPrivateRoom(
        name: 'Private Room',
        description: 'Test',
        ownerId: 'user-1',
        password: 'oldpassword',
      );

      final success = await store.changeRoomPassword(
        roomId: room.id,
        requesterId: 'user-1',
        newPassword: 'newpassword',
      );

      expect(success, true);

      // Old password should not work
      final joinWithOld = await store.joinPrivateRoom(
        roomId: room.id,
        userId: 'user-2',
        password: 'oldpassword',
      );
      expect(joinWithOld, false);

      // New password should work
      final joinWithNew = await store.joinPrivateRoom(
        roomId: room.id,
        userId: 'user-2',
        password: 'newpassword',
      );
      expect(joinWithNew, true);
    });

    test('should not join full room', () async {
      final room = await store.createPublicRoom(
        name: 'Small Room',
        description: 'Limited capacity',
        ownerId: 'user-1',
        maxMembers: 2,
      );

      await store.joinPublicRoom(roomId: room.id, userId: 'user-2');

      final joinedThird = await store.joinPublicRoom(
        roomId: room.id,
        userId: 'user-3',
      );

      expect(joinedThird, false);
    });

    test('should emit updates via stream', () async {
      final emissions = <List<dynamic>>[];
      final subscription = store.watchAll().listen(emissions.add);

      await store.createPublicRoom(
        name: 'Room 1',
        description: 'First room',
        ownerId: 'user-1',
      );

      await store.createPublicRoom(
        name: 'Room 2',
        description: 'Second room',
        ownerId: 'user-1',
      );

      await Future<void>.delayed(const Duration(milliseconds: 50));
      await subscription.cancel();

      // Should have at least 2 emissions (one per room creation)
      expect(emissions.length, greaterThanOrEqualTo(2));
      expect(emissions.last.length, 2);
    });
  });

  group('ChatRoomStore Sync', () {
    test('should export rooms for sync', () async {
      await store.createPublicRoom(
        name: 'Room 1',
        description: 'First room',
        ownerId: 'user-1',
      );

      final exported = store.exportForSync();
      final decoded = jsonDecode(exported) as Map<String, dynamic>;

      expect(decoded['rooms'], isA<List<dynamic>>());
      expect((decoded['rooms'] as List<dynamic>).length, 1);
      expect(decoded['exportedAt'], isNotNull);
      expect(decoded['metadata'], isNotNull);
    });

    test('should import rooms from sync', () async {
      final now = DateTime.now().toUtc();
      final syncPayload = jsonEncode({
        'rooms': [
          ChatRoomModel.createPublicRoom(
            id: 'room_abc123',
            name: 'Synced Room',
            description: 'From another device',
            ownerId: 'user-1',
            createdAt: now,
            updatedAt: now,
          ).toJson(),
        ],
        'metadata': <String, dynamic>{},
        'exportedAt': now.toIso8601String(),
      });

      final result = await store.importFromSync(syncPayload);

      expect(result.success, true);
      expect(result.added, 1);
      expect(store.getRoomById('room_abc123'), isNotNull);
    });

    test('should merge rooms using last-write-wins', () async {
      // Create local room
      final localRoom = await store.createPublicRoom(
        name: 'Local Room',
        description: 'Created locally',
        ownerId: 'user-1',
      );

      // Create sync payload with newer version of same room
      final newerTime = DateTime.now().add(const Duration(hours: 1)).toUtc();
      final syncPayload = jsonEncode({
        'rooms': [
          {
            'id': localRoom.id,
            'name': 'Updated Room',
            'description': 'From sync',
            'ownerId': 'user-1',
            'isPrivate': false,
            'memberIds': ['user-1', 'user-2'],
            'createdAt': localRoom.createdAt.toIso8601String(),
            'updatedAt': newerTime.toIso8601String(),
          },
        ],
        'metadata': <String, dynamic>{},
        'exportedAt': newerTime.toIso8601String(),
      });

      final result = await store.importFromSync(syncPayload);

      expect(result.success, true);
      expect(result.updated, 1);

      final merged = store.getRoomById(localRoom.id);
      expect(merged!.name, 'Updated Room');
      expect(merged.memberIds, contains('user-2'));
    });

    test('should skip older rooms during sync', () async {
      // Create local room
      final localRoom = await store.createPublicRoom(
        name: 'Local Room',
        description: 'Created locally',
        ownerId: 'user-1',
      );

      // Create sync payload with older version
      final olderTime = DateTime.now()
          .subtract(const Duration(hours: 1))
          .toUtc();
      final syncPayload = jsonEncode({
        'rooms': [
          {
            'id': localRoom.id,
            'name': 'Old Room Name',
            'description': 'Outdated',
            'ownerId': 'user-1',
            'isPrivate': false,
            'memberIds': ['user-1'],
            'createdAt': olderTime.toIso8601String(),
            'updatedAt': olderTime.toIso8601String(),
          },
        ],
        'metadata': <String, dynamic>{},
        'exportedAt': olderTime.toIso8601String(),
      });

      final result = await store.importFromSync(syncPayload);

      expect(result.success, true);
      expect(result.skipped, 1);

      final unchanged = store.getRoomById(localRoom.id);
      expect(unchanged!.name, 'Local Room'); // Should not be overwritten
    });

    test('should get rooms modified since timestamp', () async {
      await store.createPublicRoom(
        name: 'Room 1',
        description: 'First',
        ownerId: 'user-1',
      );

      final checkpoint = DateTime.now().toUtc();
      await Future<void>.delayed(const Duration(milliseconds: 10));

      await store.createPublicRoom(
        name: 'Room 2',
        description: 'Second',
        ownerId: 'user-1',
      );

      final modifiedSince = store.getRoomsModifiedSince(checkpoint);

      expect(modifiedSince.length, 1);
      expect(modifiedSince.first.name, 'Room 2');
    });

    test('should track sync metadata', () async {
      final room = await store.createPublicRoom(
        name: 'Test Room',
        description: 'Test',
        ownerId: 'user-1',
      );

      final metadata = store.getSyncMetadata();
      expect(metadata[room.id], isNotNull);
      expect(metadata[room.id]!.version, 1);

      await store.updateRoom(
        roomId: room.id,
        requesterId: 'user-1',
        name: 'Updated Name',
      );

      final updatedMetadata = store.getSyncMetadata();
      expect(updatedMetadata[room.id]!.version, 2);
    });
  });

  group('Persistence', () {
    test('should persist and restore rooms across instances', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();

      // Create store and add room
      final store1 = ChatRoomStore(sharedPreferences: prefs);
      final room = await store1.createPublicRoom(
        name: 'Persistent Room',
        description: 'Should persist',
        ownerId: 'user-1',
      );
      await store1.dispose();

      // Create new store instance
      final store2 = ChatRoomStore(sharedPreferences: prefs);
      await store2.init();

      final restored = store2.getRoomById(room.id);
      expect(restored, isNotNull);
      expect(restored!.name, 'Persistent Room');

      await store2.dispose();
    });
  });
}
