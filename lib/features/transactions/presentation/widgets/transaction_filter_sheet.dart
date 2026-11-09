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
    if (filter.accountId != null) activeFilterCount++;
    if (filter.categoryId != null) activeFilterCount++;

    final activePreset = _resolveActivePreset(filter.startDate, filter.endDate, selectedMonth);
    final isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;
    final sheetHeight = MediaQuery.of(context).size.height * (isLandscape ? 0.94 : 0.85);

    Account? selectedAccount;
    if (filter.accountId != null) {
      for (final w in wallets) {
        if (w.id == filter.accountId) {
          selectedAccount = w;
          break;
        }
      }
    }

    Category? selectedCategory;
    if (filter.categoryId != null) {
      for (final c in allCategories) {
        if (c.id == filter.categoryId) {
          selectedCategory = c;
          break;
        }
      }
    }

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
                            selectedAccountId: filter.accountId,
                            selectedAccount: selectedAccount,
                            isExpanded: _isWalletExpanded,
                            locale: locale,
                            hideBalance: hideBalance,
                            onToggleExpand: () {
                              HapticFeedback.lightImpact();
                              setState(() {
                                _isWalletExpanded = !_isWalletExpanded;
                              });
                            },
                            onSelectAccount: (accId) {
                              ref.read(transactionFilterProvider.notifier).setAccount(accId);
                              setState(() {
                                _isWalletExpanded = false;
                              });
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
                            selectedCategoryId: filter.categoryId,
                            selectedCategory: selectedCategory,
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
                            onSelectCategory: (catId) {
                              ref.read(transactionFilterProvider.notifier).setCategory(catId);
                              setState(() {
                                _isCategoryExpanded = false;
                              });
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

enum _DatePreset {
  all,
  thisMonth,
  lastMonth,
  last30Days,
  thisYear,
  custom,
}

class _TypeSegmentSelector extends StatelessWidget {
  const _TypeSegmentSelector({
    required this.selectedType,
    required this.onChanged,
  });

  final TransactionType? selectedType;
  final ValueChanged<TransactionType?> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final l10n = context.l10n;

    final items = <(TransactionType?, String, IconData, Color)>[
      (
        null,
        l10n.all,
        CupertinoIcons.square_grid_2x2,
        theme.colorScheme.primary,
      ),
      (
        TransactionType.expense,
        l10n.expense,
        CupertinoIcons.arrow_up_right,
        AppleTokens.rubyExpense,
      ),
      (
        TransactionType.income,
        l10n.income,
        CupertinoIcons.arrow_down_left,
        AppleTokens.emeraldIncome,
      ),
      (
        TransactionType.transfer,
        l10n.transfer,
        CupertinoIcons.arrow_right_arrow_left,
        AppleTokens.cobaltTransfer,
      ),
    ];

    return Container(
      padding: const EdgeInsets.all(2.5),
      decoration: BoxDecoration(
        color: isDark ? AppleTokens.bgDarkSecondary : AppleTokens.bgLightSecondary,
        borderRadius: BorderRadius.circular(AppleTokens.radiusPill),
        border: Border.all(
          color: isDark ? const Color(0xFF2C2C2E) : AppleTokens.borderLight,
          width: AppleTokens.hairline,
        ),
      ),
      child: Row(
        children: items.map((item) {
          final (type, label, icon, tintColor) = item;
          final isSelected = selectedType == type;
          return Expanded(
            child: ApplePressable(
              onTap: () {
                HapticFeedback.selectionClick();
                onChanged(type);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeOutCubic,
                padding: const EdgeInsets.symmetric(vertical: 7),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: isSelected
                      ? (isDark ? AppleTokens.bgDarkCard : Colors.white)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(AppleTokens.radiusPill),
                  border: isSelected
                      ? Border.all(
                          color: tintColor.withValues(alpha: isDark ? 0.45 : 0.35),
                          width: 1,
                        )
                      : null,
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.08),
                            blurRadius: 4,
                            offset: const Offset(0, 1),
                          ),
                        ]
                      : null,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      icon,
                      size: 12,
                      color: isSelected
                          ? tintColor
                          : (isDark ? const Color(0xFF8E8E93) : const Color(0xFF6C6C70)),
                    ),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                          color: isSelected
                              ? (isDark ? Colors.white : Colors.black87)
                              : (isDark ? const Color(0xFF8E8E93) : const Color(0xFF6C6C70)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _DatePresetChips extends StatelessWidget {
  const _DatePresetChips({
    required this.activePreset,
    required this.onSelectPreset,
  });

  final _DatePreset activePreset;
  final ValueChanged<_DatePreset> onSelectPreset;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final l10n = context.l10n;

    final presets = <(_DatePreset, String)>[
      (_DatePreset.all, l10n.filterDateAll),
      (_DatePreset.thisMonth, l10n.filterDateThisMonth),
      (_DatePreset.lastMonth, l10n.filterDateLastMonth),
      (_DatePreset.last30Days, l10n.filterDateLast30Days),
      (_DatePreset.thisYear, l10n.filterDateThisYear),
      (_DatePreset.custom, l10n.filterCustomDate),
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: presets.map((p) {
          final (preset, title) = p;
          final isSelected = activePreset == preset;
          return Padding(
            padding: const EdgeInsets.only(right: 6),
            child: ApplePressable(
              onTap: () => onSelectPreset(preset),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 160),
                padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6.5),
                decoration: BoxDecoration(
                  color: isSelected
                      ? theme.colorScheme.primary.withValues(alpha: isDark ? 0.25 : 0.12)
                      : (isDark ? AppleTokens.bgDarkSecondary : AppleTokens.bgLightSecondary),
                  borderRadius: BorderRadius.circular(AppleTokens.radiusPill),
                  border: Border.all(
                    color: isSelected
                        ? theme.colorScheme.primary
                        : (isDark ? const Color(0xFF2C2C2E) : AppleTokens.borderLight),
                    width: isSelected ? 1.2 : AppleTokens.hairline,
                  ),
                ),
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    color: isSelected
                        ? theme.colorScheme.primary
                        : (isDark ? Colors.white70 : Colors.black87),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _CompactCustomDatePill extends StatelessWidget {
  const _CompactCustomDatePill({
    required this.startDate,
    required this.endDate,
    required this.locale,
    required this.onTapEdit,
    required this.onClear,
  });

  final DateTime startDate;
  final DateTime endDate;
  final String locale;
  final VoidCallback onTapEdit;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.fromLTRB(10, 6, 8, 6),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withValues(alpha: isDark ? 0.15 : 0.08),
        borderRadius: BorderRadius.circular(AppleTokens.radiusControl),
        border: Border.all(
          color: theme.colorScheme.primary.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            CupertinoIcons.calendar_badge_plus,
            size: 14,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '${AppDateUtils.formatShortDate(startDate, locale: locale)} – ${AppDateUtils.formatShortDate(endDate, locale: locale)}',
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.primary,
              ),
            ),
          ),
          ApplePressable(
            onTap: onTapEdit,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              child: Text(
                'Đổi',
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.primary,
                ),
              ),
            ),
          ),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: onClear,
            child: Icon(
              CupertinoIcons.clear_circled_solid,
              size: 15,
              color: AppleTokens.systemRed.withValues(alpha: 0.8),
            ),
          ),
        ],
      ),
    );
  }
}

/// Expandable Menu for Wallets & Accounts
class _ExpandableWalletMenu extends StatelessWidget {
  const _ExpandableWalletMenu({
    required this.wallets,
    required this.selectedAccountId,
    required this.selectedAccount,
    required this.isExpanded,
    required this.locale,
    required this.hideBalance,
    required this.onToggleExpand,
    required this.onSelectAccount,
  });

  final List<Account> wallets;
  final String? selectedAccountId;
  final Account? selectedAccount;
  final bool isExpanded;
  final String locale;
  final bool hideBalance;
  final VoidCallback onToggleExpand;
  final ValueChanged<String?> onSelectAccount;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final l10n = context.l10n;

    final subtitle = selectedAccount != null
        ? selectedAccount!.name
        : l10n.filterAllWallets;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Header Row (Tap to expand/collapse)
        ApplePressable(
          onTap: onToggleExpand,
          child: Row(
            children: [
              AppleSquircleBadge(
                icon: selectedAccount != null
                    ? AppIconCatalog.resolve(selectedAccount!.icon)
                    : CupertinoIcons.creditcard,
                backgroundColor: selectedAccount != null
                    ? AppIconCatalog.contrastSafeColor(
                        Color(selectedAccount!.color),
                        theme.brightness,
                      )
                    : theme.colorScheme.primary,
                size: 24,
                iconSize: 13,
                radius: 6,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.walletsTitle.toUpperCase(),
                      style: theme.textTheme.labelSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: isDark ? const Color(0xFF98989D) : const Color(0xFF6C6C70),
                        letterSpacing: 0.6,
                        fontSize: 11,
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: selectedAccount != null ? FontWeight.w700 : FontWeight.w500,
                        color: selectedAccount != null
                            ? theme.colorScheme.primary
                            : (isDark ? Colors.white : Colors.black87),
                      ),
                    ),
                  ],
                ),
              ),
              if (selectedAccount != null) ...[
                GestureDetector(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    onSelectAccount(null);
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                    child: Icon(
                      CupertinoIcons.clear_circled_solid,
                      size: 16,
                      color: AppleTokens.systemRed.withValues(alpha: 0.8),
                    ),
                  ),
                ),
              ],
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: isDark ? AppleTokens.bgDarkSecondary : AppleTokens.bgLightSecondary,
                  borderRadius: BorderRadius.circular(AppleTokens.radiusPill),
                  border: Border.all(
                    color: isDark ? const Color(0xFF2C2C2E) : AppleTokens.borderLight,
                    width: AppleTokens.hairline,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${wallets.length} ví',
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark ? Colors.white54 : Colors.black54,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: 4),
                    AnimatedRotation(
                      turns: isExpanded ? 0.5 : 0.0,
                      duration: const Duration(milliseconds: 200),
                      child: Icon(
                        CupertinoIcons.chevron_down,
                        size: 11,
                        color: isDark ? Colors.white54 : Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Expanded Menu List
        AnimatedCrossFade(
          duration: const Duration(milliseconds: 220),
          firstCurve: Curves.easeOutCubic,
          secondCurve: Curves.easeInCubic,
          crossFadeState: isExpanded
              ? CrossFadeState.showFirst
              : CrossFadeState.showSecond,
          secondChild: const SizedBox.shrink(),
          firstChild: Padding(
            padding: const EdgeInsets.only(top: 10),
            child: Container(
              decoration: BoxDecoration(
                color: isDark ? AppleTokens.bgDarkSecondary : AppleTokens.bgLightSecondary,
                borderRadius: BorderRadius.circular(AppleTokens.radiusCard),
                border: Border.all(
                  color: isDark ? const Color(0xFF2C2C2E) : AppleTokens.borderLight,
                  width: AppleTokens.hairline,
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(AppleTokens.radiusCard),
                child: Column(
                  children: [
                    // Item 0: All Wallets
                    _buildMenuItem(
                      context: context,
                      isSelected: selectedAccountId == null,
                      leading: Icon(
                        CupertinoIcons.creditcard,
                        size: 15,
                        color: selectedAccountId == null
                            ? theme.colorScheme.primary
                            : (isDark ? const Color(0xFF8E8E93) : const Color(0xFF6C6C70)),
                      ),
                      title: l10n.filterAllWallets,
                      subtitle: '${wallets.length} ${l10n.walletsTitle.toLowerCase()}',
                      onTap: () {
                        HapticFeedback.selectionClick();
                        onSelectAccount(null);
                      },
                    ),
                    for (final wallet in wallets) ...[
                      Divider(
                        height: AppleTokens.hairline,
                        color: isDark ? AppleTokens.separatorDark : AppleTokens.separatorLight,
                      ),
                      _buildMenuItem(
                        context: context,
                        isSelected: selectedAccountId == wallet.id,
                        leading: AppleSquircleBadge(
                          icon: AppIconCatalog.resolve(wallet.icon),
                          backgroundColor: AppIconCatalog.contrastSafeColor(
                            Color(wallet.color),
                            theme.brightness,
                          ),
                          size: 26,
                          iconSize: 13,
                          radius: 6,
                        ),
                        title: wallet.name,
                        subtitle: hideBalance
                            ? '••••••'
                            : wallet.balanceMoney.format(locale: locale),
                        onTap: () {
                          HapticFeedback.selectionClick();
                          onSelectAccount(wallet.id);
                        },
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMenuItem({
    required BuildContext context,
    required bool isSelected,
    required Widget leading,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return ApplePressable(
      onTap: onTap,
      child: Container(
        color: isSelected
            ? theme.colorScheme.primary.withValues(alpha: isDark ? 0.18 : 0.08)
            : Colors.transparent,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        child: Row(
          children: [
            leading,
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                      color: isSelected
                          ? theme.colorScheme.primary
                          : (isDark ? Colors.white : Colors.black87),
                    ),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 10.5,
                      color: isDark ? const Color(0xFF8E8E93) : const Color(0xFF6C6C70),
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(
                CupertinoIcons.checkmark_alt,
                size: 15,
                color: theme.colorScheme.primary,
              ),
          ],
        ),
      ),
    );
  }
}

/// Expandable Menu for Categories
class _ExpandableCategoryMenu extends StatelessWidget {
  const _ExpandableCategoryMenu({
    required this.categories,
    required this.selectedCategoryId,
    required this.selectedCategory,
    required this.isExpanded,
    required this.searchController,
    required this.searchQuery,
    required this.onSearchChanged,
    required this.onToggleExpand,
    required this.onSelectCategory,
  });

  final List<Category> categories;
  final String? selectedCategoryId;
  final Category? selectedCategory;
  final bool isExpanded;
  final TextEditingController searchController;
  final String searchQuery;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onToggleExpand;
  final ValueChanged<String?> onSelectCategory;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final l10n = context.l10n;

    final resolvedCatName = selectedCategory != null
        ? DefaultCategoryLocalization.resolveName(
            l10n,
            categoryId: selectedCategory!.id,
            fallbackName: selectedCategory!.name,
          )
        : null;

    final subtitle = resolvedCatName ?? l10n.filterAllCategories;

    final filteredCategories = categories.where((c) {
      if (searchQuery.isEmpty) return true;
      final name = DefaultCategoryLocalization.resolveName(
        l10n,
        categoryId: c.id,
        fallbackName: c.name,
      ).toLowerCase();
      return name.contains(searchQuery.toLowerCase());
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Header Row (Tap to expand/collapse)
        ApplePressable(
          onTap: onToggleExpand,
          child: Row(
            children: [
              AppleSquircleBadge(
                icon: selectedCategory != null
                    ? AppIconCatalog.resolve(selectedCategory!.icon)
                    : CupertinoIcons.square_grid_2x2,
                backgroundColor: selectedCategory != null
                    ? AppIconCatalog.contrastSafeColor(
                        Color(selectedCategory!.color),
                        theme.brightness,
                      )
                    : theme.colorScheme.primary,
                size: 24,
                iconSize: 13,
                radius: 6,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.categoriesTitle.toUpperCase(),
                      style: theme.textTheme.labelSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: isDark ? const Color(0xFF98989D) : const Color(0xFF6C6C70),
                        letterSpacing: 0.6,
                        fontSize: 11,
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: selectedCategory != null ? FontWeight.w700 : FontWeight.w500,
                        color: selectedCategory != null
                            ? theme.colorScheme.primary
                            : (isDark ? Colors.white : Colors.black87),
                      ),
                    ),
                  ],
                ),
              ),
              if (selectedCategory != null) ...[
                GestureDetector(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    onSelectCategory(null);
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                    child: Icon(
                      CupertinoIcons.clear_circled_solid,
                      size: 16,
                      color: AppleTokens.systemRed.withValues(alpha: 0.8),
                    ),
                  ),
                ),
              ],
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: isDark ? AppleTokens.bgDarkSecondary : AppleTokens.bgLightSecondary,
                  borderRadius: BorderRadius.circular(AppleTokens.radiusPill),
                  border: Border.all(
                    color: isDark ? const Color(0xFF2C2C2E) : AppleTokens.borderLight,
                    width: AppleTokens.hairline,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${categories.length} mục',
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark ? Colors.white54 : Colors.black54,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: 4),
                    AnimatedRotation(
                      turns: isExpanded ? 0.5 : 0.0,
                      duration: const Duration(milliseconds: 200),
                      child: Icon(
                        CupertinoIcons.chevron_down,
                        size: 11,
                        color: isDark ? Colors.white54 : Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Expanded Menu List
        AnimatedCrossFade(
          duration: const Duration(milliseconds: 220),
          firstCurve: Curves.easeOutCubic,
          secondCurve: Curves.easeInCubic,
          crossFadeState: isExpanded
              ? CrossFadeState.showFirst
              : CrossFadeState.showSecond,
          secondChild: const SizedBox.shrink(),
          firstChild: Padding(
            padding: const EdgeInsets.only(top: 10),
            child: Container(
              decoration: BoxDecoration(
                color: isDark ? AppleTokens.bgDarkSecondary : AppleTokens.bgLightSecondary,
                borderRadius: BorderRadius.circular(AppleTokens.radiusCard),
                border: Border.all(
                  color: isDark ? const Color(0xFF2C2C2E) : AppleTokens.borderLight,
                  width: AppleTokens.hairline,
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(AppleTokens.radiusCard),
                child: Column(
                  children: [
                    // Search bar if more than 5 categories
                    if (categories.length > 5) ...[
                      Padding(
                        padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
                        child: AppleSearchBar(
                          controller: searchController,
                          hintText: 'Tìm danh mục...',
                          height: 38,
                          onChanged: onSearchChanged,
                        ),
                      ),
                      Divider(
                        height: AppleTokens.hairline,
                        color: isDark ? AppleTokens.separatorDark : AppleTokens.separatorLight,
                      ),
                    ],

                    // Constrained scrollable list of categories
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxHeight: 220),
                      child: ListView.separated(
                        shrinkWrap: true,
                        physics: const BouncingScrollPhysics(),
                        padding: EdgeInsets.zero,
                        itemCount: filteredCategories.length + 1,
                        separatorBuilder: (_, _) => Divider(
                          height: AppleTokens.hairline,
                          color: isDark ? AppleTokens.separatorDark : AppleTokens.separatorLight,
                        ),
                        itemBuilder: (context, index) {
                          if (index == 0) {
                            final isAllSelected = selectedCategoryId == null;
                            return _buildCategoryMenuItem(
                              context: context,
                              isSelected: isAllSelected,
                              leading: AppleSquircleBadge(
                                icon: CupertinoIcons.square_grid_2x2,
                                backgroundColor: theme.colorScheme.primary,
                                size: 26,
                                iconSize: 13,
                                radius: 6,
                              ),
                              title: l10n.filterAllCategories,
                              subtitle: '${categories.length} danh mục',
                              onTap: () {
                                HapticFeedback.selectionClick();
                                onSelectCategory(null);
                              },
                            );
                          }

                          final cat = filteredCategories[index - 1];
                          final isSelected = selectedCategoryId == cat.id;
                          final catName = DefaultCategoryLocalization.resolveName(
                            l10n,
                            categoryId: cat.id,
                            fallbackName: cat.name,
                          );

                          return _buildCategoryMenuItem(
                            context: context,
                            isSelected: isSelected,
                            leading: AppleSquircleBadge(
                              icon: AppIconCatalog.resolve(cat.icon),
                              backgroundColor: AppIconCatalog.contrastSafeColor(
                                Color(cat.color),
                                theme.brightness,
                              ),
                              size: 26,
                              iconSize: 13,
                              radius: 6,
                            ),
                            title: catName,
                            subtitle: cat.type == CategoryType.expense
                                ? l10n.expense
                                : l10n.income,
                            onTap: () {
                              HapticFeedback.selectionClick();
                              onSelectCategory(cat.id);
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryMenuItem({
    required BuildContext context,
    required bool isSelected,
    required Widget leading,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return ApplePressable(
      onTap: onTap,
      child: Container(
        color: isSelected
            ? theme.colorScheme.primary.withValues(alpha: isDark ? 0.18 : 0.08)
            : Colors.transparent,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8.5),
        child: Row(
          children: [
            leading,
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                      color: isSelected
                          ? theme.colorScheme.primary
                          : (isDark ? Colors.white : Colors.black87),
                    ),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 10.5,
                      color: isDark ? const Color(0xFF8E8E93) : const Color(0xFF6C6C70),
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(
                CupertinoIcons.checkmark_alt,
                size: 15,
                color: theme.colorScheme.primary,
              ),
          ],
        ),
      ),
    );
  }
}
