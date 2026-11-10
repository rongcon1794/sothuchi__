import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:so_thu_chi/core/theme/app_theme.dart';
import 'package:so_thu_chi/core/widgets/apple_text_field.dart';
import 'package:so_thu_chi/core/widgets/keyboard_accessory_bar.dart';
import 'package:so_thu_chi/l10n/app_localizations.dart';

void main() {
  group('KeyboardDismissBarOverlay Apple HIG Accessory Toolbar Tests', () {
    testWidgets('remains hidden when software keyboard is closed (viewInsets.bottom == 0)', (
      tester,
    ) async {
      final focusNode = FocusNode();
      addTearDown(focusNode.dispose);

      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('vi'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          theme: AppTheme.light(),
          builder: (context, child) => KeyboardDismissBarOverlay(child: child!),
          home: Scaffold(
            body: Center(
              child: AppleTextField(
                focusNode: focusNode,
                placeholder: 'Nhập số tiền...',
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Ẩn bàn phím'), findsNothing);
      expect(find.text('Bàn phím'), findsNothing);
    });

    testWidgets('appears smoothly when keyboard opens and dismisses keyboard on tap', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
        tester.view.resetViewInsets();
      });

      final focusNode = FocusNode();
      final controller = TextEditingController();
      addTearDown(() {
        focusNode.dispose();
        controller.dispose();
      });

      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('vi'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          theme: AppTheme.light(),
          builder: (context, child) => KeyboardDismissBarOverlay(child: child!),
          home: Scaffold(
            body: Center(
              child: AppleTextField(
                focusNode: focusNode,
                controller: controller,
                placeholder: 'Nhập nội dung...',
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap on input field to request focus
      await tester.tap(find.byType(AppleTextField));
      await tester.pump();
      expect(focusNode.hasFocus, isTrue);

      // Simulate software keyboard opening (320dp bottom inset)
      tester.view.viewInsets = const FakeViewPadding(bottom: 320);
      await tester.pumpAndSettle();

      // Accessory bar must now be visible with dismiss button
      expect(find.text('Ẩn bàn phím'), findsOneWidget);
      expect(find.text('Bàn phím'), findsOneWidget);

      // Tap the "Ẩn bàn phím" button
      await tester.tap(find.text('Ẩn bàn phím'));
      await tester.pump();

      // Focus must be dismissed
      expect(focusNode.hasFocus, isFalse);
    });

    testWidgets('adapts to ultra-compact landscape mode (844x390) without overflow', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(844, 390);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
        tester.view.resetViewInsets();
      });

      final focusNode = FocusNode();
      addTearDown(focusNode.dispose);

      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('vi'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          theme: AppTheme.light(),
          builder: (context, child) => KeyboardDismissBarOverlay(child: child!),
          home: Scaffold(
            body: Center(
              child: AppleTextField(
                focusNode: focusNode,
                placeholder: 'Landscape input...',
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Focus input and simulate landscape keyboard (180dp bottom inset)
      focusNode.requestFocus();
      tester.view.viewInsets = const FakeViewPadding(bottom: 180);
      await tester.pumpAndSettle();

      expect(find.text('Ẩn bàn phím'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets(
      'does not rebuild MediaQuery-dependent child screens on intermediate keyboard animation frames',
      (tester) async {
        tester.view.physicalSize = const Size(1080, 2400);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
          tester.view.resetViewInsets();
        });

        var childMediaQueryBuilds = 0;

        await tester.pumpWidget(
          MaterialApp(
            locale: const Locale('vi'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            theme: AppTheme.light(),
            builder: (context, child) => KeyboardDismissBarOverlay(child: child!),
            home: Builder(
              builder: (context) {
                // Subscribe to MediaQuery (just like Scaffold, AppBar, SafeArea, ModalBottomSheet)
                MediaQuery.of(context);
                childMediaQueryBuilds++;
                return const Scaffold(body: SizedBox.expand());
              },
            ),
          ),
        );
        await tester.pumpAndSettle();
        final initialBuilds = childMediaQueryBuilds;

        // Simulate 5 frames of Android 120Hz keyboard slide-up animation
        for (final inset in <double>[40, 110, 190, 260, 320]) {
          tester.view.viewInsets = FakeViewPadding(bottom: inset);
          await tester.pump();
        }

        // Child depending on MediaQuery.of(context) must have 0 rebuilds across all keyboard frames!
        expect(childMediaQueryBuilds, equals(initialBuilds));
      },
    );
  });
}

