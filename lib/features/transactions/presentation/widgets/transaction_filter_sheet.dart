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

class TransactionFilterBottomSheet extends ConsumerWidget {
  const TransactionFilterBottomSheet({super.key});

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

  void _openCategoryPicker({
    required BuildContext context,
    required WidgetRef ref,
    required List<Category> categories,
    required String? selectedCategoryId,
  }) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _CategoryPickerModalSheet(
        categories: categories,
        selectedCategoryId: selectedCategoryId,
        onSelected: (catId) {
          ref.read(transactionFilterProvider.notifier).setCategory(catId);
        },
      ),
    );
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
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final filter = ref.watch(transactionFilterProvider);
    final allCategories = ref.watch(categoriesStreamProvider).value ?? const [];
    final wallets = ref.watch(accountsStreamProvider).value ?? const [];
    final settings = ref.watch(settingsControllerProvider).value;
    final locale = settings?.localeCode ?? 'vi';

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
    final sheetHeight = MediaQuery.of(context).size.height * (isLandscape ? 0.94 : 0.82);

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

                    // Card 2: Ví & Danh mục
                    AppleGlassCard(
                      padding: const EdgeInsets.all(14),
                      borderRadius: BorderRadius.circular(AppleTokens.radiusCard),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // 3. Ví & tài khoản
                          _buildSectionHeader(
                            context: context,
                            icon: CupertinoIcons.creditcard,
                            title: l10n.walletsTitle,
                            trailing: '${wallets.length} ví',
                          ),
                          _WalletCapsuleSelector(
                            wallets: wallets,
                            selectedAccountId: filter.accountId,
                            onSelectAccount: (accId) {
                              ref.read(transactionFilterProvider.notifier).setAccount(accId);
                            },
                          ),

                          const SizedBox(height: 14),
                          Divider(
                            height: AppleTokens.hairline,
                            color: isDark ? AppleTokens.separatorDark : AppleTokens.separatorLight,
                          ),
                          const SizedBox(height: 12),

                          // 4. Danh mục thu chi
                          _buildSectionHeader(
                            context: context,
                            icon: CupertinoIcons.square_grid_2x2,
                            title: l10n.categoriesTitle,
                            trailing: filter.categoryId != null
                                ? 'Đang lọc theo danh mục'
                                : null,
                          ),
                          _CategoryCompactSelector(
                            categories: visibleCategories,
                            selectedCategoryId: filter.categoryId,
                            selectedCategory: selectedCategory,
                            onSelectCategory: (catId) {
                              ref.read(transactionFilterProvider.notifier).setCategory(catId);
                            },
                            onOpenAll: () {
                              _openCategoryPicker(
                                context: context,
                                ref: ref,
                                categories: visibleCategories,
                                selectedCategoryId: filter.categoryId,
                              );
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
        l10n.filterDateAll,
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

class _WalletCapsuleSelector extends StatelessWidget {
  const _WalletCapsuleSelector({
    required this.wallets,
    required this.selectedAccountId,
    required this.onSelectAccount,
  });

  final List<Account> wallets;
  final String? selectedAccountId;
  final ValueChanged<String?> onSelectAccount;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final l10n = context.l10n;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: [
          // All Wallets Pill
          _buildCapsule(
            context: context,
            isSelected: selectedAccountId == null,
            iconWidget: Icon(
              CupertinoIcons.creditcard,
              size: 12,
              color: selectedAccountId == null
                  ? theme.colorScheme.primary
                  : (isDark ? const Color(0xFF8E8E93) : const Color(0xFF6C6C70)),
            ),
            label: l10n.filterAllWallets,
            onTap: () => onSelectAccount(null),
          ),
          for (final wallet in wallets)
            _buildCapsule(
              context: context,
              isSelected: selectedAccountId == wallet.id,
              iconWidget: Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: AppIconCatalog.contrastSafeColor(
                    Color(wallet.color),
                    theme.brightness,
                  ),
                  shape: BoxShape.circle,
                ),
              ),
              label: wallet.name,
              onTap: () => onSelectAccount(
                selectedAccountId == wallet.id ? null : wallet.id,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCapsule({
    required BuildContext context,
    required bool isSelected,
    required Widget iconWidget,
    required String label,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: ApplePressable(
        onTap: onTap,
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
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              iconWidget,
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected
                      ? theme.colorScheme.primary
                      : (isDark ? Colors.white : Colors.black87),
                ),
              ),
              if (isSelected) ...[
                const SizedBox(width: 4),
                Icon(
                  CupertinoIcons.checkmark_alt,
                  size: 11,
                  color: theme.colorScheme.primary,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _CategoryCompactSelector extends StatelessWidget {
  const _CategoryCompactSelector({
    required this.categories,
    required this.selectedCategoryId,
    required this.selectedCategory,
    required this.onSelectCategory,
    required this.onOpenAll,
  });

  final List<Category> categories;
  final String? selectedCategoryId;
  final Category? selectedCategory;
  final ValueChanged<String?> onSelectCategory;
  final VoidCallback onOpenAll;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final l10n = context.l10n;

    // Show active category tile if a category is selected
    if (selectedCategory != null) {
      final catName = DefaultCategoryLocalization.resolveName(
        l10n,
        categoryId: selectedCategory!.id,
        fallbackName: selectedCategory!.name,
      );

      return Container(
        padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
        decoration: BoxDecoration(
          color: theme.colorScheme.primary.withValues(alpha: isDark ? 0.18 : 0.09),
          borderRadius: BorderRadius.circular(AppleTokens.radiusCard),
          border: Border.all(
            color: theme.colorScheme.primary.withValues(alpha: 0.35),
            width: 1.2,
          ),
        ),
        child: Row(
          children: [
            AppleSquircleBadge(
              icon: AppIconCatalog.resolve(selectedCategory!.icon),
              backgroundColor: AppIconCatalog.contrastSafeColor(
                Color(selectedCategory!.color),
                theme.brightness,
              ),
              size: 32,
              iconSize: 15,
              radius: 8,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    catName,
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    selectedCategory!.type == CategoryType.expense
                        ? l10n.expense
                        : l10n.income,
                    style: TextStyle(
                      fontSize: 10.5,
                      color: isDark ? const Color(0xFF8E8E93) : const Color(0xFF6C6C70),
                    ),
                  ),
                ],
              ),
            ),
            ApplePressable(
              onTap: onOpenAll,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
            const SizedBox(width: 2),
            GestureDetector(
              onTap: () {
                HapticFeedback.lightImpact();
                onSelectCategory(null);
              },
              child: Icon(
                CupertinoIcons.clear_circled_solid,
                size: 16,
                color: AppleTokens.systemRed.withValues(alpha: 0.8),
              ),
            ),
          ],
        ),
      );
    }

    // Unselected state: show "All categories" + top 5 popular categories + "See all" button
    final topCategories = categories.take(5).toList();

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: [
          // All Categories Pill
          _buildPill(
            context: context,
            isSelected: true,
            icon: CupertinoIcons.square_grid_2x2,
            iconColor: theme.colorScheme.primary,
            label: l10n.filterAllCategories,
            onTap: () => onSelectCategory(null),
          ),
          for (final cat in topCategories)
            _buildPill(
              context: context,
              isSelected: false,
              icon: AppIconCatalog.resolve(cat.icon),
              iconColor: AppIconCatalog.contrastSafeColor(
                Color(cat.color),
                theme.brightness,
              ),
              label: DefaultCategoryLocalization.resolveName(
                l10n,
                categoryId: cat.id,
                fallbackName: cat.name,
              ),
              onTap: () => onSelectCategory(cat.id),
            ),
          // "See all" pill
          Padding(
            padding: const EdgeInsets.only(right: 6),
            child: ApplePressable(
              onTap: onOpenAll,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6.5),
                decoration: BoxDecoration(
                  color: isDark ? AppleTokens.bgDarkSecondary : AppleTokens.bgLightSecondary,
                  borderRadius: BorderRadius.circular(AppleTokens.radiusPill),
                  border: Border.all(
                    color: theme.colorScheme.primary.withValues(alpha: 0.3),
                    width: AppleTokens.hairline,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      CupertinoIcons.ellipsis,
                      size: 11,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      'Tất cả (${categories.length})',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPill({
    required BuildContext context,
    required bool isSelected,
    required IconData icon,
    required Color iconColor,
    required String label,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: ApplePressable(
        onTap: onTap,
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
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 12,
                color: isSelected ? theme.colorScheme.primary : iconColor,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected
                      ? theme.colorScheme.primary
                      : (isDark ? Colors.white : Colors.black87),
                ),
              ),
              if (isSelected) ...[
                const SizedBox(width: 4),
                Icon(
                  CupertinoIcons.checkmark_alt,
                  size: 11,
                  color: theme.colorScheme.primary,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _CategoryPickerModalSheet extends StatefulWidget {
  const _CategoryPickerModalSheet({
    required this.categories,
    required this.selectedCategoryId,
    required this.onSelected,
  });

  final List<Category> categories;
  final String? selectedCategoryId;
  final ValueChanged<String?> onSelected;

  @override
  State<_CategoryPickerModalSheet> createState() => _CategoryPickerModalSheetState();
}

class _CategoryPickerModalSheetState extends State<_CategoryPickerModalSheet> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final l10n = context.l10n;

    final filtered = widget.categories.where((c) {
      if (_query.isEmpty) return true;
      final name = DefaultCategoryLocalization.resolveName(
        l10n,
        categoryId: c.id,
        fallbackName: c.name,
      ).toLowerCase();
      return name.contains(_query.toLowerCase());
    }).toList();

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.75,
      ),
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
          children: [
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
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Text(
                    'Chọn danh mục',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      fontSize: 17,
                    ),
                  ),
                  const Spacer(),
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    minimumSize: const Size(28, 28),
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
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: CupertinoSearchTextField(
                controller: _searchController,
                placeholder: 'Tìm danh mục...',
                onChanged: (val) {
                  setState(() => _query = val.trim());
                },
              ),
            ),
            const SizedBox(height: 10),
            Divider(
              height: AppleTokens.hairline,
              color: isDark ? AppleTokens.separatorDark : AppleTokens.separatorLight,
            ),
            Expanded(
              child: ListView.separated(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                itemCount: filtered.length + 1,
                separatorBuilder: (_, _) => Divider(
                  height: AppleTokens.hairline,
                  color: isDark ? AppleTokens.separatorDark : AppleTokens.separatorLight,
                ),
                itemBuilder: (context, index) {
                  if (index == 0) {
                    final isAllSelected = widget.selectedCategoryId == null;
                    return ListTile(
                      dense: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 4),
                      leading: AppleSquircleBadge(
                        icon: CupertinoIcons.square_grid_2x2,
                        backgroundColor: theme.colorScheme.primary,
                        size: 32,
                        iconSize: 15,
                        radius: 8,
                      ),
                      title: Text(
                        l10n.filterAllCategories,
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: isAllSelected ? FontWeight.w700 : FontWeight.w500,
                          color: isAllSelected
                              ? theme.colorScheme.primary
                              : (isDark ? Colors.white : Colors.black87),
                        ),
                      ),
                      trailing: isAllSelected
                          ? Icon(
                              CupertinoIcons.checkmark_alt,
                              size: 16,
                              color: theme.colorScheme.primary,
                            )
                          : null,
                      onTap: () {
                        HapticFeedback.selectionClick();
                        widget.onSelected(null);
                        Navigator.of(context).pop();
                      },
                    );
                  }

                  final cat = filtered[index - 1];
                  final isSelected = widget.selectedCategoryId == cat.id;
                  final catName = DefaultCategoryLocalization.resolveName(
                    l10n,
                    categoryId: cat.id,
                    fallbackName: cat.name,
                  );

                  return ListTile(
                    dense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 4),
                    leading: AppleSquircleBadge(
                      icon: AppIconCatalog.resolve(cat.icon),
                      backgroundColor: AppIconCatalog.contrastSafeColor(
                        Color(cat.color),
                        theme.brightness,
                      ),
                      size: 32,
                      iconSize: 15,
                      radius: 8,
                    ),
                    title: Text(
                      catName,
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                        color: isSelected
                            ? theme.colorScheme.primary
                            : (isDark ? Colors.white : Colors.black87),
                      ),
                    ),
                    subtitle: Text(
                      cat.type == CategoryType.expense
                          ? l10n.expense
                          : l10n.income,
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark ? const Color(0xFF8E8E93) : const Color(0xFF6C6C70),
                      ),
                    ),
                    trailing: isSelected
                        ? Icon(
                            CupertinoIcons.checkmark_alt,
                            size: 16,
                            color: theme.colorScheme.primary,
                          )
                        : null,
                    onTap: () {
                      HapticFeedback.selectionClick();
                      widget.onSelected(cat.id);
                      Navigator.of(context).pop();
                    },
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
