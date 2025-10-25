import 'package:flutter/material.dart';

import '../../features/chat/presentation/pages/chat_page.dart';
import '../../features/contacts/presentation/pages/contacts_page.dart';
import '../../features/home/presentation/pages/home_page.dart';
import '../../features/onboarding/presentation/pages/onboarding_page.dart';
import '../../features/settings/presentation/pages/settings_page.dart';

class AppRouter {
  const AppRouter._();

  static Route<dynamic>? onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case OnboardingPage.routeName:
        return MaterialPageRoute<void>(
          builder: (_) => const OnboardingPage(),
          settings: settings,
        );
      case HomePage.routeName:
        return MaterialPageRoute<void>(
          builder: (_) => const HomePage(),
          settings: settings,
        );
      case ChatPage.routeName:
        return MaterialPageRoute<void>(
          builder: (_) => const ChatPage(),
          settings: settings,
        );
      case ContactsPage.routeName:
        return MaterialPageRoute<void>(
          builder: (_) => const ContactsPage(),
          settings: settings,
        );
      case SettingsPage.routeName:
        return MaterialPageRoute<void>(
          builder: (_) => const SettingsPage(),
          settings: settings,
        );
      default:
        return MaterialPageRoute<void>(
          builder: (_) => const HomePage(),
          settings: settings,
        );
    }
  }
}
