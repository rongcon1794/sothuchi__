import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:so_thu_chi/core/responsive/apple_responsive.dart';
import 'package:so_thu_chi/core/theme/app_theme.dart';
import 'package:so_thu_chi/data/firebase/firebase_providers.dart';
import 'package:so_thu_chi/data/providers/repository_providers.dart';
import 'package:so_thu_chi/features/accounts/data/repositories/firestore_account_repository.dart';
import 'package:so_thu_chi/features/accounts/domain/entities/account.dart';
import 'package:so_thu_chi/features/budgets/data/repositories/firestore_budget_repository.dart';
import 'package:so_thu_chi/features/categories/data/repositories/firestore_category_repository.dart';
import 'package:so_thu_chi/features/reports/presentation/screens/reports_screen.dart';
import 'package:so_thu_chi/features/transactions/data/repositories/firestore_transaction_repository.dart';
import 'package:so_thu_chi/features/transactions/domain/entities/transaction_entity.dart';
import 'package:so_thu_chi/features/transactions/presentation/screens/home_dashboard_screen.dart';
import 'package:so_thu_chi/features/transactions/presentation/screens/transactions_screen.dart';
import 'package:so_thu_chi/l10n/app_localizations.dart';

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
              return const SizedBox();
            },
          ),
        );
      }

      // Compact (Phone portrait)
      await tester.pumpWidget(buildProbe(const Size(390, 844)));
      expect(recordedClass, AppleWindowSizeClass.compact);
      expect(recordedIsWide, isFalse);

      // Medium (Landscape phone: 600 .. 839 dp)
      await tester.pumpWidget(buildProbe(const Size(750, 390)));
      expect(recordedClass, AppleWindowSizeClass.medium);
      expect(recordedIsWide, isTrue);

      // Expanded (Tablet portrait/landscape: 840 .. 1199 dp)
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
  });
}
