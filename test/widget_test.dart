import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:glm_chat/main.dart';

void main() {
  testWidgets('App starts with ChatScreen', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: GLMChatApp()));
    expect(find.text('GLM Chat'), findsOneWidget);
  });
}
