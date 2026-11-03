import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
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
import 'package:so_thu_chi/features/budgets/data/repositories/firestore_budget_repository.dart';
import 'package:so_thu_chi/features/budgets/domain/entities/budget.dart';
import 'package:so_thu_chi/features/budgets/presentation/screens/budgets_screen.dart';
import 'package:so_thu_chi/features/categories/data/repositories/firestore_category_repository.dart';
import 'package:so_thu_chi/features/transactions/data/repositories/firestore_transaction_repository.dart';
import 'package:so_thu_chi/features/transactions/domain/entities/transaction_entity.dart';
import 'package:so_thu_chi/l10n/app_localizations.dart';

void main() {
  group('FirestoreBudgetRepository & BudgetProgress', () {
    test('upserts overall and category budgets without duplicating same month scope', () async {
      final firestore = FakeFirebaseFirestore();
      final repo = FirestoreBudgetRepository(firestore: firestore, uid: 'u1');
      final month = DateTime(2026, 11, 1);

      final res1 = await repo.upsertMonthlyBudget(
        categoryId: null,
        amount: 10000000,
        currency: 'VND',
        monthStart: month,
        alertThreshold: 80,
      );
      expect(res1, isA<Success<Budget>>());

      // Upserting overall budget again for same month updates existing record instead of duplicating
      final res2 = await repo.upsertMonthlyBudget(
        categoryId: null,
        amount: 12000000,
        currency: 'VND',
        monthStart: DateTime(2026, 11, 18),
        alertThreshold: 85,
      );
      expect(res2, isA<Success<Budget>>());

      final budgets = await repo.getBudgets();
      expect(budgets.length, 1);
      expect(budgets.first.amount, 12000000);
      expect(budgets.first.alertThreshold, 85);

      // Soft delete removes from active budgets
      await repo.softDeleteBudget(budgets.first.id);
      expect(await repo.getBudgets(), isEmpty);
    });
  });

  group('BudgetsScreen & Threshold Warning Banner', () {
    testWidgets('displays progress bar and in-app warning banner when passing alertThreshold', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({'onboarding_completed': true});
      final prefs = await SharedPreferences.getInstance();
      final accRepo = InMemoryAccountRepository();
      final catRepo = InMemoryCategoryRepository();
      final txRepo = InMemoryTransactionRepository(accountRepo: accRepo);
      final budgetRepo = InMemoryBudgetRepository();

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
      await budgetRepo.upsertMonthlyBudget(
        categoryId: 'default_food',
        amount: 3000000,
        currency: 'VND',
        monthStart: now,
        alertThreshold: 80,
      );

      // Spend 2,700,000 VND (90% >= 80% threshold)
      await txRepo.addTransaction(
        amount: 2700000,
        currency: 'VND',
        type: TransactionType.expense,
        accountId: wallet.id,
        categoryId: 'default_food',
        note: 'Đi siêu thị tuần này',
        date: now,
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
            accountRepositoryProvider.overrideWithValue(accRepo),
            categoryRepositoryProvider.overrideWithValue(catRepo),
            transactionRepositoryProvider.overrideWithValue(txRepo),
            budgetRepositoryProvider.overrideWithValue(budgetRepo),
          ],
          child: MaterialApp(
            locale: const Locale('vi'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            theme: AppTheme.light(),
            home: const BudgetsScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('90%'), findsOneWidget);
      expect(
        find.textContaining('Cảnh báo: Ăn uống đã dùng 90% hạn mức tháng!'),
        findsOneWidget,
      );
    });
  });
}

