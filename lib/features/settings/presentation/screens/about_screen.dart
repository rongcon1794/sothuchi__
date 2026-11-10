import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:so_thu_chi/core/l10n/l10n_ext.dart';
import 'package:so_thu_chi/core/responsive/apple_responsive.dart';
import 'package:so_thu_chi/core/theme/apple_theme_tokens.dart';
import 'package:so_thu_chi/core/widgets/apple_kit.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final isLandscape = context.isLandscape;
    final isVi = Localizations.localeOf(
      context,
    ).languageCode.toLowerCase().startsWith('vi');

    final features = isVi ? _viFeatures : _enFeatures;

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: isLandscape
            ? AppleTokens.appBarHeightLandscape
            : AppleTokens.appBarHeightPortrait,
        title: Text(l10n.aboutApp),
      ),
      body: SafeArea(
        top: false,
        bottom: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: AppleTokens.maxContentWidth,
            ),
            child: ListView(
              physics: const BouncingScrollPhysics(
                parent: AlwaysScrollableScrollPhysics(),
              ),
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 40),
              children: [
                // 1. Hero App Identity Card
                AppleGlassCard(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 26,
                  ),
                  borderRadius: BorderRadius.circular(AppleTokens.radiusHero),
                  child: Column(
                    children: [
                      const SoThuChiLogo(
                        size: 76,
                        heroTag: 'about_logo_hero',
                      ),
                      const SizedBox(height: 14),
                      Text(
                        l10n.appTitle,
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.4,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: scheme.primary.withValues(
                            alpha: isDark ? 0.20 : 0.12,
                          ),
                          borderRadius: BorderRadius.circular(
                            AppleTokens.radiusPill,
                          ),
                        ),
                        child: Text(
                          isVi ? 'Phiên bản 1.0.0' : 'Version 1.0.0',
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: scheme.primary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        l10n.appTagline,
                        textAlign: TextAlign.center,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        isVi
                            ? 'Giải pháp quản lý tài chính cá nhân và gia đình toàn diện, trực quan và bảo mật. Giúp bạn làm chủ dòng tiền, kiểm soát ngân sách thông minh và xây dựng thói quen tích lũy bền vững mỗi ngày.'
                            : 'A comprehensive, intuitive, and private personal and family finance manager. Designed to help you master your cashflow, stay on budget, and build lasting savings habits every day.',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: scheme.onSurfaceVariant,
                          height: 1.48,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // 2. Key Capabilities Header
                Padding(
                  padding: const EdgeInsets.only(left: 4, bottom: 10),
                  child: Text(
                    isVi ? 'TÍNH NĂNG NỔI BẬT' : 'KEY CAPABILITIES',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: scheme.onSurfaceVariant,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.6,
                    ),
                  ),
                ),

                // 3. Real App Features List
                AppleGlassCard(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  borderRadius: BorderRadius.circular(AppleTokens.radiusCard),
                  child: Column(
                    children: [
                      for (var i = 0; i < features.length; i++) ...[
                        if (i > 0)
                          Divider(
                            height: AppleTokens.hairline,
                            indent: 52,
                            color: isDark
                                ? AppleTokens.separatorDark
                                : AppleTokens.separatorLight,
                          ),
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              AppleSquircleBadge(
                                icon: features[i].icon,
                                backgroundColor: features[i].color,
                                size: 38,
                                iconSize: 20,
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      features[i].title,
                                      style: theme.textTheme.titleSmall
                                          ?.copyWith(
                                            fontWeight: FontWeight.w700,
                                            fontSize: 14.5,
                                          ),
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      features[i].description,
                                      style: theme.textTheme.bodySmall
                                          ?.copyWith(
                                            color: scheme.onSurfaceVariant,
                                            height: 1.42,
                                            fontSize: 13,
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // 4. Footer Note
                Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      isVi
                          ? 'Hoạt động mượt mà cả khi ngoại tuyến • Đồng bộ đám mây an toàn • Không quảng cáo'
                          : 'Offline-first reliability • Secure cloud sync • Zero ads',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _FeatureHighlight {
  const _FeatureHighlight({
    required this.icon,
    required this.color,
    required this.title,
    required this.description,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String description;
}

const List<_FeatureHighlight> _viFeatures = [
  _FeatureHighlight(
    icon: CupertinoIcons.layers_alt_fill,
    color: AppleTokens.systemBlue,
    title: 'Đa sổ thu chi & Đa ví tài khoản',
    description:
        'Tách biệt rõ ràng các sổ thu chi (Cá nhân, Gia đình, Công việc, Du lịch) và quản lý số dư trên Tiền mặt, Ngân hàng, Ví điện tử, Thẻ tín dụng.',
  ),
  _FeatureHighlight(
    icon: CupertinoIcons.arrow_right_arrow_left_circle_fill,
    color: AppleTokens.jadePrimary,
    title: 'Ghi chép thông minh & Giao dịch định kỳ',
    description:
        'Ghi nhận thu, chi, chuyển khoản giữa các ví chỉ trong vài chạm kèm gắn thẻ phân loại và tự động theo dõi các hóa đơn lặp lại hàng tháng.',
  ),
  _FeatureHighlight(
    icon: CupertinoIcons.gauge,
    color: AppleTokens.systemOrange,
    title: 'Kiểm soát ngân sách & Tốc độ chi tiêu',
    description:
        'Thiết lập ngân sách tổng hoặc theo từng danh mục, cảnh báo khi chạm ngưỡng và gợi ý mức chi tiêu an toàn cho những ngày còn lại trong tháng.',
  ),
  _FeatureHighlight(
    icon: CupertinoIcons.cube_box_fill,
    color: AppleTokens.systemIndigo,
    title: 'Mục tiêu tiết kiệm & Sổ nợ minh bạch',
    description:
        'Theo dõi tiến độ tích lũy cho từng mục tiêu dự định và quản lý chi tiết các khoản vay, cho vay cùng lịch sử thu hồi hoặc trả nợ.',
  ),
  _FeatureHighlight(
    icon: CupertinoIcons.chart_pie_fill,
    color: Color(0xFFE11D48),
    title: 'Báo cáo trực quan & Sức khỏe tài chính',
    description:
        'Phân tích cơ cấu chi tiêu, bản đồ nhiệt theo ngày, đường xu hướng thu - chi 6 tháng và đánh giá sức khỏe tài chính theo quy chuẩn 50/30/20.',
  ),
  _FeatureHighlight(
    icon: CupertinoIcons.lock_shield_fill,
    color: AppleTokens.systemTeal,
    title: 'Bảo mật cao, Đa tiền tệ & Xuất dữ liệu CSV',
    description:
        'Hỗ trợ 6 loại tiền tệ (VND, USD, EUR, JPY, KRW, SGD), khóa ứng dụng bằng vân tay/khuôn mặt, giao diện OLED True Black và xuất báo cáo CSV.',
  ),
];

const List<_FeatureHighlight> _enFeatures = [
  _FeatureHighlight(
    icon: CupertinoIcons.layers_alt_fill,
    color: AppleTokens.systemBlue,
    title: 'Multiple Ledgers & Wallets',
    description:
        'Separate your finances across Personal, Family, Business, or Travel ledgers and track balances across Cash, Bank, E-Wallets, and Cards.',
  ),
  _FeatureHighlight(
    icon: CupertinoIcons.arrow_right_arrow_left_circle_fill,
    color: AppleTokens.jadePrimary,
    title: 'Smart Entry & Recurring Bills',
    description:
        'Log income, expenses, and wallet transfers in seconds with smart suggestions, tags, and automated tracking for recurring subscriptions and bills.',
  ),
  _FeatureHighlight(
    icon: CupertinoIcons.gauge,
    color: AppleTokens.systemOrange,
    title: 'Monthly Budgets & Spending Pace',
    description:
        'Set overall or category budgets, receive early threshold alerts, and view recommended daily spending limits for the rest of the month.',
  ),
  _FeatureHighlight(
    icon: CupertinoIcons.cube_box_fill,
    color: AppleTokens.systemIndigo,
    title: 'Savings Goals & Debt Tracking',
    description:
        'Track progress toward your savings milestones and manage lent or borrowed balances with full repayment histories.',
  ),
  _FeatureHighlight(
    icon: CupertinoIcons.chart_pie_fill,
    color: Color(0xFFE11D48),
    title: 'Visual Reports & Financial Health',
    description:
        'Explore category breakdowns, daily spending heatmaps, 6-month income vs. expense trend lines, and 50/30/20 financial health scores.',
  ),
  _FeatureHighlight(
    icon: CupertinoIcons.lock_shield_fill,
    color: AppleTokens.systemTeal,
    title: 'Biometric Security, Multi-Currency & CSV',
    description:
        'Supports 6 currencies (VND, USD, EUR, JPY, KRW, SGD), biometric app lock, OLED True Black mode, and full UTF-8 CSV export.',
  ),
];


