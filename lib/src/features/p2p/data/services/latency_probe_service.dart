import 'dart:async';
import 'dart:convert';
import 'dart:math';

import '../../../../core/models/peer_identity.dart';
import '../../../../core/utils/logger.dart';

const String latencyProbeMessagePrefix = '__usaapp_latency__:';

class LatencyProbeSample {
  const LatencyProbeSample({
    required this.probeId,
    required this.sequence,
    required this.originId,
    required this.originName,
    required this.responderId,
    required this.responderName,
    required this.sentAt,
    required this.respondedAt,
    required this.receivedAt,
    required this.roundTripMs,
  });

  final String probeId;
  final int sequence;
  final String originId;
  final String originName;
  final String responderId;
  final String responderName;
  final DateTime sentAt;
  final DateTime respondedAt;
  final DateTime receivedAt;
  final double roundTripMs;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'probeId': probeId,
      'sequence': sequence,
      'originId': originId,
      'originName': originName,
      'responderId': responderId,
      'responderName': responderName,
      'sentAt': sentAt.toUtc().toIso8601String(),
      'respondedAt': respondedAt.toUtc().toIso8601String(),
      'receivedAt': receivedAt.toUtc().toIso8601String(),
      'roundTripMs': roundTripMs,
    };
  }
}

class LatencyProbeService {
  LatencyProbeService({required PeerIdentity identity, Logger? logger})
    : _identity = identity,
      _logger = logger ?? const Logger('LatencyProbeService');

  final Logger _logger;
  PeerIdentity _identity;

  final Map<String, _PendingProbe> _pending = <String, _PendingProbe>{};
  final List<LatencyProbeSample> _samples = <LatencyProbeSample>[];
  final StreamController<List<LatencyProbeSample>> _samplesStreamController =
      StreamController<List<LatencyProbeSample>>.broadcast();
  final StreamController<LatencyProbeSample> _latestSampleController =
      StreamController<LatencyProbeSample>.broadcast();
  int _sequence = 0;
  final Random _random = Random.secure();

  List<LatencyProbeSample> get samples =>
      List<LatencyProbeSample>.unmodifiable(_samples);
  Stream<List<LatencyProbeSample>> get samplesStream =>
      _samplesStreamController.stream;
  Stream<LatencyProbeSample> get latestSampleStream =>
      _latestSampleController.stream;

  void updateIdentity(PeerIdentity identity) {
    _identity = identity;
  }

  bool isLatencyPacket(String message) {
    return message.startsWith(latencyProbeMessagePrefix);
  }

  Future<void> sendProbe({
    required bool isSessionActive,
    required Future<void> Function(String) sendMessage,
  }) async {
    if (!isSessionActive) {
      throw StateError('Latency probe requires an active P2P session.');
    }

    final probeId = _generateProbeId();
    final sentAt = DateTime.now().toUtc();
    final sequence = ++_sequence;

    _pending[probeId] = _PendingProbe(
      id: probeId,
      sequence: sequence,
      sentAt: sentAt,
    );

    final payload = <String, dynamic>{
      'type': 'ping',
      'id': probeId,
      'sequence': sequence,
      'originId': _identity.id,
      'originName': _identity.displayName,
      'sentAt': sentAt.toIso8601String(),
    };

    final message = '$latencyProbeMessagePrefix${jsonEncode(payload)}';
    _logger.info('Broadcasting latency ping $probeId (#$sequence)');
    await sendMessage(message);
  }

  Future<bool> tryHandleIncomingPacket({
    required String message,
    required Future<void> Function(String) sendReply,
  }) async {
    if (!isLatencyPacket(message)) {
      return false;
    }

    final raw = message.substring(latencyProbeMessagePrefix.length);
    Map<String, dynamic>? decoded;
    try {
      final dynamic parsed = jsonDecode(raw);
      if (parsed is Map<String, dynamic>) {
        decoded = parsed;
      }
    } catch (e) {
      _logger.info('Unable to decode latency packet: $e');
      return true;
    }

    if (decoded == null) {
      return true;
    }

    final type = decoded['type'];
    if (type == 'ping') {
      await _handlePing(decoded, sendReply);
      return true;
    }

    if (type == 'pong') {
      _handlePong(decoded);
      return true;
    }

    return true;
  }

