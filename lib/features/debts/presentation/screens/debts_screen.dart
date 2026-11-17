import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:so_thu_chi/core/l10n/l10n_ext.dart';
import 'package:so_thu_chi/core/responsive/apple_responsive.dart';
import 'package:so_thu_chi/core/theme/apple_theme_tokens.dart';
import 'package:so_thu_chi/core/widgets/apple_kit.dart';
import 'package:so_thu_chi/core/widgets/empty_state_view.dart';
import 'package:so_thu_chi/features/debts/presentation/controllers/debts_controller.dart';
import 'package:so_thu_chi/features/debts/presentation/widgets/debt_card_tile.dart';
import 'package:so_thu_chi/features/debts/presentation/widgets/debt_form_sheet.dart';
import 'package:so_thu_chi/features/debts/presentation/widgets/debt_hero_overview_card.dart';
import 'package:so_thu_chi/features/settings/presentation/controllers/settings_controller.dart';

/// Redesigned Debt & Loan Management Screen ("Sổ Ghi Nợ").
///
/// Fully aligned with the app's executive Apple HIG design language:
/// - AppleAppBar with blur, hide-balance toggle
/// - Breathtaking Glassmorphic Hero Overview Card
/// - Real-time instant search by name, phone, or note
/// - Segmented filter pill for quick categorization (All / Lent / Borrowed / Settled)
/// - Streamlined, beautiful DebtCardTile items with 1-tap quick repayment
/// - EmptyStateView integration
/// - Adaptive Expandable FAB
class DebtsScreen extends ConsumerStatefulWidget {
  const DebtsScreen({super.key});

  @override
  ConsumerState<DebtsScreen> createState() => _DebtsScreenState();
}

