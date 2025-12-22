import 'dart:convert';
import 'dart:math';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/peer_identity.dart';

class PeerIdentityService {
  static const String _idKey = 'peer_identity_id';
  static const String _nameKey = 'peer_identity_display_name';
  static const String _fullNameKey = 'peer_identity_full_name';
  static const String _profileImageKey = 'peer_identity_profile_image';
  static const String _groupNameKey = 'peer_identity_group_name';
  static const String _roleKey = 'peer_identity_role';
  static const String _knownPeersKey = 'peer_identity_known_peers_v2';

  final Map<String, PeerIdentity> _knownPeersCache = <String, PeerIdentity>{};

  Future<PeerIdentity> getIdentity() async {
    final prefs = await SharedPreferences.getInstance();
    final id = await _ensureId(prefs);
    final displayName = prefs.getString(_nameKey) ?? _defaultDisplayName(id);
    final name = prefs.getString(_fullNameKey);
    final profileImage = prefs.getString(_profileImageKey);
    final groupName = prefs.getString(_groupNameKey);
    final roleString = prefs.getString(_roleKey);
    final role = roleString != null
        ? UserRole.values.firstWhere(
            (e) => e.name == roleString,
            orElse: () => UserRole.other,
          )
        : UserRole.other;

    return PeerIdentity(
      id: id,
      displayName: displayName,
      name: name,
      profileImage: profileImage,
      groupName: groupName,
      role: role,
    );
  }

  Future<void> setDisplayName(String name) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_nameKey, name.trim());
  }

  Future<void> updateProfile({
    String? name,
    String? profileImage,
    String? groupName,
    UserRole? role,
  }) async {
    final prefs = await SharedPreferences.getInstance();

    if (name != null) {
      if (name.isEmpty) {
        await prefs.remove(_fullNameKey);
      } else {
        await prefs.setString(_fullNameKey, name.trim());
      }
    }
    if (profileImage != null) {
      if (profileImage.isEmpty) {
        await prefs.remove(_profileImageKey);
      } else {
        await prefs.setString(_profileImageKey, profileImage);
      }
    }
    if (groupName != null) {
      if (groupName.isEmpty) {
        await prefs.remove(_groupNameKey);
      } else {
        await prefs.setString(_groupNameKey, groupName.trim());
      }
    }
    if (role != null) {
      await prefs.setString(_roleKey, role.name);
    }
  }

  String defaultDisplayName(String id) => _defaultDisplayName(id);

  Future<void> rememberPeer(PeerIdentity identity) async {
    if (identity.id.isEmpty) {
      return;
    }
    final prefs = await SharedPreferences.getInstance();
    final cache = await _loadKnownPeers(prefs);
    cache[identity.id] = identity;
    await _persistKnownPeers(prefs, cache);
  }

  Future<Map<String, PeerIdentity>> getKnownPeers() async {
    final prefs = await SharedPreferences.getInstance();
    return Map<String, PeerIdentity>.unmodifiable(await _loadKnownPeers(prefs));
  }

  Future<Map<String, PeerIdentity>> _loadKnownPeers(
    SharedPreferences prefs,
  ) async {
    if (_knownPeersCache.isNotEmpty) {
      return _knownPeersCache;
    }
    final raw = prefs.getString(_knownPeersKey);
    if (raw != null && raw.isNotEmpty) {
      try {
        final decoded = jsonDecode(raw);
        if (decoded is Map) {
          decoded.forEach((key, value) {
            if (key is String && value is Map) {
              try {
                final identity = PeerIdentity.fromJson(
                  value.cast<String, dynamic>(),
                );
                _knownPeersCache[key] = identity;
              } catch (_) {
                // Skip invalid entries
              }
            }
          });
        }
      } catch (_) {
        _knownPeersCache.clear();
      }
    }
    return _knownPeersCache;
  }

  Future<void> _persistKnownPeers(
    SharedPreferences prefs,
    Map<String, PeerIdentity> cache,
  ) async {
    final jsonMap = cache.map((key, value) => MapEntry(key, value.toJson()));
    await prefs.setString(_knownPeersKey, jsonEncode(jsonMap));
  }

  Future<String> _ensureId(SharedPreferences prefs) async {
    final existing = prefs.getString(_idKey);
    if (existing != null && existing.isNotEmpty) {
      return existing;
    }

    final generated = _generateId();
    await prefs.setString(_idKey, generated);
    return generated;
  }

  String _generateId() {
    final random = Random.secure();
    final buffer = StringBuffer();
    for (var i = 0; i < 16; i++) {
      buffer.write(_alphabet[random.nextInt(_alphabet.length)]);
    }
    return buffer.toString();
  }

  String _defaultDisplayName(String id) {
    final suffix = id.length >= 4 ? id.substring(0, 4).toUpperCase() : id;
    return 'Peer-$suffix';
  }
}

const String _alphabet = 'abcdefghijklmnopqrstuvwxyz0123456789';
