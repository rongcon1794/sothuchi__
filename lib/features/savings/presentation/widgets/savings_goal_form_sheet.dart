import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:so_thu_chi/core/constants/currency_constants.dart';
import 'package:so_thu_chi/core/l10n/l10n_ext.dart';
import 'package:so_thu_chi/core/theme/app_theme.dart';
import 'package:so_thu_chi/core/theme/apple_theme_tokens.dart';
import 'package:so_thu_chi/core/utils/money.dart';
import 'package:so_thu_chi/core/widgets/apple_kit.dart';
import 'package:so_thu_chi/features/accounts/domain/entities/account.dart';
import 'package:so_thu_chi/features/accounts/presentation/controllers/accounts_controller.dart';
import 'package:so_thu_chi/features/savings/domain/entities/savings_goal.dart';
import 'package:so_thu_chi/features/savings/presentation/controllers/savings_goals_controller.dart';
import 'package:so_thu_chi/features/settings/presentation/controllers/settings_controller.dart';
import 'package:so_thu_chi/l10n/app_localizations.dart';


part 'savings_goal_form_sections.dart';
class _GoalInspirationIdea {
  const _GoalInspirationIdea({
    required this.title,
    required this.icon,
    required this.color,
    required this.durationDays,
    required this.defaultNote,
  });

  final String title;
  final String icon;
  final int color;
  final int durationDays;
  final String defaultNote;
}

/// Redesigned, state-of-the-art Apple HIG & Lucian Savings Goal Setup Bottom Sheet.
/// Features interactive Live Goal Card Preview, Hero Target Amount input with
/// quick presets and triple-zero adder, Smart Pace Insights Calculator,
/// quick inspiration chips, sleek linked wallet selector, and vivid color/icon pickers.
class SavingsGoalFormSheet extends ConsumerStatefulWidget {
  const SavingsGoalFormSheet({
    super.key,
    this.existing,
  });

  final SavingsGoal? existing;

  static Future<void> show(BuildContext context, {SavingsGoal? existing}) {
    return AppleModalSheetLayout.show<void>(
      context: context,
      builder: (_) => SavingsGoalFormSheet(existing: existing),
    );
  }

  @override
  ConsumerState<SavingsGoalFormSheet> createState() =>
      _SavingsGoalFormSheetState();
}

