import 'package:flutter_riverpod/flutter_riverpod.dart';

enum SyncStatus { synced, syncing, offline }

abstract interface class SyncStatusService {
  Stream<SyncStatus> watchSyncStatus();
}

class SyncedSyncStatusService implements SyncStatusService {
  const SyncedSyncStatusService();

  @override
  Stream<SyncStatus> watchSyncStatus() => Stream<SyncStatus>.value(SyncStatus.synced);
}

final syncStatusServiceProvider = Provider<SyncStatusService>((ref) {
  return const SyncedSyncStatusService();
});

final syncStatusStreamProvider = StreamProvider<SyncStatus>((ref) {
  return ref.watch(syncStatusServiceProvider).watchSyncStatus();
});
