import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:so_thu_chi/core/constants/currency_constants.dart';
import 'package:so_thu_chi/core/errors/app_exception.dart';
import 'package:so_thu_chi/core/errors/result.dart';
import 'package:so_thu_chi/data/providers/repository_providers.dart';
import 'package:so_thu_chi/features/accounts/domain/entities/account.dart';
import 'package:so_thu_chi/features/budgets/presentation/controllers/budgets_controller.dart';
import 'package:so_thu_chi/features/ledger/domain/entities/ledger_book.dart';
import 'package:so_thu_chi/features/ledger/presentation/controllers/ledgers_controller.dart';
import 'package:so_thu_chi/features/settings/presentation/controllers/settings_controller.dart';

class InitialSetupWalletDraft {
  const InitialSetupWalletDraft({
    required this.key,
    required this.name,
    required this.type,
    required this.initialBalance,
    required this.icon,
    required this.color,
  });

  final String key;
  final String name;
  final AccountType type;
  final int initialBalance;
  final String icon;
  final int color;
}

class InitialSetupController extends Notifier<AsyncValue<void>> {
  @override
  AsyncValue<void> build() => const AsyncData(null);

  /// Checks if the signed-in user already has existing data (transactions, custom
  /// accounts or ledgers) on Firebase.
  /// If data exists, restores their active ledger & default wallet and marks setup completed.
  /// Returns `true` if existing data was found & restored, `false` if user is brand new.
  Future<bool> checkAndRestoreIfExisting(String uid) async {
    try {
      final ledgerRepo = ref.read(ledgerRepositoryProvider);
      final accRepo = ref.read(accountRepositoryProvider);
      final txRepo = ref.read(transactionRepositoryProvider);
      final catRepo = ref.read(categoryRepositoryProvider);
      final budgetRepo = ref.read(budgetRepositoryProvider);
      final debtRepo = ref.read(debtRepositoryProvider);
      final savingsRepo = ref.read(savingsGoalRepositoryProvider);
      final recurringRepo = ref.read(recurringRepositoryProvider);

      await catRepo.seedDefaultCategoriesIfNeeded();

      final ledgers = await ledgerRepo.getLedgers();
      final accounts = await accRepo.getAccounts();
      final txs = await txRepo.getTransactions();
      final budgets = await budgetRepo.getBudgets();
      final debts = await debtRepo.watchDebts().first.timeout(
            const Duration(seconds: 3),
            onTimeout: () => const [],
          );
      final savings = await savingsRepo.watchSavingsGoals().first.timeout(
            const Duration(seconds: 3),
            onTimeout: () => const [],
          );
      final recurring = await recurringRepo
          .watchRecurringTransactions()
          .first
          .timeout(
            const Duration(seconds: 3),
            onTimeout: () => const [],
          );

      final hasExistingData = accounts.any((a) => a.deletedAt == null) ||
          txs.any((t) => t.deletedAt == null) ||
          budgets.any((b) => b.deletedAt == null) ||
          debts.any((d) => d.deletedAt == null) ||
          savings.isNotEmpty ||
          recurring.isNotEmpty ||
          ledgers.any((l) =>
              l.id != LedgerBook.defaultPersonalId &&
              l.id != 'default_family');

      if (hasExistingData) {
        // 1. Select user's default or primary ledger
        if (ledgers.isNotEmpty) {
          final targetLedger =
              ledgers.where((l) => l.isDefault).firstOrNull ?? ledgers.first;
          ref
              .read(activeLedgerIdProvider.notifier)
              .selectLedger(targetLedger.id, ensureWallet: false);
        }

        // 2. Select default wallet
        final activeAccounts =
            accounts.where((a) => a.deletedAt == null).toList();
        if (activeAccounts.isNotEmpty) {
          final activeLedgerId = ref.read(activeLedgerIdProvider);
          final targetWallet = activeAccounts.firstWhere(
            (a) => a.ledgerId == activeLedgerId,
            orElse: () => activeAccounts.first,
          );
          await ref
              .read(settingsControllerProvider.notifier)
              .setDefaultWalletId(targetWallet.id);
        }

        // 3. Mark initial setup completed
        await ref
            .read(settingsControllerProvider.notifier)
            .completeInitialSetup(uid: uid);

        return true;
      }

      return false;
    } catch (_) {
      return false;
    }
  }

