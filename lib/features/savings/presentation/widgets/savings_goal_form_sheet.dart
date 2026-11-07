import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:so_thu_chi/core/constants/currency_constants.dart';
import 'package:so_thu_chi/core/l10n/l10n_ext.dart';
import 'package:so_thu_chi/core/theme/apple_theme_tokens.dart';
import 'package:so_thu_chi/core/utils/money.dart';
import 'package:so_thu_chi/core/widgets/apple_kit.dart';
import 'package:so_thu_chi/features/accounts/presentation/controllers/accounts_controller.dart';
import 'package:so_thu_chi/features/savings/domain/entities/savings_goal.dart';
import 'package:so_thu_chi/features/savings/presentation/controllers/savings_goals_controller.dart';

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
  ConsumerState<SavingsGoalFormSheet> createState() => _SavingsGoalFormSheetState();
}

class _SavingsGoalFormSheetState extends ConsumerState<SavingsGoalFormSheet> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _targetAmountController = TextEditingController();
  final _noteController = TextEditingController();

  DateTime? _deadline;
  String _selectedIcon = 'piggy_bank';
  int _selectedColor = 0xFF00A86B; // Jade Primary
  String? _linkedAccountId;

  bool get _isEditing => widget.existing != null;

  static const _availableIcons = [
    ('piggy_bank', CupertinoIcons.cube_box, 'Heo đất'),
    ('house', CupertinoIcons.house, 'Nhà cửa'),
    ('car', CupertinoIcons.car, 'Xe cộ'),
    ('airplane', CupertinoIcons.airplane, 'Du lịch'),
    ('shield', CupertinoIcons.shield_fill, 'Khẩn cấp'),
    ('laptop', CupertinoIcons.device_laptop, 'Thiết bị'),
    ('gift', CupertinoIcons.gift, 'Quà tặng'),
    ('heart', CupertinoIcons.heart_fill, 'Sức khỏe'),
    ('star', CupertinoIcons.star_fill, 'Mục tiêu'),
    ('bag', CupertinoIcons.bag, 'Mua sắm'),
  ];

  static const _availableColors = [
    0xFF00A86B, // Jade Green
    0xFF007AFF, // iOS Blue
    0xFF5856D6, // Indigo
    0xFAF55050, // Ruby / Coral
    0xFFFF9500, // System Orange
    0xFFFFCC00, // Amber Yellow
    0xFFAF52DE, // Purple
    0xFF30B0C7, // Teal
  ];

  @override
  void initState() {
    super.initState();
    final item = widget.existing;
    if (item != null) {
      _titleController.text = item.title;
      _targetAmountController.text = item.targetMoney.toInputString();
      _noteController.text = item.note;
      _deadline = item.deadline;
      _selectedIcon = item.icon;
      _selectedColor = item.color;
      _linkedAccountId = item.linkedAccountId;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _targetAmountController.dispose();
    _noteController.dispose();
    super.dispose();
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
      setState(() => _deadline = picked);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final l10n = context.l10n;

    final wallets = ref.read(activeAccountsProvider);
    final currency = wallets.isNotEmpty ? wallets.first.currency : AppCurrencies.defaultCode;
    final parsedTarget = Money.tryParse(_targetAmountController.text, currencyCode: currency);

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

    unawaited(HapticFeedback.mediumImpact());
    final actionNotifier = ref.read(savingsGoalsActionControllerProvider.notifier);
    final res = _isEditing
        ? await actionNotifier.updateGoal(entity)
        : await actionNotifier.createGoal(entity);

    if (!mounted) return;
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

    return AppleModalSheetLayout(
      title: _isEditing ? l10n.savingsEditGoalTitle : l10n.savingsNewGoalTitle,
      bottomAction: AppleButton.primary(
        color: Color(_selectedColor),
        label: _isEditing ? l10n.save : l10n.savingsNewGoal,
        onPressed: _submit,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Title
            AppleTextField(
              controller: _titleController,
              label: l10n.savingsGoalName,
              placeholder: l10n.savingsGoalNameHint,
              prefixIcon: const Icon(CupertinoIcons.flag, size: 18),
              validator: (v) => (v == null || v.trim().isEmpty) ? l10n.savingsTargetRequired : null,
            ),
            const SizedBox(height: 14),

                      // Target amount
                      AppleTextField(
                        controller: _targetAmountController,
                        keyboardType: TextInputType.number,
                        label: l10n.savingsTargetAmount,
                        prefixIcon: const Icon(CupertinoIcons.money_dollar_circle, size: 18),
                        validator: (v) => (v == null || v.trim().isEmpty) ? l10n.savingsAmountRequired : null,
                      ),
                      const SizedBox(height: 16),

                      // Deadline selector
                      AppleListTile(
                        title: l10n.savingsDeadline,
                        subtitle: _deadline != null
                            ? DateFormat('dd/MM/yyyy').format(_deadline!)
                            : l10n.savingsNoDeadline,
                        leading: const Icon(CupertinoIcons.calendar, color: AppleTokens.systemIndigo),
                        trailing: _deadline != null
                            ? IconButton(
                                icon: const Icon(CupertinoIcons.clear_circled, size: 18, color: AppleTokens.systemGray),
                                onPressed: () => setState(() => _deadline = null),
                              )
                            : const Icon(CupertinoIcons.chevron_forward, size: 16, color: AppleTokens.systemGray),
                        onTap: _pickDeadline,
                      ),
                      const SizedBox(height: 16),

                      // Linked Account
                      DropdownButtonFormField<String>(
                        initialValue: _linkedAccountId,
                        decoration: InputDecoration(
                          labelText: l10n.savingsLinkedWallet,
                          prefixIcon: const Icon(CupertinoIcons.creditcard),
                        ),
                        items: [
                          DropdownMenuItem<String>(
                            value: null,
                            child: Text(l10n.savingsNoLinkedWallet),
                          ),
                          ...wallets.map((w) {
                            return DropdownMenuItem<String>(
                              value: w.id,
                              child: Text(w.name, overflow: TextOverflow.ellipsis),
                            );
                          }),
                        ],
                        onChanged: (val) => setState(() => _linkedAccountId = val),
                      ),
                      const SizedBox(height: 16),

                      // Icon selector
                      Text(l10n.savingsGoalIcon, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppleTokens.systemGray)),
                      const SizedBox(height: 8),
                      SizedBox(
                        height: 52,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: _availableIcons.length,
                          separatorBuilder: (_, _) => const SizedBox(width: 10),
                          itemBuilder: (context, index) {
                            final item = _availableIcons[index];
                            final isSelected = _selectedIcon == item.$1;
                            return GestureDetector(
                              onTap: () {
                                HapticFeedback.selectionClick();
                                setState(() => _selectedIcon = item.$1);
                              },
                              child: Container(
                                width: 50,
                                height: 50,
                                decoration: BoxDecoration(
                                  color: isSelected ? Color(_selectedColor) : (isDark ? AppleTokens.bgDarkSecondary : AppleTokens.bgLightSecondary),
                                  borderRadius: BorderRadius.circular(AppleTokens.radiusControl),
                                  border: isSelected
                                      ? Border.all(color: Colors.white, width: 2)
                                      : null,
                                ),
                                child: Icon(
                                  item.$2,
                                  color: isSelected ? Colors.white : (isDark ? Colors.white70 : Colors.black87),
                                  size: 22,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Color selector
                      Text(l10n.savingsGoalColor, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppleTokens.systemGray)),
                      const SizedBox(height: 8),
                      SizedBox(
                        height: 44,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: _availableColors.length,
                          separatorBuilder: (_, _) => const SizedBox(width: 10),
                          itemBuilder: (context, index) {
                            final colorVal = _availableColors[index];
                            final isSelected = _selectedColor == colorVal;
                            return GestureDetector(
                              onTap: () {
                                HapticFeedback.selectionClick();
                                setState(() => _selectedColor = colorVal);
                              },
                              child: Container(
                                width: 42,
                                height: 42,
                                decoration: BoxDecoration(
                                  color: Color(colorVal),
                                  shape: BoxShape.circle,
                                  border: isSelected
                                      ? Border.all(color: isDark ? Colors.white : Colors.black, width: 3)
                                      : null,
                                ),
                                child: isSelected
                                    ? const Icon(CupertinoIcons.checkmark, color: Colors.white, size: 20)
                                    : null,
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 16),

            // Note
            AppleTextField(
              controller: _noteController,
              label: l10n.savingsMotivationNote,
              prefixIcon: const Icon(CupertinoIcons.quote_bubble, size: 18),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
