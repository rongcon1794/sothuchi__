import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:so_thu_chi/core/l10n/l10n_ext.dart';
import 'package:so_thu_chi/core/theme/apple_theme_tokens.dart';
import 'package:so_thu_chi/core/utils/money.dart';
import 'package:so_thu_chi/core/widgets/apple_kit.dart';
import 'package:so_thu_chi/features/accounts/presentation/controllers/accounts_controller.dart';
import 'package:so_thu_chi/features/debts/domain/entities/debt.dart';
import 'package:so_thu_chi/features/debts/presentation/controllers/debts_controller.dart';

class DebtRepaymentSheet extends ConsumerStatefulWidget {
  const DebtRepaymentSheet({super.key, required this.debt});

  final Debt debt;

  static Future<void> show(BuildContext context, Debt debt) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DebtRepaymentSheet(debt: debt),
    );
  }

  @override
  ConsumerState<DebtRepaymentSheet> createState() => _DebtRepaymentSheetState();
}

class _DebtRepaymentSheetState extends ConsumerState<DebtRepaymentSheet> {
  final _amountController = TextEditingController();
  String? _selectedAccountId;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _selectedAccountId = widget.debt.accountId;
    // Default to remaining amount
    _amountController.text = widget.debt.remainingAmount.toString();
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  void _setAmount(int amount) {
    HapticFeedback.selectionClick();
    setState(() {
      _amountController.text = amount.toString();
    });
  }

  Future<void> _submit() async {
    final rawAmount = int.tryParse(_amountController.text.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
    if (rawAmount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập số tiền hợp lệ lớn hơn 0')),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    await HapticFeedback.mediumImpact();

    final res = await ref.read(debtsActionControllerProvider.notifier).recordRepayment(
          debtId: widget.debt.id,
          amount: rawAmount,
          accountId: _selectedAccountId,
        );

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    res.fold(
      onSuccess: (_) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Đã ghi nhận trả ${Money(minorUnits: rawAmount, currencyCode: widget.debt.currency).format(locale: 'vi')}',
                  ),
                ),
              ],
            ),
            backgroundColor: AppleTokens.jadeDark,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppleTokens.radiusCard)),
          ),
        );
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
    final activeAccounts = ref.watch(activeAccountsProvider);

    final isLent = widget.debt.type == DebtType.lent;
    final title = isLent ? 'Thu hồi nợ từ ${widget.debt.personName}' : 'Trả nợ cho ${widget.debt.personName}';

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.88,
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        left: 20,
        right: 20,
        top: 16,
      ),
      decoration: BoxDecoration(
        color: isDark ? AppleTokens.bgDarkSecondary : AppleTokens.bgLightPrimary,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(AppleTokens.radiusHero)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
          // Cupertino Grabber
          Center(
            child: Container(
              width: 36,
              height: 5,
              decoration: BoxDecoration(
                color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(AppleTokens.radiusPill),
              ),
            ),
          ),
          const SizedBox(height: 16),

          Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Số tiền còn lại: ${widget.debt.remainingMoney.format(locale: 'vi')}',
            style: TextStyle(
              fontSize: 13,
              color: isLent ? AppleTokens.systemGreen : AppleTokens.systemOrange,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 20),

          // Amount text field
          AppleTextField(
            controller: _amountController,
            keyboardType: TextInputType.number,
            label: 'Số tiền trả (${widget.debt.currency})',
            clearable: true,
          ),
          const SizedBox(height: 10),

          // Quick Preset Pills
          Row(
            children: [
              Expanded(
                child: ApplePressable(
                  onTap: () => _setAmount(widget.debt.remainingAmount),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AppleTokens.systemBlue.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(AppleTokens.radiusPill),
                    ),
                    child: const Text(
                      'Trả toàn bộ',
                      style: TextStyle(
                        color: AppleTokens.systemBlue,
                        fontWeight: FontWeight.w600,
                        fontSize: 12.5,
                      ),
                    ),
                  ),
                ),
              ),
              if (widget.debt.remainingAmount > 100000) ...[
                const SizedBox(width: 8),
                Expanded(
                  child: ApplePressable(
                    onTap: () => _setAmount((widget.debt.remainingAmount / 2).round()),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(AppleTokens.radiusPill),
                      ),
                      child: const Text(
                        'Trả 50%',
                        style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12.5),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 16),

          // Linked wallet selector
          if (activeAccounts.isNotEmpty) ...[
            Text(
              isLent ? 'Nhận tiền vào ví:' : 'Thanh toán từ ví:',
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
            const SizedBox(height: 20),
          ],

          // Submit Button
          AppleButton.primary(
            label: isLent ? 'Xác nhận thu nợ' : 'Xác nhận trả nợ',
            color: isLent ? AppleTokens.systemGreen : AppleTokens.systemOrange,
            isLoading: _isSubmitting,
            onPressed: _submit,
          ),
        ],
        ),
      ),
    );
  }
}

