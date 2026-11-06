import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:so_thu_chi/core/l10n/l10n_ext.dart';
import 'package:so_thu_chi/core/responsive/apple_responsive.dart';
import 'package:so_thu_chi/core/theme/apple_theme_tokens.dart';
import 'package:so_thu_chi/core/widgets/apple_kit.dart';
import 'package:so_thu_chi/features/ledger/domain/entities/ledger_book.dart';
import 'package:so_thu_chi/features/ledger/presentation/controllers/ledgers_controller.dart';
import 'package:so_thu_chi/features/ledger/presentation/widgets/ledger_form_sheet.dart';
import 'package:so_thu_chi/l10n/app_localizations.dart';

class LedgersManagementScreen extends ConsumerStatefulWidget {
  const LedgersManagementScreen({super.key});

  @override
  ConsumerState<LedgersManagementScreen> createState() =>
      _LedgersManagementScreenState();
}

class _LedgersManagementScreenState
    extends ConsumerState<LedgersManagementScreen> {
  bool _isFabExpanded = true;
  bool _isFabVisible = true;

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

  String _typeLabel(LedgerType type, AppLocalizations l10n) {
    switch (type) {
      case LedgerType.personal:
        return l10n.ledgerPersonal;
      case LedgerType.family:
        return l10n.ledgerFamily;
      case LedgerType.business:
        return l10n.ledgerBusiness;
      case LedgerType.custom:
        return l10n.ledgerCustom;
    }
  }

  Future<void> _confirmDelete(BuildContext context, LedgerBook ledger) async {
    final l10n = context.l10n;
    final confirmed = await showCupertinoModalPopup<bool>(
      context: context,
      builder: (ctx) => CupertinoActionSheet(
        title: Text(l10n.ledgerDeleteConfirmTitle(ledger.name)),
        message: Text(l10n.ledgerDeleteConfirmBody),
        actions: [
          CupertinoActionSheetAction(
            isDestructiveAction: true,
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(l10n.delete),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.of(ctx).pop(false),
          child: Text(l10n.cancel),
        ),
      ),
    );

    if (confirmed == true && context.mounted) {
      unawaited(HapticFeedback.mediumImpact());
      await ref.read(ledgersActionControllerProvider.notifier).deleteLedger(ledger.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final l10n = context.l10n;
    final isLandscape = context.isLandscape;
    final isWide = context.isWideScreen;
    final appBarHeight = isLandscape
        ? AppleTokens.appBarHeightLandscape
        : AppleTokens.appBarHeightPortrait;
    final scrollBottomPadding = isWide
        ? AppleTokens.scrollBottomPaddingLandscape + 54
        : AppleTokens.scrollBottomPaddingWithFab;

    final ledgersAsync = ref.watch(ledgersStreamProvider);
    final activeId = ref.watch(activeLedgerIdProvider);

    return Scaffold(
      backgroundColor: isDark ? AppleTokens.bgDarkPrimary : AppleTokens.bgLightPrimary,
      appBar: AppBar(
        toolbarHeight: appBarHeight,
        title: Text(l10n.ledgersTitle, style: const TextStyle(fontWeight: FontWeight.w700)),
        centerTitle: false,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(CupertinoIcons.chevron_left, size: 24),
          onPressed: () => context.pop(),
        ),
      ),
      floatingActionButtonLocation: const AppleFloatingActionButtonLocation(),
      floatingActionButton: AppleAdaptiveExpandableFab(
        heroTag: 'ledger_add_fab',
        isVisible: _isFabVisible,
        isExpanded: _isFabExpanded,
        icon: const Icon(CupertinoIcons.plus),
        label: Text(l10n.ledgerNew),
        backgroundColor: AppleTokens.jadeDark,
        onPressed: () {
          unawaited(HapticFeedback.lightImpact());
          LedgerFormSheet.show(context);
        },
        tooltip: l10n.ledgerNewTitle,
      ),
      body: ledgersAsync.when(
        loading: () => const Center(child: CupertinoActivityIndicator()),
        error: (err, _) => Center(child: Text('Lỗi: $err')),
        data: (ledgers) {
          return NotificationListener<UserScrollNotification>(
            onNotification: (notification) {
              if (notification.direction == ScrollDirection.reverse) {
                if (_isFabVisible) {
                  setState(() {
                    _isFabVisible = false;
                    _isFabExpanded = false;
                  });
                }
              } else if (notification.direction == ScrollDirection.forward) {
                if (!_isFabVisible) {
                  setState(() => _isFabVisible = true);
                }
              } else if (notification.metrics.pixels <= 30) {
                if (!_isFabVisible || !_isFabExpanded) {
                  setState(() {
                    _isFabVisible = true;
                    _isFabExpanded = true;
                  });
                }
              }
              return false;
            },
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 860),
                child: ListView(
                  padding: EdgeInsets.fromLTRB(16, 8, 16, scrollBottomPadding),
                  children: [
                // Info Card
                AppleGlassCard(
                  borderRadius: BorderRadius.circular(AppleTokens.radiusHero),
                  padding: const EdgeInsets.all(16),
                  gradient: LinearGradient(
                    colors: isDark
                        ? const [Color(0xFF0F2636), Color(0xFF08151E)]
                        : const [Color(0xFFE0F2FE), Color(0xFFEFF6FF)],
                  ),
                  borderColor: AppleTokens.systemBlue.withValues(alpha: 0.3),
                  child: Row(
                    children: [
                      const AppleSquircleBadge(
                        icon: CupertinoIcons.layers_alt_fill,
                        backgroundColor: AppleTokens.systemBlue,
                        size: 42,
                        iconSize: 22,
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l10n.ledgersTitle.toUpperCase(),
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: AppleTokens.systemBlue,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              l10n.ledgerSwitcherSubtitle,
                              style: const TextStyle(fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
                  child: Text(
                    l10n.ledgerSwitcherTitle.toUpperCase(),
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppleTokens.systemGray,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                for (final item in ledgers) ...[
                  AppleGlassCard(
                    borderRadius: BorderRadius.circular(AppleTokens.radiusCard),
                    borderColor: item.id == activeId
                        ? Color(item.color).withValues(alpha: 0.5)
                        : null,
                    child: Row(
                      children: [
                        AppleSquircleBadge(
                          icon: _resolveIcon(item.icon),
                          backgroundColor: Color(item.color),
                          size: 44,
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
                                    item.name,
                                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                                  ),
                                  if (item.id == activeId) ...[
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: AppleTokens.jadePrimary.withValues(alpha: 0.15),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        l10n.ledgerActiveBadge,
                                        style: const TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w700,
                                          color: AppleTokens.jadePrimary,
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                              const SizedBox(height: 2),
                              Text(
                                _typeLabel(item.type, l10n),
                                style: const TextStyle(fontSize: 12, color: AppleTokens.systemGray),
                              ),
                            ],
                          ),
                        ),
                        PopupMenuButton<String>(
                          icon: const Icon(CupertinoIcons.ellipsis, color: AppleTokens.systemGray, size: 18),
                          onSelected: (val) {
                            if (val == 'select') {
                              ref.read(ledgersActionControllerProvider.notifier).switchLedger(item.id);
                            } else if (val == 'edit') {
                              LedgerFormSheet.show(context, existing: item);
                            } else if (val == 'delete') {
                              _confirmDelete(context, item);
                            }
                          },
                          itemBuilder: (ctx) => [
                            if (item.id != activeId)
                              PopupMenuItem(
                                value: 'select',
                                child: Row(
                                  children: [
                                    const Icon(CupertinoIcons.check_mark, size: 18),
                                    const SizedBox(width: 8),
                                    Text(l10n.ledgerSelectActive),
                                  ],
                                ),
                              ),
                            PopupMenuItem(
                              value: 'edit',
                              child: Row(
                                children: [
                                  const Icon(CupertinoIcons.pencil, size: 18),
                                  const SizedBox(width: 8),
                                  Text(l10n.edit),
                                ],
                              ),
                            ),
                            if (!item.isDefault)
                              PopupMenuItem(
                                value: 'delete',
                                child: Row(
                                  children: [
                                    const Icon(CupertinoIcons.trash, color: AppleTokens.rubyExpense, size: 18),
                                    const SizedBox(width: 8),
                                    Text(l10n.ledgerDelete, style: const TextStyle(color: AppleTokens.rubyExpense)),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
              ],
            ),
          ),
        ),
      );
    },
      ),
    );
  }
}

