import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:so_thu_chi/core/constants/currency_constants.dart';
import 'package:so_thu_chi/core/constants/icon_catalog.dart';
import 'package:so_thu_chi/core/l10n/l10n_ext.dart';
import 'package:so_thu_chi/core/responsive/apple_responsive.dart';
import 'package:so_thu_chi/core/router/app_routes.dart';
import 'package:so_thu_chi/core/theme/app_theme.dart';
import 'package:so_thu_chi/core/theme/apple_theme_tokens.dart';
import 'package:so_thu_chi/core/utils/date_formatter.dart';
import 'package:so_thu_chi/core/utils/money.dart';
import 'package:so_thu_chi/core/widgets/apple_kit.dart';
import 'package:so_thu_chi/core/widgets/empty_state_view.dart';
import 'package:so_thu_chi/core/widgets/skeleton_box.dart';
import 'package:so_thu_chi/features/categories/domain/entities/category.dart';
import 'package:so_thu_chi/features/categories/presentation/controllers/categories_controller.dart';
import 'package:so_thu_chi/features/categories/presentation/widgets/category_form_sheet.dart';
import 'package:so_thu_chi/features/settings/presentation/controllers/settings_controller.dart';
import 'package:so_thu_chi/features/transactions/domain/entities/transaction_entity.dart';
import 'package:so_thu_chi/features/transactions/presentation/controllers/transactions_controller.dart';

class CategoriesScreen extends ConsumerStatefulWidget {
  const CategoriesScreen({super.key});

