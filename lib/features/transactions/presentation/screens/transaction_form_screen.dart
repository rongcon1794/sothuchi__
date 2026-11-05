import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:so_thu_chi/core/constants/currency_constants.dart';
import 'package:so_thu_chi/core/constants/icon_catalog.dart';
import 'package:so_thu_chi/core/contracts/transaction_draft_contract.dart';
import 'package:so_thu_chi/core/l10n/l10n_ext.dart';
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
import 'package:so_thu_chi/features/categories/presentation/widgets/category_form_sheet.dart';
import 'package:so_thu_chi/features/settings/presentation/controllers/settings_controller.dart';
import 'package:so_thu_chi/features/transactions/domain/entities/transaction_entity.dart';
import 'package:so_thu_chi/features/transactions/presentation/controllers/transactions_controller.dart';

/// Redesigned, state-of-the-art Apple HIG Add / Edit Transaction Screen.
/// Features interactive semantic hero amount card, instant category picker,
/// grouped Apple inset cards, wallet selection sheet, and tactile sticky action dock.
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
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          ref.read(categoriesActionControllerProvider.notifier).seedDefaultsIfNeeded();
        }
      });
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

  void _clearAmount() {
    HapticFeedback.lightImpact();
    setState(() {
      _amountController.clear();
    });
  }

  void _swapTransferWallets() {
    if (_type != TransactionType.transfer) return;
    HapticFeedback.mediumImpact();
    setState(() {
      final temp = _accountId;
      _accountId = _toAccountId;
      _toAccountId = temp;
    });
  }

  Future<void> _openWalletPicker(
    BuildContext context, {
    required List<Account> wallets,
    required bool isDestination,
    required String locale,
  }) async {
    final selectedId = isDestination ? _toAccountId : _accountId;
    final result = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _WalletPickerSheet(
        wallets: wallets,
        selectedId: selectedId,
        locale: locale,
        title: isDestination ? 'Chọn ví nhận tiền' : 'Chọn ví thanh toán',
      ),
    );

    if (result != null && mounted) {
      setState(() {
        if (isDestination) {
          _toAccountId = result;
        } else {
          _accountId = result;
        }
      });
    }
  }

  Future<void> _openCreateCategorySheet(BuildContext context) async {
    final catType = _type == TransactionType.income
        ? CategoryType.income
        : CategoryType.expense;
    final created = await CategoryFormSheet.show(
      context,
      initialType: catType,
    );
    if (created != null && mounted) {
      setState(() {
        _categoryId = created.id;
      });
    }
  }

  Future<void> _openCategoryPicker(
    BuildContext context, {
    required List<Category> categories,
  }) async {
    final result = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _CategoryPickerSheet(
        categories: categories,
        selectedId: _categoryId,
        onCreateNew: () => _openCreateCategorySheet(context),
      ),
    );

    if (result != null && mounted) {
      setState(() => _categoryId = result);
    }
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

  Future<void> _confirmDelete() async {
    final l10n = context.l10n;
    final confirmed = await showCupertinoModalPopup<bool>(
      context: context,
      builder: (ctx) => CupertinoActionSheet(
        title: Text(l10n.delete),
        message: const Text('Bạn có chắc chắn muốn xóa giao dịch này?'),
        actions: [
          CupertinoActionSheetAction(
            isDestructiveAction: true,
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(l10n.delete),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.of(ctx).pop(false),
          child: Text(l10n.cancel),
        ),
      ),
    );
    if (confirmed == true && mounted) {
      await _deleteCurrent();
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
    final categoriesAsync = ref.watch(categoriesStreamProvider);
    final availableCategories = _type == TransactionType.income
        ? incomeCategories
        : expenseCategories;

    // Auto-select sensible default wallet on first render
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
      if (_accountId != null) {
        _initializedDefaults = true;
      }
    }

    // Dynamic self-healing: ensure category is always selected whenever available
    if (!_isEditing && _type != TransactionType.transfer && availableCategories.isNotEmpty) {
      if (_categoryId == null || !availableCategories.any((c) => c.id == _categoryId)) {
        _categoryId = availableCategories.first.id;
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

    // Resolved Selected Account and Category entities
    Account? selectedAccount;
    for (final w in walletsForDropdown) {
      if (w.id == _accountId) {
        selectedAccount = w;
        break;
      }
    }

    Account? selectedToAccount;
    for (final w in walletsForDropdown) {
      if (w.id == _toAccountId) {
        selectedToAccount = w;
        break;
      }
    }

    Category? selectedCategory;
    for (final c in availableCategories) {
      if (c.id == _categoryId) {
        selectedCategory = c;
        break;
      }
    }

    return Scaffold(
      backgroundColor: isDark ? AppleTokens.bgDarkPrimary : AppleTokens.bgLightPrimary,
      appBar: AppBar(
        title: Text(
          _isEditing ? l10n.editTransaction : l10n.addTransaction,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(CupertinoIcons.chevron_left, size: 24),
          tooltip: 'Quay lại',
          onPressed: () => context.pop(),
        ),
        actions: [
          if (_isEditing && _existingTx != null)
            IconButton(
              tooltip: l10n.delete,
              onPressed: isSaving ? null : _confirmDelete,
              icon: const Icon(
                CupertinoIcons.trash,
                color: AppleTokens.rubyExpense,
                size: 22,
              ),
            ),
          const SizedBox(width: 4),
        ],
      ),
      body: _loadingExisting
          ? const Center(child: CupertinoActivityIndicator())
          : Form(
              key: _formKey,
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                  // 1. Hero Amount & Mode Card
                  _HeroAmountCard(
                    type: _type,
                    amountController: _amountController,
                    currencyInfo: currencyInfo,
                    currencyCode: currencyCode,
                    locale: locale,
                    isEditing: _isEditing,
                    onTypeChanged: (newType) {
                      setState(() {
                        _type = newType;
                        if (newType != TransactionType.transfer) {
                          final list = newType == TransactionType.income
                              ? incomeCategories
                              : expenseCategories;
                          if (!list.any((c) => c.id == _categoryId)) {
                            _categoryId = list.isNotEmpty ? list.first.id : null;
                          }
                        }
                      });
                    },
                    onAddShortcut: (amount) => _addAmountShortcut(amount, currencyCode, locale),
                    onClear: _clearAmount,
                  ),
                  const SizedBox(height: 18),

                  // 2. Category Selection Section (Only for Expense & Income)
                  if (_type != TransactionType.transfer) ...[
                    if (availableCategories.isNotEmpty) ...[
                      _CategorySelectionCard(
                        categories: availableCategories,
                        selectedId: _categoryId,
                        selectedCategory: selectedCategory,
                        onSelected: (id) {
                          HapticFeedback.selectionClick();
                          setState(() => _categoryId = id);
                        },
                        onOpenMore: () => _openCategoryPicker(context, categories: availableCategories),
                        onCreateNew: () => _openCreateCategorySheet(context),
                      ),
                      const SizedBox(height: 18),
                    ] else if (categoriesAsync.isLoading) ...[
                      AppleGlassCard(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                        borderRadius: BorderRadius.circular(AppleTokens.radiusCard),
                        borderColor: isDark
                            ? Colors.white.withValues(alpha: 0.12)
                            : AppleTokens.borderLight,
                        child: Row(
                          children: [
                            const CupertinoActivityIndicator(),
                            const SizedBox(width: 12),
                            Text(
                              l10n.loadingCategories,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: AppleTokens.systemGray,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),
                    ] else ...[
                      // Empty state: Auto-seed and provide manual recovery options
                      AppleGlassCard(
                        padding: const EdgeInsets.all(16),
                        borderRadius: BorderRadius.circular(AppleTokens.radiusCard),
                        borderColor: isDark
                            ? Colors.white.withValues(alpha: 0.12)
                            : AppleTokens.borderLight,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 36,
                                  height: 36,
                                  decoration: BoxDecoration(
                                    color: AppleTokens.systemOrange.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Icon(
                                    CupertinoIcons.square_grid_2x2,
                                    size: 20,
                                    color: AppleTokens.systemOrange,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        l10n.selectCategory,
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: AppleTokens.systemGray,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      const Text(
                                        'Chưa có danh mục nào',
                                        style: TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            const Text(
                              'Vui lòng khôi phục danh mục mẫu hoặc tạo danh mục mới để phân loại giao dịch.',
                              style: TextStyle(
                                fontSize: 13,
                                color: AppleTokens.systemGray,
                              ),
                            ),
                            const SizedBox(height: 14),
                            Row(
                              children: [
                                Expanded(
                                  child: ApplePressable(
                                    scaleDown: 0.95,
                                    onTap: () async {
                                      await HapticFeedback.mediumImpact();
                                      await ref.read(categoriesActionControllerProvider.notifier).seedDefaultsIfNeeded();
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(vertical: 9),
                                      alignment: Alignment.center,
                                      decoration: BoxDecoration(
                                        color: AppleTokens.systemBlue.withValues(alpha: 0.15),
                                        borderRadius: BorderRadius.circular(AppleTokens.radiusPill),
                                      ),
                                      child: const Text(
                                        'Khôi phục mẫu',
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                          color: AppleTokens.systemBlue,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: ApplePressable(
                                    scaleDown: 0.95,
                                    onTap: () => _openCreateCategorySheet(context),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(vertical: 9),
                                      alignment: Alignment.center,
                                      decoration: BoxDecoration(
                                        color: AppleTokens.jadePrimary.withValues(alpha: 0.15),
                                        borderRadius: BorderRadius.circular(AppleTokens.radiusPill),
                                      ),
                                      child: const Text(
                                        '+ Thêm mới',
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                          color: AppleTokens.jadePrimary,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),
                    ],
                  ],

                  // 3. Wallet Selection Section
                  AppleListGroup(
                    header: l10n.walletsTitle,
                    margin: const EdgeInsets.only(bottom: 20),
                    children: [
                      if (_type == TransactionType.transfer) ...[
                        // Source Wallet (From)
                        ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                          leading: const AppleSquircleBadge(
                            icon: CupertinoIcons.arrow_up_right,
                            backgroundColor: AppleTokens.systemOrange,
                            size: 38,
                            iconSize: 18,
                            radius: 10,
                          ),
                          title: Text(
                            l10n.fromWallet,
                            style: const TextStyle(fontSize: 13, color: AppleTokens.systemGray),
                          ),
                          subtitle: Text(
                            selectedAccount != null
                                ? '${selectedAccount.name} (${selectedAccount.balanceMoney.format(locale: locale)})'
                                : 'Chọn ví chuyển',
                            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                          ),
                          trailing: const Icon(CupertinoIcons.chevron_right, size: 16, color: AppleTokens.systemGray),
                          onTap: () => _openWalletPicker(
                            context,
                            wallets: walletsForDropdown,
                            isDestination: false,
                            locale: locale,
                          ),
                        ),

                        // Transfer Inversion / Swap row
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                          color: isDark ? Colors.white.withValues(alpha: 0.02) : Colors.black.withValues(alpha: 0.02),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              ApplePressable(
                                scaleDown: 0.92,
                                onTap: _swapTransferWallets,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: isDark ? AppleTokens.bgDarkSecondary : AppleTokens.bgLightSecondary,
                                    borderRadius: BorderRadius.circular(AppleTokens.radiusPill),
                                    border: Border.all(
                                      color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.08),
                                      width: AppleTokens.hairline,
                                    ),
                                  ),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(CupertinoIcons.arrow_2_squarepath, size: 14, color: AppleTokens.systemBlue),
                                      SizedBox(width: 6),
                                      Text(
                                        'Đổi chiều chuyển',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: AppleTokens.systemBlue,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Destination Wallet (To)
                        ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                          leading: const AppleSquircleBadge(
                            icon: CupertinoIcons.arrow_down_left,
                            backgroundColor: AppleTokens.systemGreen,
                            size: 38,
                            iconSize: 18,
                            radius: 10,
                          ),
                          title: Text(
                            l10n.toWallet,
                            style: const TextStyle(fontSize: 13, color: AppleTokens.systemGray),
                          ),
                          subtitle: Text(
                            selectedToAccount != null
                                ? '${selectedToAccount.name} (${selectedToAccount.balanceMoney.format(locale: locale)})'
                                : 'Chọn ví nhận',
                            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                          ),
                          trailing: const Icon(CupertinoIcons.chevron_right, size: 16, color: AppleTokens.systemGray),
                          onTap: () => _openWalletPicker(
                            context,
                            wallets: walletsForDropdown,
                            isDestination: true,
                            locale: locale,
                          ),
                        ),
                      ] else ...[
                        // Source Wallet (Single Payment Wallet)
                        ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                          leading: AppleSquircleBadge(
                            icon: selectedAccount != null
                                ? AppIconCatalog.resolve(selectedAccount.icon)
                                : CupertinoIcons.creditcard,
                            backgroundColor: selectedAccount != null
                                ? Color(selectedAccount.color)
                                : AppleTokens.systemBlue,
                            size: 38,
                            iconSize: 20,
                            radius: 10,
                          ),
                          title: Text(
                            l10n.walletsTitle,
                            style: const TextStyle(fontSize: 13, color: AppleTokens.systemGray),
                          ),
                          subtitle: Text(
                            selectedAccount != null
                                ? '${selectedAccount.name} (${selectedAccount.balanceMoney.format(locale: locale)})'
                                : 'Chọn ví',
                            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                          ),
                          trailing: const Icon(CupertinoIcons.chevron_right, size: 16, color: AppleTokens.systemGray),
                          onTap: () => _openWalletPicker(
                            context,
                            wallets: walletsForDropdown,
                            isDestination: false,
                            locale: locale,
                          ),
                        ),
                      ],
                    ],
                  ),

                  // 3. Transaction Details & Metadata Section
                  AppleListGroup(
                    header: 'THỜI GIAN & CHI TIẾT',
                    margin: const EdgeInsets.only(bottom: 24),
                    children: [
                      // Date Selector Row
                      ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        leading: const AppleSquircleBadge(
                          icon: CupertinoIcons.calendar,
                          backgroundColor: AppleTokens.systemIndigo,
                          size: 38,
                          iconSize: 20,
                          radius: 10,
                        ),
                        title: Text(
                          l10n.date,
                          style: const TextStyle(fontSize: 13, color: AppleTokens.systemGray),
                        ),
                        subtitle: Text(
                          formattedSelectedDate,
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: isDark ? AppleTokens.bgDarkSecondary : AppleTokens.bgLightSecondary,
                                borderRadius: BorderRadius.circular(AppleTokens.radiusPill),
                              ),
                              child: Text(
                                _selectedDate.day == DateTime.now().day &&
                                        _selectedDate.month == DateTime.now().month &&
                                        _selectedDate.year == DateTime.now().year
                                    ? 'Hôm nay'
                                    : 'Thay đổi',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: AppleTokens.systemBlue,
                                ),
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Icon(CupertinoIcons.chevron_right, size: 16, color: AppleTokens.systemGray),
                          ],
                        ),
                        onTap: _pickDate,
                      ),

                      // Note Input Row
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            const AppleSquircleBadge(
                              icon: CupertinoIcons.pencil_ellipsis_rectangle,
                              backgroundColor: AppleTokens.systemYellow,
                              size: 38,
                              iconSize: 20,
                              radius: 10,
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: TextFormField(
                                controller: _noteController,
                                maxLines: null,
                                maxLength: 1000,
                                style: const TextStyle(fontSize: 15),
                                decoration: InputDecoration(
                                  border: InputBorder.none,
                                  isDense: true,
                                  contentPadding: const EdgeInsets.symmetric(vertical: 8),
                                  hintText: l10n.noteHint,
                                  hintStyle: TextStyle(
                                    fontSize: 14,
                                    color: isDark ? const Color(0xFF6C6C70) : const Color(0xFF8E8E93),
                                  ),
                                  counterText: '',
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Tags Input Row
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            const AppleSquircleBadge(
                              icon: CupertinoIcons.tag,
                              backgroundColor: AppleTokens.systemPink,
                              size: 38,
                              iconSize: 18,
                              radius: 10,
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: TextFormField(
                                controller: _tagsController,
                                style: const TextStyle(fontSize: 15),
                                decoration: InputDecoration(
                                  border: InputBorder.none,
                                  isDense: true,
                                  contentPadding: const EdgeInsets.symmetric(vertical: 8),
                                  hintText: l10n.tagsHint,
                                  hintStyle: TextStyle(
                                    fontSize: 14,
                                    color: isDark ? const Color(0xFF6C6C70) : const Color(0xFF8E8E93),
                                  ),
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
            ),
          ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
          decoration: BoxDecoration(
            color: isDark
                ? AppleTokens.bgDarkCard.withValues(alpha: 0.92)
                : Colors.white.withValues(alpha: 0.92),
            border: Border(
              top: BorderSide(
                color: isDark ? AppleTokens.separatorDark : AppleTokens.separatorLight,
                width: AppleTokens.hairline,
              ),
            ),
          ),
          child: AppleButton.primary(
            height: 50,
            borderRadius: BorderRadius.circular(AppleTokens.radiusPill),
            isLoading: isSaving,
            icon: CupertinoIcons.checkmark_alt,
            label: _isEditing ? 'Cập nhật giao dịch' : l10n.save,
            color: AppleTokens.jadePrimary,
            onPressed: isSaving ? null : _submit,
          ),
        ),
      ),
    );
  }
}

/// The centerpiece: Expressive, tactile Apple-style Hero Amount & Type Selector Card.
class _HeroAmountCard extends StatelessWidget {
  const _HeroAmountCard({
    required this.type,
    required this.amountController,
    required this.currencyInfo,
    required this.currencyCode,
    required this.locale,
    required this.isEditing,
    required this.onTypeChanged,
    required this.onAddShortcut,
    required this.onClear,
  });

  final TransactionType type;
  final TextEditingController amountController;
  final CurrencyInfo currencyInfo;
  final String currencyCode;
  final String locale;
  final bool isEditing;
  final ValueChanged<TransactionType> onTypeChanged;
  final ValueChanged<int> onAddShortcut;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final typeColor = switch (type) {
      TransactionType.expense => AppleTokens.rubyExpense,
      TransactionType.income => AppleTokens.jadePrimary,
      TransactionType.transfer => AppleTokens.cobaltTransfer,
    };

    final typeSign = switch (type) {
      TransactionType.expense => '-',
      TransactionType.income => '+',
      TransactionType.transfer => '⇄',
    };

    return AppleGlassCard(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
      borderRadius: BorderRadius.circular(AppleTokens.radiusHero),
      borderColor: typeColor.withValues(alpha: isDark ? 0.35 : 0.25),
      child: Column(
        children: [
          // 1. Sliding Segmented Type Pill
          _TransactionTypeSegmentedPill(
            selected: type,
            onChanged: onTypeChanged,
          ),
          const SizedBox(height: 18),

          // 2. Large Amount Input Display
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  typeSign,
                  style: TextStyle(
                    fontSize: 34,
                    fontWeight: FontWeight.w800,
                    color: typeColor,
                    height: 1.0,
                  ),
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: IntrinsicWidth(
                    child: TextFormField(
                      controller: amountController,
                      autofocus: !isEditing,
                      textAlign: TextAlign.center,
                      showCursor: false,
                      keyboardType: TextInputType.numberWithOptions(
                        decimal: currencyInfo.decimalDigits > 0,
                      ),
                      inputFormatters: [
                        MoneyInputFormatter(
                          currencyCode: currencyCode,
                          locale: locale,
                        ),
                      ],
                      style: theme.textTheme.displaySmall?.copyWith(
                        fontSize: 38,
                        fontWeight: FontWeight.w800,
                        color: typeColor,
                        letterSpacing: -0.8,
                        fontFeatures: AppTheme.tabularFigures,
                        height: 1.1,
                      ),
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        errorBorder: InputBorder.none,
                        focusedErrorBorder: InputBorder.none,
                        disabledBorder: InputBorder.none,
                        filled: false,
                        fillColor: Colors.transparent,
                        isDense: true,
                        hintText: '0',
                        hintStyle: TextStyle(
                          color: typeColor.withValues(alpha: 0.25),
                          fontWeight: FontWeight.w800,
                        ),
                        contentPadding: EdgeInsets.zero,
                      ),
                      validator: (val) {
                        final m = Money.tryParse(val ?? '', currencyCode: currencyCode);
                        if (m == null || m.minorUnits <= 0) {
                          return context.l10n.amountRequiredError;
                        }
                        return null;
                      },
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  currencyInfo.symbol,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: typeColor.withValues(alpha: 0.85),
                    height: 1.0,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // 3. Quick Amount Shortcut Pills
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                ApplePressable(
                  scaleDown: 0.92,
                  onTap: onClear,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: isDark ? AppleTokens.bgDarkSecondary : AppleTokens.bgLightSecondary,
                      borderRadius: BorderRadius.circular(AppleTokens.radiusPill),
                      border: Border.all(
                        color: isDark ? Colors.white.withValues(alpha: 0.12) : Colors.black.withValues(alpha: 0.08),
                        width: AppleTokens.hairline,
                      ),
                    ),
                    child: const Text(
                      'Xóa',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppleTokens.rubyExpense,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
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
                      scaleDown: 0.92,
                      borderRadius: BorderRadius.circular(AppleTokens.radiusPill),
                      onTap: () => onAddShortcut(shortcut.amount),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 6),
                        decoration: BoxDecoration(
                          color: isDark ? AppleTokens.bgDarkSecondary : AppleTokens.bgLightSecondary,
                          borderRadius: BorderRadius.circular(AppleTokens.radiusPill),
                          border: Border.all(
                            color: isDark ? Colors.white.withValues(alpha: 0.12) : Colors.black.withValues(alpha: 0.08),
                            width: AppleTokens.hairline,
                          ),
                        ),
                        child: Text(
                          shortcut.label,
                          style: TextStyle(
                            fontSize: 13,
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
        ],
      ),
    );
  }
}

/// 3-State Sliding Segmented Pill for Transaction Type with Semantic Accent Color.
class _TransactionTypeSegmentedPill extends StatelessWidget {
  const _TransactionTypeSegmentedPill({
    required this.selected,
    required this.onChanged,
  });

  final TransactionType selected;
  final ValueChanged<TransactionType> onChanged;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final segments = [
      (
        type: TransactionType.expense,
        label: 'Chi tiêu',
        icon: CupertinoIcons.arrow_up_right,
        color: AppleTokens.rubyExpense,
      ),
      (
        type: TransactionType.income,
        label: 'Thu nhập',
        icon: CupertinoIcons.arrow_down_left,
        color: AppleTokens.jadePrimary,
      ),
      (
        type: TransactionType.transfer,
        label: 'Chuyển khoản',
        icon: CupertinoIcons.arrow_right_arrow_left,
        color: AppleTokens.cobaltTransfer,
      ),
    ];

    return Container(
      height: 40,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: isDark ? AppleTokens.bgDarkSecondary : AppleTokens.bgLightSecondary,
        borderRadius: BorderRadius.circular(AppleTokens.radiusPill),
      ),
      child: Row(
        children: [
          for (final item in segments)
            Expanded(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {
                  if (item.type != selected) {
                    HapticFeedback.selectionClick();
                    onChanged(item.type);
                  }
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 240),
                  curve: Curves.easeOutCubic,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: item.type == selected
                        ? (isDark ? AppleTokens.bgDarkCard : Colors.white)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(AppleTokens.radiusPill),
                    boxShadow: item.type == selected
                        ? [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.08),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ]
                        : null,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        item.icon,
                        size: 15,
                        color: item.type == selected
                            ? item.color
                            : (isDark ? const Color(0xFF8E8E93) : const Color(0xFF6C6C70)),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        item.label,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: item.type == selected ? FontWeight.w700 : FontWeight.w500,
                          color: item.type == selected
                              ? (isDark ? Colors.white : Colors.black)
                              : (isDark ? const Color(0xFF8E8E93) : const Color(0xFF6C6C70)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Unified, elegant Apple HIG Category Selection Card for Expense & Income transactions.
/// Features clean enclosing card with crisp visible border, active category header,
/// and smooth 1-tap squircle category icons without harsh stroke boxes.
class _CategorySelectionCard extends StatelessWidget {
  const _CategorySelectionCard({
    required this.categories,
    required this.selectedId,
    required this.selectedCategory,
    required this.onSelected,
    required this.onOpenMore,
    required this.onCreateNew,
  });

  final List<Category> categories;
  final String? selectedId;
  final Category? selectedCategory;
  final ValueChanged<String> onSelected;
  final VoidCallback onOpenMore;
  final VoidCallback onCreateNew;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final l10n = context.l10n;

    final previewCategories = categories.take(8).toList();

    return AppleGlassCard(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
      borderRadius: BorderRadius.circular(AppleTokens.radiusCard),
      borderColor: isDark
          ? Colors.white.withValues(alpha: 0.12)
          : AppleTokens.borderLight,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Category Title + Current Selected Category Badge + Open Sheet Button
          Row(
            children: [
              AppleSquircleBadge(
                icon: selectedCategory != null
                    ? AppIconCatalog.resolve(selectedCategory!.icon)
                    : CupertinoIcons.square_grid_2x2,
                backgroundColor: selectedCategory != null
                    ? AppIconCatalog.contrastSafeColor(
                        Color(selectedCategory!.color),
                        theme.brightness,
                      )
                    : AppleTokens.systemBlue,
                size: 36,
                iconSize: 18,
                radius: 10,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.selectCategory,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppleTokens.systemGray,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      selectedCategory != null
                          ? DefaultCategoryLocalization.resolveName(
                              l10n,
                              categoryId: selectedCategory!.id,
                              fallbackName: selectedCategory!.name,
                            )
                          : l10n.selectCategory,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              ApplePressable(
                scaleDown: 0.94,
                onTap: onOpenMore,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: isDark ? AppleTokens.bgDarkSecondary : AppleTokens.bgLightSecondary,
                    borderRadius: BorderRadius.circular(AppleTokens.radiusPill),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Tất cả',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppleTokens.systemBlue,
                        ),
                      ),
                      SizedBox(width: 2),
                      Icon(
                        CupertinoIcons.chevron_right,
                        size: 12,
                        color: AppleTokens.systemBlue,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Divider(
            height: AppleTokens.hairline,
            thickness: AppleTokens.hairline,
            color: isDark ? AppleTokens.separatorDark : AppleTokens.separatorLight,
          ),
          const SizedBox(height: 10),

          // Horizontal 1-Tap Category Icons Strip
          SizedBox(
            height: 74,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: previewCategories.length + 2,
              separatorBuilder: (_, _) => const SizedBox(width: 10),
              itemBuilder: (context, index) {
                if (index < previewCategories.length) {
                  final cat = previewCategories[index];
                  final isSelected = cat.id == selectedId;
                  final catColor = AppIconCatalog.contrastSafeColor(
                    Color(cat.color),
                    theme.brightness,
                  );
                  final name = DefaultCategoryLocalization.resolveName(
                    l10n,
                    categoryId: cat.id,
                    fallbackName: cat.name,
                  );

                  return ApplePressable(
                    scaleDown: 0.92,
                    onTap: () => onSelected(cat.id),
                    child: SizedBox(
                      width: 58,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Stack(
                            clipBehavior: Clip.none,
                            children: [
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? catColor.withValues(alpha: 0.22)
                                      : (isDark
                                          ? AppleTokens.bgDarkSecondary
                                          : AppleTokens.bgLightSecondary),
                                  borderRadius: BorderRadius.circular(13),
                                  border: isSelected
                                      ? Border.all(color: catColor, width: 1.5)
                                      : null,
                                ),
                                child: Center(
                                  child: Icon(
                                    AppIconCatalog.resolve(cat.icon),
                                    size: 22,
                                    color: catColor,
                                  ),
                                ),
                              ),
                              if (isSelected)
                                Positioned(
                                  right: -3,
                                  top: -3,
                                  child: Container(
                                    padding: const EdgeInsets.all(2),
                                    decoration: BoxDecoration(
                                      color: catColor,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      CupertinoIcons.checkmark,
                                      size: 10,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                              color: isSelected ? catColor : theme.colorScheme.onSurface,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                if (index == previewCategories.length) {
                  // "Khác" button -> opens full picker sheet
                  return ApplePressable(
                    scaleDown: 0.92,
                    onTap: onOpenMore,
                    child: SizedBox(
                      width: 58,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: isDark ? AppleTokens.bgDarkSecondary : AppleTokens.bgLightSecondary,
                              borderRadius: BorderRadius.circular(13),
                            ),
                            child: const Center(
                              child: Icon(
                                CupertinoIcons.ellipsis,
                                size: 20,
                                color: AppleTokens.systemBlue,
                              ),
                            ),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'Khác',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: AppleTokens.systemBlue,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                // Last item: "+ Thêm" button -> opens CategoryFormSheet directly
                return ApplePressable(
                  scaleDown: 0.92,
                  onTap: onCreateNew,
                  child: SizedBox(
                    width: 58,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: isDark ? AppleTokens.bgDarkSecondary : AppleTokens.bgLightSecondary,
                            borderRadius: BorderRadius.circular(13),
                            border: Border.all(
                              color: AppleTokens.jadePrimary.withValues(alpha: 0.4),
                              width: 1,
                            ),
                          ),
                          child: const Center(
                            child: Icon(
                              CupertinoIcons.plus,
                              size: 20,
                              color: AppleTokens.jadePrimary,
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Thêm',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppleTokens.jadePrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// Cupertino-styled Bottom Sheet for Picking a Wallet with Live Balances.
class _WalletPickerSheet extends StatelessWidget {
  const _WalletPickerSheet({
    required this.wallets,
    required this.selectedId,
    required this.locale,
    required this.title,
  });

  final List<Account> wallets;
  final String? selectedId;
  final String locale;
  final String title;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.72,
      ),
      decoration: BoxDecoration(
        color: isDark ? AppleTokens.bgDarkCard : Colors.white,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppleTokens.radiusSheet),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: SafeArea(
          top: false,
          child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag handle
            Container(
              margin: const EdgeInsets.symmetric(vertical: 10),
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: isDark ? Colors.white.withValues(alpha: 0.2) : Colors.black.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(CupertinoIcons.xmark_circle_fill, color: AppleTokens.systemGray),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            const Divider(height: AppleTokens.hairline),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                itemCount: wallets.length,
                separatorBuilder: (_, _) => const Divider(indent: 56, height: AppleTokens.hairline),
                itemBuilder: (context, index) {
                  final wallet = wallets[index];
                  final isSelected = wallet.id == selectedId;
                  final walletColor = Color(wallet.color);

                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    leading: AppleSquircleBadge(
                      icon: AppIconCatalog.resolve(wallet.icon),
                      backgroundColor: walletColor,
                      size: 40,
                      iconSize: 20,
                    ),
                    title: Text(
                      wallet.name,
                      style: TextStyle(
                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                    subtitle: Text(
                      wallet.balanceMoney.format(locale: locale),
                      style: TextStyle(
                        fontFeatures: AppTheme.tabularFigures,
                        color: isDark ? const Color(0xFF8E8E93) : const Color(0xFF6C6C70),
                      ),
                    ),
                    trailing: isSelected
                        ? const Icon(CupertinoIcons.checkmark_circle_fill, color: AppleTokens.jadePrimary)
                        : null,
                    onTap: () {
                      HapticFeedback.selectionClick();
                      Navigator.of(context).pop(wallet.id);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
      ),
    );
  }
}

/// Cupertino-styled Bottom Sheet for Category Picker with Search and Squircle Grid.
class _CategoryPickerSheet extends StatefulWidget {
  const _CategoryPickerSheet({
    required this.categories,
    required this.selectedId,
    this.onCreateNew,
  });

  final List<Category> categories;
  final String? selectedId;
  final VoidCallback? onCreateNew;

  @override
  State<_CategoryPickerSheet> createState() => _CategoryPickerSheetState();
}

class _CategoryPickerSheetState extends State<_CategoryPickerSheet> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final l10n = context.l10n;

    final filtered = widget.categories.where((cat) {
      if (_searchQuery.isEmpty) return true;
      final name = DefaultCategoryLocalization.resolveName(
        l10n,
        categoryId: cat.id,
        fallbackName: cat.name,
      ).toLowerCase();
      return name.contains(_searchQuery.toLowerCase());
    }).toList();

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.8,
      ),
      decoration: BoxDecoration(
        color: isDark ? AppleTokens.bgDarkCard : Colors.white,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppleTokens.radiusSheet),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: SafeArea(
          top: false,
          child: Column(
          children: [
            // Drag handle
            Container(
              margin: const EdgeInsets.symmetric(vertical: 10),
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: isDark ? Colors.white.withValues(alpha: 0.2) : Colors.black.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Chọn danh mục',
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                    ),
                  ),
                  if (widget.onCreateNew != null)
                    ApplePressable(
                      scaleDown: 0.94,
                      onTap: () {
                        Navigator.of(context).pop();
                        widget.onCreateNew!();
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        margin: const EdgeInsets.only(right: 6),
                        decoration: BoxDecoration(
                          color: AppleTokens.jadePrimary.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(AppleTokens.radiusPill),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(CupertinoIcons.plus, size: 13, color: AppleTokens.jadePrimary),
                            SizedBox(width: 3),
                            Text(
                              'Tạo mới',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppleTokens.jadePrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  IconButton(
                    icon: const Icon(CupertinoIcons.xmark_circle_fill, color: AppleTokens.systemGray),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),

            // Search Bar
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: CupertinoSearchTextField(
                placeholder: 'Tìm kiếm danh mục...',
                onChanged: (val) => setState(() => _searchQuery = val),
              ),
            ),

            const Divider(height: AppleTokens.hairline),

            // 4-Column Squircle Category Grid or Empty Search State
            Expanded(
              child: filtered.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            CupertinoIcons.search,
                            size: 40,
                            color: AppleTokens.systemGray,
                          ),
                          const SizedBox(height: 10),
                          const Text(
                            'Không tìm thấy danh mục',
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                          ),
                          if (widget.onCreateNew != null) ...[
                            const SizedBox(height: 12),
                            ApplePressable(
                              scaleDown: 0.94,
                              onTap: () {
                                Navigator.of(context).pop();
                                widget.onCreateNew!();
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                decoration: BoxDecoration(
                                  color: AppleTokens.jadePrimary,
                                  borderRadius: BorderRadius.circular(AppleTokens.radiusPill),
                                ),
                                child: const Text(
                                  '+ Tạo danh mục mới',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    )
                  : GridView.builder(
                padding: const EdgeInsets.all(16),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 12,
                  childAspectRatio: 0.8,
                ),
                itemCount: filtered.length,
                itemBuilder: (context, index) {
                  final cat = filtered[index];
                  final isSelected = cat.id == widget.selectedId;
                  final catColor = AppIconCatalog.contrastSafeColor(
                    Color(cat.color),
                    theme.brightness,
                  );
                  final name = DefaultCategoryLocalization.resolveName(
                    l10n,
                    categoryId: cat.id,
                    fallbackName: cat.name,
                  );

                  return ApplePressable(
                    scaleDown: 0.92,
                    onTap: () {
                      HapticFeedback.selectionClick();
                      Navigator.of(context).pop(cat.id);
                    },
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Stack(
                          clipBehavior: Clip.none,
                          children: [
                            Container(
                              width: 52,
                              height: 52,
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? catColor.withValues(alpha: 0.2)
                                    : (isDark ? AppleTokens.bgDarkSecondary : AppleTokens.bgLightSecondary),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: isSelected
                                      ? catColor
                                      : (isDark ? Colors.white.withValues(alpha: 0.1) : AppleTokens.borderLight),
                                  width: isSelected ? 2 : AppleTokens.hairline,
                                ),
                              ),
                              child: Center(
                                child: Icon(
                                  AppIconCatalog.resolve(cat.icon),
                                  size: 26,
                                  color: catColor,
                                ),
                              ),
                            ),
                            if (isSelected)
                              Positioned(
                                right: -4,
                                top: -4,
                                child: Container(
                                  padding: const EdgeInsets.all(2),
                                  decoration: const BoxDecoration(
                                    color: AppleTokens.jadePrimary,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    CupertinoIcons.checkmark,
                                    size: 12,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                            color: isSelected ? catColor : theme.colorScheme.onSurface,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      ),
    );
  }
}
