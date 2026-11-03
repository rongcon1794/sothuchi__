import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:so_thu_chi/core/theme/app_theme.dart';
import 'package:so_thu_chi/core/widgets/biometric_lock_gate.dart';
import 'package:so_thu_chi/data/firebase/firebase_providers.dart';
import 'package:so_thu_chi/data/providers/repository_providers.dart';
import 'package:so_thu_chi/data/services/biometric_service.dart';
import 'package:so_thu_chi/features/accounts/data/repositories/firestore_account_repository.dart';
import 'package:so_thu_chi/features/accounts/domain/entities/account.dart';
import 'package:so_thu_chi/features/auth/domain/entities/app_user.dart';
import 'package:so_thu_chi/features/budgets/data/repositories/firestore_budget_repository.dart';
import 'package:so_thu_chi/features/categories/data/repositories/firestore_category_repository.dart';
import 'package:so_thu_chi/features/reports/presentation/screens/reports_screen.dart';
import 'package:so_thu_chi/features/transactions/data/repositories/firestore_transaction_repository.dart';
import 'package:so_thu_chi/features/transactions/domain/entities/transaction_entity.dart';
import 'package:so_thu_chi/features/transactions/presentation/screens/home_dashboard_screen.dart';
import 'package:so_thu_chi/l10n/app_localizations.dart';

class _ManualBiometricService implements BiometricService {
  bool allowAuth = false;
  int prompts = 0;

  @override
  Future<bool> isAvailable() async => true;

  @override
  Future<bool> authenticate({required String localizedReason}) async {
    prompts++;
    return allowAuth;
  }
}

void main() {
  group('BiometricLockGate & Accessibility 200% Text-Scale Audits', () {
    testWidgets(
      'BiometricLockGate blocks cold-start access until biometric auth succeeds',
      (tester) async {
        SharedPreferences.setMockInitialValues({
          'settings.onboarding_completed': true,
        });
        FlutterSecureStorage.setMockInitialValues({
          'settings.biometric_lock_enabled': 'true',
        });
        final prefs = await SharedPreferences.getInstance();
        final bio = _ManualBiometricService()..allowAuth = false;
        final now = DateTime(2026, 11, 3);
        final testUser = AppUser(
          uid: 'u_lock_test',
          email: 'lock@sothuchi.vn',
          displayName: 'Minh',
          createdAt: now,
          updatedAt: now,
        );

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              sharedPreferencesProvider.overrideWithValue(prefs),
              biometricServiceProvider.overrideWithValue(bio),
              authStateStreamProvider.overrideWith(
                (ref) => Stream<AppUser?>.value(testUser),
              ),
              currentUserProvider.overrideWithValue(testUser),
            ],
            child: MaterialApp(
              locale: const Locale('vi'),
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              theme: AppTheme.light(),
              home: const BiometricLockGate(
                child: Scaffold(body: Center(child: Text('SECRET_DASHBOARD'))),
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Secret content is hidden behind the lock shield when initial biometric fails.
        expect(find.text('Sổ Thu Chi đang khóa'), findsOneWidget);
        expect(find.text('SECRET_DASHBOARD'), findsNothing);
        expect(bio.prompts, 1);

        // User taps Unlock Now and succeeds.
        bio.allowAuth = true;
        await tester.tap(find.text('Mở khóa ngay'));
        await tester.pumpAndSettle();

        expect(find.text('SECRET_DASHBOARD'), findsOneWidget);
        expect(find.text('Sổ Thu Chi đang khóa'), findsNothing);
      },
    );

    testWidgets(
      'HomeDashboardScreen and ReportsScreen render cleanly at 200% font scale without overflow',
      (tester) async {
        SharedPreferences.setMockInitialValues({
          'settings.onboarding_completed': true,
        });
        FlutterSecureStorage.setMockInitialValues({});
        final prefs = await SharedPreferences.getInstance();
        final accRepo = InMemoryAccountRepository();
        final catRepo = InMemoryCategoryRepository();
        final txRepo = InMemoryTransactionRepository(accountRepo: accRepo);
        final budgetRepo = InMemoryBudgetRepository();

        await catRepo.seedDefaultCategoriesIfNeeded();
        final createdWallet = await accRepo.createAccount(
          name: 'Ví chính Vietcombank',
          type: AccountType.bank,
          initialBalance: 15500000,
          currency: 'VND',
          icon: 'bank',
          color: 0xFF0D7C66,
        );
        final walletId = (createdWallet as dynamic).value.id as String;
        await txRepo.addTransaction(
          amount: 125000,
          currency: 'VND',
          type: TransactionType.expense,
          accountId: walletId,
          categoryId: 'default_food',
          note: 'Bún bò Huế buổi sáng cùng đồng nghiệp',
          date: DateTime.now(),
          tags: const ['ăn sáng', 'văn phòng'],
        );

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              sharedPreferencesProvider.overrideWithValue(prefs),
              accountRepositoryProvider.overrideWithValue(accRepo),
              categoryRepositoryProvider.overrideWithValue(catRepo),
              transactionRepositoryProvider.overrideWithValue(txRepo),
              budgetRepositoryProvider.overrideWithValue(budgetRepo),
            ],
            child: MediaQuery(
              data: const MediaQueryData(
                size: Size(390, 844),
                textScaler: TextScaler.linear(2.0),
              ),
              child: MaterialApp(
                locale: const Locale('vi'),
                localizationsDelegates: AppLocalizations.localizationsDelegates,
                supportedLocales: AppLocalizations.supportedLocales,
                theme: AppTheme.dark(),
                home: const HomeDashboardScreen(),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              sharedPreferencesProvider.overrideWithValue(prefs),
              accountRepositoryProvider.overrideWithValue(accRepo),
              categoryRepositoryProvider.overrideWithValue(catRepo),
              transactionRepositoryProvider.overrideWithValue(txRepo),
              budgetRepositoryProvider.overrideWithValue(budgetRepo),
            ],
            child: MediaQuery(
              data: const MediaQueryData(
                size: Size(390, 844),
                textScaler: TextScaler.linear(2.0),
              ),
              child: MaterialApp(
                locale: const Locale('vi'),
                localizationsDelegates: AppLocalizations.localizationsDelegates,
                supportedLocales: AppLocalizations.supportedLocales,
                theme: AppTheme.dark(),
                home: const ReportsScreen(),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      },
    );
  });
}

