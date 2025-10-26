import 'dart:convert';
import 'dart:math';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/peer_identity.dart';

class PeerIdentityService {
  static const String _idKey = 'peer_identity_id';
  static const String _nameKey = 'peer_identity_display_name';
  static const String _knownPeersKey = 'peer_identity_known_peers_v1';

  final Map<String, String> _knownPeersCache = <String, String>{};

  Future<PeerIdentity> getIdentity() async {
    final prefs = await SharedPreferences.getInstance();
    final id = await _ensureId(prefs);
    final name = prefs.getString(_nameKey) ?? _defaultDisplayName(id);
    return PeerIdentity(id: id, displayName: name);
  }

  Future<void> setDisplayName(String name) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_nameKey, name.trim());
  }

  String defaultDisplayName(String id) => _defaultDisplayName(id);

  Future<void> rememberPeer({
    required String id,
    required String displayName,
  }) async {
    if (id.isEmpty) {
      return;
    }
    final prefs = await SharedPreferences.getInstance();
    final cache = await _loadKnownPeers(prefs);
    final trimmed = displayName.trim();
    if (trimmed.isEmpty) {
      cache.remove(id);
    } else {
      cache[id] = trimmed;
    }
    await _persistKnownPeers(prefs, cache);
  }

  Future<Map<String, String>> getKnownPeers() async {
    final prefs = await SharedPreferences.getInstance();
    return Map<String, String>.unmodifiable(await _loadKnownPeers(prefs));
  }

  Future<Map<String, String>> _loadKnownPeers(SharedPreferences prefs) async {
    if (_knownPeersCache.isNotEmpty) {
      return _knownPeersCache;
    }
    final raw = prefs.getString(_knownPeersKey);
    if (raw != null && raw.isNotEmpty) {
      try {
        final decoded = jsonDecode(raw);
        if (decoded is Map) {
          decoded.forEach((key, value) {
            if (key is String && value is String) {
              _knownPeersCache[key] = value;
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
    Map<String, String> cache,
  ) async {
    await prefs.setString(_knownPeersKey, jsonEncode(cache));
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
