import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:so_thu_chi/core/l10n/l10n_ext.dart';
import 'package:so_thu_chi/core/theme/app_theme.dart';
import 'package:so_thu_chi/core/theme/apple_theme_tokens.dart';
import 'package:so_thu_chi/core/utils/date_formatter.dart';
import 'package:so_thu_chi/core/utils/money.dart';
import 'package:so_thu_chi/core/widgets/apple_kit.dart';
import 'package:so_thu_chi/features/accounts/domain/entities/account.dart';
import 'package:so_thu_chi/features/accounts/presentation/controllers/accounts_controller.dart';
import 'package:so_thu_chi/features/debts/domain/entities/debt.dart';
import 'package:so_thu_chi/features/debts/presentation/controllers/debts_controller.dart';
import 'package:so_thu_chi/features/settings/presentation/controllers/settings_controller.dart';
import 'package:so_thu_chi/l10n/app_localizations.dart';

/// Redesigned, state-of-the-art Apple HIG Debt & Loan Recording Bottom Sheet.
/// Features interactive Live Debt Preview, Sliding Segmented Type Pill with semantic colors,
/// Quick Contact relationship tags, Quick Amount Presets with triple-zero adder,
/// Quick Due Date shortcuts, and visual Wallet selector.
class DebtFormSheet extends ConsumerStatefulWidget {
  const DebtFormSheet({super.key, this.initialDebt});

  final Debt? initialDebt;

  static Future<void> show(BuildContext context, {Debt? initialDebt}) {
    return AppleModalSheetLayout.show<void>(
      context: context,
      builder: (_) => DebtFormSheet(initialDebt: initialDebt),
    );
  }

  @override
  ConsumerState<DebtFormSheet> createState() => _DebtFormSheetState();
}

