import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:so_thu_chi/core/theme/app_theme.dart';
import 'package:so_thu_chi/features/reports/domain/entities/monthly_report.dart';
import 'package:so_thu_chi/features/reports/presentation/screens/financial_health_detail_screen.dart';
import 'package:so_thu_chi/features/reports/presentation/widgets/financial_health_card.dart';

void main() {
  final nov = DateTime(2026, 11, 1);
  final healthyReport = MonthlyReportData(
    selectedMonth: nov,
    currencyCode: 'VND',
    totalIncomeMinor: 20000000,
    totalExpenseMinor: 10000000,
    categorySlices: const [
      CategorySpendSlice(
        categoryId: 'cat_food',
        fallbackName: 'Ăn uống',
        icon: 'restaurant',
        color: 0xFF00C7BE,
        amountMinorUnits: 5000000,
        currencyCode: 'VND',
        percentage: 50,
        transactionCount: 10,
      ),
    ],
    sixMonthTrend: const [],
    dailyExpenseMinor: const {
      5: 1000000,
      12: 4000000,
    },
    nowOverride: DateTime(2026, 11, 15),
  );

  testWidgets('FinancialHealthCard renders compact summary and navigates to detail screen', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: AppTheme.light(),
          home: Scaffold(
            body: SingleChildScrollView(
              child: FinancialHealthCard(
                report: healthyReport,
                locale: 'vi',
                hideBalance: false,
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // 1. Verify compact card contents
    expect(find.text('Sức Khỏe Tài Chính'), findsOneWidget);
    expect(find.textContaining('Chuẩn 50/30/20'), findsOneWidget);
    expect(find.text('/100'), findsOneWidget);
    expect(find.byType(LinearProgressIndicator), findsOneWidget);

    // 2. Tap to navigate to detail screen
    await tester.tap(find.byType(FinancialHealthCard));
    await tester.pumpAndSettle();

    // 3. Verify FinancialHealthDetailScreen is pushed and visible
    expect(find.byType(FinancialHealthDetailScreen), findsOneWidget);
    expect(find.text('Quy chuẩn tài chính 50/30/20'), findsOneWidget);
    expect(find.text('Chi tiết các tiêu chí chấm điểm'), findsOneWidget);
    expect(find.text('Nhịp độ & Điểm nhấn chi tiêu'), findsOneWidget);
    expect(find.text('Gợi ý tối ưu tài chính'), findsOneWidget);

    // 4. Verify back navigation
    final backButton = find.byType(BackButton);
    expect(backButton, findsOneWidget);
    await tester.tap(backButton);
    await tester.pumpAndSettle();

    expect(find.byType(FinancialHealthDetailScreen), findsNothing);
    expect(find.byType(FinancialHealthCard), findsOneWidget);
  });

  testWidgets('FinancialHealthDetailScreen adapts nicely to wide landscape view', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1200, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: AppTheme.light(),
          home: FinancialHealthDetailScreen(
            report: healthyReport,
            locale: 'vi',
            hideBalance: false,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Sức Khỏe Tài Chính'), findsOneWidget);
    expect(find.text('Quy chuẩn tài chính 50/30/20'), findsOneWidget);
    expect(find.text('1. Tỷ lệ tích lũy'), findsOneWidget);
    expect(find.text('2. Kỷ luật chi tiêu theo danh mục'), findsOneWidget);
    expect(find.text('3. Dòng tiền ròng (Net Cashflow)'), findsOneWidget);
  });
}

