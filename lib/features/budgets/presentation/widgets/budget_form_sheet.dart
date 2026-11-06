import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:so_thu_chi/core/constants/currency_constants.dart';
import 'package:so_thu_chi/core/l10n/l10n_ext.dart';
import 'package:so_thu_chi/core/utils/money.dart';
import 'package:so_thu_chi/core/widgets/apple_kit.dart';
import 'package:so_thu_chi/features/budgets/domain/entities/budget.dart';
import 'package:so_thu_chi/features/budgets/presentation/controllers/budgets_controller.dart';
import 'package:so_thu_chi/features/categories/presentation/controllers/categories_controller.dart';
import 'package:so_thu_chi/features/settings/presentation/controllers/settings_controller.dart';

class BudgetFormBottomSheet extends ConsumerStatefulWidget {
  const BudgetFormBottomSheet({
    super.key,
    required this.monthStart,
    this.existing,
  });

  final DateTime monthStart;
  final Budget? existing;

  static Future<void> show(
    BuildContext context, {
    required DateTime monthStart,
    Budget? existing,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (_) => BudgetFormBottomSheet(
        monthStart: monthStart,
        existing: existing,
      ),
    );
  }

  @override
  ConsumerState<BudgetFormBottomSheet> createState() =>
      _BudgetFormBottomSheetState();
}

class _BudgetFormBottomSheetState
    extends ConsumerState<BudgetFormBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  String? _selectedCategoryId; // null => Overall Monthly Budget
  int _threshold = 80;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    if (existing != null) {
      final locale =
          ref.read(settingsControllerProvider).value?.localeCode ?? 'vi';
      _selectedCategoryId = existing.categoryId;
      _threshold = existing.alertThreshold;
      _amountController.text = existing.limitMoney.toInputString(
        locale: locale,
      );
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final settings = ref.read(settingsControllerProvider).value;
    final currency =
        widget.existing?.currency ??
        settings?.currencyCode ??
        AppCurrencies.defaultCode;
    final parsed = Money.tryParse(
      _amountController.text,
      currencyCode: currency,
    );
    if (parsed == null || parsed.minorUnits <= 0) return;

    final messenger = ScaffoldMessenger.of(context);
    final res = await ref
        .read(budgetsActionControllerProvider.notifier)
        .upsertBudget(
          existingId: widget.existing?.id,
          categoryId: _selectedCategoryId,
          amount: parsed.minorUnits,
          currency: currency,
          monthStart: widget.monthStart,
          alertThreshold: _threshold,
        );

    if (!mounted) return;
    res.fold(
      onSuccess: (_) => Navigator.of(context).pop(),
      onFailure: (err) {
        messenger.showSnackBar(
          SnackBar(content: Text(context.localizeError(err))),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final settings = ref.watch(settingsControllerProvider).value;
    final locale = settings?.localeCode ?? 'vi';
    final currencyCode =
        widget.existing?.currency ??
        settings?.currencyCode ??
        AppCurrencies.defaultCode;
    final currencyInfo = AppCurrencies.byCode(currencyCode);
    final expenseCategories = ref.watch(expenseCategoriesProvider);

    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 4,
        bottom: MediaQuery.viewInsetsOf(context).bottom + 24,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                widget.existing != null ? l10n.editBudget : l10n.addBudget,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 16),

              // Scope Selector (Overall or Specific Expense Category)
              DropdownButtonFormField<String?>(
                isExpanded: true,
                initialValue: _selectedCategoryId,
                decoration: InputDecoration(
                  labelText: l10n.budgetScope,
                  prefixIcon: const Icon(Icons.layers_outlined),
                ),
                items: [
                  DropdownMenuItem<String?>(
                    value: null,
                    child: Text(
                      l10n.overallMonthlyBudget,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  for (final cat in expenseCategories)
                    DropdownMenuItem<String?>(
                      value: cat.id,
                      child: Text(
                        DefaultCategoryLocalization.resolveName(
                          l10n,
                          categoryId: cat.id,
                          fallbackName: cat.name,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                ],
                onChanged: (val) => setState(() => _selectedCategoryId = val),
              ),
              const SizedBox(height: 16),

              // Monthly Limit Amount
              AppleTextField(
                controller: _amountController,
                keyboardType: TextInputType.numberWithOptions(
                  decimal: currencyInfo.decimalDigits > 0,
                ),
                inputFormatters: [
                  MoneyInputFormatter(
                    currencyCode: currencyCode,
                    locale: locale,
                  ),
                ],
                label: l10n.budgetLimit,
                placeholder: '0',
                suffix: Text(
                  currencyInfo.symbol,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                validator: (val) {
                  final m = Money.tryParse(
                    val ?? '',
                    currencyCode: currencyCode,
                  );
                  if (m == null || m.minorUnits <= 0) {
                    return l10n.amountRequiredError;
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // Alert Threshold Slider (50% .. 100%)
              Text(
                l10n.alertThresholdLabel(_threshold),
                style: theme.textTheme.titleSmall,
              ),
              Slider(
                value: _threshold.toDouble(),
                min: 50,
                max: 100,
                divisions: 10,
                label: '$_threshold%',
                semanticFormatterCallback: (val) => '${val.round()}%',
                onChanged: (val) => setState(() => _threshold = val.round()),
              ),
              const SizedBox(height: 16),

              AppleButton.primary(
                onPressed: _save,
                label: l10n.save,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

