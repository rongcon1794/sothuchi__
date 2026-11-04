import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:so_thu_chi/core/constants/icon_catalog.dart';
import 'package:so_thu_chi/core/l10n/l10n_ext.dart';
import 'package:so_thu_chi/core/theme/apple_theme_tokens.dart';
import 'package:so_thu_chi/core/widgets/apple_kit.dart';
import 'package:so_thu_chi/core/widgets/icon_and_color_picker.dart';
import 'package:so_thu_chi/core/widgets/skeleton_box.dart';
import 'package:so_thu_chi/features/categories/domain/entities/category.dart';
import 'package:so_thu_chi/features/categories/presentation/controllers/categories_controller.dart';

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
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _CategoryFormSheet(
        initialType: _selectedType,
        existing: existing,
      ),
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
    final categoriesAsync = ref.watch(categoriesStreamProvider);
    final items = _selectedType == CategoryType.expense
        ? ref.watch(expenseCategoriesProvider)
        : ref.watch(incomeCategoriesProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.categoriesTitle),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
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
                data: (_) => ListView.separated(
                  padding: const EdgeInsets.fromLTRB(
                    16,
                    4,
                    16,
                    AppleTokens.scrollBottomPaddingWithFab,
                  ),
                itemCount: items.length,
                separatorBuilder: (_, _) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final cat = items[index];
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
                    onTap: () => _openCategorySheet(existing: cat),
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
                },
              ),
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

class _CategoryFormSheet extends ConsumerStatefulWidget {
  const _CategoryFormSheet({
    required this.initialType,
    this.existing,
  });

  final CategoryType initialType;
  final Category? existing;

  @override
  ConsumerState<_CategoryFormSheet> createState() => _CategoryFormSheetState();
}

class _CategoryFormSheetState extends ConsumerState<_CategoryFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late CategoryType _type;
  late String _icon;
  late int _color;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    _nameController = TextEditingController(text: existing?.name ?? '');
    _type = existing?.type ?? widget.initialType;
    _icon = existing?.icon ?? 'food';
    _color = existing?.color ?? AppIconCatalog.palette.first;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final ctrl = ref.read(categoriesActionControllerProvider.notifier);
    final existing = widget.existing;
    final result = existing == null
        ? await ctrl.createCategory(
            name: _nameController.text,
            type: _type,
            icon: _icon,
            color: _color,
          )
        : await ctrl.updateCategory(
            existing.copyWith(
              name: _nameController.text,
              type: _type,
              icon: _icon,
              color: _color,
            ),
          );

    if (!mounted) return;
    result.fold(
      onSuccess: (_) => Navigator.of(context).pop(),
      onFailure: (err) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(context.localizeError(err))));
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);

    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        bottom: MediaQuery.viewInsetsOf(context).bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                widget.existing == null ? l10n.addCategory : l10n.editCategory,
                style: theme.textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              SegmentedButton<CategoryType>(
                segments: [
                  ButtonSegment(
                    value: CategoryType.expense,
                    label: Text(l10n.expense),
                  ),
                  ButtonSegment(
                    value: CategoryType.income,
                    label: Text(l10n.income),
                  ),
                ],
                selected: {_type},
                onSelectionChanged: widget.existing != null
                    ? null
                    : (s) => setState(() => _type = s.first),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nameController,
                maxLength: 100,
                decoration: InputDecoration(
                  labelText: l10n.categoryName,
                  hintText: l10n.categoryNameHint,
                  counterText: '',
                ),
                validator: (v) {
                  final trimmed = v?.trim() ?? '';
                  if (trimmed.isEmpty || trimmed.length > 100) {
                    return l10n.errorValidation;
                  }
                  return null;
                },
              ),
              const SizedBox(height: 18),
              IconAndColorPicker(
                selectedIcon: _icon,
                selectedColor: _color,
                onIconChanged: (v) => setState(() => _icon = v),
                onColorChanged: (v) => setState(() => _color = v),
                iconSectionLabel: l10n.selectIcon,
                colorSectionLabel: l10n.selectColor,
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: _submit,
                child: Text(l10n.save),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
