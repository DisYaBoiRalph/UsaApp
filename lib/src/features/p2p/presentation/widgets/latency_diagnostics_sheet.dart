import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../app/di/app_dependencies.dart';
import '../../data/services/latency_probe_service.dart';
import '../controllers/p2p_session_controller.dart';

class LatencyDiagnosticsSheet extends StatefulWidget {
  const LatencyDiagnosticsSheet({super.key, required this.controller});

  final P2pSessionController controller;

  @override
  State<LatencyDiagnosticsSheet> createState() =>
      _LatencyDiagnosticsSheetState();
}

class _LatencyDiagnosticsSheetState extends State<LatencyDiagnosticsSheet> {
  late final LatencyProbeService _service;
  late List<LatencyProbeSample> _samples;
  StreamSubscription<List<LatencyProbeSample>>? _subscription;
  bool _isRunning = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _service = AppDependencies.instance.latencyProbeService;
    _samples = _service.samples;
    _subscription = _service.samplesStream.listen((samples) {
      setState(() {
        _samples = samples;
      });
    });
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final media = MediaQuery.of(context);
          final maxHeight = constraints.maxHeight.isFinite
              ? constraints.maxHeight
              : media.size.height;
          var sheetHeight = maxHeight * 0.85;
          if (sheetHeight < 320) {
            sheetHeight = 320;
          }
          if (sheetHeight > maxHeight) {
            sheetHeight = maxHeight;
          }

          return AnimatedPadding(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
            padding: EdgeInsets.fromLTRB(
              24,
              16,
              24,
              media.viewInsets.bottom + 24,
            ),
            child: Align(
              alignment: Alignment.bottomCenter,
              child: SizedBox(
                height: sheetHeight,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            'Latency diagnostics',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_sweep_outlined),
                          tooltip: 'Clear results',
                          onPressed: _samples.isEmpty
                              ? null
                              : () {
                                  _service.clear();
                                  setState(() {
                                    _error = null;
                                    _samples = _service.samples;
                                  });
                                },
                        ),
                        IconButton(
                          icon: const Icon(Icons.copy_all_outlined),
                          tooltip: 'Copy CSV',
                          onPressed: _samples.isEmpty ? null : _copyCsv,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Measure round-trip latency by sending a probe to connected peers. '
                      'Results are saved locally and can be exported as CSV for analysis.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 16),
                    if (_error != null) ...[
                      Text(
                        _error!,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                    Row(
                      children: [
                        FilledButton.icon(
                          icon: _isRunning
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.speed_outlined),
                          label: Text(_isRunning ? 'Sending…' : 'Send probe'),
                          onPressed: _isRunning ? null : _startProbe,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            widget.controller.hasActiveSession
                                ? 'Active session detected.'
                                : 'No active P2P session.',
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(
                                  color: widget.controller.hasActiveSession
                                      ? Theme.of(context).colorScheme.primary
                                      : Theme.of(context).colorScheme.error,
                                ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Expanded(
                      child: _samples.isEmpty
                          ? const _EmptyState()
                          : _ResultsList(samples: _samples),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _startProbe() async {
    if (!widget.controller.hasActiveSession) {
      setState(() {
        _error = 'Start hosting or join a session before running a probe.';
      });
      return;
    }

    setState(() {
      _isRunning = true;
      _error = null;
    });

    try {
      await _service.sendProbe(
        isSessionActive: widget.controller.hasActiveSession,
        sendMessage: widget.controller.sendGroupText,
      );
    } catch (e) {
      setState(() {
        _error = '$e';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isRunning = false;
        });
      }
    }
  }

  Future<void> _copyCsv() async {
    final csv = _service.exportCsv();
    await Clipboard.setData(ClipboardData(text: csv));
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Copied results to clipboard.')),
    );
  }
}

class _ResultsList extends StatelessWidget {
  const _ResultsList({required this.samples});

  final List<LatencyProbeSample> samples;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      shrinkWrap: true,
      itemCount: samples.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final sample = samples[samples.length - index - 1];
        return ListTile(
          leading: CircleAvatar(child: Text(sample.sequence.toString())),
          title: Text(
            '${sample.roundTripMs.toStringAsFixed(2)} ms '
            '(${sample.responderName})',
          ),
          subtitle: Text(
            'Sent ${_relativeTime(sample.sentAt)} · '
            'Responded ${_relativeTime(sample.receivedAt)}',
          ),
        );
      },
    );
  }

  String _relativeTime(DateTime timestamp) {
    final difference = DateTime.now().difference(timestamp);
    if (difference.inSeconds < 60) {
      return '${difference.inSeconds}s ago';
    }
    if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    }
    if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    }
    return '${difference.inDays}d ago';
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        'No latency samples yet. Run a probe to capture metrics.',
        style: Theme.of(context).textTheme.bodyMedium,
        textAlign: TextAlign.center,
      ),
    );
  }
}
