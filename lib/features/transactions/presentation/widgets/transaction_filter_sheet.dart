import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:so_thu_chi/core/constants/icon_catalog.dart';
import 'package:so_thu_chi/core/l10n/l10n_ext.dart';
import 'package:so_thu_chi/core/theme/apple_theme_tokens.dart';
import 'package:so_thu_chi/core/utils/date_formatter.dart';
import 'package:so_thu_chi/core/widgets/apple_kit.dart';
import 'package:so_thu_chi/features/accounts/domain/entities/account.dart';
import 'package:so_thu_chi/features/accounts/presentation/controllers/accounts_controller.dart';
import 'package:so_thu_chi/features/categories/domain/entities/category.dart';
import 'package:so_thu_chi/features/categories/presentation/controllers/categories_controller.dart';
import 'package:so_thu_chi/features/transactions/domain/entities/transaction_entity.dart';
import 'package:so_thu_chi/features/settings/presentation/controllers/settings_controller.dart';
import 'package:so_thu_chi/features/transactions/presentation/controllers/transactions_controller.dart';


part 'transaction_filter_sheet_components.dart';
class TransactionFilterBottomSheet extends ConsumerStatefulWidget {
  const TransactionFilterBottomSheet({super.key});

  @override
  ConsumerState<TransactionFilterBottomSheet> createState() =>
      _TransactionFilterBottomSheetState();
}

