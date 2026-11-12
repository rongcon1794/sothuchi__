import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:so_thu_chi/core/constants/icon_catalog.dart';
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

/// Apple HIG Debt & Loan Recording / Editing Bottom Sheet.
///
/// Features a glassmorphic Live Debt Preview matching [DebtsScreen],
/// semantic sliding type pill, grouped [AppleGlassCard] form sections,
/// relationship & quick-amount chips, date presets, and linked wallet picker.
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
  String _lastFieldsSnapshot = '';

  bool get _isEditing => widget.initialDebt != null;

  static const _relationshipTags = [
    'Bạn bè',
    'Đồng nghiệp',
    'Người thân',
    'Khách hàng',
    'Hàng xóm',
    'Đối tác',
  ];

  static const _amountDeltas = [
    100000,
    200000,
    500000,
    1000000,
    2000000,
    5000000,
    10000000,
  ];

  @override
  void initState() {
    super.initState();
    final d = widget.initialDebt;
    _selectedType = d?.type ?? DebtType.lent;
    if (d != null) {
      _nameController.text = d.personName;
      _phoneController.text = d.phoneNumber ?? '';
      _amountController.text = Money.groupInteger(d.amount, separator: '.');
      _noteController.text = d.note;
      _dueDate = d.dueDate;
      _selectedAccountId = d.accountId;
    }

    _lastFieldsSnapshot = _computeFieldsSnapshot();
    _nameController.addListener(_onFieldChanged);
    _phoneController.addListener(_onFieldChanged);
    _amountController.addListener(_onFieldChanged);
    _noteController.addListener(_onFieldChanged);
  }

  String _computeFieldsSnapshot() =>
      '${_nameController.text}|${_phoneController.text}|${_amountController.text}|${_noteController.text}';

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
    final snap = _computeFieldsSnapshot();
    if (snap == _lastFieldsSnapshot) return;
    _lastFieldsSnapshot = snap;
    if (mounted) setState(() {});
  }

  int _parseRawAmount() =>
      int.tryParse(_amountController.text.replaceAll(RegExp(r'[^0-9]'), '')) ??
      0;

  void _setFormattedAmount(int amount) {
    final formatted = Money.groupInteger(amount, separator: '.');
    _amountController.value = TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }

  void _addAmount(int delta) {
    unawaited(HapticFeedback.selectionClick());
    final current = _parseRawAmount();
    setState(() {
      _setFormattedAmount(current + delta);
    });
  }

  void _appendTripleZeros() {
    final current = _amountController.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (current.isEmpty || current == '0') return;
    final next = int.tryParse('${current}000');
    if (next == null) return;
    unawaited(HapticFeedback.selectionClick());
    setState(() {
      _setFormattedAmount(next);
    });
  }

  void _toggleRelationship(String tag) {
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

  static DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  bool _isSameDay(DateTime? a, DateTime b) =>
      a != null && a.year == b.year && a.month == b.month && a.day == b.day;

  void _setDueDate(DateTime target) {
    unawaited(HapticFeedback.selectionClick());
    setState(() => _dueDate = _dateOnly(target));
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
      setState(() => _dueDate = _dateOnly(picked));
    }
  }

  Future<void> _save() async {
    final l10n = context.l10n;
    if (!_formKey.currentState!.validate()) return;

    final rawAmount = _parseRawAmount();
    if (rawAmount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.debtAmountRequired)),
      );
      return;
    }

    setState(() => _isSaving = true);
    unawaited(HapticFeedback.mediumImpact());

    final controller = ref.read(debtsActionControllerProvider.notifier);
    final trimmedName = _nameController.text.trim();
    final trimmedPhone = _phoneController.text.trim();
    final trimmedNote = _noteController.text.trim();

    if (_isEditing) {
      final updated = widget.initialDebt!.copyWith(
        personName: trimmedName,
        phoneNumber: trimmedPhone.isEmpty ? null : trimmedPhone,
        type: _selectedType,
        amount: rawAmount,
        dueDate: _dueDate,
        accountId: _selectedAccountId,
        note: trimmedNote,
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
        onFailure: (err) => _showError(context.localizeError(err)),
      );
    } else {
      final res = await controller.addDebt(
        personName: trimmedName,
        phoneNumber: trimmedPhone.isEmpty ? null : trimmedPhone,
        type: _selectedType,
        amount: rawAmount,
        dueDate: _dueDate,
        accountId: _selectedAccountId,
        note: trimmedNote,
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
        onFailure: (err) => _showError(context.localizeError(err)),
      );
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Theme.of(context).colorScheme.error,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Widget _buildSectionTitle({
    required IconData icon,
    required String title,
    required Color accentColor,
  }) {
    return Row(
      children: [
        Icon(icon, size: 13.5, color: accentColor),
        const SizedBox(width: 6),
        Text(
          title.toUpperCase(),
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
            color: accentColor,
          ),
        ),
      ],
    );
  }

  Widget _buildQuickChip({
    required String label,
    required bool isDark,
    required Color accentColor,
    required VoidCallback onTap,
    bool isSelected = false,
    bool emphasize = false,
  }) {
    final highlighted = isSelected || emphasize;
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: ApplePressable(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: highlighted
                ? accentColor.withValues(alpha: isDark ? 0.24 : 0.12)
                : (isDark
                    ? Colors.white.withValues(alpha: 0.06)
                    : Colors.black.withValues(alpha: 0.04)),
            borderRadius: BorderRadius.circular(AppleTokens.radiusPill),
            border: Border.all(
              color: highlighted
                  ? accentColor.withValues(alpha: 0.45)
                  : (isDark
                      ? AppleTokens.separatorDark
                      : AppleTokens.separatorLight),
              width: highlighted ? 1.0 : AppleTokens.hairline,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: highlighted ? FontWeight.w700 : FontWeight.w600,
              color: highlighted
                  ? accentColor
                  : (isDark ? Colors.white70 : Colors.black87),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLivePreviewCard({
    required ThemeData theme,
    required bool isDark,
    required String currency,
    required String locale,
    required AppLocalizations l10n,
    required Account? selectedWallet,
  }) {
    final isLent = _selectedType == DebtType.lent;
    final accentColor =
        isLent ? AppleTokens.emeraldIncome : AppleTokens.systemOrange;

    final personName = _nameController.text.trim();
    final displayName = personName.isNotEmpty
        ? personName
        : (isLent ? 'Người vay tiền' : 'Chủ nợ');
    final phone = _phoneController.text.trim();
    final note = _noteController.text.trim();

    final rawAmount = _parseRawAmount();
    final formattedAmount = Money(
      minorUnits: rawAmount,
      currencyCode: currency,
    ).format(locale: locale);

    final initialChar =
        personName.isNotEmpty ? personName[0].toUpperCase() : null;

    return AppleGlassCard(
      borderRadius: BorderRadius.circular(AppleTokens.radiusHero),
      padding: const EdgeInsets.all(14),
      borderColor: accentColor.withValues(alpha: isDark ? 0.35 : 0.22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: isDark ? 0.24 : 0.14),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: accentColor.withValues(alpha: 0.3),
                    width: 0.8,
                  ),
                ),
                alignment: Alignment.center,
                child: initialChar != null
                    ? Text(
                        initialChar,
                        style: TextStyle(
                          color: accentColor,
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                        ),
                      )
                    : Icon(
                        isLent
                            ? CupertinoIcons.arrow_up_right
                            : CupertinoIcons.arrow_down_left,
                        color: accentColor,
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
                            displayName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                              fontSize: 15.5,
                              letterSpacing: -0.2,
                              color: personName.isNotEmpty
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
                            isLent
                                ? l10n.debtLent.toUpperCase()
                                : l10n.debtBorrowed.toUpperCase(),
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
                    Text(
                      phone.isNotEmpty
                          ? phone
                          : (isLent ? 'Khoản cho vay' : 'Khoản đi vay'),
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
                          color: rawAmount > 0
                              ? (isDark
                                  ? Colors.white
                                  : const Color(0xFF1C1C1E))
                              : (isDark ? Colors.white30 : Colors.black26),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (_dueDate != null || selectedWallet != null) ...[
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_dueDate != null)
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
                            'Hạn ${AppDateUtils.formatShortDate(_dueDate!, locale: locale)}',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: isDark ? Colors.white70 : Colors.black87,
                            ),
                          ),
                        ],
                      ),
                    if (selectedWallet != null) ...[
                      if (_dueDate != null) const SizedBox(height: 3),
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
          if (note.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              '"$note"',
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

  String _dueStatusText(DateTime dueDate) {
    final today = _dateOnly(DateTime.now());
    final target = _dateOnly(dueDate);
    final diff = target.difference(today).inDays;
    if (diff == 0) return 'Hạn là hôm nay';
    if (diff > 0) return 'Còn $diff ngày nữa';
    return 'Đã quá hạn ${diff.abs()} ngày';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final l10n = context.l10n;
    final activeAccounts = ref.watch(activeAccountsProvider);
    final settings = ref.watch(settingsControllerProvider).value;
    final currency =
        widget.initialDebt?.currency ?? (settings?.currencyCode ?? 'VND');
    final locale = settings?.localeCode ?? 'vi';

    final isLent = _selectedType == DebtType.lent;
    final accentColor =
        isLent ? AppleTokens.emeraldIncome : AppleTokens.systemOrange;

    Account? selectedWallet;
    for (final w in activeAccounts) {
      if (w.id == _selectedAccountId) {
        selectedWallet = w;
        break;
      }
    }

    final now = DateTime.now();
    final preset7d = _dateOnly(now.add(const Duration(days: 7)));
    final preset15d = _dateOnly(now.add(const Duration(days: 15)));
    final presetMonthEnd = DateTime(now.year, now.month + 1, 0);
    final preset30d = _dateOnly(now.add(const Duration(days: 30)));
    final currentNote = _noteController.text.trim();

    return AppleModalSheetLayout(
      title: _isEditing ? l10n.debtEditTitle : l10n.debtNewTitle,
      subtitle: _isEditing
          ? 'Cập nhật thông tin nợ'
          : (isLent ? 'Ghi nhận khoản cho vay' : 'Ghi nhận khoản đi vay'),
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
              theme: theme,
              isDark: isDark,
              currency: currency,
              locale: locale,
              l10n: l10n,
              selectedWallet: selectedWallet,
            ),
            const SizedBox(height: 14),

            // 2. Segmented Type Tab: Cho vay vs Đi vay
            LucianSlidingPillTabs<DebtType>(
              items: [
                LucianTabItem(
                  value: DebtType.lent,
                  label: l10n.debtLent,
                  icon: CupertinoIcons.arrow_up_right,
                  activeColor: AppleTokens.emeraldIncome,
                ),
                LucianTabItem(
                  value: DebtType.borrowed,
                  label: l10n.debtBorrowed,
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
            const SizedBox(height: 14),

            // 3. Partner & Contact Card
            AppleGlassCard(
              borderRadius: BorderRadius.circular(AppleTokens.radiusHero),
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildSectionTitle(
                    icon: CupertinoIcons.person_2_fill,
                    title: isLent ? 'Thông tin người vay' : 'Thông tin chủ nợ',
                    accentColor: accentColor,
                  ),
                  const SizedBox(height: 10),
                  AppleTextField(
                    controller: _nameController,
                    label: isLent
                        ? l10n.debtPersonLentLabel
                        : l10n.debtPersonBorrowedLabel,
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
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    child: Row(
                      children: [
                        for (final tag in _relationshipTags)
                          _buildQuickChip(
                            label: tag,
                            isDark: isDark,
                            accentColor: accentColor,
                            isSelected: currentNote.contains(tag),
                            onTap: () => _toggleRelationship(tag),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  AppleTextField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    label: l10n.debtPhoneNumber,
                    placeholder: 'VD: 0912 345 678',
                    clearable: true,
                    prefixIcon: Icon(
                      CupertinoIcons.phone_fill,
                      size: 18,
                      color: accentColor,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // 4. Amount & Due Date Card
            AppleGlassCard(
              borderRadius: BorderRadius.circular(AppleTokens.radiusHero),
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildSectionTitle(
                    icon: CupertinoIcons.money_dollar_circle_fill,
                    title: 'Số tiền & Kỳ hạn',
                    accentColor: accentColor,
                  ),
                  const SizedBox(height: 10),
                  AppleTextField(
                    controller: _amountController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      MoneyInputFormatter(currencyCode: currency),
                    ],
                    label: l10n.debtAmountLabel(currency),
                    placeholder: '0',
                    clearable: true,
                    prefixIcon: Icon(
                      CupertinoIcons.money_dollar,
                      size: 18,
                      color: accentColor,
                    ),
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) {
                        return l10n.debtAmountRequired;
                      }
                      final num = int.tryParse(
                        val.replaceAll(RegExp(r'[^0-9]'), ''),
                      );
                      if (num == null || num <= 0) {
                        return l10n.debtAmountRequired;
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 8),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    child: Row(
                      children: [
                        for (final delta in _amountDeltas)
                          _buildQuickChip(
                            label:
                                '+${delta >= 1000000 ? '${delta ~/ 1000000}tr' : '${delta ~/ 1000}k'}',
                            isDark: isDark,
                            accentColor: accentColor,
                            onTap: () => _addAmount(delta),
                          ),
                        _buildQuickChip(
                          label: '+000',
                          isDark: isDark,
                          accentColor: accentColor,
                          emphasize: true,
                          onTap: _appendTripleZeros,
                        ),
                      ],
                    ),
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
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    child: Row(
                      children: [
                        _buildQuickChip(
                          label: '7 ngày',
                          isDark: isDark,
                          accentColor: accentColor,
                          isSelected: _isSameDay(_dueDate, preset7d),
                          onTap: () => _setDueDate(preset7d),
                        ),
                        _buildQuickChip(
                          label: '15 ngày',
                          isDark: isDark,
                          accentColor: accentColor,
                          isSelected: _isSameDay(_dueDate, preset15d),
                          onTap: () => _setDueDate(preset15d),
                        ),
                        _buildQuickChip(
                          label: 'Cuối tháng',
                          isDark: isDark,
                          accentColor: accentColor,
                          isSelected: _isSameDay(_dueDate, presetMonthEnd),
                          onTap: () => _setDueDate(presetMonthEnd),
                        ),
                        _buildQuickChip(
                          label: '1 tháng',
                          isDark: isDark,
                          accentColor: accentColor,
                          isSelected: _isSameDay(_dueDate, preset30d),
                          onTap: () => _setDueDate(preset30d),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  ApplePressable(
                    onTap: _pickDueDate,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.05)
                            : Colors.black.withValues(alpha: 0.03),
                        borderRadius:
                            BorderRadius.circular(AppleTokens.radiusControl),
                        border: Border.all(
                          color: _dueDate != null
                              ? accentColor.withValues(alpha: 0.45)
                              : (isDark
                                  ? AppleTokens.separatorDark
                                  : AppleTokens.separatorLight),
                          width:
                              _dueDate != null ? 1.0 : AppleTokens.hairline,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            CupertinoIcons.calendar,
                            size: 17,
                            color: _dueDate != null
                                ? accentColor
                                : theme.colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  _dueDate != null
                                      ? 'Hạn trả: ${AppDateUtils.formatShortDate(_dueDate!, locale: locale)}'
                                      : 'Chưa hẹn hạn trả (Tùy chọn)',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: _dueDate != null
                                        ? theme.colorScheme.onSurface
                                        : theme.colorScheme.onSurfaceVariant,
                                    fontWeight: _dueDate != null
                                        ? FontWeight.w700
                                        : FontWeight.normal,
                                    fontSize: 13,
                                  ),
                                ),
                                if (_dueDate != null) ...[
                                  const SizedBox(height: 2),
                                  Text(
                                    _dueStatusText(_dueDate!),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: _dateOnly(_dueDate!)
                                              .isBefore(_dateOnly(now))
                                          ? AppleTokens.rubyExpense
                                          : AppleTokens.systemGreen,
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
                              minimumSize: const Size(26, 26),
                              onPressed: () {
                                unawaited(HapticFeedback.selectionClick());
                                setState(() => _dueDate = null);
                              },
                              child: const Icon(
                                CupertinoIcons.clear_circled_solid,
                                size: 17,
                                color: AppleTokens.systemGray,
                              ),
                            )
                          else
                            const Icon(
                              CupertinoIcons.chevron_right,
                              size: 13,
                              color: AppleTokens.systemGray,
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // 5. Linked Wallet & Note Card
            AppleGlassCard(
              borderRadius: BorderRadius.circular(AppleTokens.radiusHero),
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (activeAccounts.isNotEmpty) ...[
                    _buildSectionTitle(
                      icon: CupertinoIcons.creditcard_fill,
                      title: 'Ví tiền liên kết',
                      accentColor: accentColor,
                    ),
                    const SizedBox(height: 10),
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
                                    _selectedAccountId =
                                        _selectedAccountId == acc.id
                                            ? null
                                            : acc.id;
                                  });
                                },
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _selectedAccountId == acc.id
                                        ? accentColor.withValues(
                                            alpha: isDark ? 0.22 : 0.12,
                                          )
                                        : (isDark
                                            ? Colors.white
                                                .withValues(alpha: 0.05)
                                            : Colors.black
                                                .withValues(alpha: 0.03)),
                                    borderRadius: BorderRadius.circular(
                                      AppleTokens.radiusControl,
                                    ),
                                    border: Border.all(
                                      color: _selectedAccountId == acc.id
                                          ? accentColor
                                          : (isDark
                                              ? AppleTokens.separatorDark
                                              : AppleTokens.separatorLight),
                                      width: _selectedAccountId == acc.id
                                          ? 1.5
                                          : AppleTokens.hairline,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Container(
                                        width: 26,
                                        height: 26,
                                        decoration: BoxDecoration(
                                          color: Color(acc.color).withValues(
                                            alpha: isDark ? 0.24 : 0.14,
                                          ),
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                        alignment: Alignment.center,
                                        child: Icon(
                                          AppIconCatalog.resolve(acc.icon),
                                          size: 14,
                                          color: AppIconCatalog
                                              .contrastSafeColor(
                                            Color(acc.color),
                                            theme.brightness,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          ConstrainedBox(
                                            constraints: const BoxConstraints(
                                              maxWidth: 120,
                                            ),
                                            child: Text(
                                              acc.name,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: TextStyle(
                                                fontWeight:
                                                    _selectedAccountId == acc.id
                                                        ? FontWeight.w700
                                                        : FontWeight.w600,
                                                color:
                                                    _selectedAccountId == acc.id
                                                        ? accentColor
                                                        : theme.colorScheme
                                                            .onSurface,
                                                fontSize: 12,
                                              ),
                                            ),
                                          ),
                                          Text(
                                            Money(
                                              minorUnits: acc.balance,
                                              currencyCode: acc.currency,
                                            ).format(locale: locale),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              fontSize: 10.5,
                                              color: isDark
                                                  ? Colors.white54
                                                  : Colors.black45,
                                              fontFeatures:
                                                  AppTheme.tabularFigures,
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
                  _buildSectionTitle(
                    icon: CupertinoIcons.doc_text_fill,
                    title: 'Ghi chú',
                    accentColor: accentColor,
                  ),
                  const SizedBox(height: 10),
                  AppleTextField(
                    controller: _noteController,
                    label: l10n.note,
                    placeholder: 'Nhập ghi chú hoặc lý do...',
                    maxLines: 2,
                    clearable: true,
                    prefixIcon: Icon(
                      CupertinoIcons.doc_text,
                      size: 18,
                      color: accentColor,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
          ],
        ),
      ),
    );
  }
}
