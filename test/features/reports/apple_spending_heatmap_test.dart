import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:so_thu_chi/core/theme/app_theme.dart';
import 'package:so_thu_chi/features/reports/domain/entities/monthly_report.dart';
import 'package:so_thu_chi/features/reports/presentation/widgets/apple_spending_heatmap.dart';

void main() {
  final nov = DateTime(2026, 11, 1);
  final report = MonthlyReportData(
    selectedMonth: nov,
    currencyCode: 'VND',
    totalIncomeMinor: 10000000,
    totalExpenseMinor: 5000000,
    categorySlices: const [],
    sixMonthTrend: const [],
    dailyExpenseMinor: const {
      5: 500000,
      10: 1500000,
    },
  );

  testWidgets('AppleSpendingHeatmap renders and toggles selection in portrait mode', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: Scaffold(
          body: SingleChildScrollView(
            child: AppleSpendingHeatmap(
              report: report,
              locale: 'vi',
              hideBalance: false,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Verify Title and Day 5
    expect(find.text('Bản đồ Chi tiêu theo Ngày'), findsOneWidget);
    expect(find.text('5'), findsOneWidget);

    // Tap on Day 5 to select it
    await tester.tap(find.text('5'));
    await tester.pumpAndSettle();

    // Verify detail container appears for Day 5
    expect(find.text('Ngày 5/11:'), findsOneWidget);

    // Verify the AnimatedContainer has rounded corners
    final animatedContainerFinder = find.ancestor(
      of: find.text('5'),
      matching: find.byType(AnimatedContainer),
    );
    expect(animatedContainerFinder, findsOneWidget);

    final animatedContainer = tester.widget<AnimatedContainer>(animatedContainerFinder);
    final decoration = animatedContainer.decoration as BoxDecoration;
    expect(decoration.borderRadius, BorderRadius.circular(8));
    expect(decoration.border, isNotNull);
    expect(decoration.boxShadow, isNotNull);

    // Tap Day 5 again to deselect
    await tester.tap(find.text('5'));
    await tester.pumpAndSettle();

    expect(find.text('Ngày 5/11:'), findsNothing);
  });

  testWidgets('AppleSpendingHeatmap adapts to wide landscape screens with side-by-side inspector', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1200, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: Scaffold(
          body: SingleChildScrollView(
            child: AppleSpendingHeatmap(
              report: report,
              locale: 'vi',
              hideBalance: false,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // In wide screen with no day selected, right inspector shows overview
    expect(find.text('Tổng quan Chi tiêu Tháng'), findsOneWidget);
    expect(find.text('Chi tiêu TB/ngày:'), findsOneWidget);

    // Tap Day 10 (Peak day)
    await tester.tap(find.text('10'));
    await tester.pumpAndSettle();

    // Right panel inspector updates with Day 10 details and comparison badge
    expect(find.text('Ngày 10/11:'), findsOneWidget);
    expect(find.text('Tổng chi trong ngày:'), findsOneWidget);
  });
}
