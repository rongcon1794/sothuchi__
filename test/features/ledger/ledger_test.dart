import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:so_thu_chi/core/constants/currency_constants.dart';
import 'package:so_thu_chi/core/theme/app_theme.dart';
import 'package:so_thu_chi/data/firebase/firebase_providers.dart';
import 'package:so_thu_chi/data/providers/repository_providers.dart';
import 'package:so_thu_chi/features/accounts/data/repositories/firestore_account_repository.dart';
import 'package:so_thu_chi/features/accounts/presentation/controllers/accounts_controller.dart';
import 'package:so_thu_chi/features/budgets/data/repositories/firestore_budget_repository.dart';
import 'package:so_thu_chi/features/budgets/presentation/controllers/budgets_controller.dart';
import 'package:so_thu_chi/features/ledger/data/repositories/firestore_ledger_repository.dart';
import 'package:so_thu_chi/features/ledger/domain/entities/ledger_book.dart';
import 'package:so_thu_chi/features/ledger/presentation/controllers/ledgers_controller.dart';
import 'package:so_thu_chi/features/ledger/presentation/widgets/ledger_selector_pill.dart';
import 'package:so_thu_chi/features/ledger/presentation/widgets/ledger_switcher_sheet.dart';
import 'package:so_thu_chi/features/transactions/data/repositories/firestore_transaction_repository.dart';
import 'package:so_thu_chi/features/transactions/domain/entities/transaction_entity.dart';
import 'package:so_thu_chi/features/transactions/presentation/controllers/transactions_controller.dart';
import 'package:so_thu_chi/l10n/app_localizations.dart';

