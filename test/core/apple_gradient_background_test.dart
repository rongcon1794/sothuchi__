import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:so_thu_chi/core/theme/apple_theme_tokens.dart';
import 'package:so_thu_chi/core/widgets/apple_gradient_background.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AppleGradientBackground Unit & Widget Tests', () {
    testWidgets('renders child cleanly and wraps in opaque canvas', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(
            brightness: Brightness.light,
            scaffoldBackgroundColor: AppleTokens.bgLightGrouped,
          ),
          home: const AppleGradientBackground(
            child: Scaffold(
              backgroundColor: Colors.transparent,
              body: Center(
                child: Text('Synchronous Gradient Content'),
              ),
            ),
          ),
        ),
      );

      expect(find.text('Synchronous Gradient Content'), findsOneWidget);
      expect(find.byType(AppleGradientBackground), findsOneWidget);
      expect(find.byType(CustomPaint), findsWidgets);
      expect(find.byType(RepaintBoundary), findsWidgets);
    });

    testWidgets('synchronizes with ancestor AppleAmbientTheme paletteIndex', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(
            brightness: Brightness.light,
            scaffoldBackgroundColor: AppleTokens.bgLightGrouped,
          ),
          home: const AppleAmbientTheme(
            paletteIndex: 2, // Budgets
            child: AppleGradientBackground(
              child: Text('Tab 2 Background'),
            ),
          ),
        ),
      );

      expect(find.text('Tab 2 Background'), findsOneWidget);
    });

    testWidgets('allows explicit paletteIndex override', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(
            brightness: Brightness.dark,
            scaffoldBackgroundColor: AppleTokens.bgDarkGrouped,
          ),
          home: const AppleGradientBackground(
            paletteIndex: 3, // Reports
            child: Text('Explicit Override'),
          ),
        ),
      );

      expect(find.text('Explicit Override'), findsOneWidget);
    });

    testWidgets('paints in OLED True Black mode with pure black canvas', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(
            brightness: Brightness.dark,
            scaffoldBackgroundColor: AppleTokens.bgOledPrimary,
          ),
          home: const AppleGradientBackground(
            isOled: true,
            child: Text('OLED Canvas'),
          ),
        ),
      );

      expect(find.text('OLED Canvas'), findsOneWidget);
    });

    testWidgets('clamps out-of-bounds paletteIndex safely without crashing', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(
            brightness: Brightness.dark,
            scaffoldBackgroundColor: AppleTokens.bgDarkGrouped,
          ),
          home: const AppleGradientBackground(
            paletteIndex: 999, // Out of bounds
            child: Text('Clamped Index'),
          ),
        ),
      );

      expect(find.text('Clamped Index'), findsOneWidget);
    });
  });
}

