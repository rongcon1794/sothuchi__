import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:so_thu_chi/core/errors/result.dart';
import 'package:so_thu_chi/l10n/app_localizations.dart';
import 'package:so_thu_chi/data/firebase/firebase_providers.dart';
import 'package:so_thu_chi/data/providers/repository_providers.dart';
import 'package:so_thu_chi/features/accounts/data/repositories/firestore_account_repository.dart';
import 'package:so_thu_chi/features/accounts/domain/entities/account.dart';
import 'package:so_thu_chi/features/accounts/presentation/controllers/accounts_controller.dart';
import 'package:so_thu_chi/features/auth/domain/entities/app_user.dart';
import 'package:so_thu_chi/features/auth/domain/repositories/auth_repository.dart';
import 'package:so_thu_chi/features/auth/presentation/controllers/auth_controller.dart';
import 'package:so_thu_chi/features/auth/presentation/controllers/initial_setup_controller.dart';
import 'package:so_thu_chi/features/auth/presentation/screens/initial_setup_screen.dart';
import 'package:so_thu_chi/features/budgets/data/repositories/firestore_budget_repository.dart';
import 'package:so_thu_chi/features/budgets/presentation/controllers/budgets_controller.dart';
import 'package:so_thu_chi/features/categories/data/repositories/firestore_category_repository.dart';
import 'package:so_thu_chi/features/debts/data/repositories/firestore_debt_repository.dart';
import 'package:so_thu_chi/features/ledger/data/repositories/firestore_ledger_repository.dart';
import 'package:so_thu_chi/features/ledger/domain/entities/ledger_book.dart';
import 'package:so_thu_chi/features/ledger/presentation/controllers/ledgers_controller.dart';
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
      locale: Locale('vi'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
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

  group('InitialSetupScreen Onboarding Flow Tests', () {
    testWidgets('renders Step 1 (Tạo ví tiền đầu tiên) with suggestions and preview', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      // Verify Step 1 elements
      expect(find.text('Bước 1 / 2 • Tạo ví tiền đầu tiên'), findsOneWidget);
      expect(find.text('Tạo ví tiền đầu tiên'), findsWidgets);
      expect(find.text('Gợi ý nhanh'), findsOneWidget);
      expect(find.text('Techcombank'), findsOneWidget);
      expect(find.text('MB Bank'), findsOneWidget);
      expect(find.text('Ví MoMo'), findsOneWidget);
      expect(find.text('Tiếp tục: Thiết lập ngân sách'), findsOneWidget);
    });

    testWidgets('tapping template chip updates wallet name', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Techcombank'));
      await tester.pumpAndSettle();

      final textFinder = find.byWidgetPredicate(
        (w) => w is TextField && w.controller?.text == 'Techcombank',
      );
      expect(textFinder, findsOneWidget);
    });

    testWidgets('completing step 1 transitions to Step 2 (Thiết lập ngân sách)', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      // Tap Next to step 2
      final nextFinder = find.text('Tiếp tục: Thiết lập ngân sách');
      await tester.ensureVisible(nextFinder);
      await tester.tap(nextFinder);
      await tester.pumpAndSettle();

      // Verify Step 2 elements
      expect(find.text('Bước 2 / 2 • Thiết lập ngân sách'), findsOneWidget);
      expect(find.text('Thiết lập ngân sách tháng'), findsOneWidget);
      expect(find.text('Kiểm soát chi tiêu thông minh'), findsOneWidget);
      expect(find.text('Hạn mức chi tiêu tháng này'), findsOneWidget);
      expect(find.text('Hoàn tất & Bắt đầu sử dụng'), findsOneWidget);
      expect(find.text('Để sau (Bỏ qua bước này)'), findsOneWidget);
    });

    testWidgets('completing step 2 creates wallet and budget', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final container = createContainer();
      await tester.pumpWidget(buildTestWidget(container: container));
      await tester.pumpAndSettle();

      // Go to Step 2
      final nextFinder = find.text('Tiếp tục: Thiết lập ngân sách');
      await tester.ensureVisible(nextFinder);
      await tester.tap(nextFinder);
      await tester.pumpAndSettle();

      // Tap Hoàn tất & Bắt đầu sử dụng
      final finishFinder = find.text('Hoàn tất & Bắt đầu sử dụng');
      await tester.ensureVisible(finishFinder);
      await tester.tap(finishFinder);
      await tester.pumpAndSettle();

      // Verify wallet created
      final accounts = await accRepo.getAccounts();
      expect(accounts.any((a) => a.name == 'Tiền mặt' && a.balance == 500000), isTrue);

      // Verify budget created
      final budgets = await budgetRepo.getBudgets();
      expect(budgets.any((b) => b.isOverall && b.amount == 5000000), isTrue);

      // Verify settings updated
      final settings = container.read(settingsControllerProvider).value;
      expect(settings?.initialSetupCompleted, isTrue);
    });

    testWidgets('skipping budget in step 2 creates wallet without budget', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final container = createContainer();
      await tester.pumpWidget(buildTestWidget(container: container));
      await tester.pumpAndSettle();

      // Go to Step 2
      final nextFinder = find.text('Tiếp tục: Thiết lập ngân sách');
      await tester.ensureVisible(nextFinder);
      await tester.tap(nextFinder);
      await tester.pumpAndSettle();

      // Tap Để sau (Bỏ qua bước này)
      final skipBudgetFinder = find.text('Để sau (Bỏ qua bước này)');
      await tester.ensureVisible(skipBudgetFinder);
      await tester.tap(skipBudgetFinder);
      await tester.pumpAndSettle();

      // Verify wallet created
      final accounts = await accRepo.getAccounts();
      expect(accounts.isNotEmpty, isTrue);

      // Verify no budget created
      final budgets = await budgetRepo.getBudgets();
      expect(budgets.isEmpty, isTrue);

      // Verify settings updated
      final settings = container.read(settingsControllerProvider).value;
      expect(settings?.initialSetupCompleted, isTrue);
    });

    testWidgets('skip in Step 1 appbar applies quick defaults and finishes', (tester) async {
      final container = createContainer();
      await tester.pumpWidget(buildTestWidget(container: container));
      await tester.pumpAndSettle();

      // Tap Bỏ qua in appbar
      await tester.tap(find.text('Bỏ qua'));
      await tester.pumpAndSettle();

      // Verify default accounts created
      final accounts = await accRepo.getAccounts();
      expect(accounts.any((a) => a.name == 'Tiền mặt' && a.balance == 500000), isTrue);

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

    test('checkAndRestoreIfExisting returns true for user with 0-balance cash wallet and no txs', () async {
      final container = createContainer();
      await accRepo.createAccount(
        name: 'Tiền mặt',
        type: AccountType.cash,
        initialBalance: 0,
        currency: 'VND',
        icon: 'cash',
        color: 0xFF00A86B,
      );

      final restored = await container
          .read(initialSetupControllerProvider.notifier)
          .checkAndRestoreIfExisting('existing_zero_balance_user');

      expect(restored, isTrue);
      final settings = await container.read(settingsControllerProvider.future);
      expect(settings.initialSetupCompleted, isTrue);
      expect(settings.defaultWalletId, isNotNull);

      // Verify no extra wallets were created
      final allAccs = await accRepo.getAccounts();
      expect(allAccs.length, 1);
    });

    test('selectLedger does not auto-create phantom default_cash_wallet', () async {
      final container = createContainer();
      final beforeAccs = await accRepo.getAccounts();
      expect(beforeAccs, isEmpty);

      container.read(activeLedgerIdProvider.notifier).selectLedger('custom_ledger_123');
      expect(container.read(activeLedgerIdProvider), 'custom_ledger_123');

      final afterAccs = await accRepo.getAccounts();
      expect(afterAccs, isEmpty);
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

    test('Firestore repositories: completing initial onboarding persists wallet & budget under active ledger', () async {
      final fakeFirestore = FakeFirebaseFirestore();
      const uid = 'cloud_user_first_time';
      final cloudLedgerRepo = FirestoreLedgerRepository(
        firestore: fakeFirestore,
        currentUserIdGetter: () => uid,
      );
      final cloudAccRepo = FirestoreAccountRepository(
        firestore: fakeFirestore,
        uid: uid,
      );
      final cloudBudgetRepo = FirestoreBudgetRepository(
        firestore: fakeFirestore,
        uid: uid,
      );
      final cloudCatRepo = FirestoreCategoryRepository(
        firestore: fakeFirestore,
        uid: uid,
      );
      final cloudTxRepo = FirestoreTransactionRepository(
        firestore: fakeFirestore,
        uid: uid,
      );

      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          ledgerRepositoryProvider.overrideWithValue(cloudLedgerRepo),
          accountRepositoryProvider.overrideWithValue(cloudAccRepo),
          budgetRepositoryProvider.overrideWithValue(cloudBudgetRepo),
          categoryRepositoryProvider.overrideWithValue(cloudCatRepo),
          transactionRepositoryProvider.overrideWithValue(cloudTxRepo),
          currentUserProvider.overrideWithValue(
            AppUser(
              uid: uid,
              email: 'cloud@sothuchi.vn',
              displayName: 'Cloud User',
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
            ),
          ),
        ],
      );
      addTearDown(container.dispose);

      await container.read(settingsControllerProvider.future);

      final res = await container
          .read(initialSetupControllerProvider.notifier)
          .completeInitialOnboarding(
            walletName: 'Ví Techcombank',
            walletType: AccountType.bank,
            initialBalance: 8500000,
            icon: 'bank',
            color: 0xFFE50914,
            currency: 'VND',
            monthlyBudgetAmount: 4500000,
            budgetAlertThreshold: 80,
            uid: uid,
          );

      expect(res.isSuccess, isTrue);

      // Keep listeners active (simulating HomeDashboardScreen's ref.watch in Riverpod 3)
      final ledgerSub = container.listen(ledgersStreamProvider, (_, _) {});
      final accSub = container.listen(rawAccountsStreamProvider, (_, _) {});
      final budgetSub = container.listen(rawBudgetsStreamProvider, (_, _) {});
      addTearDown(() {
        ledgerSub.close();
        accSub.close();
        budgetSub.close();
      });

      // Load ledgers stream & verify active ledger ID matches default_personal
      final ledgers = await container.read(ledgersStreamProvider.future);
      expect(ledgers.any((l) => l.id == LedgerBook.defaultPersonalId), isTrue);
      expect(container.read(activeLedgerIdProvider), LedgerBook.defaultPersonalId);

      // Load accounts & budgets streams and verify wallet and budget exist on active ledger
      await container.read(rawAccountsStreamProvider.future);
      await container.read(rawBudgetsStreamProvider.future);

      final activeAccounts = container.read(activeAccountsProvider);
      expect(activeAccounts, hasLength(1));
      expect(activeAccounts.first.name, 'Ví Techcombank');
      expect(activeAccounts.first.balance, 8500000);
      expect(container.read(totalNetBalanceProvider).minorUnits, 8500000);

      final monthBudgets = container.read(currentMonthBudgetProgressProvider);
      expect(monthBudgets, hasLength(1));
      expect(monthBudgets.first.budget.isOverall, isTrue);
      expect(monthBudgets.first.budget.amount, 4500000);
    });

    test('deleteAccountAndAllData resets initialSetupCompleted and defaultWalletId so user restarts setup from scratch', () async {
      final container = ProviderContainer(
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
          authRepositoryProvider.overrideWithValue(_ResetTestAuthRepository()),
          currentUserProvider.overrideWithValue(
            AppUser(
              uid: 'user_to_reset',
              email: 'reset@sothuchi.vn',
              displayName: 'Reset User',
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
            ),
          ),
        ],
      );
      addTearDown(container.dispose);

      await container.read(settingsControllerProvider.future);

      // First complete initial onboarding
      await container
          .read(initialSetupControllerProvider.notifier)
          .completeInitialOnboarding(
            walletName: 'Tiền mặt',
            walletType: AccountType.cash,
            initialBalance: 1000000,
            icon: 'cash',
            color: 0xFF00A86B,
            currency: 'VND',
            monthlyBudgetAmount: 3000000,
            uid: 'user_to_reset',
          );

      expect(
        container.read(settingsControllerProvider).value?.initialSetupCompleted,
        isTrue,
      );
      expect(
        container.read(settingsControllerProvider).value?.defaultWalletId,
        isNotNull,
      );

      // Now delete account and all data
      final delRes = await container
          .read(authActionControllerProvider.notifier)
          .deleteAccountAndAllData();
      expect(delRes.isSuccess, isTrue);

      final afterSettings = container.read(settingsControllerProvider).value;
      expect(afterSettings?.initialSetupCompleted, isFalse);
      expect(afterSettings?.defaultWalletId, isNull);
      expect(prefs.getBool('settings.initial_setup_completed'), isFalse);
    });
  });
}

class _ResetTestAuthRepository implements AuthRepository {
  @override
  bool get isCloudAuthConfigured => true;

  @override
  AppUser? get currentUser => null;

  @override
  Stream<AppUser?> watchAuthState() => Stream.value(null);

  @override
  Future<Result<AppUser>> signInWithGoogle() => throw UnimplementedError();

  @override
  Future<Result<AppUser>> signInOfflineDemo() => throw UnimplementedError();

  @override
  Future<Result<void>> signOut() async => const Success(null);

  @override
  Future<Result<void>> deleteAccountAndAllData() async => const Success(null);

  @override
  Future<Result<void>> updateProfilePreferences({
    String? defaultCurrency,
    String? locale,
    String? themeMode,
    int? accentColorIndex,
    String? defaultWalletId,
    bool? oledMode,
    bool? hideBalance,
    bool? initialSetupCompleted,
  }) async => const Success(null);
}
