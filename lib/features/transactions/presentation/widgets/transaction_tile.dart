import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:so_thu_chi/core/constants/icon_catalog.dart';
import 'package:so_thu_chi/core/l10n/l10n_ext.dart';
import 'package:so_thu_chi/core/theme/app_theme.dart';
import 'package:so_thu_chi/features/accounts/domain/entities/account.dart';
import 'package:so_thu_chi/features/categories/domain/entities/category.dart';
import 'package:so_thu_chi/features/transactions/domain/entities/transaction_entity.dart';

class TransactionTile extends StatelessWidget {
  const TransactionTile({
    super.key,
    required this.transaction,
    required this.category,
    required this.sourceAccount,
    this.destinationAccount,
    required this.locale,
    required this.hideAmount,
    required this.onTap,
    this.onSwipeEdit,
    this.onSwipeDelete,
  });

  final TransactionEntity transaction;
  final Category? category;
  final Account? sourceAccount;
  final Account? destinationAccount;
  final String locale;
  final bool hideAmount;
  final VoidCallback onTap;
  final VoidCallback? onSwipeEdit;
  final Future<bool> Function()? onSwipeDelete;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final financeColors = context.financeColors;

    final isTransfer = transaction.type == TransactionType.transfer;
    final isIncome = transaction.type == TransactionType.income;

    final title = isTransfer
        ? l10n.transfer
        : (category != null
              ? DefaultCategoryLocalization.resolveName(
                  l10n,
                  categoryId: category!.id,
                  fallbackName: category!.name,
                )
              : l10n.catOtherExpense);

    final rawBadgeColor = isTransfer
        ? financeColors.transfer
        : (category != null
              ? Color(category!.color)
              : (isIncome ? financeColors.income : financeColors.expense));
    final badgeColor = AppIconCatalog.contrastSafeColor(
      rawBadgeColor,
      theme.brightness,
    );

    final iconData = isTransfer
        ? Icons.swap_horiz_rounded
        : AppIconCatalog.resolve(category?.icon ?? 'other');

    final walletLabel = isTransfer
        ? '${sourceAccount?.name ?? '—'} → ${destinationAccount?.name ?? '—'}'
        : (sourceAccount?.name ?? '');

    final subtitleParts = <String>[
      if (walletLabel.isNotEmpty) walletLabel,
      if (transaction.note.isNotEmpty) transaction.note,
    ];
    final subtitleText = subtitleParts.join(' • ');

    final amountColor = switch (transaction.type) {
      TransactionType.income => financeColors.income,
      TransactionType.expense => financeColors.expense,
      TransactionType.transfer => financeColors.transfer,
    };

    final prefix = switch (transaction.type) {
      TransactionType.income => '+',
      TransactionType.expense => '-',
      TransactionType.transfer => '',
    };

    final typeLabel = switch (transaction.type) {
      TransactionType.income => l10n.income,
      TransactionType.expense => l10n.expense,
      TransactionType.transfer => l10n.transfer,
    };

    final formattedMoney = transaction.money.format(
      locale: locale,
      masked: hideAmount,
    );
    final displayAmount = hideAmount ? formattedMoney : '$prefix$formattedMoney';
    final spokenAmount = hideAmount ? l10n.balanceHidden : displayAmount;

    final semanticParts = <String>[
      typeLabel,
      title,
      spokenAmount,
      if (subtitleText.isNotEmpty) subtitleText,
      if (transaction.tags.isNotEmpty)
        transaction.tags.take(3).map((t) => '#$t').join(', '),
    ];
    final semanticLabel = semanticParts.join(', ');

    final customActions = <CustomSemanticsAction, VoidCallback>{
      CustomSemanticsAction(label: l10n.edit): ?onSwipeEdit,
      if (onSwipeDelete != null)
        CustomSemanticsAction(label: l10n.delete): () {
          onSwipeDelete!();
        },
    };

    final textScale = MediaQuery.textScalerOf(context).scale(1);
    final stackAmountBelow = textScale >= 1.6;

    final amountWidget = FittedBox(
      fit: BoxFit.scaleDown,
      alignment: Alignment.centerRight,
      child: Text(
        displayAmount,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: theme.textTheme.titleSmall?.copyWith(
          color: amountColor,
          fontWeight: FontWeight.w700,
          fontFeatures: AppTheme.tabularFigures,
        ),
      ),
    );

    final tileContent = InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          crossAxisAlignment: stackAmountBelow
              ? CrossAxisAlignment.start
              : CrossAxisAlignment.center,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: badgeColor.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(iconData, color: badgeColor, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: stackAmountBelow ? 2 : 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (subtitleText.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitleText,
                      maxLines: stackAmountBelow ? 2 : 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                  if (transaction.tags.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 4,
                      runSpacing: 4,
                      children: [
                        for (final tag in transaction.tags.take(3))
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              '#$tag',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                  if (stackAmountBelow) ...[
                    const SizedBox(height: 6),
                    amountWidget,
                  ],
                ],
              ),
            ),
            if (!stackAmountBelow) ...[
              const SizedBox(width: 10),
              Flexible(flex: 0, child: amountWidget),
            ],
          ],
        ),
      ),
    );

    final semanticTile = Semantics(
      button: true,
      excludeSemantics: true,
      label: semanticLabel,
      customSemanticsActions: customActions.isEmpty ? null : customActions,
      child: tileContent,
    );

    if (onSwipeEdit == null && onSwipeDelete == null) {
      return semanticTile;
    }

    return Dismissible(
      key: ValueKey('tx_${transaction.id}'),
      direction: DismissDirection.horizontal,
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.startToEnd) {
          onSwipeEdit?.call();
          return false;
        }
        if (direction == DismissDirection.endToStart && onSwipeDelete != null) {
          return await onSwipeDelete!();
        }
        return false;
      },
      background: Container(
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          color: const Color(0xFF007AFF),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.edit_rounded,
              color: Colors.white,
            ),
            const SizedBox(width: 8),
            Text(
              l10n.edit,
              style: theme.textTheme.labelLarge?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
      secondaryBackground: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          color: const Color(0xFFFF3B30),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Text(
              l10n.delete,
              style: theme.textTheme.labelLarge?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 8),
            const Icon(
              Icons.delete_outline_rounded,
              color: Colors.white,
            ),
          ],
        ),
      ),
      child: semanticTile,
    );
  }
}
