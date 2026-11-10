import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:so_thu_chi/data/firebase/firebase_providers.dart';
import 'package:so_thu_chi/features/accounts/data/repositories/firestore_account_repository.dart';
import 'package:so_thu_chi/features/accounts/domain/repositories/account_repository.dart';
import 'package:so_thu_chi/features/auth/data/datasources/google_sign_in_client.dart';
import 'package:so_thu_chi/features/auth/data/repositories/firebase_auth_repository.dart';
import 'package:so_thu_chi/features/auth/domain/entities/app_user.dart';
import 'package:so_thu_chi/features/auth/domain/repositories/auth_repository.dart';
import 'package:so_thu_chi/features/budgets/data/repositories/firestore_budget_repository.dart';
import 'package:so_thu_chi/features/budgets/domain/repositories/budget_repository.dart';
import 'package:so_thu_chi/features/categories/data/repositories/firestore_category_repository.dart';
import 'package:so_thu_chi/features/categories/domain/repositories/category_repository.dart';
import 'package:so_thu_chi/features/debts/data/repositories/firestore_debt_repository.dart';
import 'package:so_thu_chi/features/debts/domain/repositories/debt_repository.dart';
import 'package:so_thu_chi/features/ledger/data/repositories/firestore_ledger_repository.dart';
import 'package:so_thu_chi/features/ledger/domain/entities/ledger_book.dart';
import 'package:so_thu_chi/features/ledger/domain/repositories/ledger_repository.dart';
import 'package:so_thu_chi/features/ledger/presentation/controllers/ledgers_controller.dart';
import 'package:so_thu_chi/features/recurring/data/repositories/firestore_recurring_repository.dart';
import 'package:so_thu_chi/features/recurring/domain/repositories/recurring_repository.dart';
import 'package:so_thu_chi/features/savings/data/repositories/firestore_savings_goal_repository.dart';
import 'package:so_thu_chi/features/savings/domain/repositories/savings_goal_repository.dart';
import 'package:so_thu_chi/features/reports/data/repositories/reports_repository_impl.dart';
import 'package:so_thu_chi/features/reports/domain/repositories/reports_repository.dart';
import 'package:so_thu_chi/features/settings/data/repositories/settings_repository_impl.dart';
import 'package:so_thu_chi/features/settings/domain/repositories/settings_repository.dart';
import 'package:so_thu_chi/features/settings/presentation/controllers/settings_controller.dart';
import 'package:so_thu_chi/features/transactions/data/repositories/firestore_transaction_repository.dart';
import 'package:so_thu_chi/features/transactions/domain/repositories/transaction_repository.dart';

/// Shared in-memory stores used in Offline Demo Mode or unauthenticated state.
final inMemoryAccountRepoProvider = Provider<InMemoryAccountRepository>((ref) {
  return InMemoryAccountRepository();
});

final inMemoryCategoryRepoProvider = Provider<InMemoryCategoryRepository>((
  ref,
) {
  return InMemoryCategoryRepository();
});

final inMemoryTransactionRepoProvider = Provider<InMemoryTransactionRepository>(
  (ref) {
    return InMemoryTransactionRepository(
      accountRepo: ref.watch(inMemoryAccountRepoProvider),
    );
  },
);

final inMemoryBudgetRepoProvider = Provider<InMemoryBudgetRepository>((ref) {
  return InMemoryBudgetRepository();
});

final inMemoryDebtRepoProvider = Provider<InMemoryDebtRepository>((ref) {
  return InMemoryDebtRepository(
    accountRepo: ref.watch(inMemoryAccountRepoProvider),
    seedDemoData: false,
  );
});

final inMemoryRecurringRepoProvider = Provider<InMemoryRecurringRepository>((ref) {
  return InMemoryRecurringRepository(
    transactionRepository: ref.watch(inMemoryTransactionRepoProvider),
  );
});

final inMemorySavingsGoalRepoProvider =
    Provider<InMemorySavingsGoalRepository>((ref) {
  return InMemorySavingsGoalRepository(
    transactionRepository: ref.watch(inMemoryTransactionRepoProvider),
  );
});

final inMemoryLedgerRepoProvider = Provider<InMemoryLedgerRepository>((ref) {
  return InMemoryLedgerRepository();
});

