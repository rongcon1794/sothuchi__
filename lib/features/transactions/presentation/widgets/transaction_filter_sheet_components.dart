part of 'transaction_filter_sheet.dart';

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
                locale.startsWith('vi') ? 'Đổi' : 'Change',
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

/// Expandable Menu for Wallets (Supports multi-select)
class _ExpandableWalletMenu extends StatelessWidget {
  const _ExpandableWalletMenu({
    required this.wallets,
    required this.selectedAccountIds,
    required this.isExpanded,
    required this.locale,
    required this.hideBalance,
    required this.onToggleExpand,
    required this.onToggleAccount,
    required this.onClearAccounts,
  });

  final List<Account> wallets;
  final Set<String> selectedAccountIds;
  final bool isExpanded;
  final String locale;
  final bool hideBalance;
  final VoidCallback onToggleExpand;
  final ValueChanged<String> onToggleAccount;
  final VoidCallback onClearAccounts;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final l10n = context.l10n;

    final singleWallet = selectedAccountIds.length == 1
        ? wallets.where((w) => selectedAccountIds.contains(w.id)).firstOrNull
        : null;

    final String subtitle;
    if (selectedAccountIds.isEmpty) {
      subtitle = l10n.filterAllWallets;
    } else if (selectedAccountIds.length == 1) {
      subtitle = singleWallet?.name ?? l10n.filterAllWallets;
    } else {
      subtitle = '${selectedAccountIds.length} ví đã chọn';
    }

