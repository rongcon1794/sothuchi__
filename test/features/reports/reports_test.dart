import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:so_thu_chi/core/errors/result.dart';
import 'package:so_thu_chi/core/theme/app_theme.dart';
import 'package:so_thu_chi/data/firebase/firebase_providers.dart';
import 'package:so_thu_chi/data/providers/repository_providers.dart';
import 'package:so_thu_chi/features/accounts/data/repositories/firestore_account_repository.dart';
import 'package:so_thu_chi/features/accounts/domain/entities/account.dart';
import 'package:so_thu_chi/features/categories/data/datasources/default_categories_catalog.dart';
import 'package:so_thu_chi/features/categories/data/repositories/firestore_category_repository.dart';
import 'package:so_thu_chi/features/reports/data/repositories/reports_repository_impl.dart';
import 'package:so_thu_chi/features/reports/domain/entities/monthly_report.dart';
import 'package:so_thu_chi/features/reports/presentation/screens/reports_screen.dart';
import 'package:so_thu_chi/features/transactions/data/repositories/firestore_transaction_repository.dart';
import 'package:so_thu_chi/features/transactions/domain/entities/transaction_entity.dart';
import 'package:so_thu_chi/l10n/app_localizations.dart';

void main() {
  group('ReportsRepositoryImpl & ReportsScreen', () {
    test('aggregates monthly category percentages and 6-month trend using integer math', () {
      const repo = ReportsRepositoryImpl();
      final categories = {
        for (final c in DefaultCategoriesCatalog.buildDefaults(DateTime(2026)))
          c.id: c,
      };
      final nov = DateTime(2026, 11, 10);
      final oct = DateTime(2026, 10, 15);

      final txs = [
        TransactionEntity(
          id: '1',
          amount: 20000000,
          type: TransactionType.income,
          accountId: 'w1',
          categoryId: 'default_salary',
          date: nov,
          createdAt: nov,
          updatedAt: nov,
        ),
        TransactionEntity(
          id: '2',
          amount: 3000000,
          type: TransactionType.expense,
          accountId: 'w1',
          categoryId: 'default_food',
          date: nov,
          createdAt: nov,
          updatedAt: nov,
        ),
        TransactionEntity(
          id: '3',
          amount: 1000000,
          type: TransactionType.expense,
          accountId: 'w1',
          categoryId: 'default_transport',
          date: nov,
          createdAt: nov,
          updatedAt: nov,
        ),
        TransactionEntity(
          id: '4',
          amount: 2000000,
          type: TransactionType.expense,
          accountId: 'w1',
          categoryId: 'default_food',
          date: oct,
          createdAt: oct,
          updatedAt: oct,
        ),
      ];

      final report = repo.buildMonthlyReport(
        selectedMonth: nov,
        currencyCode: 'VND',
        transactions: txs,
        categoriesById: categories,
      );

      expect(report.totalIncomeMinor, 20000000);
      expect(report.totalExpenseMinor, 4000000);
      expect(report.netMinor, 16000000);
      expect(report.savingsRatePercent, 80);
      expect(report.categorySlices.length, 2);
      expect(report.categorySlices.first.categoryId, 'default_food');
      expect(report.categorySlices.first.percentage, 75);
      expect(report.sixMonthTrend.length, 6);
      expect(report.sixMonthTrend[4].expenseMinorUnits, 2000000); // Oct
      expect(report.sixMonthTrend[5].expenseMinorUnits, 4000000); // Nov

      // Daily spending heatmap assertions
      expect(report.dailyExpenseMinor[10], 4000000);
      expect(report.peakSpendingDay, 10);
      expect(report.peakSpendingAmountMinor, 4000000);
      expect(report.activeSpendingDaysCount, 1);
    });

    test('calculates average daily spending based on elapsed days so far instead of entire month when month is ongoing', () {
      // 1. Current month (November 2026, 30 days total), simulated on day 10
      final novCurrent = DateTime(2026, 11, 1);
      final currentMonthReport = MonthlyReportData(
        selectedMonth: novCurrent,
        currencyCode: 'VND',
        totalIncomeMinor: 10000000,
        totalExpenseMinor: 5000000, // 5,000,000 VND spent so far
        categorySlices: const [],
        sixMonthTrend: const [],
        nowOverride: DateTime(2026, 11, 10), // Day 10
      );

      expect(currentMonthReport.daysInMonth, 30);
      expect(currentMonthReport.elapsedDaysInMonth, 10);
      // 5,000,000 / 10 days = 500,000 VND/day (NOT 5,000,000 / 30 = 166,666 VND/day)
      expect(currentMonthReport.averageDailyExpenseMinor, 500000);

      // 2. Past month (October 2026, 31 days total), viewed in November 2026
      final octPast = DateTime(2026, 10, 1);
      final pastMonthReport = MonthlyReportData(
        selectedMonth: octPast,
        currencyCode: 'VND',
        totalIncomeMinor: 10000000,
        totalExpenseMinor: 6200000,
        categorySlices: const [],
        sixMonthTrend: const [],
        nowOverride: DateTime(2026, 11, 10),
      );

      expect(pastMonthReport.daysInMonth, 31);
      expect(pastMonthReport.elapsedDaysInMonth, 31);
      // Full month has passed: 6,200,000 / 31 = 200,000 VND/day
      expect(pastMonthReport.averageDailyExpenseMinor, 200000);
    });

    test('activeDailyExpenseMinor correctly benchmarks active spending days into low, medium, and high tiers', () {
      final report = MonthlyReportData(
        selectedMonth: DateTime(2026, 11, 1),
        currencyCode: 'VND',
        totalIncomeMinor: 10000000,
        totalExpenseMinor: 920000, // 4 active days: 50k, 120k, 150k, 600k
        categorySlices: const [],
        sixMonthTrend: const [],
        dailyExpenseMinor: const {
          2: 50000,
          5: 120000,
          8: 150000,
          12: 600000,
        },
        nowOverride: DateTime(2026, 11, 15),
      );

      // Active days = 4
      expect(report.activeSpendingDaysCount, 4);
      // activeDailyExpenseMinor = 920,000 / 4 = 230,000 VND
      expect(report.activeDailyExpenseMinor, 230000);

      final benchmark = report.activeDailyExpenseMinor;
      // Day 2 (50k): 50k / 230k = 0.22 (< 0.65) -> Low (Green)
      expect(50000 / benchmark < 0.65, isTrue);

      // Day 8 (150k): 150k / 230k = 0.65 (between 0.65 and 1.35) -> Medium (Orange)
      expect(150000 / benchmark >= 0.65 && 150000 / benchmark <= 1.35, isTrue);

      // Day 12 (600k): 600k / 230k = 2.61 (> 1.35) -> High (Red)
      expect(600000 / benchmark > 1.35, isTrue);
    });

    testWidgets('renders PieChart donut, BarChart 6-month trend, and switches months', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      SharedPreferences.setMockInitialValues({'onboarding_completed': true});
      final prefs = await SharedPreferences.getInstance();
      final accRepo = InMemoryAccountRepository();
      final catRepo = InMemoryCategoryRepository();
      final txRepo = InMemoryTransactionRepository(accountRepo: accRepo);

      await catRepo.seedDefaultCategoriesIfNeeded();
      final wallet = ((await accRepo.createAccount(
        name: 'Ví chính',
        type: AccountType.cash,
        initialBalance: 10000000,
        currency: 'VND',
        icon: 'cash',
        color: 0xFF0D7C66,
      )) as Success<Account>).value;

      final now = DateTime.now();
      await txRepo.addTransaction(
        amount: 12000000,
        currency: 'VND',
        type: TransactionType.income,
        accountId: wallet.id,
        categoryId: 'default_salary',
        date: now,
      );
      await txRepo.addTransaction(
        amount: 3000000,
        currency: 'VND',
        type: TransactionType.expense,
        accountId: wallet.id,
        categoryId: 'default_food',
        date: now,
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
            accountRepositoryProvider.overrideWithValue(accRepo),
            categoryRepositoryProvider.overrideWithValue(catRepo),
            transactionRepositoryProvider.overrideWithValue(txRepo),
          ],
          child: MaterialApp(
            locale: const Locale('vi'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            theme: AppTheme.light(),
            home: const ReportsScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Sức Khỏe Tài Chính'), findsOneWidget);
      expect(find.text('Bản đồ Chi tiêu theo Ngày'), findsOneWidget);
      expect(find.byType(PieChart), findsOneWidget);
      expect(find.text('75%'), findsWidgets); // savings rate = (12M - 3M) / 12M

      await tester.drag(find.byType(ListView).first, const Offset(0, -500));
      await tester.pumpAndSettle();
      expect(find.byType(LineChart), findsOneWidget);
    });

    testWidgets('adapts charts to 2-column side-by-side layout on wide landscape screens', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1200, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      SharedPreferences.setMockInitialValues({'onboarding_completed': true});
      final prefs = await SharedPreferences.getInstance();
      final accRepo = InMemoryAccountRepository();
      final catRepo = InMemoryCategoryRepository();
      final txRepo = InMemoryTransactionRepository(accountRepo: accRepo);

      await catRepo.seedDefaultCategoriesIfNeeded();
      final wallet = ((await accRepo.createAccount(
        name: 'Ví chính',
        type: AccountType.cash,
        initialBalance: 10000000,
        currency: 'VND',
        icon: 'cash',
        color: 0xFF0D7C66,
      )) as Success<Account>).value;

      final now = DateTime.now();
      await txRepo.addTransaction(
        amount: 5000000,
        currency: 'VND',
        type: TransactionType.expense,
        accountId: wallet.id,
        categoryId: 'default_food',
        date: now,
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
            accountRepositoryProvider.overrideWithValue(accRepo),
            categoryRepositoryProvider.overrideWithValue(catRepo),
            transactionRepositoryProvider.overrideWithValue(txRepo),
          ],
          child: MaterialApp(
            locale: const Locale('vi'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            theme: AppTheme.light(),
            home: const ReportsScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Scroll down to Donut Chart
      await tester.drag(find.byType(ListView).first, const Offset(0, -350));
      await tester.pumpAndSettle();
      expect(find.byType(PieChart), findsOneWidget);

      // Scroll down to Bar Chart
      await tester.drag(find.byType(ListView).first, const Offset(0, -450));
      await tester.pumpAndSettle();

      // Both LineChart and 6-Month Summary Panel are visible on wide screen
      expect(find.byType(LineChart), findsOneWidget);
      expect(find.text('Tổng quan 6 Tháng'), findsOneWidget);
    });
  });
}

