enum UserRole {
  student,
  teacher,
  other;

  String get displayName {
    switch (this) {
      case UserRole.student:
        return 'Student';
      case UserRole.teacher:
        return 'Teacher';
      case UserRole.other:
        return 'Other';
    }
  }
}

class PeerIdentity {
  const PeerIdentity({
    required this.id,
    required this.displayName,
    this.name,
    this.profileImage,
    this.groupName,
    this.role = UserRole.other,
  });

  final String id;
  final String displayName;
  final String? name;

  /// Profile image as base64-encoded string (without data URI prefix)
  final String? profileImage;
  final String? groupName;
  final UserRole role;

  PeerIdentity copyWith({
    String? id,
    String? displayName,
    String? name,
    String? profileImage,
    String? groupName,
    UserRole? role,
  }) {
    return PeerIdentity(
      id: id ?? this.id,
      displayName: displayName ?? this.displayName,
      name: name ?? this.name,
      profileImage: profileImage ?? this.profileImage,
      groupName: groupName ?? this.groupName,
      role: role ?? this.role,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'displayName': displayName,
      'name': name,
      'profileImage': profileImage,
      'groupName': groupName,
      'role': role.name,
    };
  }

  factory PeerIdentity.fromJson(Map<String, dynamic> json) {
    return PeerIdentity(
      id: json['id'] as String,
      displayName: json['displayName'] as String,
      name: json['name'] as String?,
      profileImage: json['profileImage'] as String?,
      groupName: json['groupName'] as String?,
      role: UserRole.values.firstWhere(
        (e) => e.name == json['role'],
        orElse: () => UserRole.other,
      ),
    );
  }
}