    final hasSelection = selectedAccountIds.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Header Row (Tap to expand/collapse)
        ApplePressable(
          onTap: onToggleExpand,
          child: Row(
            children: [
              AppleSquircleBadge(
                icon: singleWallet != null
                    ? AppIconCatalog.resolve(singleWallet.icon)
                    : (hasSelection ? CupertinoIcons.creditcard_fill : CupertinoIcons.creditcard),
                backgroundColor: singleWallet != null
                    ? AppIconCatalog.contrastSafeColor(
                        Color(singleWallet.color),
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
                        fontWeight: hasSelection ? FontWeight.w700 : FontWeight.w500,
                        color: hasSelection
                            ? theme.colorScheme.primary
                            : (isDark ? Colors.white : Colors.black87),
                      ),
                    ),
                  ],
                ),
              ),
              if (hasSelection) ...[
                GestureDetector(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    onClearAccounts();
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
                      hasSelection
                          ? '${selectedAccountIds.length}/${wallets.length} ${l10n.localeName.startsWith('vi') ? 'ví' : 'wallets'}'
                          : '${wallets.length} ${l10n.localeName.startsWith('vi') ? 'ví' : 'wallets'}',
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
                    // Item 0: All Wallets (Clears specific selections)
                    _buildMenuItem(
                      context: context,
                      isSelected: selectedAccountIds.isEmpty,
                      leading: Icon(
                        CupertinoIcons.creditcard,
                        size: 15,
                        color: selectedAccountIds.isEmpty
                            ? theme.colorScheme.primary
                            : (isDark ? const Color(0xFF8E8E93) : const Color(0xFF6C6C70)),
                      ),
                      title: l10n.filterAllWallets,
                      subtitle: '${wallets.length} ${l10n.walletsTitle.toLowerCase()}',
                      onTap: () {
                        HapticFeedback.selectionClick();
                        onClearAccounts();
                      },
                    ),
                    for (final wallet in wallets) ...[
                      Divider(
                        height: AppleTokens.hairline,
                        color: isDark ? AppleTokens.separatorDark : AppleTokens.separatorLight,
                      ),
                      _buildMenuItem(
                        context: context,
                        isSelected: selectedAccountIds.contains(wallet.id),
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
                          onToggleAccount(wallet.id);
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
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: isSelected ? theme.colorScheme.primary : Colors.transparent,
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected
                      ? theme.colorScheme.primary
                      : (isDark ? const Color(0xFF545458) : const Color(0xFFC7C7CC)),
                  width: 1.5,
                ),
              ),
              alignment: Alignment.center,
              child: isSelected
                  ? const Icon(
                      CupertinoIcons.checkmark,
                      size: 12,
                      color: Colors.white,
                    )
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}

/// Expandable Menu for Categories (Supports multi-select)
class _ExpandableCategoryMenu extends StatelessWidget {
  const _ExpandableCategoryMenu({
    required this.categories,
    required this.selectedCategoryIds,
    required this.isExpanded,
    required this.searchController,
    required this.searchQuery,
    required this.onSearchChanged,
    required this.onToggleExpand,
    required this.onToggleCategory,
    required this.onClearCategories,
  });

  final List<Category> categories;
  final Set<String> selectedCategoryIds;
  final bool isExpanded;
  final TextEditingController searchController;
  final String searchQuery;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onToggleExpand;
  final ValueChanged<String> onToggleCategory;
  final VoidCallback onClearCategories;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final l10n = context.l10n;

    final singleCat = selectedCategoryIds.length == 1
        ? categories.where((c) => selectedCategoryIds.contains(c.id)).firstOrNull
        : null;

    final String subtitle;
    if (selectedCategoryIds.isEmpty) {
      subtitle = l10n.filterAllCategories;
    } else if (selectedCategoryIds.length == 1 && singleCat != null) {
      subtitle = DefaultCategoryLocalization.resolveName(
        l10n,
        categoryId: singleCat.id,
        fallbackName: singleCat.name,
      );
    } else {
      subtitle = l10n.localeName.startsWith('vi')
          ? '${selectedCategoryIds.length} danh mục đã chọn'
          : '${selectedCategoryIds.length} categories selected';
    }

    final hasSelection = selectedCategoryIds.isNotEmpty;

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
                icon: singleCat != null
                    ? AppIconCatalog.resolve(singleCat.icon)
                    : (hasSelection ? CupertinoIcons.square_grid_2x2_fill : CupertinoIcons.square_grid_2x2),
                backgroundColor: singleCat != null
                    ? AppIconCatalog.contrastSafeColor(
                        Color(singleCat.color),
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
                        fontWeight: hasSelection ? FontWeight.w700 : FontWeight.w500,
                        color: hasSelection
                            ? theme.colorScheme.primary
                            : (isDark ? Colors.white : Colors.black87),
                      ),
                    ),
                  ],
                ),
              ),
              if (hasSelection) ...[
                GestureDetector(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    onClearCategories();
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
                      hasSelection
                          ? '${selectedCategoryIds.length}/${categories.length} ${l10n.localeName.startsWith('vi') ? 'mục' : 'items'}'
                          : '${categories.length} ${l10n.localeName.startsWith('vi') ? 'mục' : 'items'}',
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
                          hintText: l10n.localeName.startsWith('vi')
                              ? 'Tìm danh mục...'
                              : 'Search categories...',
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
                            final isAllSelected = selectedCategoryIds.isEmpty;
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
                              subtitle: '${categories.length} ${l10n.localeName.startsWith('vi') ? 'danh mục' : 'categories'}',
                              onTap: () {
                                HapticFeedback.selectionClick();
                                onClearCategories();
                              },
                            );
                          }

                          final cat = filteredCategories[index - 1];
                          final isSelected = selectedCategoryIds.contains(cat.id);
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
                              onToggleCategory(cat.id);
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
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: isSelected ? theme.colorScheme.primary : Colors.transparent,
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected
                      ? theme.colorScheme.primary
                      : (isDark ? const Color(0xFF545458) : const Color(0xFFC7C7CC)),
                  width: 1.5,
                ),
              ),
              alignment: Alignment.center,
              child: isSelected
                  ? const Icon(
                      CupertinoIcons.checkmark,
                      size: 12,
                      color: Colors.white,
                    )
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}
