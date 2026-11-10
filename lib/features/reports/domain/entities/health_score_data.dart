import 'package:flutter/material.dart';
import 'package:so_thu_chi/core/theme/apple_theme_tokens.dart';
import 'package:so_thu_chi/features/reports/domain/entities/monthly_report.dart';
import 'package:so_thu_chi/l10n/app_localizations.dart';

/// Breakdown of financial health score calculation according to the 50/30/20 standard.
class HealthScoreData {
  const HealthScoreData({
    required this.score,
    required this.rating,
    required this.color,
    required this.savingsRate,
    required this.savingsScoreImpact,
    required this.disciplineScoreImpact,
    required this.isDisciplinePassed,
    required this.topCategoryName,
    required this.topCategoryPercent,
    required this.cashflowScoreImpact,
    required this.isNetPositive,
  });

  final int score;
  final String rating;
  final Color color;
  final int savingsRate;
  final int savingsScoreImpact;
  final int disciplineScoreImpact;
  final bool isDisciplinePassed;
  final String? topCategoryName;
  final int topCategoryPercent;
  final int cashflowScoreImpact;
  final bool isNetPositive;

  static HealthScoreData calculate(MonthlyReportData r, AppLocalizations l10n) {
    if (r.totalIncomeMinor <= 0 && r.totalExpenseMinor <= 0) {
      return HealthScoreData(
        score: 50,
        rating: l10n.healthInsufficientData,
        color: AppleTokens.systemGray,
        savingsRate: 0,
        savingsScoreImpact: 0,
        disciplineScoreImpact: 0,
        isDisciplinePassed: true,
        topCategoryName: null,
        topCategoryPercent: 0,
        cashflowScoreImpact: 0,
        isNetPositive: true,
      );
    }

    var score = 50;

    // 1. Savings rate weight (up to 30 points)
    final rate = r.savingsRatePercent;
    final int savingsImpact;
    if (rate >= 30) {
      savingsImpact = 30;
    } else if (rate >= 20) {
      savingsImpact = 25;
    } else if (rate >= 10) {
      savingsImpact = 15;
    } else if (rate > 0) {
      savingsImpact = 5;
    } else {
      savingsImpact = -20;
    }
    score += savingsImpact;

    // 2. Spending discipline: is there any category exceeding 70%?
    final topCategory = r.categorySlices.firstOrNull;
    final topCategoryPercent = topCategory?.percentage ?? 0;
    final isDisciplinePassed = topCategoryPercent <= 70;
    final disciplineImpact = isDisciplinePassed ? 10 : -10;
    score += disciplineImpact;

    // 3. Positive Net Cashflow
    final isNetPositive = r.netMinor > 0;
    final cashflowImpact = isNetPositive ? 10 : 0;
    score += cashflowImpact;

    score = score.clamp(10, 100);

    final String rating;
    final Color color;
    if (score >= 80) {
      rating = l10n.healthRatingExcellent;
      color = AppleTokens.systemGreen;
    } else if (score >= 60) {
      rating = l10n.healthRatingGood;
      color = AppleTokens.jadeDark;
    } else if (score >= 40) {
      rating = l10n.healthRatingAverage;
      color = AppleTokens.systemOrange;
    } else {
      rating = l10n.healthRatingNeedsAttention;
      color = AppleTokens.systemRed;
    }

    return HealthScoreData(
      score: score,
      rating: rating,
      color: color,
      savingsRate: rate,
      savingsScoreImpact: savingsImpact,
      disciplineScoreImpact: disciplineImpact,
      isDisciplinePassed: isDisciplinePassed,
      topCategoryName: topCategory?.fallbackName,
      topCategoryPercent: topCategoryPercent,
      cashflowScoreImpact: cashflowImpact,
      isNetPositive: isNetPositive,
    );
  }
}

