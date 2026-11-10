import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:so_thu_chi/core/errors/result.dart';
import 'package:so_thu_chi/core/theme/app_theme.dart';
import 'package:so_thu_chi/core/widgets/apple_kit.dart';
import 'package:so_thu_chi/data/firebase/firebase_providers.dart';
import 'package:so_thu_chi/data/providers/repository_providers.dart';
import 'package:so_thu_chi/features/accounts/data/repositories/firestore_account_repository.dart';
import 'package:so_thu_chi/features/accounts/domain/entities/account.dart';
import 'package:so_thu_chi/features/accounts/presentation/screens/account_detail_screen.dart';
import 'package:so_thu_chi/features/accounts/presentation/screens/accounts_screen.dart';
import 'package:so_thu_chi/features/accounts/presentation/widgets/wallet_form_sheet.dart';
import 'package:so_thu_chi/features/categories/data/repositories/firestore_category_repository.dart';
import 'package:so_thu_chi/features/categories/domain/entities/category.dart';
import 'package:so_thu_chi/features/categories/presentation/screens/category_detail_screen.dart';
import 'package:so_thu_chi/features/categories/presentation/screens/categories_screen.dart';
import 'package:so_thu_chi/features/categories/presentation/widgets/category_form_sheet.dart';
import 'package:so_thu_chi/features/transactions/data/repositories/firestore_transaction_repository.dart';
import 'package:so_thu_chi/features/transactions/presentation/widgets/dashboard_mini_cards.dart';
import 'package:so_thu_chi/features/transactions/presentation/widgets/dashboard_quick_action_bar.dart';
import 'package:so_thu_chi/l10n/app_localizations.dart';

