import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:so_thu_chi/core/l10n/l10n_ext.dart';
import 'package:so_thu_chi/core/responsive/apple_responsive.dart';
import 'package:so_thu_chi/core/theme/apple_theme_tokens.dart';
import 'package:so_thu_chi/core/widgets/apple_kit.dart';
import 'package:so_thu_chi/core/widgets/empty_state_view.dart';
import 'package:so_thu_chi/core/widgets/skeleton_box.dart';
import 'package:so_thu_chi/features/budgets/domain/entities/budget.dart';
import 'package:so_thu_chi/features/budgets/presentation/controllers/budgets_controller.dart';
import 'package:so_thu_chi/features/budgets/presentation/widgets/budget_alert_banner.dart';
import 'package:so_thu_chi/features/budgets/presentation/widgets/budget_allocation_bar.dart';
import 'package:so_thu_chi/features/budgets/presentation/widgets/budget_category_card.dart';
import 'package:so_thu_chi/features/budgets/presentation/widgets/budget_form_sheet.dart';
import 'package:so_thu_chi/features/budgets/presentation/widgets/budget_hero_overview_card.dart';
import 'package:so_thu_chi/features/budgets/presentation/widgets/budget_status_filter_bar.dart';
import 'package:so_thu_chi/features/categories/presentation/controllers/categories_controller.dart';
import 'package:so_thu_chi/features/settings/presentation/controllers/settings_controller.dart';

/// Redesigned Budgets Screen featuring an Apple-grade financial overview,
/// interactive health activity ring, dynamic category allocation bar,
/// status filtering, and intuitive threshold-marked budget progress cards.
class BudgetsScreen extends ConsumerStatefulWidget {
  const BudgetsScreen({super.key});

  @override
  ConsumerState<BudgetsScreen> createState() => _BudgetsScreenState();
}

class _BudgetsScreenState extends ConsumerState<BudgetsScreen> {
  bool _isFabExpanded = true;
  bool _isFabVisible = true;
  BudgetFilterStatus _selectedFilter = BudgetFilterStatus.all;

  Future<void> _openBudgetForm(
    BuildContext context, {
    required DateTime selectedMonth,
    Budget? existing,
  }) async {
    await BudgetFormBottomSheet.show(
      context,
      monthStart: selectedMonth,
      existing: existing,
    );
  }

  Future<void> _deleteBudget(
    BuildContext context,
    String budgetId,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    final res = await ref
        .read(budgetsActionControllerProvider.notifier)
        .deleteBudget(budgetId);
    if (!context.mounted) return;
    res.fold(
      onSuccess: (_) {},
      onFailure: (err) {
        messenger.showSnackBar(
          SnackBar(content: Text(context.localizeError(err))),
        );
      },
    );
  }

