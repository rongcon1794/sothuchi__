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
import 'package:so_thu_chi/core/utils/date_formatter.dart';
import 'package:so_thu_chi/core/utils/money.dart';
import 'package:so_thu_chi/core/widgets/apple_kit.dart';
import 'package:so_thu_chi/features/accounts/domain/entities/account.dart';
import 'package:so_thu_chi/features/accounts/presentation/controllers/accounts_controller.dart';
import 'package:so_thu_chi/features/savings/domain/entities/savings_goal.dart';
import 'package:so_thu_chi/features/savings/presentation/controllers/savings_goals_controller.dart';
import 'package:so_thu_chi/features/settings/presentation/controllers/settings_controller.dart';
import 'package:so_thu_chi/l10n/app_localizations.dart';

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

    _amountFocusNode.addListener(_onFocusChange);
    _titleController.addListener(_onFieldChange);
    _targetAmountController.addListener(_onFieldChange);
    _noteController.addListener(_onFieldChange);
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
              // Glowing Icon Badge
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      accentColor.withValues(alpha: isDark ? 0.95 : 0.9),
                      accentColor.withValues(alpha: isDark ? 0.75 : 0.7),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(AppleTokens.radiusCard),
                  boxShadow: [
                    BoxShadow(
                      color: accentColor.withValues(alpha: isDark ? 0.35 : 0.25),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Icon(
                  _resolveIcon(_selectedIcon),
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
                    Row(
                      children: [
                        Text(
                          parsedTarget != null && parsedTarget.minorUnits > 0
                              ? parsedTarget.format(locale: locale)
                              : '0 ${AppCurrencies.byCode(currency).symbol}',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: accentColor,
                            fontFeatures: AppTheme.tabularFigures,
                            letterSpacing: -0.3,
                          ),
                        ),
                        if (_isEditing && currentAmount > 0) ...[
                          const SizedBox(width: 6),
                          Text(
                            '(Đã có ${(previewProgress * 100).round()}%)',
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                              color: isDark ? Colors.white60 : Colors.black54,
                            ),
                          ),
                        ],
                      ],
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
          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: previewProgress,
              minHeight: 5,
              backgroundColor: isDark
                  ? Colors.white.withValues(alpha: 0.1)
                  : Colors.black.withValues(alpha: 0.08),
              valueColor: AlwaysStoppedAnimation<Color>(accentColor),
            ),
          ),
          const SizedBox(height: 8),
          // Metadata Badges
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              // Deadline badge
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
                      _deadline != null
                          ? '${AppDateUtils.formatShortDate(_deadline!, locale: locale)} (${l10n.savingsDaysRemaining(daysRemaining ?? 0)})'
                          : l10n.savingsNoDeadline,
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white70 : Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),
              // Linked wallet badge
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
              // Pace pill
              if (dailyNeeded != null && dailyNeeded > 0)
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
                        CupertinoIcons.bolt_fill,
                        size: 10,
                        color: accentColor,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        l10n.savingsDailyNeeded(
                          Money(minorUnits: dailyNeeded, currencyCode: currency)
                              .format(locale: locale),
                        ),
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                          color: accentColor,
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

  Widget _buildInspirationIdeas({
    required bool isDark,
    required Color accentColor,
  }) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: [
          for (final idea in _inspirationIdeas) ...[
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
        itemCount: _availableColors.length,
        separatorBuilder: (_, _) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final colorVal = _availableColors[index];
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
        itemCount: _availableIcons.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final item = _availableIcons[index];
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
