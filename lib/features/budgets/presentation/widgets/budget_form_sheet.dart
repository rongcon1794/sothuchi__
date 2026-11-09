import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:so_thu_chi/core/constants/currency_constants.dart';
import 'package:so_thu_chi/core/constants/icon_catalog.dart';
import 'package:so_thu_chi/core/l10n/l10n_ext.dart';
import 'package:so_thu_chi/core/theme/app_theme.dart';
import 'package:so_thu_chi/core/theme/apple_theme_tokens.dart';
import 'package:so_thu_chi/core/utils/money.dart';
import 'package:so_thu_chi/core/widgets/apple_kit.dart';
import 'package:so_thu_chi/features/budgets/domain/entities/budget.dart';
import 'package:so_thu_chi/features/budgets/presentation/controllers/budgets_controller.dart';
import 'package:so_thu_chi/features/categories/domain/entities/category.dart';
import 'package:so_thu_chi/features/categories/presentation/controllers/categories_controller.dart';
import 'package:so_thu_chi/features/categories/presentation/widgets/category_form_sheet.dart';
import 'package:so_thu_chi/features/settings/presentation/controllers/settings_controller.dart';

enum _BudgetScopeMode { overall, category }

/// Redesigned, state-of-the-art Apple HIG & Lucian Budget Setup Bottom Sheet.
/// Features interactive semantic Hero Amount display, quick amount preset pills,
/// tactile segmented scope toggle (Overall Monthly vs Expense Category Carousel),
/// and dynamic Live Risk & Buffer intelligence calculation card.
class BudgetFormBottomSheet extends ConsumerStatefulWidget {
  const BudgetFormBottomSheet({
    super.key,
    required this.monthStart,
    this.existing,
  });

  final DateTime monthStart;
  final Budget? existing;

  static Future<void> show(
    BuildContext context, {
    required DateTime monthStart,
    Budget? existing,
  }) {
    return AppleModalSheetLayout.show<void>(
      context: context,
      builder: (_) => BudgetFormBottomSheet(
        monthStart: monthStart,
        existing: existing,
      ),
    );
  }

  @override
  ConsumerState<BudgetFormBottomSheet> createState() =>
      _BudgetFormBottomSheetState();
}

