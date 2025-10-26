import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../app/di/app_dependencies.dart';
import '../../../../core/services/onboarding_service.dart';
import '../../../../core/utils/logger.dart';
import '../../../home/presentation/pages/home_page.dart';

/// Onboarding screen that explains permissions and sets up P2P on first launch.
class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  static const routeName = '/onboarding';

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final PageController _pageController = PageController();
  final Logger _logger = const Logger('OnboardingPage');
  int _currentPage = 0;
  bool _isSettingUp = false;
  bool _setupComplete = false;
  String _setupStatus = '';

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    Future.microtask(_checkExistingSetup);
  }

  Future<void> _setupP2p() async {
    setState(() {
      _isSettingUp = true;
      _setupStatus = 'Setting up permissions...';
    });

    try {
      final p2pService = AppDependencies.instance.p2pService;

      // Request permissions
      setState(() => _setupStatus = 'Requesting permissions...');
      try {
        await p2pService.checkAndRequestPermissions().timeout(
          const Duration(seconds: 30),
        );
      } on TimeoutException {
        _logger.info('Permission request timed out, continuing setup');
      }
      await Future.delayed(const Duration(milliseconds: 500));

      // Enable services
      setState(() => _setupStatus = 'Enabling services...');
      await p2pService.checkAndEnableServices();
      await Future.delayed(const Duration(milliseconds: 500));

      // Check if everything is ready
      final permissionsGranted = await p2pService.areAllPermissionsGranted();
      final servicesEnabled = await p2pService.areAllServicesEnabled();

      if (permissionsGranted && servicesEnabled) {
        setState(() {
          _setupStatus = 'Setup complete!';
          _setupComplete = true;
        });
        _logger.info('P2P setup completed successfully');
        await _completeOnboarding();
        return;
      } else {
        setState(() {
          _setupStatus =
              'Setup incomplete. You can configure this later in Settings.';
          _setupComplete = true;
        });
        _logger.info('P2P setup incomplete');
      }
    } catch (e) {
      _logger.error('Error during P2P setup: $e');
      setState(() {
        _setupStatus =
            'Setup encountered an error. You can try again in Settings.';
        _setupComplete = true;
      });
    } finally {
      if (mounted) {
        setState(() => _isSettingUp = false);
      }
    }
  }

  Future<void> _checkExistingSetup() async {
    final p2pService = AppDependencies.instance.p2pService;
  final permissionsGranted = await p2pService
    .areAllPermissionsGranted(requestIfMissing: false);
    final servicesEnabled = await p2pService.areAllServicesEnabled();

    if (!mounted || !(permissionsGranted && servicesEnabled)) {
      return;
    }

    setState(() {
      _setupComplete = true;
      _setupStatus = 'Setup complete!';
    });

    await _completeOnboarding();
  }

  Future<void> _completeOnboarding() async {
    await OnboardingService().completeOnboarding();
    if (mounted) {
      Navigator.of(
        context,
      ).pushNamedAndRemoveUntil(HomePage.routeName, (route) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: (page) => setState(() => _currentPage = page),
                children: [
                  _buildWelcomePage(),
                  _buildPermissionsExplanationPage(),
                  _buildSetupPage(),
                ],
              ),
            ),
            _buildPageIndicator(),
            _buildNavigationButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomePage() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.chat_bubble_outline,
            size: 120,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(height: 32),
          Text(
            'Welcome to OffChat',
            style: Theme.of(
              context,
            ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            'Connect and chat with nearby devices without internet using peer-to-peer technology.',
            style: Theme.of(context).textTheme.bodyLarge,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildPermissionsExplanationPage() {
    final permissions = [
      _PermissionInfo(
        icon: Icons.location_on,
        title: 'Location & Nearby Devices',
        description:
            'Needed on Android to scan for nearby peers over Wi-Fi Direct and Bluetooth.',
      ),
      _PermissionInfo(
        icon: Icons.bluetooth,
        title: 'Bluetooth Access',
        description:
            'Required to advertise your device and maintain peer connections.',
      ),
      _PermissionInfo(
        icon: Icons.sd_storage,
        title: 'Media & Storage',
        description:
            'Allows sharing chats, media, and files with nearby devices.',
      ),
    ];

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Permissions Needed',
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            'OffChat needs these permissions to work:',
            style: Theme.of(context).textTheme.bodyLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ...permissions.map(
            (permission) => Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    permission.icon,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          permission.title,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          permission.description,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSetupPage() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (_isSettingUp)
            const CircularProgressIndicator()
          else if (_setupComplete)
            Icon(Icons.check_circle, size: 80, color: Colors.green)
          else
            Icon(
              Icons.settings_outlined,
              size: 80,
              color: Theme.of(context).colorScheme.primary,
            ),
          const SizedBox(height: 32),
          Text(
            _setupComplete ? 'Ready to Go!' : 'Setup P2P Connection',
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            _setupStatus.isEmpty
                ? 'Tap the button below to configure permissions and services. This will allow OffChat to discover and connect to nearby devices.'
                : _setupStatus,
            style: Theme.of(context).textTheme.bodyLarge,
            textAlign: TextAlign.center,
          ),
          if (!_setupComplete && !_isSettingUp) ...[
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: _setupP2p,
              icon: const Icon(Icons.play_arrow),
              label: const Text('Start Setup'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPageIndicator() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(
          3,
          (index) => Container(
            margin: const EdgeInsets.symmetric(horizontal: 4),
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _currentPage == index
                  ? Theme.of(context).colorScheme.primary
                  : Colors.grey.shade300,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavigationButtons() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          if (_currentPage > 0)
            TextButton(
              onPressed: () {
                _pageController.previousPage(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                );
              },
              child: const Text('Back'),
            )
          else
            const SizedBox(width: 80),
          if (_currentPage < 2)
            ElevatedButton(
              onPressed: () {
                _pageController.nextPage(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                );
              },
              child: const Text('Next'),
            )
          else
            ElevatedButton(
              onPressed: _setupComplete && !_isSettingUp
                  ? _completeOnboarding
                  : null,
              child: const Text('Get Started'),
            ),
        ],
      ),
    );
  }
}

class _PermissionInfo {
  final IconData icon;
  final String title;
  final String description;

  _PermissionInfo({
    required this.icon,
    required this.title,
    required this.description,
  });
}
