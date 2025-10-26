import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../app/di/app_dependencies.dart';
import '../../data/datasources/conversation_store.dart';
import '../../domain/entities/conversation.dart';
import '../controllers/chat_controller.dart';

class ConversationHistoryPage extends StatefulWidget {
  const ConversationHistoryPage({super.key, required this.conversation});

  final Conversation conversation;

  @override
  State<ConversationHistoryPage> createState() =>
      _ConversationHistoryPageState();
}

class _ConversationHistoryPageState extends State<ConversationHistoryPage> {
  late final ChatController _chatController;
  late final ConversationStore _conversationStore;
  late final StreamSubscription<List<Conversation>> _conversationSubscription;
  final ScrollController _scrollController = ScrollController();

  Conversation? _currentConversation;

  @override
  void initState() {
    super.initState();
    _conversationStore = AppDependencies.instance.conversationStore;
    _currentConversation = widget.conversation;
    _chatController = AppDependencies.instance.createChatController(
      conversation: widget.conversation,
    );
    unawaited(_chatController.start());

    _conversationSubscription = _conversationStore.watchAll().listen((items) {
      final match = items
          .where((item) => item.id == widget.conversation.id)
          .toList();
      if (match.isEmpty) {
        if (mounted) {
          Navigator.of(context).maybePop();
        }
        return;
      }
      final updated = match.first;
      if (_currentConversation?.title != updated.title) {
        setState(() => _currentConversation = updated);
      }
      _chatController.conversation = updated;
    });

    _chatController.addListener(_handleMessagesChanged);
  }

  @override
  void dispose() {
    _chatController.removeListener(_handleMessagesChanged);
    _conversationSubscription.cancel();
    _chatController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final conversationTitle = _currentConversation?.title ?? 'Conversation';

    return Scaffold(
      appBar: AppBar(title: Text(conversationTitle)),
      body: AnimatedBuilder(
        animation: _chatController,
        builder: (context, _) {
          final messages = _chatController.messages;
          if (messages.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 32),
                child: Text(
                  'No messages have been recorded for this chat yet.',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          return ListView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            itemCount: messages.length,
            itemBuilder: (context, index) {
              final message = messages[index];
              final alignment = message.isLocal
                  ? Alignment.centerRight
                  : Alignment.centerLeft;
              final theme = Theme.of(context);
              final scheme = theme.colorScheme;
              final backgroundColor = message.isLocal
                  ? scheme.primaryContainer
                  : scheme.surfaceContainerHighest;
              final textColor = message.isLocal
                  ? scheme.onPrimaryContainer
                  : scheme.onSurfaceVariant;

              return Align(
                alignment: alignment,
                child: Container(
                  margin: const EdgeInsets.symmetric(vertical: 6),
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
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: _scaledAlpha(textColor, 0.8),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        message.content,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: textColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Align(
                        alignment: Alignment.centerRight,
                        child: Text(
                          message.sentAtFormatted,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: _scaledAlpha(textColor, 0.7),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _handleMessagesChanged() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) {
        return;
      }
      _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
    });
  }

  Color _scaledAlpha(Color color, double factor) {
    final scaled = (color.a * factor).clamp(0.0, 1.0);
    return color.withAlpha((scaled * 255).round());
  }
}