/// Bootstrapper invoked when a user signs in:
/// - If the user has existing data on Firebase, restores their state and marks initial setup complete.
/// - If the user is a first-time user without data, only seeds categories and leaves initial setup
///   to be completed via the InitialSetupScreen so no duplicate or phantom data is generated.
final userBootstrapCallbackProvider = Provider<UserBootstrapCallback?>((ref) {
  return (AppUser user) async {
    final firestore = ref.read(firestoreProvider);
    final settingsRepo = ref.read(settingsRepositoryProvider);

    // 1. If user has settings stored in cloud, restore them immediately
    if (user.themeMode != null ||
        user.accentColorIndex != null ||
        (user.defaultWalletId != null && user.defaultWalletId!.isNotEmpty) ||
        user.oledMode != null ||
        user.hideBalance != null ||
        user.initialSetupCompleted == true) {
      await ref
          .read(settingsControllerProvider.notifier)
          .restoreFromCloudUser(user);
    }

    // Fast-path: If setup is already completed, exit immediately.
    // Avoids heavy Firestore queries & JSON deserialization on app wake-up.
    final currentSettings = await settingsRepo.loadSettings();
    if (currentSettings.initialSetupCompleted) {
      if (user.themeMode == null &&
          user.accentColorIndex == null &&
          !user.isDemoUser &&
          firestore != null) {
        unawaited(
          ref.read(settingsControllerProvider.notifier).backupToCloudUser(),
        );
      }
      return;
    }

    if (user.isDemoUser || firestore == null) {
      final catRepo = ref.read(inMemoryCategoryRepoProvider);
      await catRepo.seedDefaultCategoriesIfNeeded();
      final accRepo = ref.read(inMemoryAccountRepoProvider);
      final txRepo = ref.read(inMemoryTransactionRepoProvider);
      final ledgerRepo = ref.read(inMemoryLedgerRepoProvider);

      final accounts = await accRepo.getAccounts();
      final txs = await txRepo.getTransactions();
      final ledgers = await ledgerRepo.getLedgers();
      final budgets = await ref.read(inMemoryBudgetRepoProvider).getBudgets();

      final hasExistingData = txs.isNotEmpty ||
          budgets.isNotEmpty ||
          accounts.any((a) => a.deletedAt == null) ||
          ledgers.any((l) =>
              l.id != LedgerBook.defaultPersonalId &&
              l.id != 'default_family');

      if (hasExistingData) {
        await ref
            .read(settingsControllerProvider.notifier)
            .completeInitialSetup(uid: user.uid);
        if (accounts.isNotEmpty) {
          await ref
              .read(settingsControllerProvider.notifier)
              .setDefaultWalletId(accounts.first.id);
        }
      }
    } else {
      final catRepo = FirestoreCategoryRepository(
        firestore: firestore,
        uid: user.uid,
      );
      await catRepo.seedDefaultCategoriesIfNeeded();

      final userDoc = firestore.collection('users').doc(user.uid);

      // Query with limit and in parallel to avoid downloading entire database
      QuerySnapshot<Map<String, dynamic>> txSnap;
      QuerySnapshot<Map<String, dynamic>> accSnap;
      QuerySnapshot<Map<String, dynamic>> ledgerSnap;
      QuerySnapshot<Map<String, dynamic>> budgetSnap;
      QuerySnapshot<Map<String, dynamic>> debtSnap;
      QuerySnapshot<Map<String, dynamic>> savingsSnap;
      QuerySnapshot<Map<String, dynamic>> recurringSnap;

      try {
        final results = await Future.wait([
          userDoc.collection('transactions').limit(5).get(),
          userDoc.collection('accounts').limit(5).get(),
          userDoc.collection('ledgers').limit(5).get(),
          userDoc.collection('budgets').limit(5).get(),
          userDoc.collection('debts').limit(5).get(),
          userDoc.collection('savings_goals').limit(5).get(),
          userDoc.collection('recurring').limit(5).get(),
        ]).timeout(const Duration(seconds: 10));
        txSnap = results[0];
        accSnap = results[1];
        ledgerSnap = results[2];
        budgetSnap = results[3];
        debtSnap = results[4];
        savingsSnap = results[5];
        recurringSnap = results[6];
      } catch (_) {
        return;
      }

      final activeTxDocs = txSnap.docs
          .where((d) => d.data()['deletedAt'] == null)
          .toList();
      final activeAccDocs = accSnap.docs
          .where((d) => d.data()['deletedAt'] == null)
          .toList();
      final activeBudgetDocs = budgetSnap.docs
          .where((d) => d.data()['deletedAt'] == null)
          .toList();
      final activeDebtDocs = debtSnap.docs
          .where((d) => d.data()['deletedAt'] == null)
          .toList();
      final activeSavingsDocs = savingsSnap.docs
          .where((d) => d.data()['deletedAt'] == null)
          .toList();
      final activeRecurringDocs = recurringSnap.docs
          .where((d) => d.data()['deletedAt'] == null)
          .toList();
      final activeLedgerDocs = ledgerSnap.docs
          .where((d) => d.data()['deletedAt'] == null)
          .toList();

      final hasExistingData = activeTxDocs.isNotEmpty ||
          activeAccDocs.isNotEmpty ||
          activeBudgetDocs.isNotEmpty ||
          activeDebtDocs.isNotEmpty ||
          activeSavingsDocs.isNotEmpty ||
          activeRecurringDocs.isNotEmpty ||
          activeLedgerDocs.any((d) =>
              d.id != LedgerBook.defaultPersonalId &&
              d.id != 'default_family');

      if (hasExistingData) {
        // User has existing data on Firebase -> restore setup state
        await ref
            .read(settingsControllerProvider.notifier)
            .completeInitialSetup(uid: user.uid);

        if (activeAccDocs.isNotEmpty) {
          final settings = ref.read(settingsControllerProvider).value;
          final savedDefaultId = user.defaultWalletId;
          if (savedDefaultId != null &&
              savedDefaultId.isNotEmpty &&
              activeAccDocs.any((d) => d.id == savedDefaultId)) {
            await ref
                .read(settingsControllerProvider.notifier)
                .setDefaultWalletId(savedDefaultId);
          } else if (settings?.defaultWalletId == null ||
              settings!.defaultWalletId!.isEmpty) {
            await ref
                .read(settingsControllerProvider.notifier)
                .setDefaultWalletId(activeAccDocs.first.id);
          }
        }

        if (activeLedgerDocs.isNotEmpty) {
          final defaultLedger = activeLedgerDocs.firstWhere(
            (d) => d.data()['isDefault'] == true,
            orElse: () => activeLedgerDocs.first,
          );
          ref.read(activeLedgerIdProvider.notifier).selectLedger(defaultLedger.id);
        }
      }
    }
  };
});

