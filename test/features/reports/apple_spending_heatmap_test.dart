import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:so_thu_chi/core/theme/app_theme.dart';
import 'package:so_thu_chi/features/reports/domain/entities/monthly_report.dart';
import 'package:so_thu_chi/features/reports/presentation/widgets/apple_spending_heatmap.dart';

void main() {
  testWidgets('AppleSpendingHeatmap renders and toggles selection with rounded border', (
    tester,
  ) async {
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
}