class _DebtsScreenState extends ConsumerState<DebtsScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _isFabExpanded = true;
  bool _isFabVisible = true;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  void _onSearchChanged() {
    final query = _searchController.text.trim();
    if (query != _searchQuery) {
      setState(() => _searchQuery = query);
    }
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final l10n = context.l10n;
    final isVi = l10n.localeName.startsWith('vi');
    final debtsAsync = ref.watch(debtsStreamProvider);
    final filteredDebts = ref.watch(filteredDebtsProvider);
    final summary = ref.watch(debtSummaryProvider);
    final currentFilter = ref.watch(debtFilterModeProvider);
    final (locale, hideBalance) = ref.watch(
      settingsControllerProvider.select(
        (s) => (s.value?.localeCode ?? 'vi', s.value?.hideBalance ?? false),
      ),
    );
    final isLandscape = context.isLandscape;
    final isWide = context.isWideScreen;
    final scrollBottomPadding = isWide
        ? AppleTokens.scrollBottomPaddingLandscape + 42
        : AppleTokens.scrollBottomPaddingWithFab;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppleAppBar(
        titleText: l10n.debtBookTitle,
        isLandscape: isLandscape,
        actions: [
          AppleIconButton(
            icon: hideBalance ? CupertinoIcons.eye_slash : CupertinoIcons.eye,
            size: isLandscape ? 32 : 36,
            iconSize: isLandscape ? 16 : 18,
            tooltip: hideBalance ? l10n.showBalance : l10n.hideBalance,
            onTap: () {
              unawaited(HapticFeedback.selectionClick());
              ref.read(settingsControllerProvider.notifier).toggleHideBalance();
            },
          ),
        ],
      ),
      floatingActionButtonLocation: const AppleFloatingActionButtonLocation(),
      floatingActionButton: AppleAdaptiveExpandableFab(
        heroTag: 'debts_add_fab',
        isVisible: _isFabVisible,
        isExpanded: _isFabExpanded,
        icon: const Icon(CupertinoIcons.plus),
        label: Text(l10n.debtNew),
        backgroundColor: AppleTokens.emeraldIncome,
        onPressed: () {
          HapticFeedback.mediumImpact();
          DebtFormSheet.show(context);
        },
        tooltip: l10n.debtNew,
      ),
      body: SafeArea(
        top: false,
        bottom: false,
        child: debtsAsync.when(
          loading: () => const Center(child: CupertinoActivityIndicator()),
          error: (err, _) => Center(child: Text(context.localizeError(err))),
          data: (allDebts) {
            final activeCount = allDebts.where((d) => !d.isSettled).length;

            // Apply in-memory search query
            final query = _searchQuery.toLowerCase();
            final displayedDebts = query.isEmpty
                ? filteredDebts
                : filteredDebts.where((d) {
                    final matchName = d.personName.toLowerCase().contains(query);
                    final matchPhone = d.phoneNumber?.contains(query) ?? false;
                    final matchNote = d.note.toLowerCase().contains(query);
                    return matchName || matchPhone || matchNote;
                  }).toList();

            final summaryCardWidgets = <Widget>[
              // 1. Executive Glassmorphic Hero Overview Card
              DebtHeroOverviewCard(
                summary: summary,
                activeCount: activeCount,
                locale: locale,
                hideBalance: hideBalance,
              ),

              const SizedBox(height: 12),

              // 2. Real-Time Search Field
              AppleTextField(
                controller: _searchController,
                placeholder: isVi
                    ? 'Tìm theo tên, SĐT, ghi chú...'
                    : 'Search by name, phone, note...',
                prefixIcon: const Icon(CupertinoIcons.search, size: 17),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(
                          CupertinoIcons.clear_thick_circled,
                          size: 16,
                        ),
                        onPressed: () {
                          unawaited(HapticFeedback.lightImpact());
                          _searchController.clear();
                        },
                      )
                    : null,
              ),

              const SizedBox(height: 10),

              // 3. Filter Segmented Pill
              AppleSegmentedPill<DebtFilterMode>(
                selected: currentFilter,
                segments: {
                  for (final mode in DebtFilterMode.values)
                    mode: mode.label(l10n),
                },
                onChanged: (mode) {
                  ref.read(debtFilterModeProvider.notifier).setMode(mode);
                },
              ),
            ];

            final debtListWidgets = <Widget>[
              // Section Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const AppleSquircleBadge(
                          icon: CupertinoIcons.person_2_fill,
                          backgroundColor: AppleTokens.systemIndigo,
                          size: 22,
                          iconSize: 11,
                          radius: 6,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          currentFilter.label(l10n).toUpperCase(),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                            color: isDark ? Colors.white70 : const Color(0xFF55555B),
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.08)
                            : Colors.black.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(
                          AppleTokens.radiusPill,
                        ),
                      ),
                      child: Text(
                        '${displayedDebts.length} ${locale.startsWith('vi') ? 'khoản' : (displayedDebts.length == 1 ? 'item' : 'items')}',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),

              if (displayedDebts.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 32,
                  ),
                  child: _searchQuery.isNotEmpty
                      ? EmptyStateView(
                          icon: CupertinoIcons.search,
                          title: isVi
                              ? 'Không tìm thấy khoản nợ'
                              : 'No debts found',
                          subtitle: isVi
                              ? 'Không có kết quả phù hợp với từ khóa "$_searchQuery".'
                              : 'No debts match "$_searchQuery".',
                          actionLabel: isVi ? 'Xóa tìm kiếm' : 'Clear search',
                          onAction: () => _searchController.clear(),
                        )
                      : EmptyStateView(
                          icon: CupertinoIcons.tray_fill,
                          title: currentFilter == DebtFilterMode.settled
                              ? l10n.debtFilterSettled
                              : l10n.debtEmpty,
                          subtitle: l10n.debtEmptySubtitle,
                          actionLabel: l10n.debtNew,
                          onAction: () {
                            HapticFeedback.mediumImpact();
                            DebtFormSheet.show(context);
                          },
                        ),
                )
              else
                for (final debt in displayedDebts)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: RepaintBoundary(
                      child: DebtCardTile(
                        debt: debt,
                        hideBalance: hideBalance,
                      ),
                    ),
                  ),
            ];

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
                  constraints: const BoxConstraints(maxWidth: 1024),
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(
                      parent: BouncingScrollPhysics(),
                    ),
                    padding: EdgeInsets.fromLTRB(
                      16,
                      8,
                      16,
                      scrollBottomPadding,
                    ),
                    children: [
                      if (isWide)
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              flex: 40,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: summaryCardWidgets,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              flex: 60,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: debtListWidgets,
                              ),
                            ),
                          ],
                        )
                      else ...[
                        ...summaryCardWidgets,
                        const SizedBox(height: 14),
                        ...debtListWidgets,
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
}