class _SavingsGoalFormSheetState extends ConsumerState<SavingsGoalFormSheet> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _targetAmountController = TextEditingController();
  final _noteController = TextEditingController();
  final _amountFocusNode = FocusNode();

  DateTime? _deadline;
  String _selectedIcon = 'piggy_bank';
  int _selectedColor = 0xFF00A86B; // Jade Primary
  String? _linkedAccountId;
  bool _isAmountFocused = false;
  bool _isSubmitting = false;

  bool get _isEditing => widget.existing != null;

  static const _availableIcons = [
    ('piggy_bank', CupertinoIcons.cube_box, 'Heo đất'),
    ('shield', CupertinoIcons.shield_fill, 'Khẩn cấp'),
    ('house', CupertinoIcons.house_fill, 'Nhà cửa'),
    ('car', CupertinoIcons.car_detailed, 'Xe cộ'),
    ('airplane', CupertinoIcons.airplane, 'Du lịch'),
    ('laptop', CupertinoIcons.device_laptop, 'Thiết bị'),
    ('gift', CupertinoIcons.gift_fill, 'Quà tặng'),
    ('heart', CupertinoIcons.heart_fill, 'Sức khỏe'),
    ('star', CupertinoIcons.star_fill, 'Mục tiêu'),
    ('bag', CupertinoIcons.bag_fill, 'Mua sắm'),
    ('book', CupertinoIcons.book_fill, 'Học tập'),
    ('music', CupertinoIcons.music_note_2, 'Giải trí'),
  ];

  static const _availableColors = [
    0xFF00A86B, // Jade Green
    0xFF007AFF, // iOS Blue
    0xFF5856D6, // Indigo
    0xFFE11D48, // Ruby / Coral
    0xFFFF9500, // System Orange
    0xFFFFB020, // Amber Yellow
    0xFFAF52DE, // Purple
    0xFF30B0C7, // Teal
  ];

  static const _inspirationIdeas = [
    _GoalInspirationIdea(
      title: 'Quỹ khẩn cấp 6 tháng',
      icon: 'shield',
      color: 0xFF00A86B,
      durationDays: 180,
      defaultNote: 'Khoản dự phòng an tâm cho mọi tình huống bất ngờ',
    ),
    _GoalInspirationIdea(
      title: 'Chuyến du lịch mơ ước',
      icon: 'airplane',
      color: 0xFF007AFF,
      durationDays: 90,
      defaultNote: 'Tự thưởng cho bản thân một chuyến đi đáng nhớ',
    ),
    _GoalInspirationIdea(
      title: 'Đổi xe máy mới',
      icon: 'car',
      color: 0xFFE11D48,
      durationDays: 365,
      defaultNote: 'Nâng cấp phương tiện đi lại an toàn & tiện nghi',
    ),
    _GoalInspirationIdea(
      title: 'Laptop / Thiết bị công nghệ',
      icon: 'laptop',
      color: 0xFF5856D6,
      durationDays: 90,
      defaultNote: 'Công cụ làm việc và học tập đắc lực',
    ),
    _GoalInspirationIdea(
      title: 'Tích lũy mua nhà',
      icon: 'house',
      color: 0xFFFFB020,
      durationDays: 730,
      defaultNote: 'Mục tiêu lớn cho tổ ấm gia đình tương lai',
    ),
    _GoalInspirationIdea(
      title: 'Khóa học & Nâng cao kỹ năng',
      icon: 'book',
      color: 0xFF30B0C7,
      durationDays: 60,
      defaultNote: 'Đầu tư phát triển bản thân cho sự nghiệp',
    ),
    _GoalInspirationIdea(
      title: 'Quà tặng sinh nhật / kỷ niệm',
      icon: 'gift',
      color: 0xFFAF52DE,
      durationDays: 30,
      defaultNote: 'Món quà ý nghĩa cho người thân yêu',
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
      _targetAmountController.text = item.targetMoney.toInputString(locale: locale);
      _noteController.text = item.note;
      _deadline = item.deadline;
      _selectedIcon = item.icon;
      _selectedColor = item.color;
      _linkedAccountId = item.linkedAccountId;
    }

    _lastFieldsSnapshot = _computeFieldsSnapshot();
    _amountFocusNode.addListener(_onFocusChange);
    _titleController.addListener(_onFieldChange);
    _targetAmountController.addListener(_onFieldChange);
    _noteController.addListener(_onFieldChange);
  }

  String _lastFieldsSnapshot = '';

  String _computeFieldsSnapshot() =>
      '${_titleController.text}|${_targetAmountController.text}|${_noteController.text}';

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
    _targetAmountController.removeListener(_onFieldChange);
    _noteController.removeListener(_onFieldChange);

    _amountFocusNode.dispose();
    _titleController.dispose();
    _targetAmountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  IconData _resolveIcon(String key) {
    switch (key) {
      case 'house':
        return CupertinoIcons.house_fill;
      case 'car':
        return CupertinoIcons.car_detailed;
      case 'airplane':
        return CupertinoIcons.airplane;
      case 'shield':
        return CupertinoIcons.shield_fill;
      case 'laptop':
        return CupertinoIcons.device_laptop;
      case 'gift':
        return CupertinoIcons.gift_fill;
      case 'heart':
        return CupertinoIcons.heart_fill;
      case 'star':
        return CupertinoIcons.star_fill;
      case 'bag':
        return CupertinoIcons.bag_fill;
      case 'book':
        return CupertinoIcons.book_fill;
      case 'music':
        return CupertinoIcons.music_note_2;
      case 'piggy_bank':
      default:
        return CupertinoIcons.cube_box;
    }
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
        (minorUnits: 1000000, label: '1 triệu'),
        (minorUnits: 2000000, label: '2 triệu'),
        (minorUnits: 5000000, label: '5 triệu'),
        (minorUnits: 10000000, label: '10 triệu'),
        (minorUnits: 20000000, label: '20 triệu'),
        (minorUnits: 50000000, label: '50 triệu'),
      ];
    }
    final info = AppCurrencies.byCode(currencyCode);
    final factor = info.minorUnitFactor;
    return [
      (minorUnits: 100 * factor, label: '${info.symbol}100'),
      (minorUnits: 250 * factor, label: '${info.symbol}250'),
      (minorUnits: 500 * factor, label: '${info.symbol}500'),
      (minorUnits: 1000 * factor, label: '${info.symbol}1k'),
      (minorUnits: 2000 * factor, label: '${info.symbol}2k'),
      (minorUnits: 5000 * factor, label: '${info.symbol}5k'),
    ];
  }

  void _setPresetAmount(int minorUnits, String currencyCode, String locale) {
    unawaited(HapticFeedback.selectionClick());
    final str = Money(minorUnits: minorUnits, currencyCode: currencyCode)
        .toInputString(locale: locale);
    setState(() {
      _targetAmountController.text = str;
      _targetAmountController.selection =
          TextSelection.collapsed(offset: str.length);
    });
  }

  void _appendTripleZeros(String currencyCode, String locale) {
    final current =
        _targetAmountController.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (current.isEmpty || current == '0') return;
    unawaited(HapticFeedback.selectionClick());
    final newRaw = '${current}000';
    final parsed = int.tryParse(newRaw);
    if (parsed == null) return;
    final formatted = Money(minorUnits: parsed, currencyCode: currencyCode)
        .toInputString(locale: locale);
    setState(() {
      _targetAmountController.text = formatted;
      _targetAmountController.selection =
          TextSelection.collapsed(offset: formatted.length);
    });
  }

  void _applyInspirationIdea(_GoalInspirationIdea idea) {
    unawaited(HapticFeedback.selectionClick());
    final now = DateTime.now();
    setState(() {
      _titleController.text = idea.title;
      _selectedIcon = idea.icon;
      _selectedColor = idea.color;
      _deadline =
          DateTime(now.year, now.month, now.day).add(Duration(days: idea.durationDays));
      if (_noteController.text.trim().isEmpty) {
        _noteController.text = idea.defaultNote;
      }
    });
  }

  void _setQuickDeadline(int days) {
    unawaited(HapticFeedback.selectionClick());
    final now = DateTime.now();
    setState(() {
      _deadline =
          DateTime(now.year, now.month, now.day).add(Duration(days: days));
    });
  }

  Future<void> _pickDeadline() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _deadline ?? now.add(const Duration(days: 90)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 365 * 10)),
    );
    if (picked != null && mounted) {
      unawaited(HapticFeedback.selectionClick());
      setState(() => _deadline = picked);
    }
  }

  int? _calculateDaysRemaining() {
    if (_deadline == null) return null;
    final now = DateTime.now();
    final dDate = DateTime(_deadline!.year, _deadline!.month, _deadline!.day);
    final nDate = DateTime(now.year, now.month, now.day);
    final diff = dDate.difference(nDate).inDays;
    return diff < 0 ? 0 : diff;
  }

  int? _calculateDailySavingsNeeded(String currency) {
    final days = _calculateDaysRemaining();
    final parsed = Money.tryParse(_targetAmountController.text, currencyCode: currency);
    final target = parsed?.minorUnits ?? 0;
    final current = widget.existing?.currentAmount ?? 0;
    final remaining = target > current ? target - current : 0;
    if (days == null || days <= 0 || remaining <= 0) return null;
    return (remaining / days).ceil();
  }

  int? _calculateMonthlySavingsNeeded(String currency) {
    final days = _calculateDaysRemaining();
    final parsed = Money.tryParse(_targetAmountController.text, currencyCode: currency);
    final target = parsed?.minorUnits ?? 0;
    final current = widget.existing?.currentAmount ?? 0;
    final remaining = target > current ? target - current : 0;
    if (days == null || days <= 0 || remaining <= 0) return null;
    final months = days / 30.0;
    if (months <= 1.0) return remaining;
    return (remaining / months).ceil();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final l10n = context.l10n;

    final wallets = ref.read(activeAccountsProvider);
    final currency = wallets.isNotEmpty
        ? wallets.first.currency
        : AppCurrencies.defaultCode;
    final parsedTarget =
        Money.tryParse(_targetAmountController.text, currencyCode: currency);

    if (parsedTarget == null || parsedTarget.minorUnits <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.savingsAmountRequired)),
      );
      return;
    }

    final entity = SavingsGoal(
      id: widget.existing?.id ?? '',
      title: _titleController.text.trim(),
      targetAmount: parsedTarget.minorUnits,
      currentAmount: widget.existing?.currentAmount ?? 0,
      currency: currency,
      deadline: _deadline,
      icon: _selectedIcon,
      color: _selectedColor,
      isCompleted: widget.existing?.isCompleted ?? false,
      linkedAccountId: _linkedAccountId,
      note: _noteController.text.trim(),
      createdAt: widget.existing?.createdAt ?? DateTime.now(),
      updatedAt: DateTime.now(),
    );

    setState(() => _isSubmitting = true);
    unawaited(HapticFeedback.mediumImpact());
    final actionNotifier =
        ref.read(savingsGoalsActionControllerProvider.notifier);
    final res = _isEditing
        ? await actionNotifier.updateGoal(entity)
        : await actionNotifier.createGoal(entity);

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
    final settings = ref.watch(settingsControllerProvider).value;
    final locale = settings?.localeCode ?? 'vi';
    final currency = wallets.isNotEmpty
        ? wallets.first.currency
        : (settings?.currencyCode ?? AppCurrencies.defaultCode);

    final accentColor = Color(_selectedColor);
    final parsedTarget =
        Money.tryParse(_targetAmountController.text, currencyCode: currency);
    final currentAmount = widget.existing?.currentAmount ?? 0;
    final targetAmount = parsedTarget?.minorUnits ?? 0;
    final previewProgress = targetAmount > 0
        ? (currentAmount / targetAmount).clamp(0.0, 1.0)
        : 0.0;

    final daysRemaining = _calculateDaysRemaining();
    final dailyNeeded = _calculateDailySavingsNeeded(currency);
    final monthlyNeeded = _calculateMonthlySavingsNeeded(currency);

    Account? selectedWallet;
    if (_linkedAccountId != null) {
      try {
        selectedWallet =
            wallets.firstWhere((w) => w.id == _linkedAccountId);
      } catch (_) {}
    }

    return AppleModalSheetLayout(
      title: _isEditing ? l10n.savingsEditGoalTitle : l10n.savingsNewGoalTitle,
      subtitle: _isEditing
          ? 'Cập nhật kế hoạch & nhịp độ tích lũy'
          : 'Thiết lập mục tiêu thông minh & lộ trình tài chính',
      bottomAction: AppleButton.primary(
        color: accentColor,
        isLoading: _isSubmitting,
        label: _isEditing ? l10n.save : l10n.savingsNewGoal,
        onPressed: _isSubmitting ? null : _submit,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            // 1. Interactive Live Goal Card Preview
            _buildLivePreviewCard(
              context: context,
              theme: theme,
              isDark: isDark,
              accentColor: accentColor,
              locale: locale,
              currency: currency,
              l10n: l10n,
              parsedTarget: parsedTarget,
              currentAmount: currentAmount,
              previewProgress: previewProgress,
              daysRemaining: daysRemaining,
              dailyNeeded: dailyNeeded,
              selectedWallet: selectedWallet,
            ),
            const SizedBox(height: 18),

            // 2. Quick Inspiration Ideas (if creating new)
            if (!_isEditing) ...[
              _buildSectionHeader(
                icon: CupertinoIcons.sparkles,
                title: 'Gợi ý mục tiêu thịnh hành',
                accentColor: accentColor,
              ),
              _buildInspirationIdeas(
                isDark: isDark,
                accentColor: accentColor,
              ),
              const SizedBox(height: 16),
            ],

            // 3. Goal Name & Motivation
            _buildSectionHeader(
              icon: CupertinoIcons.flag_fill,
              title: l10n.savingsGoalName,
              accentColor: accentColor,
            ),
            AppleTextField(
              controller: _titleController,
              placeholder: l10n.savingsGoalNameHint,
              clearable: true,
              prefixIcon: Icon(
                CupertinoIcons.flag,
                size: 18,
                color: accentColor,
              ),
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? l10n.savingsTargetRequired
                  : null,
            ),
            const SizedBox(height: 16),

            // 4. Hero Target Amount Card
            _buildHeroAmountCard(
              context: context,
              isDark: isDark,
              currencyCode: currency,
              locale: locale,
              l10n: l10n,
              accentColor: accentColor,
            ),
            const SizedBox(height: 18),

            // 5. Target Deadline & Smart Pace Calculator
            _buildSectionHeader(
              icon: CupertinoIcons.calendar,
              title: l10n.savingsDeadline,
              accentColor: accentColor,
              trailing: _deadline != null
                  ? ApplePressable(
                      scaleDown: 0.9,
                      onTap: () {
                        unawaited(HapticFeedback.lightImpact());
                        setState(() => _deadline = null);
                      },
                      child: Text(
                        l10n.clear,
                        style: const TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: AppleTokens.systemGray,
                        ),
                      ),
                    )
                  : null,
            ),
            _buildDeadlineContainer(
              context: context,
              isDark: isDark,
              locale: locale,
              currency: currency,
              l10n: l10n,
              accentColor: accentColor,
              daysRemaining: daysRemaining,
              dailyNeeded: dailyNeeded,
              monthlyNeeded: monthlyNeeded,
            ),
            const SizedBox(height: 18),

            // 6. Linked Wallet Picker
            _buildSectionHeader(
              icon: CupertinoIcons.creditcard_fill,
              title: l10n.savingsLinkedWallet,
              subtitle: 'Tiền tích lũy sẽ được trừ trực tiếp từ ví này',
              accentColor: accentColor,
            ),
            _buildLinkedWalletSelector(
              wallets: wallets,
              isDark: isDark,
              locale: locale,
              l10n: l10n,
              accentColor: accentColor,
            ),
            const SizedBox(height: 18),

            // 7. Icon & Color Customization
            _buildSectionHeader(
              icon: CupertinoIcons.paintbrush_fill,
              title: 'Màu sắc & Biểu tượng nhận diện',
              accentColor: accentColor,
            ),
            _buildColorSelector(isDark: isDark),
            const SizedBox(height: 10),
            _buildIconSelector(
              isDark: isDark,
              accentColor: accentColor,
            ),
            const SizedBox(height: 18),

            // 8. Motivation Note
            _buildSectionHeader(
              icon: CupertinoIcons.quote_bubble_fill,
              title: l10n.savingsMotivationNote,
              accentColor: accentColor,
            ),
            AppleTextField(
              controller: _noteController,
              placeholder: 'VD: Kiên trì mỗi ngày vì tự do tài chính...',
              clearable: true,
              prefixIcon: Icon(
                CupertinoIcons.quote_bubble,
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
}
