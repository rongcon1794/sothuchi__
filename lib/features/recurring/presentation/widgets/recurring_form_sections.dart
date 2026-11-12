// ignore_for_file: invalid_use_of_protected_member

part of 'recurring_form_sheet.dart';

extension _RecurringFormSections on _RecurringFormSheetState {
  Widget _buildSectionHeader({
    required IconData icon,
    required String title,
    String? subtitle,
    Widget? trailing,
    Color? accentColor,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(
            icon,
            size: 13,
            color: accentColor ?? AppleTokens.systemGray,
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title.toUpperCase(),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                    color: accentColor ?? AppleTokens.systemGray,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 1),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 10.5,
                      color: AppleTokens.systemGray,
                    ),
                  ),
                ],
              ],
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }

  Widget _buildTypeTabSelector({
    required BuildContext context,
    required bool isDark,
    required AppLocalizations l10n,
    required List<Category> expenseCats,
    required List<Category> incomeCats,
  }) {
    final isExpense = _type == TransactionType.expense;
    return Container(
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.04)
            : Colors.black.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(AppleTokens.radiusCard),
        border: Border.all(
          color: isDark ? AppleTokens.separatorDark : AppleTokens.separatorLight,
          width: AppleTokens.hairline,
        ),
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        children: [
          // 1. Khoản chi (Expense) Tab Card
          Expanded(
            child: _buildTypeCard(
              type: TransactionType.expense,
              label: l10n.expense,
              subtitle: 'Hóa đơn & dịch vụ',
              icon: CupertinoIcons.arrow_up_right,
              accentColor: AppleTokens.rubyExpense,
              isSelected: isExpense,
              isDark: isDark,
              onTap: () {
                if (_type != TransactionType.expense) {
                  unawaited(HapticFeedback.selectionClick());
                  setState(() {
                    _type = TransactionType.expense;
                    if (expenseCats.isNotEmpty) {
                      _categoryId = expenseCats.first.id;
                    }
                  });
                }
              },
            ),
          ),
          const SizedBox(width: 6),

          // 2. Thu nhập (Income) Tab Card
          Expanded(
            child: _buildTypeCard(
              type: TransactionType.income,
              label: l10n.income,
              subtitle: 'Lương & thu nhập',
              icon: CupertinoIcons.arrow_down_left,
              accentColor: AppleTokens.jadePrimary,
              isSelected: !isExpense,
              isDark: isDark,
              onTap: () {
                if (_type != TransactionType.income) {
                  unawaited(HapticFeedback.selectionClick());
                  setState(() {
                    _type = TransactionType.income;
                    if (incomeCats.isNotEmpty) {
                      _categoryId = incomeCats.first.id;
                    }
                  });
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypeCard({
    required TransactionType type,
    required String label,
    required String subtitle,
    required IconData icon,
    required Color accentColor,
    required bool isSelected,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return ApplePressable(
      onTap: onTap,
      scaleDown: 0.97,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 240),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark
                  ? accentColor.withValues(alpha: 0.18)
                  : Colors.white)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(AppleTokens.radiusControl),
          border: Border.all(
            color: isSelected
                ? (isDark
                    ? accentColor.withValues(alpha: 0.55)
                    : accentColor.withValues(alpha: 0.35))
                : Colors.transparent,
            width: isSelected ? 1.5 : 0,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: isDark
                        ? accentColor.withValues(alpha: 0.25)
                        : Colors.black.withValues(alpha: 0.06),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                  if (!isDark)
                    BoxShadow(
                      color: accentColor.withValues(alpha: 0.12),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                ]
              : null,
        ),
        child: Row(
          children: [
            // Squircle Icon Badge
            AnimatedContainer(
              duration: const Duration(milliseconds: 240),
              curve: Curves.easeOutCubic,
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: isSelected
                    ? accentColor
                    : (isDark
                        ? Colors.white.withValues(alpha: 0.08)
                        : Colors.black.withValues(alpha: 0.05)),
                borderRadius: BorderRadius.circular(AppleTokens.radiusControl),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: accentColor.withValues(alpha: 0.35),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : null,
              ),
              child: Icon(
                icon,
                size: 16,
                color: isSelected
                    ? Colors.white
                    : (isDark ? Colors.white54 : Colors.black45),
              ),
            ),
            const SizedBox(width: 8),

            // Text Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                            letterSpacing: -0.2,
                            color: isSelected
                                ? (isDark ? Colors.white : accentColor)
                                : (isDark ? Colors.white70 : Colors.black87),
                          ),
                        ),
                      ),
                      if (isSelected) ...[
                        const SizedBox(width: 4),
                        Icon(
                          CupertinoIcons.checkmark_circle_fill,
                          size: 13,
                          color: accentColor,
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w500,
                      color: isSelected
                          ? (isDark
                              ? accentColor.withValues(alpha: 0.9)
                              : accentColor.withValues(alpha: 0.85))
                          : (isDark ? Colors.white38 : Colors.black38),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLivePreviewCard({
    required BuildContext context,
    required ThemeData theme,
    required bool isDark,
    required Color accentColor,
    required String locale,
    required String currency,
    required AppLocalizations l10n,
    required Money? parsedAmount,
    required Category? selectedCategory,
    required Account? selectedWallet,
  }) {
    final hasTitle = _titleController.text.trim().isNotEmpty;
    final titleText = hasTitle
        ? _titleController.text.trim()
        : (_type == TransactionType.expense
            ? l10n.recurringTitleLabel
            : 'Tên khoản thu nhập');
    final noteText = _noteController.text.trim();
    final isExpense = _type == TransactionType.expense;
    final rawIconColor =
        selectedCategory != null ? Color(selectedCategory.color) : accentColor;
    final badgeColor = AppIconCatalog.contrastSafeColor(
      rawIconColor,
      isDark ? Brightness.dark : Brightness.light,
    );
    final hasAmount = parsedAmount != null && parsedAmount.minorUnits > 0;
    final formattedAmount = hasAmount
        ? '${isExpense ? '-' : '+'}${parsedAmount.format(locale: locale)}'
        : Money.zero(currency).format(locale: locale);

    return AppleGlassCard(
      borderRadius: BorderRadius.circular(AppleTokens.radiusHero),
      borderColor: accentColor.withValues(alpha: isDark ? 0.35 : 0.22),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: badgeColor.withValues(alpha: isDark ? 0.22 : 0.14),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: badgeColor.withValues(alpha: 0.3),
                    width: 0.8,
                  ),
                ),
                alignment: Alignment.center,
                child: Icon(
                  selectedCategory != null
                      ? AppIconCatalog.resolve(selectedCategory.icon)
                      : (isExpense
                          ? CupertinoIcons.arrow_up_right
                          : CupertinoIcons.arrow_down_left),
                  color: badgeColor,
                  size: 19,
                ),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            titleText,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                              fontSize: 15.5,
                              letterSpacing: -0.2,
                              color: hasTitle
                                  ? (isDark ? Colors.white : Colors.black87)
                                  : (isDark ? Colors.white38 : Colors.black38),
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 2.5,
                          ),
                          decoration: BoxDecoration(
                            color: accentColor.withValues(
                              alpha: isDark ? 0.22 : 0.12,
                            ),
                            borderRadius:
                                BorderRadius.circular(AppleTokens.radiusPill),
                          ),
                          child: Text(
                            _intervalLabel(_interval, l10n).toUpperCase(),
                            style: TextStyle(
                              fontSize: 9.5,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.3,
                              color: accentColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Icon(
                          _autoExecute
                              ? CupertinoIcons.bolt_fill
                              : CupertinoIcons.hand_draw,
                          size: 11,
                          color: _autoExecute
                              ? AppleTokens.systemGreen
                              : (isDark ? Colors.white54 : Colors.black45),
                        ),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            _autoExecute
                                ? (isExpense
                                    ? 'Tự động thanh toán'
                                    : 'Tự động nhận tiền')
                                : 'Xác nhận thủ công',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w500,
                              color: _autoExecute
                                  ? AppleTokens.systemGreen
                                  : (isDark ? Colors.white60 : Colors.black54),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
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
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      l10n.amount.toUpperCase(),
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                        color: isDark ? Colors.white54 : Colors.black45,
                      ),
                    ),
                    const SizedBox(height: 2),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        formattedAmount,
                        style: theme.textTheme.headlineMedium?.copyWith(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.4,
                          fontFeatures: AppTheme.tabularFigures,
                          color: hasAmount
                              ? accentColor
                              : (isDark ? Colors.white30 : Colors.black26),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        CupertinoIcons.calendar,
                        size: 11,
                        color: accentColor,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        isExpense
                            ? l10n.recurringNextDue(
                                AppDateUtils.formatShortDate(
                                  _startDate,
                                  locale: locale,
                                ),
                              )
                            : l10n.recurringNextIncomeDue(
                                AppDateUtils.formatShortDate(
                                  _startDate,
                                  locale: locale,
                                ),
                              ),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white70 : Colors.black87,
                        ),
                      ),
                    ],
                  ),
                  if (selectedWallet != null) ...[
                    const SizedBox(height: 3),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: Color(selectedWallet.color),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          selectedWallet.name,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Color(selectedWallet.color),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ],
          ),
          if (noteText.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              '“$noteText”',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11.5,
                fontStyle: FontStyle.italic,
                color: isDark ? Colors.white54 : Colors.black54,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTemplatesCarousel({
    required List<Category> availableCats,
    required bool isDark,
  }) {
    final filteredTemplates = _RecurringFormSheetState._popularTemplates
        .where((t) => t.type == _type)
        .toList();

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: [
          for (final template in filteredTemplates) ...[
            ApplePressable(
              scaleDown: 0.93,
              onTap: () => _applyTemplate(template, availableCats),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                margin: const EdgeInsets.only(right: 6),
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.06)
                      : Colors.black.withValues(alpha: 0.03),
                  borderRadius: BorderRadius.circular(AppleTokens.radiusPill),
                  border: Border.all(
                    color: (template.type == TransactionType.expense
                            ? AppleTokens.rubyExpense
                            : AppleTokens.jadePrimary)
                        .withValues(alpha: 0.35),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      template.icon,
                      size: 13,
                      color: template.type == TransactionType.expense
                          ? AppleTokens.rubyExpense
                          : AppleTokens.jadePrimary,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      template.title,
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildHeroAmountSection({
    required BuildContext context,
    required bool isDark,
    required String currencyCode,
    required String locale,
    required AppLocalizations l10n,
    required Color accentColor,
  }) {
    final textLength = _amountController.text.length;
    final dynamicFontSize = _getDynamicFontSize(textLength);
    final currencyInfo = AppCurrencies.byCode(currencyCode);
    final quickPresets = _getQuickPresets(currencyCode);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(
                  CupertinoIcons.money_dollar_circle_fill,
                  size: 13,
                  color: accentColor,
                ),
                const SizedBox(width: 6),
                Text(
                  l10n.recurringAmountLabel.toUpperCase(),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                    color: accentColor,
                  ),
                ),
              ],
            ),
            if (_amountController.text.isNotEmpty)
              ApplePressable(
                scaleDown: 0.9,
                onTap: () {
                  unawaited(HapticFeedback.lightImpact());
                  _amountController.clear();
                },
                child: Text(
                  l10n.clear,
                  style: const TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: AppleTokens.systemGray,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        // Amount Input Box
        GestureDetector(
          onTap: () {
            if (!_amountFocusNode.hasFocus) {
              _amountFocusNode.requestFocus();
            }
            SystemChannels.textInput.invokeMethod<void>('TextInput.show');
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            constraints: const BoxConstraints(minHeight: 54),
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: _isAmountFocused
                  ? accentColor.withValues(alpha: isDark ? 0.14 : 0.08)
                  : (isDark
                      ? Colors.white.withValues(alpha: 0.04)
                      : Colors.black.withValues(alpha: 0.025)),
              borderRadius: BorderRadius.circular(AppleTokens.radiusControl),
              border: Border.all(
                color: _isAmountFocused
                    ? accentColor
                    : (isDark
                        ? Colors.white.withValues(alpha: 0.1)
                        : Colors.black.withValues(alpha: 0.06)),
                width: _isAmountFocused ? 1.5 : 1.0,
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Center(
                    child: TextFormField(
                      controller: _amountController,
                      focusNode: _amountFocusNode,
                      textAlign: TextAlign.center,
                      keyboardType: TextInputType.numberWithOptions(
                        decimal: currencyInfo.decimalDigits > 0,
                      ),
                      inputFormatters: [
                        MoneyInputFormatter(
                          currencyCode: currencyCode,
                          locale: locale,
                        ),
                      ],
                      style: TextStyle(
                        fontSize: dynamicFontSize,
                        fontWeight: FontWeight.w800,
                        fontFeatures: AppTheme.tabularFigures,
                        color: isDark ? Colors.white : Colors.black87,
                        letterSpacing: -0.5,
                      ),
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        errorBorder: InputBorder.none,
                        focusedErrorBorder: InputBorder.none,
                        filled: false,
                        isDense: true,
                        hintText: '0',
                        hintStyle: TextStyle(
                          fontSize: dynamicFontSize,
                          fontWeight: FontWeight.w800,
                          color: (isDark ? Colors.white : Colors.black)
                              .withValues(alpha: 0.25),
                        ),
                        contentPadding: EdgeInsets.zero,
                      ),
                      validator: (val) {
                        final parsed = Money.tryParse(val ?? '',
                            currencyCode: currencyCode);
                        if (parsed == null || parsed.minorUnits <= 0) {
                          return l10n.recurringAmountRequired;
                        }
                        return null;
                      },
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: accentColor.withValues(alpha: 0.15),
                    borderRadius:
                        BorderRadius.circular(AppleTokens.radiusPill),
                  ),
                  child: Text(
                    currencyInfo.symbol,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: accentColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        // Presets & Triple Zeros Adder
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          child: Row(
            children: [
              for (final preset in quickPresets) ...[
                ApplePressable(
                  scaleDown: 0.92,
                  onTap: () => _setPresetAmount(
                      preset.minorUnits, currencyCode, locale),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 5),
                    margin: const EdgeInsets.only(right: 6),
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.06)
                          : Colors.black.withValues(alpha: 0.04),
                      borderRadius:
                          BorderRadius.circular(AppleTokens.radiusPill),
                      border: Border.all(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.08)
                            : Colors.black.withValues(alpha: 0.06),
                      ),
                    ),
                    child: Text(
                      preset.label,
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white70 : Colors.black87,
                      ),
                    ),
                  ),
                ),
              ],
              if (currencyCode.toUpperCase() == 'VND')
                ApplePressable(
                  scaleDown: 0.92,
                  onTap: () => _appendTripleZeros(currencyCode, locale),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: accentColor.withValues(alpha: 0.14),
                      borderRadius:
                          BorderRadius.circular(AppleTokens.radiusPill),
                      border: Border.all(
                        color: accentColor.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Text(
                      '+000',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: accentColor,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildIntervalSelector({
    required bool isDark,
    required AppLocalizations l10n,
    required Color accentColor,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          child: Row(
            children: [
              for (final interval in RecurringInterval.values) ...[
                ApplePressable(
                  scaleDown: 0.92,
                  onTap: () {
                    unawaited(HapticFeedback.selectionClick());
                    setState(() => _interval = interval);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    margin: const EdgeInsets.only(right: 6),
                    decoration: BoxDecoration(
                      color: _interval == interval
                          ? accentColor.withValues(alpha: 0.18)
                          : (isDark
                              ? Colors.white.withValues(alpha: 0.06)
                              : Colors.black.withValues(alpha: 0.04)),
                      borderRadius: BorderRadius.circular(AppleTokens.radiusPill),
                      border: Border.all(
                        color: _interval == interval
                            ? accentColor
                            : (isDark
                                ? Colors.white.withValues(alpha: 0.08)
                                : Colors.black.withValues(alpha: 0.06)),
                        width: _interval == interval ? 1.5 : 1.0,
                      ),
                    ),
                    child: Text(
                      _intervalLabel(interval, l10n),
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: _interval == interval
                            ? FontWeight.w700
                            : FontWeight.w600,
                        color: _interval == interval
                            ? accentColor
                            : (isDark ? Colors.white70 : Colors.black87),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 8),
        // Schedule projection explanation badge
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: isDark
                ? Colors.white.withValues(alpha: 0.04)
                : Colors.black.withValues(alpha: 0.02),
            borderRadius: BorderRadius.circular(AppleTokens.radiusControl),
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.06)
                  : Colors.black.withValues(alpha: 0.04),
            ),
          ),
          child: Row(
            children: [
              Icon(
                CupertinoIcons.clock,
                size: 14,
                color: accentColor,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _getScheduleExplanation(_interval, _startDate),
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white70 : Colors.black87,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStartDateTile({
    required BuildContext context,
    required bool isDark,
    required String locale,
    required Color accentColor,
  }) {
    final isExpense = _type == TransactionType.expense;
    return ApplePressable(
      scaleDown: 0.98,
      onTap: _pickStartDate,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isDark
              ? Colors.white.withValues(alpha: 0.05)
              : Colors.black.withValues(alpha: 0.025),
          borderRadius: BorderRadius.circular(AppleTokens.radiusControl),
          border: Border.all(
            color: isDark
                ? Colors.white.withValues(alpha: 0.08)
                : Colors.black.withValues(alpha: 0.05),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                CupertinoIcons.calendar,
                color: accentColor,
                size: 17,
              ),
            ),
            const SizedBox(width: 11),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isExpense
                        ? 'Kỳ hạn thanh toán đầu tiên'
                        : 'Ngày nhận tiền đầu tiên',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppleTokens.systemGray,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${AppDateUtils.formatShortDate(_startDate, locale: locale)}  •  ${_formatDaysUntilStart(_startDate)}',
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              CupertinoIcons.chevron_forward,
              size: 15,
              color: AppleTokens.systemGray,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategorySelector({
    required List<Category> categories,
    required bool isDark,
    required Color accentColor,
  }) {
    if (categories.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.03),
          borderRadius: BorderRadius.circular(AppleTokens.radiusControl),
        ),
        child: const Text('Đang tải danh mục...'),
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: [
          for (final c in categories) ...[
            ApplePressable(
              scaleDown: 0.94,
              onTap: () {
                unawaited(HapticFeedback.selectionClick());
                setState(() => _categoryId = c.id);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                margin: const EdgeInsets.only(right: 8),
                decoration: BoxDecoration(
                  color: _categoryId == c.id
                      ? Color(c.color).withValues(alpha: isDark ? 0.24 : 0.14)
                      : (isDark
                          ? Colors.white.withValues(alpha: 0.05)
                          : Colors.black.withValues(alpha: 0.03)),
                  borderRadius: BorderRadius.circular(AppleTokens.radiusCard),
                  border: Border.all(
                    color: _categoryId == c.id
                        ? Color(c.color)
                        : (isDark
                            ? Colors.white.withValues(alpha: 0.08)
                            : Colors.black.withValues(alpha: 0.06)),
                    width: _categoryId == c.id ? 1.5 : 1.0,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: Color(c.color).withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        AppIconCatalog.resolve(c.icon),
                        size: 13,
                        color: Color(c.color),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      c.name,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: _categoryId == c.id
                            ? FontWeight.w700
                            : FontWeight.w600,
                        color: _categoryId == c.id
                            ? Color(c.color)
                            : (isDark ? Colors.white : Colors.black87),
                      ),
                    ),
                    if (_categoryId == c.id) ...[
                      const SizedBox(width: 6),
                      Icon(
                        CupertinoIcons.checkmark_circle_fill,
                        size: 14,
                        color: Color(c.color),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildWalletSelector({
    required List<Account> wallets,
    required bool isDark,
    required String locale,
    required Color accentColor,
  }) {
    if (wallets.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.03),
          borderRadius: BorderRadius.circular(AppleTokens.radiusControl),
        ),
        child: const Text('Chưa có ví nào khả dụng'),
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: [
          for (final w in wallets) ...[
            ApplePressable(
              scaleDown: 0.94,
              onTap: () {
                unawaited(HapticFeedback.selectionClick());
                setState(() => _accountId = w.id);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                margin: const EdgeInsets.only(right: 8),
                decoration: BoxDecoration(
                  color: _accountId == w.id
                      ? Color(w.color).withValues(alpha: isDark ? 0.24 : 0.14)
                      : (isDark
                          ? Colors.white.withValues(alpha: 0.05)
                          : Colors.black.withValues(alpha: 0.03)),
                  borderRadius: BorderRadius.circular(AppleTokens.radiusCard),
                  border: Border.all(
                    color: _accountId == w.id
                        ? Color(w.color)
                        : (isDark
                            ? Colors.white.withValues(alpha: 0.08)
                            : Colors.black.withValues(alpha: 0.06)),
                    width: _accountId == w.id ? 1.5 : 1.0,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: AppIconCatalog.contrastSafeColor(
                          Color(w.color),
                          isDark ? Brightness.dark : Brightness.light,
                        ).withValues(alpha: 0.16),
                        borderRadius: BorderRadius.circular(7),
                      ),
                      child: Icon(
                        AppIconCatalog.resolve(w.icon),
                        size: 13,
                        color: AppIconCatalog.contrastSafeColor(
                          Color(w.color),
                          isDark ? Brightness.dark : Brightness.light,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          w.name,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: _accountId == w.id
                                ? FontWeight.w700
                                : FontWeight.w600,
                            color: _accountId == w.id
                                ? Color(w.color)
                                : (isDark ? Colors.white : Colors.black87),
                          ),
                        ),
                        Text(
                          Money(minorUnits: w.balance, currencyCode: w.currency)
                              .format(locale: locale),
                          style: TextStyle(
                            fontSize: 10.5,
                            color: isDark ? Colors.white60 : Colors.black54,
                            fontFeatures: AppTheme.tabularFigures,
                          ),
                        ),
                      ],
                    ),
                    if (_accountId == w.id) ...[
                      const SizedBox(width: 6),
                      Icon(
                        CupertinoIcons.checkmark_circle_fill,
                        size: 14,
                        color: Color(w.color),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAutoExecuteRow({
    required bool isDark,
    required AppLocalizations l10n,
  }) {
    return Row(
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: _autoExecute
                ? AppleTokens.systemGreen.withValues(alpha: 0.15)
                : (isDark
                    ? Colors.white.withValues(alpha: 0.05)
                    : Colors.black.withValues(alpha: 0.04)),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            CupertinoIcons.bolt_fill,
            color: _autoExecute
                ? AppleTokens.systemGreen
                : AppleTokens.systemGray,
            size: 17,
          ),
        ),
        const SizedBox(width: 11),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.recurringAutoExecute,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                _type == TransactionType.income
                    ? l10n.recurringAutoExecuteIncomeSubtitle
                    : l10n.recurringAutoExecuteSubtitle,
                style: TextStyle(
                  fontSize: 11,
                  color: isDark ? Colors.white60 : Colors.black54,
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        CupertinoSwitch(
          value: _autoExecute,
          activeTrackColor: AppleTokens.systemGreen,
          onChanged: (v) {
            unawaited(HapticFeedback.selectionClick());
            setState(() => _autoExecute = v);
          },
        ),
      ],
    );
  }
}
