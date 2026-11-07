import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:so_thu_chi/core/constants/currency_constants.dart';
import 'package:so_thu_chi/core/l10n/l10n_ext.dart';
import 'package:so_thu_chi/core/theme/apple_theme_tokens.dart';
import 'package:so_thu_chi/core/utils/money.dart';
import 'package:so_thu_chi/core/widgets/apple_kit.dart';
import 'package:so_thu_chi/features/accounts/presentation/controllers/accounts_controller.dart';
import 'package:so_thu_chi/features/categories/presentation/controllers/categories_controller.dart';
import 'package:so_thu_chi/features/recurring/domain/entities/recurring_transaction.dart';
import 'package:so_thu_chi/features/recurring/presentation/controllers/recurring_controller.dart';
import 'package:so_thu_chi/features/transactions/domain/entities/transaction_entity.dart';
import 'package:so_thu_chi/l10n/app_localizations.dart';

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

  TransactionType _type = TransactionType.expense;
  RecurringInterval _interval = RecurringInterval.monthly;
  DateTime _startDate = DateTime.now();
  String? _accountId;
  String? _categoryId;
  bool _autoExecute = false;

  bool get _isEditing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final item = widget.existing;
    if (item != null) {
      _titleController.text = item.title;
      _amountController.text = item.money.toInputString();
      _noteController.text = item.note;
      _type = item.type;
      _interval = item.interval;
      _startDate = item.startDate;
      _accountId = item.accountId;
      _categoryId = item.categoryId;
      _autoExecute = item.autoExecute;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ref.read(categoriesActionControllerProvider.notifier).seedDefaultsIfNeeded();
      }
    });
  }

  @override
  void dispose() {
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

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final l10n = context.l10n;

    final wallets = ref.read(activeAccountsProvider);
    final currency = wallets.isNotEmpty ? wallets.first.currency : AppCurrencies.defaultCode;
    final parsed = Money.tryParse(_amountController.text, currencyCode: currency);

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

    final actionNotifier = ref.read(recurringActionControllerProvider.notifier);
    final res = _isEditing
        ? await actionNotifier.updateRecurring(entity)
        : await actionNotifier.createRecurring(entity);

    if (!mounted) return;
    res.fold(
      onSuccess: (_) {
        HapticFeedback.mediumImpact();
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
    final l10n = context.l10n;
    final wallets = ref.watch(activeAccountsProvider);
    final expenseCats = ref.watch(expenseCategoriesProvider);
    final incomeCats = ref.watch(incomeCategoriesProvider);
    final availableCats = _type == TransactionType.income ? incomeCats : expenseCats;

    if (_accountId == null && wallets.isNotEmpty) {
      _accountId = wallets.first.id;
    }
    if (availableCats.isNotEmpty &&
        (_categoryId == null || !availableCats.any((c) => c.id == _categoryId))) {
      _categoryId = availableCats.first.id;
    }

    return AppleModalSheetLayout(
      title: _isEditing ? l10n.recurringEditTitle : l10n.recurringNewTitle,
      bottomAction: AppleButton.primary(
        label: _isEditing ? l10n.recurringConfirmUpdate : l10n.recurringConfirmCreate,
        color: AppleTokens.jadePrimary,
        onPressed: _submit,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Title input
            AppleTextField(
              controller: _titleController,
              label: l10n.recurringTitleLabel,
              prefixIcon: const Icon(CupertinoIcons.tag, size: 18),
              validator: (v) => (v == null || v.trim().isEmpty) ? l10n.recurringTitleRequired : null,
            ),
                      const SizedBox(height: 12),

                      // Amount input
                      AppleTextField(
                        controller: _amountController,
                        keyboardType: TextInputType.number,
                        label: l10n.recurringAmountLabel,
                        prefixIcon: const Icon(CupertinoIcons.money_dollar_circle, size: 18),
                        validator: (v) => (v == null || v.trim().isEmpty) ? l10n.recurringAmountRequired : null,
                      ),
                      const SizedBox(height: 14),

                      // Interval Selector
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<RecurringInterval>(
                              initialValue: _interval,
                              decoration: InputDecoration(
                                labelText: l10n.recurringFrequencyLabel,
                                prefixIcon: const Icon(CupertinoIcons.repeat),
                              ),
                              items: RecurringInterval.values.map((i) {
                                return DropdownMenuItem(
                                  value: i,
                                  child: Text(_intervalLabel(i, l10n)),
                                );
                              }).toList(),
                              onChanged: (val) {
                                if (val != null) setState(() => _interval = val);
                              },
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: DropdownButtonFormField<TransactionType>(
                              initialValue: _type,
                              decoration: InputDecoration(
                                labelText: l10n.type,
                                prefixIcon: const Icon(CupertinoIcons.arrow_right_arrow_left),
                              ),
                              items: [
                                DropdownMenuItem(value: TransactionType.expense, child: Text(l10n.expense)),
                                DropdownMenuItem(value: TransactionType.income, child: Text(l10n.income)),
                              ],
                              onChanged: (val) {
                                if (val != null) setState(() => _type = val);
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // Wallet & Category Selection
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              initialValue: _accountId,
                              decoration: InputDecoration(
                                labelText: l10n.recurringWalletLabel,
                                prefixIcon: const Icon(CupertinoIcons.creditcard),
                              ),
                              items: wallets.map((w) {
                                return DropdownMenuItem(
                                  value: w.id,
                                  child: Text(w.name, overflow: TextOverflow.ellipsis),
                                );
                              }).toList(),
                              onChanged: (val) => setState(() => _accountId = val),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              initialValue: _categoryId,
                              decoration: InputDecoration(
                                labelText: l10n.recurringCategoryLabel,
                                prefixIcon: const Icon(CupertinoIcons.square_grid_2x2),
                              ),
                              items: availableCats.map((c) {
                                return DropdownMenuItem(
                                  value: c.id,
                                  child: Text(c.name, overflow: TextOverflow.ellipsis),
                                );
                              }).toList(),
                              onChanged: (val) => setState(() => _categoryId = val),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // Start Date selector
                      AppleDatePickerTile(
                        label: l10n.recurringStartDateLabel,
                        selectedDate: _startDate,
                        onDateSelected: (d) => setState(() => _startDate = d),
                        iconColor: AppleTokens.systemIndigo,
                      ),
                      const SizedBox(height: 12),

            // Auto execute toggle
            SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              title: Text(l10n.recurringAutoExecute, style: const TextStyle(fontWeight: FontWeight.w600)),
              subtitle: Text(l10n.recurringAutoExecuteSubtitle),
              value: _autoExecute,
              onChanged: (v) => setState(() => _autoExecute = v),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
