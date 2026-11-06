import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:so_thu_chi/core/errors/result.dart';
import 'package:so_thu_chi/core/theme/app_theme.dart';
import 'package:so_thu_chi/data/firebase/firebase_providers.dart';
import 'package:so_thu_chi/data/providers/repository_providers.dart';
import 'package:so_thu_chi/features/accounts/data/repositories/firestore_account_repository.dart';
import 'package:so_thu_chi/features/accounts/domain/entities/account.dart';
import 'package:so_thu_chi/features/accounts/presentation/screens/account_detail_screen.dart';
import 'package:so_thu_chi/features/accounts/presentation/screens/accounts_screen.dart';
import 'package:so_thu_chi/features/categories/data/repositories/firestore_category_repository.dart';
import 'package:so_thu_chi/features/categories/domain/entities/category.dart';
import 'package:so_thu_chi/features/categories/presentation/screens/category_detail_screen.dart';
import 'package:so_thu_chi/features/categories/presentation/screens/categories_screen.dart';
import 'package:so_thu_chi/features/transactions/data/repositories/firestore_transaction_repository.dart';
import 'package:so_thu_chi/features/transactions/domain/entities/transaction_entity.dart';
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
      expect(find.text('Chưa có giao dịch trên ví này'), findsOneWidget);
      expect(find.text('Thêm giao dịch'), findsAtLeastNWidgets(1));
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
  });
}

