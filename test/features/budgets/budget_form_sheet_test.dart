import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:so_thu_chi/core/theme/app_theme.dart';
import 'package:so_thu_chi/data/firebase/firebase_providers.dart';
import 'package:so_thu_chi/data/providers/repository_providers.dart';
import 'package:so_thu_chi/features/accounts/data/repositories/firestore_account_repository.dart';
import 'package:so_thu_chi/features/budgets/data/repositories/firestore_budget_repository.dart';
import 'package:so_thu_chi/features/budgets/presentation/widgets/budget_form_sheet.dart';
import 'package:so_thu_chi/features/categories/data/repositories/firestore_category_repository.dart';
import 'package:so_thu_chi/features/transactions/data/repositories/firestore_transaction_repository.dart';
import 'package:so_thu_chi/l10n/app_localizations.dart';

void main() {
  group('Redesigned BudgetFormBottomSheet Apple HIG Tests', () {
    late InMemoryAccountRepository accRepo;
    late InMemoryCategoryRepository catRepo;
    late InMemoryTransactionRepository txRepo;
    late InMemoryBudgetRepository budgetRepo;
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
      budgetRepo = InMemoryBudgetRepository();

      await catRepo.seedDefaultCategoriesIfNeeded();
    });

    Widget buildTestWidget({DateTime? monthStart}) {
      final targetMonth = monthStart ?? DateTime(2026, 11, 1);
      return ProviderScope(
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
          home: Scaffold(
            body: BudgetFormBottomSheet(monthStart: targetMonth),
          ),
        ),
      );
    }

    testWidgets('renders Hero Amount card, quick presets, and month subtitle', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      // Title & Month subtitle
      expect(find.text('Thiết lập ngân sách'), findsOneWidget);
      expect(find.text('Áp dụng cho tháng 11/2026'), findsOneWidget);

      // Hero Amount label & presets
      expect(find.text('HẠN MỨC THÁNG'), findsOneWidget);
      expect(find.text('1 triệu'), findsOneWidget);
      expect(find.text('2 triệu'), findsOneWidget);
      expect(find.text('5 triệu'), findsOneWidget);
      expect(find.text('10 triệu'), findsOneWidget);
      expect(find.text('20 triệu'), findsOneWidget);

      // Scope switch
      expect(find.text('Tổng chi tiêu'), findsOneWidget);
      expect(find.text('Theo danh mục'), findsOneWidget);
    });

    testWidgets('tapping quick preset amount updates amount field and live buffer calculation', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      // Tap '10 triệu'
      await tester.tap(find.text('10 triệu'));
      await tester.pumpAndSettle();

      // Amount field text is 10.000.000
      expect(find.text('10.000.000'), findsOneWidget);

      // Live threshold calculation card appears (80% of 10tr = 8tr, buffer = 2tr)
      expect(find.text('Cảnh báo khi chi đạt:'), findsOneWidget);
      expect(find.text('8.000.000 ₫'), findsOneWidget);
      expect(find.text('Khoảng đệm an toàn:'), findsOneWidget);
      expect(find.text('2.000.000 ₫'), findsOneWidget);
    });

    testWidgets('switching to Theo danh mục displays category carousel and allows selection', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      // Tap 'Theo danh mục'
      await tester.tap(find.text('Theo danh mục'));
      await tester.pumpAndSettle();

      // Category items appear
      expect(find.text('Ăn uống'), findsOneWidget);

      // Tap Ăn uống
      await tester.tap(find.text('Ăn uống'));
      await tester.pumpAndSettle();
    });

    testWidgets('adjusting alert threshold updates threshold badge and live calculation', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      // Set amount 10.000.000
      await tester.tap(find.text('10 triệu'));
      await tester.pumpAndSettle();

      // Tap 90% preset chip
      await tester.tap(find.text('90%'));
      await tester.pumpAndSettle();

      // 90% of 10tr = 9.000.000, buffer = 1.000.000
      expect(find.text('9.000.000 ₫'), findsOneWidget);
      expect(find.text('1.000.000 ₫'), findsOneWidget);
    });

    testWidgets('saves budget properly and closes sheet', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      // Tap 5 triệu
      await tester.tap(find.text('5 triệu'));
      await tester.pumpAndSettle();

      // Tap Lưu
      await tester.tap(find.text('Lưu'));
      await tester.pumpAndSettle();

      // Verify budget is saved in repository
      final budgets = await budgetRepo.getBudgets();
      expect(budgets.length, 1);
      expect(budgets.first.amount, 5000000);
      expect(budgets.first.alertThreshold, 80);
      expect(budgets.first.categoryId, isNull);
    });
  });
}
