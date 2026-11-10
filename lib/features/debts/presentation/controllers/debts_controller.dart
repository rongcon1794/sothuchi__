import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:so_thu_chi/core/constants/currency_constants.dart';
import 'package:so_thu_chi/core/errors/result.dart';
import 'package:so_thu_chi/core/utils/money.dart';
import 'package:so_thu_chi/data/providers/repository_providers.dart';
import 'package:so_thu_chi/features/debts/domain/entities/debt.dart';
import 'package:so_thu_chi/features/settings/presentation/controllers/settings_controller.dart';
import 'package:so_thu_chi/l10n/app_localizations.dart';

enum DebtFilterMode {
  all,
  lent,
  borrowed,
  settled;

  String label(AppLocalizations l10n) => switch (this) {
        DebtFilterMode.all => l10n.debtFilterAll,
        DebtFilterMode.lent => l10n.debtFilterLent,
        DebtFilterMode.borrowed => l10n.debtFilterBorrowed,
        DebtFilterMode.settled => l10n.debtFilterSettled,
      };

  String get labelVi => switch (this) {
        DebtFilterMode.all => 'Tất cả',
        DebtFilterMode.lent => 'Cho vay',
        DebtFilterMode.borrowed => 'Đi vay',
        DebtFilterMode.settled => 'Đã trả xong',
      };
}

class DebtFilterModeController extends Notifier<DebtFilterMode> {
  @override
  DebtFilterMode build() => DebtFilterMode.all;

  void setMode(DebtFilterMode mode) => state = mode;
}

final debtFilterModeProvider =
    NotifierProvider<DebtFilterModeController, DebtFilterMode>(
  DebtFilterModeController.new,
);

final debtsStreamProvider = StreamProvider<List<Debt>>((ref) {
  return ref.watch(debtRepositoryProvider).watchDebts();
});

final filteredDebtsProvider = Provider<List<Debt>>((ref) {
  final all = ref.watch(debtsStreamProvider).value ?? const <Debt>[];
  final filter = ref.watch(debtFilterModeProvider);

  return all.where((d) {
    return switch (filter) {
      DebtFilterMode.all => !d.isSettled,
      DebtFilterMode.lent => d.type == DebtType.lent && !d.isSettled,
      DebtFilterMode.borrowed => d.type == DebtType.borrowed && !d.isSettled,
      DebtFilterMode.settled => d.isSettled,
    };
  }).toList(growable: false);
});

final debtSummaryProvider = Provider<DebtSummary>((ref) {
  final all = ref.watch(debtsStreamProvider).value ?? const <Debt>[];
  final currency = ref.watch(
    settingsControllerProvider.select(
      (s) => s.value?.currencyCode ?? AppCurrencies.defaultCode,
    ),
  );

  var totalLentMinor = 0;
  var totalBorrowedMinor = 0;
  var overdueCount = 0;

  for (final d in all) {
    if (d.currency != currency || d.isSettled) continue;
    if (d.isOverdue) overdueCount++;

    if (d.type == DebtType.lent) {
      totalLentMinor += d.remainingAmount;
    } else {
      totalBorrowedMinor += d.remainingAmount;
    }
  }

  return DebtSummary(
    totalLent: Money(minorUnits: totalLentMinor, currencyCode: currency),
    totalBorrowed:
        Money(minorUnits: totalBorrowedMinor, currencyCode: currency),
    netBalance: Money(
      minorUnits: totalLentMinor - totalBorrowedMinor,
      currencyCode: currency,
    ),
    overdueCount: overdueCount,
  );
});

class DebtsActionController extends Notifier<AsyncValue<void>> {
  @override
  AsyncValue<void> build() => const AsyncData(null);

  Future<Result<Debt>> addDebt({
    required String personName,
    String? phoneNumber,
    required DebtType type,
    required int amount,
    String? currency,
    DateTime? dueDate,
    String? accountId,
    String note = '',
  }) async {
    state = const AsyncLoading();
    final res = await ref.read(debtRepositoryProvider).addDebt(
          personName: personName,
          phoneNumber: phoneNumber,
          type: type,
          amount: amount,
          currency: currency,
          dueDate: dueDate,
          accountId: accountId,
          note: note,
        );
    state = res.fold(
      onSuccess: (_) => const AsyncData(null),
      onFailure: (e) => AsyncError(e, StackTrace.current),
    );
    return res;
  }

  Future<Result<Debt>> updateDebt(Debt debt) async {
    state = const AsyncLoading();
    final res = await ref.read(debtRepositoryProvider).updateDebt(debt);
    state = res.fold(
      onSuccess: (_) => const AsyncData(null),
      onFailure: (e) => AsyncError(e, StackTrace.current),
    );
    return res;
  }

  Future<Result<void>> recordRepayment({
    required String debtId,
    required int amount,
    String? accountId,
    String note = '',
  }) async {
    state = const AsyncLoading();
    final res = await ref.read(debtRepositoryProvider).recordRepayment(
          debtId: debtId,
          amount: amount,
          accountId: accountId,
          note: note,
        );
    state = res.fold(
      onSuccess: (_) => const AsyncData(null),
      onFailure: (e) => AsyncError(e, StackTrace.current),
    );
    return res;
  }

  Future<Result<void>> deleteDebt(String id) async {
    state = const AsyncLoading();
    final res = await ref.read(debtRepositoryProvider).softDeleteDebt(id);
    state = res.fold(
      onSuccess: (_) => const AsyncData(null),
      onFailure: (e) => AsyncError(e, StackTrace.current),
    );
    return res;
  }
}

final debtsActionControllerProvider =
    NotifierProvider<DebtsActionController, AsyncValue<void>>(
  DebtsActionController.new,
);
