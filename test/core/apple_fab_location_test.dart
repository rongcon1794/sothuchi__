import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:so_thu_chi/core/widgets/apple_kit.dart';

void main() {
  group('AppleFloatingActionButtonLocation Unit & Layout Tests', () {
    testWidgets('positions FAB cleanly above floating bar with safe area clearance', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(
            size: Size(390, 844),
            padding: EdgeInsets.only(bottom: 34),
            viewPadding: EdgeInsets.only(bottom: 34), // iPhone home indicator
          ),
          child: MaterialApp(
            home: Scaffold(
              floatingActionButtonLocation:
                  const AppleFloatingActionButtonLocation(),
              floatingActionButton: FloatingActionButton(
                onPressed: () {},
                child: const Icon(Icons.add),
              ),
              body: const SizedBox.expand(),
            ),
          ),
        ),
      );

      final fabFinder = find.byType(FloatingActionButton);
      expect(fabFinder, findsOneWidget);

      final fabRect = tester.getRect(fabFinder);

      // Total bottom clearance:
      // Bar height (64) + bottom margin (8) + gap (16) = 88 + safeArea (34) = 122
      // Screen height: 844. FAB bottom should be: 844 - 122 = 722.
      expect(fabRect.bottom, 722.0);

      // FAB is aligned to the right margin (16px from right edge):
      // 390 - 16 = 374.
      expect(fabRect.right, 374.0);
    });

    testWidgets('lifts FAB when on-screen keyboard appears (viewInsets.bottom > 0)', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(
            size: Size(390, 844),
            padding: EdgeInsets.only(bottom: 34),
            viewInsets: EdgeInsets.only(bottom: 300), // Keyboard open
          ),
          child: MaterialApp(
            home: Scaffold(
              floatingActionButtonLocation:
                  const AppleFloatingActionButtonLocation(),
              floatingActionButton: FloatingActionButton(
                onPressed: () {},
                child: const Icon(Icons.add),
              ),
              body: const SizedBox.expand(),
            ),
          ),
        ),
      );

      final fabFinder = find.byType(FloatingActionButton);
      final fabRect = tester.getRect(fabFinder);

      // When keyboard is 300px, bottom offset is keyboard + 16 = 316.
      // Screen height: 844. FAB bottom should be: 844 - 316 = 528.
      expect(fabRect.bottom, 528.0);
    });
  });
}
