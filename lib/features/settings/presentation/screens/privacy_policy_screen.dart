import 'package:flutter/material.dart';
import 'package:so_thu_chi/core/l10n/l10n_ext.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final isVi = Localizations.localeOf(
      context,
    ).languageCode.toLowerCase().startsWith('vi');

    return Scaffold(
      appBar: AppBar(title: Text(l10n.privacyPolicy)),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isVi
                        ? 'Cam kết Quyền riêng tư — Sổ Thu Chi'
                        : 'Privacy Commitment — Sổ Thu Chi',
                    style: theme.textTheme.titleLarge,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    isVi
                        ? '1. Dữ liệu thuộc quyền sở hữu của bạn: Toàn bộ ví, danh mục, giao dịch và ngân sách được lưu trữ riêng biệt dưới định danh tài khoản Google cá nhân của bạn (`users/{uid}`) và được bảo vệ bằng quy tắc bảo mật Cloud Firestore.\n\n'
                              '2. Không bán hoặc chia sẻ dữ liệu: Ứng dụng không thu thập dữ liệu quảng cáo, không theo dõi hành vi bên thứ ba và không chia sẻ dữ liệu tài chính cá nhân cho bất kỳ bên nào khác.\n\n'
                              '3. Bảo mật thiết bị: Khóa ứng dụng sinh trắc học sử dụng phần cứng bảo mật gốc trên thiết bị của bạn (Android BiometricPrompt / iOS Face ID & Touch ID).\n\n'
                              '4. Quyền xóa toàn bộ dữ liệu: Bạn có thể xuất dữ liệu ra tệp CSV hoặc xóa vĩnh viễn tài khoản cùng toàn bộ dữ liệu đám mây bất cứ lúc nào ngay trong mục Cài đặt > Tài khoản.'
                        : '1. Your Data Belongs to You: All wallets, categories, transactions, and budgets are stored strictly under your private Google account namespace (`users/{uid}`) protected by Cloud Firestore Security Rules.\n\n'
                              '2. Zero Ad Tracking or Data Selling: Sổ Thu Chi never sells, rents, or shares your personal financial records with third parties.\n\n'
                              '3. Device-Level Security: Biometric App Lock uses native OS hardware authentication (Android BiometricPrompt / iOS Face ID & Touch ID).\n\n'
                              '4. Right to Export & Erasure: You can export your complete ledger to UTF-8 CSV or permanently delete your account and all cloud data at any time from Settings > Account.',
                    style: theme.textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

