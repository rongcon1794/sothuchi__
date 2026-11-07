import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:so_thu_chi/core/constants/currency_constants.dart';
import 'package:so_thu_chi/core/errors/app_exception.dart';
import 'package:so_thu_chi/core/errors/result.dart';
import 'package:so_thu_chi/data/providers/repository_providers.dart';
import 'package:so_thu_chi/features/accounts/domain/entities/account.dart';
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
      await ledgerRepo.createLedger(personalLedger);
      ref.read(activeLedgerIdProvider.notifier).selectLedger(personalLedger.id);

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
        ledgerId: personalLedger.id,
      );

      await accRepo.createAccount(
        name: 'Tài khoản Ngân hàng',
        type: AccountType.bank,
        initialBalance: 5000000,
        currency: AppCurrencies.defaultCode,
        icon: 'bank',
        color: 0xFF007AFF,
        ledgerId: personalLedger.id,
      );

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
      await ledgerRepo.createLedger(primaryLedger);
      ref
          .read(activeLedgerIdProvider.notifier)
          .selectLedger(primaryLedger.id);

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
          ledgerId: primaryLedger.id,
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
          ledgerId: primaryLedger.id,
        );
        resolvedDefaultWalletId = 'default_cash_wallet_${primaryLedger.id}';
      }

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