void main() {
  group('LedgerBook Domain Entity Tests', () {
    test('defaultPersonal returns initialized entity with isDefault = true', () {
      final book = LedgerBook.defaultPersonal();
      expect(book.id, LedgerBook.defaultPersonalId);
      expect(book.name, 'Sổ Cá Nhân');
      expect(book.isDefault, isTrue);
      expect(book.type, LedgerType.personal);
    });

    test('copyWith properly overrides fields', () {
      final book = LedgerBook.defaultPersonal();
      final updated = book.copyWith(name: 'Sổ Riêng', color: 0xFF5856D6);
      expect(updated.name, 'Sổ Riêng');
      expect(updated.color, 0xFF5856D6);
      expect(updated.id, book.id);
    });
  });

  group('InMemoryLedgerRepository Unit Tests', () {
    test('seeds default books, creates new book, and prevents deleting default', () async {
      final repo = InMemoryLedgerRepository();
      var books = await repo.watchLedgers().first;
      expect(books.length, 2);
      expect(books.any((b) => b.id == LedgerBook.defaultPersonalId), isTrue);

      // Create new business book
      final createRes = await repo.createLedger(
        LedgerBook(
          id: 'ledger_biz',
          name: 'Quỹ Dự Án Nhỏ',
          type: LedgerType.business,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );
      expect(createRes.isSuccess, isTrue);
      books = await repo.watchLedgers().first;
      expect(books.length, 3);

      // Trying to delete default personal book fails
      final delDefaultRes = await repo.deleteLedger(LedgerBook.defaultPersonalId);
      expect(delDefaultRes.isFailure, isTrue);

      // Deleting custom book succeeds
      final delCustomRes = await repo.deleteLedger('ledger_biz');
      expect(delCustomRes.isSuccess, isTrue);
      books = await repo.watchLedgers().first;
      expect(books.length, 2);
    });
  });

  group('LedgerSelectorPill and Switcher Widget Tests', () {
    late InMemoryLedgerRepository ledgerRepo;
    late SharedPreferences prefs;

    setUp(() async {
      SharedPreferences.setMockInitialValues({
        'theme_mode': 'system',
        'locale_code': 'vi',
        'active_ledger_id': LedgerBook.defaultPersonalId,
      });
      prefs = await SharedPreferences.getInstance();
      ledgerRepo = InMemoryLedgerRepository();
    });

    Widget buildTestWidget() {
      return ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          ledgerRepositoryProvider.overrideWithValue(ledgerRepo),
        ],
        child: MaterialApp(
          locale: const Locale('vi'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          theme: AppTheme.light(),
          home: const Scaffold(
            appBar: null,
            body: Center(
              child: LedgerSelectorPill(),
            ),
          ),
        ),
      );
    }

    testWidgets('renders active book name and opens switcher modal', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      // Renders active book name "Sổ Cá Nhân"
      expect(find.text('Sổ Cá Nhân'), findsOneWidget);

      // Tap on pill
      await tester.tap(find.byType(LedgerSelectorPill));
      await tester.pumpAndSettle();

      // Switcher bottom sheet opened
      expect(find.byType(LedgerSwitcherSheet), findsOneWidget);
      expect(find.text('Chuyển Sổ Thu Chi'), findsOneWidget);
      expect(find.text('Sổ Gia Đình'), findsOneWidget);

      // Tap to switch to "Sổ Gia Đình"
      await tester.tap(find.text('Sổ Gia Đình'));
      await tester.pumpAndSettle();

      // Active ledger on pill switched to "Sổ Gia Đình"
      expect(find.text('Sổ Gia Đình'), findsOneWidget);
    });

    testWidgets('compact mode renders icon button and opens switcher modal on tap', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
            ledgerRepositoryProvider.overrideWithValue(ledgerRepo),
          ],
          child: MaterialApp(
            locale: const Locale('vi'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            theme: AppTheme.light(),
            home: const Scaffold(
              body: Center(
                child: LedgerSelectorPill(compact: true),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(LedgerSelectorPill), findsOneWidget);
      expect(find.byType(Tooltip), findsOneWidget);

      await tester.tap(find.byType(LedgerSelectorPill));
      await tester.pumpAndSettle();

      expect(find.byType(LedgerSwitcherSheet), findsOneWidget);
      expect(find.text('Chuyển Sổ Thu Chi'), findsOneWidget);
    });
  });

  group('Multi-Ledger Data Isolation Tests', () {
    late SharedPreferences prefs;
    late InMemoryLedgerRepository ledgerRepo;
    late InMemoryAccountRepository accountRepo;
    late InMemoryTransactionRepository txRepo;
    late InMemoryBudgetRepository budgetRepo;
    late ProviderContainer container;

    setUp(() async {
      SharedPreferences.setMockInitialValues({
        'theme_mode': 'system',
        'locale_code': 'vi',
        'active_ledger_id': LedgerBook.defaultPersonalId,
      });
      prefs = await SharedPreferences.getInstance();
      ledgerRepo = InMemoryLedgerRepository();
      accountRepo = InMemoryAccountRepository();
      txRepo = InMemoryTransactionRepository(accountRepo: accountRepo);
      budgetRepo = InMemoryBudgetRepository();

      container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          ledgerRepositoryProvider.overrideWithValue(ledgerRepo),
          accountRepositoryProvider.overrideWithValue(accountRepo),
          transactionRepositoryProvider.overrideWithValue(txRepo),
          budgetRepositoryProvider.overrideWithValue(budgetRepo),
        ],
      );

      container.listen(transactionsStreamProvider, (_, _) {});
      container.listen(accountsStreamProvider, (_, _) {});
      container.listen(budgetsStreamProvider, (_, _) {});

      // Seed initial cash wallet for default personal ledger
      await accountRepo.ensureDefaultWallet(
        currency: AppCurrencies.defaultCode,
        ledgerId: LedgerBook.defaultPersonalId,
      );
      await Future<void>.delayed(const Duration(milliseconds: 10));
    });

    tearDown(() {
      container.dispose();
    });

    test('isolates transactions and accounts between personal and family ledgers', () async {
      // 1. Initially on Sổ Cá Nhân
      expect(container.read(activeLedgerIdProvider), LedgerBook.defaultPersonalId);

      // Add a transaction to personal ledger
      final personalTx = await container
          .read(transactionsActionControllerProvider.notifier)
          .add(
            amount: 50000,
            currency: 'VND',
            type: TransactionType.expense,
            accountId: 'default_cash_wallet_${LedgerBook.defaultPersonalId}',
            categoryId: 'food',
            note: 'Ăn sáng cá nhân',
            date: DateTime.now(),
          );
      expect(personalTx.isSuccess, isTrue);
      expect(personalTx.valueOrNull!.ledgerId, LedgerBook.defaultPersonalId);
      await Future<void>.delayed(const Duration(milliseconds: 10));

      // Verify transactionsStreamProvider sees the personal transaction
      var currentTxs = container.read(transactionsStreamProvider).value ?? [];
      expect(currentTxs.length, 1);
      expect(currentTxs.first.note, 'Ăn sáng cá nhân');

      // 2. Switch to Sổ Gia Đình ('default_family')
      container
          .read(ledgersActionControllerProvider.notifier)
          .switchLedger('default_family');
      await Future<void>.delayed(const Duration(milliseconds: 10));

      expect(container.read(activeLedgerIdProvider), 'default_family');

      // Transactions stream for active ledger should now be empty
      currentTxs = container.read(transactionsStreamProvider).value ?? [];
      expect(currentTxs, isEmpty);

      // Default Cash wallet for 'default_family' was auto-provisioned
      final familyAccounts = container.read(accountsStreamProvider).value ?? [];
      expect(familyAccounts.length, 1);
      expect(familyAccounts.first.ledgerId, 'default_family');
      expect(familyAccounts.first.id, 'default_cash_wallet_default_family');

      // 3. Add a transaction to Sổ Gia Đình
      final familyTx = await container
          .read(transactionsActionControllerProvider.notifier)
          .add(
            amount: 200000,
            currency: 'VND',
            type: TransactionType.expense,
            accountId: 'default_cash_wallet_default_family',
            categoryId: 'utilities',
            note: 'Tiền điện gia đình',
            date: DateTime.now(),
          );
      expect(familyTx.isSuccess, isTrue);
      expect(familyTx.valueOrNull!.ledgerId, 'default_family');
      await Future<void>.delayed(const Duration(milliseconds: 10));

      // Family ledger sees its transaction
      currentTxs = container.read(transactionsStreamProvider).value ?? [];
      expect(currentTxs.length, 1);
      expect(currentTxs.first.note, 'Tiền điện gia đình');

      // 4. Switch back to Sổ Cá Nhân
      container
          .read(ledgersActionControllerProvider.notifier)
          .switchLedger(LedgerBook.defaultPersonalId);
      await Future<void>.delayed(const Duration(milliseconds: 10));

      expect(container.read(activeLedgerIdProvider), LedgerBook.defaultPersonalId);

      // Personal ledger only sees the personal transaction!
      currentTxs = container.read(transactionsStreamProvider).value ?? [];
      expect(currentTxs.length, 1);
      expect(currentTxs.first.note, 'Ăn sáng cá nhân');

      final personalAccounts = container.read(accountsStreamProvider).value ?? [];
      expect(personalAccounts.length, 1);
      expect(personalAccounts.first.ledgerId, LedgerBook.defaultPersonalId);
    });

    test('isolates budgets between personal and family ledgers', () async {
      // Add budget in personal ledger
      final pBudget = await container
          .read(budgetsActionControllerProvider.notifier)
          .upsertBudget(
            amount: 2000000,
            currency: 'VND',
            monthStart: DateTime(2026, 11, 1),
            alertThreshold: 80,
          );
      expect(pBudget.isSuccess, isTrue);
      expect(pBudget.valueOrNull!.ledgerId, LedgerBook.defaultPersonalId);
      await Future<void>.delayed(const Duration(milliseconds: 10));

      var activeBudgets = container.read(budgetsStreamProvider).value ?? [];
      expect(activeBudgets.length, 1);
      expect(activeBudgets.first.amount, 2000000);

      // Switch to family ledger
      container
          .read(ledgersActionControllerProvider.notifier)
          .switchLedger('default_family');
      await Future<void>.delayed(const Duration(milliseconds: 10));

      // Family ledger should have 0 budgets
      activeBudgets = container.read(budgetsStreamProvider).value ?? [];
      expect(activeBudgets, isEmpty);

      // Add budget in family ledger
      final fBudget = await container
          .read(budgetsActionControllerProvider.notifier)
          .upsertBudget(
            amount: 10000000,
            currency: 'VND',
            monthStart: DateTime(2026, 11, 1),
            alertThreshold: 90,
          );
      expect(fBudget.isSuccess, isTrue);
      expect(fBudget.valueOrNull!.ledgerId, 'default_family');
      await Future<void>.delayed(const Duration(milliseconds: 10));

      activeBudgets = container.read(budgetsStreamProvider).value ?? [];
      expect(activeBudgets.length, 1);
      expect(activeBudgets.first.amount, 10000000);

      // Switch back to personal
      container
          .read(ledgersActionControllerProvider.notifier)
          .switchLedger(LedgerBook.defaultPersonalId);
      await Future<void>.delayed(const Duration(milliseconds: 10));

      activeBudgets = container.read(budgetsStreamProvider).value ?? [];
      expect(activeBudgets.length, 1);
      expect(activeBudgets.first.amount, 2000000);
    });
  });
}

