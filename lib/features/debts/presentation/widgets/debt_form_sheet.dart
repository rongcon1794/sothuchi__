import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:so_thu_chi/core/l10n/l10n_ext.dart';
import 'package:so_thu_chi/core/theme/apple_theme_tokens.dart';
import 'package:so_thu_chi/core/utils/date_formatter.dart';
import 'package:so_thu_chi/core/widgets/apple_kit.dart';
import 'package:so_thu_chi/features/accounts/presentation/controllers/accounts_controller.dart';
import 'package:so_thu_chi/features/debts/domain/entities/debt.dart';
import 'package:so_thu_chi/features/debts/presentation/controllers/debts_controller.dart';
import 'package:so_thu_chi/features/settings/presentation/controllers/settings_controller.dart';

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
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  void _addAmount(int delta) {
    HapticFeedback.selectionClick();
    final current = int.tryParse(_amountController.text.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
    setState(() {
      _amountController.text = (current + delta).toString();
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
    await HapticFeedback.mediumImpact();

    final controller = ref.read(debtsActionControllerProvider.notifier);
    final isEditing = widget.initialDebt != null;

    if (isEditing) {
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final l10n = context.l10n;
    final activeAccounts = ref.watch(activeAccountsProvider);
    final isEditing = widget.initialDebt != null;
    final currency = widget.initialDebt?.currency ?? (ref.watch(settingsControllerProvider).value?.currencyCode ?? 'VND');

    final isLent = _selectedType == DebtType.lent;

    return AppleModalSheetLayout(
      title: isEditing ? l10n.debtEditTitle : l10n.debtNewTitle,
      bottomAction: AppleButton.primary(
        label: isEditing ? l10n.save : l10n.debtSubmitNew,
        color: isLent ? AppleTokens.systemGreen : AppleTokens.systemOrange,
        isLoading: _isSaving,
        onPressed: _save,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Segmented Type: Cho vay vs Đi vay
            LucianSlidingPillTabs<DebtType>(
                items: [
                  LucianTabItem(
                    value: DebtType.lent,
                    label: l10n.debtTypeLent,
                    icon: CupertinoIcons.arrow_up_right,
                    activeColor: AppleTokens.systemGreen,
                  ),
                  LucianTabItem(
                    value: DebtType.borrowed,
                    label: l10n.debtTypeBorrowed,
                    icon: CupertinoIcons.arrow_down_left,
                    activeColor: AppleTokens.systemOrange,
                  ),
                ],
                selected: _selectedType,
                onChanged: (type) => setState(() => _selectedType = type),
              ),
              const SizedBox(height: 16),

              // Person Name
              AppleTextField(
                controller: _nameController,
                label: isLent ? l10n.debtPersonLentLabel : l10n.debtPersonBorrowedLabel,
                placeholder: l10n.debtPersonNameHint,
                prefixIcon: const Icon(CupertinoIcons.person_fill, size: 18),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return l10n.debtPersonRequired;
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),

              // Phone number
              AppleTextField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                label: l10n.debtPhoneNumber,
                prefixIcon: const Icon(CupertinoIcons.phone_fill, size: 18),
              ),
              const SizedBox(height: 12),

              // Amount
              AppleTextField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                label: l10n.debtAmountLabel(currency),
                prefixIcon: const Icon(CupertinoIcons.money_dollar, size: 18),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) return l10n.debtAmountRequired;
                  final num = int.tryParse(val.replaceAll(RegExp(r'[^0-9]'), ''));
                  if (num == null || num <= 0) return l10n.debtAmountRequired;
                  return null;
                },
              ),
              const SizedBox(height: 8),

              // Quick Amount Pills
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    for (final delta in [100000, 200000, 500000, 1000000, 2000000, 5000000])
                      Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: ApplePressable(
                          onTap: () => _addAmount(delta),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? AppleTokens.bgDarkPrimary
                                  : AppleTokens.bgLightSecondary.withValues(alpha: 0.9),
                              borderRadius: BorderRadius.circular(AppleTokens.radiusPill),
                              border: Border.all(
                                color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.2),
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
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // Due Date Selector
              ApplePressable(
                onTap: _pickDueDate,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: isDark ? AppleTokens.bgDarkPrimary : AppleTokens.bgLightSecondary,
                    borderRadius: BorderRadius.circular(AppleTokens.radiusControl),
                  ),
                  child: Row(
                    children: [
                      const Icon(CupertinoIcons.calendar, size: 18),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _dueDate != null
                              ? l10n.debtDueDate(AppDateUtils.formatVnDate(_dueDate!))
                              : l10n.savingsDeadline,
                          style: TextStyle(
                            color: _dueDate != null ? theme.colorScheme.onSurface : theme.colorScheme.onSurfaceVariant,
                            fontWeight: _dueDate != null ? FontWeight.w600 : FontWeight.normal,
                          ),
                        ),
                      ),
                      if (_dueDate != null)
                        IconButton(
                          icon: const Icon(CupertinoIcons.clear_circled, size: 16),
                          onPressed: () => setState(() => _dueDate = null),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // Wallet selection (optional)
              if (activeAccounts.isNotEmpty) ...[
                Text(
                  '${l10n.walletsTitle} (${l10n.all.toLowerCase()}):',
                  style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      for (final acc in activeAccounts)
                        Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ApplePressable(
                            onTap: () {
                              HapticFeedback.selectionClick();
                              setState(() {
                                _selectedAccountId = _selectedAccountId == acc.id ? null : acc.id;
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: _selectedAccountId == acc.id
                                    ? AppleTokens.jadePrimary.withValues(alpha: 0.18)
                                    : (isDark ? AppleTokens.bgDarkPrimary : AppleTokens.bgLightSecondary),
                                borderRadius: BorderRadius.circular(AppleTokens.radiusControl),
                                border: Border.all(
                                  color: _selectedAccountId == acc.id
                                      ? AppleTokens.jadePrimary
                                      : Colors.transparent,
                                  width: 1.5,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    CupertinoIcons.creditcard,
                                    size: 14,
                                    color: _selectedAccountId == acc.id
                                        ? AppleTokens.jadePrimary
                                        : theme.colorScheme.onSurfaceVariant,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    acc.name,
                                    style: TextStyle(
                                      fontWeight: _selectedAccountId == acc.id ? FontWeight.w700 : FontWeight.w500,
                                      color: _selectedAccountId == acc.id
                                          ? AppleTokens.jadePrimary
                                          : theme.colorScheme.onSurface,
                                      fontSize: 12.5,
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
                const SizedBox(height: 14),
              ],

              // Note
              AppleTextField(
                controller: _noteController,
                label: l10n.note,
                placeholder: l10n.noteHint,
                prefixIcon: const Icon(CupertinoIcons.doc_text, size: 18),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      );
    }
  }
