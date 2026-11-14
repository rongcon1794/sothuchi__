import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:so_thu_chi/core/theme/apple_theme_tokens.dart';
import 'package:so_thu_chi/core/widgets/apple_kit.dart';
import 'package:so_thu_chi/features/accounts/domain/entities/account.dart';
import 'package:so_thu_chi/l10n/app_localizations.dart';

/// Horizontal filter pills for filtering wallets by type (All, Cash, Bank, E-wallet, Card).
class AccountsTypeFilterPills extends StatelessWidget {
  const AccountsTypeFilterPills({
    super.key,
    required this.activeAccounts,
    required this.selectedTypeFilter,
    required this.isDark,
    required this.l10n,
    required this.onSelectFilter,
  });

  final List<Account> activeAccounts;
  final AccountType? selectedTypeFilter;
  final bool isDark;
  final AppLocalizations l10n;
  final ValueChanged<AccountType?> onSelectFilter;

  @override
  Widget build(BuildContext context) {
    final filters = [
      (
        type: null,
        icon: CupertinoIcons.square_grid_2x2,
        label: '${l10n.localeName.startsWith('vi') ? 'Tất cả' : 'All'} (${activeAccounts.length})'
      ),
      (
        type: AccountType.cash,
        icon: Icons.payments_rounded,
        label:
            '${l10n.walletTypeCash} (${activeAccounts.where((a) => a.type == AccountType.cash).length})'
      ),
      (
        type: AccountType.bank,
        icon: Icons.account_balance_rounded,
        label:
            '${l10n.walletTypeBank} (${activeAccounts.where((a) => a.type == AccountType.bank).length})'
      ),
      (
        type: AccountType.ewallet,
        icon: Icons.qr_code_2_rounded,
        label:
            '${l10n.walletTypeEwallet} (${activeAccounts.where((a) => a.type == AccountType.ewallet).length})'
      ),
      (
        type: AccountType.card,
        icon: Icons.credit_card_rounded,
        label:
            '${l10n.walletTypeCard} (${activeAccounts.where((a) => a.type == AccountType.card).length})'
      ),
    ];

    return SizedBox(
      height: 38,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: filters.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final f = filters[index];
          final isSelected = selectedTypeFilter == f.type;
          return ApplePressable(
            onTap: () {
              unawaited(HapticFeedback.selectionClick());
              onSelectFilter(f.type);
            },
            borderRadius: BorderRadius.circular(AppleTokens.radiusPill),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: isSelected
                    ? (isDark ? Colors.white : const Color(0xFF1C1C1E))
                    : (isDark
                        ? Colors.white.withValues(alpha: 0.08)
                        : Colors.white.withValues(alpha: 0.85)),
                borderRadius: BorderRadius.circular(AppleTokens.radiusPill),
                border: Border.all(
                  color: isSelected
                      ? Colors.transparent
                      : (isDark
                          ? Colors.white.withValues(alpha: 0.12)
                          : AppleTokens.borderLight),
                  width: 0.8,
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.08),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : null,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    f.icon,
                    size: 14,
                    color: isSelected
                        ? (isDark ? Colors.black : Colors.white)
                        : (isDark ? Colors.white70 : Colors.black87),
                  ),
                  const SizedBox(width: 5),
                  Text(
                    f.label,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                      color: isSelected
                          ? (isDark ? Colors.black : Colors.white)
                          : (isDark ? Colors.white70 : Colors.black87),
                      height: 1.2,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