  String exportCsv({bool includeHeader = true}) {
    final buffer = StringBuffer();
    if (includeHeader) {
      buffer.writeln(
        'probeId,sequence,originId,originName,responderId,responderName,sentAt,respondedAt,receivedAt,roundTripMs',
      );
    }

    for (final sample in _samples) {
      buffer.writeln(
        '${sample.probeId},'
        '${sample.sequence},'
        '${_escape(sample.originId)},'
        '${_escape(sample.originName)},'
        '${_escape(sample.responderId)},'
        '${_escape(sample.responderName)},'
        '${sample.sentAt.toUtc().toIso8601String()},'
        '${sample.respondedAt.toUtc().toIso8601String()},'
        '${sample.receivedAt.toUtc().toIso8601String()},'
        '${sample.roundTripMs.toStringAsFixed(3)}',
      );
    }

    return buffer.toString();
  }

  void clear() {
    _pending.clear();
    _samples.clear();
    _samplesStreamController.add(samples);
  }

  Future<void> dispose() async {
    await _samplesStreamController.close();
    await _latestSampleController.close();
  }

  Future<void> _handlePing(
    Map<String, dynamic> payload,
    Future<void> Function(String) sendReply,
  ) async {
    final originId = payload['originId'] as String?;
    final probeId = payload['id'] as String?;
    if (originId == null || probeId == null) {
      return;
    }

    // Ignore our own ping echoes.
    if (originId == _identity.id) {
      return;
    }

    final sentAtIso = payload['sentAt'] as String?;
    DateTime? sentAt;
    if (sentAtIso != null) {
      sentAt = DateTime.tryParse(sentAtIso)?.toUtc();
    }

    final respondedAt = DateTime.now().toUtc();
    final replyPayload = <String, dynamic>{
      'type': 'pong',
      'id': probeId,
      'sequence': payload['sequence'],
      'originId': originId,
      'originName': payload['originName'],
      'responderId': _identity.id,
      'responderName': _identity.displayName,
      'sentAt': sentAt?.toIso8601String(),
      'respondedAt': respondedAt.toIso8601String(),
    };

    final reply = '$latencyProbeMessagePrefix${jsonEncode(replyPayload)}';
    _logger.info('Echoing latency probe $probeId to $originId');
    try {
      await sendReply(reply);
    } catch (e) {
      _logger.info('Failed to send latency pong for $probeId: $e');
    }
  }

  void _handlePong(Map<String, dynamic> payload) {
    final originId = payload['originId'] as String?;
    final probeId = payload['id'] as String?;
    if (originId == null || probeId == null) {
      return;
    }

    if (originId != _identity.id) {
      // Another peer's response; ignore.
      return;
    }

    final pending = _pending.remove(probeId);
    if (pending == null) {
      _logger.info('Received pong for unknown probe $probeId');
      return;
    }

    final sentAt = pending.sentAt;
    final respondedAtIso = payload['respondedAt'] as String?;
    final respondedAt = respondedAtIso != null
        ? DateTime.tryParse(respondedAtIso)?.toUtc()
        : null;
    final receivedAt = DateTime.now().toUtc();
    final effectiveRespondedAt = respondedAt ?? receivedAt;
    final roundTripMs = receivedAt.difference(sentAt).inMicroseconds / 1000.0;

    final sample = LatencyProbeSample(
      probeId: probeId,
      sequence: pending.sequence,
      originId: originId,
      originName: _identity.displayName,
      responderId: (payload['responderId'] as String?) ?? 'unknown',
      responderName: (payload['responderName'] as String?) ?? 'Peer',
      sentAt: sentAt,
      respondedAt: effectiveRespondedAt,
      receivedAt: receivedAt,
      roundTripMs: roundTripMs,
    );

    _samples.add(sample);
    _samplesStreamController.add(samples);
    _latestSampleController.add(sample);
    _logger.info(
      'Latency probe ${sample.probeId} completed in '
      '${sample.roundTripMs.toStringAsFixed(2)} ms',
    );
  }

  String _generateProbeId() {
    const String alphabet = 'abcdefghijklmnopqrstuvwxyz0123456789';
    final buffer = StringBuffer();
    for (var i = 0; i < 10; i++) {
      buffer.write(alphabet[_random.nextInt(alphabet.length)]);
    }
    return buffer.toString();
  }

  String _escape(String value) {
    if (value.contains(',')) {
      return '"${value.replaceAll('"', '""')}"';
    }
    return value;
  }
}

class _PendingProbe {
  const _PendingProbe({
    required this.id,
    required this.sequence,
    required this.sentAt,
  });

  final String id;
  final int sequence;
  final DateTime sentAt;
}
