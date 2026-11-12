part of '../screens/onboarding_screen.dart';

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
                title: Localizations.localeOf(context).languageCode == 'vi'
                    ? 'Cà phê sáng'
                    : 'Morning coffee',
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
                title: Localizations.localeOf(context).languageCode == 'vi'
                    ? 'Lương tháng 11'
                    : 'Nov Salary',
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
                      Localizations.localeOf(context).languageCode == 'vi'
                          ? 'NGÂN SÁCH THÁNG'
                          : 'MONTHLY BUDGET',
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
                    Expanded(
                      child: Text(
                        Localizations.localeOf(context).languageCode == 'vi'
                            ? 'Chi tiêu an toàn hôm nay:'
                            : 'Safe to spend today:',
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
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
                        Text(
                          Localizations.localeOf(context).languageCode == 'vi'
                              ? 'Hóa đơn điện EVN'
                              : 'Electricity Bill',
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
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
                              child: Text(
                                Localizations.localeOf(context).languageCode == 'vi'
                                    ? 'Còn 3 ngày'
                                    : '3 days left',
                                style: const TextStyle(
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
                      Localizations.localeOf(context).languageCode == 'vi'
                          ? 'DÒNG TIỀN THÁNG'
                          : 'MONTHLY CASHFLOW',
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
                  Expanded(
                    child: _buildMetricCell(
                      Localizations.localeOf(context).languageCode == 'vi'
                          ? 'Thu nhập'
                          : 'Income',
                      '+35.000.000 ₫',
                      AppleTokens.emeraldIncome,
                    ),
                  ),
                  Expanded(
                    child: _buildMetricCell(
                      Localizations.localeOf(context).languageCode == 'vi'
                          ? 'Chi tiêu'
                          : 'Expense',
                      '-19.500.000 ₫',
                      AppleTokens.rubyExpense,
                    ),
                  ),
                  Expanded(
                    child: _buildMetricCell(
                      Localizations.localeOf(context).languageCode == 'vi'
                          ? 'Dư ròng'
                          : 'Net',
                      '+15.500.000 ₫',
                      AppleTokens.jadePrimary,
                    ),
                  ),
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
                  Flexible(
                    child: _buildMiniLegendDot(
                      AppleTokens.systemPurple,
                      Localizations.localeOf(context).languageCode == 'vi'
                          ? 'Ăn uống 42%'
                          : 'Food 42%',
                    ),
                  ),
                  Flexible(
                    child: _buildMiniLegendDot(
                      AppleTokens.systemPink,
                      Localizations.localeOf(context).languageCode == 'vi'
                          ? 'Nhà ở 28%'
                          : 'Home 28%',
                    ),
                  ),
                  Flexible(
                    child: _buildMiniLegendDot(
                      AppleTokens.systemBlue,
                      Localizations.localeOf(context).languageCode == 'vi'
                          ? 'Mua sắm 18%'
                          : 'Shop 18%',
                    ),
                  ),
                  Flexible(
                    child: _buildMiniLegendDot(
                      AppleTokens.systemOrange,
                      Localizations.localeOf(context).languageCode == 'vi'
                          ? 'Khác 12%'
                          : 'Other 12%',
                    ),
                  ),
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
                label: Localizations.localeOf(context).languageCode == 'vi'
                    ? 'Ngoại tuyến 100%'
                    : '100% Offline',
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
                label: Localizations.localeOf(context).languageCode == 'vi'
                    ? 'Đồng bộ tức thì'
                    : 'Instant Sync',
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
