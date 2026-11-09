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
import 'package:so_thu_chi/core/utils/date_formatter.dart';
import 'package:so_thu_chi/core/utils/money.dart';
import 'package:so_thu_chi/core/widgets/apple_kit.dart';
import 'package:so_thu_chi/features/accounts/domain/entities/account.dart';
import 'package:so_thu_chi/features/accounts/presentation/controllers/accounts_controller.dart';
import 'package:so_thu_chi/features/categories/domain/entities/category.dart';
import 'package:so_thu_chi/features/categories/presentation/controllers/categories_controller.dart';
import 'package:so_thu_chi/features/recurring/domain/entities/recurring_transaction.dart';
import 'package:so_thu_chi/features/recurring/presentation/controllers/recurring_controller.dart';
import 'package:so_thu_chi/features/settings/presentation/controllers/settings_controller.dart';
import 'package:so_thu_chi/features/transactions/domain/entities/transaction_entity.dart';
import 'package:so_thu_chi/l10n/app_localizations.dart';

class _RecurringTemplate {
  const _RecurringTemplate({
    required this.title,
    required this.type,
    required this.categoryKeyword,
    required this.icon,
    required this.defaultNote,
  });

  final String title;
  final TransactionType type;
  final String categoryKeyword;
  final IconData icon;
  final String defaultNote;
}

/// Redesigned, state-of-the-art Apple HIG Recurring Bill / Subscription Bottom Sheet.
/// Features interactive Live Bill Preview, Hero Amount Input with quick presets and triple-zero adder,
/// tactile Segmented Type Pill, Quick Bill Templates, Apple Interval Selector with schedule projection,
/// visual Category & Wallet carousels, and Apple Glass auto-execute toggle.
class RecurringFormSheet extends ConsumerStatefulWidget {
  const RecurringFormSheet({
    super.key,
    this.existing,
  });

  final RecurringTransaction? existing;

  static Future<void> show(BuildContext context, {RecurringTransaction? existing}) {
    return AppleModalSheetLayout.show<void>(
      context: context,
      builder: (_) => RecurringFormSheet(existing: existing),
    );
  }

  @override
  ConsumerState<RecurringFormSheet> createState() => _RecurringFormSheetState();
}

