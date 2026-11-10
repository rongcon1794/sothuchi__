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
    final titleText = _titleController.text.trim().isNotEmpty
        ? _titleController.text.trim()
        : l10n.savingsGoalNameHint;
    final noteText = _noteController.text.trim();
    final targetMinor = parsedTarget?.minorUnits ?? 0;
    final remainingMinor = (targetMinor - currentAmount).clamp(0, double.infinity).toInt();
    final progressPercent = (previewProgress * 100).round();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 4, bottom: 8),
          child: Row(
            children: [
              Icon(
                Icons.remove_red_eye_outlined,
                size: 14,
                color: AppleTokens.systemGray,
              ),
              SizedBox(width: 6),
              Text(
                'BẢN XEM TRƯỚC MỤC TIÊU TRÊN DANH SÁCH',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.6,
                  color: AppleTokens.systemGray,
                ),
              ),
            ],
          ),
        ),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppleTokens.radiusHero),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                isDark
                    ? Color.lerp(accentColor, const Color(0xFF1E1E22), 0.84)!
                    : Color.lerp(accentColor, Colors.white, 0.90)!,
                isDark
                    ? const Color(0xFF141416)
                    : Color.lerp(accentColor, const Color(0xFFF7F8FA), 0.96)!,
              ],
            ),
            border: Border.all(
              color: accentColor.withValues(alpha: isDark ? 0.35 : 0.22),
              width: 1.0,
            ),
            boxShadow: [
              BoxShadow(
                color: accentColor.withValues(alpha: isDark ? 0.18 : 0.07),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppleTokens.radiusHero),
            child: Stack(
              children: [
                // Subtle ambient radiant glow at top-right
                Positioned(
                  right: -24,
                  top: -30,
                  child: Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          accentColor.withValues(alpha: isDark ? 0.22 : 0.12),
                          accentColor.withValues(alpha: 0.0),
                        ],
                      ),
                    ),
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // --- Tier 1: Icon, Title, Badges, Menu ---
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // Squircle Icon Badge with high-gloss gradient & shadow
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  accentColor,
                                  Color.lerp(
                                    accentColor,
                                    Colors.black,
                                    isDark ? 0.35 : 0.2,
                                  )!,
                                ],
                              ),
                              borderRadius: BorderRadius.circular(13),
                              border: Border.all(
                                color: Colors.white.withValues(
                                  alpha: isDark ? 0.3 : 0.45,
                                ),
                                width: 1.0,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: accentColor.withValues(
                                    alpha: isDark ? 0.4 : 0.25,
                                  ),
                                  blurRadius: 10,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: Icon(
                              _resolveIcon(_selectedIcon),
                              color: Colors.white,
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 12),

                          // Title & Subtitle / Badges
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  titleText,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 16.5,
                                    letterSpacing: -0.2,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Wrap(
                                  spacing: 5,
                                  runSpacing: 4,
                                  crossAxisAlignment: WrapCrossAlignment.center,
                                  children: [
                                    if (_deadline != null)
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 7,
                                          vertical: 2.5,
                                        ),
                                        alignment: Alignment.center,
                                        decoration: BoxDecoration(
                                          color: isDark
                                              ? Colors.white.withValues(alpha: 0.08)
                                              : Colors.black.withValues(alpha: 0.05),
                                          borderRadius: BorderRadius.circular(
                                            AppleTokens.radiusPill,
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              CupertinoIcons.calendar,
                                              size: 11,
                                              color: isDark
                                                  ? Colors.white60
                                                  : Colors.black54,
                                            ),
                                            const SizedBox(width: 3),
                                            Text(
                                              l10n.savingsDaysRemaining(daysRemaining ?? 0),
                                              style: TextStyle(
                                                fontSize: 10.5,
                                                fontWeight: FontWeight.w600,
                                                color: isDark
                                                    ? Colors.white70
                                                    : Colors.black87,
                                                height: 1.2,
                                              ),
                                            ),
                                          ],
                                        ),
                                      )
                                    else
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 7,
                                          vertical: 2.5,
                                        ),
                                        alignment: Alignment.center,
                                        decoration: BoxDecoration(
                                          color: isDark
                                              ? Colors.white.withValues(alpha: 0.08)
                                              : Colors.black.withValues(alpha: 0.05),
                                          borderRadius: BorderRadius.circular(
                                            AppleTokens.radiusPill,
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              CupertinoIcons.calendar,
                                              size: 11,
                                              color: isDark
                                                  ? Colors.white60
                                                  : Colors.black54,
                                            ),
                                            const SizedBox(width: 3),
                                            Text(
                                              l10n.savingsNoDeadline,
                                              style: TextStyle(
                                                fontSize: 10.5,
                                                fontWeight: FontWeight.w600,
                                                color: isDark
                                                    ? Colors.white70
                                                    : Colors.black87,
                                                height: 1.2,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    if (selectedWallet != null)
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 7,
                                          vertical: 2.5,
                                        ),
                                        alignment: Alignment.center,
                                        decoration: BoxDecoration(
                                          color: Color(selectedWallet.color)
                                              .withValues(alpha: 0.15),
                                          borderRadius: BorderRadius.circular(
                                            AppleTokens.radiusPill,
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              CupertinoIcons.creditcard,
                                              size: 11,
                                              color: Color(selectedWallet.color),
                                            ),
                                            const SizedBox(width: 3),
                                            Text(
                                              selectedWallet.name,
                                              style: TextStyle(
                                                fontSize: 10.5,
                                                fontWeight: FontWeight.w600,
                                                color: Color(selectedWallet.color),
                                                height: 1.2,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    if (noteText.isNotEmpty)
                                      Text(
                                        noteText,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontSize: 11,
                                          color: AppleTokens.systemGray,
                                        ),
                                      ),
                                  ],
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(width: 8),

                          // Progress Badge
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3.5,
                            ),
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: accentColor.withValues(
                                alpha: isDark ? 0.22 : 0.12,
                              ),
                              borderRadius:
                                  BorderRadius.circular(AppleTokens.radiusPill),
                              border: Border.all(
                                color: accentColor.withValues(alpha: 0.35),
                                width: 0.8,
                              ),
                            ),
                            child: Text(
                              '$progressPercent%',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                                fontFeatures: AppTheme.tabularFigures,
                                color: accentColor,
                                height: 1.2,
                              ),
                            ),
                          ),

                          const SizedBox(width: 4),

                          // 3-dots Menu Preview
                          Container(
                            width: 28,
                            height: 28,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: isDark
                                  ? Colors.white.withValues(alpha: 0.08)
                                  : Colors.black.withValues(alpha: 0.04),
                              borderRadius:
                                  BorderRadius.circular(AppleTokens.radiusPill),
                            ),
                            child: const Icon(
                              CupertinoIcons.ellipsis,
                              size: 16,
                              color: AppleTokens.systemGray,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 14),

                      // --- Tier 2: Balance Amounts & Progress Bar ---
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Expanded(
                            child: Text(
                              Money(minorUnits: currentAmount, currencyCode: currency)
                                  .format(locale: locale),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontSize: 19,
                                fontWeight: FontWeight.w800,
                                fontFeatures: AppTheme.tabularFigures,
                                letterSpacing: -0.3,
                                color: isDark
                                    ? Colors.white
                                    : const Color(0xFF1C1C1E),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Mục tiêu: ${parsedTarget != null && parsedTarget.minorUnits > 0 ? parsedTarget.format(locale: locale) : '0 ${AppCurrencies.byCode(currency).symbol}'}',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: AppleTokens.systemGray,
                              fontFeatures: AppTheme.tabularFigures,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 8),

                      // Smooth Capsule Progress Bar
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: Stack(
                          children: [
                            Container(
                              height: 7,
                              width: double.infinity,
                              color: accentColor.withValues(
                                alpha: isDark ? 0.18 : 0.10,
                              ),
                            ),
                            FractionallySizedBox(
                              widthFactor: previewProgress.clamp(0.0, 1.0),
                              child: Container(
                                height: 7,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      accentColor,
                                      Color.lerp(
                                        accentColor,
                                        Colors.white,
                                        0.25,
                                      )!,
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(4),
                                  boxShadow: [
                                    BoxShadow(
                                      color: accentColor.withValues(alpha: 0.5),
                                      blurRadius: 4,
                                      offset: const Offset(0, 1),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 6),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '$progressPercent% đã tích lũy',
                            style: const TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                              color: AppleTokens.systemGray,
                            ),
                          ),
                          Text(
                            'Còn lại: ${Money(minorUnits: remainingMinor, currencyCode: currency).format(locale: locale)}',
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                              fontFeatures: AppTheme.tabularFigures,
                              color: isDark ? Colors.white70 : Colors.black87,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
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

  Widget _buildHeroAmountCard({
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

    return AppleGlassCard(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      borderRadius: BorderRadius.circular(AppleTokens.radiusCard),
      borderColor: _isAmountFocused
          ? accentColor
          : (isDark
              ? Colors.white.withValues(alpha: 0.12)
              : AppleTokens.borderLight),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    CupertinoIcons.money_dollar_circle_fill,
                    size: 14,
                    color: accentColor,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    l10n.savingsTargetAmount.toUpperCase(),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.6,
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
          const SizedBox(height: 10),
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
              constraints: const BoxConstraints(minHeight: 56),
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: _isAmountFocused
                    ? accentColor.withValues(alpha: isDark ? 0.14 : 0.08)
                    : (isDark
                        ? Colors.white.withValues(alpha: 0.04)
                        : Colors.black.withValues(alpha: 0.02)),
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
          const SizedBox(height: 10),
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
      ),
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
              _buildDurationChip(30, '1 tháng', isDark, accentColor),
              _buildDurationChip(90, '3 tháng', isDark, accentColor),
              _buildDurationChip(180, '6 tháng', isDark, accentColor),
              _buildDurationChip(365, '1 năm', isDark, accentColor),
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
                            : 'Tùy chọn ngày...',
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
                        'Nhịp độ tích lũy thông minh'.toUpperCase(),
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.4,
                          color: accentColor,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '~ ${Money(minorUnits: dailyNeeded, currencyCode: currency).format(locale: locale)} / ngày  (hoặc ~ ${Money(minorUnits: monthlyNeeded ?? 0, currencyCode: currency).format(locale: locale)} / tháng)',
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
                    'Mẹo: Chọn hạn hoàn thành giúp bạn chia nhỏ số tiền cần tiết kiệm mỗi ngày/tháng để dễ dàng hoàn thành mục tiêu.',
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
    return SizedBox(
      height: 52,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: _SavingsGoalFormSheetState._availableIcons.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final item = _SavingsGoalFormSheetState._availableIcons[index];
          final isSelected = _selectedIcon == item.$1;
          return ApplePressable(
            scaleDown: 0.92,
            onTap: () {
              unawaited(HapticFeedback.selectionClick());
              setState(() => _selectedIcon = item.$1);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: 50,
              height: 50,
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
                    style: TextStyle(
                      fontSize: 8.5,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
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
      ),
    );
  }
}
