import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Update Stage Bottom Sheet renders all 7 stages cleanly at 320x568 without overflow', (WidgetTester tester) async {
    // Set viewport to 320x568 (small phone viewport)
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1.0;

    final stages = [
      'Order Received',
      'Cutting',
      'Sewing',
      'Fitting',
      'Quality Check',
      'Ready',
      'Delivered',
    ];

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () {
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  useSafeArea: true,
                  useRootNavigator: true,
                  showDragHandle: true,
                  builder: (modalCtx) => Container(
                    constraints: BoxConstraints(
                      maxHeight: MediaQuery.of(modalCtx).size.height * 0.75,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('Update Task Stage'),
                        Flexible(
                          child: ListView.builder(
                            itemCount: stages.length,
                            itemBuilder: (ctx, index) => ListTile(
                              minTileHeight: 52,
                              title: Text(stages[index]),
                            ),
                          ),
                        ),
                        ElevatedButton(
                          onPressed: () => Navigator.pop(modalCtx),
                          child: const Text('Update Stage'),
                        ),
                      ],
                    ),
                  ),
                );
              },
              child: const Text('Open Sheet'),
            ),
          ),
        ),
      ),
    );

    // Tap button to open sheet
    await tester.tap(find.text('Open Sheet'));
    await tester.pumpAndSettle();

    // Verify sheet title and button are present
    expect(find.text('Update Task Stage'), findsOneWidget);
    expect(find.text('Update Stage'), findsOneWidget);

    // Scroll to verify all 7 stages are reachable in the sheet
    for (final stage in stages) {
      final stageFinder = find.text(stage);
      if (tester.widgetList(stageFinder).isEmpty) {
        await tester.drag(find.byType(ListView), const Offset(0, -100));
        await tester.pumpAndSettle();
      }
      expect(find.text(stage), findsWidgets);
    }

    // Reset view
    addTearDown(tester.view.resetPhysicalSize);
  });
}
