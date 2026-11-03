import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:so_thu_chi/core/contracts/sync_status.dart';
import 'package:so_thu_chi/core/l10n/l10n_ext.dart';
import 'package:so_thu_chi/core/theme/app_theme.dart';

/// Compact, accessible banner shown at the top of the app shell whenever
/// the device is offline or Firestore has pending local writes syncing to cloud.
class OfflineSyncBanner extends ConsumerWidget {
  const OfflineSyncBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status =
        ref.watch(syncStatusStreamProvider).value ?? SyncStatus.synced;

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 220),
      child: switch (status) {
        SyncStatus.synced => const SizedBox.shrink(key: ValueKey('synced')),
        SyncStatus.offline => _BannerBar(
          key: const ValueKey('offline'),
          icon: Icons.cloud_off_rounded,
          label: context.l10n.offlineIndicator,
          backgroundColor: context.financeColors.warningContainer,
          foregroundColor: context.financeColors.onWarningContainer,
        ),
        SyncStatus.syncing => _BannerBar(
          key: const ValueKey('syncing'),
          icon: Icons.cloud_sync_rounded,
          label: context.l10n.syncingIndicator,
          backgroundColor: context.financeColors.transferContainer,
          foregroundColor: context.financeColors.onTransferContainer,
        ),
      },
    );
  }
}

class _BannerBar extends StatelessWidget {
  const _BannerBar({
    super.key,
    required this.icon,
    required this.label,
    required this.backgroundColor,
    required this.foregroundColor,
  });

  final IconData icon;
  final String label;
  final Color backgroundColor;
  final Color foregroundColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Semantics(
      container: true,
      liveRegion: true,
      child: Material(
        color: backgroundColor,
        child: SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 16, color: foregroundColor),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    label,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: foregroundColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
