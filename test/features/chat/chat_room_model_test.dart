import 'package:flutter_test/flutter_test.dart';
import 'package:usaapp/src/features/chat/data/models/chat_room_model.dart';
import 'package:usaapp/src/features/chat/domain/entities/chat_room.dart';

void main() {
  group('ChatRoom Entity', () {
    test('should create a ChatRoom with required fields', () {
      final now = DateTime.now().toUtc();
      final room = ChatRoom(
        id: 'room-1',
        name: 'Test Room',
        description: 'A test chat room',
        ownerId: 'user-1',
        isPrivate: false,
        createdAt: now,
        updatedAt: now,
      );

      expect(room.id, 'room-1');
      expect(room.name, 'Test Room');
      expect(room.description, 'A test chat room');
      expect(room.ownerId, 'user-1');
      expect(room.isPrivate, false);
      expect(room.passwordHash, isNull);
      expect(room.memberIds, isEmpty);
      expect(room.maxMembers, isNull);
    });

    test('should check if user is member', () {
      final now = DateTime.now().toUtc();
      final room = ChatRoom(
        id: 'room-1',
        name: 'Test Room',
        description: 'A test chat room',
        ownerId: 'user-1',
        isPrivate: false,
        createdAt: now,
        updatedAt: now,
        memberIds: ['user-1', 'user-2'],
      );

      expect(room.isMember('user-1'), true);
      expect(room.isMember('user-2'), true);
      expect(room.isMember('user-3'), false);
    });

    test('should check if user is owner', () {
      final now = DateTime.now().toUtc();
      final room = ChatRoom(
        id: 'room-1',
        name: 'Test Room',
        description: 'A test chat room',
        ownerId: 'user-1',
        isPrivate: false,
        createdAt: now,
        updatedAt: now,
      );

      expect(room.isOwner('user-1'), true);
      expect(room.isOwner('user-2'), false);
    });

    test('should correctly report member count', () {
      final now = DateTime.now().toUtc();
      final room = ChatRoom(
        id: 'room-1',
        name: 'Test Room',
        description: 'A test chat room',
        ownerId: 'user-1',
        isPrivate: false,
        createdAt: now,
        updatedAt: now,
        memberIds: ['user-1', 'user-2', 'user-3'],
      );

      expect(room.memberCount, 3);
    });

    test('should correctly report if room is full', () {
      final now = DateTime.now().toUtc();
      final room = ChatRoom(
        id: 'room-1',
        name: 'Test Room',
        description: 'A test chat room',
        ownerId: 'user-1',
        isPrivate: false,
        createdAt: now,
        updatedAt: now,
        memberIds: ['user-1', 'user-2'],
        maxMembers: 2,
      );

      expect(room.isFull, true);

      final roomNotFull = room.copyWith(maxMembers: 5);
      expect(roomNotFull.isFull, false);

      // Room without max members limit
      final roomUnlimited = ChatRoom(
        id: 'room-1',
        name: 'Test Room',
        description: 'A test chat room',
        ownerId: 'user-1',
        isPrivate: false,
        createdAt: now,
        updatedAt: now,
        memberIds: ['user-1', 'user-2'],
      );
      expect(roomUnlimited.isFull, false);
    });

    test('copyWith should create a new instance with updated values', () {
      final now = DateTime.now().toUtc();
      final room = ChatRoom(
        id: 'room-1',
        name: 'Test Room',
        description: 'A test chat room',
        ownerId: 'user-1',
        isPrivate: false,
        createdAt: now,
        updatedAt: now,
      );

      final updatedRoom = room.copyWith(
        name: 'Updated Room',
        isPrivate: true,
        passwordHash: 'hashed-password',
      );

      expect(updatedRoom.id, 'room-1');
      expect(updatedRoom.name, 'Updated Room');
      expect(updatedRoom.isPrivate, true);
      expect(updatedRoom.passwordHash, 'hashed-password');
    });

    test('equality should be based on id', () {
      final now = DateTime.now().toUtc();
      final room1 = ChatRoom(
        id: 'room-1',
        name: 'Test Room',
        description: 'A test chat room',
        ownerId: 'user-1',
        isPrivate: false,
        createdAt: now,
        updatedAt: now,
      );

      final room2 = ChatRoom(
        id: 'room-1',
        name: 'Different Name',
        description: 'Different description',
        ownerId: 'user-2',
        isPrivate: true,
        createdAt: now,
        updatedAt: now,
      );

      final room3 = ChatRoom(
        id: 'room-2',
        name: 'Test Room',
        description: 'A test chat room',
        ownerId: 'user-1',
        isPrivate: false,
        createdAt: now,
        updatedAt: now,
      );

      expect(room1, equals(room2));
      expect(room1, isNot(equals(room3)));
    });
  });

  group('ChatRoomModel', () {
    test('should create from entity', () {
      final now = DateTime.now().toUtc();
      final entity = ChatRoom(
        id: 'room-1',
        name: 'Test Room',
        description: 'A test chat room',
        ownerId: 'user-1',
        isPrivate: true,
        passwordHash: 'hashed-password',
        memberIds: ['user-1', 'user-2'],
        maxMembers: 10,
        createdAt: now,
        updatedAt: now,
      );

      final model = ChatRoomModel.fromEntity(entity);

      expect(model.id, entity.id);
      expect(model.name, entity.name);
      expect(model.description, entity.description);
      expect(model.ownerId, entity.ownerId);
      expect(model.isPrivate, entity.isPrivate);
      expect(model.passwordHash, entity.passwordHash);
      expect(model.memberIds, entity.memberIds);
      expect(model.maxMembers, entity.maxMembers);
      expect(model.createdAt, entity.createdAt);
      expect(model.updatedAt, entity.updatedAt);
    });

    test('should convert to entity', () {
      final now = DateTime.now().toUtc();
      final model = ChatRoomModel(
        id: 'room-1',
        name: 'Test Room',
        description: 'A test chat room',
        ownerId: 'user-1',
        isPrivate: false,
        createdAt: now,
        updatedAt: now,
      );

      final entity = model.toEntity();

      expect(entity.id, model.id);
      expect(entity.name, model.name);
      expect(entity, isA<ChatRoom>());
    });

    test('should serialize to JSON', () {
      final now = DateTime.utc(2025, 12, 19, 10, 30, 0);
      final model = ChatRoomModel(
        id: 'room-1',
        name: 'Test Room',
        description: 'A test chat room',
        ownerId: 'user-1',
        isPrivate: true,
        passwordHash: 'hashed-password',
        memberIds: ['user-1', 'user-2'],
        maxMembers: 10,
        createdAt: now,
        updatedAt: now,
      );

      final json = model.toJson();

      expect(json['id'], 'room-1');
      expect(json['name'], 'Test Room');
      expect(json['description'], 'A test chat room');
      expect(json['ownerId'], 'user-1');
      expect(json['isPrivate'], true);
      expect(json['passwordHash'], 'hashed-password');
      expect(json['memberIds'], ['user-1', 'user-2']);
      expect(json['maxMembers'], 10);
      expect(json['createdAt'], '2025-12-19T10:30:00.000Z');
      expect(json['updatedAt'], '2025-12-19T10:30:00.000Z');
    });

    test('should deserialize from JSON', () {
      final json = {
        'id': 'room-1',
        'name': 'Test Room',
        'description': 'A test chat room',
        'ownerId': 'user-1',
        'isPrivate': true,
        'passwordHash': 'hashed-password',
        'memberIds': ['user-1', 'user-2'],
        'maxMembers': 10,
        'createdAt': '2025-12-19T10:30:00.000Z',
        'updatedAt': '2025-12-19T10:30:00.000Z',
      };

      final model = ChatRoomModel.fromJson(json);

      expect(model.id, 'room-1');
      expect(model.name, 'Test Room');
      expect(model.description, 'A test chat room');
      expect(model.ownerId, 'user-1');
      expect(model.isPrivate, true);
      expect(model.passwordHash, 'hashed-password');
      expect(model.memberIds, ['user-1', 'user-2']);
      expect(model.maxMembers, 10);
      expect(model.createdAt, DateTime.utc(2025, 12, 19, 10, 30, 0));
      expect(model.updatedAt, DateTime.utc(2025, 12, 19, 10, 30, 0));
    });

    test('should handle missing optional fields in JSON', () {
      final json = {
        'id': 'room-1',
        'name': 'Test Room',
        'ownerId': 'user-1',
        'createdAt': '2025-12-19T10:30:00.000Z',
        'updatedAt': '2025-12-19T10:30:00.000Z',
      };

      final model = ChatRoomModel.fromJson(json);

      expect(model.description, '');
      expect(model.isPrivate, false);
      expect(model.passwordHash, isNull);
      expect(model.memberIds, isEmpty);
      expect(model.maxMembers, isNull);
    });

    test('should hash password correctly', () {
      const password = 'secret123';
      final hash1 = ChatRoomModel.hashPassword(password);
      final hash2 = ChatRoomModel.hashPassword(password);

      expect(hash1, equals(hash2));
      expect(hash1, isNot(equals(password)));
      expect(hash1.length, 64); // SHA-256 produces 64 hex characters
    });

    test('should verify password correctly', () {
      const password = 'secret123';
      final hashedPassword = ChatRoomModel.hashPassword(password);

      final privateRoom = ChatRoomModel(
        id: 'room-1',
        name: 'Private Room',
        description: 'A private chat room',
        ownerId: 'user-1',
        isPrivate: true,
        passwordHash: hashedPassword,
        createdAt: DateTime.now().toUtc(),
        updatedAt: DateTime.now().toUtc(),
      );

      expect(privateRoom.verifyPassword('secret123'), true);
      expect(privateRoom.verifyPassword('wrongpassword'), false);
    });

    test('should return true for public rooms without password check', () {
      final publicRoom = ChatRoomModel(
        id: 'room-1',
        name: 'Public Room',
        description: 'A public chat room',
        ownerId: 'user-1',
        isPrivate: false,
        createdAt: DateTime.now().toUtc(),
        updatedAt: DateTime.now().toUtc(),
      );

      expect(publicRoom.verifyPassword('anypassword'), true);
      expect(publicRoom.verifyPassword(''), true);
    });

    test('should create private room with hashed password', () {
      final room = ChatRoomModel.createPrivateRoom(
        id: 'room-1',
        name: 'Private Room',
        description: 'A private chat room',
        ownerId: 'user-1',
        password: 'secret123',
      );

      expect(room.isPrivate, true);
      expect(room.passwordHash, isNotNull);
      expect(room.passwordHash, isNot(equals('secret123')));
      expect(room.verifyPassword('secret123'), true);
      expect(room.verifyPassword('wrongpassword'), false);
      expect(room.memberIds, contains('user-1'));
    });

    test('should create public room without password', () {
      final room = ChatRoomModel.createPublicRoom(
        id: 'room-1',
        name: 'Public Room',
        description: 'A public chat room',
        ownerId: 'user-1',
      );

      expect(room.isPrivate, false);
      expect(room.passwordHash, isNull);
      expect(room.memberIds, contains('user-1'));
    });

    test('copyWith should return ChatRoomModel', () {
      final now = DateTime.now().toUtc();
      final model = ChatRoomModel(
        id: 'room-1',
        name: 'Test Room',
        description: 'A test chat room',
        ownerId: 'user-1',
        isPrivate: false,
        createdAt: now,
        updatedAt: now,
      );

      final copied = model.copyWith(name: 'New Name');

      expect(copied, isA<ChatRoomModel>());
      expect(copied.name, 'New Name');
      expect(copied.id, 'room-1');
    });

    test('JSON round-trip should preserve data', () {
      final original = ChatRoomModel.createPrivateRoom(
        id: 'room-1',
        name: 'Private Room',
        description: 'A private chat room',
        ownerId: 'user-1',
        password: 'secret123',
        memberIds: ['user-1', 'user-2'],
        maxMembers: 10,
      );

      final json = original.toJson();
      final restored = ChatRoomModel.fromJson(json);

      expect(restored.id, original.id);
      expect(restored.name, original.name);
      expect(restored.description, original.description);
      expect(restored.ownerId, original.ownerId);
      expect(restored.isPrivate, original.isPrivate);
      expect(restored.passwordHash, original.passwordHash);
      expect(restored.memberIds, original.memberIds);
      expect(restored.maxMembers, original.maxMembers);
      expect(restored.verifyPassword('secret123'), true);
    });
  });
}
