import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:so_thu_chi/core/theme/app_theme.dart';
import 'package:so_thu_chi/core/widgets/apple_button.dart';
import 'package:so_thu_chi/data/firebase/firebase_providers.dart';
import 'package:so_thu_chi/data/providers/repository_providers.dart';
import 'package:so_thu_chi/features/accounts/data/repositories/firestore_account_repository.dart';
import 'package:so_thu_chi/features/accounts/domain/entities/account.dart';
import 'package:so_thu_chi/features/categories/data/repositories/firestore_category_repository.dart';
import 'package:so_thu_chi/features/transactions/data/repositories/firestore_transaction_repository.dart';
import 'package:so_thu_chi/features/transactions/domain/entities/transaction_entity.dart';
import 'package:so_thu_chi/features/transactions/presentation/screens/transaction_detail_screen.dart';
import 'package:so_thu_chi/l10n/app_localizations.dart';

void main() {
  group('TransactionDetailScreen 3-Tier View Tests', () {
    late InMemoryAccountRepository accRepo;
    late InMemoryCategoryRepository catRepo;
    late InMemoryTransactionRepository txRepo;
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

      await catRepo.seedDefaultCategoriesIfNeeded();
    });

    Widget buildTestWidget(String transactionId) {
      return ProviderScope(
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
          home: TransactionDetailScreen(transactionId: transactionId),
        ),
      );
    }

    testWidgets('displays all transaction details (Hero amount, category, wallet, note, tags)', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final wallet = ((await accRepo.createAccount(
        name: 'Ví tiền mặt',
        type: AccountType.cash,
        initialBalance: 5000000,
        currency: 'VND',
        icon: 'cash',
        color: 0xFF00A86B,
      )) as dynamic).value as Account;

      final tx = ((await txRepo.addTransaction(
        amount: 150000,
        currency: 'VND',
        type: TransactionType.expense,
        accountId: wallet.id,
        categoryId: 'default_food',
        note: 'Ăn tối cùng đồng nghiệp',
        date: DateTime(2026, 11, 6, 19, 30),
        tags: ['banbe', 'antoi'],
      )) as dynamic).value as TransactionEntity;

      await tester.pumpWidget(buildTestWidget(tx.id));
      await tester.pumpAndSettle();

      // Title & Hero amount
      expect(find.text('Chi tiết giao dịch'), findsOneWidget);
      expect(find.text('- 150.000 ₫'), findsOneWidget);
      expect(find.text('Chi tiêu'), findsOneWidget);

      // Note
      expect(find.text('Ăn tối cùng đồng nghiệp'), findsOneWidget);

      // Category & Wallet
      expect(find.text('Ăn uống'), findsOneWidget);
      expect(find.text('Ví tiền mặt'), findsOneWidget);

      // Tags
      expect(find.text('#banbe'), findsOneWidget);
      expect(find.text('#antoi'), findsOneWidget);

      // Buttons
      expect(find.text('Chỉnh sửa'), findsOneWidget);
      expect(find.text('Xóa'), findsOneWidget);
      expect(find.text('Sao chép thành giao dịch mới'), findsOneWidget);
    });

    testWidgets('displays transfer transaction with source and destination wallets', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final w1 = ((await accRepo.createAccount(
        name: 'Ví nguồn',
        type: AccountType.bank,
        initialBalance: 10000000,
        currency: 'VND',
        icon: 'bank',
        color: 0xFF007AFF,
      )) as dynamic).value as Account;

      final w2 = ((await accRepo.createAccount(
        name: 'Ví tiết kiệm',
        type: AccountType.cash,
        initialBalance: 2000000,
        currency: 'VND',
        icon: 'savings',
        color: 0xFFFF9500,
      )) as dynamic).value as Account;

      final tx = ((await txRepo.addTransaction(
        amount: 2000000,
        currency: 'VND',
        type: TransactionType.transfer,
        accountId: w1.id,
        toAccountId: w2.id,
        categoryId: 'default_other',
        note: 'Trích quỹ tiết kiệm',
        date: DateTime(2026, 11, 6, 10, 0),
      )) as dynamic).value as TransactionEntity;

      await tester.pumpWidget(buildTestWidget(tx.id));
      await tester.pumpAndSettle();

      expect(find.text('2.000.000 ₫'), findsOneWidget);
      expect(find.text('Chuyển khoản'), findsOneWidget);
      expect(find.text('Ví chuyển (nguồn)'), findsOneWidget);
      expect(find.text('Ví nguồn'), findsOneWidget);
      expect(find.text('Ví nhận (đích)'), findsOneWidget);
      expect(find.text('Ví tiết kiệm'), findsOneWidget);
    });

    testWidgets('tapping Xóa prompts CupertinoActionSheet and confirms deletion', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final wallet = ((await accRepo.createAccount(
        name: 'Ví test',
        type: AccountType.cash,
        initialBalance: 1000000,
        currency: 'VND',
        icon: 'cash',
        color: 0xFF00A86B,
      )) as dynamic).value as Account;

      final tx = ((await txRepo.addTransaction(
        amount: 50000,
        currency: 'VND',
        type: TransactionType.expense,
        accountId: wallet.id,
        categoryId: 'default_food',
        note: 'Trà đá',
        date: DateTime.now(),
      )) as dynamic).value as TransactionEntity;

      await tester.pumpWidget(buildTestWidget(tx.id));
      await tester.pumpAndSettle();

      // Tap Xóa button in primary action row
      final deleteBtnFinder = find.widgetWithText(AppleButton, 'Xóa');
      await tester.tap(deleteBtnFinder);
      await tester.pumpAndSettle();

      // ActionSheet appears
      expect(find.byType(CupertinoActionSheet), findsOneWidget);
      expect(find.text('Xóa giao dịch'), findsOneWidget);

      // Confirm delete in ActionSheet
      final actionSheetDeleteBtn = find.descendant(
        of: find.byType(CupertinoActionSheet),
        matching: find.text('Xóa'),
      );
      await tester.tap(actionSheetDeleteBtn);
      await tester.pumpAndSettle();

      // Verify transaction is deleted in repository
      final allTxs = await txRepo.watchTransactions().first;
      expect(allTxs.where((t) => t.id == tx.id), isEmpty);
    });
  });
}
