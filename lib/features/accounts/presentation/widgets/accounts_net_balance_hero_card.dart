import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:so_thu_chi/core/theme/app_theme.dart';
import 'package:so_thu_chi/core/theme/apple_theme_tokens.dart';
import 'package:so_thu_chi/core/utils/money.dart';
import 'package:so_thu_chi/core/widgets/apple_kit.dart';
import 'package:so_thu_chi/features/accounts/domain/entities/account.dart';
import 'package:so_thu_chi/l10n/app_localizations.dart';

/// Redesigned Apple Glass Hero Net Balance Card with Asset Allocation Telemetry.
class AccountsNetBalanceHeroCard extends StatelessWidget {
  const AccountsNetBalanceHeroCard({
    super.key,
    required this.totalBalance,
    required this.activeAccounts,
    required this.locale,
    required this.hideBalance,
    required this.l10n,
    required this.isDark,
    required this.onToggleHideBalance,
    required this.onOpenTransferSheet,
  });

  final Money totalBalance;
  final List<Account> activeAccounts;
  final String locale;
  final bool hideBalance;
  final AppLocalizations l10n;
  final bool isDark;
  final VoidCallback onToggleHideBalance;
  final VoidCallback onOpenTransferSheet;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isVi = locale.startsWith('vi');

    // Calculate asset allocation across categories for visual telemetry
    int totalCashMinor = 0;
    int totalBankMinor = 0;
    int totalEwalletMinor = 0;
    int totalCardMinor = 0;

    for (final acc in activeAccounts) {
      final bal = acc.balance;
      if (bal > 0) {
        switch (acc.type) {
          case AccountType.cash:
            totalCashMinor += bal;
            break;
          case AccountType.bank:
            totalBankMinor += bal;
            break;
          case AccountType.ewallet:
            totalEwalletMinor += bal;
            break;
          case AccountType.card:
            totalCardMinor += bal;
            break;
        }
      }
    }

    final positiveTotalMinor =
        totalCashMinor + totalBankMinor + totalEwalletMinor + totalCardMinor;

    return AppleGlassCard(
      padding: const EdgeInsets.all(18),
      borderRadius: BorderRadius.circular(AppleTokens.radiusHero),
      borderColor: isDark
          ? AppleTokens.jadePrimary.withValues(alpha: 0.30)
          : AppleTokens.jadePrimary.withValues(alpha: 0.22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // 1. Header: Shield Badge + Eyebrow + Count + Eye Toggle
          Row(
            children: [
              const AppleSquircleBadge(
                icon: CupertinoIcons.shield_fill,
                backgroundColor: AppleTokens.jadePrimary,
                size: 28,
                iconSize: 14,
                radius: 8,
              ),
              const SizedBox(width: 9),
              Flexible(
                child: Text(
                  l10n.totalBalance.toUpperCase(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.6,
                    color: isDark ? AppleTokens.jadePrimary : const Color(0xFF0F764A),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.08)
                      : Colors.black.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(AppleTokens.radiusPill),
                ),
                child: Text(
                  isVi
                      ? '${activeAccounts.length} ví'
                      : '${activeAccounts.length} wallets',
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white70 : const Color(0xFF1B5E20),
                  ),
                ),
              ),
              const Spacer(),
              IconButton(
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                alignment: Alignment.centerRight,
                tooltip: hideBalance ? l10n.showBalance : l10n.hideBalance,
                onPressed: () {
                  unawaited(HapticFeedback.selectionClick());
                  onToggleHideBalance();
                },
                icon: Icon(
                  hideBalance
                      ? CupertinoIcons.eye_slash
                      : CupertinoIcons.eye,
                  size: 20,
                  color: isDark ? Colors.white70 : Colors.black54,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // 2. Primary Big Balance Figure
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              totalBalance.format(locale: locale, masked: hideBalance),
              semanticsLabel: hideBalance ? l10n.balanceHidden : null,
              style: theme.textTheme.headlineMedium?.copyWith(
                fontSize: 32,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.8,
                fontFeatures: AppTheme.tabularFigures,
                color: isDark ? Colors.white : const Color(0xFF072711),
              ),
            ),
          ),
          const SizedBox(height: 14),

          // 3. Segmented Asset Distribution Telemetry
          if (positiveTotalMinor > 0 && !hideBalance) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(AppleTokens.radiusPill),
              child: SizedBox(
                height: 6,
                child: Row(
                  children: [
                    if (totalCashMinor > 0)
                      Expanded(
                        flex: totalCashMinor,
                        child: Container(color: AppleTokens.jadePrimary),
                      ),
                    if (totalBankMinor > 0)
                      Expanded(
                        flex: totalBankMinor,
                        child: Container(color: AppleTokens.systemBlue),
                      ),
                    if (totalEwalletMinor > 0)
                      Expanded(
                        flex: totalEwalletMinor,
                        child: Container(color: AppleTokens.systemTeal),
                      ),
                    if (totalCardMinor > 0)
                      Expanded(
                        flex: totalCardMinor,
                        child: Container(color: AppleTokens.systemPurple),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 12,
              runSpacing: 6,
              children: [
                if (totalCashMinor > 0)
                  _buildLegendItem(
                    color: AppleTokens.jadePrimary,
                    label: l10n.walletTypeCash,
                    percent: (totalCashMinor * 100 / positiveTotalMinor).round(),
                    isDark: isDark,
                  ),
                if (totalBankMinor > 0)
                  _buildLegendItem(
                    color: AppleTokens.systemBlue,
                    label: l10n.walletTypeBank,
                    percent: (totalBankMinor * 100 / positiveTotalMinor).round(),
                    isDark: isDark,
                  ),
                if (totalEwalletMinor > 0)
                  _buildLegendItem(
                    color: AppleTokens.systemTeal,
                    label: l10n.walletTypeEwallet,
                    percent: (totalEwalletMinor * 100 / positiveTotalMinor).round(),
                    isDark: isDark,
                  ),
                if (totalCardMinor > 0)
                  _buildLegendItem(
                    color: AppleTokens.systemPurple,
                    label: l10n.walletTypeCard,
                    percent: (totalCardMinor * 100 / positiveTotalMinor).round(),
                    isDark: isDark,
                  ),
              ],
            ),
          ],

          // 4. Quick Action Button: Transfer between wallets
          if (activeAccounts.length >= 2) ...[
            const SizedBox(height: 14),
            ApplePressable(
              onTap: onOpenTransferSheet,
              borderRadius: BorderRadius.circular(AppleTokens.radiusPill),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 12),
                decoration: BoxDecoration(
                  color: AppleTokens.systemBlue.withValues(alpha: isDark ? 0.22 : 0.10),
                  borderRadius: BorderRadius.circular(AppleTokens.radiusPill),
                  border: Border.all(
                    color: AppleTokens.systemBlue.withValues(alpha: 0.32),
                    width: 0.9,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.swap_horiz_rounded,
                      size: 16,
                      color: AppleTokens.systemBlue,
                    ),
                    const SizedBox(width: 5),
                    Flexible(
                      child: Text(
                        l10n.transferBetweenWallets,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppleTokens.systemBlue,
                          letterSpacing: -0.1,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLegendItem({
    required Color color,
    required String label,
    required int percent,
    required bool isDark,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 7,
          height: 7,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 4.5),
        Text(
          '$label $percent%',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: isDark ? Colors.white70 : const Color(0xFF48484A),
          ),
        ),
      ],
    );
  }
}

