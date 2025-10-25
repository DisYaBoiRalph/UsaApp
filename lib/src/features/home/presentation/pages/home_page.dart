import 'package:flutter/material.dart';

import '../../../chat/presentation/pages/chat_page.dart';
import '../../../contacts/presentation/pages/contacts_page.dart';
import '../../../settings/presentation/pages/settings_page.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  static const routeName = '/';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('OffChat')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: <Widget>[
          Text('Welcome to OffChat', style: theme.textTheme.headlineSmall),
          const SizedBox(height: 12),
          Text(
            'Choose where you would like to start. You can explore contacts, tweak your settings, or jump right into conversations.',
            style: theme.textTheme.bodyLarge,
          ),
          const SizedBox(height: 24),
          _DestinationTile(
            icon: Icons.people_outline,
            title: 'Contacts',
            subtitle: 'Browse nearby peers and manage invitations.',
            onTap: () =>
                Navigator.of(context).pushNamed(ContactsPage.routeName),
          ),
          _DestinationTile(
            icon: Icons.message_outlined,
            title: 'Conversations',
            subtitle: 'Continue chatting with your current peers.',
            onTap: () => Navigator.of(context).pushNamed(ChatPage.routeName),
          ),
          _DestinationTile(
            icon: Icons.settings_outlined,
            title: 'Settings',
            subtitle: 'Adjust preferences before you enable peer-to-peer mode.',
            onTap: () =>
                Navigator.of(context).pushNamed(SettingsPage.routeName),
          ),
        ],
      ),
    );
  }
}

class _DestinationTile extends StatelessWidget {
  const _DestinationTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListTile(
        leading: Icon(icon),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }
}
