import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:so_thu_chi/core/constants/currency_constants.dart';
import 'package:so_thu_chi/core/constants/icon_catalog.dart';
import 'package:so_thu_chi/core/contracts/transaction_draft_contract.dart';
import 'package:so_thu_chi/core/l10n/l10n_ext.dart';
import 'package:so_thu_chi/core/responsive/apple_responsive.dart';
import 'package:so_thu_chi/core/theme/app_theme.dart';
import 'package:so_thu_chi/core/theme/apple_theme_tokens.dart';
import 'package:so_thu_chi/core/utils/date_formatter.dart';
import 'package:so_thu_chi/core/utils/money.dart';
import 'package:so_thu_chi/core/widgets/apple_kit.dart';
import 'package:so_thu_chi/features/accounts/domain/entities/account.dart';
import 'package:so_thu_chi/features/accounts/presentation/controllers/accounts_controller.dart';
import 'package:so_thu_chi/features/accounts/presentation/widgets/wallet_form_sheet.dart';
import 'package:so_thu_chi/features/budgets/presentation/controllers/budgets_controller.dart';
import 'package:so_thu_chi/features/categories/domain/entities/category.dart';
import 'package:so_thu_chi/features/categories/presentation/controllers/categories_controller.dart';
import 'package:so_thu_chi/features/categories/presentation/widgets/category_form_sheet.dart';
import 'package:so_thu_chi/features/settings/presentation/controllers/settings_controller.dart';
import 'package:so_thu_chi/features/transactions/domain/entities/transaction_entity.dart';
import 'package:so_thu_chi/features/transactions/presentation/controllers/transactions_controller.dart';
import 'package:so_thu_chi/features/transactions/presentation/widgets/transaction_category_picker_section.dart';
import 'package:so_thu_chi/features/transactions/presentation/widgets/transaction_hero_amount_card.dart';
import 'package:so_thu_chi/features/transactions/presentation/widgets/transaction_smart_note_section.dart';
import 'package:so_thu_chi/features/transactions/presentation/widgets/transaction_smart_tags_section.dart';
import 'package:so_thu_chi/features/transactions/presentation/widgets/transaction_wallet_picker_sheet.dart';

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
  final _amountFocusNode = FocusNode();
  final _noteController = TextEditingController();
  final _tagsController = TextEditingController();
  final _tagInputController = TextEditingController();
  final List<String> _selectedTags = [];

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
        _selectedTags.addAll(draft.tags);
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
      _scheduleAutoFocus();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          ref.read(categoriesActionControllerProvider.notifier).seedDefaultsIfNeeded();
        }
      });
    }
  }

  void _scheduleAutoFocus() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _isEditing) return;

      final modalRoute = ModalRoute.of(context);
      if (modalRoute != null &&
          modalRoute.animation != null &&
          !modalRoute.animation!.isCompleted) {
        void onAnimationCompleted(AnimationStatus status) {
          if (status == AnimationStatus.completed) {
            modalRoute.animation?.removeStatusListener(onAnimationCompleted);
            if (mounted && !_isEditing) {
              _requestAmountFocus();
            }
          }
        }

        modalRoute.animation!.addStatusListener(onAnimationCompleted);
      } else {
        _requestAmountFocus();
      }
    });
  }

  void _requestAmountFocus() {
    if (!mounted || _isEditing) return;
    if (!_amountFocusNode.hasFocus) {
      _amountFocusNode.requestFocus();
    }
    if (_amountController.text.isNotEmpty) {
      _amountController.selection = TextSelection.collapsed(
        offset: _amountController.text.length,
      );
    }
    SystemChannels.textInput.invokeMethod<void>('TextInput.show');
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
        _selectedTags.clear();
        _selectedTags.addAll(tx.tags);
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
    _amountFocusNode.dispose();
    _noteController.dispose();
    _tagsController.dispose();
    _tagInputController.dispose();
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

  void _clearAmount() {
    HapticFeedback.lightImpact();
    setState(() {
      _amountController.clear();
    });
  }

  void _setAmount(int minorUnits, String currencyCode, String locale) {
    HapticFeedback.lightImpact();
    final newText = Money(
      minorUnits: minorUnits,
      currencyCode: currencyCode,
    ).toInputString(locale: locale);
    setState(() {
      _amountController.text = newText;
    });
  }

  void _addTag(String raw) {
    final clean = raw.trim().replaceAll('#', '');
    if (clean.isNotEmpty && !_selectedTags.contains(clean)) {
      setState(() {
        _selectedTags.add(clean);
        _tagsController.text = _selectedTags.join(', ');
      });
      _tagInputController.clear();
      HapticFeedback.lightImpact();
    }
  }

  void _removeTag(String tag) {
    setState(() {
      _selectedTags.remove(tag);
      _tagsController.text = _selectedTags.join(', ');
    });
    HapticFeedback.lightImpact();
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
    final l10n = context.l10n;
    final selectedId = isDestination ? _toAccountId : _accountId;
    final result = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => TransactionWalletPickerSheet(
        wallets: wallets,
        selectedId: selectedId,
        defaultWalletId:
            ref.read(settingsControllerProvider).value?.defaultWalletId,
        locale: locale,
        title: isDestination
            ? (locale.startsWith('vi') ? 'Chọn ví nhận tiền' : l10n.txDestWallet)
            : (locale.startsWith('vi') ? 'Chọn ví thanh toán' : l10n.txSelectWallet),
        onCreateNew: () => _createNewWallet(isDestination: isDestination),
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

  Future<void> _createNewWallet({bool isDestination = false}) async {
    final created = await WalletFormSheet.show(context);
    if (created != null && mounted) {
      setState(() {
        if (isDestination) {
          _toAccountId = created.id;
        } else {
          _accountId = created.id;
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
      builder: (ctx) => TransactionCategoryPickerSheet(
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

    if (_tagInputController.text.trim().isNotEmpty) {
      final clean = _tagInputController.text.trim().replaceAll('#', '');
      if (clean.isNotEmpty && !_selectedTags.contains(clean)) {
        _selectedTags.add(clean);
      }
    }

    final tags = _selectedTags.isNotEmpty
        ? List<String>.from(_selectedTags)
        : _tagsController.text
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
    final isLandscape = context.isLandscape;
    final isWide = context.isWideScreen;
    final appBarHeight = isLandscape
        ? AppleTokens.appBarHeightLandscape
        : AppleTokens.appBarHeightPortrait;
    final scrollBottomPadding = isWide
        ? AppleTokens.scrollBottomPaddingLandscape + 40
        : 120.0;

    final activeWallets = ref.watch(activeAccountsProvider);
    final allWallets = ref.watch(accountsStreamProvider).value ?? const [];
    final walletsForDropdown = _isEditing ? allWallets : activeWallets;

    // Source wallet balance for Lucian Element #035 Balance Shield
    final sourceWallet = walletsForDropdown
        .where((w) => w.id == _accountId)
        .firstOrNull;
    final availableBalance = sourceWallet?.balanceMoney;

    final expenseCategories = ref.watch(expenseCategoriesProvider);
    final incomeCategories = ref.watch(incomeCategoriesProvider);
    final categoriesAsync = ref.watch(categoriesStreamProvider);
    final availableCategories = _type == TransactionType.income
        ? incomeCategories
        : expenseCategories;

    // Auto-select sensible default wallet on first render
    if (!_initializedDefaults && !_isEditing) {
      if (_accountId == null && walletsForDropdown.isNotEmpty) {
        final defaultWalletId =
            ref.read(settingsControllerProvider).value?.defaultWalletId;
        final matched = walletsForDropdown
            .where((w) => w.id == defaultWalletId)
            .firstOrNull;
        _accountId = matched?.id ?? walletsForDropdown.first.id;
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
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        toolbarHeight: appBarHeight,
        title: Text(
          _isEditing ? l10n.editTransaction : l10n.addTransaction,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(CupertinoIcons.chevron_left, size: 24),
          tooltip: l10n.back,
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
      body: SafeArea(
        top: false,
        bottom: false,
        child: _loadingExisting
            ? const Center(child: CupertinoActivityIndicator())
            : Form(
              key: _formKey,
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: AppleTokens.maxDetailWidth),
                  child: SingleChildScrollView(
                    padding: EdgeInsets.fromLTRB(16, 8, 16, scrollBottomPadding),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // 1. Hero Amount & Mode Card
                        RepaintBoundary(
                          child: TransactionHeroAmountCard(
                            type: _type,
                            amountController: _amountController,
                            focusNode: _amountFocusNode,
                            currencyInfo: currencyInfo,
                            currencyCode: currencyCode,
                            locale: locale,
                            isEditing: _isEditing,
                            availableWalletBalance: availableBalance,
                            onTypeChanged: (newType) {
                              setState(() {
                                _type = newType;
                                if (newType != TransactionType.transfer) {
                                  final list = newType == TransactionType.income
                                      ? incomeCategories
                                      : expenseCategories;
                                  if (!list.any((c) => c.id == _categoryId)) {
                                    _categoryId =
                                        list.isNotEmpty ? list.first.id : null;
                                  }
                                }
                              });
                            },
                            onSetAmount: (amount) =>
                                _setAmount(amount, currencyCode, locale),
                            onClear: _clearAmount,
                          ),
                        ),
                        const SizedBox(height: 12),

                        // 2. Category Selection Section (Only for Expense & Income)
                        if (_type != TransactionType.transfer) ...[
                          if (availableCategories.isNotEmpty) ...[
                            RepaintBoundary(
                              child: TransactionCategorySelectionCard(
                                categories: availableCategories,
                                selectedId: _categoryId,
                                selectedCategory: selectedCategory,
                                onSelected: (id) {
                                  HapticFeedback.selectionClick();
                                  setState(() => _categoryId = id);
                                },
                                onOpenMore: () => _openCategoryPicker(
                                  context,
                                  categories: availableCategories,
                                ),
                                onCreateNew: () =>
                                    _openCreateCategorySheet(context),
                              ),
                            ),
                            const SizedBox(height: 12),
                    ] else if (categoriesAsync.isLoading) ...[
                      AppleGlassCard(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                        borderRadius: BorderRadius.circular(AppleTokens.radiusCard),
                        borderColor: isDark
                            ? Colors.white.withValues(alpha: 0.10)
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
                      const SizedBox(height: 12),
                    ] else ...[
                      // Empty state: Auto-seed and provide manual recovery options
                      AppleGlassCard(
                        padding: const EdgeInsets.all(16),
                        borderRadius: BorderRadius.circular(AppleTokens.radiusCard),
                        borderColor: isDark
                            ? Colors.white.withValues(alpha: 0.10)
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
                                    size: 18,
                                    color: AppleTokens.systemOrange,
                                  ),
                                ),
                                const SizedBox(width: 12),
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
                                        l10n.noCategories,
                                        style: const TextStyle(
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
                            Text(
                              l10n.noCategoriesDescription,
                              style: const TextStyle(
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
                                      child: Text(
                                        l10n.restoreDefaultCategories,
                                        style: const TextStyle(
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
                                        color: theme.colorScheme.primary.withValues(alpha: 0.15),
                                        borderRadius: BorderRadius.circular(AppleTokens.radiusPill),
                                      ),
                                      child: Text(
                                        '+ ${l10n.txCategoryAdd}',
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                          color: theme.colorScheme.primary,
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
                      const SizedBox(height: 12),
                    ],
                  ],

                  // 3. Unified Wallet & Date Selection Card
                  RepaintBoundary(
                    child: AppleGlassCard(
                    padding: EdgeInsets.zero,
                    borderRadius: BorderRadius.circular(AppleTokens.radiusCard),
                    borderColor: isDark
                        ? Colors.white.withValues(alpha: 0.10)
                        : AppleTokens.borderLight,
                    child: Column(
                      children: [
                        if (_type == TransactionType.transfer) ...[
                          // Source Wallet (From)
                          ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
                            leading: const AppleSquircleBadge(
                              icon: CupertinoIcons.arrow_up_right,
                              backgroundColor: AppleTokens.systemOrange,
                              size: 36,
                              iconSize: 18,
                              radius: 10,
                            ),
                            title: Text(
                              l10n.fromWallet,
                              style: const TextStyle(fontSize: 12, color: AppleTokens.systemGray, fontWeight: FontWeight.w500),
                            ),
                            subtitle: Text(
                              selectedAccount != null
                                  ? '${selectedAccount.name} (${selectedAccount.balanceMoney.format(locale: locale)})'
                                  : l10n.txSourceWallet,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
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
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Divider(
                                    height: AppleTokens.hairline,
                                    color: isDark ? AppleTokens.separatorDark : AppleTokens.separatorLight,
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                                  child: ApplePressable(
                                    scaleDown: 0.92,
                                    onTap: _swapTransferWallets,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: isDark ? AppleTokens.bgDarkSecondary : AppleTokens.bgLightSecondary,
                                        borderRadius: BorderRadius.circular(AppleTokens.radiusPill),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(CupertinoIcons.arrow_2_squarepath, size: 13, color: AppleTokens.systemBlue),
                                          const SizedBox(width: 5),
                                          Text(
                                            l10n.txSwapWallets,
                                            style: const TextStyle(
                                              fontSize: 11.5,
                                              fontWeight: FontWeight.w600,
                                              color: AppleTokens.systemBlue,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: Divider(
                                    height: AppleTokens.hairline,
                                    color: isDark ? AppleTokens.separatorDark : AppleTokens.separatorLight,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Destination Wallet (To)
                          ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
                            leading: const AppleSquircleBadge(
                              icon: CupertinoIcons.arrow_down_left,
                              backgroundColor: AppleTokens.systemGreen,
                              size: 36,
                              iconSize: 18,
                              radius: 10,
                            ),
                            title: Text(
                              l10n.toWallet,
                              style: const TextStyle(fontSize: 12, color: AppleTokens.systemGray, fontWeight: FontWeight.w500),
                            ),
                            subtitle: Text(
                              selectedToAccount != null
                                  ? '${selectedToAccount.name} (${selectedToAccount.balanceMoney.format(locale: locale)})'
                                  : l10n.txDestWallet,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
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
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
                            leading: AppleSquircleBadge(
                              icon: selectedAccount != null
                                  ? AppIconCatalog.resolve(selectedAccount.icon)
                                  : CupertinoIcons.creditcard,
                              backgroundColor: selectedAccount != null
                                  ? Color(selectedAccount.color)
                                  : AppleTokens.systemBlue,
                              size: 36,
                              iconSize: 18,
                              radius: 10,
                            ),
                            title: Text(
                              l10n.walletsTitle,
                              style: const TextStyle(fontSize: 12, color: AppleTokens.systemGray, fontWeight: FontWeight.w500),
                            ),
                            subtitle: Text(
                              selectedAccount != null
                                  ? '${selectedAccount.name} (${selectedAccount.balanceMoney.format(locale: locale)})'
                                  : l10n.txSelectWallet,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
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
                        Divider(
                          height: AppleTokens.hairline,
                          indent: 64,
                          color: isDark ? AppleTokens.separatorDark : AppleTokens.separatorLight,
                        ),
                        // Date Selector Row
                        ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
                          leading: const AppleSquircleBadge(
                            icon: CupertinoIcons.calendar,
                            backgroundColor: AppleTokens.systemBlue,
                            size: 36,
                            iconSize: 18,
                            radius: 10,
                          ),
                          title: Text(
                            l10n.date,
                            style: const TextStyle(fontSize: 12, color: AppleTokens.systemGray, fontWeight: FontWeight.w500),
                          ),
                          subtitle: Text(
                            formattedSelectedDate,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
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
                                      ? l10n.today
                                      : l10n.edit,
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
                      ],
                    ),
                  ),
                  ),
                  const SizedBox(height: 12),

                  // 4. Unified Note & Tags Card
                  RepaintBoundary(
                    child: AppleGlassCard(
                      padding: EdgeInsets.zero,
                      borderRadius: BorderRadius.circular(AppleTokens.radiusCard),
                      borderColor: isDark
                          ? Colors.white.withValues(alpha: 0.10)
                          : AppleTokens.borderLight,
                      child: Column(
                        children: [
                          // Note Input Section
                          TransactionSmartNoteSection(
                            noteController: _noteController,
                            type: _type,
                            selectedCategory: selectedCategory,
                            isDark: isDark,
                          ),
                          Divider(
                            height: AppleTokens.hairline,
                            indent: 64,
                            color: isDark ? AppleTokens.separatorDark : AppleTokens.separatorLight,
                          ),
                          // Tags Input Section
                          TransactionSmartTagsSection(
                            selectedTags: _selectedTags,
                            tagInputController: _tagInputController,
                            onAddTag: _addTag,
                            onRemoveTag: _removeTag,
                            isDark: isDark,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
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
          child: Center(
            heightFactor: 1.0,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 860),
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  16,
                  isLandscape ? 4 : 10,
                  16,
                  isLandscape ? 6 : 12,
                ),
                child: AppleButton.primary(
                  height: isLandscape ? 40 : 50,
                  borderRadius: BorderRadius.circular(AppleTokens.radiusPill),
                  isLoading: isSaving,
                  icon: CupertinoIcons.checkmark_alt,
                  label: _isEditing ? l10n.editTransaction : l10n.save,
                  color: theme.colorScheme.primary,
                  onPressed: isSaving ? null : _submit,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
