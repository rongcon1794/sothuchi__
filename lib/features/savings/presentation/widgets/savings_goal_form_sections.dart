// ignore_for_file: invalid_use_of_protected_member

part of 'savings_goal_form_sheet.dart';

extension _SavingsGoalFormSections on _SavingsGoalFormSheetState {
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

  Widget _buildLivePreviewCard({
    required BuildContext context,
    required ThemeData theme,
    required bool isDark,
    required Color accentColor,
    required String locale,
    required String currency,
    required AppLocalizations l10n,
    required Money? parsedTarget,
    required int currentAmount,
    required double previewProgress,
    required int? daysRemaining,
    required int? dailyNeeded,
    required Account? selectedWallet,
  }) {
    final hasTitle = _titleController.text.trim().isNotEmpty;
    final titleText = hasTitle
        ? _titleController.text.trim()
        : l10n.savingsGoalNameHint;
    final noteText = _noteController.text.trim();
    final targetMinor = parsedTarget?.minorUnits ?? 0;
    final hasTarget = targetMinor > 0;
    final progressPercent = (previewProgress * 100).round();
    final safeColor = AppIconCatalog.contrastSafeColor(
      accentColor,
      isDark ? Brightness.dark : Brightness.light,
    );
    final formattedTarget = hasTarget
        ? parsedTarget!.format(locale: locale)
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
                  color: safeColor.withValues(alpha: isDark ? 0.22 : 0.14),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: safeColor.withValues(alpha: 0.3),
                    width: 0.8,
                  ),
                ),
                alignment: Alignment.center,
                child: Icon(
                  _resolveIcon(_selectedIcon),
                  color: safeColor,
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
                            color: safeColor.withValues(
                              alpha: isDark ? 0.22 : 0.12,
                            ),
                            borderRadius:
                                BorderRadius.circular(AppleTokens.radiusPill),
                          ),
                          child: Text(
                            '$progressPercent%',
                            style: TextStyle(
                              fontSize: 9.5,
                              fontWeight: FontWeight.w800,
                              fontFeatures: AppTheme.tabularFigures,
                              color: safeColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _deadline != null
                          ? l10n.savingsDaysRemaining(daysRemaining ?? 0)
                          : l10n.savingsNoDeadline,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11.5,
                        color: isDark ? Colors.white60 : Colors.black54,
                      ),
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
                      l10n.savingsTargetAmount.toUpperCase(),
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
                        formattedTarget,
                        style: theme.textTheme.headlineMedium?.copyWith(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.4,
                          fontFeatures: AppTheme.tabularFigures,
                          color: hasTarget
                              ? (isDark
                                  ? Colors.white
                                  : const Color(0xFF1C1C1E))
                              : (isDark ? Colors.white30 : Colors.black26),
                        ),
                      ),
                    ),
                    if (_isEditing && currentAmount > 0) ...[
                      const SizedBox(height: 2),
                      Text(
                        '${locale == 'vi' ? 'Đã có' : 'Saved'} ${Money(minorUnits: currentAmount, currencyCode: currency).format(locale: locale)}',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          fontFeatures: AppTheme.tabularFigures,
                          color: safeColor,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (dailyNeeded != null || selectedWallet != null) ...[
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (dailyNeeded != null)
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            CupertinoIcons.sparkles,
                            size: 11,
                            color: safeColor,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            l10n.savingsDailyNeeded(
                              Money(
                                minorUnits: dailyNeeded,
                                currencyCode: currency,
                              ).format(locale: locale),
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
                      if (dailyNeeded != null) const SizedBox(height: 3),
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
            ],
          ),
          if (previewProgress > 0) ...[
            const SizedBox(height: 8),
            LucianProgressBar(
              value: previewProgress,
              height: 4.5,
              activeColor: safeColor,
              showGlow: false,
            ),
          ],
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

  Widget _buildInspirationIdeas({
    required bool isDark,
    required Color accentColor,
  }) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: [
          for (final idea in _SavingsGoalFormSheetState._inspirationIdeas) ...[
            ApplePressable(
              scaleDown: 0.93,
              onTap: () => _applyInspirationIdea(idea),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                margin: const EdgeInsets.only(right: 6),
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.06)
                      : Colors.black.withValues(alpha: 0.03),
                  borderRadius: BorderRadius.circular(AppleTokens.radiusPill),
                  border: Border.all(
                    color: Color(idea.color).withValues(alpha: 0.35),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _resolveIcon(idea.icon),
                      size: 13,
                      color: Color(idea.color),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      idea.title,
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
    final textLength = _targetAmountController.text.length;
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
                  l10n.savingsTargetAmount.toUpperCase(),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                    color: accentColor,
                  ),
                ),
              ],
            ),
            if (_targetAmountController.text.isNotEmpty)
              ApplePressable(
                scaleDown: 0.9,
                onTap: () {
                  unawaited(HapticFeedback.lightImpact());
                  _targetAmountController.clear();
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
                      controller: _targetAmountController,
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
                          return l10n.savingsAmountRequired;
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
        // Presets & Quick Zero Adders
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

  Widget _buildDeadlineContainer({
    required BuildContext context,
    required bool isDark,
    required String locale,
    required String currency,
    required AppLocalizations l10n,
    required Color accentColor,
    required int? daysRemaining,
    required int? dailyNeeded,
    required int? monthlyNeeded,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Quick duration chips
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          child: Row(
            children: [
              _buildDurationChip(
                30,
                locale == 'vi' ? '1 tháng' : '1 month',
                isDark,
                accentColor,
              ),
              _buildDurationChip(
                90,
                locale == 'vi' ? '3 tháng' : '3 months',
                isDark,
                accentColor,
              ),
              _buildDurationChip(
                180,
                locale == 'vi' ? '6 tháng' : '6 months',
                isDark,
                accentColor,
              ),
              _buildDurationChip(
                365,
                locale == 'vi' ? '1 năm' : '1 year',
                isDark,
                accentColor,
              ),
              ApplePressable(
                scaleDown: 0.92,
                onTap: _pickDeadline,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  margin: const EdgeInsets.only(right: 6),
                  decoration: BoxDecoration(
                    color: _deadline != null && !_isPredefinedDuration(daysRemaining)
                        ? accentColor.withValues(alpha: 0.18)
                        : (isDark
                            ? Colors.white.withValues(alpha: 0.06)
                            : Colors.black.withValues(alpha: 0.04)),
                    borderRadius:
                        BorderRadius.circular(AppleTokens.radiusPill),
                    border: Border.all(
                      color: _deadline != null && !_isPredefinedDuration(daysRemaining)
                          ? accentColor
                          : (isDark
                              ? Colors.white.withValues(alpha: 0.08)
                              : Colors.black.withValues(alpha: 0.06)),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        CupertinoIcons.calendar_today,
                        size: 13,
                        color: _deadline != null && !_isPredefinedDuration(daysRemaining)
                            ? accentColor
                            : (isDark ? Colors.white70 : Colors.black87),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _deadline != null
                            ? DateFormat('dd/MM/yyyy').format(_deadline!)
                            : (locale == 'vi'
                                ? 'Tùy chọn ngày...'
                                : 'Custom date...'),
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: _deadline != null && !_isPredefinedDuration(daysRemaining)
                              ? FontWeight.w700
                              : FontWeight.w600,
                          color: _deadline != null && !_isPredefinedDuration(daysRemaining)
                              ? accentColor
                              : (isDark ? Colors.white70 : Colors.black87),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),

        // Smart Savings Pace Insights
        if (dailyNeeded != null && dailyNeeded > 0)
          AppleGlassCard(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            borderRadius: BorderRadius.circular(AppleTokens.radiusCard),
            borderColor: accentColor.withValues(alpha: 0.25),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: accentColor.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    CupertinoIcons.speedometer,
                    color: accentColor,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        (locale == 'vi'
                                ? 'Nhịp độ tích lũy thông minh'
                                : 'Smart Savings Pace')
                            .toUpperCase(),
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.4,
                          color: accentColor,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        locale == 'vi'
                            ? '~ ${Money(minorUnits: dailyNeeded, currencyCode: currency).format(locale: locale)} / ngày  (hoặc ~ ${Money(minorUnits: monthlyNeeded ?? 0, currencyCode: currency).format(locale: locale)} / tháng)'
                            : '~ ${Money(minorUnits: dailyNeeded, currencyCode: currency).format(locale: locale)} / day  (or ~ ${Money(minorUnits: monthlyNeeded ?? 0, currencyCode: currency).format(locale: locale)} / month)',
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: isDark ? Colors.white : Colors.black87,
                          fontFeatures: AppTheme.tabularFigures,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          )
        else
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
                const Icon(
                  CupertinoIcons.lightbulb,
                  size: 15,
                  color: AppleTokens.systemOrange,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    locale == 'vi'
                        ? 'Mẹo: Chọn hạn hoàn thành giúp bạn chia nhỏ số tiền cần tiết kiệm mỗi ngày/tháng để dễ dàng hoàn thành mục tiêu.'
                        : 'Tip: Setting a target date helps break down how much to save daily/monthly to reach your goal.',
                    style: TextStyle(
                      fontSize: 11,
                      color: isDark ? Colors.white60 : Colors.black54,
                      height: 1.3,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  bool _isPredefinedDuration(int? days) {
    if (days == null) return false;
    return (days - 30).abs() <= 1 ||
        (days - 90).abs() <= 1 ||
        (days - 180).abs() <= 1 ||
        (days - 365).abs() <= 1;
  }

  Widget _buildDurationChip(
    int durationDays,
    String label,
    bool isDark,
    Color accentColor,
  ) {
    final days = _calculateDaysRemaining();
    final isSelected = days != null && (days - durationDays).abs() <= 1;

    return ApplePressable(
      scaleDown: 0.92,
      onTap: () => _setQuickDeadline(durationDays),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        margin: const EdgeInsets.only(right: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? accentColor.withValues(alpha: 0.18)
              : (isDark
                  ? Colors.white.withValues(alpha: 0.06)
                  : Colors.black.withValues(alpha: 0.04)),
          borderRadius: BorderRadius.circular(AppleTokens.radiusPill),
          border: Border.all(
            color: isSelected
                ? accentColor
                : (isDark
                    ? Colors.white.withValues(alpha: 0.08)
                    : Colors.black.withValues(alpha: 0.06)),
            width: isSelected ? 1.5 : 1.0,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
            color: isSelected
                ? accentColor
                : (isDark ? Colors.white70 : Colors.black87),
          ),
        ),
      ),
    );
  }

  Widget _buildLinkedWalletSelector({
    required List<Account> wallets,
    required bool isDark,
    required String locale,
    required AppLocalizations l10n,
    required Color accentColor,
  }) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: [
          // Option 1: Không liên kết ví cụ thể
          ApplePressable(
            scaleDown: 0.94,
            onTap: () {
              unawaited(HapticFeedback.selectionClick());
              setState(() => _linkedAccountId = null);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                color: _linkedAccountId == null
                    ? accentColor.withValues(alpha: isDark ? 0.22 : 0.12)
                    : (isDark
                        ? Colors.white.withValues(alpha: 0.05)
                        : Colors.black.withValues(alpha: 0.03)),
                borderRadius: BorderRadius.circular(AppleTokens.radiusCard),
                border: Border.all(
                  color: _linkedAccountId == null
                      ? accentColor
                      : (isDark
                          ? Colors.white.withValues(alpha: 0.08)
                          : Colors.black.withValues(alpha: 0.06)),
                  width: _linkedAccountId == null ? 1.5 : 1.0,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _linkedAccountId == null
                        ? CupertinoIcons.checkmark_circle_fill
                        : CupertinoIcons.circle,
                    size: 15,
                    color: _linkedAccountId == null
                        ? accentColor
                        : (isDark ? Colors.white38 : Colors.black38),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    l10n.savingsNoLinkedWallet,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: _linkedAccountId == null
                          ? FontWeight.w700
                          : FontWeight.w500,
                      color: _linkedAccountId == null
                          ? accentColor
                          : (isDark ? Colors.white70 : Colors.black87),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Option 2+: Active wallets
          for (final w in wallets) ...[
            ApplePressable(
              scaleDown: 0.94,
              onTap: () {
                unawaited(HapticFeedback.selectionClick());
                setState(() => _linkedAccountId = w.id);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                margin: const EdgeInsets.only(right: 8),
                decoration: BoxDecoration(
                  color: _linkedAccountId == w.id
                      ? Color(w.color).withValues(alpha: isDark ? 0.24 : 0.14)
                      : (isDark
                          ? Colors.white.withValues(alpha: 0.05)
                          : Colors.black.withValues(alpha: 0.03)),
                  borderRadius: BorderRadius.circular(AppleTokens.radiusCard),
                  border: Border.all(
                    color: _linkedAccountId == w.id
                        ? Color(w.color)
                        : (isDark
                            ? Colors.white.withValues(alpha: 0.08)
                            : Colors.black.withValues(alpha: 0.06)),
                    width: _linkedAccountId == w.id ? 1.5 : 1.0,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: Color(w.color),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          w.name,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: _linkedAccountId == w.id
                                ? FontWeight.w700
                                : FontWeight.w600,
                            color: _linkedAccountId == w.id
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
                    if (_linkedAccountId == w.id) ...[
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

  Widget _buildColorSelector({
    required bool isDark,
  }) {
    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: _SavingsGoalFormSheetState._availableColors.length,
        separatorBuilder: (_, _) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final colorVal = _SavingsGoalFormSheetState._availableColors[index];
          final isSelected = _selectedColor == colorVal;
          return ApplePressable(
            scaleDown: 0.9,
            onTap: () {
              unawaited(HapticFeedback.selectionClick());
              setState(() => _selectedColor = colorVal);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Color(colorVal),
                shape: BoxShape.circle,
                border: isSelected
                    ? Border.all(
                        color: isDark ? Colors.white : Colors.black87,
                        width: 3,
                      )
                    : Border.all(
                        color: Colors.white.withValues(alpha: 0.3),
                        width: 1,
                      ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: Color(colorVal).withValues(alpha: 0.4),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : null,
              ),
              child: isSelected
                  ? const Icon(
                      CupertinoIcons.checkmark,
                      color: Colors.white,
                      size: 18,
                    )
                  : null,
            ),
          );
        },
      ),
    );
  }

  Widget _buildIconSelector({
    required bool isDark,
    required Color accentColor,
  }) {
    const items = AppIconCatalog.savingsIcons;
    return LayoutBuilder(
      builder: (context, constraints) {
        final cols = constraints.maxWidth >= 520
            ? 8
            : (constraints.maxWidth >= 330 ? 6 : 4);
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: EdgeInsets.zero,
          itemCount: items.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: cols,
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            childAspectRatio: 0.96,
          ),
          itemBuilder: (context, index) {
            final item = items[index];
            final isSelected = _selectedIcon == item.$1;
            return ApplePressable(
              scaleDown: 0.92,
              onTap: () {
                unawaited(HapticFeedback.selectionClick());
                setState(() => _selectedIcon = item.$1);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(horizontal: 2),
                decoration: BoxDecoration(
                  color: isSelected
                      ? accentColor
                      : (isDark
                          ? Colors.white.withValues(alpha: 0.05)
                          : Colors.black.withValues(alpha: 0.03)),
                  borderRadius: BorderRadius.circular(AppleTokens.radiusCard),
                  border: Border.all(
                    color: isSelected
                        ? accentColor
                        : (isDark
                            ? Colors.white.withValues(alpha: 0.08)
                            : Colors.black.withValues(alpha: 0.06)),
                    width: isSelected ? 1.5 : 1.0,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: accentColor.withValues(alpha: 0.35),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ]
                      : null,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      item.$2,
                      color: isSelected
                          ? Colors.white
                          : (isDark ? Colors.white70 : Colors.black87),
                      size: 20,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      item.$3,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 8.5,
                        fontWeight:
                            isSelected ? FontWeight.w700 : FontWeight.w500,
                        color: isSelected
                            ? Colors.white
                            : (isDark ? Colors.white54 : Colors.black54),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
