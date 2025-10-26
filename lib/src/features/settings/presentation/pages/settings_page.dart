import 'package:flutter/material.dart';

import '../controllers/settings_controller.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  static const routeName = '/settings';

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  late final SettingsController _controller;
  late final TextEditingController _displayNameController;
  late final FocusNode _displayNameFocusNode;

  @override
  void initState() {
    super.initState();
    _controller = SettingsController();
    _displayNameController = TextEditingController();
    _displayNameFocusNode = FocusNode();
    _controller.addListener(_syncDisplayNameField);
    _controller.refreshStatus();
  }

  @override
  void dispose() {
    _controller.removeListener(_syncDisplayNameField);
    _controller.dispose();
    _displayNameController.dispose();
    _displayNameFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: <Widget>[
          Text(
            'P2P Connection Setup',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          AnimatedBuilder(
            animation: _controller,
            builder: (context, _) {
              return Column(
                children: [
                  // Permissions Card
                  Card(
                    child: ListTile(
                      leading: Icon(
                        _controller.allPermissionsGranted
                            ? Icons.check_circle
                            : Icons.warning_amber,
                        color: _controller.allPermissionsGranted
                            ? Colors.green
                            : Colors.orange,
                      ),
                      title: const Text('Permissions'),
                      subtitle: Text(
                        _controller.allPermissionsGranted
                            ? 'All permissions granted'
                            : 'Permissions needed for P2P functionality',
                      ),
                      trailing: _controller.isCheckingPermissions
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : ElevatedButton(
                              onPressed: _controller.setupPermissions,
                              child: const Text('Setup'),
                            ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Services Card
                  Card(
                    child: ListTile(
                      leading: Icon(
                        _controller.allServicesEnabled
                            ? Icons.check_circle
                            : Icons.warning_amber,
                        color: _controller.allServicesEnabled
                            ? Colors.green
                            : Colors.orange,
                      ),
                      title: const Text('Services'),
                      subtitle: Text(
                        _controller.allServicesEnabled
                            ? 'All services enabled'
                            : 'Wi-Fi, Location, and Bluetooth required',
                      ),
                      trailing: _controller.isCheckingServices
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : ElevatedButton(
                              onPressed: _controller.setupServices,
                              child: const Text('Setup'),
                            ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Overall Status
                  if (_controller.isP2pReady)
                    Card(
                      color: Colors.green.shade50,
                      child: const Padding(
                        padding: EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Icon(Icons.check_circle, color: Colors.green),
                            SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'P2P is ready! You can now discover and connect to nearby devices.',
                                style: TextStyle(color: Colors.green),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
          const SizedBox(height: 24),
          const Divider(),
          const SizedBox(height: 16),
          Text('Other Settings', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          AnimatedBuilder(
            animation: _controller,
            builder: (context, _) {
              final isSaving = _controller.isSavingDisplayName;
              final helperText = _controller.displayName.trim().isEmpty
                  ? 'Set a name so peers can recognize you.'
                  : 'This is how your name appears to peers. Leave blank to reset.';
              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Your Identity',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _displayNameController,
                        focusNode: _displayNameFocusNode,
                        textCapitalization: TextCapitalization.words,
                        decoration: InputDecoration(
                          labelText: 'Display name',
                          helperText: helperText,
                        ),
                        onSubmitted: (_) => _handleSaveDisplayName(),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          FilledButton.icon(
                            onPressed: isSaving
                                ? null
                                : () => _handleSaveDisplayName(),
                            icon: isSaving
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Icon(Icons.save_outlined),
                            label: Text(isSaving ? 'Saving…' : 'Save name'),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: SelectableText(
                              'Device ID: ${_controller.deviceCode}',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 8),
          const ListTile(
            leading: Icon(Icons.security_outlined),
            title: Text('Privacy'),
            subtitle: Text('Configure how peers discover you.'),
          ),
          // const ListTile(
          //   leading: Icon(Icons.palette_outlined),
          //   title: Text('Appearance'),
          //   subtitle: Text('Adjust theme and accessibility.'),
          // ),
        ],
      ),
    );
  }

  void _syncDisplayNameField() {
    if (!mounted) {
      return;
    }
    final value = _controller.displayName;
    if (_displayNameFocusNode.hasFocus) {
      return;
    }
    if (_displayNameController.text != value) {
      _displayNameController.text = value;
    }
  }

  Future<void> _handleSaveDisplayName() async {
    final trimmed = _displayNameController.text.trim();
    await _controller.updateDisplayName(trimmed);
    if (!mounted) {
      return;
    }
    final message = trimmed.isEmpty
        ? 'Display name reset to default.'
        : 'Display name updated.';
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}
