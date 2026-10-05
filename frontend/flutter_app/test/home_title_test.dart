import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tailorsync/ui/components/ts_page.dart';

void main() {
  testWidgets('TsScrollPage shows a custom titleWidget (home wordmark) in the top-left app bar',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(MaterialApp(
      home: TsScrollPage(
        title: 'TailorSync',
        titleWidget: const Text('TailorSync', key: Key('wordmark')),
        automaticallyImplyLeading: false,
        actions: const [SizedBox(width: 46, height: 46, key: Key('avatar'))],
        slivers: const [SliverToBoxAdapter(child: SizedBox(height: 2000))],
      ),
    ));
    await tester.pump(const Duration(milliseconds: 100));

    final word = find.byKey(const Key('wordmark'));
    expect(word, findsOneWidget);
    final r = tester.getRect(word);
    final avatar = tester.getRect(find.byKey(const Key('avatar')));
    // Inside the app bar row, on the left, and not squeezed to nothing.
    expect(r.top, lessThan(80));
    expect(r.left, lessThan(60));
    expect(r.width, greaterThan(40));
    expect(r.right, lessThanOrEqualTo(avatar.left));
  });
}
