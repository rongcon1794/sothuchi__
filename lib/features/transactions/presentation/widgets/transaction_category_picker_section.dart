import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:so_thu_chi/core/constants/icon_catalog.dart';
import 'package:so_thu_chi/core/l10n/l10n_ext.dart';
import 'package:so_thu_chi/core/theme/apple_theme_tokens.dart';
import 'package:so_thu_chi/core/widgets/apple_kit.dart';
import 'package:so_thu_chi/features/categories/domain/entities/category.dart';

/// Unified, elegant Apple HIG Category Selection Card for Expense & Income transactions.
/// Features clean enclosing card with crisp visible border, active category header,
/// and smooth 1-tap squircle category icons without harsh stroke boxes.
class TransactionCategorySelectionCard extends StatelessWidget {
  const TransactionCategorySelectionCard({
    super.key,
    required this.categories,
    required this.selectedId,
    required this.selectedCategory,
    required this.onSelected,
    required this.onOpenMore,
    required this.onCreateNew,
  });

  final List<Category> categories;
  final String? selectedId;
  final Category? selectedCategory;
  final ValueChanged<String> onSelected;
  final VoidCallback onOpenMore;
  final VoidCallback onCreateNew;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final l10n = context.l10n;

    final previewCategories = categories.take(8).toList();

