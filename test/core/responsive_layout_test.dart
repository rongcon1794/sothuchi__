import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:so_thu_chi/app.dart';
import 'package:so_thu_chi/core/errors/result.dart';
import 'package:so_thu_chi/core/responsive/apple_responsive.dart';
import 'package:so_thu_chi/core/theme/app_theme.dart';
import 'package:so_thu_chi/data/firebase/firebase_providers.dart';
import 'package:so_thu_chi/data/providers/repository_providers.dart';
import 'package:so_thu_chi/features/accounts/data/repositories/firestore_account_repository.dart';
import 'package:so_thu_chi/features/accounts/domain/entities/account.dart';
import 'package:so_thu_chi/features/accounts/presentation/screens/accounts_screen.dart';
import 'package:so_thu_chi/features/auth/domain/entities/app_user.dart';
import 'package:so_thu_chi/features/auth/domain/repositories/auth_repository.dart';
import 'package:so_thu_chi/features/budgets/data/repositories/firestore_budget_repository.dart';
import 'package:so_thu_chi/features/budgets/presentation/screens/budgets_screen.dart';
import 'package:so_thu_chi/features/categories/data/repositories/firestore_category_repository.dart';
import 'package:so_thu_chi/features/categories/presentation/screens/categories_screen.dart';
import 'package:so_thu_chi/features/debts/data/repositories/firestore_debt_repository.dart';
import 'package:so_thu_chi/features/debts/presentation/screens/debts_screen.dart';
import 'package:so_thu_chi/features/reports/presentation/screens/reports_screen.dart';
import 'package:so_thu_chi/features/savings/data/repositories/firestore_savings_goal_repository.dart';
import 'package:so_thu_chi/features/savings/presentation/screens/savings_goals_screen.dart';
import 'package:so_thu_chi/features/transactions/data/repositories/firestore_transaction_repository.dart';
import 'package:so_thu_chi/features/transactions/domain/entities/transaction_entity.dart';
import 'package:so_thu_chi/features/transactions/presentation/screens/home_dashboard_screen.dart';
import 'package:so_thu_chi/features/transactions/presentation/screens/transactions_screen.dart';
import 'package:so_thu_chi/l10n/app_localizations.dart';

class _TestAuthRepo implements AuthRepository {
  final _u = AppUser(
    uid: 'u_resp_test',
    email: 'user@test.vn',
    displayName: 'Thử Nghiệm',
    createdAt: DateTime(2026, 1, 1),
    updatedAt: DateTime(2026, 1, 1),
  );

  @override
  bool get isCloudAuthConfigured => true;

  @override
  AppUser? get currentUser => _u;

  @override
  Stream<AppUser?> watchAuthState() => Stream.value(_u);

  @override
  Future<Result<AppUser>> signInWithGoogle() async => Success(_u);

  @override
  Future<Result<AppUser>> signInOfflineDemo() async => Success(_u);

  @override
  Future<Result<void>> signOut() async => const Success(null);

  @override
  Future<Result<void>> deleteAccountAndAllData() async => const Success(null);

