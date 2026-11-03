import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:so_thu_chi/core/constants/currency_constants.dart';
import 'package:so_thu_chi/core/constants/icon_catalog.dart';
import 'package:so_thu_chi/core/contracts/transaction_draft_contract.dart';
import 'package:so_thu_chi/core/l10n/l10n_ext.dart';
import 'package:so_thu_chi/core/router/app_routes.dart';
import 'package:so_thu_chi/core/theme/app_theme.dart';
import 'package:so_thu_chi/core/theme/apple_theme_tokens.dart';
import 'package:so_thu_chi/core/utils/date_formatter.dart';
import 'package:so_thu_chi/core/utils/money.dart';
import 'package:so_thu_chi/core/widgets/apple_kit.dart';
import 'package:so_thu_chi/features/accounts/domain/entities/account.dart';
import 'package:so_thu_chi/features/accounts/presentation/controllers/accounts_controller.dart';
import 'package:so_thu_chi/features/budgets/presentation/controllers/budgets_controller.dart';
import 'package:so_thu_chi/features/categories/domain/entities/category.dart';
import 'package:so_thu_chi/features/categories/presentation/controllers/categories_controller.dart';
import 'package:so_thu_chi/features/settings/presentation/controllers/settings_controller.dart';
import 'package:so_thu_chi/features/transactions/domain/entities/transaction_entity.dart';
import 'package:so_thu_chi/features/transactions/presentation/controllers/transactions_controller.dart';

class TransactionFormScreen extends ConsumerStatefulWidget {
  const TransactionFormScreen({
    super.key,
    this.editTransactionId,
    this.initialDraft,
  });

  final String? editTransactionId;
  final TransactionDraft? initialDraft;

  @override
  ConsumerState<TransactionFormScreen> createState() =>
      _TransactionFormScreenState();
}

