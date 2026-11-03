import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:so_thu_chi/core/contracts/sync_status.dart';
import 'package:so_thu_chi/data/firebase/firebase_providers.dart';
import 'package:so_thu_chi/data/providers/repository_providers.dart';

export 'package:so_thu_chi/core/contracts/sync_status.dart';

class FirestoreSyncStatusService implements SyncStatusService {
  FirestoreSyncStatusService({
    required this.firestore,
    required this.uid,
    Connectivity? connectivity,
  }) : _connectivity = connectivity ?? Connectivity();

  final FirebaseFirestore? firestore;
  final String? uid;
  final Connectivity _connectivity;

  @override
  Stream<SyncStatus> watchSyncStatus() {
    late StreamController<SyncStatus> controller;
    StreamSubscription<List<ConnectivityResult>>? connSub;
    final pendingSubs =
        <StreamSubscription<QuerySnapshot<Map<String, dynamic>>>>[];

    var isOffline = false;
    final pendingByCollection = <String, bool>{};

    void emitCurrent() {
      if (controller.isClosed) return;
      final hasPendingWrites = pendingByCollection.values.any((v) => v);
      if (isOffline) {
        controller.add(SyncStatus.offline);
      } else if (hasPendingWrites) {
        controller.add(SyncStatus.syncing);
      } else {
        controller.add(SyncStatus.synced);
      }
    }

    void watchQueryPending(
      String key,
      Query<Map<String, dynamic>> query,
    ) {
      final sub = query.snapshots(includeMetadataChanges: true).listen(
        (snap) {
          pendingByCollection[key] = snap.metadata.hasPendingWrites;
          emitCurrent();
        },
        onError: (_) {
          pendingByCollection[key] = false;
          emitCurrent();
        },
      );
      pendingSubs.add(sub);
    }

    Future<void> start() async {
      emitCurrent();
      try {
        final initial = await _connectivity.checkConnectivity();
        isOffline = initial.contains(ConnectivityResult.none);
        emitCurrent();

        connSub = _connectivity.onConnectivityChanged.listen(
          (results) {
            isOffline = results.contains(ConnectivityResult.none);
            emitCurrent();
          },
          onError: (_) {
            // Gracefully ignore MissingPluginException in headless test environments.
          },
        );
      } on MissingPluginException {
        // Test environment without native connectivity channel.
      } on PlatformException {
        // Platform channel unavailable.
      } catch (_) {
        // Keep safe default `synced`.
      }

      if (firestore != null && uid != null && uid!.isNotEmpty) {
        final userDoc = firestore!.collection('users').doc(uid);
        watchQueryPending(
          'transactions',
          userDoc
              .collection('transactions')
              .where('deletedAt', isNull: true)
              .orderBy('date', descending: true)
              .limit(50),
        );
        watchQueryPending('accounts', userDoc.collection('accounts'));
        watchQueryPending('categories', userDoc.collection('categories'));
        watchQueryPending('budgets', userDoc.collection('budgets'));
      }
    }

    controller = StreamController<SyncStatus>(
      onListen: start,
      onCancel: () async {
        await connSub?.cancel();
        for (final sub in pendingSubs) {
          await sub.cancel();
        }
      },
    );

    return controller.stream.distinct();
  }
}

final firestoreSyncStatusServiceProvider = Provider<SyncStatusService>((ref) {
  final user = ref.watch(currentUserProvider);
  final firestore = ref.watch(firestoreProvider);
  return FirestoreSyncStatusService(
    firestore: (user != null && !user.isDemoUser) ? firestore : null,
    uid: user?.uid,
  );
});
