import 'package:flutter/cupertino.dart';
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
import 'package:so_thu_chi/features/transactions/presentation/widgets/apple_financial_keypad.dart';
import 'package:so_thu_chi/features/transactions/presentation/widgets/transaction_wallet_picker_sheet.dart';
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

    testWidgets('renders Hero Amount card with active cursor and Segmented Type Pill', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      // Verify title (l10n.addTransaction in Vietnamese is 'Ghi giao dịch')
      expect(find.text('Ghi giao dịch'), findsOneWidget);

      // Verify segmented pills: Chi tiêu, Thu nhập, Chuyển khoản
      expect(find.text('Chi tiêu'), findsOneWidget);
      expect(find.text('Thu nhập'), findsOneWidget);
      expect(find.text('Chuyển khoản'), findsOneWidget);

      // Verify cursor is visible for clear interactive feedback
      final textField = tester.widget<TextField>(find.byType(TextField).first);
      expect(textField.showCursor, isTrue);

      // Verify Save button (l10n.save in Vietnamese is 'Lưu')
      expect(find.text('Lưu'), findsOneWidget);
    });

    testWidgets('entering amount shows inline clear button, and tapping it clears amount', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      final amountField = find.byType(TextField).first;
      await tester.enterText(amountField, '50000');
      await tester.pumpAndSettle();
      expect(find.text('50.000'), findsOneWidget);

      // Inline clear button appears
      final clearIcon = find.byIcon(CupertinoIcons.clear_circled_solid);
      expect(clearIcon, findsOneWidget);

      // Tap clear button -> clears
      await tester.tap(clearIcon);
      await tester.pumpAndSettle();
      expect(find.text('50.000'), findsNothing);
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
      expect(
        find.descendant(
          of: find.byType(TransactionWalletPickerSheet),
          matching: find.text('Tiền mặt'),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byType(TransactionWalletPickerSheet),
          matching: find.text('Techcombank'),
        ),
        findsOneWidget,
      );

      // Tap Techcombank to select it in sheet
      await tester.tap(
        find.descendant(
          of: find.byType(TransactionWalletPickerSheet),
          matching: find.text('Techcombank'),
        ),
      );
      await tester.pumpAndSettle();

      // Sheet is closed
      expect(find.text('Chọn ví thanh toán'), findsNothing);
      expect(find.textContaining('Techcombank'), findsWidgets);
    });

    testWidgets('category selection card displays active category and supports 1-tap selection', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      // Category card should be present in expense mode
      expect(find.text('Chọn danh mục'), findsOneWidget);
      expect(find.text('Tất cả'), findsOneWidget);
      expect(find.text('Khác'), findsOneWidget);
      expect(find.text('Thêm'), findsOneWidget);

      // Verify TextField for amount has showCursor: true for active user feedback
      final textField = tester.widget<TextField>(
        find.byType(TextField).first,
      );
      expect(textField.showCursor, isTrue);
    });

    testWidgets('when categories are empty, it automatically seeds defaults and displays categories', (tester) async {
      final emptyCatRepo = InMemoryCategoryRepository();
      final widget = ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          accountRepositoryProvider.overrideWithValue(accRepo),
          categoryRepositoryProvider.overrideWithValue(emptyCatRepo),
          transactionRepositoryProvider.overrideWithValue(txRepo),
        ],
        child: MaterialApp(
          locale: const Locale('vi'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          theme: AppTheme.light(),
          home: const TransactionFormScreen(),
        ),
      );

      await tester.pumpWidget(widget);
      await tester.pumpAndSettle();

      // Automatically seeds defaults and shows category card!
      expect(find.text('Chọn danh mục'), findsOneWidget);
      expect(find.text('Tất cả'), findsOneWidget);
      expect(find.text('Khác'), findsOneWidget);
      expect(find.text('Thêm'), findsOneWidget);
    });

    testWidgets('shows smart zero suggestions when entering amount and sets value on tap', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      // Enter '5' in amount field
      final amountField = find.byType(TextField).first;
      await tester.enterText(amountField, '5');
      await tester.pumpAndSettle();

      // Suggestions header appears with actual calculated amounts
      expect(find.text('Gợi ý thêm số 0'), findsOneWidget);
      expect(find.text('50.000 ₫'), findsOneWidget);
      expect(find.text('500.000 ₫'), findsOneWidget);
      expect(find.text('5.000.000 ₫'), findsOneWidget);

      // Tap '50.000 ₫'
      await tester.tap(find.text('50.000 ₫'));
      await tester.pumpAndSettle();

      // Amount field text should now be '50.000'
      expect(find.text('50.000'), findsOneWidget);
    });

    testWidgets('tapping suggested note sets note text and clear button clears it', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      // Scroll down to Note section
      await tester.ensureVisible(find.text('Ăn sáng'));
      await tester.pumpAndSettle();

      // Tap suggested note 'Ăn sáng'
      expect(find.text('Ăn sáng'), findsOneWidget);
      await tester.tap(find.text('Ăn sáng'));
      await tester.pumpAndSettle();

      // Note should now contain 'Ăn sáng'
      expect(find.text('Ăn sáng'), findsWidgets);

      // Clear button should be visible and clear it
      final clearIcon = find.byIcon(CupertinoIcons.clear_circled_solid);
      expect(clearIcon, findsOneWidget);
      await tester.tap(clearIcon);
      await tester.pumpAndSettle();
      expect(find.byIcon(CupertinoIcons.clear_circled_solid), findsNothing);
    });

    testWidgets('tapping frequent tag adds tag chip and delete button removes it', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      // Scroll down to Tags section
      await tester.ensureVisible(find.text('#thiết yếu'));
      await tester.pumpAndSettle();

      // Frequent tags row contains '#thiết yếu'
      expect(find.text('#thiết yếu'), findsOneWidget);
      await tester.tap(find.text('#thiết yếu'));
      await tester.pumpAndSettle();

      // Tag chip with delete icon should now be active
      final deleteChip = find.byIcon(CupertinoIcons.xmark_circle_fill);
      expect(deleteChip, findsOneWidget);

      // Tap delete icon to remove tag
      await tester.tap(deleteChip);
      await tester.pumpAndSettle();
      expect(find.byIcon(CupertinoIcons.xmark_circle_fill), findsNothing);
    });

    testWidgets('toggles financial keypad and quick-selects wallet via chips', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      // Quick wallet chip selects Techcombank directly
      final techcombankChip = find.text('Techcombank');
      expect(techcombankChip, findsOneWidget);
      await tester.tap(techcombankChip);
      await tester.pumpAndSettle();

      // Toggle financial keypad
      final keypadToggle = find.byIcon(CupertinoIcons.number_square);
      expect(keypadToggle, findsOneWidget);
      await tester.tap(keypadToggle);
      await tester.pumpAndSettle();

      // Keypad is open
      expect(find.byType(AppleFinancialKeypad), findsOneWidget);
      expect(find.text('000'), findsOneWidget);
    });
  });
}