void main() {
  group('FirestoreCategoryRepository & FirestoreAccountRepository', () {
    test('seeds 13 Vietnamese default categories idempotently and supports custom CRUD', () async {
      final firestore = FakeFirebaseFirestore();
      final repo = FirestoreCategoryRepository(
        firestore: firestore,
        uid: 'user_1',
      );

      final seed1 = await repo.seedDefaultCategoriesIfNeeded();
      expect(seed1.isSuccess, isTrue);

      final all1 = await repo.getCategories();
      expect(all1.length, 13);
      expect(all1.any((c) => c.name == 'Ăn uống'), isTrue);
      expect(all1.any((c) => c.name == 'Lương'), isTrue);

      // Calling seed again is idempotent
      await repo.seedDefaultCategoriesIfNeeded();
      expect((await repo.getCategories()).length, 13);

      // Custom category CRUD + soft delete
      final created = await repo.createCategory(
        name: 'Đầu tư chứng khoán',
        type: CategoryType.income,
        icon: 'gift',
        color: 0xFF0D7C66,
      );
      expect(created, isA<Success<Category>>());
      final custom = (created as Success<Category>).value;
      expect((await repo.getCategories(type: CategoryType.income)).length, 5);

      await repo.softDeleteCategory(custom.id);
      expect((await repo.getCategories(type: CategoryType.income)).length, 4);
    });

    test('creates wallets, archives, and atomically transfers between wallets', () async {
      final firestore = FakeFirebaseFirestore();
      final repo = FirestoreAccountRepository(
        firestore: firestore,
        uid: 'user_1',
      );

      final w1Res = await repo.createAccount(
        name: 'Tiền mặt',
        type: AccountType.cash,
        initialBalance: 1000000,
        currency: 'VND',
        icon: 'cash',
        color: 0xFF0D7C66,
      );
      final w2Res = await repo.createAccount(
        name: 'Vietcombank',
        type: AccountType.bank,
        initialBalance: 500000,
        currency: 'VND',
        icon: 'bank',
        color: 0xFF2563EB,
      );

      final w1 = (w1Res as Success<Account>).value;
      final w2 = (w2Res as Success<Account>).value;

      // Transfer 300,000 VND from Cash to Vietcombank
      final transferRes = await repo.transferBetweenAccounts(
        fromAccountId: w1.id,
        toAccountId: w2.id,
        amountMinorUnits: 300000,
        currency: 'VND',
        note: 'Nộp tiền vào tài khoản',
      );
      expect(transferRes.isSuccess, isTrue);

      final accounts = await repo.getAccounts();
      final updatedW1 = accounts.firstWhere((a) => a.id == w1.id);
      final updatedW2 = accounts.firstWhere((a) => a.id == w2.id);
      expect(updatedW1.balance, 700000);
      expect(updatedW2.balance, 800000);

      // Verify transfer transaction document was written with soft-delete fields
      final txDocs = await firestore
          .collection('users')
          .doc('user_1')
          .collection('transactions')
          .get();
      expect(txDocs.docs.length, 1);
      expect(txDocs.docs.first.data()['type'], 'transfer');
      expect(txDocs.docs.first.data()['amount'], 300000);
      expect(txDocs.docs.first.data().containsKey('deletedAt'), isTrue);

      // Archive second wallet
      await repo.setArchived(accountId: w2.id, archived: true);
      final activeOnly = await repo.getAccounts(includeArchived: false);
      expect(activeOnly.length, 1);
      expect(activeOnly.first.id, w1.id);
    });
  });

  group('AccountsScreen & CategoriesScreen widget smoke tests', () {
    testWidgets('renders seeded categories and wallets in Vietnamese', (tester) async {
      SharedPreferences.setMockInitialValues({'onboarding_completed': true});
      final prefs = await SharedPreferences.getInstance();
      final firestore = FakeFirebaseFirestore();
      final accRepo = FirestoreAccountRepository(firestore: firestore, uid: 'u1');
      final catRepo = FirestoreCategoryRepository(firestore: firestore, uid: 'u1');
      await accRepo.ensureDefaultWallet(currency: 'VND');
      await catRepo.seedDefaultCategoriesIfNeeded();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
            accountRepositoryProvider.overrideWithValue(accRepo),
            categoryRepositoryProvider.overrideWithValue(catRepo),
          ],
          child: MaterialApp(
            locale: const Locale('vi'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            theme: AppTheme.light(),
            home: const AccountsScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Tiền mặt'), findsAtLeastNWidgets(1));

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
            accountRepositoryProvider.overrideWithValue(accRepo),
            categoryRepositoryProvider.overrideWithValue(catRepo),
          ],
          child: MaterialApp(
            locale: const Locale('vi'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            theme: AppTheme.light(),
            home: const CategoriesScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Ăn uống'), findsOneWidget);
    });

    testWidgets('AccountDetailScreen renders wallet information, stats, and actions', (tester) async {
      SharedPreferences.setMockInitialValues({'onboarding_completed': true});
      final prefs = await SharedPreferences.getInstance();
      final firestore = FakeFirebaseFirestore();
      final accRepo = FirestoreAccountRepository(firestore: firestore, uid: 'u1');
      final catRepo = FirestoreCategoryRepository(firestore: firestore, uid: 'u1');
      final txRepo = FirestoreTransactionRepository(firestore: firestore, uid: 'u1');

      final wRes = await accRepo.createAccount(
        name: 'Ví Tiền Mặt',
        type: AccountType.cash,
        initialBalance: 2500000,
        currency: 'VND',
        icon: 'cash',
        color: 0xFF0D7C66,
      );
      final wallet = (wRes as Success<Account>).value;

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
            home: AccountDetailScreen(accountId: wallet.id),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Ví Tiền Mặt'), findsAtLeastNWidgets(1));
      expect(find.text('Biến động 14 ngày qua'), findsOneWidget);
      expect(find.text('Số dư ổn định 14 ngày'), findsOneWidget);
      expect(find.text('Chưa có giao dịch trên ví này'), findsOneWidget);
      expect(find.text('Thêm giao dịch'), findsAtLeastNWidgets(1));

      // Verify delete button is present in Quick Actions, and removed from bottom & header
      expect(find.text('Xóa ví "Ví Tiền Mặt"'), findsNothing);
      expect(find.byIcon(CupertinoIcons.trash), findsOneWidget);

      // Tap delete button in Quick Actions
      await tester.tap(find.byIcon(CupertinoIcons.trash));
      await tester.pumpAndSettle();

      // CupertinoActionSheet appears
      expect(find.byType(CupertinoActionSheet), findsOneWidget);

      // Tap Delete in ActionSheet
      await tester.tap(find.widgetWithText(CupertinoActionSheetAction, 'Xóa'));
      await tester.pumpAndSettle();

      // Verify wallet was soft deleted
      final accounts = await accRepo.getAccounts();
      expect(accounts.any((a) => a.id == wallet.id), isFalse);
    });

    testWidgets('DashboardMiniWalletCard renders accurate sparkline for wallet balance', (tester) async {
      final account = Account(
        id: 'acc1',
        name: 'Tiền mặt',
        type: AccountType.cash,
        balance: 5000000,
        currency: 'VND',
        icon: 'cash',
        color: 0xFF00A86B,
        archived: false,
        ledgerId: 'ledger1',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DashboardMiniWalletCard(
              account: account,
              locale: 'vi',
              hideBalance: false,
              onTap: () {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Tiền mặt'), findsOneWidget);
      expect(find.byType(CustomPaint), findsWidgets);
    });

    testWidgets('DashboardMiniWalletCard triggers onTap when tapped', (tester) async {
      var tapped = false;
      final account = Account(
        id: 'acc1',
        name: 'Tiền mặt',
        type: AccountType.cash,
        balance: 5000000,
        currency: 'VND',
        icon: 'cash',
        color: 0xFF00A86B,
        archived: false,
        ledgerId: 'ledger1',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DashboardMiniWalletCard(
              account: account,
              locale: 'vi',
              hideBalance: false,
              onTap: () => tapped = true,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Tiền mặt'));
      await tester.pumpAndSettle();

      expect(tapped, isTrue);
    });

    testWidgets('DashboardQuickActionBar renders and triggers wallet action', (tester) async {
      SharedPreferences.setMockInitialValues({'onboarding_completed': true});
      final prefs = await SharedPreferences.getInstance();
      final firestore = FakeFirebaseFirestore();
      final accRepo = FirestoreAccountRepository(firestore: firestore, uid: 'u1');
      await accRepo.createAccount(
        name: 'Ví Tiền Mặt',
        type: AccountType.cash,
        initialBalance: 1000000,
        currency: 'VND',
        icon: 'cash',
        color: 0xFF00A86B,
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
            accountRepositoryProvider.overrideWithValue(accRepo),
          ],
          child: MaterialApp(
            locale: const Locale('vi'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            theme: AppTheme.light(),
            home: const Scaffold(
              body: DashboardQuickActionBar(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Ví tiền'), findsOneWidget);
    });

    testWidgets('CategoryDetailScreen renders category information and actions', (tester) async {
      SharedPreferences.setMockInitialValues({'onboarding_completed': true});
      final prefs = await SharedPreferences.getInstance();
      final firestore = FakeFirebaseFirestore();
      final accRepo = FirestoreAccountRepository(firestore: firestore, uid: 'u1');
      final catRepo = FirestoreCategoryRepository(firestore: firestore, uid: 'u1');
      final txRepo = FirestoreTransactionRepository(firestore: firestore, uid: 'u1');

      await catRepo.seedDefaultCategoriesIfNeeded();
      final cats = await catRepo.getCategories();
      final cat = cats.firstWhere((c) => c.name == 'Ăn uống');

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
            home: CategoryDetailScreen(categoryId: cat.id),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Ăn uống'), findsAtLeastNWidgets(1));
      expect(find.text('Chưa có giao dịch'), findsOneWidget);
      expect(find.text('Thêm giao dịch'), findsAtLeastNWidgets(1));
    });

    testWidgets('AccountsScreen renders net balance hero card, filters and toggles eye', (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 1200));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      SharedPreferences.setMockInitialValues({'onboarding_completed': true});
      final prefs = await SharedPreferences.getInstance();
      final firestore = FakeFirebaseFirestore();
      final accRepo = FirestoreAccountRepository(firestore: firestore, uid: 'u1');
      await accRepo.ensureDefaultWallet(currency: 'VND');
      await accRepo.createAccount(
        name: 'Vietcombank',
        type: AccountType.bank,
        initialBalance: 500000000,
        currency: 'VND',
        icon: 'account_balance',
        color: 0xFF007AFF,
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
            accountRepositoryProvider.overrideWithValue(accRepo),
          ],
          child: MaterialApp(
            locale: const Locale('vi'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            theme: AppTheme.light(),
            home: const AccountsScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Net balance hero card
      expect(find.text('TỔNG TÀI SẢN RÒNG'), findsOneWidget);
      expect(find.text('Chuyển tiền giữa các ví'), findsAtLeastNWidgets(1));

      // Filters
      expect(find.text('Tất cả (2)'), findsOneWidget);
      expect(find.text('Tiền mặt (1)'), findsOneWidget);

      // Test eye toggle for masking balance
      final eyeIcon = find.byIcon(CupertinoIcons.eye);
      expect(eyeIcon, findsOneWidget);
      await tester.tap(eyeIcon);
      await tester.pumpAndSettle();

      expect(find.byIcon(CupertinoIcons.eye_slash), findsOneWidget);
    });

    testWidgets('WalletFormSheet renders live preview, templates and presets', (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 1400));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      SharedPreferences.setMockInitialValues({'onboarding_completed': true});
      final prefs = await SharedPreferences.getInstance();
      final firestore = FakeFirebaseFirestore();
      final accRepo = FirestoreAccountRepository(firestore: firestore, uid: 'u1');

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
            accountRepositoryProvider.overrideWithValue(accRepo),
          ],
          child: MaterialApp(
            locale: const Locale('vi'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            theme: AppTheme.light(),
            home: Scaffold(
              body: Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () => WalletFormSheet.show(context),
                  child: const Text('Open Sheet'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Open Sheet'));
      await tester.pumpAndSettle();

      // Check header and template carousel section
      expect(find.text('Thêm ví mới'), findsOneWidget);
      expect(find.text('MẪU TÀI KHOẢN & VÍ PHỔ BIẾN'), findsOneWidget);

      // Tap Vietcombank template
      expect(find.text('Vietcombank'), findsOneWidget);
      await tester.tap(find.text('Vietcombank'));
      await tester.pumpAndSettle();

      // Quick amount presets
      expect(find.text('+000'), findsOneWidget);
      expect(find.text('1 triệu'), findsOneWidget);

      // Tap 1 triệu preset
      await tester.tap(find.text('1 triệu'));
      await tester.pumpAndSettle();

      // Tap +000
      await tester.tap(find.text('+000'));
      await tester.pumpAndSettle();

      // Save button exists
      expect(find.text('Lưu'), findsOneWidget);
    });

    testWidgets('CategoriesScreen renders hero overview, filters by search, and switches tabs', (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 1400));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      SharedPreferences.setMockInitialValues({'onboarding_completed': true});
      final prefs = await SharedPreferences.getInstance();
      final firestore = FakeFirebaseFirestore();
      final accRepo = FirestoreAccountRepository(firestore: firestore, uid: 'u1');
      final catRepo = FirestoreCategoryRepository(firestore: firestore, uid: 'u1');
      await catRepo.seedDefaultCategoriesIfNeeded();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
            accountRepositoryProvider.overrideWithValue(accRepo),
            categoryRepositoryProvider.overrideWithValue(catRepo),
          ],
          child: MaterialApp(
            locale: const Locale('vi'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            theme: AppTheme.light(),
            home: const CategoriesScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Check Hero Overview
      expect(find.text('TỔNG QUAN PHÂN LOẠI'), findsOneWidget);
      expect(find.text('13 danh mục khả dụng'), findsOneWidget);
      expect(find.text('9 Khoản chi'), findsOneWidget);
      expect(find.text('4 Khoản thu'), findsOneWidget);

      // Default tab is Expense, check "Ăn uống" is visible
      expect(find.text('Ăn uống'), findsOneWidget);

      // Search for "Di chuyển"
      final searchField = find.byType(TextField);
      expect(searchField, findsOneWidget);
      await tester.enterText(searchField, 'Di chuyển');
      await tester.pumpAndSettle();

      expect(find.widgetWithText(ApplePressable, 'Di chuyển'), findsOneWidget);
      expect(find.text('Ăn uống'), findsNothing);

      // Clear search
      await tester.enterText(searchField, '');
      await tester.pumpAndSettle();
      expect(find.text('Ăn uống'), findsOneWidget);

      // Switch to Income tab
      await tester.tap(find.text('Thu nhập'));
      await tester.pumpAndSettle();

      expect(find.text('Lương'), findsOneWidget);
      expect(find.text('Thưởng'), findsOneWidget);
      expect(find.text('Ăn uống'), findsNothing);
    });

    testWidgets('CategoryFormSheet renders live preview, suggestions templates, and saves new category', (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 1400));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      SharedPreferences.setMockInitialValues({'onboarding_completed': true});
      final prefs = await SharedPreferences.getInstance();
      final firestore = FakeFirebaseFirestore();
      final accRepo = FirestoreAccountRepository(firestore: firestore, uid: 'u1');
      final catRepo = FirestoreCategoryRepository(firestore: firestore, uid: 'u1');

      Category? createdCategory;

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
            accountRepositoryProvider.overrideWithValue(accRepo),
            categoryRepositoryProvider.overrideWithValue(catRepo),
          ],
          child: MaterialApp(
            locale: const Locale('vi'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            theme: AppTheme.light(),
            home: Scaffold(
              body: Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () async {
                    createdCategory = await CategoryFormSheet.show(
                      context,
                      initialType: CategoryType.expense,
                    );
                  },
                  child: const Text('Open Category Sheet'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Open Category Sheet'));
      await tester.pumpAndSettle();

      // Check header and live preview
      expect(find.text('Thêm danh mục'), findsOneWidget);
      expect(find.text('BẢN XEM TRƯỚC DANH MỤC TRÊN DANH SÁCH'), findsOneWidget);
      expect(find.text('MẪU DANH MỤC GỢI Ý'), findsOneWidget);

      // Tap on "Cà phê & Đồ uống" template chip
      expect(find.text('Cà phê & Đồ uống'), findsOneWidget);
      await tester.tap(find.text('Cà phê & Đồ uống'));
      await tester.pumpAndSettle();

      // Live preview should now display "Cà phê & Đồ uống"
      expect(find.text('Cà phê & Đồ uống'), findsAtLeastNWidgets(1));

      // Tap Save button
      await tester.tap(find.text('Lưu'));
      await tester.pumpAndSettle();

      expect(createdCategory, isNotNull);
      expect(createdCategory?.name, 'Cà phê & Đồ uống');
      expect(createdCategory?.type, CategoryType.expense);
    });
  });
}