  Widget _buildHeaderMonthSwitcher({
    required DateTime selectedMonth,
  }) {
    return AppleCompactMonthSwitcher(
      isHeaderMode: true,
      selectedMonth: selectedMonth,
      allowAllOption: false,
      onPrevious: () =>
          ref.read(selectedBudgetMonthProvider.notifier).previousMonth(),
      onNext: () =>
          ref.read(selectedBudgetMonthProvider.notifier).nextMonth(),
      onSelectMonth: (month) {
        if (month != null) {
          ref.read(selectedBudgetMonthProvider.notifier).setMonth(month);
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isVi = l10n.localeName.startsWith('vi');
    final textScale = MediaQuery.textScalerOf(context).scale(1);
    final isLargeText = textScale >= 1.35;
    final settings = ref.watch(settingsControllerProvider).value;
    final locale = settings?.localeCode ?? 'vi';
    final hideBalance = settings?.hideBalance ?? false;

    final selectedMonth = ref.watch(selectedBudgetMonthProvider);
    final budgetsStream = ref.watch(budgetsStreamProvider);
    final progressList = ref.watch(selectedMonthBudgetProgressProvider);
    final categoriesMap = ref.watch(categoriesMapProvider);
    final triggered = progressList
        .where((p) => p.isWarningTriggered)
        .toList(growable: false);

    final isLandscape = context.isLandscape;
    final isWide = context.isWideScreen;

    // Filter category budgets based on user-selected status chip
    final filteredList = switch (_selectedFilter) {
      BudgetFilterStatus.all => progressList,
      BudgetFilterStatus.warning => progressList
          .where((p) => p.isWarningTriggered && !p.isExceeded)
          .toList(growable: false),
      BudgetFilterStatus.exceeded => progressList
          .where((p) => p.isExceeded)
          .toList(growable: false),
      BudgetFilterStatus.safe => progressList
          .where((p) => !p.isWarningTriggered && !p.isExceeded)
          .toList(growable: false),
    };

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: isLandscape
            ? AppleTokens.appBarHeightLandscape
            : AppleTokens.appBarHeightPortrait,
        title: Text(l10n.budgetsTitle),
        actions: [
          if (isLandscape) ...[
            Center(
              child: _buildHeaderMonthSwitcher(
                selectedMonth: selectedMonth,
              ),
            ),
            const SizedBox(width: 12),
          ],
        ],
      ),
      body: SafeArea(
        top: false,
        bottom: false,
        child: Column(
          children: [
            // Month Switcher Bar (portrait mode; merged into AppBar in landscape)
            if (!isLandscape)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 2, 16, 6),
                child: Center(
                  child: AppleCompactMonthSwitcher(
                    selectedMonth: selectedMonth,
                    allowAllOption: false,
                    onPrevious: () => ref
                        .read(selectedBudgetMonthProvider.notifier)
                        .previousMonth(),
                    onNext: () => ref
                        .read(selectedBudgetMonthProvider.notifier)
                        .nextMonth(),
                    onSelectMonth: (month) {
                      if (month != null) {
                        ref
                            .read(selectedBudgetMonthProvider.notifier)
                            .setMonth(month);
                      }
                    },
                  ),
                ),
              ),

            Expanded(
              child: NotificationListener<UserScrollNotification>(
                onNotification: (notification) {
                  if (notification.direction == ScrollDirection.reverse) {
                    if (_isFabVisible) {
                      setState(() {
                        _isFabVisible = false;
                        _isFabExpanded = false;
                      });
                    }
                  } else if (notification.direction ==
                      ScrollDirection.forward) {
                    if (!_isFabVisible) {
                      setState(() {
                        _isFabVisible = true;
                      });
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
                child: budgetsStream.when(
                  loading: () => const SkeletonListView(itemCount: 3),
                  error: (err, _) => Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(context.localizeError(err)),
                    ),
                  ),
                  data: (_) {
                    if (progressList.isEmpty) {
                      return EmptyStateView(
                        icon: Icons.pie_chart_outline_rounded,
                        title: l10n.emptyBudgetsTitle,
                        subtitle: l10n.emptyBudgetsSubtitle,
                        actionLabel: l10n.addBudget,
                        onAction: () => _openBudgetForm(
                          context,
                          selectedMonth: selectedMonth,
                        ),
                      );
                    }

                    // Left Overview block (Overview Hero Card + Allocation + Warnings)
                    final overviewWidgets = <Widget>[
                      BudgetHeroOverviewCard(
                        progressList: progressList,
                        selectedMonth: selectedMonth,
                        locale: locale,
                        hideBalance: hideBalance,
                      ),
                      if (triggered.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        BudgetAlertBanner(
                          progressOverride: triggered,
                          navigateOnTap: false,
                        ),
                      ],
                      if (progressList.length >= 2) ...[
                        const SizedBox(height: 16),
                        BudgetAllocationBar(
                          progressList: progressList,
                          categoriesMap: categoriesMap,
                        ),
                      ],
                    ];

                    // Right / Category Budgets list section
                    final categoryListSection = <Widget>[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            isVi ? 'Danh sách ngân sách' : 'Budget Categories',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.2,
                            ),
                          ),
                          Text(
                            '${filteredList.length} / ${progressList.length}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: scheme.onSurfaceVariant,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      BudgetStatusFilterBar(
                        selectedFilter: _selectedFilter,
                        progressList: progressList,
                        onSelectFilter: (filter) {
                          setState(() {
                            _selectedFilter = filter;
                          });
                        },
                      ),
                      const SizedBox(height: 14),
                      if (filteredList.isEmpty)
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: scheme.surfaceContainerHighest
                                .withValues(alpha: 0.35),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Column(
                            children: [
                              Icon(
                                CupertinoIcons.tray,
                                size: 36,
                                color: scheme.onSurfaceVariant
                                    .withValues(alpha: 0.6),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                isVi
                                    ? 'Không có ngân sách nào ở bộ lọc này'
                                    : 'No budgets match this filter',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: scheme.onSurfaceVariant,
                                ),
                              ),
                              const SizedBox(height: 8),
                              AppleButton(
                                label: isVi ? 'Xem tất cả' : 'Show all',
                                variant: AppleButtonVariant.secondary,
                                isFullWidth: false,
                                height: 36,
                                onPressed: () {
                                  setState(() {
                                    _selectedFilter = BudgetFilterStatus.all;
                                  });
                                },
                              ),
                            ],
                          ),
                        )
                      else
                        for (final item in filteredList) ...[
                          RepaintBoundary(
                            child: BudgetCategoryCard(
                              progress: item,
                              category: item.budget.categoryId != null
                                  ? categoriesMap[item.budget.categoryId!]
                                  : null,
                              locale: locale,
                              hideBalance: hideBalance,
                              onEdit: () => _openBudgetForm(
                                context,
                                selectedMonth: selectedMonth,
                                existing: item.budget,
                              ),
                              onDelete: () =>
                                  _deleteBudget(context, item.budget.id),
                            ),
                          ),
                          const SizedBox(height: 12),
                        ],
                    ];

                    return Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 1024),
                        child: ListView(
                          physics: const BouncingScrollPhysics(
                            parent: AlwaysScrollableScrollPhysics(),
                          ),
                          padding: EdgeInsets.fromLTRB(
                            16,
                            4,
                            16,
                            isWide
                                ? AppleTokens.scrollBottomPaddingLandscape + 42
                                : AppleTokens.scrollBottomPaddingWithFab,
                          ),
                          children: [
                            if (isWide)
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    flex: 42,
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.stretch,
                                      children: overviewWidgets,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    flex: 58,
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.stretch,
                                      children: categoryListSection,
                                    ),
                                  ),
                                ],
                              )
                            else ...[
                              ...overviewWidgets,
                              const SizedBox(height: 20),
                              ...categoryListSection,
                            ],
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButtonLocation: const AppleFloatingActionButtonLocation(),
      floatingActionButton: AppleAdaptiveExpandableFab(
        heroTag: 'budgets_add_fab',
        isVisible: _isFabVisible,
        isExpanded: _isFabExpanded && !isLargeText,
        icon: const Icon(CupertinoIcons.plus),
        label: Text(l10n.addBudget),
        onPressed: () => _openBudgetForm(context, selectedMonth: selectedMonth),
        tooltip: l10n.addBudget,
      ),
    );
  }
}
