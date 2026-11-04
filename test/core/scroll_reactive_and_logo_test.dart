import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:so_thu_chi/core/widgets/apple_kit.dart';
import 'package:so_thu_chi/core/widgets/scroll_reactive_fab.dart';
import 'package:so_thu_chi/core/widgets/so_thu_chi_logo.dart';

void main() {
  group('SoThuChiLogo widget tests', () {
    testWidgets('renders SoThuChiLogo with specified size without crash', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: SoThuChiLogo(size: 64),
            ),
          ),
        ),
      );

      expect(find.byType(SoThuChiLogo), findsOneWidget);
      expect(find.byType(CustomPaint), findsWidgets);
    });
  });

  group('ScrollReactiveFab widget tests', () {
    testWidgets('shows child when visible is true and disables pointer when visible is false', (tester) async {
      var fabTapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: StatefulBuilder(
            builder: (context, setState) {
              return Scaffold(
                floatingActionButton: ScrollReactiveFab(
                  visible: true,
                  child: FloatingActionButton(
                    onPressed: () => fabTapped = true,
                    child: const Icon(Icons.add),
                  ),
                ),
              );
            },
          ),
        ),
      );

      // FAB is visible and tappable
      expect(find.byType(ScrollReactiveFab), findsOneWidget);
      await tester.tap(find.byType(FloatingActionButton));
      expect(fabTapped, isTrue);

      // Update to hidden
      await tester.pumpWidget(
        MaterialApp(
          home: StatefulBuilder(
            builder: (context, setState) {
              return Scaffold(
                floatingActionButton: ScrollReactiveFab(
                  visible: false,
                  child: FloatingActionButton(
                    onPressed: () => fabTapped = true,
                    child: const Icon(Icons.add),
                  ),
                ),
              );
            },
          ),
        ),
      );

      await tester.pump(const Duration(milliseconds: 200));

      final ignorePointerFinder = find.descendant(
        of: find.byType(ScrollReactiveFab),
        matching: find.byType(IgnorePointer),
      );
      final ignorePointer = tester.widget<IgnorePointer>(ignorePointerFinder);
      expect(ignorePointer.ignoring, isTrue);
    });
  });
}
