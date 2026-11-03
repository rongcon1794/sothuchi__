import 'package:so_thu_chi/core/errors/result.dart';
import 'package:so_thu_chi/features/accounts/domain/entities/account.dart';

abstract interface class AccountRepository {
  Stream<List<Account>> watchAccounts({bool includeArchived = true});
  Future<List<Account>> getAccounts({bool includeArchived = true});
  Future<Result<Account>> createAccount({
    required String name,
    required AccountType type,
    required int initialBalance,
    required String currency,
    required String icon,
    required int color,
  });
  Future<Result<Account>> updateAccount(Account account);
  Future<Result<void>> setArchived({
    required String accountId,
    required bool archived,
  });
  Future<Result<void>> softDeleteAccount(String accountId);
  Future<Result<void>> transferBetweenAccounts({
    required String fromAccountId,
    required String toAccountId,
    required int amountMinorUnits,
    required String currency,
    String note = '',
    DateTime? date,
  });
  Future<Result<void>> ensureDefaultWallet({required String currency});
}
