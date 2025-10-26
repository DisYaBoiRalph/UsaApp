import 'package:flutter/material.dart';

import '../../../../app/di/app_dependencies.dart';
import '../../data/datasources/conversation_store.dart';
import '../../domain/entities/conversation.dart';
import 'conversation_history_page.dart';

class ChatsLibraryPage extends StatefulWidget {
  const ChatsLibraryPage({super.key});

  static const String routeName = '/chats';

  @override
  State<ChatsLibraryPage> createState() => _ChatsLibraryPageState();
}

class _ChatsLibraryPageState extends State<ChatsLibraryPage> {
  late final ConversationStore _store;
  late final Stream<List<Conversation>> _conversationsStream;
  bool _isCreating = false;
  bool _isRenaming = false;

  @override
  void initState() {
    super.initState();
    _store = AppDependencies.instance.conversationStore;
    _conversationsStream = _store.watchAll();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Saved Chats')),
      body: StreamBuilder<List<Conversation>>(
        stream: _conversationsStream,
        initialData: _store.current,
        builder: (context, snapshot) {
          final conversations = snapshot.data ?? const <Conversation>[];
          if (conversations.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 32),
                child: Text(
                  'You have not saved any chats yet. Start a conversation, and it will appear here for easy access.',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: conversations.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final conversation = conversations[index];
              return Card(
                child: ListTile(
                  leading: const Icon(Icons.chat_bubble_outline),
                  title: Text(conversation.title),
                  subtitle: Text(_relativeTime(conversation.updatedAt)),
                  onTap: () => _openConversation(conversation),
                  trailing: PopupMenuButton<_ConversationMenuAction>(
                    onSelected: (action) =>
                        _handleConversationAction(action, conversation),
                    itemBuilder: (context) => const [
                      PopupMenuItem<_ConversationMenuAction>(
                        value: _ConversationMenuAction.rename,
                        child: Text('Rename'),
                      ),
                      PopupMenuItem<_ConversationMenuAction>(
                        value: _ConversationMenuAction.delete,
                        child: Text('Delete'),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        icon: _isCreating
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.add_comment_outlined),
        label: Text(_isCreating ? 'Creating…' : 'New chat'),
        onPressed: _isCreating ? null : _handleCreateConversation,
      ),
    );
  }

  Future<void> _handleCreateConversation() async {
    final name = await _promptForName(title: 'Create new chat');
    final trimmed = name?.trim() ?? '';
    if (trimmed.isEmpty) {
      return;
    }

    setState(() => _isCreating = true);
    try {
      await _store.createConversation(trimmed);
    } finally {
      if (mounted) {
        setState(() => _isCreating = false);
      }
    }
  }

  Future<void> _handleConversationAction(
    _ConversationMenuAction action,
    Conversation conversation,
  ) async {
    switch (action) {
      case _ConversationMenuAction.rename:
        await _renameConversation(conversation);
        break;
      case _ConversationMenuAction.delete:
        await _deleteConversation(conversation);
        break;
    }
  }

  Future<void> _renameConversation(Conversation conversation) async {
    if (_isRenaming) {
      return;
    }
    final newName = await _promptForName(
      title: 'Rename chat',
      initialValue: conversation.title,
    );
    final trimmed = newName?.trim() ?? '';
    if (trimmed.isEmpty || trimmed == conversation.title) {
      return;
    }

    setState(() => _isRenaming = true);
    try {
      await _store.renameConversation(id: conversation.id, newTitle: trimmed);
    } finally {
      if (mounted) {
        setState(() => _isRenaming = false);
      }
    }
  }

  Future<void> _deleteConversation(Conversation conversation) async {
    final confirmed =
        await showDialog<bool>(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: const Text('Delete chat?'),
              content: Text(
                'This will remove "${conversation.title}" and its messages from this device.',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: const Text('Delete'),
                ),
              ],
            );
          },
        ) ??
        false;

    if (!confirmed) {
      return;
    }

    await _store.deleteConversation(conversation.id);
  }

  Future<String?> _promptForName({
    required String title,
    String? initialValue,
  }) async {
    final controller = TextEditingController(text: initialValue ?? '');
    String currentText = controller.text.trim();
    final result = await showDialog<String>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(title),
              content: TextField(
                controller: controller,
                autofocus: true,
                textInputAction: TextInputAction.done,
                onChanged: (value) {
                  setState(() => currentText = value.trim());
                },
                onSubmitted: (_) {
                  final trimmed = controller.text.trim();
                  if (trimmed.isEmpty) {
                    return;
                  }
                  Navigator.of(context).pop(trimmed);
                },
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: currentText.isEmpty
                      ? null
                      : () => Navigator.of(context).pop(currentText),
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
    controller.dispose();
    return result;
  }

  void _openConversation(Conversation conversation) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ConversationHistoryPage(conversation: conversation),
      ),
    );
  }

  String _relativeTime(DateTime timestamp) {
    final difference = DateTime.now().difference(timestamp);
    if (difference.inMinutes < 1) {
      return 'Updated just now';
    }
    if (difference.inHours < 1) {
      return 'Updated ${difference.inMinutes} min ago';
    }
    if (difference.inDays < 1) {
      return 'Updated ${difference.inHours} h ago';
    }
    return 'Updated ${difference.inDays} day${difference.inDays > 1 ? 's' : ''} ago';
  }
}

enum _ConversationMenuAction { rename, delete }
