import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:so_thu_chi/core/theme/app_theme.dart';
import 'package:so_thu_chi/core/widgets/forms/forms.dart';

void main() {
  group('HeroAmountCard', () {
    testWidgets('renders initial amount and allows typing', (tester) async {
      final controller = TextEditingController(text: '100.000');

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          home: Scaffold(
            body: HeroAmountCard(
              controller: controller,
              currencyCode: 'VND',
              label: 'Số dư ban đầu',
            ),
          ),
        ),
      );

      expect(find.text('SỐ DƯ BAN ĐẦU'), findsOneWidget);
      expect(find.text('100.000'), findsOneWidget);
      expect(find.text('₫'), findsOneWidget);
      expect(find.text('+000'), findsOneWidget);

      // Tap clear button
      await tester.tap(find.byIcon(CupertinoIcons.clear_circled_solid));
      await tester.pumpAndSettle();
      expect(controller.text, isEmpty);
    });

    testWidgets('appends triple zeros correctly', (tester) async {
      final controller = TextEditingController(text: '150');

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          home: Scaffold(
            body: HeroAmountCard(
              controller: controller,
              currencyCode: 'VND',
            ),
          ),
        ),
      );

      await tester.tap(find.text('+000'));
      await tester.pumpAndSettle();

      expect(controller.text, '150.000');
    });

    testWidgets('sets preset amount on pill tap', (tester) async {
      final controller = TextEditingController();

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          home: Scaffold(
            body: HeroAmountCard(
              controller: controller,
              currencyCode: 'VND',
            ),
          ),
        ),
      );

      expect(find.text('500k'), findsOneWidget);
      await tester.tap(find.text('500k'));
      await tester.pumpAndSettle();

      expect(controller.text, '500.000');
    });
  });
}
