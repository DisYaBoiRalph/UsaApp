import 'dart:convert';

import 'package:crypto/crypto.dart';

import '../../domain/entities/chat_room.dart';

/// Data model for [ChatRoom] with JSON serialization support.
class ChatRoomModel extends ChatRoom {
  const ChatRoomModel({
    required super.id,
    required super.name,
    required super.description,
    required super.ownerId,
    required super.isPrivate,
    required super.createdAt,
    required super.updatedAt,
    super.passwordHash,
    super.memberIds,
    super.maxMembers,
  });

  /// Creates a [ChatRoomModel] from a [ChatRoom] entity.
  factory ChatRoomModel.fromEntity(ChatRoom entity) {
    return ChatRoomModel(
      id: entity.id,
      name: entity.name,
      description: entity.description,
      ownerId: entity.ownerId,
      isPrivate: entity.isPrivate,
      passwordHash: entity.passwordHash,
      memberIds: entity.memberIds,
      maxMembers: entity.maxMembers,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }

  /// Creates a [ChatRoomModel] from a JSON map.
  factory ChatRoomModel.fromJson(Map<String, dynamic> json) {
    final createdAtRaw = json['createdAt'];
    final updatedAtRaw = json['updatedAt'];
    final memberIdsRaw = json['memberIds'];

    return ChatRoomModel(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String? ?? '',
      ownerId: json['ownerId'] as String,
      isPrivate: json['isPrivate'] as bool? ?? false,
      passwordHash: json['passwordHash'] as String?,
      memberIds: memberIdsRaw is List
          ? List<String>.from(memberIdsRaw.map((e) => e.toString()))
          : const [],
      maxMembers: json['maxMembers'] as int?,
      createdAt: createdAtRaw is String
          ? DateTime.tryParse(createdAtRaw)?.toUtc() ?? DateTime.now().toUtc()
          : DateTime.now().toUtc(),
      updatedAt: updatedAtRaw is String
          ? DateTime.tryParse(updatedAtRaw)?.toUtc() ?? DateTime.now().toUtc()
          : DateTime.now().toUtc(),
    );
  }

  /// Converts this model to a [ChatRoom] entity.
  ChatRoom toEntity() {
    return ChatRoom(
      id: id,
      name: name,
      description: description,
      ownerId: ownerId,
      isPrivate: isPrivate,
      passwordHash: passwordHash,
      memberIds: memberIds,
      maxMembers: maxMembers,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  /// Converts this model to a JSON map.
  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'name': name,
      'description': description,
      'ownerId': ownerId,
      'isPrivate': isPrivate,
      'passwordHash': passwordHash,
      'memberIds': memberIds,
      'maxMembers': maxMembers,
      'createdAt': createdAt.toUtc().toIso8601String(),
      'updatedAt': updatedAt.toUtc().toIso8601String(),
    };
  }

  /// Hashes a password using SHA-256 for secure storage.
  static String hashPassword(String password) {
    final bytes = utf8.encode(password);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// Verifies if the provided password matches the stored hash.
  bool verifyPassword(String password) {
    if (!isPrivate || passwordHash == null) return true;
    return hashPassword(password) == passwordHash;
  }

  /// Creates a new private room with a hashed password.
  static ChatRoomModel createPrivateRoom({
    required String id,
    required String name,
    required String description,
    required String ownerId,
    required String password,
    List<String> memberIds = const [],
    int? maxMembers,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    final now = DateTime.now().toUtc();
    return ChatRoomModel(
      id: id,
      name: name,
      description: description,
      ownerId: ownerId,
      isPrivate: true,
      passwordHash: hashPassword(password),
      memberIds: memberIds.isEmpty ? [ownerId] : memberIds,
      maxMembers: maxMembers,
      createdAt: createdAt ?? now,
      updatedAt: updatedAt ?? now,
    );
  }

  /// Creates a new public room (no password required).
  static ChatRoomModel createPublicRoom({
    required String id,
    required String name,
    required String description,
    required String ownerId,
    List<String> memberIds = const [],
    int? maxMembers,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    final now = DateTime.now().toUtc();
    return ChatRoomModel(
      id: id,
      name: name,
      description: description,
      ownerId: ownerId,
      isPrivate: false,
      memberIds: memberIds.isEmpty ? [ownerId] : memberIds,
      maxMembers: maxMembers,
      createdAt: createdAt ?? now,
      updatedAt: updatedAt ?? now,
    );
  }

  @override
  ChatRoomModel copyWith({
    String? id,
    String? name,
    String? description,
    String? ownerId,
    bool? isPrivate,
    String? passwordHash,
    List<String>? memberIds,
    int? maxMembers,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ChatRoomModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      ownerId: ownerId ?? this.ownerId,
      isPrivate: isPrivate ?? this.isPrivate,
      passwordHash: passwordHash ?? this.passwordHash,
      memberIds: memberIds ?? this.memberIds,
      maxMembers: maxMembers ?? this.maxMembers,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
