import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:so_thu_chi/core/constants/currency_constants.dart';
import 'package:so_thu_chi/core/errors/result.dart';
import 'package:so_thu_chi/core/utils/money.dart';
import 'package:so_thu_chi/data/providers/repository_providers.dart';
import 'package:so_thu_chi/features/accounts/domain/entities/account.dart';
import 'package:so_thu_chi/features/ledger/presentation/controllers/ledgers_controller.dart';
import 'package:so_thu_chi/features/settings/presentation/controllers/settings_controller.dart';

/// Streams all non-deleted accounts from the repository across all ledgers.
final rawAccountsStreamProvider = StreamProvider<List<Account>>((ref) {
  return ref.watch(accountRepositoryProvider).watchAccounts();
});

/// Streams all non-deleted accounts (both active and archived) for the currently active ledger.
final accountsStreamProvider = Provider<AsyncValue<List<Account>>>((ref) {
  final activeLedgerId = ref.watch(activeLedgerIdProvider);
  final rawAsync = ref.watch(rawAccountsStreamProvider);
  return rawAsync.whenData(
    (all) => all.where((a) => a.ledgerId == activeLedgerId).toList(growable: false),
  );
});

/// Active (non-archived) accounts list.
final activeAccountsProvider = Provider<List<Account>>((ref) {
  final all = ref.watch(accountsStreamProvider).value ?? const <Account>[];
  return all.where((a) => !a.archived).toList(growable: false);
});

/// Archived accounts list.
final archivedAccountsProvider = Provider<List<Account>>((ref) {
  final all = ref.watch(accountsStreamProvider).value ?? const <Account>[];
  return all.where((a) => a.archived).toList(growable: false);
});

/// Total net balance across active wallets matching the selected default currency.
final totalNetBalanceProvider = Provider<Money>((ref) {
  final currency = ref.watch(
    settingsControllerProvider.select(
      (s) => s.value?.currencyCode ?? AppCurrencies.defaultCode,
    ),
  );
  final active = ref.watch(activeAccountsProvider);
  var sum = 0;
  for (final account in active) {
    if (account.currency == currency) {
      sum += account.balance;
    }
  }
  return Money(minorUnits: sum, currencyCode: currency);
});

class AccountsActionController extends Notifier<AsyncValue<void>> {
  @override
  AsyncValue<void> build() => const AsyncData(null);

  Future<Result<Account>> createWallet({
    required String name,
    required AccountType type,
    required int initialBalance,
    required String currency,
    required String icon,
    required int color,
    String? ledgerId,
  }) async {
    state = const AsyncLoading();
    final effectiveLedgerId = ledgerId ?? ref.read(activeLedgerIdProvider);
    final res = await ref
        .read(accountRepositoryProvider)
        .createAccount(
          name: name,
          type: type,
          initialBalance: initialBalance,
          currency: currency,
          icon: icon,
          color: color,
          ledgerId: effectiveLedgerId,
        );
    state = res.fold(
      onSuccess: (_) => const AsyncData(null),
      onFailure: (e) => AsyncError(e, StackTrace.current),
    );
    return res;
  }

  Future<Result<Account>> updateWallet(Account account) async {
    state = const AsyncLoading();
    final res = await ref
        .read(accountRepositoryProvider)
        .updateAccount(account);
    state = res.fold(
      onSuccess: (_) => const AsyncData(null),
      onFailure: (e) => AsyncError(e, StackTrace.current),
    );
    return res;
  }

  Future<Result<void>> toggleArchive({
    required String accountId,
    required bool archived,
  }) async {
    state = const AsyncLoading();
    final res = await ref
        .read(accountRepositoryProvider)
        .setArchived(accountId: accountId, archived: archived);
    state = res.fold(
      onSuccess: (_) => const AsyncData(null),
      onFailure: (e) => AsyncError(e, StackTrace.current),
    );
    return res;
  }

  Future<Result<void>> deleteWallet(String accountId) async {
    state = const AsyncLoading();
    final res = await ref
        .read(accountRepositoryProvider)
        .softDeleteAccount(accountId);
    state = res.fold(
      onSuccess: (_) => const AsyncData(null),
      onFailure: (e) => AsyncError(e, StackTrace.current),
    );
    return res;
  }

  Future<Result<void>> transfer({
    required String fromAccountId,
    required String toAccountId,
    required int amountMinorUnits,
    required String currency,
    String note = '',
    DateTime? date,
  }) async {
    state = const AsyncLoading();
    final res = await ref
        .read(accountRepositoryProvider)
        .transferBetweenAccounts(
          fromAccountId: fromAccountId,
          toAccountId: toAccountId,
          amountMinorUnits: amountMinorUnits,
          currency: currency,
          note: note,
          date: date,
        );
    state = res.fold(
      onSuccess: (_) => const AsyncData(null),
      onFailure: (e) => AsyncError(e, StackTrace.current),
    );
    return res;
  }
}

final accountsActionControllerProvider =
    NotifierProvider<AccountsActionController, AsyncValue<void>>(
      AccountsActionController.new,
    );

