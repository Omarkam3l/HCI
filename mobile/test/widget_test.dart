import 'package:flutter_test/flutter_test.dart';
import 'package:ai_demo_mobile/main.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const AiDemoApp());
    expect(find.byType(AiDemoApp), findsOneWidget);
  });
}
