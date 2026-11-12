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


part 'recurring_form_sections.dart';
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
    // --- Chi tiêu định kỳ (Expenses) ---
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
      title: 'Học phí / Khóa học',
      type: TransactionType.expense,
      categoryKeyword: 'education',
      icon: Icons.school_rounded,
      defaultNote: 'Học phí định kỳ hoặc lớp học kỹ năng',
    ),
    _RecurringTemplate(
      title: 'Bảo hiểm định kỳ',
      type: TransactionType.expense,
      categoryKeyword: 'insurance',
      icon: Icons.health_and_safety_rounded,
      defaultNote: 'Phí bảo hiểm nhân thọ / y tế định kỳ',
    ),

    // --- Thu nhập định kỳ (Income) ---
    _RecurringTemplate(
      title: 'Lương cố định',
      type: TransactionType.income,
      categoryKeyword: 'salary',
      icon: Icons.payments_rounded,
      defaultNote: 'Thu nhập tiền lương cố định hàng tháng',
    ),
    _RecurringTemplate(
      title: 'Tiền thưởng định kỳ',
      type: TransactionType.income,
      categoryKeyword: 'bonus',
      icon: Icons.card_giftcard_rounded,
      defaultNote: 'Thưởng KPI hoặc trợ cấp định kỳ',
    ),
    _RecurringTemplate(
      title: 'Cho thuê nhà / Mặt bằng',
      type: TransactionType.income,
      categoryKeyword: 'rental',
      icon: Icons.real_estate_agent_rounded,
      defaultNote: 'Thu nhập từ tiền cho thuê bất động sản',
    ),
    _RecurringTemplate(
      title: 'Lãi tiết kiệm & Đầu tư',
      type: TransactionType.income,
      categoryKeyword: 'investment',
      icon: Icons.trending_up_rounded,
      defaultNote: 'Tiền lãi gửi tiết kiệm hoặc lợi nhuận đầu tư',
    ),
    _RecurringTemplate(
      title: 'Thu nhập Freelance / Ngoài giờ',
      type: TransactionType.income,
      categoryKeyword: 'freelance',
      icon: Icons.laptop_mac_rounded,
      defaultNote: 'Thu nhập dự án làm ngoài định kỳ',
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

    _lastFieldsSnapshot = _computeFieldsSnapshot();
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

  String _lastFieldsSnapshot = '';

  String _computeFieldsSnapshot() =>
      '${_titleController.text}|${_amountController.text}|${_noteController.text}';

  void _onFocusChange() {
    final hasFocus = _amountFocusNode.hasFocus;
    if (hasFocus == _isAmountFocused) return;
    if (mounted) {
      setState(() => _isAmountFocused = hasFocus);
    }
  }

  void _onFieldChange() {
    final snap = _computeFieldsSnapshot();
    if (snap == _lastFieldsSnapshot) return;
    _lastFieldsSnapshot = snap;
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
    final expenseCats = ref.read(expenseCategoriesProvider);
    final incomeCats = ref.read(incomeCategoriesProvider);
    final targetCats =
        template.type == TransactionType.income ? incomeCats : expenseCats;

    setState(() {
      _titleController.text = template.title;
      _type = template.type;
      _interval = RecurringInterval.monthly;
      if (_noteController.text.trim().isEmpty) {
        _noteController.text = template.defaultNote;
      }

      // Match category
      final matchedCat = targetCats.where((c) {
        final idMatch = c.id
            .toLowerCase()
            .contains(template.categoryKeyword.toLowerCase());
        final nameMatch = c.name
            .toLowerCase()
            .contains(template.categoryKeyword.toLowerCase());
        return idMatch || nameMatch;
      }).firstOrNull;

      if (matchedCat != null) {
        _categoryId = matchedCat.id;
      } else if (targetCats.isNotEmpty) {
        _categoryId = targetCats.first.id;
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
          : (isExpense
              ? 'Thiết lập hóa đơn lặp lại & nhắc nhở thanh toán'
              : 'Thiết lập nguồn thu nhập lặp lại & nhắc nhở ngày nhận tiền'),
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
            const SizedBox(height: 12),

            // 2. Type Selector (Chi tiêu vs Thu nhập)
            _buildTypeTabSelector(
              context: context,
              isDark: isDark,
              l10n: l10n,
              expenseCats: expenseCats,
              incomeCats: incomeCats,
            ),
            const SizedBox(height: 12),

            // 3. Card 1: Templates + Title + Amount
            AppleGlassCard(
              borderRadius: BorderRadius.circular(AppleTokens.radiusHero),
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (!_isEditing) ...[
                    _buildSectionHeader(
                      icon: CupertinoIcons.sparkles,
                      title: _type == TransactionType.income
                          ? 'Mẫu thu nhập thông dụng'
                          : 'Mẫu hóa đơn thông dụng',
                      accentColor: accentColor,
                    ),
                    _buildTemplatesCarousel(
                      availableCats: availableCats,
                      isDark: isDark,
                    ),
                    const SizedBox(height: 12),
                    Divider(
                      height: AppleTokens.hairline,
                      thickness: AppleTokens.hairline,
                      color: isDark
                          ? AppleTokens.separatorDark
                          : AppleTokens.separatorLight,
                    ),
                    const SizedBox(height: 12),
                  ],
                  _buildSectionHeader(
                    icon: CupertinoIcons.tag_fill,
                    title: isExpense
                        ? l10n.recurringTitleLabel
                        : 'Tên khoản thu nhập',
                    accentColor: accentColor,
                  ),
                  AppleTextField(
                    controller: _titleController,
                    placeholder: isExpense
                        ? 'VD: Tiền điện, Internet, Tiền nhà, Netflix...'
                        : 'VD: Lương công ty, Cho thuê nhà, Tiền thưởng...',
                    clearable: true,
                    textCapitalization: TextCapitalization.sentences,
                    prefixIcon: Icon(
                      CupertinoIcons.tag,
                      size: 18,
                      color: accentColor,
                    ),
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? (isExpense
                            ? l10n.recurringTitleRequired
                            : 'Vui lòng nhập tên nguồn thu nhập')
                        : null,
                  ),
                  const SizedBox(height: 12),
                  Divider(
                    height: AppleTokens.hairline,
                    thickness: AppleTokens.hairline,
                    color: isDark
                        ? AppleTokens.separatorDark
                        : AppleTokens.separatorLight,
                  ),
                  const SizedBox(height: 12),
                  _buildHeroAmountSection(
                    context: context,
                    isDark: isDark,
                    currencyCode: currency,
                    locale: locale,
                    l10n: l10n,
                    accentColor: accentColor,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // 4. Card 2: Frequency & Start Date
            AppleGlassCard(
              borderRadius: BorderRadius.circular(AppleTokens.radiusHero),
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
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
                  const SizedBox(height: 12),
                  Divider(
                    height: AppleTokens.hairline,
                    thickness: AppleTokens.hairline,
                    color: isDark
                        ? AppleTokens.separatorDark
                        : AppleTokens.separatorLight,
                  ),
                  const SizedBox(height: 12),
                  _buildStartDateTile(
                    context: context,
                    isDark: isDark,
                    locale: locale,
                    accentColor: accentColor,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // 5. Card 3: Category + Wallet + Auto Execute + Note
            AppleGlassCard(
              borderRadius: BorderRadius.circular(AppleTokens.radiusHero),
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildSectionHeader(
                    icon: CupertinoIcons.square_grid_2x2_fill,
                    title: isExpense
                        ? l10n.recurringCategoryLabel
                        : l10n.recurringCategoryIncomeLabel,
                    accentColor: accentColor,
                  ),
                  _buildCategorySelector(
                    categories: availableCats,
                    isDark: isDark,
                    accentColor: accentColor,
                  ),
                  const SizedBox(height: 12),
                  _buildSectionHeader(
                    icon: CupertinoIcons.creditcard_fill,
                    title: isExpense
                        ? l10n.recurringWalletLabel
                        : l10n.recurringReceiveWalletLabel,
                    accentColor: accentColor,
                  ),
                  _buildWalletSelector(
                    wallets: wallets,
                    isDark: isDark,
                    locale: locale,
                    accentColor: accentColor,
                  ),
                  const SizedBox(height: 12),
                  Divider(
                    height: AppleTokens.hairline,
                    thickness: AppleTokens.hairline,
                    color: isDark
                        ? AppleTokens.separatorDark
                        : AppleTokens.separatorLight,
                  ),
                  const SizedBox(height: 10),
                  _buildAutoExecuteRow(
                    isDark: isDark,
                    l10n: l10n,
                  ),
                  const SizedBox(height: 12),
                  Divider(
                    height: AppleTokens.hairline,
                    thickness: AppleTokens.hairline,
                    color: isDark
                        ? AppleTokens.separatorDark
                        : AppleTokens.separatorLight,
                  ),
                  const SizedBox(height: 12),
                  AppleTextField(
                    controller: _noteController,
                    label: 'Ghi chú / Mã khách hàng (Tùy chọn)',
                    placeholder: isExpense
                        ? 'VD: Mã thuê bao cáp quang, số hợp đồng...'
                        : 'VD: Lương Techcombank, thưởng quý...',
                    clearable: true,
                    textCapitalization: TextCapitalization.sentences,
                    prefixIcon: Icon(
                      CupertinoIcons.doc_text,
                      size: 18,
                      color: accentColor,
                    ),
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
}
