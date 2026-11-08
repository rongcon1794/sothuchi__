import 'dart:math' as math;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:so_thu_chi/core/constants/icon_catalog.dart';
import 'package:so_thu_chi/core/l10n/l10n_ext.dart';
import 'package:so_thu_chi/core/theme/app_theme.dart';
import 'package:so_thu_chi/core/theme/apple_theme_tokens.dart';
import 'package:so_thu_chi/core/widgets/apple_kit.dart';
import 'package:so_thu_chi/features/accounts/domain/entities/account.dart';
import 'package:so_thu_chi/features/savings/domain/entities/savings_goal.dart';
import 'package:so_thu_chi/features/savings/presentation/widgets/savings_arc_progress.dart';
import 'package:so_thu_chi/features/transactions/domain/entities/transaction_entity.dart';

class DashboardMiniWalletCard extends StatelessWidget {
  const DashboardMiniWalletCard({
    super.key,
    required this.account,
    required this.locale,
    required this.hideBalance,
    required this.onTap,
    this.transactions = const <TransactionEntity>[],
  });

  final Account account;
  final String locale;
  final bool hideBalance;
  final VoidCallback onTap;
  final List<TransactionEntity> transactions;

  List<double> _calculateSparkPoints() {
    final now = DateTime.now();
    // 7 sample calendar days: 6 days ago -> today
    final days = List.generate(
      7,
      (i) => DateTime(now.year, now.month, now.day).subtract(Duration(days: 6 - i)),
    );

    final walletTxs = transactions.where((tx) {
      return (tx.accountId == account.id || tx.toAccountId == account.id) &&
          tx.currency == account.currency;
    }).toList(growable: false);

    final currentBalanceMinor = account.balance.toDouble();
    final balances = <double>[];

    for (final day in days) {
      final endOfDay = DateTime(day.year, day.month, day.day, 23, 59, 59, 999);
      var futureNet = 0.0;
      for (final tx in walletTxs) {
        if (tx.date.isAfter(endOfDay)) {
          if (tx.type == TransactionType.income) {
            futureNet += tx.amount;
          } else if (tx.type == TransactionType.expense) {
            futureNet -= tx.amount;
          } else if (tx.type == TransactionType.transfer) {
            if (tx.accountId == account.id) {
              futureNet -= tx.amount;
            } else if (tx.toAccountId == account.id) {
              futureNet += tx.amount;
            }
          }
        }
      }
      balances.add(currentBalanceMinor - futureNet);
    }

    final minVal = balances.reduce(math.min);
    final maxVal = balances.reduce(math.max);

    if (minVal == maxVal) {
      // Balance was stable across all sample days
      return const <double>[0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 0.5];
    }

    return balances.map((b) {
      final ratio = (b - minVal) / (maxVal - minVal);
      return 0.15 + (0.70 * ratio);
    }).toList(growable: false);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textScale = MediaQuery.textScalerOf(context).scale(1);
    final cardWidth = math.max(180.0, 144.0 * textScale);
    final color = AppIconCatalog.contrastSafeColor(
      Color(account.color),
      theme.brightness,
    );
    final formattedBalance = account.balanceMoney.format(
      locale: locale,
      masked: hideBalance,
    );

    return SizedBox(
      width: cardWidth,
      child: ApplePressable(
        borderRadius: BorderRadius.circular(AppleTokens.radiusCard),
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            color: isDark ? AppleTokens.bgDarkCard : AppleTokens.bgLightCard,
            borderRadius: BorderRadius.circular(AppleTokens.radiusCard),
            border: Border.all(
              color: color.withValues(alpha: isDark ? 0.35 : 0.22),
              width: 1.0,
            ),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: isDark ? 0.14 : 0.08),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            children: [
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                height: 28,
                child: IgnorePointer(
                  child: CustomPaint(
                    painter: _MiniWalletSparklinePainter(
                      points: _calculateSparkPoints(),
                      color: color,
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(12),
                child: Semantics(
                  button: true,
                  excludeSemantics: true,
                  label:
                      '${account.name}, ${hideBalance ? l10n.balanceHidden : formattedBalance}',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              color: color.withValues(alpha: 0.16),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              AppIconCatalog.resolve(account.icon),
                              size: 16,
                              color: color,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              account.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.labelLarge?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      Text(
                        formattedBalance,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                          fontFeatures: AppTheme.tabularFigures,
                          color: isDark ? Colors.white : const Color(0xFF1C1C1E),
                        ),
                      ),
                    ],
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

class _MiniWalletSparklinePainter extends CustomPainter {
  const _MiniWalletSparklinePainter({
    required this.points,
    required this.color,
  });

  final List<double> points;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    if (points.length < 2) return;

    final width = size.width;
    final height = size.height;
    final stepX = width / (points.length - 1);

    final List<Offset> coords = [];
    for (var i = 0; i < points.length; i++) {
      final x = i * stepX;
      // Invert Y coordinate so 1.0 (highest balance) is near top of 28px card base
      final y = height - (points[i].clamp(0.08, 0.92) * height);
      coords.add(Offset(x, y));
    }

    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          color.withValues(alpha: 0.20),
          color.withValues(alpha: 0.02),
        ],
      ).createShader(Rect.fromLTWH(0, 0, width, height))
      ..style = PaintingStyle.fill;

    final linePaint = Paint()
      ..color = color.withValues(alpha: 0.50)
      ..strokeWidth = 1.6
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final linePath = Path();
    final fillPath = Path();

    linePath.moveTo(coords[0].dx, coords[0].dy);
    fillPath.moveTo(coords[0].dx, height);
    fillPath.lineTo(coords[0].dx, coords[0].dy);

    for (var i = 0; i < coords.length - 1; i++) {
      final p0 = coords[i];
      final p1 = coords[i + 1];
      final controlX1 = p0.dx + (p1.dx - p0.dx) / 2;
      final controlY1 = p0.dy;
      final controlX2 = p0.dx + (p1.dx - p0.dx) / 2;
      final controlY2 = p1.dy;

      linePath.cubicTo(controlX1, controlY1, controlX2, controlY2, p1.dx, p1.dy);
      fillPath.cubicTo(controlX1, controlY1, controlX2, controlY2, p1.dx, p1.dy);
    }

    fillPath.lineTo(coords.last.dx, height);
    fillPath.close();

    canvas.drawPath(fillPath, fillPaint);
    canvas.drawPath(linePath, linePaint);

    // Subtle glowing dot at the latest point (current balance)
    final lastPoint = coords.last;
    final dotPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    final glowPaint = Paint()
      ..color = color.withValues(alpha: 0.35)
      ..style = PaintingStyle.fill;

    canvas.drawCircle(lastPoint, 3.5, glowPaint);
    canvas.drawCircle(lastPoint, 2.0, dotPaint);
  }

  @override
  bool shouldRepaint(covariant _MiniWalletSparklinePainter oldDelegate) {
    if (oldDelegate.color != color || oldDelegate.points.length != points.length) {
      return true;
    }
    for (var i = 0; i < points.length; i++) {
      if (oldDelegate.points[i] != points[i]) return true;
    }
    return false;
  }
}

class DashboardAddWalletCard extends StatelessWidget {
  const DashboardAddWalletCard({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textScale = MediaQuery.textScalerOf(context).scale(1);
    final cardWidth = math.max(120.0, 96.0 * textScale);

    return SizedBox(
      width: cardWidth,
      child: ApplePressable(
        borderRadius: BorderRadius.circular(AppleTokens.radiusCard),
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            color: isDark
                ? AppleTokens.bgDarkSecondary.withValues(alpha: 0.5)
                : AppleTokens.bgLightSecondary.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(AppleTokens.radiusCard),
            border: Border.all(
              color: isDark ? AppleTokens.bgDarkTertiary : AppleTokens.borderLight,
              width: 1,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                CupertinoIcons.plus_circle_fill,
                color: theme.colorScheme.primary,
                size: 22,
              ),
              const SizedBox(height: 4),
              Text(
                context.l10n.addWallet,
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.primary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class DashboardMiniSavingsGoalCard extends StatelessWidget {
  const DashboardMiniSavingsGoalCard({
    super.key,
    required this.goal,
    required this.hideBalance,
    required this.onTap,
  });

  final SavingsGoal goal;
  final bool hideBalance;
  final VoidCallback onTap;

  IconData _resolveIcon(String key) {
    switch (key) {
      case 'house':
        return CupertinoIcons.house;
      case 'car':
        return CupertinoIcons.car;
      case 'airplane':
        return CupertinoIcons.airplane;
      case 'shield':
        return CupertinoIcons.shield_fill;
      case 'laptop':
        return CupertinoIcons.device_laptop;
      case 'gift':
        return CupertinoIcons.gift;
      case 'heart':
        return CupertinoIcons.heart_fill;
      case 'star':
        return CupertinoIcons.star_fill;
      case 'bag':
        return CupertinoIcons.bag;
      case 'piggy_bank':
      default:
        return CupertinoIcons.cube_box;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final locale = Localizations.localeOf(context).languageCode;
    final accentColor = Color(goal.color);

    return ApplePressable(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppleTokens.radiusCard),
      child: Container(
        width: 220,
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: isDark ? AppleTokens.bgDarkCard : Colors.white,
          borderRadius: BorderRadius.circular(AppleTokens.radiusCard),
          border: Border.all(
            color: accentColor.withValues(alpha: isDark ? 0.25 : 0.2),
            width: AppleTokens.hairline,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            SavingsArcProgressIndicator(
              progress: goal.progress,
              color: accentColor,
              size: 48,
              strokeWidth: 4.5,
              child: Icon(
                _resolveIcon(goal.icon),
                size: 18,
                color: accentColor,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    goal.title,
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    goal.currentMoney.format(locale: locale, masked: hideBalance),
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      fontFeatures: AppTheme.tabularFigures,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${goal.progressPercent}% / ${goal.targetMoney.format(locale: locale, masked: hideBalance)}',
                    style: const TextStyle(fontSize: 10, color: AppleTokens.systemGray),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
