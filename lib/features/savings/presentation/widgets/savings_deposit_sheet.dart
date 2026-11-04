import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:so_thu_chi/core/l10n/l10n_ext.dart';
import 'package:so_thu_chi/core/theme/apple_theme_tokens.dart';
import 'package:so_thu_chi/core/utils/money.dart';
import 'package:so_thu_chi/features/accounts/presentation/controllers/accounts_controller.dart';
import 'package:so_thu_chi/features/savings/domain/entities/savings_goal.dart';
import 'package:so_thu_chi/features/savings/presentation/controllers/savings_goals_controller.dart';

class SavingsDepositSheet extends ConsumerStatefulWidget {
  const SavingsDepositSheet({
    super.key,
    required this.goal,
    this.isWithdraw = false,
  });

  final SavingsGoal goal;
  final bool isWithdraw;

  static Future<void> show(
    BuildContext context, {
    required SavingsGoal goal,
    bool isWithdraw = false,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => SavingsDepositSheet(goal: goal, isWithdraw: isWithdraw),
    );
  }

  @override
  ConsumerState<SavingsDepositSheet> createState() => _SavingsDepositSheetState();
}

class _SavingsDepositSheetState extends ConsumerState<SavingsDepositSheet> {
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  late bool _isWithdraw;
  String? _selectedAccountId;

  @override
  void initState() {
    super.initState();
    _isWithdraw = widget.isWithdraw;
    _selectedAccountId = widget.goal.linkedAccountId;
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  void _applyQuickAmount(int minorUnits) {
    HapticFeedback.selectionClick();
    final money = Money(minorUnits: minorUnits, currencyCode: widget.goal.currency);
    _amountController.text = money.toInputString();
  }

  Future<void> _submit() async {
    final messenger = ScaffoldMessenger.of(context);
    final wallets = ref.read(activeAccountsProvider);
    final currency = widget.goal.currency;
    final parsed = Money.tryParse(_amountController.text, currencyCode: currency);

    if (parsed == null || parsed.minorUnits <= 0) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập số tiền hợp lệ')),
      );
      return;
    }

    if (_selectedAccountId == null || _selectedAccountId!.isEmpty) {
      if (wallets.isEmpty) {
        messenger.showSnackBar(
          const SnackBar(content: Text('Chưa có ví nào khả dụng')),
        );
        return;
      }
      _selectedAccountId = wallets.first.id;
    }

    unawaited(HapticFeedback.mediumImpact());
    final actionNotifier = ref.read(savingsGoalsActionControllerProvider.notifier);

    final res = _isWithdraw
        ? await actionNotifier.withdrawFromGoal(
            goalId: widget.goal.id,
            amount: parsed.minorUnits,
            toAccountId: _selectedAccountId!,
            note: _noteController.text.trim(),
          )
        : await actionNotifier.depositToGoal(
            goalId: widget.goal.id,
            amount: parsed.minorUnits,
            fromAccountId: _selectedAccountId!,
            note: _noteController.text.trim(),
          );