  Future<Result<void>> applyQuickDefaults({String? uid}) async {
    state = const AsyncLoading();
    try {
      final accRepo = ref.read(accountRepositoryProvider);
      final ledgerRepo = ref.read(ledgerRepositoryProvider);
      final catRepo = ref.read(categoryRepositoryProvider);

      // 1. Seed categories
      await catRepo.seedDefaultCategoriesIfNeeded();

      // 2. Ensure Personal & Family ledgers
      final now = DateTime.now();
      final personalLedger = LedgerBook(
        id: LedgerBook.defaultPersonalId,
        name: 'Sổ Cá Nhân',
        type: LedgerType.personal,
        icon: 'person',
        color: 0xFF00A86B,
        currency: AppCurrencies.defaultCode,
        isDefault: true,
        createdAt: now,
        updatedAt: now,
      );
      final personalRes = await ledgerRepo.createLedger(personalLedger);
      final targetLedgerId =
          personalRes.valueOrNull?.id ?? LedgerBook.defaultPersonalId;

      final familyLedger = LedgerBook(
        id: 'default_family',
        name: 'Sổ Gia Đình',
        type: LedgerType.family,
        icon: 'family',
        color: 0xFF007AFF,
        currency: AppCurrencies.defaultCode,
        isDefault: false,
        createdAt: now,
        updatedAt: now,
      );
      await ledgerRepo.createLedger(familyLedger);

      // 3. Create default recommended wallets: Tiền mặt (500k) & Ngân hàng (5M)
      final cashRes = await accRepo.createAccount(
        name: 'Tiền mặt',
        type: AccountType.cash,
        initialBalance: 500000,
        currency: AppCurrencies.defaultCode,
        icon: 'cash',
        color: 0xFF00A86B,
        ledgerId: targetLedgerId,
      );

      await accRepo.createAccount(
        name: 'Tài khoản Ngân hàng',
        type: AccountType.bank,
        initialBalance: 5000000,
        currency: AppCurrencies.defaultCode,
        icon: 'bank',
        color: 0xFF007AFF,
        ledgerId: targetLedgerId,
      );

      ref
          .read(activeLedgerIdProvider.notifier)
          .selectLedger(targetLedgerId, ensureWallet: false);

      // 4. Set default wallet ID
      final cashAccount = cashRes.valueOrNull;
      if (cashAccount != null) {
        await ref
            .read(settingsControllerProvider.notifier)
            .setDefaultWalletId(cashAccount.id);
      }

      // 5. Mark initial setup completed
      await ref
          .read(settingsControllerProvider.notifier)
          .completeInitialSetup(uid: uid);

      state = const AsyncData(null);
      return const Success(null);
    } catch (e, st) {
      state = AsyncError(e, st);
      return Failure(UnexpectedException(e.toString()));
    }
  }

