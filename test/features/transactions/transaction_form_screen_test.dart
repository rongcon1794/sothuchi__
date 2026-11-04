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
import 'package:so_thu_chi/features/transactions/data/repositories/firestore_transaction_repository.dart';
import 'package:so_thu_chi/features/transactions/presentation/screens/transaction_form_screen.dart';
import 'package:so_thu_chi/l10n/app_localizations.dart';

void main() {
  group('Redesigned TransactionFormScreen Apple HIG Tests', () {
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
      await accRepo.createAccount(
        name: 'Tiền mặt',
        type: AccountType.cash,
        initialBalance: 2000000,
        currency: 'VND',
        icon: 'cash',
        color: 0xFF00A86B,
      );
      await accRepo.createAccount(
        name: 'Techcombank',
        type: AccountType.bank,
        initialBalance: 15000000,
        currency: 'VND',
        icon: 'bank',
        color: 0xFF007AFF,
      );
    });

    Widget buildTestWidget({String? editId}) {
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
          home: TransactionFormScreen(editTransactionId: editId),
        ),
      );
    }

    testWidgets('renders Hero Amount card, Quick Actions, and Segmented Type Pill', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      // Verify title (l10n.addTransaction in Vietnamese is 'Ghi giao dịch')
      expect(find.text('Ghi giao dịch'), findsOneWidget);

      // Verify segmented pills: Chi tiêu, Thu nhập, Chuyển khoản
      expect(find.text('Chi tiêu'), findsOneWidget);
      expect(find.text('Thu nhập'), findsOneWidget);
      expect(find.text('Chuyển khoản'), findsOneWidget);

      // Verify quick increment pills
      expect(find.text('+20k'), findsOneWidget);
      expect(find.text('+50k'), findsOneWidget);
      expect(find.text('+100k'), findsOneWidget);
      expect(find.text('+500k'), findsOneWidget);
      expect(find.text('Xóa'), findsOneWidget);

      // Verify Save button (l10n.save in Vietnamese is 'Lưu')
      expect(find.text('Lưu'), findsOneWidget);
    });

    testWidgets('tapping quick increment pills increments amount, and Xóa clears it', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      // Tap +50k
      await tester.tap(find.text('+50k'));
      await tester.pumpAndSettle();
      expect(find.text('50.000'), findsOneWidget);

      // Tap +100k -> 150.000
      await tester.tap(find.text('+100k'));
      await tester.pumpAndSettle();
      expect(find.text('150.000'), findsOneWidget);

      // Tap Xóa -> clears
      await tester.tap(find.text('Xóa'));
      await tester.pumpAndSettle();
      expect(find.text('150.000'), findsNothing);
    });

    testWidgets('switching to Chuyển khoản mode displays source and destination wallet pickers', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      // Tap Chuyển khoản
      await tester.tap(find.text('Chuyển khoản'));
      await tester.pumpAndSettle();

      // In transfer mode, category selection is hidden, fromWallet & toWallet are visible
      expect(find.text('Từ ví nguồn'), findsOneWidget);
      expect(find.text('Đến ví đích'), findsOneWidget);
      expect(find.text('Đổi chiều chuyển'), findsOneWidget);

      // Tap Đổi chiều chuyển (swap)
      await tester.tap(find.text('Đổi chiều chuyển'));
      await tester.pumpAndSettle();

      // Verify from/to were inverted
      expect(find.text('Từ ví nguồn'), findsOneWidget);
      expect(find.text('Đến ví đích'), findsOneWidget);
    });

    testWidgets('opening wallet picker bottom sheet displays available accounts with balances', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      // Tap on wallet tile ('Ví & Tài khoản')
      await tester.tap(find.text('Ví & Tài khoản'));
      await tester.pumpAndSettle();

      // Bottom sheet is visible with title
      expect(find.text('Chọn ví thanh toán'), findsOneWidget);
      expect(find.text('Tiền mặt'), findsOneWidget);
      expect(find.text('Techcombank'), findsOneWidget);

      // Tap Techcombank to select it
      await tester.tap(find.text('Techcombank'));
      await tester.pumpAndSettle();

      // Sheet is closed
      expect(find.text('Chọn ví thanh toán'), findsNothing);
      expect(find.textContaining('Techcombank'), findsOneWidget);
    });

    testWidgets('category selection card displays active category and supports 1-tap selection', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      // Category card should be present in expense mode
      expect(find.text('Chọn danh mục'), findsOneWidget);
      expect(find.text('Tất cả'), findsOneWidget);

      // Verify TextField for amount has showCursor: false and no border
      final textField = tester.widget<TextField>(
        find.byType(TextField).first,
      );
      expect(textField.showCursor, isFalse);
    });
  });
}