class _DebtFormSheetState extends ConsumerState<DebtFormSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();

  late DebtType _selectedType;
  DateTime? _dueDate;
  String? _selectedAccountId;
  bool _isSaving = false;

  bool get _isEditing => widget.initialDebt != null;

  static const _relationshipTags = [
    'Bạn bè',
    'Đồng nghiệp',
    'Người thân',
    'Khách hàng',
    'Hàng xóm',
    'Đối tác',
  ];

  @override
  void initState() {
    super.initState();
    final d = widget.initialDebt;
    _selectedType = d?.type ?? DebtType.lent;
    if (d != null) {
      _nameController.text = d.personName;
      _phoneController.text = d.phoneNumber ?? '';
      _amountController.text = d.amount.toString();
      _noteController.text = d.note;
      _dueDate = d.dueDate;
      _selectedAccountId = d.accountId;
    }

    _nameController.addListener(_onFieldChanged);
    _phoneController.addListener(_onFieldChanged);
    _amountController.addListener(_onFieldChanged);
    _noteController.addListener(_onFieldChanged);
  }

  @override
  void dispose() {
    _nameController.removeListener(_onFieldChanged);
    _phoneController.removeListener(_onFieldChanged);
    _amountController.removeListener(_onFieldChanged);
    _noteController.removeListener(_onFieldChanged);
    _nameController.dispose();
    _phoneController.dispose();
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  void _onFieldChanged() {
    if (mounted) setState(() {});
  }

  void _addAmount(int delta) {
    unawaited(HapticFeedback.selectionClick());
    final current = int.tryParse(_amountController.text.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
    setState(() {
      _amountController.text = (current + delta).toString();
    });
  }

  void _appendTripleZeros() {
    final current = _amountController.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (current.isEmpty || current == '0') return;
    unawaited(HapticFeedback.selectionClick());
    setState(() {
      _amountController.text = '${current}000';
    });
  }

  void _selectRelationship(String tag) {
    unawaited(HapticFeedback.selectionClick());
    final current = _noteController.text.trim();
    setState(() {
      if (current.isEmpty) {
        _noteController.text = tag;
      } else if (!current.contains(tag)) {
        _noteController.text = '$current • $tag';
      }
    });
  }

  void _setDueDatePreset(Duration offset) {
    unawaited(HapticFeedback.selectionClick());
    setState(() {
      _dueDate = DateTime.now().add(offset);
    });
  }

  void _setDueEndOfMonth() {
    unawaited(HapticFeedback.selectionClick());
    final now = DateTime.now();
    final lastDay = DateTime(now.year, now.month + 1, 0);
    setState(() {
      _dueDate = lastDay;
    });
  }

  Future<void> _pickDueDate() async {
    await HapticFeedback.lightImpact();
    if (!mounted) return;
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _dueDate ?? now.add(const Duration(days: 7)),
      firstDate: now.subtract(const Duration(days: 365)),
      lastDate: now.add(const Duration(days: 365 * 5)),
      locale: const Locale('vi'),
    );
    if (!mounted) return;
    if (picked != null) {
      setState(() => _dueDate = picked);
    }
  }

  Future<void> _save() async {
    final l10n = context.l10n;
    if (!_formKey.currentState!.validate()) return;

    final rawAmount = int.tryParse(_amountController.text.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
    if (rawAmount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.debtAmountRequired)),
      );
      return;
    }

    setState(() => _isSaving = true);
    unawaited(HapticFeedback.mediumImpact());

    final controller = ref.read(debtsActionControllerProvider.notifier);

    if (_isEditing) {
      final updated = widget.initialDebt!.copyWith(
        personName: _nameController.text.trim(),
        phoneNumber: _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim(),
        type: _selectedType,
        amount: rawAmount,
        dueDate: _dueDate,
        accountId: _selectedAccountId,
        note: _noteController.text.trim(),
      );
      final res = await controller.updateDebt(updated);
      if (!mounted) return;
      setState(() => _isSaving = false);
      res.fold(
        onSuccess: (_) {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.debtUpdatedSuccess)),
          );
        },
        onFailure: (err) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(context.localizeError(err)),
              backgroundColor: Theme.of(context).colorScheme.error,
              behavior: SnackBarBehavior.floating,
            ),
          );
        },
      );
    } else {
      final res = await controller.addDebt(
        personName: _nameController.text.trim(),
        phoneNumber: _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim(),
        type: _selectedType,
        amount: rawAmount,
        dueDate: _dueDate,
        accountId: _selectedAccountId,
        note: _noteController.text.trim(),
      );
      if (!mounted) return;
      setState(() => _isSaving = false);
      res.fold(
        onSuccess: (_) {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.debtAddedSuccess)),
          );
        },
        onFailure: (err) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(context.localizeError(err)),
              backgroundColor: Theme.of(context).colorScheme.error,
              behavior: SnackBarBehavior.floating,
            ),
          );
        },
      );
    }
  }

  Widget _buildSectionHeader({
    required IconData icon,
    required String title,
    required Color accentColor,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 14, color: accentColor),
          const SizedBox(width: 6),
          Text(
            title.toUpperCase(),
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
              color: accentColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLivePreviewCard({
    required BuildContext context,
    required ThemeData theme,
    required bool isDark,
    required String currency,
    required String locale,
    required AppLocalizations l10n,
    required Account? selectedWallet,
  }) {
    final isLent = _selectedType == DebtType.lent;
    final accentColor = isLent ? AppleTokens.emeraldIncome : AppleTokens.systemOrange;

    final personName = _nameController.text.trim();
    final displayName = personName.isNotEmpty
        ? personName
        : (isLent ? 'Người vay tiền' : 'Chủ nợ');

    final rawAmount = int.tryParse(_amountController.text.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
    final formattedAmount = Money(minorUnits: rawAmount, currencyCode: currency).format(locale: locale);

    final initialChar = personName.isNotEmpty ? personName[0].toUpperCase() : null;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [
                  accentColor.withValues(alpha: 0.22),
                  accentColor.withValues(alpha: 0.08),
                  AppleTokens.bgDarkCard,
                ]
              : [
                  accentColor.withValues(alpha: 0.14),
                  accentColor.withValues(alpha: 0.05),
                  Colors.white,
                ],
        ),
        borderRadius: BorderRadius.circular(AppleTokens.radiusCard),
        border: Border.all(
          color: accentColor.withValues(alpha: isDark ? 0.40 : 0.25),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: accentColor.withValues(alpha: isDark ? 0.15 : 0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header Row: Avatar, Name, Type Pill
          Row(
            children: [
              // 44x44 Squircle Avatar Badge
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      accentColor,
                      accentColor.withValues(alpha: 0.75),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(AppleTokens.radiusControl),
                  boxShadow: [
                    BoxShadow(
                      color: accentColor.withValues(alpha: 0.35),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                alignment: Alignment.center,
                child: initialChar != null
                    ? Text(
                        initialChar,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      )
                    : Icon(
                        isLent ? CupertinoIcons.arrow_up_right : CupertinoIcons.arrow_down_left,
                        color: Colors.white,
                        size: 20,
                      ),
              ),
              const SizedBox(width: 12),

              // Name & Contact Status
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      displayName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                        color: personName.isNotEmpty
                            ? (isDark ? Colors.white : Colors.black87)
                            : (isDark ? Colors.white38 : Colors.black38),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _phoneController.text.trim().isNotEmpty
                          ? _phoneController.text.trim()
                          : (isLent ? 'Khoản cho mượn' : 'Khoản đi mượn'),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? Colors.white60 : Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 8),

              // Type Badge Pill
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: isDark ? 0.28 : 0.15),
                  borderRadius: BorderRadius.circular(AppleTokens.radiusPill),
                  border: Border.all(
                    color: accentColor.withValues(alpha: 0.4),
                    width: 0.8,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isLent ? CupertinoIcons.arrow_up_right : CupertinoIcons.arrow_down_left,
                      size: 11,
                      color: accentColor,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      isLent ? l10n.debtTypeLent.toUpperCase() : l10n.debtTypeBorrowed.toUpperCase(),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.4,
                        color: accentColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // Amount Row
          Text(
            l10n.amount.toUpperCase(),
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
              color: isDark ? Colors.white54 : Colors.black45,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            formattedAmount,
            style: theme.textTheme.headlineMedium?.copyWith(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.4,
              fontFeatures: AppTheme.tabularFigures,
              color: rawAmount > 0
                  ? (isDark ? Colors.white : const Color(0xFF1C1C1E))
                  : (isDark ? Colors.white30 : Colors.black26),
            ),
          ),

          const SizedBox(height: 12),

          // Meta Info Pills Row (Due date, Wallet, Note preview)
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              // Due Date Chip
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: (_dueDate != null
                      ? (isDark ? Colors.white.withValues(alpha: 0.12) : Colors.black.withValues(alpha: 0.06))
                      : (isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.03))),
                  borderRadius: BorderRadius.circular(AppleTokens.radiusPill),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      CupertinoIcons.calendar,
                      size: 12,
                      color: _dueDate != null ? accentColor : (isDark ? Colors.white54 : Colors.black45),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _dueDate != null
                          ? 'Hạn: ${AppDateUtils.formatVnDate(_dueDate!)}'
                          : 'Chưa hẹn ngày',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: _dueDate != null
                            ? (isDark ? Colors.white : Colors.black87)
                            : (isDark ? Colors.white54 : Colors.black45),
                      ),
                    ),
                  ],
                ),
              ),

              // Wallet Chip
              if (selectedWallet != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Color(selectedWallet.color).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(AppleTokens.radiusPill),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        CupertinoIcons.creditcard_fill,
                        size: 12,
                        color: Color(selectedWallet.color),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        selectedWallet.name,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Color(selectedWallet.color),
                        ),
                      ),
                    ],
                  ),
                ),

              // Note snippet
              if (_noteController.text.trim().isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.04),
                    borderRadius: BorderRadius.circular(AppleTokens.radiusPill),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        CupertinoIcons.doc_text,
                        size: 11,
                        color: isDark ? Colors.white54 : Colors.black45,
                      ),
                      const SizedBox(width: 4),
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 160),
                        child: Text(
                          _noteController.text.trim(),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 11,
                            color: isDark ? Colors.white70 : Colors.black87,
                          ),
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final l10n = context.l10n;
    final activeAccounts = ref.watch(activeAccountsProvider);
    final currency = widget.initialDebt?.currency ?? (ref.watch(settingsControllerProvider).value?.currencyCode ?? 'VND');
    final locale = ref.watch(settingsControllerProvider).value?.localeCode ?? 'vi';

    final isLent = _selectedType == DebtType.lent;
    final accentColor = isLent ? AppleTokens.emeraldIncome : AppleTokens.systemOrange;

    Account? selectedWallet;
    if (_selectedAccountId != null) {
      try {
        selectedWallet = activeAccounts.firstWhere((w) => w.id == _selectedAccountId);
      } catch (_) {}
    }

    return AppleModalSheetLayout(
      title: _isEditing ? l10n.debtEditTitle : l10n.debtNewTitle,
      subtitle: _isEditing
          ? 'Cập nhật số tiền, kỳ hạn và đối tác ghi nợ'
          : (isLent
              ? 'Ghi nhận số tiền bạn đã cho người khác vay'
              : 'Ghi nhận số tiền bạn đã mượn từ người khác'),
      bottomAction: AppleButton.primary(
        label: _isEditing ? l10n.save : l10n.debtSubmitNew,
        color: accentColor,
        isLoading: _isSaving,
        onPressed: _isSaving ? null : _save,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. Live Interactive Debt Preview Card
            _buildLivePreviewCard(
              context: context,
              theme: theme,
              isDark: isDark,
              currency: currency,
              locale: locale,
              l10n: l10n,
              selectedWallet: selectedWallet,
            ),
            const SizedBox(height: 16),

            // 2. Segmented Type Tab: Cho vay vs Đi vay
            LucianSlidingPillTabs<DebtType>(
              items: [
                LucianTabItem(
                  value: DebtType.lent,
                  label: l10n.debtTypeLent,
                  icon: CupertinoIcons.arrow_up_right,
                  activeColor: AppleTokens.emeraldIncome,
                ),
                LucianTabItem(
                  value: DebtType.borrowed,
                  label: l10n.debtTypeBorrowed,
                  icon: CupertinoIcons.arrow_down_left,
                  activeColor: AppleTokens.systemOrange,
                ),
              ],
              selected: _selectedType,
              onChanged: (type) {
                unawaited(HapticFeedback.selectionClick());
                setState(() => _selectedType = type);
              },
            ),
            const SizedBox(height: 18),

            // 3. Person & Contact Information Section
            _buildSectionHeader(
              icon: CupertinoIcons.person_2_fill,
              title: isLent ? 'Người vay tiền' : 'Chủ nợ',
              accentColor: accentColor,
            ),

            // Person Name
            AppleTextField(
              controller: _nameController,
              label: isLent ? l10n.debtPersonLentLabel : l10n.debtPersonBorrowedLabel,
              placeholder: l10n.debtPersonNameHint,
              textCapitalization: TextCapitalization.words,
              clearable: true,
              prefixIcon: Icon(
                CupertinoIcons.person_fill,
                size: 18,
                color: accentColor,
              ),
              validator: (val) {
                if (val == null || val.trim().isEmpty) {
                  return l10n.debtPersonRequired;
                }
                return null;
              },
            ),
            const SizedBox(height: 8),

            // Quick relationship tags
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: Row(
                children: [
                  for (final tag in _relationshipTags)
                    Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: ApplePressable(
                        onTap: () => _selectRelationship(tag),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.06)
                                : Colors.black.withValues(alpha: 0.04),
                            borderRadius: BorderRadius.circular(AppleTokens.radiusPill),
                            border: Border.all(
                              color: isDark
                                  ? AppleTokens.separatorDark
                                  : AppleTokens.separatorLight,
                              width: AppleTokens.hairline,
                            ),
                          ),
                          child: Text(
                            tag,
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                              color: isDark ? Colors.white70 : Colors.black87,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Phone number
            AppleTextField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              label: l10n.debtPhoneNumber,
              placeholder: 'VD: 0912 345 678 (Tùy chọn)',
              clearable: true,
              prefixIcon: Icon(
                CupertinoIcons.phone_fill,
                size: 18,
                color: accentColor,
              ),
            ),
            const SizedBox(height: 18),

            // 4. Amount Section
            _buildSectionHeader(
              icon: CupertinoIcons.money_dollar_circle_fill,
              title: 'Số tiền ghi nợ',
              accentColor: accentColor,
            ),

            // Amount Input Field
            AppleTextField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              label: l10n.debtAmountLabel(currency),
              placeholder: '0',
              clearable: true,
              prefixIcon: Icon(
                CupertinoIcons.money_dollar,
                size: 18,
                color: accentColor,
              ),
              validator: (val) {
                if (val == null || val.trim().isEmpty) return l10n.debtAmountRequired;
                final num = int.tryParse(val.replaceAll(RegExp(r'[^0-9]'), ''));
                if (num == null || num <= 0) return l10n.debtAmountRequired;
                return null;
              },
            ),
            const SizedBox(height: 8),

            // Quick Amount Pills (+ Presets and +000 adder)
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: Row(
                children: [
                  for (final delta in [100000, 200000, 500000, 1000000, 2000000, 5000000, 10000000])
                    Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: ApplePressable(
                        onTap: () => _addAmount(delta),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: isDark
                                ? AppleTokens.bgDarkSecondary
                                : AppleTokens.bgLightSecondary,
                            borderRadius: BorderRadius.circular(AppleTokens.radiusPill),
                            border: Border.all(
                              color: isDark
                                  ? AppleTokens.separatorDark
                                  : AppleTokens.separatorLight,
                              width: AppleTokens.hairline,
                            ),
                          ),
                          child: Text(
                            '+${delta >= 1000000 ? '${delta ~/ 1000000}tr' : '${delta ~/ 1000}k'}',
                            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
                          ),
                        ),
                      ),
                    ),
                  // Triple-zero (+000) multiplier
                  Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: ApplePressable(
                      onTap: _appendTripleZeros,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: accentColor.withValues(alpha: isDark ? 0.25 : 0.12),
                          borderRadius: BorderRadius.circular(AppleTokens.radiusPill),
                          border: Border.all(
                            color: accentColor.withValues(alpha: 0.35),
                            width: AppleTokens.hairline,
                          ),
                        ),
                        child: Text(
                          '+000',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                            color: accentColor,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),

            // 5. Due Date Section
            _buildSectionHeader(
              icon: CupertinoIcons.calendar,
              title: 'Kỳ hạn thanh toán',
              accentColor: accentColor,
            ),

            // Quick date shortcut pills
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: Row(
                children: [
                  Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: ApplePressable(
                      onTap: () => _setDueDatePreset(const Duration(days: 7)),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4.5),
                        decoration: BoxDecoration(
                          color: isDark ? AppleTokens.bgDarkSecondary : AppleTokens.bgLightSecondary,
                          borderRadius: BorderRadius.circular(AppleTokens.radiusPill),
                          border: Border.all(
                            color: isDark ? AppleTokens.separatorDark : AppleTokens.separatorLight,
                            width: AppleTokens.hairline,
                          ),
                        ),
                        child: const Text('7 ngày', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600)),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: ApplePressable(
                      onTap: () => _setDueDatePreset(const Duration(days: 15)),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4.5),
                        decoration: BoxDecoration(
                          color: isDark ? AppleTokens.bgDarkSecondary : AppleTokens.bgLightSecondary,
                          borderRadius: BorderRadius.circular(AppleTokens.radiusPill),
                          border: Border.all(
                            color: isDark ? AppleTokens.separatorDark : AppleTokens.separatorLight,
                            width: AppleTokens.hairline,
                          ),
                        ),
                        child: const Text('15 ngày', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600)),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: ApplePressable(
                      onTap: _setDueEndOfMonth,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4.5),
                        decoration: BoxDecoration(
                          color: isDark ? AppleTokens.bgDarkSecondary : AppleTokens.bgLightSecondary,
                          borderRadius: BorderRadius.circular(AppleTokens.radiusPill),
                          border: Border.all(
                            color: isDark ? AppleTokens.separatorDark : AppleTokens.separatorLight,
                            width: AppleTokens.hairline,
                          ),
                        ),
                        child: const Text('Cuối tháng này', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600)),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: ApplePressable(
                      onTap: () => _setDueDatePreset(const Duration(days: 30)),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4.5),
                        decoration: BoxDecoration(
                          color: isDark ? AppleTokens.bgDarkSecondary : AppleTokens.bgLightSecondary,
                          borderRadius: BorderRadius.circular(AppleTokens.radiusPill),
                          border: Border.all(
                            color: isDark ? AppleTokens.separatorDark : AppleTokens.separatorLight,
                            width: AppleTokens.hairline,
                          ),
                        ),
                        child: const Text('1 tháng', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),

            // Due Date Picker Card
            ApplePressable(
              onTap: _pickDueDate,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: isDark ? AppleTokens.bgDarkSecondary : AppleTokens.bgLightSecondary,
                  borderRadius: BorderRadius.circular(AppleTokens.radiusControl),
                  border: Border.all(
                    color: _dueDate != null
                        ? accentColor.withValues(alpha: 0.5)
                        : (isDark ? AppleTokens.separatorDark : AppleTokens.separatorLight),
                    width: _dueDate != null ? 1.0 : AppleTokens.hairline,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      CupertinoIcons.calendar,
                      size: 18,
                      color: _dueDate != null ? accentColor : theme.colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _dueDate != null
                                ? l10n.debtDueDate(AppDateUtils.formatVnDate(_dueDate!))
                                : 'Chưa hẹn ngày thanh toán (Tùy chọn)',
                            style: TextStyle(
                              color: _dueDate != null ? theme.colorScheme.onSurface : theme.colorScheme.onSurfaceVariant,
                              fontWeight: _dueDate != null ? FontWeight.w700 : FontWeight.normal,
                              fontSize: 13.5,
                            ),
                          ),
                          if (_dueDate != null) ...[
                            const SizedBox(height: 2),
                            Text(
                              _dueDate!.isAfter(DateTime.now())
                                  ? 'Còn ${_dueDate!.difference(DateTime.now()).inDays + 1} ngày nữa'
                                  : 'Đã đến hoặc quá hạn',
                              style: TextStyle(
                                fontSize: 11.5,
                                color: _dueDate!.isAfter(DateTime.now())
                                    ? AppleTokens.systemGreen
                                    : AppleTokens.rubyExpense,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    if (_dueDate != null)
                      CupertinoButton(
                        padding: EdgeInsets.zero,
                        minimumSize: const Size(28, 28),
                        onPressed: () {
                          unawaited(HapticFeedback.selectionClick());
                          setState(() => _dueDate = null);
                        },
                        child: const Icon(CupertinoIcons.clear_circled_solid, size: 18, color: AppleTokens.systemGray),
                      )
                    else
                      const Icon(CupertinoIcons.chevron_right, size: 14, color: AppleTokens.systemGray),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 18),

            // 6. Linked Wallet Selection
            if (activeAccounts.isNotEmpty) ...[
              _buildSectionHeader(
                icon: CupertinoIcons.creditcard_fill,
                title: '${l10n.walletsTitle} (${l10n.all.toLowerCase()})',
                accentColor: accentColor,
              ),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                child: Row(
                  children: [
                    for (final acc in activeAccounts)
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ApplePressable(
                          onTap: () {
                            unawaited(HapticFeedback.selectionClick());
                            setState(() {
                              _selectedAccountId = _selectedAccountId == acc.id ? null : acc.id;
                            });
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                            decoration: BoxDecoration(
                              color: _selectedAccountId == acc.id
                                  ? accentColor.withValues(alpha: isDark ? 0.22 : 0.12)
                                  : (isDark ? AppleTokens.bgDarkSecondary : AppleTokens.bgLightSecondary),
                              borderRadius: BorderRadius.circular(AppleTokens.radiusControl),
                              border: Border.all(
                                color: _selectedAccountId == acc.id
                                    ? accentColor
                                    : (isDark ? AppleTokens.separatorDark : AppleTokens.separatorLight),
                                width: _selectedAccountId == acc.id ? 1.5 : AppleTokens.hairline,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  _selectedAccountId == acc.id
                                      ? CupertinoIcons.checkmark_circle_fill
                                      : CupertinoIcons.creditcard,
                                  size: 14,
                                  color: _selectedAccountId == acc.id
                                      ? accentColor
                                      : theme.colorScheme.onSurfaceVariant,
                                ),
                                const SizedBox(width: 6),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      acc.name,
                                      style: TextStyle(
                                        fontWeight: _selectedAccountId == acc.id ? FontWeight.w700 : FontWeight.w500,
                                        color: _selectedAccountId == acc.id
                                            ? accentColor
                                            : theme.colorScheme.onSurface,
                                        fontSize: 12.5,
                                      ),
                                    ),
                                    Text(
                                      Money(minorUnits: acc.balance, currencyCode: acc.currency).format(locale: locale),
                                      style: TextStyle(
                                        fontSize: 10.5,
                                        color: isDark ? Colors.white54 : Colors.black45,
                                        fontFeatures: AppTheme.tabularFigures,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
            ],

            // 7. Note Section
            _buildSectionHeader(
              icon: CupertinoIcons.doc_text_fill,
              title: l10n.note,
              accentColor: accentColor,
            ),
            AppleTextField(
              controller: _noteController,
              label: l10n.note,
              placeholder: l10n.noteHint,
              maxLines: 2,
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
}