/// Cleanup hook when an offline demo account deletes all data.
final demoDataCleanupCallbackProvider = Provider<Future<void> Function()?>(
  (ref) => () async {
    ref.read(inMemoryDebtRepoProvider).clear();
    ref.read(inMemoryBudgetRepoProvider).clear();
    ref.read(inMemoryTransactionRepoProvider).clear();
    ref.read(inMemoryAccountRepoProvider).clear();
    ref.read(inMemoryCategoryRepoProvider).clear();
    ref.read(inMemoryRecurringRepoProvider).clear();
    ref.read(inMemorySavingsGoalRepoProvider).clear();
    ref.read(inMemoryLedgerRepoProvider).clear();
    await ref.read(settingsControllerProvider.notifier).resetInitialSetup();
  },
);

final settingsRepositoryProvider = Provider<SettingsRepository>((ref) {
  return SettingsRepositoryImpl(
    prefs: ref.watch(sharedPreferencesProvider),
    secureStorage: ref.watch(secureStorageProvider),
  );
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final repo = FirebaseAuthRepository(
    firebaseAuth: ref.watch(firebaseAuthProvider),
    firestore: ref.watch(firestoreProvider),
    googleSignInClient: ref.watch(googleSignInClientProvider),
    prefs: ref.watch(sharedPreferencesProvider),
    onUserSignedIn: (AppUser user) async {
      final cb = ref.read(userBootstrapCallbackProvider);
      if (cb != null) {
        await cb(user);
      }
    },
    onDemoDataCleared: () async {
      final cb = ref.read(demoDataCleanupCallbackProvider);
      if (cb != null) {
        await cb();
      }
    },
  );
  ref.onDispose(repo.dispose);
  return repo;
});

