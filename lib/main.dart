import 'package:flutter/material.dart';

import 'src/app/di/app_dependencies.dart';
import 'src/app/offchat_app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppDependencies.instance.init();

  runApp(const OffChatApp());
}
