import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:so_thu_chi/core/constants/icon_catalog.dart';
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

  IconData _resolveIcon(String iconKey) =>
      AppIconCatalog.resolveLedgerIcon(iconKey);

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

  void _switchLedger(BuildContext context, LedgerBook item) {
    unawaited(HapticFeedback.mediumImpact());
    ref.read(ledgersActionControllerProvider.notifier).switchLedger(item.id);
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(CupertinoIcons.checkmark_alt_circle_fill,
                color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                context.l10n.localeName.startsWith('vi')
                    ? 'Đã chuyển sang sổ: ${item.name}'
                    : 'Switched to ledger: ${item.name}',
              ),
            ),
          ],
        ),
        backgroundColor: AppleTokens.jadeDark,
        duration: const Duration(seconds: 2),
      ),
    );
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
      final res = await ref
          .read(ledgersActionControllerProvider.notifier)
          .deleteLedger(ledger.id);
      if (context.mounted) {
        res.fold(
          onSuccess: (_) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  l10n.localeName.startsWith('vi')
                      ? 'Đã xóa sổ: ${ledger.name}'
                      : 'Deleted ledger: ${ledger.name}',
                ),
                backgroundColor: AppleTokens.rubyExpense,
              ),
            );
          },
          onFailure: (err) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(context.localizeError(err))),
            );
          },
        );
      }
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
        ? AppleTokens.scrollBottomPaddingLandscape + 42
        : AppleTokens.scrollBottomPaddingWithFab;

    final ledgersAsync = ref.watch(ledgersStreamProvider);
    final activeId = ref.watch(activeLedgerIdProvider);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        toolbarHeight: appBarHeight,
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleSpacing: 0,
        leading: const AppleBackButton(),
        title: AppleHeaderTitle(
          title: l10n.ledgersTitle,
          isLandscape: isLandscape,
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
      body: SafeArea(
        top: false,
        bottom: false,
        child: ledgersAsync.when(
          loading: () => const Center(child: CupertinoActivityIndicator()),
          error: (err, _) => Center(child: Text('Lỗi: $err')),
          data: (ledgers) {
            final activeLedger = ledgers.firstWhere(
              (l) => l.id == activeId,
              orElse: () =>
                  ledgers.isNotEmpty ? ledgers.first : LedgerBook.defaultPersonal(),
            );

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
                  constraints: const BoxConstraints(
                    maxWidth: AppleTokens.maxContentWidth,
                  ),
                  child: ListView(
                    physics: const BouncingScrollPhysics(),
                    padding:
                        EdgeInsets.fromLTRB(16, 8, 16, scrollBottomPadding),
                    children: [
                      // 1. Active Ledger Showcase Hero Card
                      _buildActiveLedgerShowcase(
                        context: context,
                        ledger: activeLedger,
                        isDark: isDark,
                        l10n: l10n,
                      ),
                      const SizedBox(height: 16),

                      // 2. Metrics Bar Strip
                      _buildMetricsBar(
                        ledgersCount: ledgers.length,
                        activeTypeLabel: _typeLabel(activeLedger.type, l10n),
                        currency: activeLedger.currency,
                        isDark: isDark,
                      ),
                      const SizedBox(height: 22),

                      // 3. Section Header: All Ledgers
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 4, vertical: 6),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              l10n.ledgerSwitcherTitle.toUpperCase(),
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: AppleTokens.systemGray,
                                letterSpacing: 0.6,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? AppleTokens.bgDarkSecondary
                                    : AppleTokens.bgLightSecondary,
                                borderRadius: BorderRadius.circular(
                                    AppleTokens.radiusPill),
                              ),
                              child: Text(
                                '${ledgers.length} sổ',
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: AppleTokens.systemGray,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 6),

                      // 4. Ledger Books List
                      for (final item in ledgers) ...[
                        _buildLedgerCard(
                          context: context,
                          item: item,
                          isActive: item.id == activeId,
                          isDark: isDark,
                          l10n: l10n,
                        ),
                        const SizedBox(height: 12),
                      ],
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildActiveLedgerShowcase({
    required BuildContext context,
    required LedgerBook ledger,
    required bool isDark,
    required AppLocalizations l10n,
  }) {
    final bookColor = Color(ledger.color);

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            bookColor,
            Color.lerp(bookColor, Colors.black, isDark ? 0.45 : 0.3)!,
          ],
        ),
        borderRadius: BorderRadius.circular(AppleTokens.radiusHero),
        boxShadow: [
          BoxShadow(
            color: bookColor.withValues(alpha: isDark ? 0.45 : 0.3),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppleTokens.radiusHero),
        child: Stack(
          children: [
            // Left Book Spine Ribbon
            Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              width: 8,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.22),
                  border: Border(
                    right: BorderSide(
                      color: Colors.black.withValues(alpha: 0.15),
                      width: 1,
                    ),
                  ),
                ),
              ),
            ),
            // Stitching Line
            Positioned(
              left: 14,
              top: 0,
              bottom: 0,
              width: 1,
              child: Container(
                color: Colors.white.withValues(alpha: 0.2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(26, 18, 18, 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.35),
                            width: 1.5,
                          ),
                        ),
                        child: Icon(
                          _resolveIcon(ledger.icon),
                          color: Colors.white,
                          size: 26,
                        ),
                      ),
                      // Active Pill & Edit
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: AppleTokens.jadeDark.withValues(alpha: 0.9),
                              borderRadius:
                                  BorderRadius.circular(AppleTokens.radiusPill),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.15),
                                  blurRadius: 4,
                                  offset: const Offset(0, 1),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  CupertinoIcons.circle_fill,
                                  color: Colors.white,
                                  size: 7,
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  Localizations.localeOf(context)
                                          .languageCode
                                          .startsWith('vi')
                                      ? 'ĐANG HOẠT ĐỘNG'
                                      : 'ACTIVE',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.4,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          CupertinoButton(
                            padding: EdgeInsets.zero,
                            minimumSize: const Size(32, 32),
                            onPressed: () {
                              unawaited(HapticFeedback.lightImpact());
                              LedgerFormSheet.show(context, existing: ledger);
                            },
                            child: Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.22),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                CupertinoIcons.pencil,
                                color: Colors.white,
                                size: 16,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    ledger.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.4,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    Localizations.localeOf(context).languageCode.startsWith('vi')
                        ? 'Toàn bộ ví tiền, thu chi và báo cáo hiện tại được lưu riêng trong sổ này.'
                        : 'All wallets, transactions, and reports are isolated inside this ledger.',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.85),
                      fontSize: 12.5,
                      fontWeight: FontWeight.w500,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricsBar({
    required int ledgersCount,
    required String activeTypeLabel,
    required String currency,
    required bool isDark,
  }) {
    return Builder(
      builder: (context) {
        final isVi =
            Localizations.localeOf(context).languageCode.startsWith('vi');
        return Row(
          children: [
            Expanded(
              child: _buildMetricTile(
                icon: CupertinoIcons.book_fill,
                color: AppleTokens.systemBlue,
                title: isVi ? '$ledgersCount Sổ' : '$ledgersCount Ledgers',
                label: isVi ? 'Tổng số sổ' : 'Total ledgers',
                isDark: isDark,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildMetricTile(
                icon: CupertinoIcons.tag_fill,
                color: AppleTokens.systemIndigo,
                title: activeTypeLabel,
                label: isVi ? 'Loại hiện tại' : 'Current type',
                isDark: isDark,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildMetricTile(
                icon: CupertinoIcons.money_dollar_circle_fill,
                color: AppleTokens.jadePrimary,
                title: currency,
                label: isVi ? 'Tiền tệ hạch toán' : 'Currency',
                isDark: isDark,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildMetricTile({
    required IconData icon,
    required Color color,
    required String title,
    required String label,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: isDark
            ? AppleTokens.bgDarkSecondary
            : AppleTokens.bgLightSecondary,
        borderRadius: BorderRadius.circular(AppleTokens.radiusCard),
        border: Border.all(
          color: isDark ? AppleTokens.separatorDark : AppleTokens.separatorLight,
          width: 0.8,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: color),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    fontSize: 10.5,
                    color: AppleTokens.systemGray,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildLedgerCard({
    required BuildContext context,
    required LedgerBook item,
    required bool isActive,
    required bool isDark,
    required AppLocalizations l10n,
  }) {
    final cardColor = Color(item.color);

    return AppleGlassCard(
      padding: EdgeInsets.zero,
      borderRadius: BorderRadius.circular(AppleTokens.radiusCard),
      borderColor: isActive ? cardColor.withValues(alpha: 0.55) : null,
      child: ApplePressable(
        onTap: () {
          if (!isActive) {
            _switchLedger(context, item);
          } else {
            unawaited(HapticFeedback.lightImpact());
            LedgerFormSheet.show(context, existing: item);
          }
        },
        borderRadius: BorderRadius.circular(AppleTokens.radiusCard),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppleTokens.radiusCard),
          child: Stack(
            children: [
              // Colored Left Spine Strip
              Positioned(
                left: 0,
                top: 0,
                bottom: 0,
                width: 6,
                child: Container(color: cardColor),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 14, 12, 14),
                child: Row(
                  children: [
                    // Squircle Badge
                    AppleSquircleBadge(
                      icon: _resolveIcon(item.icon),
                      backgroundColor: cardColor,
                      size: 46,
                      iconSize: 24,
                    ),
                    const SizedBox(width: 14),
                    // Name & Tags
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  item.name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 16,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (isActive) ...[
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppleTokens.jadePrimary
                                        .withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(4),
                                    border: Border.all(
                                      color: AppleTokens.jadePrimary
                                          .withValues(alpha: 0.4),
                                      width: 0.8,
                                    ),
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
                              if (item.isDefault) ...[
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isDark
                                        ? Colors.white12
                                        : Colors.black.withValues(alpha: 0.06),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    l10n.localeName.startsWith('vi')
                                        ? 'Mặc định'
                                        : 'Default',
                                    style: const TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                      color: AppleTokens.systemGray,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 3),
                          Text(
                            _typeLabel(item.type, l10n),
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppleTokens.systemGray,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Actions on Right
                    if (!isActive) ...[
                      CupertinoButton(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6),
                        minimumSize: Size.zero,
                        color: cardColor.withValues(alpha: isDark ? 0.2 : 0.1),
                        borderRadius:
                            BorderRadius.circular(AppleTokens.radiusPill),
                        onPressed: () => _switchLedger(context, item),
                        child: Text(
                          l10n.localeName.startsWith('vi')
                              ? 'Chọn sổ'
                              : 'Switch',
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                            color: isDark ? Colors.white : cardColor,
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                    ],
                    ApplePopupMenuButton<String>(
                      tooltip: l10n.moreOptions,
                      onSelected: (val) {
                        if (val == 'select') {
                          _switchLedger(context, item);
                        } else if (val == 'edit') {
                          LedgerFormSheet.show(context, existing: item);
                        } else if (val == 'delete') {
                          _confirmDelete(context, item);
                        }
                      },
                      itemBuilder: (ctx) => [
                        if (!isActive)
                          ApplePopupMenuItem(
                            value: 'select',
                            icon: CupertinoIcons.check_mark,
                            title: l10n.ledgerSelectActive,
                          ),
                        ApplePopupMenuItem(
                          value: 'edit',
                          icon: CupertinoIcons.pencil,
                          title: l10n.edit,
                        ),
                        if (!item.isDefault &&
                            item.id != LedgerBook.defaultPersonalId)
                          ApplePopupMenuItem(
                            value: 'delete',
                            icon: CupertinoIcons.trash,
                            title: l10n.ledgerDelete,
                            isDestructive: true,
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