/// Streams the active [AppUser] session from [AuthRepository].
final authStateStreamProvider = StreamProvider<AppUser?>((ref) {
  return ref.watch(authRepositoryProvider).watchAuthState();
});

/// Synchronous convenience accessor for the authenticated user.
final currentUserProvider = Provider<AppUser?>((ref) {
  final asyncUser = ref.watch(authStateStreamProvider);
  return asyncUser.value ?? ref.watch(authRepositoryProvider).currentUser;
});

final accountRepositoryProvider = Provider<AccountRepository>((ref) {
  final user = ref.watch(currentUserProvider);
  final firestore = ref.watch(firestoreProvider);
  if (user == null || user.isDemoUser || firestore == null) {
    return ref.watch(inMemoryAccountRepoProvider);
  }
  return FirestoreAccountRepository(firestore: firestore, uid: user.uid);
});

final categoryRepositoryProvider = Provider<CategoryRepository>((ref) {
  final user = ref.watch(currentUserProvider);
  final firestore = ref.watch(firestoreProvider);
  if (user == null || user.isDemoUser || firestore == null) {
    return ref.watch(inMemoryCategoryRepoProvider);
  }
  return FirestoreCategoryRepository(firestore: firestore, uid: user.uid);
});

final transactionRepositoryProvider = Provider<TransactionRepository>((ref) {
  final user = ref.watch(currentUserProvider);
  final firestore = ref.watch(firestoreProvider);
  if (user == null || user.isDemoUser || firestore == null) {
    return ref.watch(inMemoryTransactionRepoProvider);
  }
  return FirestoreTransactionRepository(firestore: firestore, uid: user.uid);
});

final budgetRepositoryProvider = Provider<BudgetRepository>((ref) {
  final user = ref.watch(currentUserProvider);
  final firestore = ref.watch(firestoreProvider);
  if (user == null || user.isDemoUser || firestore == null) {
    return ref.watch(inMemoryBudgetRepoProvider);
  }
  return FirestoreBudgetRepository(firestore: firestore, uid: user.uid);
});

final debtRepositoryProvider = Provider<DebtRepository>((ref) {
  final user = ref.watch(currentUserProvider);
  final firestore = ref.watch(firestoreProvider);
  if (user == null || user.isDemoUser || firestore == null) {
    return ref.watch(inMemoryDebtRepoProvider);
  }
  return FirestoreDebtRepository(firestore: firestore, uid: user.uid);
});

final recurringRepositoryProvider = Provider<RecurringRepository>((ref) {
  final user = ref.watch(currentUserProvider);
  final firestore = ref.watch(firestoreProvider);
  final txRepo = ref.watch(transactionRepositoryProvider);
  if (user == null || user.isDemoUser || firestore == null) {
    return ref.watch(inMemoryRecurringRepoProvider);
  }
  return FirestoreRecurringRepository(
    firestore: firestore,
    currentUserIdGetter: () => user.uid,
    transactionRepository: txRepo,
  );
});

final savingsGoalRepositoryProvider = Provider<SavingsGoalRepository>((ref) {
  final user = ref.watch(currentUserProvider);
  final firestore = ref.watch(firestoreProvider);
  final txRepo = ref.watch(transactionRepositoryProvider);
  if (user == null || user.isDemoUser || firestore == null) {
    return ref.watch(inMemorySavingsGoalRepoProvider);
  }
  return FirestoreSavingsGoalRepository(
    firestore: firestore,
    currentUserIdGetter: () => user.uid,
    transactionRepository: txRepo,
  );
});

final ledgerRepositoryProvider = Provider<LedgerRepository>((ref) {
  final user = ref.watch(currentUserProvider);
  final firestore = ref.watch(firestoreProvider);
  if (user == null || user.isDemoUser || firestore == null) {
    return ref.watch(inMemoryLedgerRepoProvider);
  }
  return FirestoreLedgerRepository(
    firestore: firestore,
    currentUserIdGetter: () => user.uid,
  );
});

final reportsRepositoryProvider = Provider<ReportsRepository>((ref) {
  return const ReportsRepositoryImpl();
});