  @override
  ConsumerState<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends ConsumerState<CategoriesScreen> {
  CategoryType _selectedType = CategoryType.expense;
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

  void _openCategorySheet({Category? existing, String? initialName}) {
    unawaited(HapticFeedback.lightImpact());
    CategoryFormSheet.show(
      context,
      initialType: _selectedType,
      existing: existing,
      initialName: initialName,
    );
  }

  Future<void> _deleteCategory(Category cat) async {
    final l10n = context.l10n;
    final isVi = l10n.localeName.startsWith('vi');
    final confirmed = await showCupertinoModalPopup<bool>(
      context: context,
      builder: (ctx) => CupertinoActionSheet(
        title: Text('${l10n.delete} ${cat.name}'),
        message: Text(
          isVi
              ? 'Bạn có chắc chắn muốn xóa danh mục này? Các giao dịch đã ghi nhận vẫn được bảo lưu an toàn.'
              : 'Are you sure you want to delete this category? Existing transactions will remain safe.',
        ),
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

    if (confirmed == true && mounted) {
      unawaited(HapticFeedback.mediumImpact());
      final messenger = ScaffoldMessenger.of(context);
      final res = await ref
          .read(categoriesActionControllerProvider.notifier)
          .deleteCategory(cat.id);
      if (!mounted) return;
      res.fold(
        onSuccess: (_) {
          messenger.showSnackBar(
            SnackBar(
              content: Text(
                isVi
                    ? 'Đã xóa danh mục "${cat.name}"'
                    : 'Deleted category "${cat.name}"',
              ),
              behavior: SnackBarBehavior.floating,
            ),
          );
        },
        onFailure: (err) {
          messenger.showSnackBar(
            SnackBar(
              content: Text(context.localizeError(err)),
              behavior: SnackBarBehavior.floating,
            ),
          );
        },
      );
    }
  }

  Future<void> _restoreDefaults() async {
    unawaited(HapticFeedback.mediumImpact());
    final messenger = ScaffoldMessenger.of(context);
    final res = await ref
        .read(categoriesActionControllerProvider.notifier)
        .seedDefaultsIfNeeded();
    if (!mounted) return;
    res.fold(
      onSuccess: (_) {
        messenger.showSnackBar(
          SnackBar(
            content: Text(
              context.l10n.localeName.startsWith('vi')
                  ? 'Đã khôi phục các danh mục mẫu mặc định.'
                  : 'Default categories restored.',
            ),
            behavior: SnackBarBehavior.floating,
          ),
        );
      },
      onFailure: (err) {
        messenger.showSnackBar(
          SnackBar(
            content: Text(context.localizeError(err)),
            behavior: SnackBarBehavior.floating,
          ),
        );
      },
    );
  }

  Widget _buildHeroSummaryCard({
    required BuildContext context,
    required ThemeData theme,
    required bool isDark,
    required int expenseCount,
    required int incomeCount,
    required int defaultCount,
    required int customCount,
    required int totalTransactions,
    required String locale,
  }) {
    final totalCategories = expenseCount + incomeCount;
    final isVi = locale.startsWith('vi');

    return AppleGlassCard(
      borderRadius: BorderRadius.circular(AppleTokens.radiusHero),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      theme.colorScheme.primary.withValues(alpha: 0.25),
                      theme.colorScheme.primary.withValues(alpha: 0.08),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(AppleTokens.radiusControl),
                  border: Border.all(
                    color: theme.colorScheme.primary.withValues(alpha: 0.35),
                    width: 1.2,
                  ),
                ),
                child: Icon(
                  CupertinoIcons.square_grid_2x2,
                  color: theme.colorScheme.primary,
                  size: 21,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isVi
                          ? 'TỔNG QUAN PHÂN LOẠI'
                          : 'CATEGORIES OVERVIEW',
                      style: theme.textTheme.labelSmall?.copyWith(
                        letterSpacing: 0.8,
                        fontWeight: FontWeight.w700,
                        color: AppleTokens.systemGray,
                        fontSize: 11,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      isVi
                          ? '$totalCategories danh mục khả dụng'
                          : '$totalCategories categories available',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        fontSize: 16.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Metric Pills Strip: Expense vs Income counts
          Row(
            children: [
              // Expense badge
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppleTokens.rubyExpense.withValues(alpha: isDark ? 0.20 : 0.08),
                    borderRadius: BorderRadius.circular(AppleTokens.radiusControl),
                    border: Border.all(
                      color: AppleTokens.rubyExpense.withValues(alpha: isDark ? 0.35 : 0.20),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.trending_down_rounded,
                        size: 16,
                        color: AppleTokens.rubyExpense,
                      ),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          isVi
                              ? '$expenseCount Khoản chi'
                              : '$expenseCount Expense',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppleTokens.rubyExpense,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),

              // Income badge
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppleTokens.emeraldIncome.withValues(alpha: isDark ? 0.20 : 0.08),
                    borderRadius: BorderRadius.circular(AppleTokens.radiusControl),
                    border: Border.all(
                      color: AppleTokens.emeraldIncome.withValues(alpha: isDark ? 0.35 : 0.20),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.trending_up_rounded,
                        size: 16,
                        color: AppleTokens.emeraldIncome,
                      ),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          isVi
                              ? '$incomeCount Khoản thu'
                              : '$incomeCount Income',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppleTokens.emeraldIncome,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          // Visual Proportion Ratio Bar
          if (totalCategories > 0) ...[
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(AppleTokens.radiusPill),
              child: SizedBox(
                height: 6,
                child: Row(
                  children: [
                    if (expenseCount > 0)
                      Expanded(
                        flex: expenseCount,
                        child: Container(color: AppleTokens.rubyExpense),
                      ),
                    if (incomeCount > 0)
                      Expanded(
                        flex: incomeCount,
                        child: Container(color: AppleTokens.emeraldIncome),
                      ),
                  ],
                ),
              ),
            ),
          ],

          // Category Telemetry Strip (Default Templates, Custom Categories, Categorized Txs)
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.04)
                  : Colors.black.withValues(alpha: 0.03),
              borderRadius: BorderRadius.circular(AppleTokens.radiusControl),
            ),
            child: Row(
              children: [
                // 1. Default categories
                Expanded(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        CupertinoIcons.checkmark_seal_fill,
                        size: 14,
                        color: AppleTokens.systemBlue,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isVi ? 'Mẫu chuẩn' : 'Templates',
                              style: const TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w500,
                                color: AppleTokens.systemGray,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              '$defaultCount',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                fontFeatures: AppTheme.tabularFigures,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 1,
                  height: 24,
                  color: isDark ? AppleTokens.separatorDark : AppleTokens.separatorLight,
                ),
                const SizedBox(width: 10),

                // 2. Custom categories
                Expanded(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        CupertinoIcons.pencil_circle_fill,
                        size: 14,
                        color: AppleTokens.systemPurple,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isVi ? 'Tùy chỉnh' : 'Custom',
                              style: const TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w500,
                                color: AppleTokens.systemGray,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              '$customCount',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                fontFeatures: AppTheme.tabularFigures,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 1,
                  height: 24,
                  color: isDark ? AppleTokens.separatorDark : AppleTokens.separatorLight,
                ),
                const SizedBox(width: 10),

                // 3. Categorized transactions
                Expanded(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        CupertinoIcons.doc_text_fill,
                        size: 14,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isVi ? 'Đã gán GD' : 'Assigned',
                              style: const TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w500,
                                color: AppleTokens.systemGray,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              '$totalTransactions GD',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                fontFeatures: AppTheme.tabularFigures,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryCard({
    required BuildContext context,
    required Category cat,
    required ThemeData theme,
    required bool isDark,
    required int txCount,
    required int monthSpendMinor,
    required String currency,
    required String locale,
    required bool hideBalance,
  }) {
    final l10n = context.l10n;
    final color = AppIconCatalog.contrastSafeColor(
      Color(cat.color),
      theme.brightness,
    );
    final displayName = cat.isDefault
        ? DefaultCategoryLocalization.resolveName(
            l10n,
            categoryId: cat.id,
            fallbackName: cat.name,
          )
        : cat.name;

    final isIncome = cat.type == CategoryType.income;
    final monthMoney = Money(minorUnits: monthSpendMinor, currencyCode: currency);

    return ApplePressable(
      borderRadius: BorderRadius.circular(AppleTokens.radiusCard),
      onTap: () {
        unawaited(HapticFeedback.lightImpact());
        context.push(AppRoutes.categoryDetail(cat.id));
      },
      child: AppleGlassCard(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        borderRadius: BorderRadius.circular(AppleTokens.radiusCard),
        child: Row(
          children: [
            // Squircle Badge with glowing border and subtle shadow
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: color.withValues(alpha: isDark ? 0.22 : 0.14),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: color.withValues(alpha: isDark ? 0.40 : 0.28),
                  width: 1.2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: color.withValues(alpha: isDark ? 0.22 : 0.14),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(
                AppIconCatalog.resolve(cat.icon),
                color: color,
                size: 24,
              ),
            ),
            const SizedBox(width: 14),

            // Middle Column: Title & Metadata Badges
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    displayName,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      fontSize: 15.5,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      // Default or Custom badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6.5, vertical: 2),
                        decoration: BoxDecoration(
                          color: cat.isDefault
                              ? AppleTokens.systemBlue.withValues(alpha: 0.12)
                              : AppleTokens.systemPurple.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(AppleTokens.radiusPill),
                        ),
                        child: Text(
                          cat.isDefault
                              ? l10n.defaultCategoryBadge
                              : (locale.startsWith('vi') ? 'Tùy chỉnh' : 'Custom'),
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                            color: cat.isDefault
                                ? AppleTokens.systemBlue
                                : AppleTokens.systemPurple,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      // Transaction count indicator
                      Flexible(
                        child: Text(
                          txCount > 0
                              ? (locale.startsWith('vi') ? '$txCount GD' : '$txCount tx')
                              : (locale.startsWith('vi') ? 'Chưa dùng' : 'Unused'),
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            fontFeatures: AppTheme.tabularFigures,
                            color: AppleTokens.systemGray,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Right Column: Month Spend & Actions
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (monthSpendMinor > 0)
                  Text(
                    isIncome
                        ? '+${monthMoney.format(locale: locale, masked: hideBalance)}'
                        : '-${monthMoney.format(locale: locale, masked: hideBalance)}',
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      fontFeatures: AppTheme.tabularFigures,
                      color: isIncome ? AppleTokens.emeraldIncome : AppleTokens.rubyExpense,
                    ),
                  )
                else
                  Text(
                    '0 ${currency == 'VND' ? '₫' : currency}',
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w500,
                      color: isDark ? Colors.white24 : Colors.black26,
                    ),
                  ),
                const SizedBox(height: 2),
                ApplePopupMenuButton<String>(
                  tooltip: l10n.moreOptions,
                  iconSize: 18,
                  size: 26,
                  onSelected: (value) {
                    if (value == 'detail') {
                      context.push(AppRoutes.categoryDetail(cat.id));
                    } else if (value == 'edit') {
                      _openCategorySheet(existing: cat);
                    } else if (value == 'delete') {
                      _deleteCategory(cat);
                    }
                  },
                  itemBuilder: (ctx) => [
                    ApplePopupMenuItem(
                      value: 'detail',
                      icon: CupertinoIcons.chart_bar_alt_fill,
                      title: locale.startsWith('vi')
                          ? 'Xem báo cáo chi tiết'
                          : 'View detailed report',
                    ),
                    ApplePopupMenuItem(
                      value: 'edit',
                      icon: Icons.edit_outlined,
                      title: l10n.edit,
                    ),
                    ApplePopupMenuItem(
                      value: 'delete',
                      icon: CupertinoIcons.trash,
                      title: l10n.delete,
                      isDestructive: true,
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isLandscape = context.isLandscape;
    final isWide = context.isWideScreen;
    final appBarHeight = isLandscape
        ? AppleTokens.appBarHeightLandscape
        : AppleTokens.appBarHeightPortrait;
    final scrollBottomPadding = isWide
        ? AppleTokens.scrollBottomPaddingLandscape + 42
        : AppleTokens.scrollBottomPaddingWithFab;

    final categoriesAsync = ref.watch(categoriesStreamProvider);
    final expenseList = ref.watch(expenseCategoriesProvider);
    final incomeList = ref.watch(incomeCategoriesProvider);
    final currentList = _selectedType == CategoryType.expense ? expenseList : incomeList;

    // Currency and settings
    final settings = ref.watch(settingsControllerProvider).value;
    final locale = settings?.localeCode ?? 'vi';
    final currency = settings?.currencyCode ?? AppCurrencies.defaultCode;
    final hideBalance = settings?.hideBalance ?? false;

    // Collect transactions count & month spend per category safely
    final transactionsAsync = ref.watch(transactionsStreamProvider);
    final txList = transactionsAsync.asData?.value ?? const <TransactionEntity>[];
    final txCounts = <String, int>{};
    final txMonthTotals = <String, int>{};
    final now = DateTime.now();

    for (final tx in txList) {
      txCounts[tx.categoryId] = (txCounts[tx.categoryId] ?? 0) + 1;
      if (tx.currency == currency && AppDateUtils.isSameMonth(tx.date, now)) {
        txMonthTotals[tx.categoryId] = (txMonthTotals[tx.categoryId] ?? 0) + tx.amount;
      }
    }

    final defaultCount = expenseList.where((c) => c.isDefault).length +
        incomeList.where((c) => c.isDefault).length;
    final customCount = expenseList.where((c) => !c.isDefault).length +
        incomeList.where((c) => !c.isDefault).length;

    // Filter items based on search query
    final query = _searchQuery.toLowerCase();
    final items = currentList.where((cat) {
      if (query.isEmpty) return true;
      final localizedName = cat.isDefault
          ? DefaultCategoryLocalization.resolveName(
              l10n,
              categoryId: cat.id,
              fallbackName: cat.name,
            )
          : cat.name;
      return localizedName.toLowerCase().contains(query) ||
          cat.name.toLowerCase().contains(query);
    }).toList(growable: false);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        toolbarHeight: appBarHeight,
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleSpacing: 0,
        leading: const AppleBackButton(),
        title: AppleHeaderTitle(
          title: l10n.categoriesTitle,
          isLandscape: isLandscape,
        ),
        actions: [
          ApplePopupMenuButton<String>(
            tooltip: l10n.moreOptions,
            icon: CupertinoIcons.ellipsis_circle,
            iconSize: 22,
            size: 38,
            onSelected: (value) {
              if (value == 'restore') {
                _restoreDefaults();
              } else if (value == 'add') {
                _openCategorySheet();
              }
            },
            itemBuilder: (ctx) => [
              ApplePopupMenuItem(
                value: 'add',
                icon: Icons.add_circle_outline_rounded,
                title: l10n.addCategory,
              ),
              ApplePopupMenuItem(
                value: 'restore',
                icon: Icons.restart_alt_rounded,
                title: l10n.localeName.startsWith('vi')
                    ? 'Khôi phục mẫu mặc định'
                    : 'Restore default templates',
              ),
            ],
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        top: false,
        bottom: false,
          child: NotificationListener<UserScrollNotification>(
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
            child: categoriesAsync.when(
              loading: () => const SkeletonListView(),
              error: (err, _) => Center(
                child: Text(context.localizeError(err)),
              ),
              data: (_) {
                return Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1024),
                    child: CustomScrollView(
                      slivers: [
                        // 1. Overview Hero Summary Card
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                            child: _buildHeroSummaryCard(
                              context: context,
                              theme: theme,
                              isDark: isDark,
                              expenseCount: expenseList.length,
                              incomeCount: incomeList.length,
                              defaultCount: defaultCount,
                              customCount: customCount,
                              totalTransactions: txList.length,
                              locale: locale,
                            ),
                          ),
                        ),

                        // 2. Search & Segmented Sliding Tabs Controls
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                            child: Center(
                              child: ConstrainedBox(
                                constraints: const BoxConstraints(maxWidth: 680),
                                child: Column(
                                  children: [
                                    // Apple Search Bar
                                    AppleTextField(
                                      controller: _searchController,
                                      placeholder: l10n.searchCategories,
                                      prefixIcon: const Icon(CupertinoIcons.search, size: 18),
                                      suffixIcon: _searchQuery.isNotEmpty
                                          ? IconButton(
                                              icon: const Icon(
                                                CupertinoIcons.clear_thick_circled,
                                                size: 17,
                                              ),
                                              onPressed: () {
                                                unawaited(HapticFeedback.lightImpact());
                                                _searchController.clear();
                                              },
                                            )
                                          : null,
                                    ),
                                    const SizedBox(height: 10),
                                    // Lucian Segmented Sliding Pill Tabs
                                    LucianSlidingPillTabs<CategoryType>(
                                      items: [
                                        LucianTabItem(
                                          value: CategoryType.expense,
                                          label: l10n.expense,
                                          icon: Icons.trending_down_rounded,
                                          badgeCount: expenseList.length,
                                          activeColor: LucianTokens.resolveDanger(isDark),
                                        ),
                                        LucianTabItem(
                                          value: CategoryType.income,
                                          label: l10n.income,
                                          icon: Icons.trending_up_rounded,
                                          badgeCount: incomeList.length,
                                          activeColor: LucianTokens.resolveMint(isDark),
                                        ),
                                      ],
                                      selected: _selectedType,
                                      onChanged: (type) {
                                        unawaited(HapticFeedback.selectionClick());
                                        setState(() => _selectedType = type);
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),

                        // 3. Search result counter indicator
                        if (_searchQuery.isNotEmpty)
                          SliverToBoxAdapter(
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                              child: Row(
                                children: [
                                  Text(
                                    l10n.localeName.startsWith('vi')
                                        ? 'Tìm thấy ${items.length} danh mục phù hợp'
                                        : 'Found ${items.length} matching categories',
                                    style: theme.textTheme.labelMedium?.copyWith(
                                      fontWeight: FontWeight.w600,
                                      color: AppleTokens.systemGray,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                        // 4. Category items or Empty State
                        if (items.isEmpty)
                          SliverFillRemaining(
                            hasScrollBody: false,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 36,
                              ),
                              child: _searchQuery.isNotEmpty
                                  ? EmptyStateView(
                                      icon: CupertinoIcons.search,
                                      title: l10n.noCategoriesFound,
                                      subtitle: l10n.localeName.startsWith('vi')
                                          ? 'Không tìm thấy danh mục nào phù hợp với từ khóa "$_searchQuery".'
                                          : 'No categories found matching "$_searchQuery".',
                                      actionLabel: l10n.localeName.startsWith('vi')
                                          ? 'Tạo danh mục "$_searchQuery"'
                                          : 'Create "$_searchQuery"',
                                      onAction: () => _openCategorySheet(
                                        initialName: _searchQuery,
                                      ),
                                    )
                                  : EmptyStateView(
                                      icon: CupertinoIcons.folder_badge_plus,
                                      title: l10n.noCategories,
                                      subtitle:
                                          _selectedType == CategoryType.expense
                                              ? (l10n.localeName.startsWith('vi')
                                                  ? 'Chưa có danh mục chi tiêu nào.'
                                                  : 'No expense categories yet.')
                                              : (l10n.localeName.startsWith('vi')
                                                  ? 'Chưa có danh mục thu nhập nào.'
                                                  : 'No income categories yet.'),
                                      actionLabel: l10n.addCategory,
                                      onAction: _openCategorySheet,
                                    ),
                            ),
                          )
                        else if (isWide)
                          SliverPadding(
                            padding: EdgeInsets.fromLTRB(
                              16,
                              4,
                              16,
                              scrollBottomPadding,
                            ),
                            sliver: SliverGrid(
                              gridDelegate:
                                  const SliverGridDelegateWithMaxCrossAxisExtent(
                                maxCrossAxisExtent: 440,
                                mainAxisExtent: 88,
                                crossAxisSpacing: 12,
                                mainAxisSpacing: 10,
                              ),
                              delegate: SliverChildBuilderDelegate(
                                (context, index) => _buildCategoryCard(
                                  context: context,
                                  cat: items[index],
                                  theme: theme,
                                  isDark: isDark,
                                  txCount: txCounts[items[index].id] ?? 0,
                                  monthSpendMinor: txMonthTotals[items[index].id] ?? 0,
                                  currency: currency,
                                  locale: locale,
                                  hideBalance: hideBalance,
                                ),
                                childCount: items.length,
                              ),
                            ),
                          )
                        else
                          SliverPadding(
                            padding: EdgeInsets.fromLTRB(
                              16,
                              4,
                              16,
                              scrollBottomPadding,
                            ),
                            sliver: SliverList(
                              delegate: SliverChildBuilderDelegate(
                                (context, index) {
                                  final item = items[index];
                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 10),
                                    child: _buildCategoryCard(
                                      context: context,
                                      cat: item,
                                      theme: theme,
                                      isDark: isDark,
                                      txCount: txCounts[item.id] ?? 0,
                                      monthSpendMinor: txMonthTotals[item.id] ?? 0,
                                      currency: currency,
                                      locale: locale,
                                      hideBalance: hideBalance,
                                    ),
                                  );
                                },
                                childCount: items.length,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      floatingActionButtonLocation: const AppleFloatingActionButtonLocation(),
      floatingActionButton: AppleAdaptiveExpandableFab(
        heroTag: 'categories_add_fab',
        isVisible: _isFabVisible,
        isExpanded: _isFabExpanded,
        icon: const Icon(Icons.add_rounded),
        label: Text(l10n.addCategory),
        onPressed: _openCategorySheet,
        tooltip: l10n.addCategory,
      ),
    );
  }
}
