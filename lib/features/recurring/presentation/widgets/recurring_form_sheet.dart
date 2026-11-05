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

class RecurringFormSheet extends ConsumerStatefulWidget {
  const RecurringFormSheet({
    super.key,
    this.existing,
  });

  final RecurringTransaction? existing;

  static Future<void> show(BuildContext context, {RecurringTransaction? existing}) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
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

  String _intervalLabel(RecurringInterval interval) {
    switch (interval) {
      case RecurringInterval.daily:
        return 'Hàng ngày';
      case RecurringInterval.weekly:
        return 'Hàng tuần';
      case RecurringInterval.biweekly:
        return '2 tuần một lần';
      case RecurringInterval.monthly:
        return 'Hàng tháng';
      case RecurringInterval.yearly:
        return 'Hàng năm';
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final wallets = ref.read(activeAccountsProvider);
    final currency = wallets.isNotEmpty ? wallets.first.currency : AppCurrencies.defaultCode;
    final parsed = Money.tryParse(_amountController.text, currencyCode: currency);

    if (parsed == null || parsed.minorUnits <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập số tiền hợp lệ')),
      );
      return;
    }

    if (_accountId == null || _accountId!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng chọn ví thanh toán')),
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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
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

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.88,
      ),
      decoration: BoxDecoration(
        color: isDark ? AppleTokens.bgDarkCard : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(AppleTokens.radiusSheet)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Column(
            children: [
              // Drag Handle
              Container(
                margin: const EdgeInsets.symmetric(vertical: 10),
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark ? Colors.white.withValues(alpha: 0.2) : Colors.black.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // Sheet Header
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 16, 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _isEditing ? 'Sửa giao dịch định kỳ' : 'Thêm giao dịch định kỳ',
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    IconButton(
                      icon: const Icon(CupertinoIcons.xmark_circle_fill, color: AppleTokens.systemGray),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),

              Expanded(
                child: Form(
                  key: _formKey,
                  child: ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    children: [
                      // Title input
                      AppleTextField(
                        controller: _titleController,
                        label: 'Tên gói / Khoản chi (VD: Netflix, Tiền phòng, Internet)',
                        prefixIcon: const Icon(CupertinoIcons.tag, size: 18),
                        validator: (v) => (v == null || v.trim().isEmpty) ? 'Vui lòng nhập tên gói' : null,
                      ),
                      const SizedBox(height: 12),

                      // Amount input
                      AppleTextField(
                        controller: _amountController,
                        keyboardType: TextInputType.number,
                        label: 'Số tiền định kỳ',
                        prefixIcon: const Icon(CupertinoIcons.money_dollar_circle, size: 18),
                        validator: (v) => (v == null || v.trim().isEmpty) ? 'Vui lòng nhập số tiền' : null,
                      ),
                      const SizedBox(height: 14),

                      // Interval Selector
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<RecurringInterval>(
                              initialValue: _interval,
                              decoration: const InputDecoration(
                                labelText: 'Chu kỳ lặp lại',
                                prefixIcon: Icon(CupertinoIcons.repeat),
                              ),
                              items: RecurringInterval.values.map((i) {
                                return DropdownMenuItem(
                                  value: i,
                                  child: Text(_intervalLabel(i)),
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
                              decoration: const InputDecoration(
                                labelText: 'Loại',
                                prefixIcon: Icon(CupertinoIcons.arrow_right_arrow_left),
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
                              decoration: const InputDecoration(
                                labelText: 'Ví thanh toán',
                                prefixIcon: Icon(CupertinoIcons.creditcard),
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
                              decoration: const InputDecoration(
                                labelText: 'Danh mục',
                                prefixIcon: Icon(CupertinoIcons.square_grid_2x2),
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
                        label: 'Ngày bắt đầu / Đến hạn kế tiếp',
                        selectedDate: _startDate,
                        onDateSelected: (d) => setState(() => _startDate = d),
                        iconColor: AppleTokens.systemIndigo,
                      ),
                      const SizedBox(height: 12),

                      // Auto execute toggle
                      SwitchListTile.adaptive(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Tự động ghi sổ khi đến hạn', style: TextStyle(fontWeight: FontWeight.w600)),
                        subtitle: const Text('Tự trừ tiền trong ví và tạo giao dịch mà không cần xác nhận thủ công'),
                        value: _autoExecute,
                        onChanged: (v) => setState(() => _autoExecute = v),
                      ),
                      const SizedBox(height: 20),

                      // Submit Button
                      AppleButton.primary(
                        label: _isEditing ? 'Cập nhật định kỳ' : 'Tạo gói định kỳ',
                        color: AppleTokens.jadePrimary,
                        onPressed: _submit,
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
