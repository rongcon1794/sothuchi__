import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:so_thu_chi/data/firebase/firebase_providers.dart';
import 'package:so_thu_chi/data/providers/repository_providers.dart';
import 'package:so_thu_chi/features/accounts/data/repositories/firestore_account_repository.dart';
import 'package:so_thu_chi/features/accounts/domain/entities/account.dart';
import 'package:so_thu_chi/features/auth/domain/entities/app_user.dart';
import 'package:so_thu_chi/features/auth/presentation/controllers/initial_setup_controller.dart';
import 'package:so_thu_chi/features/auth/presentation/screens/initial_setup_screen.dart';
import 'package:so_thu_chi/features/budgets/data/repositories/firestore_budget_repository.dart';
import 'package:so_thu_chi/features/categories/data/repositories/firestore_category_repository.dart';
import 'package:so_thu_chi/features/debts/data/repositories/firestore_debt_repository.dart';
import 'package:so_thu_chi/features/ledger/data/repositories/firestore_ledger_repository.dart';
import 'package:so_thu_chi/features/recurring/data/repositories/firestore_recurring_repository.dart';
import 'package:so_thu_chi/features/savings/data/repositories/firestore_savings_goal_repository.dart';
import 'package:so_thu_chi/features/settings/presentation/controllers/settings_controller.dart';
import 'package:so_thu_chi/features/transactions/data/repositories/firestore_transaction_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late SharedPreferences prefs;
  late InMemoryAccountRepository accRepo;
  late InMemoryCategoryRepository catRepo;
  late InMemoryTransactionRepository txRepo;
  late InMemoryLedgerRepository ledgerRepo;
  late InMemoryBudgetRepository budgetRepo;
  late InMemoryDebtRepository debtRepo;
  late InMemoryRecurringRepository recurringRepo;
  late InMemorySavingsGoalRepository savingsRepo;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    accRepo = InMemoryAccountRepository();
    catRepo = InMemoryCategoryRepository();
    txRepo = InMemoryTransactionRepository(accountRepo: accRepo);
    ledgerRepo = InMemoryLedgerRepository();
    budgetRepo = InMemoryBudgetRepository();
    debtRepo = InMemoryDebtRepository(accountRepo: accRepo, seedDemoData: false);
    recurringRepo = InMemoryRecurringRepository(transactionRepository: txRepo);
    savingsRepo = InMemorySavingsGoalRepository(transactionRepository: txRepo);
  });

  Widget buildTestWidget({
    AppUser? user,
    ProviderContainer? container,
  }) {
    const root = MaterialApp(
      home: InitialSetupScreen(),
    );

    if (container != null) {
      return UncontrolledProviderScope(
        container: container,
        child: root,
      );
    }

    return ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        accountRepositoryProvider.overrideWithValue(accRepo),
        categoryRepositoryProvider.overrideWithValue(catRepo),
        transactionRepositoryProvider.overrideWithValue(txRepo),
        ledgerRepositoryProvider.overrideWithValue(ledgerRepo),
        budgetRepositoryProvider.overrideWithValue(budgetRepo),
        debtRepositoryProvider.overrideWithValue(debtRepo),
        recurringRepositoryProvider.overrideWithValue(recurringRepo),
        savingsGoalRepositoryProvider.overrideWithValue(savingsRepo),
        currentUserProvider.overrideWithValue(
          user ??
              AppUser(
                uid: 'user_new_123',
                email: 'test@sothuchi.vn',
                displayName: 'Người Dùng Mới',
                createdAt: DateTime.now(),
                updatedAt: DateTime.now(),
              ),
        ),
      ],
      child: root,
    );
  }

  ProviderContainer createContainer({AppUser? user}) {
    return ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        accountRepositoryProvider.overrideWithValue(accRepo),
        categoryRepositoryProvider.overrideWithValue(catRepo),
        transactionRepositoryProvider.overrideWithValue(txRepo),
        ledgerRepositoryProvider.overrideWithValue(ledgerRepo),
        budgetRepositoryProvider.overrideWithValue(budgetRepo),
        debtRepositoryProvider.overrideWithValue(debtRepo),
        recurringRepositoryProvider.overrideWithValue(recurringRepo),
        savingsGoalRepositoryProvider.overrideWithValue(savingsRepo),
        currentUserProvider.overrideWithValue(
          user ??
              AppUser(
                uid: 'user_new_123',
                email: 'test@sothuchi.vn',
                displayName: 'Người Dùng Mới',
                createdAt: DateTime.now(),
                updatedAt: DateTime.now(),
              ),
        ),
      ],
    );
  }

  group('InitialSetupScreen Tests', () {
    testWidgets('renders all setup sections, presets, and actions', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      // Verify Header
      expect(find.text('Thiết lập ban đầu'), findsOneWidget);
      expect(find.text('Chào mừng bạn đến với Sổ Thu Chi!'), findsOneWidget);

      // Verify Quick Preset Card
      expect(find.text('Thiết lập đề xuất (1 chạm)'), findsOneWidget);
      expect(find.text('Áp dụng đề xuất & Bắt đầu ngay'), findsOneWidget);

      // Verify Section 1: Ledgers
      expect(find.text('Sổ thu chi đầu tiên'), findsOneWidget);
      expect(find.text('Sổ Cá Nhân'), findsWidgets);
      expect(find.text('Sổ Gia Đình'), findsWidgets);
      expect(find.text('Sổ Kinh Doanh'), findsWidgets);
      expect(find.text('Sổ Du Lịch / Dự Án'), findsWidgets);

      // Verify Section 2: Wallets
      expect(find.text('Các ví giao dịch ban đầu'), findsOneWidget);
      expect(find.text('Tiền mặt'), findsWidgets);
      expect(find.text('Tài khoản Ngân hàng'), findsWidgets);
      expect(find.text('Ví MoMo'), findsWidgets);
      expect(find.text('Sổ Tiết kiệm'), findsWidgets);

      // Verify Actions
      expect(find.text('Hoàn tất & Bắt đầu sử dụng'), findsOneWidget);
      expect(find.text('Bỏ qua & Sử dụng cấu hình cơ bản'), findsOneWidget);
    });

    testWidgets('switching ledger preset updates name textfield', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      // Ensure visible and tap Sổ Kinh Doanh chip
      final kinhDoanhFinder = find.text('Sổ Kinh Doanh').first;
      await tester.ensureVisible(kinhDoanhFinder);
      await tester.tap(kinhDoanhFinder);
      await tester.pumpAndSettle();

      final textFinder = find.byWidgetPredicate(
        (w) => w is TextField && w.controller?.text == 'Sổ Kinh Doanh',
      );
      expect(textFinder, findsOneWidget);
    });

    testWidgets('quick preset setup creates ledger, wallets, and completes setup', (tester) async {
      final container = createContainer();
      await tester.pumpWidget(buildTestWidget(container: container));
      await tester.pumpAndSettle();

      // Tap Quick Recommendation
      await tester.tap(find.text('Áp dụng đề xuất & Bắt đầu ngay'));
      await tester.pumpAndSettle();

      // Verify accounts created in repo
      final accounts = await accRepo.getAccounts();
      expect(accounts.any((a) => a.name == 'Tiền mặt' && a.balance == 500000), isTrue);
      expect(accounts.any((a) => a.name == 'Tài khoản Ngân hàng' && a.balance == 5000000), isTrue);

      // Verify default wallet saved
      final defaultWalletId = prefs.getString('default_wallet_id');
      expect(defaultWalletId, isNotNull);

      // Verify settings updated
      final settings = container.read(settingsControllerProvider).value;
      expect(settings?.initialSetupCompleted, isTrue);
    });

    testWidgets('skip action creates fallback cash wallet and marks complete', (tester) async {
      final container = createContainer();
      await tester.pumpWidget(buildTestWidget(container: container));
      await tester.pumpAndSettle();

      // Tap skip in appbar
      await tester.tap(find.text('Bỏ qua').first);
      await tester.pumpAndSettle();

      // Verify fallback cash wallet ensured
      final accounts = await accRepo.getAccounts();
      expect(accounts.isNotEmpty, isTrue);

      // Verify settings updated
      final settings = container.read(settingsControllerProvider).value;
      expect(settings?.initialSetupCompleted, isTrue);
    });

    test('checkAndRestoreIfExisting returns true and restores state for user with existing data', () async {
      final container = createContainer();
      await accRepo.createAccount(
        name: 'Ví Techcombank',
        type: AccountType.bank,
        initialBalance: 12000000,
        currency: 'VND',
        icon: 'bank',
        color: 0xFF007AFF,
      );

      final restored = await container
          .read(initialSetupControllerProvider.notifier)
          .checkAndRestoreIfExisting('existing_user_uid');

      expect(restored, isTrue);
      final settings = await container.read(settingsControllerProvider.future);
      expect(settings.initialSetupCompleted, isTrue);
      expect(settings.defaultWalletId, isNotNull);
    });

    test('checkAndRestoreIfExisting returns false for brand-new user without data', () async {
      final container = createContainer();
      final restored = await container
          .read(initialSetupControllerProvider.notifier)
          .checkAndRestoreIfExisting('brand_new_user_uid');

      expect(restored, isFalse);
      final settings = await container.read(settingsControllerProvider.future);
      expect(settings.initialSetupCompleted, isFalse);
    });
  });
}
