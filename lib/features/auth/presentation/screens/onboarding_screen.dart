import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:so_thu_chi/core/l10n/l10n_ext.dart';
import 'package:so_thu_chi/core/theme/app_theme.dart';
import 'package:so_thu_chi/core/theme/apple_theme_tokens.dart';
import 'package:so_thu_chi/core/widgets/apple_kit.dart';
import 'package:so_thu_chi/features/settings/presentation/controllers/settings_controller.dart';
import 'package:so_thu_chi/l10n/app_localizations.dart';

/// Redesigned Onboarding Screen for Sổ Thu Chi.
///
/// Features an Apple HIG Glassmorphism aesthetic, dynamic ambient background glow,
/// 5 interactive Flutter visual illustrations showcasing the entire feature suite
/// (Transactions & Multi-wallets, Smart Budgets, Savings Goals & Bills, Reports & Cashflow,
/// Security & Cloud Sync), concise punchy copy, feature tag chips, and seamless responsive layout.
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _finishOnboarding() async {
    unawaited(HapticFeedback.mediumImpact());
    await ref.read(settingsControllerProvider.notifier).completeOnboarding();
  }

  void _nextPage(int totalSlides) {
    unawaited(HapticFeedback.selectionClick());
    if (_currentPage < totalSlides - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeOutCubic,
      );
    } else {
      _finishOnboarding();
    }
  }

  void _previousPage() {
    unawaited(HapticFeedback.selectionClick());
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeOutCubic,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final mediaQuery = MediaQuery.of(context);
    final isWide = mediaQuery.size.width >= 720;
    final isLandscape = mediaQuery.orientation == Orientation.landscape;

    final slides = _buildSlides(l10n);
    final currentSlide = slides[_currentPage];
    final isLast = _currentPage == slides.length - 1;

    return Scaffold(
      backgroundColor: isDark ? AppleTokens.bgDarkGrouped : AppleTokens.bgLightGrouped,
      body: Stack(
        children: [
          // 1. Dynamic Ambient Mesh Gradient Background that morphs per slide
          Positioned.fill(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 400),
              curve: Curves.easeInOut,
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment(
                    -0.6 + (_currentPage * 0.3),
                    -0.6 + (_currentPage * 0.15),
                  ),
                  radius: 1.2,
                  colors: [
                    currentSlide.accentColor.withValues(alpha: isDark ? 0.22 : 0.12),
                    currentSlide.secondaryAccent.withValues(alpha: isDark ? 0.10 : 0.05),
                    Colors.transparent,
                  ],
                  stops: const [0.0, 0.55, 1.0],
                ),
              ),
            ),
          ),

          // 2. Main Content
          SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: isWide ? 960 : 540),
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: isWide ? 28 : 20,
                    vertical: isLandscape && !isWide ? 8 : 14,
                  ),
                  child: Column(
                    children: [
                      // Top Navigation Header: Brand on left, Skip on right
                      _buildTopHeader(isDark: isDark, l10n: l10n),
                      const SizedBox(height: 8),

                      // Slide Stage & Content
                      Expanded(
                        child: PageView.builder(
                          controller: _pageController,
                          itemCount: slides.length,
                          physics: const BouncingScrollPhysics(),
                          onPageChanged: (index) {
                            setState(() => _currentPage = index);
                          },
                          itemBuilder: (context, index) {
                            final slide = slides[index];
                            if (isWide || (isLandscape && mediaQuery.size.width >= 600)) {
                              return _buildWideSlideLayout(
                                slide: slide,
                                isDark: isDark,
                                theme: theme,
                              );
                            }
                            return _buildPortraitSlideLayout(
                              slide: slide,
                              isDark: isDark,
                              theme: theme,
                            );
                          },
                        ),
                      ),

                      // Bottom Navigation Controls
                      _buildBottomControls(
                        totalSlides: slides.length,
                        isLast: isLast,
                        accentColor: currentSlide.accentColor,
                        isDark: isDark,
                        l10n: l10n,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopHeader({required bool isDark, required AppLocalizations l10n}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Row(
            children: [
              const SoThuChiLogo(size: 32, showShadow: false),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            l10n.appTitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.3,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                          decoration: BoxDecoration(
                            color: AppleTokens.jadePrimary.withValues(alpha: isDark ? 0.25 : 0.14),
                            borderRadius: BorderRadius.circular(AppleTokens.radiusPill),
                          ),
                          child: const Text(
                            'PRO',
                            style: TextStyle(
                              fontSize: 9.5,
                              fontWeight: FontWeight.w800,
                              color: AppleTokens.jadePrimary,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                    Text(
                      'Quản lý tài chính cá nhân',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: isDark ? Colors.white54 : Colors.black45,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        // Skip Button
        ApplePressable(
          onTap: _finishOnboarding,
          borderRadius: BorderRadius.circular(AppleTokens.radiusPill),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6.5),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.08)
                  : Colors.black.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(AppleTokens.radiusPill),
              border: Border.all(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.12)
                    : Colors.black.withValues(alpha: 0.08),
                width: 0.8,
              ),
            ),
            child: Text(
              l10n.onboardingSkip,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white70 : Colors.black87,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPortraitSlideLayout({
    required _OnboardingSlide slide,
    required bool isDark,
    required ThemeData theme,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final stageHeight = (constraints.maxHeight * 0.48).clamp(180.0, 260.0);

        return SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            children: [
              const SizedBox(height: 10),
              // Visual Illustration Stage
              SizedBox(
                height: stageHeight,
                width: double.infinity,
                child: slide.illustrationBuilder(context, isDark),
              ),
              const SizedBox(height: 16),

              // Category Tag
              _buildTagPill(tag: slide.tag, color: slide.accentColor, isDark: isDark),
              const SizedBox(height: 10),

              // Title Headline
              Text(
                slide.title,
                textAlign: TextAlign.center,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                  fontSize: 22,
                  height: 1.25,
                ),
              ),
              const SizedBox(height: 8),

              // Subtitle
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  slide.subtitle,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: isDark ? Colors.white70 : Colors.black54,
                    height: 1.4,
                    fontSize: 13.5,
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // Feature Highlights Chips
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 6,
                runSpacing: 6,
                children: slide.highlights
                    .map((h) => _buildHighlightChip(h, slide.accentColor, isDark))
                    .toList(),
              ),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
  }

  Widget _buildWideSlideLayout({
    required _OnboardingSlide slide,
    required bool isDark,
    required ThemeData theme,
  }) {
    return Center(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Left: Visual Illustration Stage
          Expanded(
            flex: 52,
            child: SizedBox(
              height: 320,
              child: slide.illustrationBuilder(context, isDark),
            ),
          ),
          const SizedBox(width: 32),

          // Right: Content Details
          Expanded(
            flex: 48,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildTagPill(tag: slide.tag, color: slide.accentColor, isDark: isDark),
                const SizedBox(height: 12),
                Text(
                  slide.title,
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.6,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  slide.subtitle,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: isDark ? Colors.white70 : Colors.black54,
                    height: 1.45,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 18),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: slide.highlights
                      .map((h) => _buildHighlightChip(h, slide.accentColor, isDark))
                      .toList(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTagPill({required String tag, required Color color, required bool isDark}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.2 : 0.12),
        borderRadius: BorderRadius.circular(AppleTokens.radiusPill),
        border: Border.all(
          color: color.withValues(alpha: isDark ? 0.4 : 0.3),
          width: 0.8,
        ),
      ),
      child: Text(
        tag.toUpperCase(),
        style: TextStyle(
          fontSize: 10.5,
          fontWeight: FontWeight.w800,
          color: color,
          letterSpacing: 0.8,
        ),
      ),
    );
  }

  Widget _buildHighlightChip(
    _OnboardingHighlight highlight,
    Color accentColor,
    bool isDark,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: isDark
            ? AppleTokens.bgDarkSecondary.withValues(alpha: 0.85)
            : Colors.white.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(AppleTokens.radiusPill),
        border: Border.all(
          color: isDark ? AppleTokens.separatorDark : AppleTokens.separatorLight,
          width: 0.8,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.15 : 0.04),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            highlight.icon,
            size: 13,
            color: accentColor,
          ),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              highlight.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomControls({
    required int totalSlides,
    required bool isLast,
    required Color accentColor,
    required bool isDark,
    required AppLocalizations l10n,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Page Indicators
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(totalSlides, (index) {
            final isSelected = index == _currentPage;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOutCubic,
              margin: const EdgeInsets.symmetric(horizontal: 3.5),
              height: 6.5,
              width: isSelected ? 26 : 6.5,
              decoration: BoxDecoration(
                color: isSelected
                    ? accentColor
                    : (isDark ? Colors.white24 : Colors.black12),
                borderRadius: BorderRadius.circular(AppleTokens.radiusPill),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: accentColor.withValues(alpha: 0.4),
                          blurRadius: 6,
                          offset: const Offset(0, 1),
                        ),
                      ]
                    : null,
              ),
            );
          }),
        ),
        const SizedBox(height: 14),

        // Navigation Action Buttons Row
        Row(
          children: [
            // Back Button (if not first page)
            if (_currentPage > 0) ...[
              ApplePressable(
                onTap: _previousPage,
                borderRadius: BorderRadius.circular(AppleTokens.radiusControl),
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppleTokens.bgDarkSecondary
                        : Colors.white,
                    borderRadius: BorderRadius.circular(AppleTokens.radiusControl),
                    border: Border.all(
                      color: isDark
                          ? AppleTokens.separatorDark
                          : AppleTokens.separatorLight,
                      width: 0.8,
                    ),
                  ),
                  child: Icon(
                    CupertinoIcons.arrow_left,
                    size: 18,
                    color: isDark ? Colors.white70 : Colors.black87,
                  ),
                ),
              ),
              const SizedBox(width: 10),
            ],

            // Main Primary CTA Button
            Expanded(
              child: ApplePressable(
                onTap: () => _nextPage(totalSlides),
                borderRadius: BorderRadius.circular(AppleTokens.radiusControl),
                child: Container(
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        accentColor,
                        Color.lerp(accentColor, Colors.black, isDark ? 0.35 : 0.15)!,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(AppleTokens.radiusControl),
                    boxShadow: [
                      BoxShadow(
                        color: accentColor.withValues(alpha: isDark ? 0.4 : 0.28),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        isLast ? l10n.onboardingStart : l10n.onboardingNext,
                        style: const TextStyle(
                          fontSize: 15.5,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          letterSpacing: -0.2,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        isLast ? CupertinoIcons.sparkles : CupertinoIcons.arrow_right,
                        size: 17,
                        color: Colors.white,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  List<_OnboardingSlide> _buildSlides(AppLocalizations l10n) {
    return [
      // Slide 1: Lightning Entry & Multi-Wallet
      _OnboardingSlide(
        tag: l10n.onboarding1Tag,
        title: l10n.onboarding1Title,
        subtitle: l10n.onboarding1Subtitle,
        accentColor: AppleTokens.jadePrimary,
        secondaryAccent: AppleTokens.systemMint,
        highlights: const [
          _OnboardingHighlight(icon: CupertinoIcons.bolt_fill, label: 'Nhập liệu 3 giây'),
          _OnboardingHighlight(icon: CupertinoIcons.creditcard_fill, label: 'Quản lý đa ví'),
          _OnboardingHighlight(icon: CupertinoIcons.mic_fill, label: 'Giọng nói & AI Scan'),
        ],
        illustrationBuilder: (context, isDark) => const _Slide1TransactionWalletGraphic(),
      ),

      // Slide 2: Smart Budgets & Safe Pacing
      _OnboardingSlide(
        tag: l10n.onboarding2Tag,
        title: l10n.onboarding2Title,
        subtitle: l10n.onboarding2Subtitle,
        accentColor: AppleTokens.systemBlue,
        secondaryAccent: AppleTokens.systemIndigo,
        highlights: const [
          _OnboardingHighlight(icon: CupertinoIcons.chart_pie_fill, label: 'Hạn mức danh mục'),
          _OnboardingHighlight(icon: CupertinoIcons.speedometer, label: 'Nhịp chi an toàn/ngày'),
          _OnboardingHighlight(icon: CupertinoIcons.bell_fill, label: 'Cảnh báo bội chi'),
        ],
        illustrationBuilder: (context, isDark) => const _Slide2SmartBudgetGraphic(),
      ),

      // Slide 3: Savings Goals & Recurring Bills
      _OnboardingSlide(
        tag: l10n.onboarding3Tag,
        title: l10n.onboarding3Title,
        subtitle: l10n.onboarding3Subtitle,
        accentColor: AppleTokens.systemOrange,
        secondaryAccent: AppleTokens.systemYellow,
        highlights: const [
          _OnboardingHighlight(icon: CupertinoIcons.archivebox_fill, label: 'Hũ tiết kiệm mơ ước'),
          _OnboardingHighlight(icon: CupertinoIcons.calendar_today, label: 'Hóa đơn định kỳ'),
          _OnboardingHighlight(icon: CupertinoIcons.bell_fill, label: 'Tự động nhắc hẹn'),
        ],
        illustrationBuilder: (context, isDark) => const _Slide3SavingsBillsGraphic(),
      ),

      // Slide 4: Financial Reports & Cashflow Analytics
      _OnboardingSlide(
        tag: l10n.onboarding4Tag,
        title: l10n.onboarding4Title,
        subtitle: l10n.onboarding4Subtitle,
        accentColor: AppleTokens.systemPurple,
        secondaryAccent: AppleTokens.systemPink,
        highlights: const [
          _OnboardingHighlight(icon: CupertinoIcons.chart_bar_alt_fill, label: 'Biểu đồ dòng tiền'),
          _OnboardingHighlight(icon: CupertinoIcons.layers_fill, label: 'Cơ cấu chi tiêu'),
          _OnboardingHighlight(icon: CupertinoIcons.share, label: 'Xuất Excel & PDF'),
        ],
        illustrationBuilder: (context, isDark) => const _Slide4ReportsAnalyticsGraphic(),
      ),

      // Slide 5: Private Security & Instant Cloud Sync
      _OnboardingSlide(
        tag: l10n.onboarding5Tag,
        title: l10n.onboarding5Title,
        subtitle: l10n.onboarding5Subtitle,
        accentColor: AppleTokens.emeraldIncome,
        secondaryAccent: AppleTokens.systemCyan,
        highlights: const [
          _OnboardingHighlight(icon: CupertinoIcons.lock_shield_fill, label: 'Face ID & PIN'),
          _OnboardingHighlight(icon: CupertinoIcons.wifi_slash, label: '100% Ngoại tuyến'),
          _OnboardingHighlight(icon: CupertinoIcons.cloud_upload_fill, label: 'Đồng bộ Firebase'),
        ],
        illustrationBuilder: (context, isDark) => const _Slide5SecurityCloudGraphic(),
      ),
    ];
  }
}

class _OnboardingHighlight {
  const _OnboardingHighlight({required this.icon, required this.label});
  final IconData icon;
  final String label;
}

class _OnboardingSlide {
  const _OnboardingSlide({
    required this.tag,
    required this.title,
    required this.subtitle,
    required this.accentColor,
    required this.secondaryAccent,
    required this.highlights,
    required this.illustrationBuilder,
  });

  final String tag;
  final String title;
  final String subtitle;
  final Color accentColor;
  final Color secondaryAccent;
  final List<_OnboardingHighlight> highlights;
  final Widget Function(BuildContext context, bool isDark) illustrationBuilder;
}

// ---------------------------------------------------------------------------
// 1. Slide 1 Graphic: Interactive Apple Wallet Card + Floating Transactions
// ---------------------------------------------------------------------------
class _Slide1TransactionWalletGraphic extends StatelessWidget {
  const _Slide1TransactionWalletGraphic();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Center(
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 380),
          child: Stack(
            alignment: Alignment.center,
            clipBehavior: Clip.none,
            children: [
            // Background Apple Wallet Card
            Container(
              width: 320,
              height: 155,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF0D6B4E),
                    Color(0xFF033324),
                  ],
                ),
                borderRadius: BorderRadius.circular(AppleTokens.radiusHero),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.18),
                  width: 0.8,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF0D6B4E).withValues(alpha: isDark ? 0.45 : 0.25),
                    blurRadius: 18,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Gold Smart Chip
                      Container(
                        width: 32,
                        height: 22,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFFFDF7A), Color(0xFFD4AF37)],
                          ),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(width: 1, color: Colors.black26),
                            const SizedBox(width: 6),
                            Container(width: 1, color: Colors.black26),
                          ],
                        ),
                      ),
                      const Icon(
                        CupertinoIcons.waveform_path,
                        color: Colors.white70,
                        size: 18,
                      ),
                    ],
                  ),
                  const Spacer(),
                  const Text(
                    'Vietcombank Digital',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  const Text(
                    '42.500.000 ₫',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      fontFeatures: AppTheme.tabularFigures,
                      letterSpacing: -0.4,
                    ),
                  ),
                ],
              ),
            ),

            // Floating Top Expense Pill (Coffee)
            Positioned(
              top: -8,
              right: 8,
              child: _buildFloatingTransactionPill(
                icon: Icons.local_cafe_rounded,
                iconColor: AppleTokens.systemOrange,
                title: 'Cà phê sáng',
                amount: '-45.000 ₫',
                isIncome: false,
                isDark: isDark,
              ),
            ),

            // Floating Bottom Income Pill (Salary)
            Positioned(
              bottom: -10,
              left: 6,
              child: _buildFloatingTransactionPill(
                icon: Icons.arrow_downward_rounded,
                iconColor: AppleTokens.jadePrimary,
                title: 'Lương tháng 11',
                amount: '+25.000.000 ₫',
                isIncome: true,
                isDark: isDark,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

  Widget _buildFloatingTransactionPill({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String amount,
    required bool isIncome,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E202C) : Colors.white,
        borderRadius: BorderRadius.circular(AppleTokens.radiusPill),
        border: Border.all(
          color: isDark ? AppleTokens.separatorDark : AppleTokens.separatorLight,
          width: 0.8,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.12),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 26,
            height: 26,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 14, color: iconColor),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white70 : Colors.black87,
                ),
              ),
              Text(
                amount,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: isIncome ? AppleTokens.emeraldIncome : AppleTokens.rubyExpense,
                  fontFeatures: AppTheme.tabularFigures,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// 2. Slide 2 Graphic: Smart Budget & Safe Daily Pacing
// ---------------------------------------------------------------------------
class _Slide2SmartBudgetGraphic extends StatelessWidget {
  const _Slide2SmartBudgetGraphic();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Center(
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 340),
          child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isDark
                  ? const [Color(0xFF0F1E36), Color(0xFF091222)]
                  : const [Color(0xFFEBF3FF), Color(0xFFD6E6FF)],
            ),
            borderRadius: BorderRadius.circular(AppleTokens.radiusHero),
            border: Border.all(
              color: AppleTokens.systemBlue.withValues(alpha: isDark ? 0.35 : 0.25),
              width: 1.0,
            ),
            boxShadow: [
              BoxShadow(
                color: AppleTokens.systemBlue.withValues(alpha: isDark ? 0.3 : 0.12),
                blurRadius: 16,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(5),
                    decoration: BoxDecoration(
                      color: AppleTokens.systemBlue.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      CupertinoIcons.chart_pie_fill,
                      color: AppleTokens.systemBlue,
                      size: 14,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'NGÂN SÁCH THÁNG',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.3,
                        color: isDark ? AppleTokens.systemBlue : const Color(0xFF004999),
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppleTokens.systemBlue.withValues(alpha: isDark ? 0.25 : 0.15),
                      borderRadius: BorderRadius.circular(AppleTokens.radiusPill),
                    ),
                    child: const Text(
                      '68%',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: AppleTokens.systemBlue,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Amount Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: Text(
                      '6.800.000 ₫',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        fontFeatures: AppTheme.tabularFigures,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '/ 10.000.000 ₫',
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white54 : Colors.black54,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Progress Bar
              ClipRRect(
                borderRadius: BorderRadius.circular( AppleTokens.radiusPill),
                child: SizedBox(
                  height: 8,
                  child: LinearProgressIndicator(
                    value: 0.68,
                    backgroundColor: isDark
                        ? Colors.white.withValues(alpha: 0.1)
                        : Colors.black.withValues(alpha: 0.08),
                    valueColor: const AlwaysStoppedAnimation<Color>(AppleTokens.systemBlue),
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // Safe Daily Pace Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.black.withValues(alpha: 0.3)
                      : Colors.white.withValues(alpha: 0.75),
                  borderRadius: BorderRadius.circular(AppleTokens.radiusSm),
                  border: Border.all(
                    color: AppleTokens.emeraldIncome.withValues(alpha: 0.3),
                    width: 0.8,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 7,
                      height: 7,
                      decoration: const BoxDecoration(
                        color: AppleTokens.emeraldIncome,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 7),
                    const Expanded(
                      child: Text(
                        'Chi tiêu an toàn hôm nay:',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                      ),
                    ),
                    const Text(
                      '240.000 ₫',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w800,
                        color: AppleTokens.emeraldIncome,
                        fontFeatures: AppTheme.tabularFigures,
                      ),
                    ),
                  ],
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

// ---------------------------------------------------------------------------
// 3. Slide 3 Graphic: Savings Goals & Recurring Bills
// ---------------------------------------------------------------------------
class _Slide3SavingsBillsGraphic extends StatelessWidget {
  const _Slide3SavingsBillsGraphic();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Center(
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 350),
          child: Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: [
            // Savings Goal Card (Main)
            Container(
              width: 320,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: isDark
                      ? const [Color(0xFF2E1F08), Color(0xFF191104)]
                      : const [Color(0xFFFFF7EB), Color(0xFFFFECC8)],
                ),
                borderRadius: BorderRadius.circular(AppleTokens.radiusHero),
                border: Border.all(
                  color: AppleTokens.systemOrange.withValues(alpha: isDark ? 0.35 : 0.25),
                  width: 1.0,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppleTokens.systemOrange.withValues(alpha: isDark ? 0.3 : 0.12),
                    blurRadius: 16,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: AppleTokens.systemOrange.withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          CupertinoIcons.archivebox_fill,
                          color: AppleTokens.systemOrange,
                          size: 15,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          'MUA MACBOOK PRO M3',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.4,
                            color: AppleTokens.systemOrange,
                          ),
                        ),
                      ),
                      const Text(
                        '75%',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: AppleTokens.systemOrange,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: Text(
                          '22.500.000 ₫',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            fontFeatures: AppTheme.tabularFigures,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '/ 30.000.000 ₫',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white54 : Colors.black54,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(AppleTokens.radiusPill),
                    child: SizedBox(
                      height: 7,
                      child: LinearProgressIndicator(
                        value: 0.75,
                        backgroundColor: isDark
                            ? Colors.white.withValues(alpha: 0.1)
                            : Colors.black.withValues(alpha: 0.08),
                        valueColor: const AlwaysStoppedAnimation<Color>(AppleTokens.systemOrange),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Floating Recurring Bill Badge (Bottom overlap)
            Positioned(
              bottom: -18,
              right: 6,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E1E26) : Colors.white,
                  borderRadius: BorderRadius.circular(AppleTokens.radiusCard),
                  border: Border.all(
                    color: isDark ? AppleTokens.separatorDark : AppleTokens.separatorLight,
                    width: 0.8,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.12),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(5),
                      decoration: BoxDecoration(
                        color: AppleTokens.systemYellow.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.bolt_rounded,
                        size: 15,
                        color: AppleTokens.systemOrange,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'Hóa đơn điện EVN',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                        ),
                        Row(
                          children: [
                            const Text(
                              '850.000 ₫',
                              style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w800,
                                fontFeatures: AppTheme.tabularFigures,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                              decoration: BoxDecoration(
                                color: AppleTokens.rubyExpense.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(AppleTokens.radiusPill),
                              ),
                              child: const Text(
                                'Còn 3 ngày',
                                style: TextStyle(
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w700,
                                  color: AppleTokens.rubyExpense,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
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

// ---------------------------------------------------------------------------
// 4. Slide 4 Graphic: Reports & Cashflow Analytics
// ---------------------------------------------------------------------------
class _Slide4ReportsAnalyticsGraphic extends StatelessWidget {
  const _Slide4ReportsAnalyticsGraphic();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Center(
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 340),
          child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isDark
                  ? const [Color(0xFF220E33), Color(0xFF13071F)]
                  : const [Color(0xFFF7ECFF), Color(0xFFEDD4FF)],
            ),
            borderRadius: BorderRadius.circular(AppleTokens.radiusHero),
            border: Border.all(
              color: AppleTokens.systemPurple.withValues(alpha: isDark ? 0.35 : 0.25),
              width: 1.0,
            ),
            boxShadow: [
              BoxShadow(
                color: AppleTokens.systemPurple.withValues(alpha: isDark ? 0.3 : 0.12),
                blurRadius: 16,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(5),
                    decoration: BoxDecoration(
                      color: AppleTokens.systemPurple.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      CupertinoIcons.chart_bar_alt_fill,
                      color: AppleTokens.systemPurple,
                      size: 14,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'DÒNG TIỀN THÁNG',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.3,
                        color: isDark ? AppleTokens.systemPurple : const Color(0xFF6A0DAD),
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppleTokens.jadePrimary.withValues(alpha: isDark ? 0.25 : 0.15),
                      borderRadius: BorderRadius.circular(AppleTokens.radiusPill),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(CupertinoIcons.arrow_up_right, size: 10, color: AppleTokens.jadePrimary),
                        SizedBox(width: 2),
                        Text(
                          '+44%',
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w800,
                            color: AppleTokens.jadePrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Cashflow Split Row
              Row(
                children: [
                  Expanded(child: _buildMetricCell('Thu nhập', '+35.000.000 ₫', AppleTokens.emeraldIncome)),
                  Expanded(child: _buildMetricCell('Chi tiêu', '-19.500.000 ₫', AppleTokens.rubyExpense)),
                  Expanded(child: _buildMetricCell('Dư ròng', '+15.500.000 ₫', AppleTokens.jadePrimary)),
                ],
              ),
              const SizedBox(height: 12),

              // Visual Category Segmented Bar
              ClipRRect(
                borderRadius: BorderRadius.circular(AppleTokens.radiusPill),
                child: SizedBox(
                  height: 9,
                  child: Row(
                    children: [
                      Expanded(flex: 42, child: Container(color: AppleTokens.systemPurple)),
                      const SizedBox(width: 2),
                      Expanded(flex: 28, child: Container(color: AppleTokens.systemPink)),
                      const SizedBox(width: 2),
                      Expanded(flex: 18, child: Container(color: AppleTokens.systemBlue)),
                      const SizedBox(width: 2),
                      Expanded(flex: 12, child: Container(color: AppleTokens.systemOrange)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),

              // Tags
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(child: _buildMiniLegendDot(AppleTokens.systemPurple, 'Ăn uống 42%')),
                  Flexible(child: _buildMiniLegendDot(AppleTokens.systemPink, 'Nhà ở 28%')),
                  Flexible(child: _buildMiniLegendDot(AppleTokens.systemBlue, 'Mua sắm 18%')),
                  Flexible(child: _buildMiniLegendDot(AppleTokens.systemOrange, 'Khác 12%')),
                ],
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

  Widget _buildMetricCell(String label, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 10.5, color: Colors.grey, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 1),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(
            value,
            maxLines: 1,
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w800,
              color: color,
              fontFeatures: AppTheme.tabularFigures,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMiniLegendDot(Color color, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 5,
          height: 5,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 3),
        Flexible(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.w500, color: Colors.grey),
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// 5. Slide 5 Graphic: Biometric Security & Realtime Cloud Sync
// ---------------------------------------------------------------------------
class _Slide5SecurityCloudGraphic extends StatelessWidget {
  const _Slide5SecurityCloudGraphic();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Center(
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 340),
          child: Stack(
          alignment: Alignment.center,
          children: [
            // Ambient Outer Glow Ring
            Container(
              width: 190,
              height: 190,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppleTokens.emeraldIncome.withValues(alpha: isDark ? 0.2 : 0.12),
                  width: 1.5,
                ),
              ),
            ),
            Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppleTokens.emeraldIncome.withValues(alpha: isDark ? 0.35 : 0.2),
                  width: 1.5,
                ),
              ),
            ),

            // Center Emerald Shield Box
            Container(
              width: 110,
              height: 110,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF00A86B),
                    Color(0xFF034A3C),
                  ],
                ),
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: AppleTokens.emeraldIncome.withValues(alpha: 0.45),
                    blurRadius: 20,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: const Center(
                child: Icon(
                  CupertinoIcons.lock_shield_fill,
                  size: 52,
                  color: Colors.white,
                ),
              ),
            ),

            // Floating Top-Left Offline Badge
            Positioned(
              top: 15,
              left: 10,
              child: _buildSecurityPill(
                icon: CupertinoIcons.wifi_slash,
                label: 'Ngoại tuyến 100%',
                color: AppleTokens.systemTeal,
                isDark: isDark,
              ),
            ),

            // Floating Bottom-Right Cloud Sync Badge
            Positioned(
              bottom: 15,
              right: 10,
              child: _buildSecurityPill(
                icon: CupertinoIcons.cloud_upload_fill,
                label: 'Đồng bộ tức thì',
                color: AppleTokens.emeraldIncome,
                isDark: isDark,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

  Widget _buildSecurityPill({
    required IconData icon,
    required String label,
    required Color color,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1B1D28) : Colors.white,
        borderRadius: BorderRadius.circular(AppleTokens.radiusPill),
        border: Border.all(
          color: color.withValues(alpha: 0.35),
          width: 0.8,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}
