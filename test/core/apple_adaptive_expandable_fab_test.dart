import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:so_thu_chi/core/widgets/apple_adaptive_expandable_fab.dart';

void main() {
  group('AppleAdaptiveExpandableFab Widget Tests', () {
    testWidgets('renders icon and label in expanded mode, taps invoke callback', (tester) async {
      var tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            floatingActionButton: AppleAdaptiveExpandableFab(
              isExpanded: true,
              icon: const Icon(CupertinoIcons.plus),
              label: const Text('Thêm giao dịch'),
              onPressed: () => tapped = true,
            ),
          ),
        ),
      );

      expect(find.text('Thêm giao dịch'), findsOneWidget);
      expect(find.byIcon(CupertinoIcons.plus), findsOneWidget);

      await tester.tap(find.byType(AppleAdaptiveExpandableFab));
      expect(tapped, isTrue);
    });

    testWidgets('smoothly collapses text label when isExpanded is false but remains interactive', (tester) async {
      var tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: StatefulBuilder(
            builder: (context, setState) {
              return Scaffold(
                floatingActionButton: AppleAdaptiveExpandableFab(
                  isExpanded: false,
                  icon: const Icon(CupertinoIcons.plus),
                  label: const Text('Thêm giao dịch'),
                  onPressed: () => tapped = true,
                ),
              );
            },
          ),
        ),
      );

      await tester.pumpAndSettle();

      // In collapsed mode, the FAB is still rendered and interactive
      expect(find.byType(AppleAdaptiveExpandableFab), findsOneWidget);
      expect(find.byIcon(CupertinoIcons.plus), findsOneWidget);

      // Verify label widthFactor is 0.0
      final alignFinder = find.descendant(
        of: find.byType(AppleAdaptiveExpandableFab),
        matching: find.byType(AnimatedAlign),
      );
      final animatedAlign = tester.widget<AnimatedAlign>(alignFinder);
      expect(animatedAlign.widthFactor, 0.0);

      // Still tappable
      await tester.tap(find.byType(AppleAdaptiveExpandableFab));
      expect(tapped, isTrue);
    });
  });
}