class _RecurringFormSheetState extends ConsumerState<RecurringFormSheet> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  final _amountFocusNode = FocusNode();

  TransactionType _type = TransactionType.expense;
  RecurringInterval _interval = RecurringInterval.monthly;
  DateTime _startDate = DateTime.now();
  String? _accountId;
  String? _categoryId;
  bool _autoExecute = false;
  bool _isAmountFocused = false;
  bool _isSubmitting = false;

  bool get _isEditing => widget.existing != null;

  static const _popularTemplates = [
    _RecurringTemplate(
      title: 'Tiền điện sinh hoạt',
      type: TransactionType.expense,
      categoryKeyword: 'bills',
      icon: Icons.bolt_rounded,
      defaultNote: 'Hóa đơn tiền điện sinh hoạt hàng tháng',
    ),
    _RecurringTemplate(
      title: 'Tiền nước sinh hoạt',
      type: TransactionType.expense,
      categoryKeyword: 'bills',
      icon: Icons.water_drop_rounded,
      defaultNote: 'Hóa đơn tiền nước gia đình',
    ),
    _RecurringTemplate(
      title: 'Internet & Cáp quang',
      type: TransactionType.expense,
      categoryKeyword: 'bills',
      icon: Icons.wifi_rounded,
      defaultNote: 'Cước mạng internet cáp quang gia đình',
    ),
    _RecurringTemplate(
      title: 'Gói cước 4G / 5G',
      type: TransactionType.expense,
      categoryKeyword: 'bills',
      icon: Icons.phone_iphone_rounded,
      defaultNote: 'Cước data di động thoại và internet',
    ),
    _RecurringTemplate(
      title: 'Tiền thuê nhà / Chung cư',
      type: TransactionType.expense,
      categoryKeyword: 'housing',
      icon: Icons.home_rounded,
      defaultNote: 'Chi phí thuê nhà / phí dịch vụ chung cư',
    ),
    _RecurringTemplate(
      title: 'Netflix / Spotify',
      type: TransactionType.expense,
      categoryKeyword: 'entertainment',
      icon: Icons.tv_rounded,
      defaultNote: 'Thuê bao dịch vụ giải trí trực tuyến',
    ),
    _RecurringTemplate(
      title: 'Thẻ tập Gym / Yoga',
      type: TransactionType.expense,
      categoryKeyword: 'fitness',
      icon: Icons.fitness_center_rounded,
      defaultNote: 'Chi phí rèn luyện sức khỏe định kỳ',
    ),
    _RecurringTemplate(
      title: 'Lương cố định',
      type: TransactionType.income,
      categoryKeyword: 'salary',
      icon: Icons.payments_rounded,
      defaultNote: 'Thu nhập tiền lương cố định hàng tháng',
    ),
  ];

  @override
  void initState() {
    super.initState();
    final item = widget.existing;
    final locale =
        ref.read(settingsControllerProvider).value?.localeCode ?? 'vi';

    if (item != null) {
      _titleController.text = item.title;
      _amountController.text = item.money.toInputString(locale: locale);
      _noteController.text = item.note;
      _type = item.type;
      _interval = item.interval;
      _startDate = item.startDate;
      _accountId = item.accountId;
      _categoryId = item.categoryId;
      _autoExecute = item.autoExecute;
    }

    _amountFocusNode.addListener(_onFocusChange);
    _titleController.addListener(_onFieldChange);
    _amountController.addListener(_onFieldChange);
    _noteController.addListener(_onFieldChange);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ref.read(categoriesActionControllerProvider.notifier).seedDefaultsIfNeeded();
      }
    });
  }

  void _onFocusChange() {
    if (mounted) {
      setState(() => _isAmountFocused = _amountFocusNode.hasFocus);
    }
  }

  void _onFieldChange() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _amountFocusNode.removeListener(_onFocusChange);
    _titleController.removeListener(_onFieldChange);
    _amountController.removeListener(_onFieldChange);
    _noteController.removeListener(_onFieldChange);

    _amountFocusNode.dispose();
    _titleController.dispose();
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  String _intervalLabel(RecurringInterval interval, AppLocalizations l10n) {
    switch (interval) {
      case RecurringInterval.daily:
        return l10n.recurringIntervalDaily;
      case RecurringInterval.weekly:
        return l10n.recurringIntervalWeekly;
      case RecurringInterval.biweekly:
        return l10n.recurringIntervalBiweekly;
      case RecurringInterval.monthly:
        return l10n.recurringIntervalMonthly;
      case RecurringInterval.yearly:
        return l10n.recurringIntervalYearly;
    }
  }

  String _getScheduleExplanation(RecurringInterval interval, DateTime date) {
    switch (interval) {
      case RecurringInterval.daily:
        return 'Lặp lại tự động mỗi ngày một lần';
      case RecurringInterval.weekly:
        const weekdayNames = ['Thứ 2', 'Thứ 3', 'Thứ 4', 'Thứ 5', 'Thứ 6', 'Thứ 7', 'Chủ nhật'];
        final dayName = weekdayNames[(date.weekday - 1).clamp(0, 6)];
        return 'Lặp lại vào $dayName hàng tuần';
      case RecurringInterval.biweekly:
        const weekdayNames = ['Thứ 2', 'Thứ 3', 'Thứ 4', 'Thứ 5', 'Thứ 6', 'Thứ 7', 'Chủ nhật'];
        final dayName = weekdayNames[(date.weekday - 1).clamp(0, 6)];
        return 'Lặp lại 2 tuần một lần vào $dayName';
      case RecurringInterval.monthly:
        return 'Lặp lại vào ngày ${date.day} hàng tháng';
      case RecurringInterval.yearly:
        return 'Lặp lại vào ngày ${date.day}/${date.month} hàng năm';
    }
  }

  String _formatDaysUntilStart(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(date.year, date.month, date.day);
    final diff = target.difference(today).inDays;
    if (diff == 0) return 'Hôm nay';
    if (diff == 1) return 'Ngày mai';
    if (diff > 1) return 'Còn $diff ngày';
    return 'Quá hạn ${-diff} ngày';
  }

  double _getDynamicFontSize(int textLength) {
    if (textLength <= 7) return 32.0;
    if (textLength <= 10) return 26.0;
    if (textLength <= 13) return 22.0;
    return 18.0;
  }

  List<({int minorUnits, String label})> _getQuickPresets(String currencyCode) {
    if (currencyCode.toUpperCase() == 'VND') {
      return [
        (minorUnits: 100000, label: '100k'),
        (minorUnits: 200000, label: '200k'),
        (minorUnits: 500000, label: '500k'),
        (minorUnits: 1000000, label: '1 triệu'),
        (minorUnits: 2000000, label: '2 triệu'),
        (minorUnits: 5000000, label: '5 triệu'),
        (minorUnits: 10000000, label: '10 triệu'),
      ];
    }
    final info = AppCurrencies.byCode(currencyCode);
    final factor = info.minorUnitFactor;
    return [
      (minorUnits: 10 * factor, label: '${info.symbol}10'),
      (minorUnits: 25 * factor, label: '${info.symbol}25'),
      (minorUnits: 50 * factor, label: '${info.symbol}50'),
      (minorUnits: 100 * factor, label: '${info.symbol}100'),
      (minorUnits: 250 * factor, label: '${info.symbol}250'),
      (minorUnits: 500 * factor, label: '${info.symbol}500'),
    ];
  }

  void _setPresetAmount(int minorUnits, String currencyCode, String locale) {
    unawaited(HapticFeedback.selectionClick());
    final str = Money(minorUnits: minorUnits, currencyCode: currencyCode)
        .toInputString(locale: locale);
    setState(() {
      _amountController.text = str;
      _amountController.selection = TextSelection.collapsed(offset: str.length);
    });
  }

  void _appendTripleZeros(String currencyCode, String locale) {
    final current = _amountController.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (current.isEmpty || current == '0') return;
    unawaited(HapticFeedback.selectionClick());
    final newRaw = '${current}000';
    final parsed = int.tryParse(newRaw);
    if (parsed == null) return;
    final formatted = Money(minorUnits: parsed, currencyCode: currencyCode)
        .toInputString(locale: locale);
    setState(() {
      _amountController.text = formatted;
      _amountController.selection = TextSelection.collapsed(offset: formatted.length);
    });
  }

  void _applyTemplate(_RecurringTemplate template, List<Category> cats) {
    unawaited(HapticFeedback.selectionClick());
    setState(() {
      _titleController.text = template.title;
      _type = template.type;
      _interval = RecurringInterval.monthly;
      if (_noteController.text.trim().isEmpty) {
        _noteController.text = template.defaultNote;
      }

      // Match category
      final matchedCat = cats.where((c) {
        final idMatch = c.id.toLowerCase().contains(template.categoryKeyword.toLowerCase());
        final nameMatch = c.name.toLowerCase().contains(template.categoryKeyword.toLowerCase());
        return idMatch || nameMatch;
      }).firstOrNull;

      if (matchedCat != null) {
        _categoryId = matchedCat.id;
      }
    });
  }

  Future<void> _pickStartDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
    );
    if (picked != null && mounted) {
      unawaited(HapticFeedback.selectionClick());
      setState(() => _startDate = picked);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final l10n = context.l10n;

    final wallets = ref.read(activeAccountsProvider);
    final currency = wallets.isNotEmpty
        ? wallets.first.currency
        : AppCurrencies.defaultCode;
    final parsed =
        Money.tryParse(_amountController.text, currencyCode: currency);

    if (parsed == null || parsed.minorUnits <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.recurringAmountRequired)),
      );
      return;
    }

    if (_accountId == null || _accountId!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.recurringWalletRequired)),
      );
      return;
    }

    final entity = RecurringTransaction(
      id: widget.existing?.id ?? '',
      title: _titleController.text.trim(),
      amount: parsed.minorUnits,
      currency: currency,
      type: _type,
      interval: _interval,
      startDate: _startDate,
      nextDueDate: widget.existing?.nextDueDate ?? _startDate,
      accountId: _accountId!,
      categoryId: _categoryId ??
          (_type == TransactionType.income
              ? 'default_other_income'
              : 'default_other_expense'),
      autoExecute: _autoExecute,
      note: _noteController.text.trim(),
      createdAt: widget.existing?.createdAt ?? DateTime.now(),
      updatedAt: DateTime.now(),
    );

    setState(() => _isSubmitting = true);
    unawaited(HapticFeedback.mediumImpact());
    final actionNotifier =
        ref.read(recurringActionControllerProvider.notifier);
    final res = _isEditing
        ? await actionNotifier.updateRecurring(entity)
        : await actionNotifier.createRecurring(entity);

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    res.fold(
      onSuccess: (_) {
        unawaited(HapticFeedback.lightImpact());
        Navigator.of(context).pop();
      },
      onFailure: (err) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.localizeError(err))),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final l10n = context.l10n;
    final wallets = ref.watch(activeAccountsProvider);
    final expenseCats = ref.watch(expenseCategoriesProvider);
    final incomeCats = ref.watch(incomeCategoriesProvider);
    final availableCats = _type == TransactionType.income ? incomeCats : expenseCats;
    final settings = ref.watch(settingsControllerProvider).value;
    final locale = settings?.localeCode ?? 'vi';
    final currency = wallets.isNotEmpty
        ? wallets.first.currency
        : (settings?.currencyCode ?? AppCurrencies.defaultCode);

    if (_accountId == null && wallets.isNotEmpty) {
      _accountId = wallets.first.id;
    }
    if (availableCats.isNotEmpty &&
        (_categoryId == null || !availableCats.any((c) => c.id == _categoryId))) {
      _categoryId = availableCats.first.id;
    }

    final isExpense = _type == TransactionType.expense;
    final accentColor = isExpense ? AppleTokens.rubyExpense : AppleTokens.jadePrimary;
    final parsedAmount =
        Money.tryParse(_amountController.text, currencyCode: currency);

    Account? selectedWallet;
    if (_accountId != null) {
      try {
        selectedWallet = wallets.firstWhere((w) => w.id == _accountId);
      } catch (_) {}
    }

    Category? selectedCategory;
    if (_categoryId != null) {
      try {
        selectedCategory = availableCats.firstWhere((c) => c.id == _categoryId);
      } catch (_) {}
    }

    return AppleModalSheetLayout(
      title: _isEditing ? l10n.recurringEditTitle : l10n.recurringNewTitle,
      subtitle: _isEditing
          ? 'Cập nhật chu kỳ & thông tin gói định kỳ'
          : 'Thiết lập hóa đơn lặp lại & nhắc nhở thanh toán',
      bottomAction: AppleButton.primary(
        color: accentColor,
        isLoading: _isSubmitting,
        label: _isEditing
            ? l10n.recurringConfirmUpdate
            : l10n.recurringConfirmCreate,
        onPressed: _isSubmitting ? null : _submit,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            // 1. Live Recurring Bill Preview Card
            _buildLivePreviewCard(
              context: context,
              theme: theme,
              isDark: isDark,
              accentColor: accentColor,
              locale: locale,
              currency: currency,
              l10n: l10n,
              parsedAmount: parsedAmount,
              selectedCategory: selectedCategory,
              selectedWallet: selectedWallet,
            ),
            const SizedBox(height: 16),

            // 2. Sliding Segmented Type Pill (Chi tiêu vs Thu nhập)
            _buildTypeSegmentedPill(
              isDark: isDark,
              l10n: l10n,
            ),
            const SizedBox(height: 16),

            // 3. Quick Bill Templates (only in add mode)
            if (!_isEditing) ...[
              _buildSectionHeader(
                icon: CupertinoIcons.sparkles,
                title: 'Mẫu hóa đơn thông dụng',
                accentColor: accentColor,
              ),
              _buildTemplatesCarousel(
                availableCats: availableCats,
                isDark: isDark,
              ),
              const SizedBox(height: 16),
            ],

            // 4. Bill Title & Note
            _buildSectionHeader(
              icon: CupertinoIcons.tag_fill,
              title: l10n.recurringTitleLabel,
              accentColor: accentColor,
            ),
            AppleTextField(
              controller: _titleController,
              placeholder: 'VD: Tiền điện, Internet, Tiền nhà, Netflix...',
              clearable: true,
              prefixIcon: Icon(
                CupertinoIcons.tag,
                size: 18,
                color: accentColor,
              ),
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? l10n.recurringTitleRequired
                  : null,
            ),
            const SizedBox(height: 16),

            // 5. Hero Amount Card
            _buildHeroAmountCard(
              context: context,
              isDark: isDark,
              currencyCode: currency,
              locale: locale,
              l10n: l10n,
              accentColor: accentColor,
            ),
            const SizedBox(height: 18),

            // 6. Recurrence Frequency / Interval Selector
            _buildSectionHeader(
              icon: CupertinoIcons.repeat,
              title: l10n.recurringFrequencyLabel,
              accentColor: accentColor,
            ),
            _buildIntervalSelector(
              isDark: isDark,
              l10n: l10n,
              accentColor: accentColor,
            ),
            const SizedBox(height: 18),

            // 7. Start Date & First Due Date Selector
            _buildSectionHeader(
              icon: CupertinoIcons.calendar,
              title: l10n.recurringStartDateLabel,
              accentColor: accentColor,
            ),
            _buildStartDateTile(
              context: context,
              isDark: isDark,
              locale: locale,
              accentColor: accentColor,
            ),
            const SizedBox(height: 18),

            // 8. Category Selector
            _buildSectionHeader(
              icon: CupertinoIcons.square_grid_2x2_fill,
              title: l10n.recurringCategoryLabel,
              accentColor: accentColor,
            ),
            _buildCategorySelector(
              categories: availableCats,
              isDark: isDark,
              accentColor: accentColor,
            ),
            const SizedBox(height: 18),

            // 9. Wallet Selector
            _buildSectionHeader(
              icon: CupertinoIcons.creditcard_fill,
              title: l10n.recurringWalletLabel,
              accentColor: accentColor,
            ),
            _buildWalletSelector(
              wallets: wallets,
              isDark: isDark,
              locale: locale,
              accentColor: accentColor,
            ),
            const SizedBox(height: 18),

            // 10. Auto Execute Switch Card
            _buildAutoExecuteCard(
              isDark: isDark,
              l10n: l10n,
            ),
            const SizedBox(height: 16),

            // 11. Motivation / Contract Note
            _buildSectionHeader(
              icon: CupertinoIcons.doc_text_fill,
              title: 'Ghi chú / Mã khách hàng (Tùy chọn)',
              accentColor: accentColor,
            ),
            AppleTextField(
              controller: _noteController,
              placeholder: 'VD: Mã thuê bao cáp quang, số tài khoản nhận...',
              clearable: true,
              prefixIcon: Icon(
                CupertinoIcons.doc_text,
                size: 18,
                color: accentColor,
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

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
    required Money? parsedAmount,
    required Category? selectedCategory,
    required Account? selectedWallet,
  }) {
    final titleText = _titleController.text.trim().isNotEmpty
        ? _titleController.text.trim()
        : l10n.recurringTitleLabel;
    final noteText = _noteController.text.trim();
    final isExpense = _type == TransactionType.expense;

    return AppleGlassCard(
      borderRadius: BorderRadius.circular(AppleTokens.radiusHero),
      borderColor: accentColor.withValues(alpha: isDark ? 0.35 : 0.25),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Category Icon Badge
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      (selectedCategory != null
                              ? Color(selectedCategory.color)
                              : accentColor)
                          .withValues(alpha: isDark ? 0.95 : 0.9),
                      (selectedCategory != null
                              ? Color(selectedCategory.color)
                              : accentColor)
                          .withValues(alpha: isDark ? 0.75 : 0.7),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(AppleTokens.radiusCard),
                  boxShadow: [
                    BoxShadow(
                      color: (selectedCategory != null
                              ? Color(selectedCategory.color)
                              : accentColor)
                          .withValues(alpha: isDark ? 0.35 : 0.25),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Icon(
                  selectedCategory != null
                      ? AppIconCatalog.resolve(selectedCategory.icon)
                      : (isExpense
                          ? CupertinoIcons.arrow_up_right
                          : CupertinoIcons.arrow_down_left),
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      titleText,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.2,
                        color: _titleController.text.trim().isNotEmpty
                            ? (isDark ? Colors.white : Colors.black87)
                            : (isDark ? Colors.white38 : Colors.black38),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      parsedAmount != null && parsedAmount.minorUnits > 0
                          ? '${isExpense ? '-' : '+'}${parsedAmount.format(locale: locale)}'
                          : '0 ${AppCurrencies.byCode(currency).symbol}',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: accentColor,
                        fontFeatures: AppTheme.tabularFigures,
                        letterSpacing: -0.3,
                      ),
                    ),
                    if (noteText.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        '“$noteText”',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11,
                          fontStyle: FontStyle.italic,
                          color: isDark ? Colors.white60 : Colors.black54,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Badges: Frequency + Start Date / Next Due + Wallet + Auto Mode
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              // Frequency badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(AppleTokens.radiusPill),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      CupertinoIcons.repeat,
                      size: 11,
                      color: accentColor,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _intervalLabel(_interval, l10n),
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                        color: accentColor,
                      ),
                    ),
                  ],
                ),
              ),
              // Start Date badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.07)
                      : Colors.black.withValues(alpha: 0.04),
                  borderRadius: BorderRadius.circular(AppleTokens.radiusPill),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      CupertinoIcons.calendar,
                      size: 11,
                      color: isDark ? Colors.white70 : Colors.black54,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      AppDateUtils.formatShortDate(_startDate, locale: locale),
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white70 : Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),
              // Wallet badge
              if (selectedWallet != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(
                    color: Color(selectedWallet.color).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(AppleTokens.radiusPill),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        CupertinoIcons.creditcard,
                        size: 11,
                        color: Color(selectedWallet.color),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        selectedWallet.name,
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                          color: Color(selectedWallet.color),
                        ),
                      ),
                    ],
                  ),
                ),
              // Auto Mode badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: (_autoExecute ? AppleTokens.systemGreen : AppleTokens.systemGray)
                      .withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(AppleTokens.radiusPill),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _autoExecute ? CupertinoIcons.bolt_fill : CupertinoIcons.hand_draw,
                      size: 11,
                      color: _autoExecute ? AppleTokens.systemGreen : AppleTokens.systemGray,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _autoExecute ? 'Tự động' : 'Thủ công',
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                        color: _autoExecute ? AppleTokens.systemGreen : AppleTokens.systemGray,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTypeSegmentedPill({
    required bool isDark,
    required AppLocalizations l10n,
  }) {
    return Container(
      height: 40,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: isDark ? AppleTokens.bgDarkSecondary : AppleTokens.bgLightSecondary,
        borderRadius: BorderRadius.circular(AppleTokens.radiusPill),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {
                if (_type != TransactionType.expense) {
                  unawaited(HapticFeedback.selectionClick());
                  setState(() => _type = TransactionType.expense);
                }
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOutCubic,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: _type == TransactionType.expense
                      ? (isDark ? AppleTokens.bgDarkCard : Colors.white)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(AppleTokens.radiusPill - 2),
                  boxShadow: _type == TransactionType.expense
                      ? [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.08),
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
                      CupertinoIcons.arrow_up_right,
                      size: 14,
                      color: _type == TransactionType.expense
                          ? AppleTokens.rubyExpense
                          : (isDark ? Colors.white60 : Colors.black54),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      l10n.expense,
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: _type == TransactionType.expense
                            ? FontWeight.w700
                            : FontWeight.w500,
                        color: _type == TransactionType.expense
                            ? AppleTokens.rubyExpense
                            : (isDark ? Colors.white70 : Colors.black87),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {
                if (_type != TransactionType.income) {
                  unawaited(HapticFeedback.selectionClick());
                  setState(() => _type = TransactionType.income);
                }
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOutCubic,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: _type == TransactionType.income
                      ? (isDark ? AppleTokens.bgDarkCard : Colors.white)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(AppleTokens.radiusPill - 2),
                  boxShadow: _type == TransactionType.income
                      ? [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.08),
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
                      CupertinoIcons.arrow_down_left,
                      size: 14,
                      color: _type == TransactionType.income
                          ? AppleTokens.jadePrimary
                          : (isDark ? Colors.white60 : Colors.black54),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      l10n.income,
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: _type == TransactionType.income
                            ? FontWeight.w700
                            : FontWeight.w500,
                        color: _type == TransactionType.income
                            ? AppleTokens.jadePrimary
                            : (isDark ? Colors.white70 : Colors.black87),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTemplatesCarousel({
    required List<Category> availableCats,
    required bool isDark,
  }) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: [
          for (final template in _popularTemplates) ...[
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

  Widget _buildHeroAmountCard({
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
                    l10n.recurringAmountLabel.toUpperCase(),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.6,
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
          const SizedBox(height: 10),
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
      ),
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
    return ApplePressable(
      scaleDown: 0.96,
      onTap: _pickStartDate,
      child: AppleGlassCard(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        borderRadius: BorderRadius.circular(AppleTokens.radiusCard),
        borderColor: isDark
            ? Colors.white.withValues(alpha: 0.1)
            : AppleTokens.borderLight,
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppleTokens.systemIndigo.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                CupertinoIcons.calendar,
                color: AppleTokens.systemIndigo,
                size: 18,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Kỳ hạn thanh toán đầu tiên',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppleTokens.systemGray,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${AppDateUtils.formatShortDate(_startDate, locale: locale)}  •  ${_formatDaysUntilStart(_startDate)}',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              CupertinoIcons.chevron_forward,
              size: 16,
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
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: Color(w.color),
                        shape: BoxShape.circle,
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

  Widget _buildAutoExecuteCard({
    required bool isDark,
    required AppLocalizations l10n,
  }) {
    return AppleGlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      borderRadius: BorderRadius.circular(AppleTokens.radiusCard),
      borderColor: isDark
          ? Colors.white.withValues(alpha: 0.1)
          : AppleTokens.borderLight,
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: _autoExecute
                  ? AppleTokens.systemGreen.withValues(alpha: 0.15)
                  : (isDark
                      ? Colors.white.withValues(alpha: 0.05)
                      : Colors.black.withValues(alpha: 0.04)),
              shape: BoxShape.circle,
            ),
            child: Icon(
              CupertinoIcons.bolt_fill,
              color: _autoExecute
                  ? AppleTokens.systemGreen
                  : AppleTokens.systemGray,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
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
                  l10n.recurringAutoExecuteSubtitle,
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
      ),
    );
  }
}