  @override
  Future<Result<void>> updateProfilePreferences({String? defaultCurrency, String? locale}) async => const Success(null);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AppleResponsive Window Size Class & Extensions', () {
    testWidgets('classifies window widths into AppleWindowSizeClass correctly', (tester) async {
      late AppleWindowSizeClass recordedClass;
      late bool recordedIsWide;

      Widget buildProbe(Size size) {
        return MediaQuery(
          data: MediaQueryData(size: size),
          child: Builder(
            builder: (context) {
              recordedClass = context.windowSizeClass;
              recordedIsWide = context.isWideScreen;
              return const SizedBox.shrink();
            },
          ),
        );
      }

      // Compact (Phone portrait)
      await tester.pumpWidget(buildProbe(const Size(390, 844)));
      expect(recordedClass, AppleWindowSizeClass.compact);
      expect(recordedIsWide, isFalse);

      // Medium (Phone landscape / Foldable)
      await tester.pumpWidget(buildProbe(const Size(844, 390)));
      expect(recordedClass, AppleWindowSizeClass.expanded);
      expect(recordedIsWide, isTrue);

      // Expanded (Tablet portrait/landscape)
      await tester.pumpWidget(buildProbe(const Size(1024, 768)));
      expect(recordedClass, AppleWindowSizeClass.expanded);
      expect(recordedIsWide, isTrue);

      // Large (Desktop / large tablet)
      await tester.pumpWidget(buildProbe(const Size(1366, 900)));
      expect(recordedClass, AppleWindowSizeClass.large);
      expect(recordedIsWide, isTrue);
    });
  });

  group('Responsive Layout: Landscape Phone & Tablet Grid Verification', () {
    late SharedPreferences prefs;
    late FirestoreAccountRepository accRepo;
    late FirestoreCategoryRepository catRepo;
    late FirestoreTransactionRepository txRepo;
    late FirestoreBudgetRepository budgetRepo;
    late FirestoreDebtRepository debtRepo;
    late FirestoreSavingsGoalRepository savingsGoalRepo;

    setUp(() async {
      SharedPreferences.setMockInitialValues({
        'settings.onboarding_completed': true,
      });
      FlutterSecureStorage.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();

      final firestore = FakeFirebaseFirestore();
      const uid = 'u_resp_test';
      accRepo = FirestoreAccountRepository(firestore: firestore, uid: uid);
      catRepo = FirestoreCategoryRepository(firestore: firestore, uid: uid);
      txRepo = FirestoreTransactionRepository(firestore: firestore, uid: uid);
      budgetRepo = FirestoreBudgetRepository(firestore: firestore, uid: uid);
      debtRepo = FirestoreDebtRepository(firestore: firestore, uid: uid);
      savingsGoalRepo = FirestoreSavingsGoalRepository(
        firestore: firestore,
        currentUserIdGetter: () => uid,
        transactionRepository: txRepo,
      );

      await catRepo.seedDefaultCategoriesIfNeeded();
      final createdWallet = await accRepo.createAccount(
        name: 'Ví Tiền Mặt',
        type: AccountType.cash,
        initialBalance: 25000000,
        currency: 'VND',
        icon: 'wallet',
        color: 0xFF0D7C66,
      );
      final walletId = (createdWallet as dynamic).value.id as String;

      await txRepo.addTransaction(
        amount: 1500000,
        currency: 'VND',
        type: TransactionType.expense,
        accountId: walletId,
        categoryId: 'food_dining',
        note: 'Tiệc tối gia đình',
        date: DateTime.now(),
      );
      await txRepo.addTransaction(
        amount: 8000000,
        currency: 'VND',
        type: TransactionType.income,
        accountId: walletId,
        categoryId: 'salary',
        note: 'Thưởng quý',
        date: DateTime.now(),
      );
    });

    Widget buildAppWithScreen({
      required Widget screen,
      required Size size,
    }) {
      return ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          accountRepositoryProvider.overrideWithValue(accRepo),
          categoryRepositoryProvider.overrideWithValue(catRepo),
          transactionRepositoryProvider.overrideWithValue(txRepo),
          budgetRepositoryProvider.overrideWithValue(budgetRepo),
          debtRepositoryProvider.overrideWithValue(debtRepo),
          savingsGoalRepositoryProvider.overrideWithValue(savingsGoalRepo),
        ],
        child: MediaQuery(
          data: MediaQueryData(size: size),
          child: MaterialApp(
            locale: const Locale('vi'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            theme: AppTheme.light(),
            home: screen,
          ),
        ),
      );
    }

    testWidgets('HomeDashboardScreen renders 2-column Grid without overflow on Phone Landscape (844x390)', (tester) async {
      tester.view.physicalSize = const Size(844, 390);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        buildAppWithScreen(
          screen: const HomeDashboardScreen(),
          size: const Size(844, 390),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byType(HomeDashboardScreen), findsOneWidget);
    });

    testWidgets('HomeDashboardScreen renders 2-column Grid without overflow on Tablet (1024x768)', (tester) async {
      tester.view.physicalSize = const Size(1024, 768);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        buildAppWithScreen(
          screen: const HomeDashboardScreen(),
          size: const Size(1024, 768),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byType(HomeDashboardScreen), findsOneWidget);
    });

    testWidgets('ReportsScreen renders 2-column layout without overflow on Tablet (1024x768)', (tester) async {
      tester.view.physicalSize = const Size(1024, 768);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        buildAppWithScreen(
          screen: const ReportsScreen(),
          size: const Size(1024, 768),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byType(ReportsScreen), findsOneWidget);
    });

    testWidgets('TransactionsScreen renders cleanly on Phone Landscape and Tablet', (tester) async {
      tester.view.physicalSize = const Size(844, 390);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        buildAppWithScreen(
          screen: const TransactionsScreen(),
          size: const Size(844, 390),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byType(TransactionsScreen), findsOneWidget);
    });

    testWidgets('AppShellScaffold renders 42dp non-obscured BottomBar with all 5 items on Phone Landscape', (tester) async {
      tester.view.physicalSize = const Size(844, 390);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final authRepo = _TestAuthRepo();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
            firebaseBootstrapStateProvider.overrideWithValue(
              const FirebaseBootstrapState.configured(),
            ),
            authRepositoryProvider.overrideWithValue(authRepo),
            accountRepositoryProvider.overrideWithValue(accRepo),
            categoryRepositoryProvider.overrideWithValue(catRepo),
            transactionRepositoryProvider.overrideWithValue(txRepo),
            budgetRepositoryProvider.overrideWithValue(budgetRepo),
          ],
          child: const MediaQuery(
            data: MediaQueryData(
              size: Size(844, 390),
              padding: EdgeInsets.fromLTRB(44, 0, 44, 21),
              viewPadding: EdgeInsets.fromLTRB(44, 0, 44, 21),
            ),
            child: SoThuChiApp(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);

      final homeRect = tester.getRect(find.byType(HomeDashboardScreen));
      final navBarRect = tester.getRect(find.byType(ClipRect).last);
      expect(homeRect.height, greaterThan(200));
      expect(navBarRect.top, greaterThanOrEqualTo(homeRect.bottom - 1.0));

      // Verify all 5 destinations are present in bottombar
      final bottomBarFinder = find.byType(ClipRect).last;
      expect(find.descendant(of: bottomBarFinder, matching: find.text('Tổng quan')), findsOneWidget);
      expect(find.descendant(of: bottomBarFinder, matching: find.text('Giao dịch')), findsOneWidget);
      expect(find.descendant(of: bottomBarFinder, matching: find.text('Ngân sách')), findsOneWidget);
      expect(find.descendant(of: bottomBarFinder, matching: find.text('Báo cáo')), findsOneWidget);
      expect(find.descendant(of: bottomBarFinder, matching: find.text('Cài đặt')), findsOneWidget);

      // Tap 'Giao dịch' tab
      await tester.tap(find.descendant(of: bottomBarFinder, matching: find.text('Giao dịch')));
      await tester.pumpAndSettle();
      expect(find.byType(TransactionsScreen), findsOneWidget);

      // Tap 'Báo cáo' tab
      await tester.tap(find.descendant(of: bottomBarFinder, matching: find.text('Báo cáo')));
      await tester.pumpAndSettle();
      expect(find.byType(ReportsScreen), findsOneWidget);
    });

    testWidgets('AppShellScaffold on wide landscape (1024x502) does not collapse body to white screen', (tester) async {
      tester.view.physicalSize = const Size(1024, 502);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final authRepo = _TestAuthRepo();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
            firebaseBootstrapStateProvider.overrideWithValue(
              const FirebaseBootstrapState.configured(),
            ),
            authRepositoryProvider.overrideWithValue(authRepo),
            accountRepositoryProvider.overrideWithValue(accRepo),
            categoryRepositoryProvider.overrideWithValue(catRepo),
            transactionRepositoryProvider.overrideWithValue(txRepo),
            budgetRepositoryProvider.overrideWithValue(budgetRepo),
          ],
          child: const MediaQuery(
            data: MediaQueryData(
              size: Size(1024, 502),
            ),
            child: SoThuChiApp(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);

      final homeRect = tester.getRect(find.byType(HomeDashboardScreen));
      final navBarRect = tester.getRect(find.byType(ClipRect).last);

      // Verify body is visible and takes vast majority of screen
      expect(homeRect.height, greaterThan(400));
      // Verify bottom bar is docked at bottom, height is exactly navBarHeight (42dp)
      expect(navBarRect.height, closeTo(42.0, 1.0));
      expect(navBarRect.bottom, equals(502.0));
      expect(homeRect.bottom, equals(navBarRect.top));
    });

    testWidgets('AccountsScreen renders 2-column layout without overflow on Landscape Phone and Tablet', (tester) async {
      tester.view.physicalSize = const Size(844, 390);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        buildAppWithScreen(
          screen: const AccountsScreen(),
          size: const Size(844, 390),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.byType(AccountsScreen), findsOneWidget);

      // Verify on tablet
      tester.view.physicalSize = const Size(1024, 768);
      await tester.pumpWidget(
        buildAppWithScreen(
          screen: const AccountsScreen(),
          size: const Size(1024, 768),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.byType(AccountsScreen), findsOneWidget);
    });

    testWidgets('BudgetsScreen renders 2-column layout without overflow on Landscape Phone and Tablet', (tester) async {
      tester.view.physicalSize = const Size(844, 390);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        buildAppWithScreen(
          screen: const BudgetsScreen(),
          size: const Size(844, 390),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.byType(BudgetsScreen), findsOneWidget);

      // Verify on tablet
      tester.view.physicalSize = const Size(1024, 768);
      await tester.pumpWidget(
        buildAppWithScreen(
          screen: const BudgetsScreen(),
          size: const Size(1024, 768),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.byType(BudgetsScreen), findsOneWidget);
    });

    testWidgets('CategoriesScreen renders adaptive Grid without overflow on Landscape Phone and Tablet', (tester) async {
      tester.view.physicalSize = const Size(844, 390);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        buildAppWithScreen(
          screen: const CategoriesScreen(),
          size: const Size(844, 390),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.byType(CategoriesScreen), findsOneWidget);

      // Verify on tablet
      tester.view.physicalSize = const Size(1024, 768);
      await tester.pumpWidget(
        buildAppWithScreen(
          screen: const CategoriesScreen(),
          size: const Size(1024, 768),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.byType(CategoriesScreen), findsOneWidget);
    });

    testWidgets('DebtsScreen renders 2-column layout without overflow on Landscape Phone and Tablet', (tester) async {
      tester.view.physicalSize = const Size(844, 390);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        buildAppWithScreen(
          screen: const DebtsScreen(),
          size: const Size(844, 390),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.byType(DebtsScreen), findsOneWidget);

      // Verify on tablet
      tester.view.physicalSize = const Size(1024, 768);
      await tester.pumpWidget(
        buildAppWithScreen(
          screen: const DebtsScreen(),
          size: const Size(1024, 768),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.byType(DebtsScreen), findsOneWidget);
    });

    testWidgets('SavingsGoalsScreen renders 2-column layout without overflow on Landscape Phone and Tablet', (tester) async {
      tester.view.physicalSize = const Size(844, 390);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        buildAppWithScreen(
          screen: const SavingsGoalsScreen(),
          size: const Size(844, 390),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.byType(SavingsGoalsScreen), findsOneWidget);

      // Verify on tablet
      tester.view.physicalSize = const Size(1024, 768);
      await tester.pumpWidget(
        buildAppWithScreen(
          screen: const SavingsGoalsScreen(),
          size: const Size(1024, 768),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.byType(SavingsGoalsScreen), findsOneWidget);
    });
  });
}
