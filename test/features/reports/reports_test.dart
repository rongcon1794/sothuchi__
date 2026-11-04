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
      expect(find.byType(BarChart), findsOneWidget);
    });
  });
}

