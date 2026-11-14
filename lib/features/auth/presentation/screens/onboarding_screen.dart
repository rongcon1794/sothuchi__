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
part '../widgets/onboarding_slide_graphics.dart';
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
                      l10n.localeName.startsWith('vi')
                          ? 'Quản lý tài chính cá nhân'
                          : 'Personal Finance Tracker',
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
    final isVi = l10n.localeName.startsWith('vi');
    return [
      // Slide 1: Lightning Entry & Multi-Wallet
      _OnboardingSlide(
        tag: l10n.onboarding1Tag,
        title: l10n.onboarding1Title,
        subtitle: l10n.onboarding1Subtitle,
        accentColor: AppleTokens.jadePrimary,
        secondaryAccent: AppleTokens.systemMint,
        highlights: [
          _OnboardingHighlight(
            icon: CupertinoIcons.bolt_fill,
            label: isVi ? 'Nhập liệu 3 giây' : '3-Second Entry',
          ),
          _OnboardingHighlight(
            icon: CupertinoIcons.creditcard_fill,
            label: isVi ? 'Quản lý đa ví' : 'Multi-Wallet',
          ),
          _OnboardingHighlight(
            icon: CupertinoIcons.mic_fill,
            label: isVi ? 'Giọng nói & AI Scan' : 'Voice & AI Scan',
          ),
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
        highlights: [
          _OnboardingHighlight(
            icon: CupertinoIcons.chart_pie_fill,
            label: isVi ? 'Hạn mức danh mục' : 'Category Limits',
          ),
          _OnboardingHighlight(
            icon: CupertinoIcons.speedometer,
            label: isVi ? 'Nhịp chi an toàn/ngày' : 'Safe Daily Pace',
          ),
          _OnboardingHighlight(
            icon: CupertinoIcons.bell_fill,
            label: isVi ? 'Cảnh báo bội chi' : 'Overspend Alerts',
          ),
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
        highlights: [
          _OnboardingHighlight(
            icon: CupertinoIcons.archivebox_fill,
            label: isVi ? 'Hũ tiết kiệm mơ ước' : 'Savings Piggy Bank',
          ),
          _OnboardingHighlight(
            icon: CupertinoIcons.calendar_today,
            label: isVi ? 'Hóa đơn định kỳ' : 'Recurring Bills',
          ),
          _OnboardingHighlight(
            icon: CupertinoIcons.bell_fill,
            label: isVi ? 'Tự động nhắc hẹn' : 'Auto Reminders',
          ),
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
        highlights: [
          _OnboardingHighlight(
            icon: CupertinoIcons.chart_bar_alt_fill,
            label: isVi ? 'Biểu đồ dòng tiền' : 'Cashflow Trends',
          ),
          _OnboardingHighlight(
            icon: CupertinoIcons.layers_fill,
            label: isVi ? 'Cơ cấu chi tiêu' : 'Expense Breakdown',
          ),
          _OnboardingHighlight(
            icon: CupertinoIcons.share,
            label: isVi ? 'Xuất Excel & PDF' : 'Excel & PDF Export',
          ),
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
        highlights: [
          const _OnboardingHighlight(
            icon: CupertinoIcons.lock_shield_fill,
            label: 'Face ID & PIN',
          ),
          _OnboardingHighlight(
            icon: CupertinoIcons.wifi_slash,
            label: isVi ? '100% Ngoại tuyến' : '100% Offline-First',
          ),
          _OnboardingHighlight(
            icon: CupertinoIcons.cloud_upload_fill,
            label: isVi ? 'Đồng bộ Firebase' : 'Firebase Cloud Sync',
          ),
        ],
        illustrationBuilder: (context, isDark) => const _Slide5SecurityCloudGraphic(),
      ),
    ];
  }
}

