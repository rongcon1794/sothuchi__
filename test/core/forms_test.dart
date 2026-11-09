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

  group('AppleSelectorRow', () {
    testWidgets('renders title, placeholder, and handles tap', (tester) async {
      bool tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          home: Scaffold(
            body: AppleSelectorRow(
              title: 'Danh mục',
              placeholder: 'Chọn danh mục',
              icon: Icons.category,
              onTap: () => tapped = true,
            ),
          ),
        ),
      );

      expect(find.text('Danh mục'), findsOneWidget);
      expect(find.text('Chọn danh mục'), findsOneWidget);
      expect(find.byIcon(Icons.category), findsOneWidget);
      expect(find.byIcon(CupertinoIcons.chevron_right), findsOneWidget);

      await tester.tap(find.text('Danh mục'));
      await tester.pumpAndSettle();
      expect(tapped, isTrue);
    });

    testWidgets('renders valueText and clear button when non-empty', (tester) async {
      bool cleared = false;

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          home: Scaffold(
            body: AppleSelectorRow(
              title: 'Ví thanh toán',
              valueText: 'Ví MoMo',
              icon: Icons.account_balance_wallet,
              onTap: () {},
              onClear: () => cleared = true,
            ),
          ),
        ),
      );

      expect(find.text('Ví thanh toán'), findsOneWidget);
      expect(find.text('Ví MoMo'), findsOneWidget);
      expect(find.byIcon(CupertinoIcons.clear_circled_solid), findsOneWidget);

      await tester.tap(find.byIcon(CupertinoIcons.clear_circled_solid));
      await tester.pumpAndSettle();
      expect(cleared, isTrue);
    });
  });

  group('AppleExpandableSection', () {
    testWidgets('toggles expanded state smoothly', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          home: const Scaffold(
            body: AppleExpandableSection(
              title: 'Danh mục chi tiêu',
              subtitle: 'Ăn uống',
              icon: Icons.restaurant,
              hasActiveValue: true,
              expandedChild: Text('Nội dung danh mục mở rộng'),
            ),
          ),
        ),
      );

      expect(find.text('Danh mục chi tiêu'), findsOneWidget);
      expect(find.text('Ăn uống'), findsOneWidget);

      // Tap header to expand
      await tester.tap(find.text('Danh mục chi tiêu'));
      await tester.pumpAndSettle();

      expect(find.text('Nội dung danh mục mở rộng'), findsOneWidget);
    });
  });
}