  /// Completes the 2-step onboarding wizard for a new user:
  /// 1. Creates primary ledger & seeds default categories.
  /// 2. Creates the user's first wallet (Account) and sets it as default wallet.
  /// 3. Optionally creates an overall monthly budget (if [monthlyBudgetAmount] > 0).
  /// 4. Marks initial setup completed in settings.
  Future<Result<void>> completeInitialOnboarding({
    required String walletName,
    required AccountType walletType,
    required int initialBalance,
    required String icon,
    required int color,
    required String currency,
    int? monthlyBudgetAmount,
    int budgetAlertThreshold = 80,
    String? uid,
  }) async {
    state = const AsyncLoading();
    try {
      final accRepo = ref.read(accountRepositoryProvider);
      final ledgerRepo = ref.read(ledgerRepositoryProvider);
      final catRepo = ref.read(categoryRepositoryProvider);
      final budgetRepo = ref.read(budgetRepositoryProvider);

      // 1. Seed categories
      await catRepo.seedDefaultCategoriesIfNeeded();

      // 2. Ensure Personal & Family ledgers exist
      final now = DateTime.now();

      final personalLedger = LedgerBook(
        id: LedgerBook.defaultPersonalId,
        name: 'Sổ Cá Nhân',
        type: LedgerType.personal,
        icon: 'person',
        color: 0xFF00A86B,
        currency: currency,
        isDefault: true,
        createdAt: now,
        updatedAt: now,
      );
      final personalRes = await ledgerRepo.createLedger(personalLedger);
      if (personalRes.isFailure) {
        state = AsyncError(personalRes.errorOrNull!, StackTrace.current);
        return Failure(personalRes.errorOrNull!);
      }
      final targetLedgerId =
          personalRes.valueOrNull?.id ?? LedgerBook.defaultPersonalId;

      final familyLedger = LedgerBook(
        id: 'default_family',
        name: 'Sổ Gia Đình',
        type: LedgerType.family,
        icon: 'family',
        color: 0xFF007AFF,
        currency: currency,
        isDefault: false,
        createdAt: now,
        updatedAt: now,
      );
      await ledgerRepo.createLedger(familyLedger);

      // Clean up any pre-existing 0-balance placeholder cash wallet before creating the user's wallet
      final existingAccounts = await accRepo.getAccounts(includeArchived: true);
      for (final acc in existingAccounts) {
        if (acc.ledgerId == targetLedgerId &&
            (acc.id == 'default_cash_wallet' ||
                acc.id.startsWith('default_cash_wallet_')) &&
            acc.balance == 0) {
          await accRepo.softDeleteAccount(acc.id);
        }
      }

      // 3. Create the user's first wallet
      final resolvedName = walletName.trim().isEmpty ? 'Tiền mặt' : walletName.trim();
      final createdWalletRes = await accRepo.createAccount(
        name: resolvedName,
        type: walletType,
        initialBalance: initialBalance,
        currency: currency,
        icon: icon,
        color: color,
        ledgerId: targetLedgerId,
      );
      if (createdWalletRes.isFailure) {
        state = AsyncError(createdWalletRes.errorOrNull!, StackTrace.current);
        return Failure(createdWalletRes.errorOrNull!);
      }

      final createdWallet = createdWalletRes.valueOrNull!;
      await ref
          .read(settingsControllerProvider.notifier)
          .setDefaultWalletId(createdWallet.id);

      // 4. Create initial monthly budget if user specified one
      if (monthlyBudgetAmount != null && monthlyBudgetAmount > 0) {
        final monthStart = DateTime(now.year, now.month, 1);
        final budgetRes = await budgetRepo.upsertMonthlyBudget(
          categoryId: null, // overall monthly budget
          amount: monthlyBudgetAmount,
          currency: currency,
          monthStart: monthStart,
          alertThreshold: budgetAlertThreshold,
          ledgerId: targetLedgerId,
        );
        if (budgetRes.isFailure) {
          state = AsyncError(budgetRes.errorOrNull!, StackTrace.current);
          return Failure(budgetRes.errorOrNull!);
        }
        ref.read(selectedBudgetMonthProvider.notifier).setMonth(monthStart);
      }

      ref
          .read(activeLedgerIdProvider.notifier)
          .selectLedger(targetLedgerId, ensureWallet: false);

      // 5. Complete initial setup
      await ref
          .read(settingsControllerProvider.notifier)
          .completeInitialSetup(uid: uid);

      state = const AsyncData(null);
      return const Success(null);
    } catch (e, st) {
      state = AsyncError(e, st);
      return Failure(UnexpectedException(e.toString()));
    }
  }

