import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:so_thu_chi/core/theme/apple_theme_tokens.dart';
import 'package:so_thu_chi/core/widgets/apple_kit.dart';
import 'package:so_thu_chi/features/accounts/domain/entities/account.dart';
import 'package:so_thu_chi/features/accounts/presentation/widgets/wallet_list_tile.dart';
import 'package:so_thu_chi/l10n/app_localizations.dart';

/// Collapsible expansion card containing archived wallets.
class ArchivedWalletsExpansionCard extends StatelessWidget {
  const ArchivedWalletsExpansionCard({
    super.key,
    required this.archivedAccounts,
    required this.theme,
    required this.l10n,
    required this.locale,
    required this.hideBalance,
    required this.defaultWalletId,
    required this.typeLabelBuilder,
    required this.onTapWallet,
    required this.onEditWallet,
    required this.onRestoreWallet,
    required this.onDeleteWallet,
    required this.onSetDefaultWallet,
  });

  final List<Account> archivedAccounts;
  final ThemeData theme;
  final AppLocalizations l10n;
  final String locale;
  final bool hideBalance;
  final String? defaultWalletId;
  final String Function(AccountType) typeLabelBuilder;
  final ValueChanged<Account> onTapWallet;
  final ValueChanged<Account> onEditWallet;
  final ValueChanged<Account> onRestoreWallet;
  final ValueChanged<Account> onDeleteWallet;
  final ValueChanged<Account> onSetDefaultWallet;

  @override
  Widget build(BuildContext context) {
    if (archivedAccounts.isEmpty) return const SizedBox.shrink();

    return AppleGlassCard(
      padding: EdgeInsets.zero,
      borderRadius: BorderRadius.circular(AppleTokens.radiusCard),
      child: Theme(
        data: theme.copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          shape: const Border(),
          collapsedShape: const Border(),
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          title: Row(
            children: [
              const Icon(
                CupertinoIcons.archivebox_fill,
                size: 18,
                color: AppleTokens.systemGray,
              ),
              const SizedBox(width: 8),
              Text(
                '${l10n.archivedWallets} (${archivedAccounts.length})',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              child: Column(
                children: archivedAccounts
                    .map(
                      (account) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: WalletListTile(
                          key: ValueKey('archived_wallet_tile_${account.id}'),
                          account: account,
                          typeLabel: typeLabelBuilder(account.type),
                          locale: locale,
                          hideBalance: hideBalance,
                          isDefault: account.id == defaultWalletId,
                          onSetDefault: () => onSetDefaultWallet(account),
                          onTap: () => onTapWallet(account),
                          onEdit: () => onEditWallet(account),
                          onToggleArchive: () => onRestoreWallet(account),
                          onDelete: () => onDeleteWallet(account),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

