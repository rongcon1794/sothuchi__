import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:so_thu_chi/core/constants/icon_catalog.dart';
import 'package:so_thu_chi/core/l10n/l10n_ext.dart';
import 'package:so_thu_chi/core/widgets/apple_kit.dart';
import 'package:so_thu_chi/core/widgets/icon_and_color_picker.dart';
import 'package:so_thu_chi/features/categories/domain/entities/category.dart';
import 'package:so_thu_chi/features/categories/presentation/controllers/categories_controller.dart';

/// Clean Apple-styled form sheet for creating or editing a category.
/// Returns the saved [Category] upon success.
class CategoryFormSheet extends ConsumerStatefulWidget {
  const CategoryFormSheet({
    super.key,
    required this.initialType,
    this.existing,
  });

  final CategoryType initialType;
  final Category? existing;

  /// Convenience helper to show the sheet as a modal bottom sheet.
  static Future<Category?> show(
    BuildContext context, {
    required CategoryType initialType,
    Category? existing,
  }) {
    return showModalBottomSheet<Category>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: Colors.transparent,
      builder: (_) => CategoryFormSheet(
        initialType: initialType,
        existing: existing,
      ),
    );
  }

  @override
  ConsumerState<CategoryFormSheet> createState() => _CategoryFormSheetState();
}

class _CategoryFormSheetState extends ConsumerState<CategoryFormSheet> {
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
      onSuccess: (saved) => Navigator.of(context).pop(saved),
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
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 8,
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
                style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
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
              AppleTextField(
                controller: _nameController,
                maxLength: 100,
                label: l10n.categoryName,
                placeholder: l10n.categoryNameHint,
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
              AppleButton.primary(
                onPressed: _submit,
                label: l10n.save,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

