import 'package:flutter/material.dart';

import '../core/constants/app_constants.dart';
import '../core/services/onboarding_service.dart';
import 'routes/app_router.dart';

class OffChatApp extends StatefulWidget {
  const OffChatApp({super.key});

  @override
  State<OffChatApp> createState() => _OffChatAppState();
}

class _OffChatAppState extends State<OffChatApp> {
  final OnboardingService _onboardingService = OnboardingService();
  String? _initialRoute;

  @override
  void initState() {
    super.initState();
    _determineInitialRoute();
  }

  Future<void> _determineInitialRoute() async {
    final route = await _onboardingService.getInitialRoute();
    setState(() {
      _initialRoute = route;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Show loading screen while determining initial route
    if (_initialRoute == null) {
      return MaterialApp(
        title: AppConstants.appName,
        debugShowCheckedModeBanner: false,
        home: const Scaffold(
          body: Center(
            child: CircularProgressIndicator(),
          ),
        ),
      );
    }

    return MaterialApp(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
      ),
      initialRoute: _initialRoute,
      onGenerateRoute: AppRouter.onGenerateRoute,
    );
  }
}
