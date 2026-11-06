import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:so_thu_chi/core/constants/icon_catalog.dart';
import 'package:so_thu_chi/core/l10n/l10n_ext.dart';
import 'package:so_thu_chi/core/responsive/apple_responsive.dart';
import 'package:so_thu_chi/core/router/app_routes.dart';
import 'package:so_thu_chi/core/theme/apple_theme_tokens.dart';
import 'package:so_thu_chi/core/widgets/apple_kit.dart';
import 'package:so_thu_chi/core/widgets/skeleton_box.dart';
import 'package:so_thu_chi/features/categories/domain/entities/category.dart';
import 'package:so_thu_chi/features/categories/presentation/controllers/categories_controller.dart';
import 'package:so_thu_chi/features/categories/presentation/widgets/category_form_sheet.dart';

class CategoriesScreen extends ConsumerStatefulWidget {
  const CategoriesScreen({super.key});

  @override
  ConsumerState<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends ConsumerState<CategoriesScreen> {
  CategoryType _selectedType = CategoryType.expense;
  bool _isFabExpanded = true;
  bool _isFabVisible = true;

  void _openCategorySheet({Category? existing}) {
    CategoryFormSheet.show(
      context,
      initialType: _selectedType,
      existing: existing,
    );
  }

  Future<void> _deleteCategory(Category cat) async {
    final messenger = ScaffoldMessenger.of(context);
    final res = await ref
        .read(categoriesActionControllerProvider.notifier)
        .deleteCategory(cat.id);
    if (!mounted) return;
    res.fold(
      onSuccess: (_) {},
      onFailure: (err) {
        messenger.showSnackBar(
          SnackBar(content: Text(context.localizeError(err))),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isLandscape = context.isLandscape;
    final isWide = context.isWideScreen;
    final appBarHeight = isLandscape
        ? AppleTokens.appBarHeightLandscape
        : AppleTokens.appBarHeightPortrait;
    final scrollBottomPadding = isWide
        ? AppleTokens.scrollBottomPaddingLandscape + 42
        : AppleTokens.scrollBottomPaddingWithFab;

    final categoriesAsync = ref.watch(categoriesStreamProvider);
    final items = _selectedType == CategoryType.expense
        ? ref.watch(expenseCategoriesProvider)
        : ref.watch(incomeCategoriesProvider);

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: appBarHeight,
        title: Text(l10n.categoriesTitle),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: SizedBox(
                  width: double.infinity,
                  child: SegmentedButton<CategoryType>(
                    segments: [
                      ButtonSegment(
                        value: CategoryType.expense,
                        icon: const Icon(Icons.trending_down_rounded),
                        label: Text(l10n.expense),
                      ),
                      ButtonSegment(
                        value: CategoryType.income,
                        icon: const Icon(Icons.trending_up_rounded),
                        label: Text(l10n.income),
                      ),
                    ],
                    selected: {_selectedType},
                    onSelectionChanged: (set) {
                      setState(() => _selectedType = set.first);
                    },
                  ),
                ),
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
                error: (err, _) =>
                    Center(child: Text(context.localizeError(err))),
                data: (_) {
                  Widget buildTile(Category cat) {
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

                    return ApplePressable(
                      borderRadius:
                          BorderRadius.circular(AppleTokens.radiusCard),
                      onTap: () => context.push(AppRoutes.categoryDetail(cat.id)),
                      child: AppleGlassCard(
                        padding: EdgeInsets.zero,
                        borderRadius: BorderRadius.circular(AppleTokens.radiusCard),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 4,
                          ),
                          leading: Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: color.withValues(alpha: 0.16),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              AppIconCatalog.resolve(cat.icon),
                              color: color,
                              size: 22,
                            ),
                          ),
                          title: Text(
                            displayName,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          subtitle: cat.isDefault
                              ? Text(
                                  l10n.defaultCategoryBadge,
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: scheme.onSurfaceVariant,
                                  ),
                                )
                              : null,
                          trailing: PopupMenuButton<String>(
                            tooltip: l10n.moreOptions,
                            onSelected: (value) {
                              if (value == 'edit') {
                                _openCategorySheet(existing: cat);
                              } else if (value == 'delete') {
                                _deleteCategory(cat);
                              }
                            },
                            itemBuilder: (ctx) => [
                              PopupMenuItem(value: 'edit', child: Text(l10n.edit)),
                              if (!cat.isDefault)
                                PopupMenuItem(
                                  value: 'delete',
                                  child: Text(l10n.delete),
                                ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }

                  return Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1024),
                      child: isWide
                          ? GridView.builder(
                              padding: EdgeInsets.fromLTRB(
                                16,
                                4,
                                16,
                                scrollBottomPadding,
                              ),
                              gridDelegate:
                                  const SliverGridDelegateWithMaxCrossAxisExtent(
                                maxCrossAxisExtent: 440,
                                mainAxisExtent: 74,
                                crossAxisSpacing: 12,
                                mainAxisSpacing: 10,
                              ),
                              itemCount: items.length,
                              itemBuilder: (context, index) =>
                                  buildTile(items[index]),
                            )
                          : ListView.separated(
                              padding: EdgeInsets.fromLTRB(
                                16,
                                4,
                                16,
                                scrollBottomPadding,
                              ),
                              itemCount: items.length,
                              separatorBuilder: (_, _) =>
                                  const SizedBox(height: 10),
                              itemBuilder: (context, index) =>
                                  buildTile(items[index]),
                            ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
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