class _TransactionFilterBottomSheetState
    extends ConsumerState<TransactionFilterBottomSheet> {
  bool _isWalletExpanded = false;
  bool _isCategoryExpanded = false;
  final _categorySearchController = TextEditingController();
  String _categoryQuery = '';

  @override
  void dispose() {
    _categorySearchController.dispose();
    super.dispose();
  }

  static _DatePreset _resolveActivePreset(
    DateTime? start,
    DateTime? end,
    DateTime? selectedMonth,
  ) {
    if (start != null && end != null) {
      final now = DateTime.now();
      final thirtyDaysAgo = now.subtract(const Duration(days: 30));
      if (AppDateUtils.isSameDay(start, thirtyDaysAgo) &&
          AppDateUtils.isSameDay(end, now)) {
        return _DatePreset.last30Days;
      }

      final thisYearStart = DateTime(now.year, 1, 1);
      final thisYearEnd = DateTime(now.year, 12, 31, 23, 59, 59);
      if (AppDateUtils.isSameDay(start, thisYearStart) &&
          AppDateUtils.isSameDay(end, thisYearEnd)) {
        return _DatePreset.thisYear;
      }
      return _DatePreset.custom;
    }
    if (start != null || end != null) return _DatePreset.custom;

    if (selectedMonth == null) return _DatePreset.all;
    final now = DateTime.now();
    if (AppDateUtils.isSameMonth(selectedMonth, now)) {
      return _DatePreset.thisMonth;
    }
    final lastMonth = AppDateUtils.addMonths(now, -1);
    if (AppDateUtils.isSameMonth(selectedMonth, lastMonth)) {
      return _DatePreset.lastMonth;
    }

    return _DatePreset.custom;
  }

  static void _applyPreset(_DatePreset preset, WidgetRef ref) {
    final now = DateTime.now();
    switch (preset) {
      case _DatePreset.all:
        ref.read(selectedTransactionMonthProvider.notifier).setMonth(null);
        ref.read(transactionFilterProvider.notifier).setDateRange(null, null);
      case _DatePreset.thisMonth:
        ref.read(selectedTransactionMonthProvider.notifier).setMonth(now);
        ref.read(transactionFilterProvider.notifier).setDateRange(null, null);
      case _DatePreset.lastMonth:
        ref.read(selectedTransactionMonthProvider.notifier).setMonth(
              AppDateUtils.addMonths(now, -1),
            );
        ref.read(transactionFilterProvider.notifier).setDateRange(null, null);
      case _DatePreset.last30Days:
        ref.read(transactionFilterProvider.notifier).setDateRange(
              now.subtract(const Duration(days: 30)),
              now,
            );
      case _DatePreset.thisYear:
        ref.read(transactionFilterProvider.notifier).setDateRange(
              DateTime(now.year, 1, 1),
              DateTime(now.year, 12, 31, 23, 59, 59),
            );
      case _DatePreset.custom:
        break;
    }
  }

  static Future<void> _pickCustomDateRange(
    BuildContext context,
    WidgetRef ref,
    TransactionFilter filter,
  ) async {
    final now = DateTime.now();
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2018),
      lastDate: DateTime(now.year + 5, 12, 31),
      initialDateRange: filter.startDate != null && filter.endDate != null
          ? DateTimeRange(
              start: filter.startDate!,
              end: filter.endDate!,
            )
          : null,
      builder: (ctx, child) {
        return Theme(
          data: theme.copyWith(
            colorScheme: theme.colorScheme.copyWith(
              primary: theme.colorScheme.primary,
              surface: isDark ? AppleTokens.bgDarkCard : AppleTokens.bgLightCard,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      ref
          .read(transactionFilterProvider.notifier)
          .setDateRange(picked.start, picked.end);
    }
  }

  Widget _buildSectionHeader({
    required BuildContext context,
    required IconData icon,
    required String title,
    String? trailing,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Container(
            width: 20,
            height: 20,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: isDark ? 0.20 : 0.12),
              borderRadius: BorderRadius.circular(5.5),
            ),
            child: Icon(
              icon,
              size: 11.5,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(width: 7),
          Text(
            title.toUpperCase(),
            style: theme.textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: isDark ? const Color(0xFF98989D) : const Color(0xFF6C6C70),
              letterSpacing: 0.6,
              fontSize: 11,
            ),
          ),
          if (trailing != null) ...[
            const Spacer(),
            Text(
              trailing,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: isDark ? Colors.white38 : Colors.black38,
              ),
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final filter = ref.watch(transactionFilterProvider);
    final allCategories = ref.watch(categoriesStreamProvider).value ?? const [];
    final wallets = ref.watch(accountsStreamProvider).value ?? const [];
    final settings = ref.watch(settingsControllerProvider).value;
    final locale = settings?.localeCode ?? 'vi';
    final hideBalance = settings?.hideBalance ?? false;

    // Filter categories dynamically based on selected transaction type
    final visibleCategories = allCategories.where((cat) {
      if (filter.type == TransactionType.expense) {
        return cat.type == CategoryType.expense;
      }
      if (filter.type == TransactionType.income) {
        return cat.type == CategoryType.income;
      }
      return true;
    }).toList(growable: false);

    final selectedMonth = ref.watch(selectedTransactionMonthProvider);

    // Calculate active filter count
    var activeFilterCount = 0;
    if (filter.type != null) activeFilterCount++;
    if (filter.startDate != null || filter.endDate != null) activeFilterCount++;
    if (filter.effectiveAccountIds.isNotEmpty) activeFilterCount += filter.effectiveAccountIds.length;
    if (filter.effectiveCategoryIds.isNotEmpty) activeFilterCount += filter.effectiveCategoryIds.length;

    final activePreset = _resolveActivePreset(filter.startDate, filter.endDate, selectedMonth);
    final size = MediaQuery.sizeOf(context);
    final isLandscape = size.width > size.height;
    final sheetHeight = size.height * (isLandscape ? 0.94 : 0.85);

    return Container(
      constraints: BoxConstraints(maxHeight: sheetHeight),
      decoration: BoxDecoration(
        color: isDark
            ? (context.isOled ? AppleTokens.bgOledCard : AppleTokens.bgDarkPrimary)
            : AppleTokens.bgLightPrimary,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppleTokens.radiusHero),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Top Drag Handle
            const SizedBox(height: 10),
            Center(
              child: Container(
                width: 36,
                height: 5,
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF3A3A3C) : const Color(0xFFD1D1D6),
                  borderRadius: BorderRadius.circular(2.5),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Sheet Header with Title, Badge, Reset and Close
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Text(
                    l10n.filterTransactions,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.3,
                      fontSize: 19,
                    ),
                  ),
                  if (activeFilterCount > 0) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2.5,
                      ),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withValues(alpha: isDark ? 0.22 : 0.12),
                        borderRadius: BorderRadius.circular(AppleTokens.radiusPill),
                        border: Border.all(
                          color: theme.colorScheme.primary.withValues(alpha: 0.3),
                          width: AppleTokens.hairline,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 5,
                            height: 5,
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            l10n.filterSelectedCount(activeFilterCount),
                            style: TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w700,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const Spacer(),
                  if (filter.hasActiveFilters)
                    CupertinoButton(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      minimumSize: const Size(44, 30),
                      onPressed: () {
                        HapticFeedback.lightImpact();
                        ref.read(transactionFilterProvider.notifier).clearAll();
                        setState(() {
                          _categorySearchController.clear();
                          _categoryQuery = '';
                        });
                      },
                      child: Text(
                        l10n.filterReset,
                        style: const TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w600,
                          color: AppleTokens.systemRed,
                        ),
                      ),
                    ),
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    minimumSize: const Size(30, 30),
                    onPressed: () => Navigator.of(context).pop(),
                    child: Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF2C2C2E) : const Color(0xFFE5E5EA),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        CupertinoIcons.xmark,
                        size: 13,
                        color: isDark ? const Color(0xFF8E8E93) : const Color(0xFF6C6C70),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),

            Divider(
              height: AppleTokens.hairline,
              color: isDark ? AppleTokens.separatorDark : AppleTokens.separatorLight,
            ),

            // Scrollable Content
            Flexible(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Card 1: Phân loại & Thời gian
                    AppleGlassCard(
                      padding: const EdgeInsets.all(14),
                      borderRadius: BorderRadius.circular(AppleTokens.radiusCard),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // 1. Loại giao dịch
                          _buildSectionHeader(
                            context: context,
                            icon: CupertinoIcons.arrow_up_arrow_down_circle,
                            title: l10n.filterTransactionType,
                          ),
                          _TypeSegmentSelector(
                            selectedType: filter.type,
                            onChanged: (newType) {
                              ref.read(transactionFilterProvider.notifier).setType(newType);
                            },
                          ),
                          const SizedBox(height: 14),
                          Divider(
                            height: AppleTokens.hairline,
                            color: isDark ? AppleTokens.separatorDark : AppleTokens.separatorLight,
                          ),
                          const SizedBox(height: 12),

                          // 2. Khoảng thời gian
                          _buildSectionHeader(
                            context: context,
                            icon: CupertinoIcons.calendar,
                            title: l10n.dateRange,
                          ),
                          _DatePresetChips(
                            activePreset: activePreset,
                            onSelectPreset: (preset) {
                              HapticFeedback.selectionClick();
                              if (preset == _DatePreset.custom) {
                                _pickCustomDateRange(context, ref, filter);
                              } else {
                                _applyPreset(preset, ref);
                              }
                            },
                          ),
                          if (filter.startDate != null && filter.endDate != null) ...[
                            const SizedBox(height: 8),
                            _CompactCustomDatePill(
                              startDate: filter.startDate!,
                              endDate: filter.endDate!,
                              locale: locale,
                              onTapEdit: () => _pickCustomDateRange(context, ref, filter),
                              onClear: () {
                                HapticFeedback.lightImpact();
                                ref.read(transactionFilterProvider.notifier).setDateRange(null, null);
                              },
                            ),
                          ],
                        ],
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Card 2: Menu mở rộng Ví & Danh mục
                    AppleGlassCard(
                      padding: const EdgeInsets.all(14),
                      borderRadius: BorderRadius.circular(AppleTokens.radiusCard),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // 3. Menu mở rộng Ví & tài khoản
                          _ExpandableWalletMenu(
                            wallets: wallets,
                            selectedAccountIds: filter.effectiveAccountIds,
                            isExpanded: _isWalletExpanded,
                            locale: locale,
                            hideBalance: hideBalance,
                            onToggleExpand: () {
                              HapticFeedback.lightImpact();
                              setState(() {
                                _isWalletExpanded = !_isWalletExpanded;
                              });
                            },
                            onToggleAccount: (accId) {
                              ref.read(transactionFilterProvider.notifier).toggleAccount(accId);
                            },
                            onClearAccounts: () {
                              ref.read(transactionFilterProvider.notifier).clearAccounts();
                            },
                          ),

                          const SizedBox(height: 14),
                          Divider(
                            height: AppleTokens.hairline,
                            color: isDark ? AppleTokens.separatorDark : AppleTokens.separatorLight,
                          ),
                          const SizedBox(height: 12),

                          // 4. Menu mở rộng Danh mục thu chi
                          _ExpandableCategoryMenu(
                            categories: visibleCategories,
                            selectedCategoryIds: filter.effectiveCategoryIds,
                            isExpanded: _isCategoryExpanded,
                            searchController: _categorySearchController,
                            searchQuery: _categoryQuery,
                            onSearchChanged: (query) {
                              setState(() {
                                _categoryQuery = query.trim();
                              });
                            },
                            onToggleExpand: () {
                              HapticFeedback.lightImpact();
                              setState(() {
                                _isCategoryExpanded = !_isCategoryExpanded;
                              });
                            },
                            onToggleCategory: (catId) {
                              ref.read(transactionFilterProvider.notifier).toggleCategory(catId);
                            },
                            onClearCategories: () {
                              ref.read(transactionFilterProvider.notifier).clearCategories();
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Sticky Bottom Action Bar
            Divider(
              height: AppleTokens.hairline,
              color: isDark ? AppleTokens.separatorDark : AppleTokens.separatorLight,
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
              child: AppleButton.primary(
                label: l10n.filterApply,
                color: theme.colorScheme.primary,
                onPressed: () {
                  HapticFeedback.mediumImpact();
                  Navigator.of(context).pop();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

