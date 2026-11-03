import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:so_thu_chi/core/contracts/transaction_draft_contract.dart';
import 'package:so_thu_chi/core/errors/result.dart';
import 'package:so_thu_chi/core/theme/app_theme.dart';
import 'package:so_thu_chi/data/firebase/firebase_providers.dart';
import 'package:so_thu_chi/data/providers/repository_providers.dart';
import 'package:so_thu_chi/features/accounts/data/repositories/firestore_account_repository.dart';
import 'package:so_thu_chi/features/accounts/domain/entities/account.dart';
import 'package:so_thu_chi/features/categories/data/repositories/firestore_category_repository.dart';
import 'package:so_thu_chi/features/transactions/data/repositories/firestore_transaction_repository.dart';
import 'package:so_thu_chi/features/transactions/domain/entities/transaction_entity.dart';
import 'package:so_thu_chi/features/transactions/presentation/screens/home_dashboard_screen.dart';
import 'package:so_thu_chi/features/transactions/presentation/screens/transaction_form_screen.dart';
import 'package:so_thu_chi/features/transactions/presentation/screens/transactions_screen.dart';
import 'package:so_thu_chi/l10n/app_localizations.dart';

void main() {
  group('FirestoreTransactionRepository balance synchronization & soft-delete Undo', () {
    test(
      'atomically updates wallet balances across add, edit (wallet + type change), soft-delete, and undo restore',
      () async {
        final firestore = FakeFirebaseFirestore();
        const uid = 'u_tx_1';
        final accRepo = FirestoreAccountRepository(
          firestore: firestore,
          uid: uid,
        );
        final txRepo = FirestoreTransactionRepository(
          firestore: firestore,
          uid: uid,
        );

        final cash = ((await accRepo.createAccount(
          name: 'Tiền mặt',
          type: AccountType.cash,
          initialBalance: 2000000,
          currency: 'VND',
          icon: 'cash',
          color: 0xFF0D7C66,
        )) as Success<Account>).value;

        final bank = ((await accRepo.createAccount(
          name: 'Techcombank',
          type: AccountType.bank,
          initialBalance: 5000000,
          currency: 'VND',
          icon: 'bank',
          color: 0xFF2563EB,
        )) as Success<Account>).value;

        // 1. Add Expense 150,000 VND on Cash -> Cash = 1,850,000
        final addRes = await txRepo.addTransaction(
          amount: 150000,
          currency: 'VND',
          type: TransactionType.expense,
          accountId: cash.id,
          categoryId: 'default_food',
          note: 'Ăn trưa bún chả',
          date: DateTime(2026, 11, 3, 12, 30),
          tags: ['ăn trưa', 'văn phòng'],
        );
        final tx1 = (addRes as Success<TransactionEntity>).value;

        var accounts = await accRepo.getAccounts();
        expect(accounts.firstWhere((a) => a.id == cash.id).balance, 1850000);
        expect(accounts.firstWhere((a) => a.id == bank.id).balance, 5000000);

        // 2. Edit tx1: move from Cash to Bank AND change amount to 250,000 expense
        // Cash should revert back to 2,000,000; Bank should become 4,750,000
        final editRes = await txRepo.updateTransaction(
          tx1.copyWith(accountId: bank.id, amount: 250000),
        );
        expect(editRes.isSuccess, isTrue);

        accounts = await accRepo.getAccounts();
        expect(accounts.firstWhere((a) => a.id == cash.id).balance, 2000000);
        expect(accounts.firstWhere((a) => a.id == bank.id).balance, 4750000);

        // 3. Soft-delete tx1 -> Bank reverts to 5,000,000 and tx disappears from active list
        final delRes = await txRepo.softDeleteTransaction(tx1.id);
        expect(delRes.isSuccess, isTrue);
        expect(await txRepo.getTransactions(), isEmpty);

        accounts = await accRepo.getAccounts();
        expect(accounts.firstWhere((a) => a.id == bank.id).balance, 5000000);

        // 4. Undo (restoreTransaction) -> Bank returns to 4,750,000 and tx is active again
        final restoreRes = await txRepo.restoreTransaction(tx1.id);
        expect(restoreRes.isSuccess, isTrue);
        expect((await txRepo.getTransactions()).length, 1);

        accounts = await accRepo.getAccounts();
        expect(accounts.firstWhere((a) => a.id == bank.id).balance, 4750000);
      },
    );
  });

  group('HomeDashboardScreen, TransactionsScreen & TransactionFormScreen', () {
    testWidgets(
      'HomeDashboardScreen formats VND balance, toggles hide/show, and shows monthly cashflow',
      (tester) async {
        SharedPreferences.setMockInitialValues({'onboarding_completed': true});
        final prefs = await SharedPreferences.getInstance();
        final accRepo = InMemoryAccountRepository();
        final catRepo = InMemoryCategoryRepository();
        final txRepo = InMemoryTransactionRepository(accountRepo: accRepo);

        await catRepo.seedDefaultCategoriesIfNeeded();
        final wallet = ((await accRepo.createAccount(
          name: 'Ví chính',
          type: AccountType.cash,
          initialBalance: 1500000,
          currency: 'VND',
          icon: 'cash',
          color: 0xFF0D7C66,
        )) as Success<Account>).value;

        await txRepo.addTransaction(
          amount: 250000,
          currency: 'VND',
          type: TransactionType.expense,
          accountId: wallet.id,
          categoryId: 'default_food',
          note: 'Cà phê sáng',
          date: DateTime.now(),
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
              home: const HomeDashboardScreen(),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Net balance = 1,500,000 - 250,000 = 1.250.000 ₫
        expect(find.text('1.250.000 ₫'), findsAtLeastNWidgets(1));

        // Toggle hide balance
        await tester.tap(find.byTooltip('Ẩn số dư'));
        await tester.pumpAndSettle();
        expect(find.text('•••••• ₫'), findsAtLeastNWidgets(1));

        // Scroll down to Recent Transactions section on 600px test viewport
        await tester.drag(find.byType(ListView).first, const Offset(0, -320));
        await tester.pumpAndSettle();
        expect(find.textContaining('Cà phê sáng'), findsOneWidget);
      },
    );

    testWidgets(
      'TransactionsScreen searches and filters transactions, and TransactionFormScreen accepts AI TransactionDraft',
      (tester) async {
        SharedPreferences.setMockInitialValues({'onboarding_completed': true});
        final prefs = await SharedPreferences.getInstance();
        final accRepo = InMemoryAccountRepository();
        final catRepo = InMemoryCategoryRepository();
        final txRepo = InMemoryTransactionRepository(accountRepo: accRepo);

        await catRepo.seedDefaultCategoriesIfNeeded();
        final wallet = ((await accRepo.createAccount(
          name: 'Ví tiền mặt',
          type: AccountType.cash,
          initialBalance: 5000000,
          currency: 'VND',
          icon: 'cash',
          color: 0xFF0D7C66,
        )) as Success<Account>).value;

        await txRepo.addTransaction(
          amount: 55000,
          currency: 'VND',
          type: TransactionType.expense,
          accountId: wallet.id,
          categoryId: 'default_food',
          note: 'Phở bò tái lăn',
          date: DateTime.now(),
        );
        await txRepo.addTransaction(
          amount: 15000000,
          currency: 'VND',
          type: TransactionType.income,
          accountId: wallet.id,
          categoryId: 'default_salary',
          note: 'Lương tháng 11',
          date: DateTime.now(),
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
              home: const TransactionsScreen(),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.textContaining('Phở bò tái lăn'), findsOneWidget);
        expect(find.textContaining('Lương tháng 11'), findsOneWidget);

        // Search filter
        await tester.enterText(find.byType(TextField), 'Phở bò');
        await tester.pumpAndSettle();
        expect(find.textContaining('Phở bò tái lăn'), findsOneWidget);
        expect(find.textContaining('Lương tháng 11'), findsNothing);

        // Verify AI extensibility contract pre-populates TransactionFormScreen
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
              home: const TransactionFormScreen(
                initialDraft: TransactionDraft(
                  amountMinorUnits: 50000,
                  note: 'Ăn phở 50k hôm qua',
                  source: 'ai_nlp',
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('50.000'), findsOneWidget);
        expect(find.text('Ăn phở 50k hôm qua'), findsOneWidget);
      },
    );
  });
}