class _TransactionFormScreenState extends ConsumerState<TransactionFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  final _tagsController = TextEditingController();

  TransactionType _type = TransactionType.expense;
  String? _accountId;
  String? _toAccountId;
  String? _categoryId;
  DateTime _selectedDate = DateTime.now();
  TransactionEntity? _existingTx;
  bool _loadingExisting = false;
  bool _initializedDefaults = false;

  bool get _isEditing => widget.editTransactionId != null;

  @override
  void initState() {
    super.initState();
    final draft = widget.initialDraft;
    if (draft != null) {
      final locale =
          ref.read(settingsControllerProvider).value?.localeCode ?? 'vi';
      _type = switch (draft.kind) {
        TransactionDraftKind.income => TransactionType.income,
        TransactionDraftKind.expense => TransactionType.expense,
        TransactionDraftKind.transfer => TransactionType.transfer,
      };
      _accountId = draft.accountId;
      _toAccountId = draft.toAccountId;
      _categoryId = draft.categoryId;
      if (draft.date != null) _selectedDate = draft.date!;
      if (draft.note != null) _noteController.text = draft.note!;
      if (draft.tags.isNotEmpty) {
        _tagsController.text = draft.tags.join(', ');
      }
      if (draft.amountMinorUnits != null && draft.amountMinorUnits! > 0) {
        _amountController.text = Money(
          minorUnits: draft.amountMinorUnits!,
          currencyCode: draft.currencyCode ?? AppCurrencies.defaultCode,
        ).toInputString(locale: locale);
      }
    }

    if (_isEditing) {
      _loadExistingTransaction();
    }
  }

  Future<void> _loadExistingTransaction() async {
    setState(() => _loadingExisting = true);
    final tx = await ref
        .read(transactionsActionControllerProvider.notifier)
        .getById(widget.editTransactionId!);
    if (!mounted) return;
    if (tx != null) {
      final locale =
          ref.read(settingsControllerProvider).value?.localeCode ?? 'vi';
      setState(() {
        _existingTx = tx;
        _type = tx.type;
        _accountId = tx.accountId;
        _toAccountId = tx.toAccountId;
        _categoryId = tx.categoryId;
        _selectedDate = tx.date;
        _amountController.text = tx.money.toInputString(locale: locale);
        _noteController.text = tx.note;
        _tagsController.text = tx.tags.join(', ');
        _loadingExisting = false;
      });
    } else {
      setState(() => _loadingExisting = false);
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    _tagsController.dispose();
    super.dispose();
  }

  String _resolveEffectiveCurrency(List<Account> wallets) {
    if (_accountId != null) {
      for (final w in wallets) {
        if (w.id == _accountId) return w.currency;
      }
    }
    return _existingTx?.currency ??
        ref.read(settingsControllerProvider).value?.currencyCode ??
        AppCurrencies.defaultCode;
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2018),
      lastDate: DateTime(now.year + 5, 12, 31),
    );
    if (picked != null && mounted) {
      setState(() => _selectedDate = picked);
    }
  }

  void _addAmountShortcut(int additionMinorUnits, String currencyCode, String locale) {
    HapticFeedback.lightImpact();
    final current =
        Money.tryParse(_amountController.text, currencyCode: currencyCode)
            ?.minorUnits ??
        0;
    final updated = current + additionMinorUnits;
    final newText = Money(
      minorUnits: updated,
      currencyCode: currencyCode,
    ).toInputString(locale: locale);
    setState(() {
      _amountController.text = newText;
    });
  }

  Future<void> _submit() async {
    final l10n = context.l10n;
    final messenger = ScaffoldMessenger.of(context);
    final allWallets = ref.read(accountsStreamProvider).value ?? const [];
    final currency = _resolveEffectiveCurrency(allWallets);

    if (!_formKey.currentState!.validate()) return;

    final parsedMoney = Money.tryParse(
      _amountController.text,
      currencyCode: currency,
    );
    if (parsedMoney == null || parsedMoney.minorUnits <= 0) {
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.amountRequiredError)),
      );
      return;
    }

    if (_accountId == null || _accountId!.isEmpty) {
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.walletRequiredError)),
      );
      return;
    }

    if (_type == TransactionType.transfer) {
      if (_toAccountId == null || _toAccountId!.isEmpty) {
        messenger.showSnackBar(
          SnackBar(content: Text(l10n.walletRequiredError)),
        );
        return;
      }
      if (_toAccountId == _accountId) {
        messenger.showSnackBar(
          SnackBar(content: Text(l10n.sameWalletTransferError)),
        );
        return;
      }
      Account? fromAcc;
      Account? toAcc;
      for (final w in allWallets) {
        if (w.id == _accountId) fromAcc = w;
        if (w.id == _toAccountId) toAcc = w;
      }
      if (fromAcc != null && toAcc != null && fromAcc.currency != toAcc.currency) {
        messenger.showSnackBar(
          SnackBar(content: Text(l10n.differentCurrencyTransferError)),
        );
        return;
      }
    } else if (_categoryId == null || _categoryId!.isEmpty) {
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.categoryRequiredError)),
      );
      return;
    }

    final tags = _tagsController.text
        .split(',')
        .map((t) => t.trim())
        .where((t) => t.isNotEmpty)
        .toList(growable: false);

    final notifier = ref.read(transactionsActionControllerProvider.notifier);

    if (_isEditing && _existingTx != null) {
      final updated = _existingTx!.copyWith(
        amount: parsedMoney.minorUnits,
        currency: currency,
        type: _type,
        accountId: _accountId!,
        toAccountId: _type == TransactionType.transfer ? _toAccountId : null,
        categoryId: _type == TransactionType.transfer
            ? 'system_transfer'
            : _categoryId!,
        note: _noteController.text.trim(),
        date: _selectedDate,
        tags: tags,
      );
      final res = await notifier.update(updated);
      if (!mounted) return;
      res.fold(
        onSuccess: (saved) {
          _maybeShowBudgetAlert(saved);
          context.pop();
        },
        onFailure: (err) {
          messenger.showSnackBar(
            SnackBar(content: Text(context.localizeError(err))),
          );
        },
      );
    } else {
      final res = await notifier.add(
        amount: parsedMoney.minorUnits,
        currency: currency,
        type: _type,
        accountId: _accountId!,
        toAccountId: _type == TransactionType.transfer ? _toAccountId : null,
        categoryId: _type == TransactionType.transfer
            ? 'system_transfer'
            : _categoryId!,
        note: _noteController.text.trim(),
        date: _selectedDate,
        tags: tags,
      );
      if (!mounted) return;
      res.fold(
        onSuccess: (saved) {
          _maybeShowBudgetAlert(saved);
          context.pop();
        },
        onFailure: (err) {
          messenger.showSnackBar(
            SnackBar(content: Text(context.localizeError(err))),
          );
        },
      );
    }
  }

  void _maybeShowBudgetAlert(TransactionEntity saved) {
    if (saved.type != TransactionType.expense) return;
    final hook = ref.read(expenseBudgetWarningHookProvider);
    final warningText = hook != null
        ? hook(context, saved)
        : evaluateExpenseBudgetAlert(
            context: context,
            ref: ref,
            savedExpense: saved,
          );
    if (warningText != null && warningText.isNotEmpty) {
      final financeColors = context.financeColors;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: financeColors.warningContainer,
          content: Row(
            children: [
              Icon(
                Icons.warning_amber_rounded,
                color: financeColors.onWarningContainer,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  warningText,
                  style: TextStyle(
                    color: financeColors.onWarningContainer,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }
  }

  Future<void> _deleteCurrent() async {
    final existing = _existingTx;
    if (existing == null) return;
    final l10n = context.l10n;
    final messenger = ScaffoldMessenger.of(context);
    final actionNotifier = ref.read(
      transactionsActionControllerProvider.notifier,
    );
    final res = await actionNotifier.softDelete(existing.id);
    if (!mounted) return;
    res.fold(
      onSuccess: (_) {
        messenger
          ..clearSnackBars()
          ..showSnackBar(
            SnackBar(
              content: Text(l10n.transactionDeleted),
              action: SnackBarAction(
                label: l10n.undo,
                onPressed: () => actionNotifier.restore(existing.id),
              ),
            ),
          );
        context.pop();
      },
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
    final isDark = theme.brightness == Brightness.dark;
    final settings = ref.watch(settingsControllerProvider).value;
    final locale = settings?.localeCode ?? 'vi';

    final activeWallets = ref.watch(activeAccountsProvider);
    final allWallets = ref.watch(accountsStreamProvider).value ?? const [];
    final walletsForDropdown = _isEditing ? allWallets : activeWallets;

    final expenseCategories = ref.watch(expenseCategoriesProvider);
    final incomeCategories = ref.watch(incomeCategoriesProvider);
    final availableCategories = _type == TransactionType.income
        ? incomeCategories
        : expenseCategories;

    // Auto-select sensible default wallet & category on first render
    if (!_initializedDefaults && !_isEditing) {
      if (_accountId == null && walletsForDropdown.isNotEmpty) {
        _accountId = walletsForDropdown.first.id;
      }
      if (_toAccountId == null && walletsForDropdown.length > 1) {
        final srcCurrency = _resolveEffectiveCurrency(walletsForDropdown);
        final matchingDest = walletsForDropdown
            .where((w) => w.id != _accountId && w.currency == srcCurrency)
            .toList(growable: false);
        _toAccountId = matchingDest.isNotEmpty
            ? matchingDest.first.id
            : walletsForDropdown[1].id;
      }
      if (_categoryId == null && availableCategories.isNotEmpty) {
        _categoryId = availableCategories.first.id;
      }
      if (_accountId != null || _categoryId != null) {
        _initializedDefaults = true;
      }
    }

    final currencyCode = _resolveEffectiveCurrency(walletsForDropdown);
    final currencyInfo = AppCurrencies.byCode(currencyCode);
    final isSaving = ref.watch(transactionsActionControllerProvider).isLoading;

    final formattedSelectedDate = AppDateUtils.formatDayHeader(
      _selectedDate,
      locale: locale,
      todayLabel: l10n.today,
      yesterdayLabel: l10n.yesterday,
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? l10n.editTransaction : l10n.addTransaction),
        actions: [
          if (_isEditing && _existingTx != null)
            IconButton(
              tooltip: l10n.delete,
              onPressed: isSaving ? null : _deleteCurrent,
              icon: Icon(
                Icons.delete_outline_rounded,
                color: theme.colorScheme.error,
              ),
            ),
        ],
      ),
      body: _loadingExisting
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Type Segmented Control
                  SegmentedButton<TransactionType>(
                    segments: [
                      ButtonSegment(
                        value: TransactionType.expense,
                        icon: const Icon(Icons.north_east_rounded),
                        label: Text(l10n.expense),
                      ),
                      ButtonSegment(
                        value: TransactionType.income,
                        icon: const Icon(Icons.south_west_rounded),
                        label: Text(l10n.income),
                      ),
                      ButtonSegment(
                        value: TransactionType.transfer,
                        icon: const Icon(Icons.swap_horiz_rounded),
                        label: Text(l10n.transfer),
                      ),
                    ],
                    selected: {_type},
                    onSelectionChanged: (selection) {
                      final next = selection.first;
                      setState(() {
                        _type = next;
                        if (next != TransactionType.transfer) {
                          final list = next == TransactionType.income
                              ? incomeCategories
                              : expenseCategories;
                          if (!list.any((c) => c.id == _categoryId)) {
                            _categoryId = list.isNotEmpty
                                ? list.first.id
                                : null;
                          }
                        }
                      });
                    },
                  ),
                  const SizedBox(height: 20),

                  // Amount Field
                  TextFormField(
                    controller: _amountController,
                    autofocus: !_isEditing,
                    keyboardType: TextInputType.numberWithOptions(
                      decimal: currencyInfo.decimalDigits > 0,
                    ),
                    inputFormatters: [
                      MoneyInputFormatter(
                        currencyCode: currencyCode,
                        locale: locale,
                      ),
                    ],
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      fontFeatures: AppTheme.tabularFigures,
                    ),
                    decoration: InputDecoration(
                      labelText: l10n.amount,
                      suffixText: currencyInfo.symbol,
                      hintText: '0',
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
                  const SizedBox(height: 10),

                  // Quick Amount Addition Pills (Apple style)
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        for (final shortcut in [
                          (label: '+20k', amount: 20000),
                          (label: '+50k', amount: 50000),
                          (label: '+100k', amount: 100000),
                          (label: '+200k', amount: 200000),
                          (label: '+500k', amount: 500000),
                          (label: '+1tr', amount: 1000000),
                        ])
                          Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: ApplePressable(
                              borderRadius:
                                  BorderRadius.circular(AppleTokens.radiusPill),
                              onTap: () => _addAmountShortcut(
                                shortcut.amount,
                                currencyCode,
                                locale,
                              ),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? AppleTokens.bgDarkSecondary
                                      : AppleTokens.bgLightSecondary,
                                  borderRadius: BorderRadius.circular(
                                    AppleTokens.radiusPill,
                                  ),
                                ),
                                child: Text(
                                  shortcut.label,
                                  style: theme.textTheme.labelMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: theme.colorScheme.onSurface,
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Source Wallet Selector
                  DropdownButtonFormField<String>(
                    isExpanded: true,
                    initialValue:
                        walletsForDropdown.any((w) => w.id == _accountId)
                        ? _accountId
                        : null,
                    decoration: InputDecoration(
                      labelText: _type == TransactionType.transfer
                          ? l10n.fromWallet
                          : l10n.walletsTitle,
                      prefixIcon: const Icon(
                        Icons.account_balance_wallet_outlined,
                      ),
                    ),
                    items: [
                      for (final wallet in walletsForDropdown)
                        DropdownMenuItem(
                          value: wallet.id,
                          child: Text(
                            '${wallet.name} (${wallet.balanceMoney.format(locale: locale)})',
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                    ],
                    onChanged: (val) => setState(() => _accountId = val),
                    validator: (val) => val == null || val.isEmpty
                        ? l10n.walletRequiredError
                        : null,
                  ),

                  // Destination Wallet Selector (for Transfers)
                  if (_type == TransactionType.transfer) ...[
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      isExpanded: true,
                      initialValue:
                          walletsForDropdown.any((w) => w.id == _toAccountId)
                          ? _toAccountId
                          : null,
                      decoration: InputDecoration(
                        labelText: l10n.toWallet,
                        prefixIcon: const Icon(Icons.east_rounded),
                      ),
                      items: [
                        for (final wallet in walletsForDropdown)
                          DropdownMenuItem(
                            value: wallet.id,
                            child: Text(
                              '${wallet.name} (${wallet.balanceMoney.format(locale: locale)})',
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                      ],
                      onChanged: (val) => setState(() => _toAccountId = val),
                      validator: (val) {
                        if (val == null || val.isEmpty) {
                          return l10n.walletRequiredError;
                        }
                        if (val == _accountId) {
                          return l10n.sameWalletTransferError;
                        }
                        Account? fromAcc;
                        Account? toAcc;
                        for (final w in walletsForDropdown) {
                          if (w.id == _accountId) fromAcc = w;
                          if (w.id == val) toAcc = w;
                        }
                        if (fromAcc != null &&
                            toAcc != null &&
                            fromAcc.currency != toAcc.currency) {
                          return l10n.differentCurrencyTransferError;
                        }
                        return null;
                      },
                    ),
                  ],

                  // Category Picker Grid (for Income / Expense)
                  if (_type != TransactionType.transfer) ...[
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            l10n.selectCategory,
                            style: theme.textTheme.titleSmall,
                          ),
                        ),
                        Flexible(
                          flex: 0,
                          child: TextButton.icon(
                            onPressed: () => context.push(AppRoutes.categories),
                            icon: const Icon(Icons.edit_note_rounded, size: 18),
                            label: Text(l10n.manageCategories),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    _CategorySelectionGrid(
                      categories: availableCategories,
                      selectedId: _categoryId,
                      onSelected: (id) => setState(() => _categoryId = id),
                    ),
                  ],

                  const SizedBox(height: 20),

                  // Date Picker Row
                  Semantics(
                    button: true,
                    excludeSemantics: true,
                    label: '${l10n.date}: $formattedSelectedDate',
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: _pickDate,
                      child: InputDecorator(
                        decoration: InputDecoration(
                          labelText: l10n.date,
                          prefixIcon: const Icon(Icons.calendar_today_rounded),
                        ),
                        child: Text(formattedSelectedDate),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Note Field
                  TextFormField(
                    controller: _noteController,
                    maxLines: 2,
                    maxLength: 1000,
                    decoration: InputDecoration(
                      labelText: l10n.note,
                      hintText: l10n.noteHint,
                      prefixIcon: const Icon(Icons.notes_rounded),
                      counterText: '',
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Tags Field
                  TextFormField(
                    controller: _tagsController,
                    decoration: InputDecoration(
                      labelText: l10n.tags,
                      hintText: l10n.tagsHint,
                      prefixIcon: const Icon(Icons.sell_outlined),
                    ),
                  ),
                  const SizedBox(height: 28),

                  FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: AppleTokens.jadePrimary,
                      foregroundColor: Colors.white,
                      minimumSize: const Size.fromHeight(52),
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(AppleTokens.radiusPill),
                      ),
                      elevation: 0,
                    ),
                    onPressed: isSaving ? null : _submit,
                    icon: isSaving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.check_rounded),
                    label: Text(
                      l10n.save,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
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

class _CategorySelectionGrid extends StatelessWidget {
  const _CategorySelectionGrid({
    required this.categories,
    required this.selectedId,
    required this.onSelected,
  });

  final List<Category> categories;
  final String? selectedId;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final cat in categories)
          Builder(
            builder: (context) {
              final selected = cat.id == selectedId;
              final catColor = AppIconCatalog.contrastSafeColor(
                Color(cat.color),
                theme.brightness,
              );
              final label = DefaultCategoryLocalization.resolveName(
                l10n,
                categoryId: cat.id,
                fallbackName: cat.name,
              );
              return ChoiceChip(
                avatar: Icon(
                  AppIconCatalog.resolve(cat.icon),
                  size: 18,
                  color: selected
                      ? theme.colorScheme.onPrimaryContainer
                      : catColor,
                ),
                label: Text(label),
                selected: selected,
                onSelected: (_) => onSelected(cat.id),
              );
            },
          ),
      ],
    );
  }
}
