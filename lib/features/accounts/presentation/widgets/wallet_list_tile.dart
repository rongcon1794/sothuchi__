import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:so_thu_chi/core/constants/icon_catalog.dart';
import 'package:so_thu_chi/core/l10n/l10n_ext.dart';
import 'package:so_thu_chi/core/theme/app_theme.dart';
import 'package:so_thu_chi/core/theme/apple_theme_tokens.dart';
import 'package:so_thu_chi/core/widgets/apple_kit.dart';
import 'package:so_thu_chi/features/accounts/domain/entities/account.dart';

class WalletListTile extends StatelessWidget {
  const WalletListTile({
    super.key,
    required this.account,
    required this.typeLabel,
    required this.locale,
    required this.hideBalance,
    required this.onTap,
    required this.onEdit,
    required this.onToggleArchive,
    this.isDefault = false,
    this.onSetDefault,
  });

  final Account account;
  final String typeLabel;
  final String locale;
  final bool hideBalance;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onToggleArchive;
  final bool isDefault;
  final VoidCallback? onSetDefault;

  IconData _typeIcon(AccountType type) {
    switch (type) {
      case AccountType.cash:
        return Icons.payments_rounded;
      case AccountType.bank:
        return Icons.account_balance_rounded;
      case AccountType.ewallet:
        return Icons.qr_code_2_rounded;
      case AccountType.card:
        return Icons.credit_card_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final l10n = context.l10n;
    final walletColor = AppIconCatalog.contrastSafeColor(
      Color(account.color),
      theme.brightness,
    );
    final balanceText = account.balanceMoney.format(
      locale: locale,
      masked: hideBalance,
    );

    return ApplePressable(
      borderRadius: BorderRadius.circular(AppleTokens.radiusHero),
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppleTokens.radiusHero),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              isDark
                  ? Color.lerp(walletColor, const Color(0xFF1E1E22), 0.82)!
                  : Color.lerp(walletColor, Colors.white, 0.90)!,
              isDark
                  ? const Color(0xFF141416)
                  : Color.lerp(walletColor, const Color(0xFFF7F8FA), 0.96)!,
            ],
          ),
          border: Border.all(
            color: isDefault
                ? const Color(0xFFFFB800).withValues(alpha: isDark ? 0.65 : 0.55)
                : walletColor.withValues(alpha: isDark ? 0.35 : 0.22),
            width: isDefault ? 1.4 : 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: isDefault
                  ? const Color(0xFFFFB800).withValues(alpha: isDark ? 0.16 : 0.08)
                  : walletColor.withValues(alpha: isDark ? 0.18 : 0.07),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppleTokens.radiusHero),
          child: Stack(
            children: [
              // Subtle ambient radiant glow at top-right
              Positioned(
                right: -24,
                top: -30,
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        walletColor.withValues(alpha: isDark ? 0.22 : 0.12),
                        walletColor.withValues(alpha: 0.0),
                      ],
                    ),
                  ),
                ),
              ),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // --- Tier 1: Identity, Badges, and Overflow Actions ---
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Squircle Icon Badge with high-gloss gradient & shadow
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                walletColor,
                                Color.lerp(
                                  walletColor,
                                  Colors.black,
                                  isDark ? 0.35 : 0.2,
                                )!,
                              ],
                            ),
                            borderRadius: BorderRadius.circular(13),
                            border: Border.all(
                              color: Colors.white.withValues(
                                alpha: isDark ? 0.3 : 0.45,
                              ),
                              width: 1.0,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: walletColor.withValues(
                                  alpha: isDark ? 0.4 : 0.25,
                                ),
                                blurRadius: 10,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Icon(
                            AppIconCatalog.resolve(account.icon),
                            color: Colors.white,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 12),

                        // Wallet Name & Tags (Type, Currency, Default)
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                account.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 16.5,
                                  letterSpacing: -0.2,
                                  decoration: account.archived
                                      ? TextDecoration.lineThrough
                                      : null,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Wrap(
                                spacing: 5,
                                runSpacing: 4,
                                crossAxisAlignment: WrapCrossAlignment.center,
                                children: [
                                  // Wallet Type Pill with Icon
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 3.5,
                                    ),
                                    alignment: Alignment.center,
                                    decoration: BoxDecoration(
                                      color: walletColor.withValues(
                                        alpha: isDark ? 0.20 : 0.12,
                                      ),
                                      borderRadius: BorderRadius.circular(
                                        AppleTokens.radiusPill,
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.center,
                                      children: [
                                        Icon(
                                          _typeIcon(account.type),
                                          size: 11,
                                          color: isDark
                                              ? Colors.white70
                                              : walletColor,
                                        ),
                                        const SizedBox(width: 3.5),
                                        Text(
                                          typeLabel,
                                          style: TextStyle(
                                            fontSize: 10.5,
                                            fontWeight: FontWeight.w600,
                                            color: isDark
                                                ? Colors.white70
                                                : walletColor,
                                            height: 1.2,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),

                                  // Default Wallet Badge
                                  if (isDefault)
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 3.5,
                                      ),
                                      alignment: Alignment.center,
                                      decoration: BoxDecoration(
                                        gradient: const LinearGradient(
                                          colors: [
                                            Color(0xFFFFDF7A),
                                            Color(0xFFD4AF37),
                                          ],
                                        ),
                                        borderRadius: BorderRadius.circular(
                                          AppleTokens.radiusPill,
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: const Color(0xFFD4AF37)
                                                .withValues(alpha: 0.35),
                                            blurRadius: 4,
                                            offset: const Offset(0, 1),
                                          ),
                                        ],
                                      ),
                                      child: const Row(
                                        mainAxisSize: MainAxisSize.min,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.center,
                                        children: [
                                          Icon(
                                            Icons.star_rounded,
                                            size: 11,
                                            color: Color(0xFF4A3500),
                                          ),
                                          SizedBox(width: 2.5),
                                          Text(
                                            'Mặc định',
                                            style: TextStyle(
                                              fontSize: 10,
                                              fontWeight: FontWeight.w800,
                                              color: Color(0xFF4A3500),
                                              letterSpacing: 0.1,
                                              height: 1.2,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),

                                  // Currency Code Pill
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 7,
                                      vertical: 3.5,
                                    ),
                                    alignment: Alignment.center,
                                    decoration: BoxDecoration(
                                      color: isDark
                                          ? Colors.white.withValues(alpha: 0.08)
                                          : Colors.black.withValues(alpha: 0.05),
                                      borderRadius: BorderRadius.circular(
                                        AppleTokens.radiusPill,
                                      ),
                                    ),
                                    child: Text(
                                      account.currency.toUpperCase(),
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w600,
                                        color: isDark
                                            ? Colors.white54
                                            : Colors.black54,
                                        letterSpacing: 0.2,
                                        height: 1.2,
                                      ),
                                    ),
                                  ),

                                  // Archived Badge
                                  if (account.archived)
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 7,
                                        vertical: 3.5,
                                      ),
                                      alignment: Alignment.center,
                                      decoration: BoxDecoration(
                                        color: AppleTokens.rubyExpense
                                            .withValues(alpha: 0.15),
                                        borderRadius: BorderRadius.circular(
                                          AppleTokens.radiusPill,
                                        ),
                                      ),
                                      child: Text(
                                        l10n.archivedWallets,
                                        style: const TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w600,
                                          color: AppleTokens.rubyExpense,
                                          height: 1.2,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(width: 6),

                        // Apple 3-dots Menu Button
                        ApplePopupMenuButton<String>(
                          tooltip: l10n.moreOptions,
                          onSelected: (value) {
                            if (value == 'edit') onEdit();
                            if (value == 'archive') onToggleArchive();
                            if (value == 'set_default') onSetDefault?.call();
                          },
                          itemBuilder: (ctx) => [
                            if (!isDefault && onSetDefault != null)
                              ApplePopupMenuItem(
                                value: 'set_default',
                                icon: CupertinoIcons.star_fill,
                                title: 'Đặt làm ví mặc định',
                              ),
                            ApplePopupMenuItem(
                              value: 'edit',
                              icon: CupertinoIcons.pencil,
                              title: l10n.edit,
                            ),
                            ApplePopupMenuItem(
                              value: 'archive',
                              icon: account.archived
                                  ? CupertinoIcons.arrow_counterclockwise
                                  : CupertinoIcons.archivebox,
                              title: account.archived
                                  ? l10n.unarchiveWallet
                                  : l10n.archiveWallet,
                            ),
                          ],
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    // Subtle Hairline Divider
                    Divider(
                      height: 1,
                      thickness: AppleTokens.hairline,
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.08)
                          : Colors.black.withValues(alpha: 0.06),
                    ),

                    const SizedBox(height: 10),

                    // --- Tier 2: Financial Balance Row ---
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Label: "SỐ DƯ HIỆN TẠI" with glowing indicator dot
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              decoration: BoxDecoration(
                                color: walletColor,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: walletColor.withValues(alpha: 0.6),
                                    blurRadius: 4,
                                    spreadRadius: 0.5,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'SỐ DƯ HIỆN TẠI',
                              style: TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.4,
                                color: isDark
                                    ? Colors.white54
                                    : Colors.black.withValues(alpha: 0.5),
                              ),
                            ),
                          ],
                        ),

                        // Large Tabular Balance Figure + Forward Chevron
                        Flexible(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Flexible(
                                child: Text(
                                  balanceText,
                                  semanticsLabel:
                                      hideBalance ? l10n.balanceHidden : null,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  textAlign: TextAlign.right,
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                    fontFeatures: AppTheme.tabularFigures,
                                    letterSpacing: -0.3,
                                    color: isDark
                                        ? Colors.white
                                        : const Color(0xFF1C1C1E),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 4),
                              Icon(
                                CupertinoIcons.chevron_right,
                                size: 14,
                                color: isDark
                                    ? Colors.white38
                                    : Colors.black.withValues(alpha: 0.3),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
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

