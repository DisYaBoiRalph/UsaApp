import 'package:flutter/material.dart';

import '../../../../app/di/app_dependencies.dart';
import '../controllers/chat_controller.dart';

class ChatPage extends StatefulWidget {
  const ChatPage({super.key, ChatController? controller})
    : _controller = controller;

  static const routeName = '/chat';

  final ChatController? _controller;

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  late final ChatController _controller;
  late final bool _ownsController;

  @override
  void initState() {
    super.initState();
    _controller =
        widget._controller ?? AppDependencies.instance.createChatController();
    _ownsController = widget._controller == null;
    _controller.start();
  }

  @override
  void dispose() {
    if (_ownsController) {
      _controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Conversations')),
      body: Column(
        children: <Widget>[
          Expanded(
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, _) {
                if (_controller.messages.isEmpty) {
                  return const Center(
                    child: Text('Start a conversation by sending a message.'),
                  );
                }

                return ListView.builder(
                  itemCount: _controller.messages.length,
                  itemBuilder: (context, index) {
                    final message = _controller.messages[index];
                    return ListTile(
                      title: Text(message.sender),
                      subtitle: Text(message.content),
                      trailing: Text(
                        message.sentAtFormatted,
                        style: Theme.of(context).textTheme.labelSmall,
                      ),
                    );
                  },
                );
              },
            ),
          ),
          SafeArea(
            top: false,
            minimum: const EdgeInsets.all(16),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: TextField(
                    controller: _controller.messageFieldController,
                    decoration: const InputDecoration(
                      hintText: 'Type a message',
                    ),
                    onSubmitted: _controller.sendMessage,
                  ),
                ),
                const SizedBox(width: 12),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: () => _controller.sendMessage(
                    _controller.messageFieldController.text,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
