import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:offchat/src/app/di/app_dependencies.dart';
import 'package:offchat/src/features/chat/presentation/pages/chat_page.dart';

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await AppDependencies.instance.init();
  });

  testWidgets('shows empty state initially', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: ChatPage(),
      ),
    );

    expect(find.text('Conversations'), findsOneWidget);
    expect(
      find.text('Start a conversation by sending a message.'),
      findsOneWidget,
    );
  });

  testWidgets('sends a message', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: ChatPage(),
      ),
    );

    await tester.enterText(
      find.byType(TextField),
      'Hello, World!',
    );
    await tester.tap(find.byIcon(Icons.send));
    await tester.pumpAndSettle();

    expect(find.text('Hello, World!'), findsOneWidget);
  });

  testWidgets('shows multiple messages', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: ChatPage(),
      ),
    );

    // Send first message
    await tester.enterText(find.byType(TextField), 'First message');
    await tester.tap(find.byIcon(Icons.send));
    await tester.pumpAndSettle();

    // Send second message
    await tester.enterText(find.byType(TextField), 'Second message');
    await tester.tap(find.byIcon(Icons.send));
    await tester.pumpAndSettle();

    expect(find.text('First message'), findsOneWidget);
    expect(find.text('Second message'), findsOneWidget);
  });
}
