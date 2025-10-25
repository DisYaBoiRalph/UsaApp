import 'package:flutter/material.dart';

class ContactsPage extends StatelessWidget {
  const ContactsPage({super.key});

  static const routeName = '/contacts';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Contacts')),
      body: const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'Contacts and peer discovery will appear here once peer-to-peer '
            'features are enabled.',
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