class _BudgetFormBottomSheetState extends ConsumerState<BudgetFormBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _amountController;
  final _amountFocusNode = FocusNode();
  Timer? _autoFocusTimer;

  late _BudgetScopeMode _scopeMode;
  String? _selectedCategoryId; // null => Overall Monthly Budget
  int _threshold = 80;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    final locale =
        ref.read(settingsControllerProvider).value?.localeCode ?? 'vi';

    _selectedCategoryId = existing?.categoryId;
    _scopeMode = existing?.categoryId == null
        ? _BudgetScopeMode.overall
        : _BudgetScopeMode.category;
    _threshold = existing?.alertThreshold ?? 80;

    _amountController = TextEditingController(
      text: existing != null
          ? existing.limitMoney.toInputString(locale: locale)
          : '',
    );

    _amountController.addListener(_onAmountChange);

    // Auto-focus amount field when creating a new budget
    if (existing == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _autoFocusTimer = Timer(const Duration(milliseconds: 250), () {
          if (mounted && !_amountFocusNode.hasFocus) {
            _amountFocusNode.requestFocus();
            SystemChannels.textInput.invokeMethod<void>('TextInput.show');
          }
        });
      });
    }
  }

  void _onAmountChange() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _autoFocusTimer?.cancel();
    _amountController.removeListener(_onAmountChange);
    _amountFocusNode.dispose();
    _amountController.dispose();
    super.dispose();
  }

  List<({int minorUnits, String label})> _getQuickPresets(String currencyCode) {
    if (currencyCode.toUpperCase() == 'VND') {
      return [
        (minorUnits: 1000000, label: '1 triệu'),
        (minorUnits: 2000000, label: '2 triệu'),
        (minorUnits: 5000000, label: '5 triệu'),
        (minorUnits: 10000000, label: '10 triệu'),
        (minorUnits: 20000000, label: '20 triệu'),
      ];
    }
    final info = AppCurrencies.byCode(currencyCode);
    final factor = info.minorUnitFactor;
    return [
      (minorUnits: 100 * factor, label: '${info.symbol}100'),
      (minorUnits: 250 * factor, label: '${info.symbol}250'),
      (minorUnits: 500 * factor, label: '${info.symbol}500'),
      (minorUnits: 1000 * factor, label: '${info.symbol}1.000'),
      (minorUnits: 2500 * factor, label: '${info.symbol}2.500'),
    ];
  }

  void _setPresetAmount(int minorUnits, String currencyCode, String locale) {
    unawaited(HapticFeedback.selectionClick());
    final str = Money(minorUnits: minorUnits, currencyCode: currencyCode)
        .toInputString(locale: locale);
    setState(() {
      _amountController.text = str;
    });
  }

  Future<void> _openCreateCategorySheet(BuildContext context) async {
    final created = await CategoryFormSheet.show(
      context,
      initialType: CategoryType.expense,
    );
    if (created != null && mounted) {
      setState(() {
        _scopeMode = _BudgetScopeMode.category;
        _selectedCategoryId = created.id;
      });
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final settings = ref.read(settingsControllerProvider).value;
    final currency = widget.existing?.currency ??
        settings?.currencyCode ??
        AppCurrencies.defaultCode;
    final parsed = Money.tryParse(
      _amountController.text,
      currencyCode: currency,
    );
    if (parsed == null || parsed.minorUnits <= 0) return;

    final messenger = ScaffoldMessenger.of(context);
    final categoryIdToSave =
        _scopeMode == _BudgetScopeMode.overall ? null : _selectedCategoryId;

    final res = await ref
        .read(budgetsActionControllerProvider.notifier)
        .upsertBudget(
          existingId: widget.existing?.id,
          categoryId: categoryIdToSave,
          amount: parsed.minorUnits,
          currency: currency,
          monthStart: widget.monthStart,
          alertThreshold: _threshold,
        );

    if (!mounted) return;
    res.fold(
      onSuccess: (_) => Navigator.of(context).pop(),
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
    final isDark = theme.brightness == Brightness.dark;
    final isOled = context.isOled;

    final settings = ref.watch(settingsControllerProvider).value;
    final locale = settings?.localeCode ?? 'vi';
    final currencyCode = widget.existing?.currency ??
        settings?.currencyCode ??
        AppCurrencies.defaultCode;
    final expenseCategories = ref.watch(expenseCategoriesProvider);

    final monthStr =
        '${widget.monthStart.month}/${widget.monthStart.year}';
    final subtitleText = locale.startsWith('vi')
        ? 'Áp dụng cho tháng $monthStr'
        : 'Applies to $monthStr';

    final parsedMoney = Money.tryParse(
      _amountController.text,
      currencyCode: currencyCode,
    );

    final quickPresets = _getQuickPresets(currencyCode);

    final alertColor = _threshold >= 90
        ? LucianTokens.danger
        : (_threshold >= 80
            ? AppleTokens.systemOrange
            : LucianTokens.resolveMint(isDark));

    return AppleModalSheetLayout(
      title: widget.existing != null ? l10n.editBudget : l10n.addBudget,
      subtitle: subtitleText,
      bottomAction: AppleButton.primary(
        onPressed: _save,
        label: l10n.save,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            // 1. Hero Amount Card
            HeroAmountCard(
              controller: _amountController,
              currencyCode: currencyCode,
              locale: locale,
              label: l10n.budgetLimit,
              accentColor: AppleTokens.systemBlue,
              presets: quickPresets,
              showTripleZeroButton: false,
              onPresetSelected: (minorUnits) =>
                  _setPresetAmount(minorUnits, currencyCode, locale),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 18),

            // 2. Scope Selection Section
            Text(
              l10n.budgetScope,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
                fontSize: 13,
                color: isDark ? const Color(0xFFE5E5EA) : const Color(0xFF1C1C1E),
              ),
            ),
            const SizedBox(height: 10),

            // Segmented Pill
            Container(
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                color: isOled
                    ? AppleTokens.bgOledSecondary
                    : (isDark
                        ? AppleTokens.bgDarkSecondary
                        : AppleTokens.bgLightSecondary),
                borderRadius:
                    BorderRadius.circular(AppleTokens.radiusPill),
                border: Border.all(
                  color: isOled
                      ? AppleTokens.bgOledBorder
                      : AppleTokens.borderLight,
                  width: AppleTokens.hairline,
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: ApplePressable(
                      scaleDown: 0.96,
                      onTap: () {
                        unawaited(HapticFeedback.selectionClick());
                        setState(() {
                          _scopeMode = _BudgetScopeMode.overall;
                          _selectedCategoryId = null;
                        });
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: _scopeMode == _BudgetScopeMode.overall
                              ? (isOled
                                  ? AppleTokens.bgOledCard
                                  : (isDark
                                      ? AppleTokens.bgDarkCard
                                      : Colors.white))
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(
                              AppleTokens.radiusPill),
                          boxShadow: _scopeMode == _BudgetScopeMode.overall &&
                                  !isOled
                              ? [
                                  BoxShadow(
                                    color: Colors.black.withValues(
                                        alpha: isDark ? 0.2 : 0.06),
                                    blurRadius: 4,
                                    offset: const Offset(0, 1),
                                  ),
                                ]
                              : null,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              CupertinoIcons.square_stack_3d_up,
                              size: 15,
                              color: _scopeMode == _BudgetScopeMode.overall
                                  ? AppleTokens.systemBlue
                                  : AppleTokens.systemGray,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              locale.startsWith('vi')
                                  ? 'Tổng chi tiêu'
                                  : 'Overall',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight:
                                    _scopeMode == _BudgetScopeMode.overall
                                        ? FontWeight.w700
                                        : FontWeight.w500,
                                color: _scopeMode == _BudgetScopeMode.overall
                                    ? (isDark
                                        ? Colors.white
                                        : Colors.black87)
                                    : AppleTokens.systemGray,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: ApplePressable(
                      scaleDown: 0.96,
                      onTap: () {
                        unawaited(HapticFeedback.selectionClick());
                        setState(() {
                          _scopeMode = _BudgetScopeMode.category;
                          if (_selectedCategoryId == null &&
                              expenseCategories.isNotEmpty) {
                            _selectedCategoryId =
                                expenseCategories.first.id;
                          }
                        });
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: _scopeMode == _BudgetScopeMode.category
                              ? (isOled
                                  ? AppleTokens.bgOledCard
                                  : (isDark
                                      ? AppleTokens.bgDarkCard
                                      : Colors.white))
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(
                              AppleTokens.radiusPill),
                          boxShadow: _scopeMode == _BudgetScopeMode.category &&
                                  !isOled
                              ? [
                                  BoxShadow(
                                    color: Colors.black.withValues(
                                        alpha: isDark ? 0.2 : 0.06),
                                    blurRadius: 4,
                                    offset: const Offset(0, 1),
                                  ),
                                ]
                              : null,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              CupertinoIcons.square_grid_2x2,
                              size: 15,
                              color: _scopeMode == _BudgetScopeMode.category
                                  ? AppleTokens.systemBlue
                                  : AppleTokens.systemGray,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              locale.startsWith('vi')
                                  ? 'Theo danh mục'
                                  : 'By Category',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight:
                                    _scopeMode == _BudgetScopeMode.category
                                        ? FontWeight.w700
                                        : FontWeight.w500,
                                color: _scopeMode == _BudgetScopeMode.category
                                    ? (isDark
                                        ? Colors.white
                                        : Colors.black87)
                                    : AppleTokens.systemGray,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Scope Content
            if (_scopeMode == _BudgetScopeMode.overall) ...[
              AppleCard(
                borderRadius:
                    BorderRadius.circular(AppleTokens.radiusCard),
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    const AppleSquircleBadge(
                      icon: CupertinoIcons.chart_pie_fill,
                      backgroundColor: AppleTokens.systemBlue,
                      gradient: LinearGradient(
                        colors: [Color(0xFF007AFF), Color(0xFF5856D6)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      size: 40,
                      iconSize: 20,
                      radius: 11,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.overallMonthlyBudget,
                            style: const TextStyle(
                              fontSize: 14.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            locale.startsWith('vi')
                                ? 'Theo dõi và kiểm soát toàn bộ chi tiêu trong tháng.'
                                : 'Track and control overall spending for the month.',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppleTokens.systemGray,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ] else ...[
              // Expense Category Horizontal Picker
              SizedBox(
                height: 84,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  itemCount: expenseCategories.length + 1,
                  separatorBuilder: (_, _) =>
                      const SizedBox(width: 10),
                  itemBuilder: (context, index) {
                    if (index == expenseCategories.length) {
                      // Add Category Option
                      return ApplePressable(
                        scaleDown: 0.94,
                        onTap: () => _openCreateCategorySheet(context),
                        child: Container(
                          width: 76,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 4, vertical: 8),
                          decoration: BoxDecoration(
                            color: isOled
                                ? AppleTokens.bgOledSecondary
                                : (isDark
                                    ? AppleTokens.bgDarkSecondary
                                    : AppleTokens.bgLightSecondary),
                            borderRadius: BorderRadius.circular(
                                AppleTokens.radiusCard),
                            border: Border.all(
                              color: AppleTokens.systemBlue
                                  .withValues(alpha: 0.4),
                              width: AppleTokens.hairline,
                            ),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              AppleSquircleBadge(
                                icon: CupertinoIcons.plus,
                                backgroundColor: AppleTokens.systemBlue
                                    .withValues(alpha: 0.15),
                                iconColor: AppleTokens.systemBlue,
                                size: 32,
                                iconSize: 16,
                                radius: 8,
                              ),
                              const SizedBox(height: 6),
                              Text(
                                locale.startsWith('vi')
                                    ? 'Thêm'
                                    : 'Add',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
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

                    final cat = expenseCategories[index];
                    final isSelected = cat.id == _selectedCategoryId;
                    final catColor = AppIconCatalog.contrastSafeColor(
                      Color(cat.color),
                      theme.brightness,
                    );

                    return ApplePressable(
                      scaleDown: 0.94,
                      onTap: () {
                        unawaited(HapticFeedback.selectionClick());
                        setState(() => _selectedCategoryId = cat.id);
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        width: 76,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 4, vertical: 8),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? catColor.withValues(
                                  alpha: isDark ? 0.2 : 0.1)
                              : (isOled
                                  ? AppleTokens.bgOledSecondary
                                  : (isDark
                                      ? AppleTokens.bgDarkSecondary
                                      : AppleTokens.bgLightSecondary)),
                          borderRadius: BorderRadius.circular(
                              AppleTokens.radiusCard),
                          border: Border.all(
                            color: isSelected
                                ? catColor
                                : (isOled
                                    ? AppleTokens.bgOledBorder
                                    : AppleTokens.borderLight),
                            width: isSelected
                                ? 1.8
                                : AppleTokens.hairline,
                          ),
                          boxShadow: isSelected && !isOled
                              ? [
                                  BoxShadow(
                                    color: catColor.withValues(
                                        alpha: isDark ? 0.3 : 0.15),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ]
                              : null,
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            AppleSquircleBadge(
                              icon: AppIconCatalog.resolve(cat.icon),
                              backgroundColor: catColor,
                              size: 32,
                              iconSize: 16,
                              radius: 8,
                            ),
                            const SizedBox(height: 6),
                            Text(
                              DefaultCategoryLocalization.resolveName(
                                l10n,
                                categoryId: cat.id,
                                fallbackName: cat.name,
                              ),
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
                                    : (isDark
                                        ? Colors.white70
                                        : Colors.black87),
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
            const SizedBox(height: 18),

            // 3. Smart Alert Threshold Section
            AppleGlassCard(
              padding: const EdgeInsets.all(16),
              borderRadius: BorderRadius.circular(AppleTokens.radiusCard),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        locale.startsWith('vi')
                            ? 'Mức cảnh báo sớm'
                            : 'Alert threshold',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: alertColor.withValues(alpha: 0.15),
                          borderRadius:
                              BorderRadius.circular(AppleTokens.radiusPill),
                        ),
                        child: Text(
                          '$_threshold%',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: alertColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Quick Threshold Preset Chips
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [50, 70, 80, 90, 100].map((preset) {
                      final isSelected = _threshold == preset;
                      final chipColor = preset >= 90
                          ? LucianTokens.danger
                          : (preset >= 80
                              ? AppleTokens.systemOrange
                              : LucianTokens.resolveMint(isDark));
                      return ApplePressable(
                        onTap: () {
                          HapticFeedback.selectionClick();
                          setState(() => _threshold = preset);
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          curve: LucianTokens.ease,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? chipColor
                                : (isDark
                                    ? Colors.white.withValues(alpha: 0.06)
                                    : Colors.black.withValues(alpha: 0.04)),
                            borderRadius: BorderRadius.circular(
                                AppleTokens.radiusPill),
                            border: Border.all(
                              color: isSelected
                                  ? Colors.transparent
                                  : (isDark
                                      ? Colors.white.withValues(alpha: 0.1)
                                      : Colors.black
                                          .withValues(alpha: 0.08)),
                            ),
                          ),
                          child: Text(
                            '$preset%',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: isSelected
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                              color: isSelected
                                  ? Colors.white
                                  : theme.colorScheme.onSurface
                                      .withValues(alpha: 0.8),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 8),

                  SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      activeTrackColor: alertColor,
                      thumbColor: alertColor,
                      inactiveTrackColor: isDark
                          ? Colors.white.withValues(alpha: 0.1)
                          : Colors.black.withValues(alpha: 0.08),
                    ),
                    child: Slider(
                      value: _threshold.toDouble(),
                      min: 50,
                      max: 100,
                      divisions: 10,
                      label: '$_threshold%',
                      semanticFormatterCallback: (val) => '${val.round()}%',
                      onChanged: (val) =>
                          setState(() => _threshold = val.round()),
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Dynamic Live Risk & Buffer Calculation Box
                  _buildLiveThresholdCalculationBox(
                    budgetMoney: parsedMoney,
                    threshold: _threshold,
                    locale: locale,
                    isDark: isDark,
                    alertColor: alertColor,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildLiveThresholdCalculationBox({
    required Money? budgetMoney,
    required int threshold,
    required String locale,
    required bool isDark,
    required Color alertColor,
  }) {
    if (budgetMoney == null || budgetMoney.minorUnits <= 0) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: alertColor.withValues(alpha: isDark ? 0.1 : 0.06),
          borderRadius: BorderRadius.circular(AppleTokens.radiusCard),
          border: Border.all(
            color: alertColor.withValues(alpha: isDark ? 0.25 : 0.15),
            width: AppleTokens.hairline,
          ),
        ),
        child: Row(
          children: [
            Icon(CupertinoIcons.bell_fill, size: 15, color: alertColor),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                locale.startsWith('vi')
                    ? 'Cảnh báo sẽ tự động kích hoạt khi chi tiêu đạt $threshold% hạn mức.'
                    : 'Alert triggers automatically when spending reaches $threshold%.',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: isDark
                      ? const Color(0xFFE5E5EA)
                      : const Color(0xFF3A3A3C),
                ),
              ),
            ),
          ],
        ),
      );
    }

    final warnMinorUnits = (budgetMoney.minorUnits * threshold / 100).round();
    final warnMoney = Money(
      minorUnits: warnMinorUnits,
      currencyCode: budgetMoney.currencyCode,
    );
    final remainingMinorUnits = budgetMoney.minorUnits - warnMinorUnits;
    final remainingMoney = Money(
      minorUnits: remainingMinorUnits,
      currencyCode: budgetMoney.currencyCode,
    );

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: alertColor.withValues(alpha: isDark ? 0.12 : 0.07),
        borderRadius: BorderRadius.circular(AppleTokens.radiusCard),
        border: Border.all(
          color: alertColor.withValues(alpha: isDark ? 0.3 : 0.18),
          width: AppleTokens.hairline,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(CupertinoIcons.bell_fill, size: 15, color: alertColor),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  locale.startsWith('vi')
                      ? 'Cảnh báo khi chi đạt:'
                      : 'Triggers when spent:',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: isDark
                        ? const Color(0xFFD1D1D6)
                        : const Color(0xFF3A3A3C),
                  ),
                ),
              ),
              Text(
                warnMoney.format(locale: locale),
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  fontFeatures: AppTheme.tabularFigures,
                  color: alertColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Icon(
                CupertinoIcons.shield_fill,
                size: 15,
                color: isDark ? Colors.white70 : Colors.black54,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  locale.startsWith('vi')
                      ? 'Khoảng đệm an toàn:'
                      : 'Safety buffer:',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: isDark
                        ? const Color(0xFFD1D1D6)
                        : const Color(0xFF3A3A3C),
                  ),
                ),
              ),
              Text(
                remainingMoney.format(locale: locale),
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  fontFeatures: AppTheme.tabularFigures,
                  color: isDark ? Colors.white70 : Colors.black87,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
