import 'package:flutter_test/flutter_test.dart';
import 'package:tailorsync/app_widget.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const AppWidget());
    await tester.pump(const Duration(seconds: 3));
    expect(find.byType(AppWidget), findsOneWidget);
  });
}
