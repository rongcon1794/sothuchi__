import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:so_thu_chi/core/theme/app_theme.dart';
import 'package:so_thu_chi/core/widgets/offline_sync_banner.dart';
import 'package:so_thu_chi/data/services/sync_status_service.dart';
import 'package:so_thu_chi/l10n/app_localizations.dart';

class FakeSyncStatusService implements SyncStatusService {
  final StreamController<SyncStatus> controller =
      StreamController<SyncStatus>.broadcast();

  @override
  Stream<SyncStatus> watchSyncStatus() => controller.stream;
}

void main() {
  testWidgets(
    'OfflineSyncBanner shows localized offline and syncing indicators and hides when synced',
    (tester) async {
      final fakeSync = FakeSyncStatusService();
      addTearDown(fakeSync.controller.close);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            syncStatusServiceProvider.overrideWithValue(fakeSync),
          ],
          child: MaterialApp(
            locale: const Locale('vi'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            theme: AppTheme.light(),
            home: const Scaffold(body: OfflineSyncBanner()),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Initially synced -> hidden
      expect(
        find.text('Ngoại tuyến — Thay đổi sẽ tự đồng bộ khi có mạng'),
        findsNothing,
      );

      // Emit offline
      fakeSync.controller.add(SyncStatus.offline);
      await tester.pumpAndSettle();
      expect(
        find.text('Ngoại tuyến — Thay đổi sẽ tự đồng bộ khi có mạng'),
        findsOneWidget,
      );

      // Emit syncing
      fakeSync.controller.add(SyncStatus.syncing);
      await tester.pumpAndSettle();
      expect(
        find.text('Đang đồng bộ dữ liệu lên đám mây...'),
        findsOneWidget,
      );

      // Emit synced -> hidden again
      fakeSync.controller.add(SyncStatus.synced);
      await tester.pumpAndSettle();
      expect(
        find.text('Đang đồng bộ dữ liệu lên đám mây...'),
        findsNothing,
      );
    },
  );
}

