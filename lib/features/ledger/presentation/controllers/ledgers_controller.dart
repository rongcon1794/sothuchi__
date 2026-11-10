import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:so_thu_chi/core/errors/result.dart';
import 'package:so_thu_chi/data/firebase/firebase_providers.dart';
import 'package:so_thu_chi/data/providers/repository_providers.dart';
import 'package:so_thu_chi/features/ledger/domain/entities/ledger_book.dart';
import 'package:so_thu_chi/features/ledger/domain/repositories/ledger_repository.dart';

final ledgersStreamProvider = StreamProvider<List<LedgerBook>>((ref) {
  final repo = ref.watch(ledgerRepositoryProvider);
  return repo.watchLedgers();
});

class ActiveLedgerIdController extends Notifier<String> {
  static const _prefKey = 'active_ledger_id';

  @override
  String build() {
    String initialId = LedgerBook.defaultPersonalId;
    try {
      final prefs = ref.watch(sharedPreferencesProvider);
      initialId = prefs.getString(_prefKey) ?? LedgerBook.defaultPersonalId;
    } catch (_) {}

    // Listen to ledgersStreamProvider: when Firestore/cloud ledgers load,
    // if current active ledger doesn't exist in the loaded ledgers,
    // auto-select the user's default ledger or first ledger so they never get
    // stranded on an unlinked phantom ledger.
    ref.listen<AsyncValue<List<LedgerBook>>>(ledgersStreamProvider, (_, next) {
      final list = next.value;
      if (list != null && list.isNotEmpty) {
        final matches = list.any((l) => l.id == state);
        if (!matches) {
          final target =
              list.where((l) => l.isDefault).firstOrNull ?? list.first;
          selectLedger(target.id);
        }
      }
    });

    // Check if ledgers are already loaded synchronously
    final currentList = ref.read(ledgersStreamProvider).value;
    if (currentList != null && currentList.isNotEmpty) {
      if (!currentList.any((l) => l.id == initialId)) {
        final target =
            currentList.where((l) => l.isDefault).firstOrNull ?? currentList.first;
        initialId = target.id;
        try {
          final prefs = ref.read(sharedPreferencesProvider);
          prefs.setString(_prefKey, initialId);
        } catch (_) {}
      }
    }

    return initialId;
  }

  void selectLedger(String id, {bool ensureWallet = false}) {
    if (state != id) {
      state = id;
    }
    try {
      final prefs = ref.read(sharedPreferencesProvider);
      prefs.setString(_prefKey, id);
    } catch (_) {}
  }
}

final activeLedgerIdProvider =
    NotifierProvider<ActiveLedgerIdController, String>(
  ActiveLedgerIdController.new,
);

final activeLedgerProvider = Provider<LedgerBook>((ref) {
  final id = ref.watch(activeLedgerIdProvider);
  final ledgers = ref.watch(ledgersStreamProvider).value ?? const [];
  for (final l in ledgers) {
    if (l.id == id) return l;
  }
  return ledgers.isNotEmpty ? ledgers.first : LedgerBook.defaultPersonal();
});

class LedgersActionController extends Notifier<AsyncValue<void>> {
  @override
  AsyncValue<void> build() => const AsyncData(null);

  LedgerRepository get _repository => ref.read(ledgerRepositoryProvider);

  Future<Result<LedgerBook>> createLedger(LedgerBook ledger) async {
    state = const AsyncLoading();
    final res = await _repository.createLedger(ledger);
    if (res.isSuccess) {
      state = const AsyncData(null);
      ref.read(activeLedgerIdProvider.notifier).selectLedger(res.valueOrNull!.id);
    } else {
      state = AsyncError(res.errorOrNull!, StackTrace.current);
    }
    return res;
  }

  Future<Result<LedgerBook>> updateLedger(LedgerBook ledger) async {
    state = const AsyncLoading();
    final res = await _repository.updateLedger(ledger);
    state = res.isSuccess
        ? const AsyncData(null)
        : AsyncError(res.errorOrNull!, StackTrace.current);
    return res;
  }

  Future<Result<void>> deleteLedger(String id) async {
    state = const AsyncLoading();
    final res = await _repository.deleteLedger(id);
    if (res.isSuccess) {
      state = const AsyncData(null);
      final current = ref.read(activeLedgerIdProvider);
      if (current == id) {
        ref
            .read(activeLedgerIdProvider.notifier)
            .selectLedger(LedgerBook.defaultPersonalId);
      }
    } else {
      state = AsyncError(res.errorOrNull!, StackTrace.current);
    }
    return res;
  }

  void switchLedger(String id) {
    ref.read(activeLedgerIdProvider.notifier).selectLedger(id);
  }
}

final ledgersActionControllerProvider =
    NotifierProvider<LedgersActionController, AsyncValue<void>>(
  LedgersActionController.new,
);

