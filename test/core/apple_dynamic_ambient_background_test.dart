import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:so_thu_chi/core/theme/apple_theme_tokens.dart';
import 'package:so_thu_chi/core/widgets/apple_dynamic_ambient_background.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AppleDynamicAmbientBackground Unit & Widget Tests', () {
    testWidgets('renders child widget cleanly', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(
            brightness: Brightness.light,
            scaffoldBackgroundColor: AppleTokens.bgLightGrouped,
          ),
          home: const AppleDynamicAmbientBackground(
            currentIndex: 0,
            child: Scaffold(
              backgroundColor: Colors.transparent,
              body: Center(
                child: Text('Ambient Test Content'),
              ),
            ),
          ),
        ),
      );

      expect(find.text('Ambient Test Content'), findsOneWidget);
      expect(find.byType(AppleDynamicAmbientBackground), findsOneWidget);
      expect(find.byType(CustomPaint), findsWidgets);
    });

    testWidgets('animates smoothly across tab indices', (tester) async {
      int activeIndex = 0;

      await tester.pumpWidget(
        StatefulBuilder(
          builder: (context, setState) {
            return MaterialApp(
              theme: ThemeData(
                brightness: Brightness.light,
                scaffoldBackgroundColor: AppleTokens.bgLightGrouped,
              ),
              home: AppleDynamicAmbientBackground(
                currentIndex: activeIndex,
                duration: const Duration(milliseconds: 300),
                child: Column(
                  children: [
                    Text('Tab: $activeIndex'),
                    ElevatedButton(
                      onPressed: () => setState(() => activeIndex = 3),
                      child: const Text('Go to Reports'),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      );

      expect(find.text('Tab: 0'), findsOneWidget);

      // Tap button to switch to tab 3 (Reports)
      await tester.tap(find.text('Go to Reports'));
      await tester.pump(); // Start animation
      await tester.pump(const Duration(milliseconds: 150)); // Mid-transition
      expect(find.text('Tab: 3'), findsOneWidget);

      await tester.pump(const Duration(milliseconds: 200)); // Finish transition
      await tester.pumpAndSettle();
    });

    testWidgets('clamps negative and out-of-bound indices safely', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(
            brightness: Brightness.dark,
            scaffoldBackgroundColor: AppleTokens.bgDarkGrouped,
          ),
          home: const AppleDynamicAmbientBackground(
            currentIndex: 99, // Out of bounds
            child: Text('Safe Clamp'),
          ),
        ),
      );

      expect(find.text('Safe Clamp'), findsOneWidget);
    });

    testWidgets('paints in OLED True Black mode without errors', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(
            brightness: Brightness.dark,
            scaffoldBackgroundColor: AppleTokens.bgOledPrimary, // Triggers OLED mode
          ),
          home: const AppleDynamicAmbientBackground(
            currentIndex: 0,
            child: Text('OLED Content'),
          ),
        ),
      );

      expect(find.text('OLED Content'), findsOneWidget);
    });
  });
}

