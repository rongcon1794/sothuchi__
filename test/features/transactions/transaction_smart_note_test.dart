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
import 'package:so_thu_chi/features/categories/domain/entities/category.dart';
import 'package:so_thu_chi/features/transactions/data/repositories/firestore_transaction_repository.dart';
import 'package:so_thu_chi/features/transactions/domain/entities/transaction_entity.dart';
import 'package:so_thu_chi/features/transactions/presentation/screens/transaction_form_screen.dart';
import 'package:so_thu_chi/features/transactions/presentation/widgets/transaction_smart_note_section.dart';
import 'package:so_thu_chi/l10n/app_localizations.dart';

void main() {
  final now = DateTime(2026, 11, 12, 12, 0);

  Category makeCategory(String id, String name) => Category(
    id: id,
    name: name,
    type: CategoryType.expense,
    createdAt: now,
    updatedAt: now,
  );

  TransactionEntity makeTx({
    required String id,
    required int amount,
    required String categoryId,
    required String note,
    TransactionType type = TransactionType.expense,
    int daysAgo = 0,
  }) {
    final date = now.subtract(Duration(days: daysAgo));
    return TransactionEntity(
      id: id,
      amount: amount,
      currency: 'VND',
      type: type,
      accountId: 'acc_1',
      categoryId: categoryId,
      note: note,
      date: date,
      createdAt: date,
      updatedAt: date,
    );
  }

  group('buildSmartNoteSuggestions unit tests', () {
    test('prioritizes past descriptions matching BOTH category and exact amount', () {
      final foodCat = makeCategory('cat_food', 'Ăn uống');
      final txs = [
        makeTx(id: '1', amount: 150000, categoryId: 'cat_food', note: 'Lẩu nướng', daysAgo: 1),
        makeTx(id: '2', amount: 35000, categoryId: 'cat_food', note: 'Bún bò Huế', daysAgo: 2),
        makeTx(id: '3', amount: 40000, categoryId: 'cat_food', note: 'Cơm tấm', daysAgo: 3),
        makeTx(id: '4', amount: 35000, categoryId: 'cat_transport', note: 'Gửi xe tháng', daysAgo: 1),
      ];

      final suggestions = buildSmartNoteSuggestions(
        transactions: txs,
        type: TransactionType.expense,
        selectedCategory: foodCat,
        enteredAmountMinor: 35000,
        currencyCode: 'VND',
        currentQuery: '',
        fallbackSuggestions: const ['Ăn sáng', 'Ăn trưa'],
      );

      // Exact category + exact amount comes first and is marked isExactMatch
      expect(suggestions.first.note, 'Bún bò Huế');
      expect(suggestions.first.isFromHistory, isTrue);
      expect(suggestions.first.isExactMatch, isTrue);

      // Close amount in same category ('Cơm tấm' 40k is within ±25% of 35k) comes ahead of 150k 'Lẩu nướng'
      final notes = suggestions.map((s) => s.note).toList();
      expect(notes.indexOf('Cơm tấm'), lessThan(notes.indexOf('Lẩu nướng')));
      // Different category with exact amount ('Gửi xe tháng') is also available after same-category notes
      expect(notes, contains('Gửi xe tháng'));
    });

    test('suggests user history for selected category even before amount is entered', () {
      final transportCat = makeCategory('cat_transport', 'Di chuyển');
      final txs = [
        makeTx(id: '1', amount: 50000, categoryId: 'cat_transport', note: 'Đổ xăng A95', daysAgo: 2),
        makeTx(id: '2', amount: 50000, categoryId: 'cat_transport', note: 'Đổ xăng A95', daysAgo: 5),
        makeTx(id: '3', amount: 120000, categoryId: 'cat_transport', note: 'Grab sân bay', daysAgo: 1),
        makeTx(id: '4', amount: 30000, categoryId: 'cat_food', note: 'Cà phê', daysAgo: 0),
      ];

      final suggestions = buildSmartNoteSuggestions(
        transactions: txs,
        type: TransactionType.expense,
        selectedCategory: transportCat,
        enteredAmountMinor: 0,
        currencyCode: 'VND',
        currentQuery: '',
        fallbackSuggestions: const ['Đổ xăng', 'Gửi xe'],
      );

      final historyNotes = suggestions.where((s) => s.isFromHistory).map((s) => s.note).toList();
      expect(historyNotes, containsAll(['Đổ xăng A95', 'Grab sân bay']));
      // Should NOT include unrelated category notes when amount == 0 and query is empty
      expect(historyNotes, isNot(contains('Cà phê')));
    });

    test('boosts notes matching typed query prefix', () {
      final foodCat = makeCategory('cat_food', 'Ăn uống');
      final txs = [
        makeTx(id: '1', amount: 35000, categoryId: 'cat_food', note: 'Bún bò Huế', daysAgo: 1),
        makeTx(id: '2', amount: 30000, categoryId: 'cat_food', note: 'Trà sữa trân châu', daysAgo: 2),
      ];

      final suggestions = buildSmartNoteSuggestions(
        transactions: txs,
        type: TransactionType.expense,
        selectedCategory: foodCat,
        enteredAmountMinor: 0,
        currencyCode: 'VND',
        currentQuery: 'trà',
        fallbackSuggestions: const ['Ăn sáng', 'Cà phê'],
      );

      expect(suggestions.first.note, 'Trà sữa trân châu');
    });

    test('deduplicates case-insensitive notes while keeping newest casing', () {
      final foodCat = makeCategory('cat_food', 'Ăn uống');
      final txs = [
        makeTx(id: '1', amount: 30000, categoryId: 'cat_food', note: 'Cà phê muối', daysAgo: 1),
        makeTx(id: '2', amount: 30000, categoryId: 'cat_food', note: 'cà phê muối', daysAgo: 4),
      ];

      final suggestions = buildSmartNoteSuggestions(
        transactions: txs,
        type: TransactionType.expense,
        selectedCategory: foodCat,
        enteredAmountMinor: 30000,
        currencyCode: 'VND',
        currentQuery: '',
        fallbackSuggestions: const ['Ăn sáng'],
      );

      final matching = suggestions.where((s) => s.note.toLowerCase() == 'cà phê muối').toList();
      expect(matching.length, 1);
      expect(matching.first.note, 'Cà phê muối');
    });
  });

  group('TransactionFormScreen smart note widget integration', () {
    testWidgets('updates suggested descriptions dynamically when entering matching amount', (tester) async {
      SharedPreferences.setMockInitialValues({
        'theme_mode': 'system',
        'locale_code': 'vi',
        'currency_code': 'VND',
        'onboarding_completed': true,
      });
      final prefs = await SharedPreferences.getInstance();
      final accRepo = InMemoryAccountRepository();
      final catRepo = InMemoryCategoryRepository();
      final txRepo = InMemoryTransactionRepository(accountRepo: accRepo);

      await catRepo.seedDefaultCategoriesIfNeeded();
      final accRes = await accRepo.createAccount(
        name: 'Tiền mặt',
        type: AccountType.cash,
        initialBalance: 5000000,
        currency: 'VND',
        icon: 'cash',
        color: 0xFF00A86B,
      );
      final account = accRes.valueOrNull!;

      final allCats = await catRepo.watchCategories().first;
      final defaultFoodCat = allCats.firstWhere((c) => c.type == CategoryType.expense);

      // Seed user history in default category
      await txRepo.addTransaction(
        amount: 45000,
        currency: 'VND',
        type: TransactionType.expense,
        accountId: account.id,
        categoryId: defaultFoodCat.id,
        note: 'Bún chả Hà Nội',
        date: now.subtract(const Duration(days: 1)),
      );
      await txRepo.addTransaction(
        amount: 25000,
        currency: 'VND',
        type: TransactionType.expense,
        accountId: account.id,
        categoryId: defaultFoodCat.id,
        note: 'Bánh mì pate',
        date: now.subtract(const Duration(days: 2)),
      );

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
            home: const TransactionFormScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Both past descriptions appear in note suggestions
      expect(find.text('Bún chả Hà Nội'), findsOneWidget);
      expect(find.text('Bánh mì pate'), findsOneWidget);

      // Enter exact amount 25000 -> 'Bánh mì pate' should move before 'Bún chả Hà Nội'
      final amountField = find.byType(TextField).first;
      await tester.enterText(amountField, '25000');
      await tester.pumpAndSettle();

      final banhMiX = tester.getTopLeft(find.text('Bánh mì pate')).dx;
      final bunChaX = tester.getTopLeft(find.text('Bún chả Hà Nội')).dx;
      expect(banhMiX, lessThan(bunChaX));

      // Tapping 'Bánh mì pate' fills the note controller
      await tester.ensureVisible(find.text('Bánh mì pate'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Bánh mì pate'));
      await tester.pumpAndSettle();
      expect(find.text('Bánh mì pate'), findsWidgets);
    });
  });
}

