import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:offchat/src/app/di/app_dependencies.dart';
import 'package:offchat/src/features/home/presentation/pages/home_page.dart';

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await AppDependencies.instance.init();
  });

  testWidgets('displays navigation cards', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: HomePage(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Contacts'), findsOneWidget);
    expect(find.text('Conversations'), findsOneWidget);
    expect(find.text('Settings'), findsOneWidget);
  });

  testWidgets('shows welcome message', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: HomePage(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Welcome to OffChat'), findsOneWidget);
  });
}
