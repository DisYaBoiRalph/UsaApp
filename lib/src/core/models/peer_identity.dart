class PeerIdentity {
  const PeerIdentity({required this.id, required this.displayName});

  final String id;
  final String displayName;

  PeerIdentity copyWith({String? id, String? displayName}) {
    return PeerIdentity(
      id: id ?? this.id,
      displayName: displayName ?? this.displayName,
    );
  }
}
