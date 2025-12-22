/// Represents a chat room where multiple users can communicate.
class ChatRoom {
  const ChatRoom({
    required this.id,
    required this.name,
    required this.description,
    required this.ownerId,
    required this.isPrivate,
    required this.createdAt,
    required this.updatedAt,
    this.passwordHash,
    this.memberIds = const [],
    this.maxMembers,
  });

  /// Unique identifier for the chat room.
  final String id;

  /// Display name of the chat room.
  final String name;

  /// Optional description of the chat room's purpose.
  final String description;

  /// The user ID of the room creator/owner.
  final String ownerId;

  /// Whether the room requires a password to join.
  final bool isPrivate;

  /// Hashed password for private rooms (null for public rooms).
  final String? passwordHash;

  /// List of user IDs who are members of this room.
  final List<String> memberIds;

  /// Maximum number of members allowed (null for unlimited).
  final int? maxMembers;

  /// When the room was created.
  final DateTime createdAt;

  /// When the room was last updated.
  final DateTime updatedAt;

  /// Returns true if the room has reached its member capacity.
  bool get isFull => maxMembers != null && memberIds.length >= maxMembers!;

  /// Returns the current number of members.
  int get memberCount => memberIds.length;

  /// Checks if a user is a member of this room.
  bool isMember(String userId) => memberIds.contains(userId);

  /// Checks if a user is the owner of this room.
  bool isOwner(String userId) => ownerId == userId;

  ChatRoom copyWith({
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
    return ChatRoom(
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

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ChatRoom && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
