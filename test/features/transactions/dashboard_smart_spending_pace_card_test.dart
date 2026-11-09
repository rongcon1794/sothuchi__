import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:so_thu_chi/core/theme/app_theme.dart';
import 'package:so_thu_chi/core/utils/money.dart';
import 'package:so_thu_chi/features/budgets/domain/entities/budget.dart';
import 'package:so_thu_chi/features/budgets/presentation/controllers/budgets_controller.dart';
import 'package:so_thu_chi/features/transactions/presentation/controllers/transactions_controller.dart';
import 'package:so_thu_chi/features/transactions/presentation/widgets/dashboard_smart_spending_pace_card.dart';
import 'package:so_thu_chi/l10n/app_localizations.dart';

void main() {
  group('DashboardSmartSpendingPaceCard Unit & Widget Tests', () {
    testWidgets('calculates safe daily spending accurately from active monthly budget', (
      tester,
    ) async {
      final now = DateTime.now();
      final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
      final daysRemaining = daysInMonth - now.day + 1;

      const budgetAmount = 10000000;
      const spentAmount = 3400000;
      final expectedDailyMinor = (budgetAmount - spentAmount) ~/ daysRemaining;
      final expectedDailyFormatted = Money(minorUnits: expectedDailyMinor, currencyCode: 'VND')
          .format(locale: 'vi');

      final budget = Budget(
        id: 'b1',
        amount: budgetAmount,
        currency: 'VND',
        startDate: DateTime(now.year, now.month, 1),
        createdAt: now,
        updatedAt: now,
      );

      final progress = BudgetProgress(
        budget: budget,
        spentMinorUnits: spentAmount,
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentMonthBudgetProgressProvider.overrideWithValue([progress]),
          ],
          child: MaterialApp(
            locale: const Locale('vi'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            theme: AppTheme.light(),
            home: const Scaffold(
              body: DashboardSmartSpendingPaceCard(
                monthSummary: MonthlyCashflowSummary(
                  income: Money(minorUnits: 25000000, currencyCode: 'VND'),
                  expense: Money(minorUnits: spentAmount, currencyCode: 'VND'),
                  net: Money(minorUnits: 25000000 - spentAmount, currencyCode: 'VND'),
                ),
                totalBalance: Money(minorUnits: 50000000, currencyCode: 'VND'),
                locale: 'vi',
                hideBalance: false,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Card should prioritize budget (10M - 3.4M) rather than income (25M - 3.4M)
      expect(find.text('Nhịp độ chi tiêu thông minh'), findsOneWidget);
      expect(find.text('Mức chi an toàn hôm nay'), findsOneWidget);
      expect(find.text(expectedDailyFormatted), findsOneWidget);
    });

    testWidgets('when budget is exceeded, displays 0 VND instead of falling back to total balance', (
      tester,
    ) async {
      final now = DateTime.now();
      const budgetAmount = 5000000;
      const spentAmount = 6000000; // Exceeded!

      final budget = Budget(
        id: 'b1',
        amount: budgetAmount,
        currency: 'VND',
        startDate: DateTime(now.year, now.month, 1),
        createdAt: now,
        updatedAt: now,
      );

      final progress = BudgetProgress(
        budget: budget,
        spentMinorUnits: spentAmount,
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentMonthBudgetProgressProvider.overrideWithValue([progress]),
          ],
          child: MaterialApp(
            locale: const Locale('vi'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            theme: AppTheme.light(),
            home: const Scaffold(
              body: DashboardSmartSpendingPaceCard(
                monthSummary: MonthlyCashflowSummary(
                  income: Money(minorUnits: 0, currencyCode: 'VND'),
                  expense: Money(minorUnits: spentAmount, currencyCode: 'VND'),
                  net: Money(minorUnits: -spentAmount, currencyCode: 'VND'),
                ),
                totalBalance: Money(minorUnits: 80000000, currencyCode: 'VND'),
                locale: 'vi',
                hideBalance: false,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text(const Money.zero('VND').format(locale: 'vi')), findsOneWidget);
      expect(find.text('Vượt ngân sách'), findsOneWidget);
    });

    testWidgets('when no budget exists, falls back cleanly to monthly income without balance glitches', (
      tester,
    ) async {
      final now = DateTime.now();
      final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
      final daysRemaining = daysInMonth - now.day + 1;

      const incomeAmount = 15000000;
      const spentAmount = 4000000;
      final expectedDailyMinor = (incomeAmount - spentAmount) ~/ daysRemaining;
      final expectedDailyFormatted = Money(minorUnits: expectedDailyMinor, currencyCode: 'VND')
          .format(locale: 'vi');

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentMonthBudgetProgressProvider.overrideWithValue([]),
          ],
          child: MaterialApp(
            locale: const Locale('vi'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            theme: AppTheme.light(),
            home: const Scaffold(
              body: DashboardSmartSpendingPaceCard(
                monthSummary: MonthlyCashflowSummary(
                  income: Money(minorUnits: incomeAmount, currencyCode: 'VND'),
                  expense: Money(minorUnits: spentAmount, currencyCode: 'VND'),
                  net: Money(minorUnits: incomeAmount - spentAmount, currencyCode: 'VND'),
                ),
                totalBalance: Money(minorUnits: 30000000, currencyCode: 'VND'),
                locale: 'vi',
                hideBalance: false,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text(expectedDailyFormatted), findsOneWidget);
    });
  });
}