    if (!mounted) return;
    res.fold(
      onSuccess: (_) {
        unawaited(HapticFeedback.lightImpact());
        Navigator.of(context).pop();
        messenger.showSnackBar(
          SnackBar(
            content: Text(
              _isWithdraw
                  ? 'Đã rút ${parsed.format(locale: 'vi')} từ ${widget.goal.title}'
                  : 'Đã tích lũy thêm ${parsed.format(locale: 'vi')} vào ${widget.goal.title}!',
            ),
            backgroundColor: Color(widget.goal.color),
          ),
        );
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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final wallets = ref.watch(activeAccountsProvider);

    if (_selectedAccountId == null && wallets.isNotEmpty) {
      _selectedAccountId = wallets.first.id;
    }

    final accentColor = Color(widget.goal.color);

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
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

              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 16, 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _isWithdraw ? 'Rút tiền tiết kiệm' : 'Tích lũy vào heo đất',
                          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        Text(
                          widget.goal.title,
                          style: const TextStyle(fontSize: 13, color: AppleTokens.systemGray),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(CupertinoIcons.xmark_circle_fill, color: AppleTokens.systemGray),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),

              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  children: [
                    // Mode selector pill (Deposit vs Withdraw)
                    Container(
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        color: isDark ? AppleTokens.bgDarkSecondary : AppleTokens.bgLightSecondary,
                        borderRadius: BorderRadius.circular(AppleTokens.radiusControl),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () {
                                HapticFeedback.selectionClick();
                                setState(() => _isWithdraw = false);
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 8),
                                decoration: BoxDecoration(
                                  color: !_isWithdraw ? (isDark ? AppleTokens.bgDarkCard : Colors.white) : Colors.transparent,
                                  borderRadius: BorderRadius.circular(AppleTokens.radiusControl - 2),
                                  boxShadow: !_isWithdraw
                                      ? [
                                          BoxShadow(
                                            color: Colors.black.withValues(alpha: 0.08),
                                            blurRadius: 4,
                                            offset: const Offset(0, 1),
                                          )
                                        ]
                                      : null,
                                ),
                                child: Center(
                                  child: Text(
                                    'Nạp tích lũy',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 14,
                                      color: !_isWithdraw ? accentColor : AppleTokens.systemGray,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            child: GestureDetector(
                              onTap: () {
                                HapticFeedback.selectionClick();
                                setState(() => _isWithdraw = true);
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 8),
                                decoration: BoxDecoration(
                                  color: _isWithdraw ? (isDark ? AppleTokens.bgDarkCard : Colors.white) : Colors.transparent,
                                  borderRadius: BorderRadius.circular(AppleTokens.radiusControl - 2),
                                  boxShadow: _isWithdraw
                                      ? [
                                          BoxShadow(
                                            color: Colors.black.withValues(alpha: 0.08),
                                            blurRadius: 4,
                                            offset: const Offset(0, 1),
                                          )
                                        ]
                                      : null,
                                ),
                                child: Center(
                                  child: Text(
                                    'Rút tiền',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 14,
                                      color: _isWithdraw ? AppleTokens.rubyExpense : AppleTokens.systemGray,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Amount input
                    TextFormField(
                      controller: _amountController,
                      keyboardType: TextInputType.number,
                      autofocus: true,
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                      decoration: InputDecoration(
                        labelText: _isWithdraw ? 'Số tiền rút' : 'Số tiền nạp',
                        prefixIcon: const Icon(CupertinoIcons.money_dollar_circle),
                        suffixText: widget.goal.currency,
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Quick Chips
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        if (!_isWithdraw) ...[
                          ActionChip(
                            label: const Text('+100k'),
                            onPressed: () => _applyQuickAmount(100000),
                          ),
                          ActionChip(
                            label: const Text('+500k'),
                            onPressed: () => _applyQuickAmount(500000),
                          ),
                          ActionChip(
                            label: const Text('+1 Triệu'),
                            onPressed: () => _applyQuickAmount(1000000),
                          ),
                          if (widget.goal.remainingAmount > 0)
                            ActionChip(
                              label: const Text('Phần còn thiếu'),
                              backgroundColor: accentColor.withValues(alpha: 0.15),
                              onPressed: () => _applyQuickAmount(widget.goal.remainingAmount),
                            ),
                        ] else ...[
                          if (widget.goal.currentAmount > 0)
                            ActionChip(
                              label: const Text('Rút toàn bộ'),
                              backgroundColor: AppleTokens.rubyExpense.withValues(alpha: 0.15),
                              onPressed: () => _applyQuickAmount(widget.goal.currentAmount),
                            ),
                          ActionChip(
                            label: const Text('500k'),
                            onPressed: () => _applyQuickAmount(500000),
                          ),
                          ActionChip(
                            label: const Text('1 Triệu'),
                            onPressed: () => _applyQuickAmount(1000000),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Target wallet selection
                    DropdownButtonFormField<String>(
                      initialValue: _selectedAccountId,
                      decoration: InputDecoration(
                        labelText: _isWithdraw ? 'Ví nhận tiền' : 'Ví trích tiền nạp',
                        prefixIcon: const Icon(CupertinoIcons.creditcard),
                      ),
                      items: wallets.map((w) {
                        return DropdownMenuItem(
                          value: w.id,
                          child: Text('${w.name} (${w.balanceMoney.format(locale: 'vi')})', overflow: TextOverflow.ellipsis),
                        );
                      }).toList(),
                      onChanged: (val) => setState(() => _selectedAccountId = val),
                    ),
                    const SizedBox(height: 14),

                    // Note input
                    TextFormField(
                      controller: _noteController,
                      decoration: const InputDecoration(
                        labelText: 'Ghi chú (Tùy chọn)',
                        prefixIcon: Icon(CupertinoIcons.pencil),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Submit button
                    FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: _isWithdraw ? AppleTokens.rubyExpense : accentColor,
                        minimumSize: const Size.fromHeight(50),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppleTokens.radiusControl)),
                      ),
                      onPressed: _submit,
                      child: Text(
                        _isWithdraw ? 'Xác nhận rút tiền' : 'Xác nhận tích lũy',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
