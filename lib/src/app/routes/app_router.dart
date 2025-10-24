import 'package:flutter/material.dart';

import '../../features/chat/presentation/pages/chat_page.dart';

class AppRouter {
  const AppRouter._();

  static Route<dynamic>? onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case ChatPage.routeName:
        return MaterialPageRoute<void>(
          builder: (_) => const ChatPage(),
          settings: settings,
        );
      default:
        return MaterialPageRoute<void>(
          builder: (_) => const ChatPage(),
          settings: settings,
        );
    }
  }
}
