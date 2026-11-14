import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:so_thu_chi/core/constants/currency_constants.dart';
import 'package:so_thu_chi/core/l10n/l10n_ext.dart';
import 'package:so_thu_chi/core/responsive/apple_responsive.dart';
import 'package:so_thu_chi/core/theme/apple_theme_tokens.dart';
import 'package:so_thu_chi/core/utils/date_formatter.dart';
import 'package:so_thu_chi/core/widgets/apple_kit.dart';
import 'package:so_thu_chi/core/widgets/empty_state_view.dart';
import 'package:so_thu_chi/core/widgets/skeleton_box.dart';
import 'package:so_thu_chi/features/categories/domain/entities/category.dart';
import 'package:so_thu_chi/features/categories/presentation/controllers/categories_controller.dart';
import 'package:so_thu_chi/features/categories/presentation/widgets/categories_overview_hero_card.dart';
import 'package:so_thu_chi/features/categories/presentation/widgets/category_card_tile.dart';
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

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isLandscape = context.isLandscape;
    final isWide = context.isWideScreen;
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
      appBar: AppleAppBar(
        titleText: l10n.categoriesTitle,
        isLandscape: isLandscape,
        showBackButton: true,
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
                            child: CategoriesOverviewHeroCard(
                              expenseCount: expenseList.length,
                              incomeCount: incomeList.length,
                              defaultCount: defaultCount,
                              customCount: customCount,
                              totalTransactions: txList.length,
                              locale: locale,
                              isDark: isDark,
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
                                (context, index) {
                                  final cat = items[index];
                                  return RepaintBoundary(
                                    child: CategoryCardTile(
                                      key: ValueKey('category_tile_${cat.id}'),
                                      cat: cat,
                                      theme: theme,
                                      isDark: isDark,
                                      txCount: txCounts[cat.id] ?? 0,
                                      monthSpendMinor: txMonthTotals[cat.id] ?? 0,
                                      currency: currency,
                                      locale: locale,
                                      hideBalance: hideBalance,
                                      onEdit: () => _openCategorySheet(existing: cat),
                                      onDelete: () => _deleteCategory(cat),
                                    ),
                                  );
                                },
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
                                    child: RepaintBoundary(
                                      child: CategoryCardTile(
                                        key: ValueKey('category_tile_${item.id}'),
                                        cat: item,
                                        theme: theme,
                                        isDark: isDark,
                                        txCount: txCounts[item.id] ?? 0,
                                        monthSpendMinor: txMonthTotals[item.id] ?? 0,
                                        currency: currency,
                                        locale: locale,
                                        hideBalance: hideBalance,
                                        onEdit: () => _openCategorySheet(existing: item),
                                        onDelete: () => _deleteCategory(item),
                                      ),
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