    return AppleGlassCard(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
      borderRadius: BorderRadius.circular(AppleTokens.radiusCard),
      borderColor: isDark
          ? Colors.white.withValues(alpha: 0.12)
          : AppleTokens.borderLight,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Category Title + Current Selected Category Badge + Open Sheet Button
          Row(
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
                    : AppleTokens.systemBlue,
                size: 36,
                iconSize: 18,
                radius: 10,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.selectCategory,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppleTokens.systemGray,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      selectedCategory != null
                          ? DefaultCategoryLocalization.resolveName(
                              l10n,
                              categoryId: selectedCategory!.id,
                              fallbackName: selectedCategory!.name,
                            )
                          : l10n.selectCategory,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              ApplePressable(
                scaleDown: 0.94,
                onTap: onOpenMore,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppleTokens.bgDarkSecondary
                        : AppleTokens.bgLightSecondary,
                    borderRadius: BorderRadius.circular(AppleTokens.radiusPill),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Tất cả',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppleTokens.systemBlue,
                        ),
                      ),
                      SizedBox(width: 2),
                      Icon(
                        CupertinoIcons.chevron_right,
                        size: 12,
                        color: AppleTokens.systemBlue,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Divider(
            height: AppleTokens.hairline,
            thickness: AppleTokens.hairline,
            color:
                isDark ? AppleTokens.separatorDark : AppleTokens.separatorLight,
          ),
          const SizedBox(height: 10),

          // Horizontal 1-Tap Category Icons Strip
          SizedBox(
            height: 74,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: previewCategories.length + 2,
              separatorBuilder: (_, _) => const SizedBox(width: 10),
              itemBuilder: (context, index) {
                if (index < previewCategories.length) {
                  final cat = previewCategories[index];
                  final isSelected = cat.id == selectedId;
                  final catColor = AppIconCatalog.contrastSafeColor(
                    Color(cat.color),
                    theme.brightness,
                  );
                  final name = DefaultCategoryLocalization.resolveName(
                    l10n,
                    categoryId: cat.id,
                    fallbackName: cat.name,
                  );

                  return ApplePressable(
                    scaleDown: 0.92,
                    onTap: () => onSelected(cat.id),
                    child: SizedBox(
                      width: 58,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Stack(
                            clipBehavior: Clip.none,
                            children: [
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? catColor.withValues(alpha: 0.22)
                                      : (isDark
                                          ? AppleTokens.bgDarkSecondary
                                          : AppleTokens.bgLightSecondary),
                                  borderRadius: BorderRadius.circular(13),
                                  border: isSelected
                                      ? Border.all(color: catColor, width: 1.5)
                                      : null,
                                ),
                                child: Center(
                                  child: Icon(
                                    AppIconCatalog.resolve(cat.icon),
                                    size: 22,
                                    color: catColor,
                                  ),
                                ),
                              ),
                              if (isSelected)
                                Positioned(
                                  right: -3,
                                  top: -3,
                                  child: Container(
                                    padding: const EdgeInsets.all(2),
                                    decoration: BoxDecoration(
                                      color: catColor,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      CupertinoIcons.checkmark,
                                      size: 10,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: isSelected
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                              color: isSelected
                                  ? catColor
                                  : theme.colorScheme.onSurface,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                if (index == previewCategories.length) {
                  // "Khác" button -> opens full picker sheet
                  return ApplePressable(
                    scaleDown: 0.92,
                    onTap: onOpenMore,
                    child: SizedBox(
                      width: 58,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: isDark
                                  ? AppleTokens.bgDarkSecondary
                                  : AppleTokens.bgLightSecondary,
                              borderRadius: BorderRadius.circular(13),
                            ),
                            child: const Center(
                              child: Icon(
                                CupertinoIcons.ellipsis,
                                size: 20,
                                color: AppleTokens.systemBlue,
                              ),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            l10n.txCategoryOther,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: AppleTokens.systemBlue,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                // Last item: "+ Thêm" button -> opens CategoryFormSheet directly
                return ApplePressable(
                  scaleDown: 0.92,
                  onTap: onCreateNew,
                  child: SizedBox(
                    width: 58,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: isDark
                                ? AppleTokens.bgDarkSecondary
                                : AppleTokens.bgLightSecondary,
                            borderRadius: BorderRadius.circular(13),
                            border: Border.all(
                              color: theme.colorScheme.primary
                                  .withValues(alpha: 0.4),
                              width: 1,
                            ),
                          ),
                          child: const Center(
                            child: Icon(
                              CupertinoIcons.plus,
                              size: 20,
                              color: AppleTokens.jadePrimary,
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          l10n.txCategoryAdd,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// Cupertino-styled Bottom Sheet for Category Picker with Search and Squircle Grid.
class TransactionCategoryPickerSheet extends StatefulWidget {
  const TransactionCategoryPickerSheet({
    super.key,
    required this.categories,
    required this.selectedId,
    this.onCreateNew,
  });

  final List<Category> categories;
  final String? selectedId;
  final VoidCallback? onCreateNew;

  @override
  State<TransactionCategoryPickerSheet> createState() =>
      _TransactionCategoryPickerSheetState();
}

class _TransactionCategoryPickerSheetState
    extends State<TransactionCategoryPickerSheet> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final l10n = context.l10n;

    final filtered = widget.categories.where((cat) {
      if (_searchQuery.isEmpty) return true;
      final name = DefaultCategoryLocalization.resolveName(
        l10n,
        categoryId: cat.id,
        fallbackName: cat.name,
      ).toLowerCase();
      return name.contains(_searchQuery.toLowerCase());
    }).toList();

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.8,
      ),
      decoration: BoxDecoration(
        color: isDark ? AppleTokens.bgDarkCard : Colors.white,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppleTokens.radiusSheet),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: SafeArea(
          top: false,
          child: Column(
            children: [
              // Drag handle
              Container(
                margin: const EdgeInsets.symmetric(vertical: 10),
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.2)
                      : Colors.black.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        l10n.selectCategory,
                        style: theme.textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                    ),
                    if (widget.onCreateNew != null)
                      ApplePressable(
                        scaleDown: 0.94,
                        onTap: () {
                          Navigator.of(context).pop();
                          widget.onCreateNew!();
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 5),
                          margin: const EdgeInsets.only(right: 6),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary
                                .withValues(alpha: 0.15),
                            borderRadius:
                                BorderRadius.circular(AppleTokens.radiusPill),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(CupertinoIcons.plus,
                                  size: 13, color: theme.colorScheme.primary),
                              const SizedBox(width: 3),
                              Text(
                                l10n.txCategoryCreateNew,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: theme.colorScheme.primary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    IconButton(
                      icon: const Icon(CupertinoIcons.xmark_circle_fill,
                          color: AppleTokens.systemGray),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),

              // Search Bar
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: AppleSearchBar(
                  hintText: l10n.txCategorySearchPlaceholder,
                  height: 40,
                  onChanged: (val) => setState(() => _searchQuery = val),
                ),
              ),

              const Divider(height: AppleTokens.hairline),

              // 4-Column Squircle Category Grid or Empty Search State
              Expanded(
                child: filtered.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              CupertinoIcons.search,
                              size: 40,
                              color: AppleTokens.systemGray,
                            ),
                            const SizedBox(height: 10),
                            Text(
                              l10n.txCategoryNotFound,
                              style: const TextStyle(
                                  fontSize: 14, fontWeight: FontWeight.w600),
                            ),
                            if (widget.onCreateNew != null) ...[
                              const SizedBox(height: 12),
                              ApplePressable(
                                scaleDown: 0.94,
                                onTap: () {
                                  Navigator.of(context).pop();
                                  widget.onCreateNew!();
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: AppleTokens.jadePrimary,
                                    borderRadius: BorderRadius.circular(
                                        AppleTokens.radiusPill),
                                  ),
                                  child: Text(
                                    '+ ${l10n.categoryCreateNew}',
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      )
                    : GridView.builder(
                        padding: const EdgeInsets.all(16),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 4,
                          mainAxisSpacing: 16,
                          crossAxisSpacing: 12,
                          childAspectRatio: 0.8,
                        ),
                        itemCount: filtered.length,
                        itemBuilder: (context, index) {
                          final cat = filtered[index];
                          final isSelected = cat.id == widget.selectedId;
                          final catColor = AppIconCatalog.contrastSafeColor(
                            Color(cat.color),
                            theme.brightness,
                          );
                          final name = DefaultCategoryLocalization.resolveName(
                            l10n,
                            categoryId: cat.id,
                            fallbackName: cat.name,
                          );

                          return ApplePressable(
                            scaleDown: 0.92,
                            onTap: () {
                              HapticFeedback.selectionClick();
                              Navigator.of(context).pop(cat.id);
                            },
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Stack(
                                  clipBehavior: Clip.none,
                                  children: [
                                    Container(
                                      width: 52,
                                      height: 52,
                                      decoration: BoxDecoration(
                                        color: isSelected
                                            ? catColor.withValues(alpha: 0.2)
                                            : (isDark
                                                ? AppleTokens.bgDarkSecondary
                                                : AppleTokens.bgLightSecondary),
                                        borderRadius: BorderRadius.circular(16),
                                        border: Border.all(
                                          color: isSelected
                                              ? catColor
                                              : (isDark
                                                  ? Colors.white.withValues(
                                                      alpha: 0.1)
                                                  : AppleTokens.borderLight),
                                          width: isSelected
                                              ? 2
                                              : AppleTokens.hairline,
                                        ),
                                      ),
                                      child: Center(
                                        child: Icon(
                                          AppIconCatalog.resolve(cat.icon),
                                          size: 26,
                                          color: catColor,
                                        ),
                                      ),
                                    ),
                                    if (isSelected)
                                      Positioned(
                                        right: -4,
                                        top: -4,
                                        child: Container(
                                          padding: const EdgeInsets.all(2),
                                          decoration: const BoxDecoration(
                                            color: AppleTokens.jadePrimary,
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Icon(
                                            CupertinoIcons.checkmark,
                                            size: 12,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: isSelected
                                        ? FontWeight.w700
                                        : FontWeight.w500,
                                    color: isSelected
                                        ? catColor
                                        : theme.colorScheme.onSurface,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
