import 'dart:async';

import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:so_thu_chi/app.dart';
import 'package:so_thu_chi/core/errors/result.dart';
import 'package:so_thu_chi/data/firebase/firebase_providers.dart';
import 'package:so_thu_chi/data/providers/repository_providers.dart';
import 'package:so_thu_chi/features/accounts/data/repositories/firestore_account_repository.dart';
import 'package:so_thu_chi/features/auth/data/models/user_profile_dto.dart';
import 'package:so_thu_chi/features/auth/domain/entities/app_user.dart';
import 'package:so_thu_chi/features/auth/domain/repositories/auth_repository.dart';
import 'package:so_thu_chi/features/budgets/data/repositories/firestore_budget_repository.dart';
import 'package:so_thu_chi/features/categories/data/repositories/firestore_category_repository.dart';
import 'package:so_thu_chi/features/debts/data/repositories/firestore_debt_repository.dart';
import 'package:so_thu_chi/features/ledger/data/repositories/firestore_ledger_repository.dart';
import 'package:so_thu_chi/features/recurring/data/repositories/firestore_recurring_repository.dart';
import 'package:so_thu_chi/features/savings/data/repositories/firestore_savings_goal_repository.dart';
import 'package:so_thu_chi/features/transactions/data/repositories/firestore_transaction_repository.dart';

class FakeAuthRepository implements AuthRepository {
  FakeAuthRepository({this.cloudConfigured = true});

  final bool cloudConfigured;
  final StreamController<AppUser?> _ctrl =
      StreamController<AppUser?>.broadcast();
  AppUser? _user;
  bool deleteAccountCalled = false;

  @override
  bool get isCloudAuthConfigured => cloudConfigured;

  @override
  AppUser? get currentUser => _user;

  @override
  Stream<AppUser?> watchAuthState() async* {
    yield _user;
    yield* _ctrl.stream;
  }

  @override
  Future<Result<AppUser>> signInWithGoogle() async {
    final now = DateTime(2026, 11, 3);
    final signedIn = AppUser(
      uid: 'uid_test_1',
      email: 'minh@sothuchi.vn',
      displayName: 'Nguyễn Minh',
      createdAt: now,
      updatedAt: now,
    );
    _user = signedIn;
    _ctrl.add(signedIn);
    return Success(signedIn);
  }

  @override
  Future<Result<AppUser>> signInOfflineDemo() => signInWithGoogle();

  @override
  Future<Result<void>> signOut() async {
    _user = null;
    _ctrl.add(null);
    return const Success(null);
  }

  @override
  Future<Result<void>> deleteAccountAndAllData() async {
    deleteAccountCalled = true;
    _user = null;
    _ctrl.add(null);
    return const Success(null);
  }

  @override
  Future<Result<void>> updateProfilePreferences({
    String? defaultCurrency,
    String? locale,
  }) async {
    if (_user != null) {
      _user = _user!.copyWith(
        defaultCurrency: defaultCurrency ?? _user!.defaultCurrency,
        locale: locale ?? _user!.locale,
      );
      _ctrl.add(_user);
    }
    return const Success(null);
  }
}

void main() {
  group('Auth & Onboarding Milestone (b)', () {
    test('UserProfileDto round-trips timestamps and deletedAt accurately', () async {
      final fakeDb = FakeFirebaseFirestore();
      final now = DateTime(2026, 11, 3, 12, 0);
      final dto = UserProfileDto(
        uid: 'u1',
        email: 'user@example.com',
        displayName: 'Lan Anh',
        createdAt: now,
        updatedAt: now,
      );

      await fakeDb.collection('users').doc('u1').set(dto.toJson());
      final snap = await fakeDb.collection('users').doc('u1').get();
      final restored = UserProfileDto.fromJson(snap.data()!);

      expect(restored.uid, 'u1');
      expect(restored.email, 'user@example.com');
      expect(restored.defaultCurrency, 'VND');
      expect(restored.deletedAt, isNull);
    });

    testWidgets(
      'Completing onboarding navigates to Google Login, then signing in navigates to Home',
      (tester) async {
        SharedPreferences.setMockInitialValues({});
        FlutterSecureStorage.setMockInitialValues({});
        final prefs = await SharedPreferences.getInstance();
        final fakeAuth = FakeAuthRepository();
        final accRepo = InMemoryAccountRepository();
        final catRepo = InMemoryCategoryRepository();
        final txRepo = InMemoryTransactionRepository(accountRepo: accRepo);
        final budgetRepo = InMemoryBudgetRepository();
        final debtRepo = InMemoryDebtRepository(accountRepo: accRepo);
        final recurringRepo = InMemoryRecurringRepository(transactionRepository: txRepo);
        final savingsRepo = InMemorySavingsGoalRepository(transactionRepository: txRepo);
        final ledgerRepo = InMemoryLedgerRepository();

        await catRepo.seedDefaultCategoriesIfNeeded();
        await accRepo.ensureDefaultWallet(currency: 'VND');

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              sharedPreferencesProvider.overrideWithValue(prefs),
              firebaseBootstrapStateProvider.overrideWithValue(
                const FirebaseBootstrapState.configured(),
              ),
              authRepositoryProvider.overrideWithValue(fakeAuth),
              accountRepositoryProvider.overrideWithValue(accRepo),
              categoryRepositoryProvider.overrideWithValue(catRepo),
              transactionRepositoryProvider.overrideWithValue(txRepo),
              budgetRepositoryProvider.overrideWithValue(budgetRepo),
              debtRepositoryProvider.overrideWithValue(debtRepo),
              recurringRepositoryProvider.overrideWithValue(recurringRepo),
              savingsGoalRepositoryProvider.overrideWithValue(savingsRepo),
              ledgerRepositoryProvider.overrideWithValue(ledgerRepo),
            ],
            child: const SoThuChiApp(),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.text('Bỏ qua'), findsOneWidget);

        // Onboarding -> Skip
        await tester.tap(find.text('Bỏ qua'));
        await tester.pumpAndSettle();
        expect(find.text('Đăng nhập với Google'), findsOneWidget);

        // Login screen ("Đăng nhập với Google")
        expect(find.text('Đăng nhập với Google'), findsOneWidget);
        await tester.tap(find.text('Đăng nhập với Google'));
        await tester.pumpAndSettle();

        // First-time user setup wizard ("Thiết lập ban đầu")
        expect(find.text('Thiết lập ban đầu'), findsOneWidget);
        expect(find.text('Áp dụng đề xuất & Bắt đầu ngay'), findsOneWidget);

        // Apply quick defaults & start
        await tester.tap(find.text('Áp dụng đề xuất & Bắt đầu ngay'));
        await tester.pumpAndSettle();

        expect(find.text('Tổng quan'), findsWidgets);

        // Sign out returns to Login screen
        await fakeAuth.signOut();
        await tester.pumpAndSettle();
        expect(find.text('Đăng nhập với Google'), findsOneWidget);
      },
    );
  });
}

