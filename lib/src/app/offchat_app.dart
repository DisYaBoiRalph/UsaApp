import 'package:flutter/material.dart';

import '../core/constants/app_constants.dart';
import 'routes/app_router.dart';

class OffChatApp extends StatelessWidget {
  const OffChatApp({super.key, required this.initialRoute});

  final String initialRoute;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
      ),
      routes: AppRouter.routes,
      initialRoute: initialRoute,
      onGenerateRoute: AppRouter.onGenerateRoute,
    );
  }
}
