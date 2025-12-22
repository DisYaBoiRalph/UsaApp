import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../app/di/app_dependencies.dart';
import '../../../../core/widgets/profile_avatar.dart';
import '../../../p2p/data/services/p2p_service.dart';
import '../../../p2p/presentation/controllers/p2p_session_controller.dart';
import '../../../p2p/presentation/widgets/latency_diagnostics_sheet.dart';
import '../../domain/entities/chat_message_payload.dart';
import '../../domain/entities/conversation.dart';
import '../controllers/chat_controller.dart';

class ChatPage extends StatefulWidget {
  const ChatPage({
    super.key,
    required this.conversation,
    this.controller,
    this.p2pController,
  });

  static const routeName = '/chat/session';

  final Conversation conversation;
  final ChatController? controller;
  final P2pSessionController? p2pController;

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  late final ChatController _controller;
  late final bool _ownsController;
  late final P2pSessionController _p2pController;
  late final bool _ownsP2pController;
  StreamSubscription<ChatMessagePayload>? _incomingSubscription;
  final ScrollController _messageScrollController = ScrollController();
  final FocusNode _composerFocusNode = FocusNode();
  int _lastMessageCount = 0;

  @override
  void initState() {
    super.initState();
    _controller =
        widget.controller ??
        AppDependencies.instance.createChatController(
          conversation: widget.conversation,
        );
    _ownsController = widget.controller == null;
    _p2pController =
        widget.p2pController ??
        AppDependencies.instance.createP2pSessionController();
    _ownsP2pController = widget.p2pController == null;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      _p2pController.setActiveConversation(widget.conversation);
    });
    unawaited(_controller.start());
    _lastMessageCount = _controller.messages.length;
    _controller.addListener(_handleMessagesChanged);
    _composerFocusNode.addListener(_handleComposerFocusChange);

    _incomingSubscription = _p2pController.incomingMessages.listen((
      payload,
    ) async {
      if (!mounted) {
        return;
      }
      await _controller.receivePayload(payload);
    });
  }

  @override
  void dispose() {
    _incomingSubscription?.cancel();
    _controller.removeListener(_handleMessagesChanged);
    _composerFocusNode.removeListener(_handleComposerFocusChange);
    _composerFocusNode.unfocus();
    _composerFocusNode.dispose();
    if (_ownsController) {
      _controller.dispose();
    }
    if (_ownsP2pController) {
      _p2pController.dispose();
    }
    _messageScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) => Text(_controller.conversation.title),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.speed_outlined),
            tooltip: 'Latency diagnostics',
            onPressed: _showLatencyDiagnostics,
          ),
        ],
      ),
      body: Column(
        children: <Widget>[
          _buildConnectionBanner(),
          Expanded(child: _buildMessageList()),
          SafeArea(
            top: false,
            minimum: const EdgeInsets.all(16),
            child: _buildComposer(),
          ),
        ],
      ),
    );
  }

  Widget _buildConnectionBanner() {
    return AnimatedBuilder(
      animation: _p2pController,
      builder: (context, _) {
        final role = _p2pController.role;
        if (role == null) {
          return const SizedBox.shrink();
        }

        late final IconData icon;
        late final String title;
        late final String details;

        if (role == P2pSessionRole.host) {
          icon = Icons.wifi_tethering;
          title = 'Hosting conversation';
          final state = _p2pController.hostState;
          if (state != null && state.isActive) {
            details =
                'SSID: ${state.ssid ?? 'pending'} · Password: ${state.preSharedKey ?? 'pending'}';
          } else {
            details = 'Hotspot starting…';
          }
        } else {
          icon = Icons.link;
          title = 'Joined conversation';
          final state = _p2pController.clientState;
          if (state != null && state.isActive) {
            details =
                'Connected to ${state.hostSsid ?? 'host'} · Gateway ${state.hostGatewayIpAddress ?? 'pending'}';
          } else {
            details = 'Waiting for connection…';
          }
        }

        final conversationTitle =
            _p2pController.activeConversationTitle ??
            _controller.conversation.title;
        final subtitle = '$details\nSharing: $conversationTitle';

        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Card(
            child: ListTile(
              leading: Icon(icon),
              title: Text(title),
              subtitle: Text(subtitle),
            ),
          ),
        );
      },
    );
  }

  Widget _buildMessageList() {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        if (_controller.messages.isEmpty) {
          return const Center(
            child: Text('Start a conversation by sending a message.'),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          controller: _messageScrollController,
          itemCount: _controller.messages.length,
          itemBuilder: (context, index) {
            final message = _controller.messages[index];
            final scheme = Theme.of(context).colorScheme;
            final backgroundColor = message.isLocal
                ? scheme.primaryContainer
                : scheme.surfaceContainerHighest;
            final textColor = message.isLocal
                ? scheme.onPrimaryContainer
                : scheme.onSurfaceVariant;

            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                mainAxisAlignment: message.isLocal
                    ? MainAxisAlignment.end
                    : MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (!message.isLocal) ...[
                    ProfileAvatar(identity: message.senderIdentity, size: 32),
                    const SizedBox(width: 8),
                  ],
                  Flexible(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: backgroundColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          Text(
                            message.displaySender,
                            style: Theme.of(context).textTheme.labelSmall
                                ?.copyWith(color: _scaledAlpha(textColor, 0.8)),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            message.content,
                            style: Theme.of(
                              context,
                            ).textTheme.bodyMedium?.copyWith(color: textColor),
                          ),
                          const SizedBox(height: 4),
                          Align(
                            alignment: Alignment.centerRight,
                            child: Text(
                              message.sentAtFormatted,
                              style: Theme.of(context).textTheme.labelSmall
                                  ?.copyWith(
                                    color: _scaledAlpha(textColor, 0.7),
                                  ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (message.isLocal) ...[
                    const SizedBox(width: 8),
                    ProfileAvatar(identity: message.senderIdentity, size: 32),
                  ],
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildComposer() {
    return Row(
      children: <Widget>[
        Expanded(
          child: TextField(
            controller: _controller.messageFieldController,
            focusNode: _composerFocusNode,
            decoration: const InputDecoration(hintText: 'Type a message'),
            onSubmitted: (_) => unawaited(_handleSend()),
          ),
        ),
        const SizedBox(width: 12),
        IconButton(
          icon: const Icon(Icons.send),
          onPressed: () => unawaited(_handleSend()),
        ),
      ],
    );
  }

  Future<void> _handleSend() async {
    final raw = _controller.messageFieldController.text;
    final message = await _controller.sendLocalMessage(raw);
    if (message == null) {
      return;
    }

    final payload = ChatMessagePayload.fromChatMessage(
      message,
      conversationTitle: _controller.conversation.title,
      senderIdentity: AppDependencies.instance.peerIdentity,
    );
    await _p2pController.sendChatMessage(payload);
  }

  void _handleMessagesChanged() {
    final count = _controller.messages.length;
    if (count != _lastMessageCount) {
      _lastMessageCount = count;
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
    }
  }

  void _handleComposerFocusChange() {
    if (_composerFocusNode.hasFocus) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
    }
  }

  void _scrollToBottom() {
    if (!_messageScrollController.hasClients) {
      return;
    }
    final position = _messageScrollController.position;
    position.animateTo(
      position.maxScrollExtent,
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
    );
  }

  Color _scaledAlpha(Color color, double factor) {
    final scaled = (color.a * factor).clamp(0.0, 1.0);
    return color.withAlpha((scaled * 255).round());
  }

  Future<void> _showLatencyDiagnostics() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => LatencyDiagnosticsSheet(controller: _p2pController),
    );
  }
}