  Future<Result<void>> skipAndFinish({
    String? uid,
    String currency = AppCurrencies.defaultCode,
  }) async {
    state = const AsyncLoading();
    try {
      final accRepo = ref.read(accountRepositoryProvider);
      final ledgerRepo = ref.read(ledgerRepositoryProvider);
      final catRepo = ref.read(categoryRepositoryProvider);

      await ledgerRepo.ensureDefaultLedgers();
      await catRepo.seedDefaultCategoriesIfNeeded();
      await accRepo.ensureDefaultWallet(
        currency: currency,
        ledgerId: LedgerBook.defaultPersonalId,
      );

      await ref
          .read(settingsControllerProvider.notifier)
          .completeInitialSetup(uid: uid);

      state = const AsyncData(null);
      return const Success(null);
    } catch (e, st) {
      state = AsyncError(e, st);
      return Failure(UnexpectedException(e.toString()));
    }
  }

  Future<Result<void>> completeCustomSetup({
    required LedgerBook primaryLedger,
    required List<InitialSetupWalletDraft> enabledWallets,
    required String defaultWalletKey,
    String? uid,
  }) async {
    state = const AsyncLoading();
    try {
      final accRepo = ref.read(accountRepositoryProvider);
      final ledgerRepo = ref.read(ledgerRepositoryProvider);
      final catRepo = ref.read(categoryRepositoryProvider);

      // 1. Seed categories
      await catRepo.seedDefaultCategoriesIfNeeded();

      // 2. Create primary ledger
      final primaryRes = await ledgerRepo.createLedger(primaryLedger);
      final targetLedgerId = primaryRes.valueOrNull?.id ?? primaryLedger.id;

      // Also create family ledger if primary is personal
      if (primaryLedger.type == LedgerType.personal) {
        final familyLedger = LedgerBook(
          id: 'default_family',
          name: 'Sổ Gia Đình',
          type: LedgerType.family,
          icon: 'family',
          color: 0xFF007AFF,
          currency: primaryLedger.currency,
          isDefault: false,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        await ledgerRepo.createLedger(familyLedger);
      }

      // 3. Create configured wallets
      String? resolvedDefaultWalletId;
      for (final draft in enabledWallets) {
        final res = await accRepo.createAccount(
          name: draft.name,
          type: draft.type,
          initialBalance: draft.initialBalance,
          currency: primaryLedger.currency,
          icon: draft.icon,
          color: draft.color,
          ledgerId: targetLedgerId,
        );

        if (res.isSuccess) {
          final created = res.valueOrNull!;
          if (draft.key == defaultWalletKey ||
              resolvedDefaultWalletId == null) {
            resolvedDefaultWalletId = created.id;
          }
        }
      }

      // Fallback wallet if none was enabled
      if (resolvedDefaultWalletId == null) {
        await accRepo.ensureDefaultWallet(
          currency: primaryLedger.currency,
          ledgerId: targetLedgerId,
        );
        resolvedDefaultWalletId =
            targetLedgerId == LedgerBook.defaultPersonalId
                ? 'default_cash_wallet'
                : 'default_cash_wallet_$targetLedgerId';
      }

      ref
          .read(activeLedgerIdProvider.notifier)
          .selectLedger(targetLedgerId, ensureWallet: false);

      // 4. Save default wallet id
      await ref
          .read(settingsControllerProvider.notifier)
          .setDefaultWalletId(resolvedDefaultWalletId);

      // 5. Complete initial setup
      await ref
          .read(settingsControllerProvider.notifier)
          .completeInitialSetup(uid: uid);

      state = const AsyncData(null);
      return const Success(null);
    } catch (e, st) {
      state = AsyncError(e, st);
      return Failure(UnexpectedException(e.toString()));
    }
  }
}

final initialSetupControllerProvider =
    NotifierProvider<InitialSetupController, AsyncValue<void>>(
      InitialSetupController.new,
    );
