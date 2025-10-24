import 'package:flutter/material.dart';

import '../core/constants/app_constants.dart';
import 'routes/app_router.dart';
import '../features/chat/presentation/pages/chat_page.dart';

class OffChatApp extends StatelessWidget {
  const OffChatApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
      ),
      initialRoute: ChatPage.routeName,
      onGenerateRoute: AppRouter.onGenerateRoute,
    );
  }
}
