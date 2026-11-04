import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:so_thu_chi/core/theme/apple_theme_tokens.dart';
import 'package:so_thu_chi/core/widgets/apple_kit.dart';
import 'package:so_thu_chi/features/ledger/domain/entities/ledger_book.dart';
import 'package:so_thu_chi/features/ledger/presentation/controllers/ledgers_controller.dart';
import 'package:so_thu_chi/features/ledger/presentation/widgets/ledger_form_sheet.dart';

class LedgerSwitcherSheet extends ConsumerWidget {
  const LedgerSwitcherSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const LedgerSwitcherSheet(),
    );
  }

  IconData _resolveIcon(String iconKey) {
    switch (iconKey) {
      case 'family':
        return CupertinoIcons.person_3_fill;
      case 'briefcase':
        return CupertinoIcons.briefcase_fill;
      case 'wallet':
        return CupertinoIcons.creditcard_fill;
      case 'star':
        return CupertinoIcons.star_fill;
      case 'person':
      default:
        return CupertinoIcons.person_crop_circle_fill;
    }
  }

  String _typeLabel(LedgerType type) {
    switch (type) {
      case LedgerType.personal:
        return 'Cá nhân';
      case LedgerType.family:
        return 'Gia đình';
      case LedgerType.business:
        return 'Kinh doanh / Dự án';
      case LedgerType.custom:
        return 'Tùy chỉnh';
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final ledgersAsync = ref.watch(ledgersStreamProvider);
    final activeId = ref.watch(activeLedgerIdProvider);

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.75,
      ),
      decoration: BoxDecoration(
        color: isDark ? AppleTokens.bgDarkCard : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(AppleTokens.radiusSheet)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag handle
            Container(
              margin: const EdgeInsets.symmetric(vertical: 10),
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: isDark ? Colors.white.withValues(alpha: 0.2) : Colors.black.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 16, 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Chuyển Sổ Thu Chi',
                          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        const Text(
                          'Phân tách tài chính cá nhân, gia đình và công việc',
                          style: TextStyle(fontSize: 12, color: AppleTokens.systemGray),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(CupertinoIcons.xmark_circle_fill, color: AppleTokens.systemGray),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),

            Flexible(
              child: ledgersAsync.when(
                loading: () => const Center(child: CupertinoActivityIndicator()),
                error: (err, _) => Center(child: Text('Lỗi: $err')),
                data: (ledgers) {
                  return ListView(
                    shrinkWrap: true,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    children: [
                      for (final ledger in ledgers) ...[
                        _LedgerItemCard(
                          ledger: ledger,
                          isSelected: ledger.id == activeId,
                          icon: _resolveIcon(ledger.icon),
                          typeLabel: _typeLabel(ledger.type),
                          onTap: () {
                            unawaited(HapticFeedback.selectionClick());
                            ref.read(ledgersActionControllerProvider.notifier).switchLedger(ledger.id);
                            Navigator.of(context).pop();
                          },
                        ),
                        const SizedBox(height: 10),
                      ],
                      const SizedBox(height: 10),

                      // Add new ledger button
                      ApplePressable(
                        onTap: () {
                          Navigator.of(context).pop();
                          LedgerFormSheet.show(context);
                        },
                        borderRadius: BorderRadius.circular(AppleTokens.radiusCard),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(AppleTokens.radiusCard),
                            border: Border.all(
                              color: isDark ? AppleTokens.bgDarkTertiary : AppleTokens.borderLight,
                              width: 1,
                            ),
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(CupertinoIcons.plus_circle_fill, color: AppleTokens.jadePrimary, size: 20),
                              SizedBox(width: 8),
                              Text(
                                'Thêm Sổ Thu Chi Mới',
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: AppleTokens.jadePrimary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LedgerItemCard extends StatelessWidget {
  const _LedgerItemCard({
    required this.ledger,
    required this.isSelected,
    required this.icon,
    required this.typeLabel,
    required this.onTap,
  });

  final LedgerBook ledger;
  final bool isSelected;
  final IconData icon;
  final String typeLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final color = Color(ledger.color);

    return ApplePressable(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppleTokens.radiusCard),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark ? AppleTokens.bgDarkSecondary : AppleTokens.bgLightSecondary)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(AppleTokens.radiusCard),
          border: Border.all(
            color: isSelected ? color : (isDark ? AppleTokens.bgDarkTertiary : AppleTokens.borderLight),
            width: isSelected ? 1.8 : 1.0,
          ),
        ),
        child: Row(
          children: [
            AppleSquircleBadge(
              icon: icon,
              backgroundColor: color,
              size: 42,
              iconSize: 22,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        ledger.name,
                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                      ),
                      if (ledger.isDefault) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'Mặc định',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: color,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    typeLabel,
                    style: const TextStyle(fontSize: 12, color: AppleTokens.systemGray),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(CupertinoIcons.checkmark_circle_fill, color: color, size: 24)
            else
              const Icon(CupertinoIcons.circle, color: AppleTokens.systemGray, size: 22),
          ],
        ),
      ),
    );
  }
}
