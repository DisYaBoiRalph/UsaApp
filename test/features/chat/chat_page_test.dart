import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:usaapp/src/app/di/app_dependencies.dart';
import 'package:usaapp/src/features/chat/domain/entities/conversation.dart';
import 'package:usaapp/src/features/chat/presentation/pages/chat_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late Conversation conversation;

  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues(const <String, Object>{});
    await AppDependencies.instance.init();
  });

  setUp(() async {
    final store = AppDependencies.instance.conversationStore;
    conversation = await store.createConversation('Test Conversation');
  });

  tearDown(() async {
    final store = AppDependencies.instance.conversationStore;
    await store.deleteConversation(conversation.id);
  });

  testWidgets('shows empty state initially', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(home: ChatPage(conversation: conversation)),
    );

    expect(find.text('Test Conversation'), findsOneWidget);
    expect(
      find.text('Start a conversation by sending a message.'),
      findsOneWidget,
    );
  });

  testWidgets('sends a message', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(home: ChatPage(conversation: conversation)),
    );

    await tester.enterText(find.byType(TextField), 'Hello, World!');
    await tester.tap(find.byIcon(Icons.send));
    await tester.pumpAndSettle();

    expect(find.text('Hello, World!'), findsOneWidget);
  });

  testWidgets('shows multiple messages', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(home: ChatPage(conversation: conversation)),
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
