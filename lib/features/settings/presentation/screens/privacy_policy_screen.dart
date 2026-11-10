import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:so_thu_chi/core/l10n/l10n_ext.dart';
import 'package:so_thu_chi/core/responsive/apple_responsive.dart';
import 'package:so_thu_chi/core/theme/apple_theme_tokens.dart';
import 'package:so_thu_chi/core/widgets/apple_kit.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

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

    final sections = isVi ? _viSections : _enSections;

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: isLandscape
            ? AppleTokens.appBarHeightLandscape
            : AppleTokens.appBarHeightPortrait,
        title: Text(l10n.privacyPolicy),
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
                // Hero Privacy Banner
                AppleGlassCard(
                  padding: const EdgeInsets.all(20),
                  borderRadius: BorderRadius.circular(AppleTokens.radiusHero),
                  borderColor: AppleTokens.jadePrimary.withValues(alpha: 0.35),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: AppleTokens.jadePrimary.withValues(
                                alpha: isDark ? 0.22 : 0.14,
                              ),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: const Icon(
                              CupertinoIcons.shield_lefthalf_fill,
                              color: AppleTokens.jadePrimary,
                              size: 26,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  isVi
                                      ? 'Cam kết Bảo mật & Quyền riêng tư'
                                      : 'Privacy & Security Commitment',
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: -0.3,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  isVi
                                      ? 'Dữ liệu tài chính của bạn thuộc toàn quyền sở hữu của bạn'
                                      : 'Your personal financial data belongs strictly to you',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: scheme.onSurfaceVariant,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Text(
                        isVi
                            ? 'Sổ Thu Chi được xây dựng với nguyên tắc đặt sự riêng tư lên hàng đầu. Chúng tôi chỉ xử lý những dữ liệu cần thiết để cung cấp tính năng quản lý thu chi, đồng bộ hóa giữa các thiết bị của bạn và tuyệt đối không khai thác dữ liệu cá nhân cho mục đích thương mại hay quảng cáo.'
                            : 'Sổ Thu Chi is built on a privacy-first foundation. We only process the data necessary to provide expense tracking and multi-device synchronization, and we never monetize or share your financial records for advertising.',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          height: 1.48,
                          color: scheme.onSurface.withValues(alpha: 0.9),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // Policy Sections
                for (final section in sections) ...[
                  AppleGlassCard(
                    padding: const EdgeInsets.all(18),
                    borderRadius: BorderRadius.circular(AppleTokens.radiusCard),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            AppleSquircleBadge(
                              icon: section.icon,
                              backgroundColor: section.color,
                              size: 34,
                              iconSize: 18,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                section.title,
                                style: theme.textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 15,
                                  letterSpacing: -0.2,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        for (var i = 0; i < section.bullets.length; i++) ...[
                          if (i > 0) const SizedBox(height: 10),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: const EdgeInsets.only(top: 6),
                                child: Container(
                                  width: 6,
                                  height: 6,
                                  decoration: BoxDecoration(
                                    color: section.color,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  section.bullets[i],
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    height: 1.45,
                                    fontSize: 13.5,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PolicySectionData {
  const _PolicySectionData({
    required this.icon,
    required this.color,
    required this.title,
    required this.bullets,
  });

  final IconData icon;
  final Color color;
  final String title;
  final List<String> bullets;
}

const List<_PolicySectionData> _viSections = [
  _PolicySectionData(
    icon: CupertinoIcons.doc_text_search,
    color: AppleTokens.systemBlue,
    title: '1. Thông tin ứng dụng thu thập',
    bullets: [
      'Thông tin tài khoản Google (khi bạn chọn đăng nhập đám mây): Ứng dụng chỉ ghi nhận tên hiển thị, địa chỉ email và ảnh đại diện nhằm định danh tài khoản và đồng bộ dữ liệu chính xác giữa các thiết bị của bạn.',
      'Chế độ Khách (Ngoại tuyến): Bạn có thể sử dụng đầy đủ tính năng ghi chép ngay trên thiết bị mà không cần cung cấp email hay thông tin cá nhân.',
      'Dữ liệu tài chính do bạn tự nhập: Bao gồm sổ thu chi, ví & tài khoản, giao dịch thu/chi/chuyển khoản, hạn mức ngân sách, mục tiêu tiết kiệm, sổ nợ và giao dịch định kỳ.',
      'Không yêu cầu liên kết ngân hàng: Sổ Thu Chi không bao giờ yêu cầu mật khẩu ngân hàng, mã OTP hay quyền đọc tin nhắn SMS của bạn.',
    ],
  ),
  _PolicySectionData(
    icon: CupertinoIcons.lock_shield_fill,
    color: AppleTokens.jadePrimary,
    title: '2. Lưu trữ & Bảo vệ dữ liệu',
    bullets: [
      'Lưu trữ đám mây cô lập: Khi bật đồng bộ, dữ liệu được lưu trữ trên hạ tầng Google Cloud Firestore thông qua kết nối mã hóa TLS. Quy tắc bảo mật đảm bảo chỉ duy nhất tài khoản đã xác thực của bạn mới có quyền đọc và chỉnh sửa dữ liệu của mình.',
      'Hoạt động ngoại tuyến (Offline-First): Dữ liệu được lưu cục bộ trên thiết bị để bạn tra cứu và ghi chép tức thì ngay cả khi mất mạng, sau đó tự động đồng bộ an toàn khi có kết nối Internet.',
      'Khóa ứng dụng sinh trắc học: Xác thực vân tay và khuôn mặt (Android Biometric / iOS Face ID & Touch ID) được xử lý trực tiếp bởi phần cứng bảo mật của hệ điều hành; ứng dụng không bao giờ lưu trữ dữ liệu sinh trắc học của bạn.',
    ],
  ),
  _PolicySectionData(
    icon: CupertinoIcons.hand_raised_fill,
    color: AppleTokens.systemOrange,
    title: '3. Không quảng cáo & Không chia sẻ bên thứ ba',
    bullets: [
      'Không thu thập dữ liệu quảng cáo: Ứng dụng hoàn toàn không chứa quảng cáo và không tích hợp các bộ công cụ theo dõi hành vi tiếp thị của bên thứ ba.',
      'Tuyệt đối không bán hoặc chia sẻ dữ liệu: Mọi thông tin thu chi, số dư ví và lịch sử giao dịch của bạn được giữ kín tuyệt đối, không chia sẻ cho bất kỳ tổ chức tài chính hay đối tác trung gian nào.',
    ],
  ),
  _PolicySectionData(
    icon: CupertinoIcons.slider_horizontal_3,
    color: AppleTokens.systemIndigo,
    title: '4. Quyền kiểm soát, Xuất & Xóa dữ liệu',
    bullets: [
      'Trích xuất dữ liệu tự do (CSV): Bạn có thể xuất toàn bộ lịch sử giao dịch ra tệp bảng tính CSV (chuẩn UTF-8 hỗ trợ đầy đủ tiếng Việt) bất cứ lúc nào tại mục Cài đặt > Xuất giao dịch ra tệp CSV.',
      'Quyền xóa vĩnh viễn tài khoản & dữ liệu: Bạn có thể chủ động xóa hoàn toàn tài khoản cùng toàn bộ dữ liệu trên đám mây và trên thiết bị ngay lập tức tại mục Cài đặt > Xóa tài khoản & toàn bộ dữ liệu mà không cần chờ phê duyệt.',
    ],
  ),
];

const List<_PolicySectionData> _enSections = [
  _PolicySectionData(
    icon: CupertinoIcons.doc_text_search,
    color: AppleTokens.systemBlue,
    title: '1. Information We Process',
    bullets: [
      'Google Account Profile (when using Cloud Sync): We only receive your display name, email address, and profile photo to identify your account and synchronize your data across devices.',
      'Guest Mode (Offline): You can use the app locally on your device without providing an email address or any personal identity information.',
      'User-Entered Financial Records: Includes your ledgers, wallets, income/expense/transfer transactions, monthly budgets, savings goals, debt records, and recurring bills.',
      'No Bank Credentials Required: Sổ Thu Chi never asks for your bank login credentials, OTP codes, or SMS reading permissions.',
    ],
  ),
  _PolicySectionData(
    icon: CupertinoIcons.lock_shield_fill,
    color: AppleTokens.jadePrimary,
    title: '2. Data Storage & Protection',
    bullets: [
      'Isolated Cloud Storage: Synced records are stored on Google Cloud Firestore over encrypted TLS connections. Strict security rules ensure only your authenticated account can read or modify your records.',
      'Offline-First Reliability: Your records are cached locally on your device for instant access without an internet connection and automatically synchronized when back online.',
      'Biometric App Lock: Fingerprint and facial authentication (Android Biometric / iOS Face ID & Touch ID) are handled strictly by your device hardware; biometric data is never accessed or stored by the app.',
    ],
  ),
  _PolicySectionData(
    icon: CupertinoIcons.hand_raised_fill,
    color: AppleTokens.systemOrange,
    title: '3. Zero Ads & No Third-Party Sharing',
    bullets: [
      'Zero Ad Tracking: The application contains no advertisements and embeds no third-party marketing or behavioral tracking SDKs.',
      'No Data Selling or Sharing: Your financial records, wallet balances, and transaction history are never sold, rented, or shared with any third party.',
    ],
  ),
  _PolicySectionData(
    icon: CupertinoIcons.slider_horizontal_3,
    color: AppleTokens.systemIndigo,
    title: '4. Data Portability & Right to Erasure',
    bullets: [
      'Full CSV Export: You can export your entire transaction history to a standard UTF-8 CSV spreadsheet at any time via Settings > Export Transactions to CSV.',
      'Instant Account & Data Deletion: You can permanently delete your account and erase all cloud and local records immediately from Settings > Delete Account & All Data.',
    ],
  ),
];


