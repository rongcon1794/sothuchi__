import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:so_thu_chi/core/theme/app_theme.dart';
import 'package:so_thu_chi/data/firebase/firebase_providers.dart';
import 'package:so_thu_chi/data/providers/repository_providers.dart';
import 'package:so_thu_chi/features/accounts/data/repositories/firestore_account_repository.dart';
import 'package:so_thu_chi/features/accounts/domain/entities/account.dart';
import 'package:so_thu_chi/features/categories/data/repositories/firestore_category_repository.dart';
import 'package:so_thu_chi/features/recurring/data/repositories/firestore_recurring_repository.dart';
import 'package:so_thu_chi/features/recurring/domain/entities/recurring_transaction.dart';
import 'package:so_thu_chi/features/recurring/presentation/screens/recurring_transactions_screen.dart';
import 'package:so_thu_chi/features/transactions/data/repositories/firestore_transaction_repository.dart';
import 'package:so_thu_chi/features/transactions/domain/entities/transaction_entity.dart';
import 'package:so_thu_chi/l10n/app_localizations.dart';

void main() {
  group('Recurring Transactions Domain & Unit Tests', () {
    test('computeNextDate advances monthly, weekly, and yearly accurately', () {
      final now = DateTime(2026, 1, 31, 10, 0);
      final itemMonthly = RecurringTransaction(
        id: 'rec_1',
        title: 'Tiền thuê nhà',
        amount: 5000000,
        type: TransactionType.expense,
        interval: RecurringInterval.monthly,
        startDate: now,
        nextDueDate: now,
        accountId: 'acc_1',
        categoryId: 'cat_home',
        createdAt: now,
        updatedAt: now,
      );

      // Jan 31 -> Feb 28 (clamps to last day of Feb)
      final febDue = itemMonthly.computeNextDate(now);
      expect(febDue.month, 2);
      expect(febDue.day, 28);

      final itemWeekly = itemMonthly.copyWith(interval: RecurringInterval.weekly);
      final weekDue = itemWeekly.computeNextDate(now);
      expect(weekDue.difference(now).inDays, 7);

      final itemYearly = itemMonthly.copyWith(interval: RecurringInterval.yearly);
      final yearDue = itemYearly.computeNextDate(now);
      expect(yearDue.year, 2027);
      expect(yearDue.month, 1);
      expect(yearDue.day, 31);
    });

    test('InMemoryRecurringRepository create, pause, execute updates transaction store', () async {
      final accRepo = InMemoryAccountRepository();
      final txRepo = InMemoryTransactionRepository(accountRepo: accRepo);
      final recRepo = InMemoryRecurringRepository(transactionRepository: txRepo);

      final wallet = ((await accRepo.createAccount(
        name: 'Tiền mặt',
        type: AccountType.cash,
        initialBalance: 20000000,
        currency: 'VND',
        icon: 'cash',
        color: 0xFF00A86B,
      )) as dynamic).value as Account;

      final startDate = DateTime(2026, 11, 1);
      final item = RecurringTransaction(
        id: 'rec_netflix',
        title: 'Netflix Premium',
        amount: 260000,
        type: TransactionType.expense,
        interval: RecurringInterval.monthly,
        startDate: startDate,
        nextDueDate: startDate,
        accountId: wallet.id,
        categoryId: 'default_entertainment',
        createdAt: startDate,
        updatedAt: startDate,
      );

      await recRepo.createRecurring(item);

      // Execute recurring
      final execRes = await recRepo.executeRecurring(item.id);
      expect(execRes.isSuccess, isTrue);

      // Real transaction was created
      final txs = await txRepo.getTransactions();
      expect(txs.length, 1);
      expect(txs.first.amount, 260000);
      expect(txs.first.note, contains('Netflix Premium'));

      // Wallet balance was debited
      final accounts = await accRepo.getAccounts();
      expect(accounts.first.balance, 20000000 - 260000);
    });
  });

  group('RecurringTransactionsScreen Widget Tests', () {
    late InMemoryAccountRepository accRepo;
    late InMemoryCategoryRepository catRepo;
    late InMemoryTransactionRepository txRepo;
    late InMemoryRecurringRepository recRepo;
    late SharedPreferences prefs;

    setUp(() async {
      SharedPreferences.setMockInitialValues({
        'theme_mode': 'system',
        'locale_code': 'vi',
        'currency_code': 'VND',
        'onboarding_completed': true,
      });
      prefs = await SharedPreferences.getInstance();
      accRepo = InMemoryAccountRepository();
      catRepo = InMemoryCategoryRepository();
      txRepo = InMemoryTransactionRepository(accountRepo: accRepo);
      recRepo = InMemoryRecurringRepository(transactionRepository: txRepo);

      await catRepo.seedDefaultCategoriesIfNeeded();
      final wallet = ((await accRepo.createAccount(
        name: 'Ví chính',
        type: AccountType.cash,
        initialBalance: 10000000,
        currency: 'VND',
        icon: 'cash',
        color: 0xFF00A86B,
      )) as dynamic).value as Account;

      // Seed a due bill
      await recRepo.createRecurring(
        RecurringTransaction(
          id: 'rec_rent',
          title: 'Tiền thuê căn hộ',
          amount: 4500000,
          type: TransactionType.expense,
          interval: RecurringInterval.monthly,
          startDate: DateTime(2026, 11, 1),
          nextDueDate: DateTime(2026, 11, 1), // Due today/past
          accountId: wallet.id,
          categoryId: 'default_home',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );
    });

    Widget buildTestWidget() {
      return ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          accountRepositoryProvider.overrideWithValue(accRepo),
          categoryRepositoryProvider.overrideWithValue(catRepo),
          transactionRepositoryProvider.overrideWithValue(txRepo),
          recurringRepositoryProvider.overrideWithValue(recRepo),
        ],
        child: MaterialApp(
          locale: const Locale('vi'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          theme: AppTheme.light(),
          home: const RecurringTransactionsScreen(),
        ),
      );
    }

    testWidgets('renders screen with estimated monthly cost and due bills action button', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      // Screen title
      expect(find.text('Hóa Đơn & Định Kỳ'), findsOneWidget);

      // Due bill title
      expect(find.text('Tiền thuê căn hộ'), findsWidgets);

      // Action button "Ghi nhận đã thanh toán"
      expect(find.text('Ghi nhận đã thanh toán'), findsOneWidget);

      // Tap to mark as paid
      await tester.tap(find.text('Ghi nhận đã thanh toán'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Transaction was recorded and SnackBar shown
      expect(find.textContaining('Đã ghi nhận giao dịch: Tiền thuê căn hộ'), findsOneWidget);

      final txs = await txRepo.getTransactions();
      expect(txs.length, 1);
    });
  });
}
