import 'package:flutter_test/flutter_test.dart';
import 'package:packlite/main.dart';

void main() {
  testWidgets('PackLite app smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const PackLiteApp());
    expect(find.byType(PackLiteApp), findsOneWidget);
  });
}
